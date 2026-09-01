// Giriş adım 2: OTP'yi doğrula, oturumu aç, profili bordroya bağla.
//
// İstemci OTP doğrulamasını doğrudan supabase.auth.verifyOTP ile de
// yapabilirdi; bu fonksiyonun varlık sebebi doğrulamadan HEMEN SONRA
// profili oluşturup bordro alanlarını yazmak. Bunu istemciye bıraksaydık
// kullanıcı kendi kurumunu/sicilini uydurabilirdi.

import { createClient } from 'jsr:@supabase/supabase-js@2';

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
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const { identifier, code } = await req.json().catch(() => ({}));

  if (typeof identifier !== 'string' || typeof code !== 'string') {
    return Response.json({ error: 'invalid_request' }, { status: 400 });
  }

  // Kodun gittiği numarayı yeniden bul (TCKN ile girildiyse gerekiyor).
  const { data: lookup } = await db.rpc('lookup_employee', {
    p_identifier: identifier,
    p_ip: null,
  });
  const match = lookup?.[0];

  if (!match?.found) {
    return Response.json({ error: 'invalid_code' }, { status: 401 });
  }

  const { data: session, error } = await authClient.auth.verifyOtp({
    phone: match.phone,
    token: code,
    type: 'sms',
  });

  if (error || !session.user) {
    return Response.json({ error: 'invalid_code' }, { status: 401 });
  }

  const { data: profile, error: linkError } = await db.rpc('link_profile', {
    p_user_id: session.user.id,
    p_employee_id: match.employee_id,
  });

  if (linkError) {
    console.error('link_profile_failed', linkError.message);
    return Response.json({ error: 'profile_link_failed' }, { status: 500 });
  }

  return Response.json({
    session: {
      access_token: session.session?.access_token,
      refresh_token: session.session?.refresh_token,
      expires_at: session.session?.expires_at,
    },
    profile,
  });
});
