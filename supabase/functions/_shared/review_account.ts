// App Store inceleme hesabı.
//
// NEDEN VAR: Apple'ın 2.1 kuralı, giriş gerektiren uygulamalar için çalışan
// bir demo hesabı zorunlu kılıyor. Bizim girişimiz MLPCARE kurumsal
// kimliğiyle yapılıyor ve gerçek bir telefona SMS gönderiyor — inceleme
// görevlisi ne kurumsal hesaba ne de o telefona erişebilir.
//
// Bu yüzden yalnızca inceleme için ayrılmış tek bir kullanıcı adı, PDKS'ye
// hiç gitmeden sabit bir kodla giriş yapabiliyor.
//
// GÜVENLİK KURALLARI:
//  - Hem kullanıcı adı hem parola hem de kod ortam değişkeninden geliyor;
//    hiçbiri kodda yazılı değil.
//  - Üçünden biri tanımlı değilse özellik TAMAMEN KAPALI (fail-closed).
//    Yanlışlıkla açık kalmış bir arka kapı olmasın.
//  - Karşılaştırmalar sabit zamanlı; kullanıcı adı/parola tahmin edilirken
//    yanıt süresinden bilgi sızmasın.
//  - Hesap gerçek bir çalışana karşılık gelmiyor; sahte bir profil alıyor.

const USERNAME = Deno.env.get('REVIEW_USERNAME');
const PASSWORD = Deno.env.get('REVIEW_PASSWORD');
const OTP      = Deno.env.get('REVIEW_OTP');

/// Özellik yapılandırılmış mı? Üçü birden gerekiyor.
export const reviewAccountEnabled =
  !!USERNAME && !!PASSWORD && !!OTP;

/// Zamanlama saldırısına kapalı karşılaştırma.
function safeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export function isReviewLogin(username: string, password: string): boolean {
  if (!reviewAccountEnabled) return false;
  return safeEquals(username, USERNAME!) && safeEquals(password, PASSWORD!);
}

export function isReviewOtp(code: string): boolean {
  if (!reviewAccountEnabled) return false;
  return safeEquals(code, OTP!);
}

/// İnceleme hesabının sahte PDKS kullanıcısı.
///
/// Şube kodu 101 (Medical Park): eşlemesi doğrulanmış tek kod, böylece
/// inceleme görevlisi kampanyaları eksiksiz görüyor.
export function reviewPdksUser() {
  return {
    username: USERNAME!,
    adsoyad: 'App Review',
    departman: 'MLPCARE',
    mail: `${USERNAME}@pdks.mlpcare.invalid`,
    pozisyon: 'Demo Hesabı',
    telefon: null,
    sicil: 'REVIEW-0001',
    subeadi: 'Medical Park Merkez',
    yonetici: null,
    yoneticiAdSoyad: null,
    subekodu: 101,
    iseGirisTarihi: null,
    kisiTipi: 'Çalışan',
    kisiTipiId: 1120,
  };
}

/// Challenge tablosunda inceleme oturumunu işaretlemek için kullanılan token.
/// Gerçek bir PDKS token'ı değil; verify adımı bunu görünce PDKS'ye gitmiyor.
export const REVIEW_TOKEN_MARKER = '__app_review__';
