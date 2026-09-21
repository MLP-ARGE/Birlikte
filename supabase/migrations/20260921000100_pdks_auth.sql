-- Girişin PDKS'ye taşınması.
--
-- Artık kimliğin kaynağı MLPCARE'in PDKS servisi (pdksapilive.mlpcare.com).
-- Kullanıcı adı + parola ile giriş yapılıyor, ardından SMS kodu doğrulanıyor.
--
-- Supabase oturumu KORUNUYOR. Sebebi: kampanya, kupon, puan, favori ve aile
-- verilerinin tamamı RLS ile auth.uid() üzerinden korunuyor. Girişi tamamen
-- PDKS'ye taşısaydık bu politikaların dayanağı kalmaz, tüm veri erişimi
-- kırılırdı. Bu yüzden Edge Function PDKS'yi doğrular ve karşılığında bir
-- Supabase oturumu üretir — köprü deseni.

-- ---------------------------------------------------------------- profiles
--
-- private.employees artık zorunlu değil. O tablo bir bordro aynasıydı ve
-- TCKN özeti ile E.164 telefon istiyordu; PDKS ikisini de vermiyor (telefon
-- maskeli geliyor, TCKN hiç yok). PDKS ile giren kullanıcının orada karşılığı
-- olmayacak.
alter table public.profiles alter column employee_id drop not null;

alter table public.profiles
  add column if not exists pdks_username text unique,
  add column if not exists position      text,
  add column if not exists email         extensions.citext,
  add column if not exists manager_name  text,
  add column if not exists branch_code   smallint,
  add column if not exists person_type   text,
  add column if not exists hired_at      date;

comment on column public.profiles.pdks_username is
  'PDKS kullanıcı adı (örn. "merve.toz"). Kimliğin kararlı anahtarı.';
comment on column public.profiles.region is
  'PDKS bu alanı döndürmüyor; bordro senkronu gelene kadar null kalır. '
  'Profil ekranı null durumunu ele almalı.';

-- Yeni alanlar da bordro alanları gibi kullanıcıya kapalı: PDKS'den gelir,
-- uygulama düzenletmez. Kilit tetikleyicisini genişletiyoruz.
create or replace function private.lock_payroll_columns()
returns trigger
language plpgsql
as $$
begin
  if current_setting('request.jwt.claim.role', true) = 'service_role'
     or current_user = 'service_role' then
    return new;
  end if;

  new.employee_id    := old.employee_id;
  new.full_name      := old.full_name;
  new.employee_no    := old.employee_no;
  new.institution_id := old.institution_id;
  new.department     := old.department;
  new.region         := old.region;
  new.facility       := old.facility;

  -- PDKS kaynaklı alanlar.
  new.pdks_username  := old.pdks_username;
  new.position       := old.position;
  new.email          := old.email;
  new.manager_name   := old.manager_name;
  new.branch_code    := old.branch_code;
  new.person_type    := old.person_type;
  new.hired_at       := old.hired_at;

  return new;
end;
$$;

-- ------------------------------------------------------- şube → kurum eşlemesi
--
-- Kod olarak değil TABLO olarak tutuluyor: eşleme listesi İK'dan parça parça
-- geliyor, her gelişinde uygulama derlemesi yapmak istemiyoruz.
--
-- Kampanya görünürlüğü kuruma göre filtrelendiği için (bkz. RLS
-- private.current_institution_id) buradaki hata kullanıcıya yanlış kampanya
-- gösterir — yani işlevsel, kozmetik değil.
create table if not exists public.pdks_branch_map (
  branch_code    smallint primary key,
  branch_name    text,
  institution_id smallint not null references public.institutions (id),
  -- Gerçek eşleme mi, yoksa liste gelene kadar konmuş geçici değer mi?
  is_confirmed   boolean not null default false
);

comment on table public.pdks_branch_map is
  'PDKS subekodu → kurum. is_confirmed=false olan satırlar İK listesi '
  'gelmeden konmuş geçici eşlemelerdir, doğrulanmaları gerekir.';

insert into public.pdks_branch_map (branch_code, branch_name, institution_id, is_confirmed) values
  (101, 'Medical Park Merkez', 1, true)   -- canlı yanıttan doğrulandı
on conflict (branch_code) do nothing;

alter table public.pdks_branch_map enable row level security;

-- Okuma serbest: gizli bilgi değil, kurum listesi zaten herkese açık.
create policy pdks_branch_map_read on public.pdks_branch_map
  for select using (true);

-- --------------------------------------------------------- giriş oturumları
--
-- PDKS akışı iki adımlı: önce parola doğrulanıp token alınıyor, sonra SMS
-- kodu onaylanıyor. Aradaki PDKS token'ı CİHAZA İNMEMELİ — inseydi, SMS
-- adımını atlayıp doğrudan PDKS'ye istek atmak mümkün olurdu.
--
-- Bu yüzden token sunucuda tutuluyor, istemciye yalnızca rastgele bir
-- challenge kimliği dönüyor.
create table if not exists private.pdks_challenges (
  id          uuid primary key default gen_random_uuid(),
  username    text not null,
  pdks_token  text not null,
  -- Giriş yanıtındaki kullanıcı nesnesi; ikinci adımda tekrar sormamak için.
  pdks_user   jsonb not null,
  created_at  timestamptz not null default now(),
  -- SMS kodunun makul ömrü. Süresi geçen challenge kullanılamaz.
  expires_at  timestamptz not null default now() + interval '10 minutes',
  consumed_at timestamptz
);

create index if not exists pdks_challenges_expiry_idx
  on private.pdks_challenges (expires_at);

-- Süresi geçmiş kayıtları temizler; Edge Function her girişte çağırıyor.
create or replace function private.purge_expired_challenges()
returns void
language sql
security definer
set search_path = private
as $$
  delete from private.pdks_challenges
  where expires_at < now() - interval '1 hour';
$$;

-- --------------------------------------------------------- profil bağlama
--
-- PDKS'den gelen kullanıcı bilgisiyle profili oluşturur/günceller.
-- link_profile'ın PDKS karşılığı: orası private.employees'ten okuyordu,
-- burada veri doğrudan PDKS yanıtından geliyor.
create or replace function private.link_pdks_profile(
  p_user_id     uuid,
  p_username    text,
  p_full_name   text,
  p_employee_no text,
  p_branch_code smallint,
  p_department  text,
  p_facility    text,
  p_position    text,
  p_email       text,
  p_manager     text,
  p_person_type text,
  p_hired_at    date
)
returns public.profiles
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_institution_id smallint;
  v_profile        public.profiles%rowtype;
begin
  -- Eşleme yoksa varsayılana düşmüyoruz: yanlış kurum, kullanıcıya başka
  -- kurumun kampanyalarını göstermek demek. Açıkça hata veriyoruz ki eksik
  -- eşleme fark edilsin.
  select institution_id into v_institution_id
  from public.pdks_branch_map where branch_code = p_branch_code;

  if v_institution_id is null then
    raise exception 'Şube kodu % için kurum eşlemesi tanımlı değil', p_branch_code
      using errcode = 'no_data_found';
  end if;

  insert into public.profiles (
    id, employee_id, full_name, employee_no, institution_id,
    department, facility, pdks_username, position, email,
    manager_name, branch_code, person_type, hired_at
  )
  values (
    p_user_id, null, p_full_name, p_employee_no, v_institution_id,
    p_department, p_facility, p_username, p_position, p_email,
    p_manager, p_branch_code, p_person_type, p_hired_at
  )
  on conflict (id) do update set
    -- Her girişte tazele: PDKS'de departman/şube değişmiş olabilir.
    full_name      = excluded.full_name,
    employee_no    = excluded.employee_no,
    institution_id = excluded.institution_id,
    department     = excluded.department,
    facility       = excluded.facility,
    pdks_username  = excluded.pdks_username,
    position       = excluded.position,
    email          = excluded.email,
    manager_name   = excluded.manager_name,
    branch_code    = excluded.branch_code,
    person_type    = excluded.person_type,
    hired_at       = excluded.hired_at,
    updated_at     = now()
  returning * into v_profile;

  insert into public.notification_preferences (profile_id)
  values (p_user_id)
  on conflict (profile_id) do nothing;

  return v_profile;
end;
$$;

revoke all on function private.link_pdks_profile(
  uuid, text, text, text, smallint, text, text, text, text, text, text, date
) from public, anon, authenticated;

-- ------------------------------------------------- PostgREST sarmalayıcıları
-- private şeması API'ye kapalı; Edge Function'ın çağırabilmesi için public'te
-- sarmalayıcı gerekiyor. Yalnızca service_role çalıştırabilir.

create or replace function public.link_pdks_profile(
  p_user_id     uuid,
  p_username    text,
  p_full_name   text,
  p_employee_no text,
  p_branch_code smallint,
  p_department  text,
  p_facility    text,
  p_position    text,
  p_email       text,
  p_manager     text,
  p_person_type text,
  p_hired_at    date
)
returns public.profiles
language sql
security definer
set search_path = public, private
as $$
  select private.link_pdks_profile(
    p_user_id, p_username, p_full_name, p_employee_no, p_branch_code,
    p_department, p_facility, p_position, p_email, p_manager,
    p_person_type, p_hired_at);
$$;

revoke all on function public.link_pdks_profile(
  uuid, text, text, text, smallint, text, text, text, text, text, text, date
) from public, anon, authenticated;
grant execute on function public.link_pdks_profile(
  uuid, text, text, text, smallint, text, text, text, text, text, text, date
) to service_role;

-- ------------------------------------------------------------- avatarlar
--
-- PDKS profil fotoğrafını base64 JPEG olarak veriyor. Her açılışta 21 KB'lık
-- base64'ü veritabanından çekmek yerine bir kez Storage'a yazıp oradan
-- servis ediyoruz.
--
-- Bucket PRIVATE: çalışan fotoğrafı kişisel veridir, kampanya görseliyle
-- aynı kefeye konamaz. Kullanıcı yalnızca kendi fotoğrafını okuyabilir,
-- yazma yalnızca service_role'de (fotoğraf PDKS'den gelir, kullanıcı
-- yüklemez).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 2097152, array['image/jpeg','image/png'])
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Dosya adı kullanıcının kendi uuid'si: "{auth.uid()}.jpg". Politika da
-- bunu zorluyor, yani kimse başkasının fotoğrafını isteyemez.
drop policy if exists "avatars_read_own" on storage.objects;
create policy "avatars_read_own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'avatars'
    and name = auth.uid()::text || '.jpg'
  );
