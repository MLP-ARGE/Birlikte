// Giriş adım 1: PDKS'de kullanıcı adı + parola doğrula, SMS tetikle.
//
// Parola bu fonksiyonun dışına çıkmaz; PDKS token'ı da istemciye DÖNMEZ.
// Token sunucuda `private.pdks_challenges` içinde tutulur, istemciye
// yalnızca rastgele bir challenge kimliği verilir. Aksi halde istemci SMS
// adımını atlayıp doğrudan PDKS'ye istek atabilirdi.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { handlePreflight, jsonResponse } from '../_shared/cors.ts';
import { login, PdksError, type DeviceInfo } from '../_shared/pdks.ts';

const db = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

/// Telefonu maskele. PDKS zaten maskeli veriyor ("54******89"); vermezse
/// hiç göstermiyoruz — maskeleme mantığını burada uydurmak, maskesiz veri
/// sızdırma riski taşır.
function maskedPhone(raw: string | null): string | null {
  if (!raw) return null;
  return raw.includes('*') ? raw : null;
}

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405);
  }

  const { username, password, device } = await req.json().catch(() => ({}));

  if (typeof username !== 'string' || typeof password !== 'string'
      || !username.trim() || !password) {
    return jsonResponse({ error: 'invalid_request' }, 400);
  }

  try {
    const result = await login(username.trim(), password, (device ?? {}) as DeviceInfo);

    // private şemasına PostgREST üzerinden doğrudan yazılamıyor
    // (PGRST106: yalnızca public ve graphql_public yayınlanmış durumda).
    // Erişim public'teki service_role'a özel sarmalayıcıyla sağlanıyor.
    const { data: challengeId, error } = await db.rpc('create_pdks_challenge', {
      p_username:   result.user.username,
      p_pdks_token: result.token,
      p_pdks_user:  result.user,
    });

    if (error || !challengeId) {
      // Buraya düşersek PDKS SMS'i ZATEN GÖNDERDİ ama kodu eşleştireceğimiz
      // kayıt oluşmadı; kullanıcı baştan denemek zorunda kalır.
      console.error('challenge_insert_failed', error?.message);
      return jsonResponse({ error: 'server_error' }, 500);
    }

    return jsonResponse({
      challenge_id: challengeId,
      masked_phone: maskedPhone(result.user.telefon),
    });
  } catch (e) {
    if (e instanceof PdksError) {
      // Kullanıcı adı/parola hatasını ayrı koda çeviriyoruz; diğer her şey
      // (PDKS kapalı, ağ hatası) istemciye "bağlantı" olarak gidiyor.
      console.error('pdks_login_failed', e.code, e.message);
      return jsonResponse({ error: 'invalid_credentials' }, 401);
    }
    console.error('pdks_login_error', e);
    return jsonResponse({ error: 'server_error' }, 502);
  }
});
