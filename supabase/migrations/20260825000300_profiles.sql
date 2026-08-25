-- Kullanıcı profili, tercihler ve KVKK rızaları.

create type public.app_theme    as enum ('system', 'light', 'dark');
create type public.app_language as enum ('tr', 'en');

-- Kan grubu KVKK m.6 kapsamında ÖZEL NİTELİKLİ kişisel veridir (sağlık
-- verisi). Ayrı açık rıza gerektirir ve Kandaş özelliği kapatılırsa
-- silinmelidir — bkz. public.consents.
create type public.blood_type as enum (
  'A Rh+', 'A Rh−', 'B Rh+', 'B Rh−',
  'AB Rh+', 'AB Rh−', '0 Rh+', '0 Rh−'
);

create table public.profiles (
  -- auth.users ile 1:1. Kullanıcı silinirse profil de silinir.
  id             uuid primary key references auth.users (id) on delete cascade,

  -- Hangi bordro kaydına bağlandığı. Bu bağ, giriş sırasında Edge Function
  -- tarafından kurulur; istemci değiştiremez (RLS yazmayı engeller).
  employee_id    uuid not null unique references private.employees (id),

  -- Bordrodan alınan anlık görüntü. Uygulama bunları düzenletmez; İK
  -- senkronu güncelledikçe tazelenir. Denormalize tutuluyor ki her ekran
  -- private şemaya SECURITY DEFINER çağrısı yapmasın.
  full_name      text not null,
  employee_no    text not null,
  institution_id smallint not null references public.institutions (id),
  department     text,
  region         text,
  facility       text,

  -- Uygulamanın kendi alanları (kullanıcı düzenleyebilir).
  avatar_path    text,          -- Storage: avatars/{user_id}.jpg
  blood_type     public.blood_type,
  birth_date     date,
  language       public.app_language not null default 'tr',
  theme          public.app_theme    not null default 'system',

  onboarded_at   timestamptz,   -- ilgi alanı seçimi tamamlandığında dolar
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create trigger profiles_touch
  before update on public.profiles
  for each row execute function private.touch_updated_at();

comment on column public.profiles.blood_type is
  'ÖZEL NİTELİKLİ KİŞİSEL VERİ (KVKK m.6). Yalnızca Kandaş açık rızası '
  'verildiyse doldurulur; rıza geri alınırsa null''a çekilmelidir.';

-- Bildirim tercihleri: Figma `notification-preferences` ekranındaki
-- 8 konu + 3 kanal. Sabit bir küme olduğu için anahtar/değer satırları
-- yerine kolon kullanıldı — tip güvenli ve tek satır okumayla geliyor.
create table public.notification_preferences (
  profile_id                uuid primary key
                              references public.profiles (id) on delete cascade,

  -- Kampanyalar
  new_campaigns             boolean not null default true,
  personal_recommendations  boolean not null default true,
  favorite_discounts        boolean not null default true,

  -- Kupon ve puan
  coupon_expiry_reminder    boolean not null default true,
  points_earned             boolean not null default true,
  points_expiry_warning     boolean not null default true,

  -- Kandaş
  compatible_blood_requests boolean not null default true,
  appointment_reminder      boolean not null default true,

  -- Kanallar
  channel_push              boolean not null default true,
  channel_email             boolean not null default false,
  channel_sms               boolean not null default false,

  updated_at                timestamptz not null default now()
);

create trigger notification_preferences_touch
  before update on public.notification_preferences
  for each row execute function private.touch_updated_at();

-- İlgi alanları (Figma: interest-selection, 17 kategori).
create table public.interest_categories (
  id         smallint primary key,
  code       text not null unique,
  name       text not null,
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

insert into public.interest_categories (id, code, name, sort_order) values
  (1,'food_drink','Yeme & İçme',1), (2,'health','Sağlık',2),
  (3,'education','Eğitim',3),       (4,'sports','Spor',4),
  (5,'technology','Teknoloji',5),   (6,'music','Müzik',6),
  (7,'art','Sanat',7),              (8,'travel','Seyahat',8),
  (9,'fashion','Moda',9),           (10,'cinema','Sinema',10),
  (11,'books','Kitap',11),          (12,'games','Oyun',12),
  (13,'nature','Doğa',13),          (14,'photography','Fotoğrafçılık',14),
  (15,'yoga','Yoga',15),            (16,'dance','Dans',16),
  (17,'history','Tarih',17);

create table public.profile_interests (
  profile_id  uuid     not null references public.profiles (id) on delete cascade,
  category_id smallint not null references public.interest_categories (id),
  created_at  timestamptz not null default now(),
  primary key (profile_id, category_id)
);

-- Yasal metinler ve rızalar.
create type public.consent_kind as enum (
  'terms_of_use',      -- Kullanım koşulları
  'privacy_kvkk',      -- KVKK aydınlatma + açık rıza
  'blood_health_data', -- Kan grubu (özel nitelikli veri) açık rızası
  'marketing',         -- Ticari elektronik ileti (İYS)
  'family_member'      -- Yakın adına verilen açık rıza
);

create table public.legal_documents (
  id           uuid primary key default gen_random_uuid(),
  kind         public.consent_kind not null,
  version      text not null,
  locale       public.app_language not null default 'tr',
  title        text not null,
  body_md      text not null,
  published_at timestamptz not null default now(),
  unique (kind, version, locale)
);

create table public.consents (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles (id) on delete cascade,
  kind        public.consent_kind not null,
  version     text not null,

  granted     boolean not null,
  granted_at  timestamptz not null default now(),
  -- KVKK ispat yükümlülüğü için: rıza hangi ortamdan verildi.
  ip_address  inet,
  user_agent  text,

  -- Geri alma; kayıt silinmez, yeni satır yazılır ve eskisi kapatılır.
  revoked_at  timestamptz
);

create index consents_profile_kind_idx
  on public.consents (profile_id, kind, granted_at desc);

comment on table public.consents is
  'Rıza kayıtları append-only tutulur — güncelleme/silme yerine yeni satır. '
  'KVKK ispat yükümlülüğü açısından geçmiş korunmalı.';

-- Push bildirim cihazları.
create table public.devices (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles (id) on delete cascade,
  push_token    text not null,
  platform      text not null check (platform in ('ios','android')),
  app_version   text,
  last_seen_at  timestamptz not null default now(),
  created_at    timestamptz not null default now(),
  unique (profile_id, push_token)
);
