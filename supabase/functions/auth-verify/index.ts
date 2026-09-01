// Giriş adım 2: OTP'yi doğrula, oturumu aç, profili bordroya bağla.
//
// İstemci OTP doğrulamasını doğrudan supabase.auth.verifyOTP ile de
// yapabilirdi; bu fonksiyonun varlık sebebi doğrulamadan HEMEN SONRA
// profili oluşturup bordro alanlarını yazmak. Bunu istemciye bıraksaydık
// kullanıcı kendi kurumunu/sicilini uydurabilirdi.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { handlePreflight, jsonResponse } from '../_shared/cors.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// İKİ AYRI İSTEMCİ — bilerek.
//
// supabase-js'te `auth.verifyOtp()` başarılı olunca istemcinin oturumunu
// doğrulanan KULLANICIYA çevirir. Aynı istemciyle sonra `rpc()` çağırırsan
// istek service_role ile değil, o kullanıcının JWT'siyle gider ve
// `link_profile` "permission denied" verir (authenticated rolünün o
// fonksiyonda yetkisi yok — kasıtlı).
//
// Bu yüzden auth işlemleri ayrı, veritabanı işlemleri ayrı istemcide.
const authClient = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const db = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const { identifier, code } = await req.json().catch(() => ({}));

  if (typeof identifier !== 'string' || typeof code !== 'string') {
    return jsonResponse({ error: 'invalid_request' }, 400);
  }

  // Kodun gittiği numarayı yeniden bul (TCKN ile girildiyse gerekiyor).
  const { data: lookup } = await db.rpc('lookup_employee', {
    p_identifier: identifier,
    p_ip: null,
  });
  const match = lookup?.[0];

  if (!match?.found) {
    return jsonResponse({ error: 'invalid_code' }, 401);
  }

  const { data: session, error } = await authClient.auth.verifyOtp({
    phone: match.phone,
    token: code,
    type: 'sms',
  });

  if (error || !session.user) {
    return jsonResponse({ error: 'invalid_code' }, 401);
  }

  const { data: profile, error: linkError } = await db.rpc('link_profile', {
    p_user_id: session.user.id,
    p_employee_id: match.employee_id,
  });

  if (linkError) {
    console.error('link_profile_failed', linkError.message);
    return jsonResponse({ error: 'profile_link_failed' }, 500);
  }

  return jsonResponse({
    session: {
      access_token: session.session?.access_token,
      refresh_token: session.session?.refresh_token,
      expires_at: session.session?.expires_at,
    },
    profile,
  });
});
