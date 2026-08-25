// Giriş adım 1: telefon veya TCKN ile bordro kaydını doğrula, OTP gönder.
//
// Neden Edge Function: `private.employees` istemciye kapalı olmalı. Bu
// fonksiyon service_role ile çalışıp yalnızca "eşleşti mi" + maskelenmiş
// numara döndürür — çalışan verisi dışarı çıkmaz.
//
// Çalışan numarası sızmasın diye: eşleşme olmasa da yanıt 200 ve aynı
// biçimde döner. İstemci "kod gönderildi" ekranına geçer, kod gelmez.
// Bu, numara deneyerek çalışan listesi çıkarmayı engeller.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const { identifier } = await req.json().catch(() => ({ identifier: null }));

  if (typeof identifier !== 'string' || identifier.length < 10) {
    return Response.json({ error: 'invalid_identifier' }, { status: 400 });
  }

  const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null;

  const { data, error } = await supabase.rpc('lookup_employee', {
    p_identifier: identifier,
    p_ip: ip,
  });

  if (error) {
    // Hız sınırı aşıldıysa istemciye gerçek nedeni söylüyoruz; diğer
    // hatalarda ayrıntı vermiyoruz.
    const rateLimited = error.message?.includes('Çok fazla deneme');
    return Response.json(
      { error: rateLimited ? 'rate_limited' : 'lookup_failed' },
      { status: rateLimited ? 429 : 500 },
    );
  }

  const match = data?.[0];

  if (match?.found) {
    // OTP'yi bordrodaki numaraya gönder — kullanıcının girdiğine değil.
    // TCKN ile giriş yapıldığında da kod kayıtlı numaraya gider.
    const { error: otpError } = await supabase.auth.signInWithOtp({
      phone: match.phone,
      options: {
        // Kayıt yok: yalnızca bordroda olan kişi giriş yapabilir. Kullanıcı
        // auth tarafında yoksa bu çağrı onu oluşturur; bağlama işini
        // auth-verify yapar.
        shouldCreateUser: true,
        data: { employee_id: match.employee_id },
      },
    });

    if (otpError) {
      console.error('otp_send_failed', otpError.message);
      return Response.json({ error: 'otp_send_failed' }, { status: 502 });
    }
  }

  // Eşleşme olsun olmasın aynı yanıt.
  return Response.json({
    sent: true,
    masked_phone: match?.masked_phone ?? null,
  });
});
