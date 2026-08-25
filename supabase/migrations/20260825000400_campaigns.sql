-- Kampanyalar, markalar, kuponlar.

create table public.brands (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,          -- "Starbucks"
  category_label text,                -- "Yeme & İçme" (marka türü, detay ekranı)
  logo_path   text,
  created_at  timestamptz not null default now()
);

create type public.campaign_status as enum ('draft', 'active', 'paused', 'ended');

-- Kuponun nasıl kullanıldığı — Figma kupon kartlarında "Mağazada göster" /
-- "Online kullan" ayrımı buradan geliyor.
create type public.redemption_channel as enum ('in_store', 'online', 'both');

create table public.campaigns (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,     -- "istinye-yuksek-lisans"

  brand_id       uuid not null references public.brands (id),
  category_id    smallint not null references public.interest_categories (id),

  title          text not null,
  -- Serbest metin: "%25", "150 TL", "Ücretsiz", "Komisyonsuz".
  -- Sayısal karşılaştırma gerekirse discount_percent kullanılır.
  discount_label text not null,
  discount_percent smallint check (discount_percent between 0 and 100),

  description    text,
  hero_image_path text,

  -- null ise tüm kurumlara açık. Doluysa yalnızca o kurumun çalışanları görür
  -- (RLS bunu zorluyor, bkz. rls migration'ı).
  institution_id smallint references public.institutions (id),

  points_cost    integer check (points_cost >= 0),
  redemption     public.redemption_channel not null default 'both',

  status         public.campaign_status not null default 'draft',
  starts_at      timestamptz not null,
  ends_at        timestamptz not null,

  -- Kupon oluşturulduktan sonra geçerlilik süresi (Figma: 72 saat).
  coupon_ttl     interval not null default '72 hours',
  -- Toplam kupon kontenjanı; null ise sınırsız.
  total_quota    integer check (total_quota > 0),
  -- Kişi başı azami kupon (Figma koşulları: "bir kez yararlanabilir").
  per_user_limit smallint not null default 1 check (per_user_limit > 0),

  -- Detay ekranındaki editoryal içerik. Sabit şemaya oturmayan, sıralı
  -- serbest listeler olduğu için jsonb; sorgulanmıyor, yalnızca gösteriliyor.
  tags           text[] not null default '{}',
  steps          text[] not null default '{}',   -- "Nasıl kullanılır?"
  who_qualifies  text[] not null default '{}',   -- "Kimler yararlanabilir?"
  rules          text[] not null default '{}',   -- "Kampanya koşulları"
  cancellation_note text,

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint campaigns_date_order check (ends_at > starts_at)
);

create index campaigns_browse_idx
  on public.campaigns (status, ends_at)
  where status = 'active';

create index campaigns_category_idx on public.campaigns (category_id);
create index campaigns_institution_idx on public.campaigns (institution_id);

-- Marka ve başlıkta arama (Figma: "Kampanya veya marka ara").
create index campaigns_search_idx
  on public.campaigns
  using gin (to_tsvector('simple', title || ' ' || coalesce(description, '')));

create trigger campaigns_touch
  before update on public.campaigns
  for each row execute function private.touch_updated_at();

create table public.campaign_branches (
  id           uuid primary key default gen_random_uuid(),
  campaign_id  uuid not null references public.campaigns (id) on delete cascade,
  name         text not null,
  address      text not null,
  opening_hours text,
  phone        text,
  -- Mesafe istemcide hesaplanır; konum burada tutulur.
  latitude     double precision,
  longitude    double precision,
  sort_order   smallint not null default 0
);

create table public.campaign_favorites (
  profile_id  uuid not null references public.profiles (id) on delete cascade,
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (profile_id, campaign_id)
);

create index campaign_favorites_campaign_idx
  on public.campaign_favorites (campaign_id);

create type public.coupon_status as enum ('active', 'used', 'expired', 'cancelled');

create table public.coupons (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles (id) on delete cascade,
  campaign_id   uuid not null references public.campaigns (id),

  -- Kullanıcıya gösterilen kod. Üretimi sunucuda (Edge Function) yapılır;
  -- istemci kod üretemez.
  code          text not null unique,

  status        public.coupon_status not null default 'active',
  issued_at     timestamptz not null default now(),
  expires_at    timestamptz not null,
  used_at       timestamptz,
  -- Nerede kullanıldığı (şube doğrulaması yapılırsa).
  used_branch_id uuid references public.campaign_branches (id),

  -- Puanla alındıysa ilgili ledger kaydı.
  points_spent  integer check (points_spent >= 0),

  created_at    timestamptz not null default now(),

  constraint coupons_used_consistency check (
    (status = 'used' and used_at is not null) or
    (status <> 'used' and used_at is null)
  )
);

create index coupons_profile_status_idx
  on public.coupons (profile_id, status, expires_at desc);

-- Kişi başı limit ve kontenjan kontrolü sunucu tarafında yapılır, ama
-- yarış koşullarına karşı DB seviyesinde de kısmi bir güvence:
-- aynı kullanıcı aynı kampanyada birden fazla AKTİF kupon tutamaz.
create unique index coupons_one_active_per_campaign_idx
  on public.coupons (profile_id, campaign_id)
  where status = 'active';
