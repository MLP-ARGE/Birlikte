-- Supabase'in hazır sağladığı ama saf Postgres'te bulunmayan parçaların
-- taklidi. YALNIZCA yerel doğrulama içindir; migration değildir, üretime
-- gitmez. Gerçek projede bunların hepsi Supabase tarafından sağlanır.
create schema if not exists extensions;
create schema if not exists auth;

do $$ begin create role anon nologin;
  exception when duplicate_object then null; end $$;
do $$ begin create role authenticated nologin;
  exception when duplicate_object then null; end $$;
do $$ begin create role service_role nologin bypassrls;
  exception when duplicate_object then null; end $$;

grant usage on schema public, extensions to anon, authenticated, service_role;

create table if not exists auth.users (
  id    uuid primary key default gen_random_uuid(),
  phone text unique,
  email text
);

-- Supabase'de JWT'den gelen kullanıcı kimliği.
create or replace function auth.uid() returns uuid
  language sql stable
  as $fn$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $fn$;

-- Storage. Gerçek projede Supabase'in storage eklentisi sağlıyor; burada
-- yalnızca migration'ın çalışabilmesi için gereken iki tablo taklit
-- ediliyor. Kolon kümesi gerçeğinin alt kümesidir — testler yalnızca
-- bucket'ın kurulduğunu ve okuma politikasının var olduğunu doğruluyor.
create schema if not exists storage;
grant usage on schema storage to anon, authenticated, service_role;

create table if not exists storage.buckets (
  id                 text primary key,
  name               text not null,
  public             boolean not null default false,
  file_size_limit    bigint,
  allowed_mime_types text[],
  created_at         timestamptz not null default now()
);

create table if not exists storage.objects (
  id        uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name      text,
  owner     uuid,
  created_at timestamptz not null default now()
);

alter table storage.objects enable row level security;
