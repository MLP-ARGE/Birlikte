-- Puan defteri, ailem ve Kandaş.

-- Puanlar bir DEFTERDİR (append-only ledger): bakiye hiçbir yerde kolon
-- olarak tutulmaz, hareketlerden türetilir. Tek bir `balance` kolonunu
-- güncellemek eşzamanlı işlemlerde sessizce yanlış bakiye üretir; ayrıca
-- "Son hareketler" ekranı zaten hareket geçmişi istiyor.
create type public.point_reason as enum (
  'blood_donation',       -- Kan bağışı ödülü
  'campaign_usage',       -- Kampanya kullanımı ödülü
  'program_enrollment',   -- Çalışan programına katılım
  'birthday',             -- Doğum günü / özel gün
  'coupon_created',       -- Puanla kupon oluşturma (negatif)
  'coupon_used',          -- Kupon kullanımı (negatif)
  'manual_adjustment',    -- Elle düzeltme (destek ekibi)
  'expiry'                -- Süresi dolan puanın düşülmesi (negatif)
);

create table public.point_entries (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles (id) on delete cascade,

  -- Pozitif = kazanım, negatif = harcama. Sıfır anlamsız.
  amount      integer not null check (amount <> 0),
  reason      public.point_reason not null,

  -- Ekranda gösterilen açıklama, örn. "Medical Park Göztepe".
  description text,

  -- Hareketi doğuran kayıt (kupon, kan bağışı vb.) — silinirse hareket kalır.
  coupon_id   uuid references public.coupons (id) on delete set null,

  occurred_at timestamptz not null default now(),
  -- Kazanılan puan bu tarihten önce kullanılamaz ("Bekleyen 300").
  available_at timestamptz not null default now(),
  -- Kazanılan puanın son kullanma tarihi ("200 puanın 15 Ağustos'ta sona eriyor").
  expires_at  timestamptz,

  created_at  timestamptz not null default now(),

  constraint point_entries_expiry_only_on_credit
    check (expires_at is null or amount > 0)
);

create index point_entries_profile_idx
  on public.point_entries (profile_id, occurred_at desc);

create index point_entries_expiring_idx
  on public.point_entries (profile_id, expires_at)
  where expires_at is not null and amount > 0;

-- Bakiye görünümü: toplam / kullanılabilir / bekleyen.
-- security_invoker sayesinde altındaki tablonun RLS'i uygulanır, yani
-- kullanıcı yalnızca kendi satırlarını görür.
create view public.point_balances
with (security_invoker = true)
as
select
  profile_id,
  coalesce(sum(amount), 0)::integer as total,
  coalesce(sum(amount) filter (
    where available_at <= now() and (expires_at is null or expires_at > now())
  ), 0)::integer as usable,
  coalesce(sum(amount) filter (where available_at > now()), 0)::integer as pending
from public.point_entries
group by profile_id;

comment on view public.point_balances is
  'Puan bakiyesi hareketlerden türetilir; ayrı bir bakiye kolonu tutulmaz.';

-- ---------------------------------------------------------------- Ailem

create type public.family_relation as enum ('spouse', 'child', 'parent', 'sibling');
create type public.family_member_status as enum ('pending', 'active', 'rejected', 'removed');

create table public.family_members (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles (id) on delete cascade,

  full_name    text not null,
  relation     public.family_relation not null,

  -- Yakının TCKN'si de düz metin tutulmuyor; doğrulama özet üzerinden.
  tckn_hash    bytea not null,
  tckn_last2   char(2) not null,

  phone        text not null,
  email        extensions.citext,

  status       public.family_member_status not null default 'pending',

  -- Yakın adına verilen KVKK açık rızası (Figma: "Yakınım adına KVKK açık
  -- rızasını onaylıyorum"). Rıza olmadan kayıt açılamaz.
  consent_id   uuid not null references public.consents (id),

  invited_at   timestamptz not null default now(),
  activated_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint family_members_phone_format check (phone ~ '^\+905[0-9]{9}$')
);

create trigger family_members_touch
  before update on public.family_members
  for each row execute function private.touch_updated_at();

-- Aynı yakın iki kez eklenemez.
create unique index family_members_unique_person_idx
  on public.family_members (profile_id, tckn_hash)
  where status <> 'removed';

create index family_members_profile_idx on public.family_members (profile_id);

-- Azami 3 yakın (Figma: "En fazla 3 yakın ekleyebilirsin. (3/3)").
-- Uygulama katmanına bırakılırsa eşzamanlı iki istek limiti aşabilir;
-- tetikleyici DB seviyesinde garanti ediyor.
create or replace function private.enforce_family_limit()
returns trigger
language plpgsql
as $$
declare
  active_count integer;
  max_members constant integer := 3;
begin
  select count(*) into active_count
  from public.family_members
  where profile_id = new.profile_id
    and status <> 'removed'
    and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);

  if active_count >= max_members then
    raise exception 'En fazla % yakın eklenebilir', max_members
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger family_members_limit
  before insert or update of status on public.family_members
  for each row
  when (new.status <> 'removed')
  execute function private.enforce_family_limit();

-- --------------------------------------------------------------- Kandaş

create type public.blood_request_urgency as enum ('normal', 'urgent');
create type public.blood_request_status  as enum ('open', 'fulfilled', 'closed', 'expired');

create table public.hospitals (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  city       text,
  district   text,
  latitude   double precision,
  longitude  double precision,
  -- MLPCARE kurumuysa bağlı olduğu kurum; değilse (ör. Kızılay) null.
  institution_id smallint references public.institutions (id),
  is_active  boolean not null default true
);

create table public.blood_requests (
  id           uuid primary key default gen_random_uuid(),
  -- Talebi açan kullanıcı. Kendi adına değil, yakını için açıyor olabilir.
  profile_id   uuid not null references public.profiles (id) on delete cascade,

  -- Hasta adı ekranda kısaltılmış gösteriliyor ("M. Yılmaz"); tam ad
  -- saklanmıyor — üçüncü kişinin sağlık verisini gereksiz tutmamak için.
  patient_initials text not null,
  blood_type   public.blood_type not null,
  hospital_id  uuid not null references public.hospitals (id),

  urgency      public.blood_request_urgency not null default 'normal',
  status       public.blood_request_status not null default 'open',

  -- "Tüm talepler ilgili hastaneler tarafından doğrulanır."
  verified_at  timestamptz,
  verified_by  text,

  needed_by    timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index blood_requests_open_idx
  on public.blood_requests (status, blood_type, urgency, created_at desc)
  where status = 'open';

create trigger blood_requests_touch
  before update on public.blood_requests
  for each row execute function private.touch_updated_at();

create table public.blood_request_supports (
  id         uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.blood_requests (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (request_id, profile_id)
);

create table public.blood_donations (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles (id) on delete cascade,
  hospital_id  uuid references public.hospitals (id),
  -- Bağış bir talebe yanıtsa.
  request_id   uuid references public.blood_requests (id) on delete set null,
  donated_at   date not null,
  -- Verilen puan ödülünün defter kaydı.
  point_entry_id uuid references public.point_entries (id) on delete set null,
  created_at   timestamptz not null default now()
);

create index blood_donations_profile_idx
  on public.blood_donations (profile_id, donated_at desc);
