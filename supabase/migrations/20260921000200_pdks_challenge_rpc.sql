-- Challenge kayıtları için public sarmalayıcılar.
--
-- İlk sürüm Edge Function'dan `db.schema('private').from('pdks_challenges')`
-- ile yazmaya çalışıyordu ve PostgREST bunu reddetti:
--   PGRST106 — Only the following schemas are exposed: public, graphql_public
--
-- private şeması bilerek API'ye kapalı (PDKS token'ı orada duruyor). Erişim
-- public'teki SECURITY DEFINER sarmalayıcılarla veriliyor; bunlar yalnızca
-- service_role'a açık, yani Edge Function dışından çağrılamıyor.
-- Aynı desen auth_rpc.sql'de lookup_employee/link_profile için de kullanıldı.

create or replace function public.create_pdks_challenge(
  p_username   text,
  p_pdks_token text,
  p_pdks_user  jsonb
)
returns uuid
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_id uuid;
begin
  -- Süresi geçmişleri de burada süpürüyoruz: ayrı bir zamanlanmış iş
  -- kurmaya gerek kalmıyor, tablo her girişte biraz daha temizleniyor.
  delete from private.pdks_challenges
  where expires_at < now() - interval '1 hour';

  insert into private.pdks_challenges (username, pdks_token, pdks_user)
  values (p_username, p_pdks_token, p_pdks_user)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.create_pdks_challenge(text, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_pdks_challenge(text, text, jsonb)
  to service_role;

-- Challenge'ı OKUR (tüketmez): geçerliyse PDKS token'ını ve kullanıcı
-- nesnesini döner.
--
-- Okuma ile tüketme bilerek ayrı. Tek adımda tüketseydik kullanıcı SMS
-- kodunu yanlış yazdığında challenge yanar ve parolayı baştan girmek
-- zorunda kalırdı — kod girişinde yazım hatası sık görülüyor.
create or replace function public.read_pdks_challenge(p_id uuid)
returns table (pdks_token text, pdks_user jsonb)
language sql
security definer
set search_path = private, public
as $$
  select c.pdks_token, c.pdks_user
  from private.pdks_challenges c
  where c.id = p_id
    and c.consumed_at is null
    and c.expires_at > now();
$$;

revoke all on function public.read_pdks_challenge(uuid)
  from public, anon, authenticated;
grant execute on function public.read_pdks_challenge(uuid) to service_role;

-- Challenge'ı tüketir. Kod PDKS'de doğrulandıktan SONRA çağrılır.
--
-- Koşullu UPDATE atomik: aynı challenge ile eşzamanlı iki istek gelirse
-- yalnızca biri satır döndürür, diğeri boş alır ve reddedilir. Yani
-- doğrulamayı okuma adımına ayırmak tekrar kullanımı mümkün kılmıyor.
create or replace function public.consume_pdks_challenge(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_ok boolean;
begin
  update private.pdks_challenges c
     set consumed_at = now()
   where c.id = p_id
     and c.consumed_at is null
     and c.expires_at > now()
  returning true into v_ok;

  return coalesce(v_ok, false);
end;
$$;

revoke all on function public.consume_pdks_challenge(uuid)
  from public, anon, authenticated;
grant execute on function public.consume_pdks_challenge(uuid) to service_role;
