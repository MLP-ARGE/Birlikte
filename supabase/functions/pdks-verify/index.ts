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
  let link = await authClient.auth.admin.generateLink({ type: 'magiclink', email });

  if (link.error) {
    // Kullanıcı henüz yoksa oluştur ve tekrar dene.
    const created = await authClient.auth.admin.createUser({
      email,
      email_confirm: true,
    });
    if (created.error) throw new Error(`create_user: ${created.error.message}`);
    link = await authClient.auth.admin.generateLink({ type: 'magiclink', email });
    if (link.error) throw new Error(`generate_link: ${link.error.message}`);
  }

  const hashed = link.data.properties?.hashed_token;
  if (!hashed) throw new Error('missing_hashed_token');

  const verified = await authClient.auth.verifyOtp({
    token_hash: hashed,
    type: 'magiclink',
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

  // Challenge'ı al: tüketilmemiş ve süresi geçmemiş olmalı.
  const { data: challenge } = await db
    .schema('private')
    .from('pdks_challenges')
    .select('id, pdks_token, pdks_user, expires_at, consumed_at')
    .eq('id', challenge_id)
    .maybeSingle();

  if (!challenge || challenge.consumed_at
      || new Date(challenge.expires_at) < new Date()) {
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

  // Kod doğrulandı: challenge tek kullanımlık, hemen tüketildi işaretle.
  // Doğrulamadan SONRA işaretliyoruz ki yanlış kod girişi girişimi
  // harcamasın (PDKS'nin kendi deneme limiti geçerli kalsın).
  await db.schema('private').from('pdks_challenges')
    .update({ consumed_at: new Date().toISOString() })
    .eq('id', challenge.id);

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
    console.error('link_pdks_profile_failed', linkError.message);
    // Şube eşlemesi eksikse bunu ayırt edilebilir kılıyoruz: kullanıcı
    // hatası değil, bizim tamamlamamız gereken bir veri eksiği.
    const missingBranch = linkError.message.includes('kurum eşlemesi');
    return jsonResponse(
      { error: missingBranch ? 'branch_not_mapped' : 'profile_link_failed' },
      missingBranch ? 409 : 500,
    );
  }

  // Avatar yolunu profile yaz. link_pdks_profile bu alana dokunmuyor:
  // fotoğraf PDKS'den her girişte yeniden geldiği için ayrı tutuluyor ve
  // yükleme başarısız olsa bile profil yazımı etkilenmiyor.
  if (avatarPath) {
    await db.from('profiles')
      .update({ avatar_path: avatarPath })
      .eq('id', minted.user.id);
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
