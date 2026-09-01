// CORS başlıkları.
//
// Native (iOS/Android) istemciler CORS uygulamaz, ama Flutter web
// (`flutter run -d chrome`) uygular: preflight OPTIONS isteğine doğru
// yanıt verilmezse tarayıcı çağrıyı hiç göndermez ve giriş sessizce
// başarısız olur.
//
// Origin şimdilik açık (`*`) — bu uçlar zaten kimlik doğrulaması
// gerektirmiyor ve gizli veri döndürmüyor (bkz. auth-lookup'ın bilerek
// fakir yanıtı). Web üretime çıkarsa buraya uygulamanın alan adı yazılmalı.
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/// Preflight isteğini karşılar; preflight değilse null döner.
export function handlePreflight(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
}

/// JSON yanıtı — CORS başlıklarıyla.
export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
