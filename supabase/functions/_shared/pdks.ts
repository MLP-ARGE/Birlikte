// MLPCARE PDKS servisi istemcisi.
//
// Bu dosya YALNIZCA Edge Function'larda çalışır. Kullanıcı parolası ve PDKS
// token'ı hiçbir zaman cihaza inmez — ikisi de burada kalır.

const PDKS_BASE = Deno.env.get('PDKS_BASE_URL') ?? 'https://pdksapilive.mlpcare.com';

/// PDKS'nin her istekte beklediği cihaz başlıkları.
///
/// Gerçek bir istemciden yakalanan başlık kümesi bu; sunucu bunların
/// varlığına göre davranabildiği için birebir gönderiyoruz. Cihaza özgü
/// olanları (model, üretici) istemciden alıp geçiriyoruz, elimizde yoksa
/// nötr değerlere düşüyoruz.
export interface DeviceInfo {
  deviceTypeId?: string;
  appVersion?: string;
  manufacturer?: string;
  model?: string;
  osVersion?: string;
  /// FCM kayıt anahtarı; PDKS bildirim göndermek için kullanıyor.
  userApplicationId?: string;
}

function headers(device: DeviceInfo, token?: string): HeadersInit {
  const h: Record<string, string> = {
    'Content-Type': 'application/json; charset=UTF-8',
    'DeviceTypeId': device.deviceTypeId ?? 'ANDROID',
    'AppVersion': device.appVersion ?? '1.0.0',
    'DeviceManufacturer': device.manufacturer ?? 'unknown',
    'DeviceModel': device.model ?? 'unknown',
    'DeviceVersion': device.osVersion ?? '0',
    'LocationPermissionGranted': '0',
    'LanguageId': '1',
  };
  if (device.userApplicationId) h['UserApplicationId'] = device.userApplicationId;
  if (token) h['Authorization'] = `Bearer ${token}`;
  return h;
}

/// PDKS yanıt zarfı: { status, data, errorMessage, errorCode }.
interface Envelope<T> {
  status: boolean;
  data: T;
  errorMessage: string | null;
  errorCode: string | null;
}

export interface PdksUser {
  username: string;
  adsoyad: string;
  departman: string | null;
  mail: string | null;
  pozisyon: string | null;
  telefon: string | null;
  sicil: string;
  subeadi: string | null;
  yonetici: string | null;
  yoneticiAdSoyad: string | null;
  subekodu: number | null;
  iseGirisTarihi: string | null;
  kisiTipi: string | null;
  kisiTipiId: number | null;
}

export interface LoginResult {
  token: string;
  refreshToken: string;
  kvkkStatus: boolean;
  user: PdksUser;
}

export class PdksError extends Error {
  constructor(readonly code: string, readonly httpStatus: number, message?: string) {
    super(message ?? code);
  }
}

/// Adım 1: kullanıcı adı + parola. Başarılıysa PDKS SMS gönderir ve
/// token + kullanıcı bilgisini döner.
export async function login(
  username: string,
  password: string,
  device: DeviceInfo,
): Promise<LoginResult> {
  const res = await fetch(`${PDKS_BASE}/api/Auth/loginwithsms`, {
    method: 'POST',
    headers: headers(device),
    body: JSON.stringify({ username, password }),
  });

  // PDKS hatalı parolada da 200 dönebiliyor; karar zarftaki `status`a göre.
  const body = await res.json().catch(() => null) as Envelope<LoginResult> | null;

  if (!res.ok || !body?.status || !body.data?.token) {
    throw new PdksError(
      body?.errorCode ?? 'pdks_login_failed',
      res.status,
      body?.errorMessage ?? undefined,
    );
  }
  return body.data;
}

/// Adım 2: SMS kodunu doğrula. Kod yol parametresinde, token başlıkta.
export async function confirm(
  code: string,
  token: string,
  device: DeviceInfo,
): Promise<void> {
  // Kod yol parametresine giriyor; rakam dışında bir şey gelmesin.
  if (!/^\d{4,10}$/.test(code)) {
    throw new PdksError('invalid_code_format', 400);
  }

  const res = await fetch(
    `${PDKS_BASE}/api/Auth/confirm/${encodeURIComponent(code)}`,
    { method: 'GET', headers: headers(device, token) },
  );

  const body = await res.json().catch(() => null) as Envelope<string> | null;

  if (!res.ok || !body?.status) {
    throw new PdksError(
      body?.errorCode ?? 'pdks_confirm_failed',
      res.status,
      body?.errorMessage ?? undefined,
    );
  }
}

/// Profil fotoğrafı — base64 JPEG (veri, URL değil).
/// Fotoğraf giriş için kritik değil; hata durumunda null dönüyoruz ki
/// fotoğraf servisi çökse bile kullanıcı giriş yapabilsin.
export async function profileImage(
  token: string,
  device: DeviceInfo,
): Promise<string | null> {
  try {
    const res = await fetch(`${PDKS_BASE}/api/Personel/get-user-profile-image`, {
      method: 'GET',
      headers: headers(token ? device : device, token),
    });
    const body = await res.json().catch(() => null) as Envelope<string> | null;
    if (!res.ok || !body?.status || typeof body.data !== 'string') return null;
    return body.data;
  } catch (e) {
    console.error('pdks_profile_image_failed', e);
    return null;
  }
}
