// Giriş adım 2: SMS kodunu PDKS'de doğrula, Supabase oturumu üret, profili yaz.
//
// Supabase oturumunun neden hâlâ gerektiği: kampanya/kupon/puan/favori
// verilerinin tamamı RLS ile auth.uid() üzerinden korunuyor. PDKS kimliği
// doğruluyor, Supabase ise yetkilendirmeyi taşıyor.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { handlePreflight, jsonResponse } from '../_shared/cors.ts';
import { confirm, profileImage, PdksError, type DeviceInfo, type PdksUser }
  from '../_shared/pdks.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// İKİ AYRI İSTEMCİ — auth-verify'daki ile aynı sebep:
// `verifyOtp()` başarılı olunca istemcinin oturumunu o kullanıcıya çevirir.
// Aynı istemciyle sonra rpc() çağırırsak istek service_role ile değil
// kullanıcı JWT'siyle gider ve link_pdks_profile "permission denied" verir.
const authClient = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const db = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

/// PDKS e-posta vermezse sentetik bir adres üretiyoruz: Supabase auth
/// kullanıcısı e-posta ile anahtarlanıyor. Gerçek posta kutusu olmadığı
/// belli olsun diye ayrı bir alan adı kullanılıyor.
function authEmail(user: PdksUser): string {
  const mail = user.mail?.trim();
  if (mail && mail.includes('@')) return mail.toLowerCase();
  return `${user.username.toLowerCase()}@pdks.mlpcare.invalid`;
}

/// E-postadan Supabase auth kullanıcısını bulur, yoksa oluşturur; ardından
/// o kullanıcı için bir oturum üretir.
///
/// Parola kullanmıyoruz: PDKS zaten doğruladı. Magic link akışının token
/// özetini sunucuda tüketerek oturumu burada kuruyoruz — link hiçbir zaman
/// e-postayla gönderilmiyor.
async function mintSession(email: string) {
  // ÖNCE kullanıcıyı oluştur ve e-postasını doğrulanmış işaretle.
  //
  // Sırası önemli: generateLink var olmayan kullanıcı için HATA VERMİYOR,
  // kullanıcıyı sessizce oluşturuyor — ama ürettiği bağlantı bir signup
  // doğrulaması oluyor ve magiclink olarak doğrulanınca 403 "Email link is
  // invalid or has expired" dönüyor. İlk kez giren her çalışan buna
  // takılırdı; ikinci denemede çalışması hatayı gizliyordu.
  //
  // Kullanıcı zaten varsa createUser "already been registered" döner;
  // bu beklenen bir durum, yutuyoruz.
  const created = await authClient.auth.admin.createUser({
    email,
    email_confirm: true,
  });
  if (created.error && !/already/i.test(created.error.message)) {
    throw new Error(`create_user: ${created.error.message}`);
  }

  const link = await authClient.auth.admin.generateLink({
    type: 'magiclink',
    email,
  });
  if (link.error) throw new Error(`generate_link: ${link.error.message}`);

  const props = link.data.properties;
  if (!props?.hashed_token) throw new Error('missing_hashed_token');

  // Doğrulama tipini sabitlemek yerine sunucunun bildirdiğini kullanıyoruz.
  const verified = await authClient.auth.verifyOtp({
    token_hash: props.hashed_token,
    type: (props.verification_type ?? 'magiclink') as 'magiclink',
  });
  if (verified.error || !verified.data.user || !verified.data.session) {
    throw new Error(`verify_otp: ${verified.error?.message ?? 'no session'}`);
  }
  return { user: verified.data.user, session: verified.data.session };
}

/// Base64 JPEG'i avatars bucket'ına yazar. Fotoğraf girişi bloklamamalı —
/// hata olursa sessizce geçiyoruz, kullanıcı avatarsız girer.
/// Başarılıysa depolama yolunu döner, aksi halde null.
async function storeAvatar(
  userId: string,
  base64: string | null,
): Promise<string | null> {
  if (!base64) return null;
  try {
    const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    const path = `${userId}.jpg`;
    const { error } = await db.storage
      .from('avatars')
      .upload(path, bytes, { contentType: 'image/jpeg', upsert: true });
    if (error) {
      console.error('avatar_upload_failed', error.message);
      return null;
    }
    return path;
  } catch (e) {
    console.error('avatar_decode_failed', e);
    return null;
  }
}

/// "2025-06-11T00:00:00" → "2025-06-11". Geçersizse null.
function toDate(raw: string | null): string | null {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10);
}

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const { challenge_id, code, device } = await req.json().catch(() => ({}));

  if (typeof challenge_id !== 'string' || typeof code !== 'string') {
    return jsonResponse({ error: 'invalid_request' }, 400);
  }

  // Challenge'ı al ve aynı işlemde tüket. private şeması API'ye kapalı
  // olduğu için service_role'a özel public sarmalayıcı kullanılıyor.
  //
  // Burada yalnızca OKUYORUZ. Tüketme, kod PDKS'de doğrulandıktan sonra:
  // yanlış kod girişi challenge'ı yakmasın, kullanıcı parolayı baştan
  // girmek zorunda kalmasın.
  const { data: rows, error: challengeError } = await db
    .rpc('read_pdks_challenge', { p_id: challenge_id });

  const challenge = Array.isArray(rows) ? rows[0] : null;
  if (challengeError || !challenge?.pdks_token) {
    return jsonResponse({ error: 'challenge_expired' }, 401);
  }

  const pdksUser = challenge.pdks_user as PdksUser;
  const dev = (device ?? {}) as DeviceInfo;

  // 1) SMS kodunu PDKS'de doğrula.
  try {
    await confirm(code, challenge.pdks_token, dev);
  } catch (e) {
    if (e instanceof PdksError) {
      console.error('pdks_confirm_failed', e.code, e.message);
      return jsonResponse({ error: 'invalid_code' }, 401);
    }
    console.error('pdks_confirm_error', e);
    return jsonResponse({ error: 'server_error' }, 502);
  }

  // Kod doğru. Challenge'ı şimdi tüket — koşullu UPDATE atomik olduğu için
  // eşzamanlı ikinci bir istek buradan boş döner ve reddedilir.
  const { data: consumed } = await db
    .rpc('consume_pdks_challenge', { p_id: challenge_id });
  if (consumed !== true) {
    return jsonResponse({ error: 'challenge_expired' }, 401);
  }

  // 2) Fotoğrafı al (kritik değil) ve Supabase oturumunu üret.
  const [photo, minted] = await Promise.all([
    profileImage(challenge.pdks_token, dev),
    mintSession(authEmail(pdksUser)).catch((e) => {
      console.error('mint_session_failed', e);
      return null;
    }),
  ]);

  if (!minted) return jsonResponse({ error: 'session_failed' }, 500);

  const avatarPath = await storeAvatar(minted.user.id, photo);

  // 3) Profili PDKS verisiyle yaz.
  const { data: profile, error: linkError } = await db.rpc('link_pdks_profile', {
    p_user_id:     minted.user.id,
    p_username:    pdksUser.username,
    p_full_name:   pdksUser.adsoyad,
    p_employee_no: pdksUser.sicil,
    p_branch_code: pdksUser.subekodu,
    p_department:  pdksUser.departman,
    p_facility:    pdksUser.subeadi,
    p_position:    pdksUser.pozisyon,
    p_email:       pdksUser.mail,
    p_manager:     pdksUser.yoneticiAdSoyad,
    p_person_type: pdksUser.kisiTipi,
    p_hired_at:    toDate(pdksUser.iseGirisTarihi),
  });

  if (linkError) {
    // Eşlenmemiş şube artık hata değil: varsayılan kuruma düşüyor ve şube
    // public.pdks_unmapped_branches listesine kaydediliyor. Buraya düşmek
    // gerçek bir arıza demek.
    console.error('link_pdks_profile_failed', linkError.message);
    return jsonResponse({ error: 'profile_link_failed' }, 500);
  }

  // Avatar yolunu profile yaz. link_pdks_profile bu alana dokunmuyor:
  // fotoğraf PDKS'den her girişte yeniden geldiği için ayrı tutuluyor ve
  // yükleme başarısız olsa bile profil yazımı etkilenmiyor.
  if (avatarPath) {
    await db.from('profiles')
      .update({ avatar_path: avatarPath })
      .eq('id', minted.user.id);
    // Yanıttaki profil link_pdks_profile'dan geliyor, yani bu güncellemeden
    // ÖNCEKİ hâli. Değeri elde yansıtıyoruz ki istemci ikinci bir okuma
    // yapmadan avatarı gösterebilsin.
    profile.avatar_path = avatarPath;
  }

  return jsonResponse({
    session: {
      access_token:  minted.session.access_token,
      refresh_token: minted.session.refresh_token,
      expires_at:    minted.session.expires_at,
    },
    profile,
  });
});
