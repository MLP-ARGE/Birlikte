-- Kurumlar ve bordro (çalışan) kayıtları.
--
-- Bu uygulamada kayıt (sign-up) YOKTUR. Kullanıcı ancak bordroda kaydı varsa
-- giriş yapabilir. `private.employees` bu doğrulamanın tek kaynağıdır ve
-- İK/bordro sisteminden senkronize edilir — uygulama asla yazmaz.

create table public.institutions (
  id           smallint primary key,
  code         text not null unique,
  name         text not null,
  -- Marka rengi; uygulamadaki Institution enum'ı ile aynı değerler.
  brand_color  text not null check (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_key     text,
  sort_order   smallint not null default 0,
  is_active    boolean not null default true
);

comment on table public.institutions is
  'MLPCARE çatısındaki kurumlar. İstemci okuyabilir, yazamaz.';

insert into public.institutions (id, code, name, brand_color, logo_key, sort_order) values
  (1, 'medical_park',          'Medical Park',          '#E31F24', 'brands/medical-park',          1),
  (2, 'liv_hospital',          'Liv Hospital',          '#008FC5', 'brands/liv-hospital',          2),
  (3, 'liv_koleji',            'Liv Koleji',            '#008FC5', 'brands/liv-koleji',            3),
  (4, 'istinye_universitesi',  'İstinye Üniversitesi',  '#1C3B5C', 'brands/istinye-universitesi',  4);

create type public.employment_status as enum ('active', 'on_leave', 'left');

create table private.employees (
  id                uuid primary key default gen_random_uuid(),

  -- Bordrodaki sicil numarası, örn. "MP-9843102".
  employee_no       text not null unique,

  -- TCKN düz metin OLARAK TUTULMUYOR. Arama için HMAC özeti saklanır;
  -- pepper `app.tckn_pepper` GUC'undan gelir ve veritabanı dökümünde
  -- bulunmaz. Sızıntı hâlinde özetlerden TCKN geri üretilemez (11 haneli
  -- uzay kaba kuvvete açık olduğu için pepper kritik).
  tckn_hash         bytea not null unique,
  -- Maskeleme için son iki hane ("*********67"). Tek başına kimliklendirmez.
  tckn_last2        char(2) not null,

  full_name         text not null,
  phone             text not null,        -- E.164, private.normalize_phone ile
  email             extensions.citext,

  institution_id    smallint not null references public.institutions (id),
  department        text,
  region            text,                 -- örn. "İstanbul Bölge"
  facility          text,                 -- örn. "Göztepe Hastanesi"

  status            public.employment_status not null default 'active',
  hired_at          date,
  left_at           date,

  -- İK senkronizasyonunun bu satıra en son dokunduğu an; kaynakta silinen
  -- kayıtları yakalamak için (bkz. senkron notu aşağıda).
  synced_at         timestamptz not null default now(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint employees_phone_format check (phone ~ '^\+905[0-9]{9}$')
);

create index employees_phone_idx on private.employees (phone) where status = 'active';
-- tckn_hash zaten UNIQUE; ayrı indekse gerek yok.

create trigger employees_touch
  before update on private.employees
  for each row execute function private.touch_updated_at();

comment on table private.employees is
  'Bordro kaynaklı çalışan kayıtları. API''ye kapalı. İK sisteminden '
  'senkronize edilir; uygulama yalnızca giriş doğrulamasında dolaylı okur.';

-- TCKN özeti: pepper + HMAC-SHA256. Pepper veritabanı yapılandırmasında
-- tutulur (`alter database ... set app.tckn_pepper = '...'`), migration'da
-- değil.
create or replace function private.hash_tckn(raw text)
returns bytea
language plpgsql
stable
as $$
declare
  pepper text := current_setting('app.tckn_pepper', true);
begin
  if pepper is null or length(pepper) < 32 then
    raise exception 'app.tckn_pepper tanımlı değil veya çok kısa (>=32 karakter olmalı)';
  end if;

  if not private.is_valid_tckn(raw) then
    raise exception 'Geçersiz TCKN';
  end if;

  return extensions.hmac(raw, pepper, 'sha256');
end;
$$;
