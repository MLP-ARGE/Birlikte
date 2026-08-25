-- Giriş akışı ve ayrıcalıklı işlemler.
--
-- Akış (Figma prototipi):
--   login → sms-verification → welcome → institution-match →
--   interest-selection → home
--
-- Kritik: "bu telefon/TCKN bordroda var mı" sorgusu İSTEMCİYE AÇILAMAZ.
-- Açılırsa (a) çalışan listesi numara deneyerek çıkarılabilir,
-- (b) KVKK açısından yetkisiz veri işleme olur. Bu yüzden arama
-- SECURITY DEFINER fonksiyonla yapılır ve fonksiyon çalışanın verisini
-- DEĞİL, yalnızca "eşleşti mi" bilgisini ve maskelenmiş telefonu döndürür.

-- Giriş denemelerini sınırlamak için (numara deneme saldırısı).
create table private.login_attempts (
  id          bigserial primary key,
  -- Girilen değerin özeti; ham telefon/TCKN loglanmıyor.
  identifier_hash bytea not null,
  ip_address  inet,
  succeeded   boolean not null,
  attempted_at timestamptz not null default now()
);

create index login_attempts_recent_idx
  on private.login_attempts (identifier_hash, attempted_at desc);

-- Telefon veya TCKN ile bordro kaydını arar.
--
-- Dönen değer bilinçli olarak fakir: eşleşme varsa OTP'nin gideceği
-- maskelenmiş numara, yoksa found=false. Çağıran taraf hangi durumda
-- olursa olsun aynı süreyi ve aynı biçimi görür.
create or replace function private.lookup_employee(
  p_identifier text,
  p_ip         inet default null
)
returns table (
  found          boolean,
  employee_id    uuid,
  phone          text,
  masked_phone   text
)
language plpgsql
security definer
set search_path = private, public, extensions
as $$
declare
  v_phone      text;
  v_hash       bytea;
  v_emp        private.employees%rowtype;
  v_recent     integer;
  v_id_hash    bytea;
begin
  v_id_hash := extensions.digest(coalesce(p_identifier, ''), 'sha256');

  -- Son 15 dakikada 5'ten fazla başarısız deneme varsa reddet.
  select count(*) into v_recent
  from private.login_attempts
  where identifier_hash = v_id_hash
    and not succeeded
    and attempted_at > now() - interval '15 minutes';

  if v_recent >= 5 then
    raise exception 'Çok fazla deneme yapıldı, lütfen sonra tekrar deneyin'
      using errcode = 'P0001';
  end if;

  -- Girdi telefon mu TCKN mi?
  v_phone := private.normalize_phone(p_identifier);

  if v_phone is not null then
    select * into v_emp
    from private.employees e
    where e.phone = v_phone and e.status = 'active'
    limit 1;
  elsif private.is_valid_tckn(p_identifier) then
    v_hash := private.hash_tckn(p_identifier);
    select * into v_emp
    from private.employees e
    where e.tckn_hash = v_hash and e.status = 'active'
    limit 1;
  end if;

  insert into private.login_attempts (identifier_hash, ip_address, succeeded)
  values (v_id_hash, p_ip, v_emp.id is not null);

  if v_emp.id is null then
    return query select false, null::uuid, null::text, null::text;
  else
    return query select
      true,
      v_emp.id,
      v_emp.phone,
      -- "+90 532 *** ** 48" — Figma'daki maske.
      '+90 ' || substr(v_emp.phone, 4, 3) || ' *** ** ' || right(v_emp.phone, 2);
  end if;
end;
$$;

revoke all on function private.lookup_employee(text, inet) from public, anon, authenticated;

-- OTP doğrulandıktan sonra auth kullanıcısını bordro kaydına bağlar ve
-- profili oluşturur. Yalnızca Edge Function (service_role) çağırır.
create or replace function private.link_profile(
  p_user_id     uuid,
  p_employee_id uuid
)
returns public.profiles
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_emp     private.employees%rowtype;
  v_profile public.profiles%rowtype;
begin
  select * into v_emp from private.employees where id = p_employee_id;
  if not found then
    raise exception 'Çalışan kaydı bulunamadı';
  end if;

  if v_emp.status <> 'active' then
    raise exception 'Çalışan kaydı aktif değil';
  end if;

  insert into public.profiles (
    id, employee_id, full_name, employee_no,
    institution_id, department, region, facility
  )
  values (
    p_user_id, v_emp.id, v_emp.full_name, v_emp.employee_no,
    v_emp.institution_id, v_emp.department, v_emp.region, v_emp.facility
  )
  on conflict (id) do update set
    -- Yeniden girişte bordro alanlarını tazele (İK'da değişmiş olabilir).
    full_name      = excluded.full_name,
    employee_no    = excluded.employee_no,
    institution_id = excluded.institution_id,
    department     = excluded.department,
    region         = excluded.region,
    facility       = excluded.facility,
    updated_at     = now()
  returning * into v_profile;

  -- Bildirim tercihleri varsayılanlarla açılsın.
  insert into public.notification_preferences (profile_id)
  values (p_user_id)
  on conflict (profile_id) do nothing;

  return v_profile;
end;
$$;

revoke all on function private.link_profile(uuid, uuid) from public, anon, authenticated;

-- ------------------------------------------------- PostgREST sarmalayıcıları
-- Edge Function'lar supabase-js ile `rpc()` çağırıyor; PostgREST yalnızca
-- YAYINLANAN şemalardaki (public) fonksiyonları görür. `private` şeması
-- API'ye kapalı olduğundan oradaki fonksiyonlar doğrudan çağrılamaz.
--
-- Bu sarmalayıcılar public'te durur ama anon/authenticated için yetkisizdir:
-- yalnızca service_role (Edge Function) çalıştırabilir.

create or replace function public.lookup_employee(
  p_identifier text,
  p_ip         inet default null
)
returns table (
  found        boolean,
  employee_id  uuid,
  phone        text,
  masked_phone text
)
language sql
security definer
set search_path = private, public
as $$
  select * from private.lookup_employee(p_identifier, p_ip);
$$;

revoke all on function public.lookup_employee(text, inet) from public, anon, authenticated;
grant execute on function public.lookup_employee(text, inet) to service_role;

create or replace function public.link_profile(
  p_user_id     uuid,
  p_employee_id uuid
)
returns public.profiles
language sql
security definer
set search_path = private, public
as $$
  select * from private.link_profile(p_user_id, p_employee_id);
$$;

revoke all on function public.link_profile(uuid, uuid) from public, anon, authenticated;
grant execute on function public.link_profile(uuid, uuid) to service_role;

-- ------------------------------------------------------------ kupon üretimi
-- Okunabilir, tahmin edilemez kupon kodu.
--
-- Not: Postgres'in encode() fonksiyonu base32 desteklemez (yalnızca
-- base64/hex/escape), o yüzden alfabe elle uygulanıyor. Karışabilecek
-- karakterler (I, O, 0, 1) alfabede yok — kullanıcı kodu telefonda okuyup
-- kasada söyleyecek.
create or replace function private.generate_coupon_code()
returns text
language plpgsql
volatile
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- 32 karakter
  bytes    bytea := extensions.gen_random_bytes(10);
  result   text := '';
  i        integer;
begin
  for i in 0..9 loop
    -- 256 % 32 = 0 olduğu için modulo sapması yok, dağılım düzgün.
    result := result || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;

  return 'BRLKT-' || substr(result, 1, 5) || '-' || substr(result, 6, 5);
end;
$$;


-- Kod üretimi, kontenjan ve kişi başı limit kontrolü tek bir işlemde.
-- İstemciye açık (authenticated), ama tüm kuralları kendisi uyguluyor.
create or replace function public.create_coupon(p_campaign_id uuid)
returns public.coupons
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_profile_id uuid := auth.uid();
  v_campaign   public.campaigns%rowtype;
  v_issued     integer;
  v_total      integer;
  v_coupon     public.coupons%rowtype;
  v_code       text;
begin
  if v_profile_id is null then
    raise exception 'Oturum bulunamadı' using errcode = '28000';
  end if;

  -- Kampanyayı kilitleyerek al: eşzamanlı iki istek kontenjanı aşamasın.
  select * into v_campaign
  from public.campaigns
  where id = p_campaign_id
  for update;

  if not found then
    raise exception 'Kampanya bulunamadı';
  end if;

  if v_campaign.status <> 'active' or now() not between v_campaign.starts_at and v_campaign.ends_at then
    raise exception 'Kampanya aktif değil';
  end if;

  -- Kuruma özel kampanyada kullanıcının kurumu tutmalı.
  if v_campaign.institution_id is not null
     and v_campaign.institution_id <> private.current_institution_id() then
    raise exception 'Bu kampanya kurumunuza açık değil';
  end if;

  select count(*) into v_issued
  from public.coupons
  where profile_id = v_profile_id
    and campaign_id = p_campaign_id
    and status <> 'cancelled';

  if v_issued >= v_campaign.per_user_limit then
    raise exception 'Bu kampanyadan zaten yararlandınız';
  end if;

  if v_campaign.total_quota is not null then
    select count(*) into v_total
    from public.coupons
    where campaign_id = p_campaign_id and status <> 'cancelled';

    if v_total >= v_campaign.total_quota then
      raise exception 'Kampanya kontenjanı doldu';
    end if;
  end if;

  v_code := private.generate_coupon_code();

  insert into public.coupons (profile_id, campaign_id, code, expires_at)
  values (
    v_profile_id, p_campaign_id, v_code,
    least(now() + v_campaign.coupon_ttl, v_campaign.ends_at)
  )
  returning * into v_coupon;

  return v_coupon;
end;
$$;

grant execute on function public.create_coupon(uuid) to authenticated;

comment on function public.create_coupon is
  'Kupon üretiminin tek yolu. Kod üretimi, kontenjan ve kişi başı limit '
  'kontrolü burada; istemci coupons tablosuna doğrudan yazamaz.';
