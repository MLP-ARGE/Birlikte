# Birlikte — Supabase kurulumu

Bu klasör veritabanı şemasını, güvenlik politikalarını ve giriş akışının
sunucu tarafını içerir. Migration'lar sırayla uygulanır.

## Mimari kararlar

**Kayıt (sign-up) yok.** Kullanıcı ancak İK/bordro sisteminde kaydı varsa
giriş yapabilir. `private.employees` bu doğrulamanın tek kaynağıdır ve
uygulamaya kapalıdır.

**İki şema.** `public` PostgREST üzerinden istemciye açık, her tabloda RLS
var. `private` API'ye kapalı — bordro kayıtları, giriş denemeleri ve
ayrıcalıklı fonksiyonlar orada. `private` şemasını Dashboard → API Settings
→ Exposed schemas listesine **eklemeyin**.

**Puanlar defter (ledger).** Bakiye kolonu yok; `point_entries`'ten
türetiliyor (`public.point_balances` görünümü). Tek bir bakiye kolonunu
güncellemek eşzamanlı işlemlerde sessizce yanlış sonuç verir.

**Kupon üretimi sunucuda.** `public.create_coupon(campaign_id)` kod üretimi,
kontenjan ve kişi başı limiti tek işlemde uygular. `coupons` tablosunda
INSERT politikası yoktur — istemci doğrudan yazamaz.

## Şemayı doğrulama (kimlik bilgisi gerekmez)

Migration'ları gerçek projeye göndermeden önce yerel bir Postgres'te kurup
davranış testlerini koşabilirsin. Supabase CLI veya Docker gerekmez:

```bash
brew install postgresql@17
supabase/tests/run.sh
```

32 kontrol koşuyor: telefon/TCKN normalizasyonu, giriş akışı, RLS izolasyonu
(iki farklı kurumdan iki kullanıcıyla), bordro kolon kilidi, kupon limitleri
ve kontenjanı, aile limiti, rıza kayıtlarının değiştirilemezliği, puan
bakiyesi. Aynı testler her PR'da GitHub Actions üzerinde de koşuyor
(`.github/workflows/supabase.yml`).

`supabase/tests/stub_supabase.sql` yalnızca yerel doğrulama içindir —
Supabase'in sağladığı `auth` şeması, roller ve `extensions` şemasını taklit
eder, üretime gitmez.

## Kurulum

```bash
brew install supabase/tap/supabase        # CLI yok, önce bu
supabase link --project-ref <PROJE_REF>
supabase db push                          # migration'ları uygula
supabase functions deploy auth-lookup auth-verify
```

### Zorunlu sır: TCKN pepper

TCKN düz metin saklanmıyor; arama HMAC özeti üzerinden yapılıyor. Pepper
veritabanı ayarında tutulur ve **db dökümüne girmez**:

```sql
alter database postgres set app.tckn_pepper = '<en az 32 karakterlik rastgele değer>';
```

Pepper kaybolursa mevcut özetler kullanılamaz hâle gelir (tüm bordro
yeniden içe aktarılmalı). Bir sır yöneticisinde yedekleyin.

### SMS sağlayıcısı

Telefon OTP'si için Supabase Auth bir SMS sağlayıcısı ister. Yerleşik
seçenekler Twilio / MessageBird / Vonage / TextLocal. Türkiye'de
teslimat ve İYS uyumu için yerel bir sağlayıcı (Netgsm, İleti Merkezi vb.)
tercih edilecekse Auth → Hooks → **Send SMS Hook** ile bağlanır.

Karar verilene kadar giriş akışı uçtan uca çalışmaz.

## Bordro senkronizasyonu

`private.employees` İK sisteminden beslenir. Beklenen alanlar:

| Alan | Not |
|---|---|
| `employee_no` | Sicil no, benzersiz |
| `tckn` | İçe aktarımda `private.hash_tckn()` ile özetlenir, saklanmaz |
| `full_name`, `phone`, `email` | Telefon `private.normalize_phone()` ile E.164 |
| `institution_id` | `public.institutions.code` eşlemesi |
| `department`, `region`, `facility` | Profil ekranında gösteriliyor |
| `status` | `active` / `on_leave` / `left` |

İşten ayrılanlar **silinmez**, `status = 'left'` yapılır: giriş engellenir
ama kupon/puan geçmişi ve KVKK rıza kayıtları korunur.

## GitHub ile ilişkisi

Supabase projesi GitHub'dan **oluşturulamaz** — ayrı servis, ayrı kimlik
bilgisi (`sbp_...` access token). GitHub'ın buradaki rolü CI/CD:

* Her PR'da şema doğrulanır (kimlik bilgisi gerekmeden).
* `main`'e merge'de migration'lar ve Edge Function'lar yayına alınır.

Bunun için depoya üç secret eklenmeli (Settings → Secrets → Actions):

| Secret | Nereden |
|---|---|
| `SUPABASE_ACCESS_TOKEN` | supabase.com/dashboard/account/tokens |
| `SUPABASE_PROJECT_REF` | Proje ayarları → Reference ID |
| `SUPABASE_DB_PASSWORD` | Proje oluşturulurken belirlenen DB şifresi |

`deploy` işi `production` ortamına bağlı; GitHub'da o ortama onay kuralı
koyarsan üretim şemasına kazara yazma engellenir.

## Açık konular

Bunlar mimariyi etkiler, karar bekliyor — ayrıntı için proje sohbetine bakın:

1. **Veri yerleşimi (KVKK).** Kan grubu özel nitelikli kişisel veridir
   (KVKK m.6). Supabase Cloud'un Türkiye bölgesi yok; yurt dışına aktarım
   ayrı açık rıza veya uygun bir aktarım mekanizması gerektirir.
   Alternatif: self-hosted Supabase (yurt içi sunucu).
2. **SMS sağlayıcısı** ve İYS entegrasyonu.
3. **Bordro aktarım yöntemi** (nightly CSV, API, doğrudan DB view?).
