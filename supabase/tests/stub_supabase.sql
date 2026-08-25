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
