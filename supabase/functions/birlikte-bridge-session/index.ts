// birlikte-api oturumunu Supabase oturumuna köprüler.
//
// Flutter artık birlikte-api'ye DOĞRUDAN konuşuyor (kampanya/ilgi alanı/
// yakınlar için) — PDKS'deki gibi token Edge Function arkasında
// gizlenmiyor. Ama Supabase'de kalan özellikler (kupon, puan, kan bağışı)
// RLS ile auth.uid() üzerinden korunuyor; bu fonksiyon o köprüyü kuruyor.
//
// İstemcinin kendi beyanına GÜVENMİYORUZ: aldığımız access_token'ı
// GET /api/me ile SUNUCU TARAFINDA doğruluyoruz. Sahte bir token ya da
// başkasının token'ı buraya gelse, gerçek sunucu 401 döner ve köprü
// kurulmaz.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { handlePreflight, jsonResponse } from '../_shared/cors.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const BIRLIKTE_API_URL =
  Deno.env.get('BIRLIKTE_API_URL') ?? 'https://birliktetest.mlpcare.com';

// İKİ AYRI İSTEMCİ — auth-verify/pdks-verify'daki ile aynı sebep:
// verifyOtp() başarılı olunca istemcinin oturumunu o kullanıcıya çevirir.
const authClient = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const db = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

interface BirlikteMeRecord {
  kullaniciId: number;
  kayitTipi: string | null;
  ad: string | null;
  soyad: string | null;
  eposta: string | null;
  kurum: string | null;
  kurumKodu: string | null;
  subeKodu: string | null;
  subeAdi: string | null;
  departman: string | null;
  unvan: string | null;
}

/// E-postadan Supabase auth kullanıcısını bulur/oluşturur, oturum üretir.
/// pdks-verify'daki mintSession ile birebir aynı desen; ayrıntılı gerekçe
/// orada: generateLink var olmayan kullanıcı için hata vermiyor, önce
/// createUser çağrılmalı, yoksa ilk girişte "Email link is invalid or has
/// expired" alınıyor.
async function mintSession(email: string) {
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

  const verified = await authClient.auth.verifyOtp({
    token_hash: props.hashed_token,
    type: (props.verification_type ?? 'magiclink') as 'magiclink',
  });
  if (verified.error || !verified.data.user || !verified.data.session) {
    throw new Error(`verify_otp: ${verified.error?.message ?? 'no session'}`);
  }
  return { user: verified.data.user, session: verified.data.session };
}

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const { access_token: accessToken } = await req.json().catch(() => ({}));
  if (typeof accessToken !== 'string' || !accessToken) {
    return jsonResponse({ error: 'invalid_request' }, 400);
  }

  // Token'ı sunucu tarafında doğrula — kampanyaSayisi=0: profil doldurmak
  // için kampanya verisine ihtiyacımız yok.
  let records: BirlikteMeRecord[];
  try {
    const res = await fetch(
      `${BIRLIKTE_API_URL}/api/me?kampanyaSayisi=0`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    const body = await res.json().catch(() => null);
    if (!res.ok || !body?.responseStatus) {
      console.error('birlikte_me_failed', res.status, body?.responseCode);
      return jsonResponse({ error: 'invalid_token' }, 401);
    }
    records = body.veri as BirlikteMeRecord[];
  } catch (e) {
    console.error('birlikte_me_error', e);
    return jsonResponse({ error: 'server_error' }, 502);
  }

  if (!records?.length) {
    return jsonResponse({ error: 'no_profile' }, 500);
  }

  // Aynı kişinin birden fazla kaydı olabilir (çalışan + öğrenci + yakın).
  // CALISAN'ı tercih ediyoruz; yoksa ilk kaydı kullanıyoruz.
  const record =
    records.find((r) => r.kayitTipi === 'CALISAN') ?? records[0];

  const email = record.eposta?.trim() ||
    `${record.kullaniciId}@birlikte-api.mlpcare.invalid`;

  let minted;
  try {
    minted = await mintSession(email);
  } catch (e) {
    console.error('mint_session_failed', e);
    return jsonResponse({ error: 'session_failed' }, 500);
  }

  const { data: profile, error: linkError } = await db.rpc(
    'link_birlikte_profile',
    {
      p_user_id: minted.user.id,
      p_kullanici_id: record.kullaniciId,
      p_ad: record.ad,
      p_soyad: record.soyad,
      p_eposta: record.eposta,
      p_kurum_kodu: record.kurumKodu,
      p_kurum_adi: record.kurum,
      p_sube_kodu: record.subeKodu,
      p_sube_adi: record.subeAdi,
      p_departman: record.departman,
      p_unvan: record.unvan,
      p_kayit_tipi: record.kayitTipi,
      p_cinsiyet: null,
    },
  );

  if (linkError) {
    console.error('link_birlikte_profile_failed', linkError.message);
    return jsonResponse({ error: 'profile_link_failed' }, 500);
  }

  return jsonResponse({
    session: {
      access_token: minted.session.access_token,
      refresh_token: minted.session.refresh_token,
      expires_at: minted.session.expires_at,
    },
    profile,
  });
});
