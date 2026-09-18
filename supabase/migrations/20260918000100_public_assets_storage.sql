-- Herkese açık görseller: kampanya kapakları ve marka logoları.
--
-- Neden ayrı ve "public" bir bucket: bunlar pazarlama görselleri, kişiye
-- özel değil ve giriş yapmamış kullanıcı da görebilmeli (onboarding,
-- kampanya listesi). Kullanıcı avatarları BURAYA KONMAZ — onlar kişisel
-- veri, ayrı ve private bir bucket'a ait (bkz. profiles.avatar_path).
--
-- Uygulama tarafında dikkat: campaigns.hero_image_path ve brands.logo_path
-- doğrudan CachedNetworkImage'a URL olarak veriliyor, yani bu kolonlara
-- göreli yol değil TAM URL yazılır:
--   https://<ref>.supabase.co/storage/v1/object/public/public-assets/<yol>

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'public-assets',
  'public-assets',
  true,
  5242880,                                    -- 5 MB; kapak görseli için fazlasıyla yeterli
  array['image/webp','image/png','image/jpeg','image/svg+xml']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Okuma herkese açık. Bucket zaten public olduğu için nesneler CDN
-- üzerinden anonim servis ediliyor; yine de politikayı açıkça yazıyoruz ki
-- bucket ileride private'a çevrilirse davranış kazara değişmesin.
drop policy if exists "public_assets_read" on storage.objects;
create policy "public_assets_read"
  on storage.objects for select
  using (bucket_id = 'public-assets');

-- Yazma yalnızca service_role ile (içerik yükleme bir yönetim işi, uygulama
-- kullanıcısı buraya dosya koyamaz). service_role RLS'i zaten atlar; burada
-- authenticated/anon için bilinçli olarak HİÇBİR insert/update/delete
-- politikası tanımlamıyoruz, dolayısıyla onlara kapalı.
