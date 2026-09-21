-- Eşlenmemiş şube girişi engellemesin.
--
-- Önceki davranış: şube kodu pdks_branch_map'te yoksa link_pdks_profile
-- hata veriyordu. Gerekçesi kampanya görünürlüğünün kuruma bağlı olması ve
-- yanlış kurumun kullanıcıya başka kurumun kampanyalarını göstermesiydi.
--
-- Ama bu, eşleme listesi tamamlanana kadar o şubedeki hiç kimsenin giriş
-- yapamaması demek — kabul edilemez bir bedel. Artık varsayılan kuruma
-- düşüyoruz.
--
-- Sessiz düşmüyoruz: eşlemesi olmayan şube, is_confirmed=false olarak
-- pdks_branch_map'e KENDİSİ yazılıyor. Böylece düzeltilmesi gereken şubelerin
-- listesi kendiliğinden birikiyor:
--   select * from public.pdks_branch_map where not is_confirmed;

-- Varsayılan kurum. Ayrı bir fonksiyonda duruyor ki değiştirmek gerektiğinde
-- tek yer olsun.
create or replace function private.default_institution_id()
returns smallint
language sql
immutable
as $$ select 1::smallint $$;  -- Medical Park

comment on function private.default_institution_id is
  'Şube eşlemesi bulunamadığında kullanılan kurum. Geçici bir çözümdür: '
  'kampanya görünürlüğü kuruma bağlı olduğu için eşleme tamamlanmalıdır.';

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
  select institution_id into v_institution_id
  from public.pdks_branch_map where branch_code = p_branch_code;

  if v_institution_id is null then
    v_institution_id := private.default_institution_id();

    -- Şubeyi doğrulanmamış olarak kaydet ki hangi kodların eşlenmesi
    -- gerektiği sonradan sorgulanabilsin. Şube adını da yazıyoruz;
    -- listeyi okuyan kişi kodun neye karşılık geldiğini görebilsin.
    if p_branch_code is not null then
      insert into public.pdks_branch_map
        (branch_code, branch_name, institution_id, is_confirmed)
      values (p_branch_code, p_facility, v_institution_id, false)
      on conflict (branch_code) do nothing;

      raise warning 'Şube % (%) eşlenmemiş, varsayılan kuruma atandı',
        p_branch_code, coalesce(p_facility, '?');
    end if;
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

-- Eşlenmesi bekleyen şubeleri tek sorguda görmek için.
create or replace view public.pdks_unmapped_branches as
  select branch_code, branch_name, institution_id
  from public.pdks_branch_map
  where not is_confirmed
  order by branch_code;

comment on view public.pdks_unmapped_branches is
  'Girişte varsayılan kuruma atanmış şubeler. Boşalana kadar iş bitmemiştir.';
