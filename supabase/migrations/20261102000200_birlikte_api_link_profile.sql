-- birlikte-api profil bağlama RPC'si.
--
-- link_pdks_profile'ın aynı deseni: private.employees'ten değil, doğrudan
-- GET /api/me yanıtından okur. Ayrı bir fonksiyon olmasının sebebi, iki
-- entegrasyonun ("tut" kararıyla ikisi de kodda) birbirinin alanlarını
-- ezmemesi.
--
-- İlgi alanları (ilgiAlanlari) burada YAZILMIYOR: karar gereği birlikte-api
-- bu konuda tek kaynak, istemci ilgi alanlarını doğrudan
-- GET/PUT /api/ilgi-alanlari ile okuyup yazıyor. public.profile_interests
-- tablosu bu akışta kullanılmıyor.
create or replace function private.link_birlikte_profile(
  p_user_id            uuid,
  p_kullanici_id        bigint,
  p_ad                 text,
  p_soyad              text,
  p_eposta             text,
  p_kurum_kodu          text,
  p_kurum_adi           text,
  p_sube_kodu           text,
  p_sube_adi            text,
  p_departman           text,
  p_unvan              text,
  p_kayit_tipi          text,
  p_cinsiyet            text
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
  from public.birlikte_kurum_map where kurum_kodu = p_kurum_kodu;

  if v_institution_id is null then
    -- Eşlemesi olmayan kurumKodu varsayılana düşer ve kendini listeye
    -- yazar (bkz. pdks_branch_map'teki aynı güvenlik ağı). Giriş
    -- engellenmez; kampanya görünürlüğü düzeltme gelene kadar yanlış kalır.
    v_institution_id := private.default_institution_id();

    if p_kurum_kodu is not null then
      insert into public.birlikte_kurum_map
        (kurum_kodu, kurum_adi, institution_id, is_confirmed)
      values (p_kurum_kodu, p_kurum_adi, v_institution_id, false)
      on conflict (kurum_kodu) do nothing;

      raise warning 'kurumKodu % (%) eşlenmemiş, varsayılan kuruma atandı',
        p_kurum_kodu, coalesce(p_kurum_adi, '?');
    end if;
  end if;

  insert into public.profiles (
    id, employee_id, full_name, institution_id, department, facility,
    position, email, birlikte_kullanici_id, kurum_kodu, sube_kodu,
    sube_adi, kayit_tipi, cinsiyet
  )
  values (
    p_user_id, null, trim(concat_ws(' ', p_ad, p_soyad)), v_institution_id,
    p_departman, p_sube_adi, p_unvan, p_eposta, p_kullanici_id, p_kurum_kodu,
    p_sube_kodu, p_sube_adi, p_kayit_tipi, p_cinsiyet
  )
  on conflict (id) do update set
    full_name              = excluded.full_name,
    institution_id         = excluded.institution_id,
    department             = excluded.department,
    facility               = excluded.facility,
    position               = excluded.position,
    email                  = excluded.email,
    birlikte_kullanici_id  = excluded.birlikte_kullanici_id,
    kurum_kodu             = excluded.kurum_kodu,
    sube_kodu              = excluded.sube_kodu,
    sube_adi               = excluded.sube_adi,
    kayit_tipi             = excluded.kayit_tipi,
    cinsiyet               = coalesce(excluded.cinsiyet, public.profiles.cinsiyet),
    updated_at             = now()
  returning * into v_profile;

  insert into public.notification_preferences (profile_id)
  values (p_user_id)
  on conflict (profile_id) do nothing;

  return v_profile;
end;
$$;

revoke all on function private.link_birlikte_profile(
  uuid, bigint, text, text, text, text, text, text, text, text, text, text, text
) from public, anon, authenticated;

-- PostgREST sarmalayıcısı — yalnızca service_role (Edge Function).
create or replace function public.link_birlikte_profile(
  p_user_id            uuid,
  p_kullanici_id        bigint,
  p_ad                 text,
  p_soyad              text,
  p_eposta             text,
  p_kurum_kodu          text,
  p_kurum_adi           text,
  p_sube_kodu           text,
  p_sube_adi            text,
  p_departman           text,
  p_unvan              text,
  p_kayit_tipi          text,
  p_cinsiyet            text
)
returns public.profiles
language sql
security definer
set search_path = public, private
as $$
  select private.link_birlikte_profile(
    p_user_id, p_kullanici_id, p_ad, p_soyad, p_eposta, p_kurum_kodu,
    p_kurum_adi, p_sube_kodu, p_sube_adi, p_departman, p_unvan,
    p_kayit_tipi, p_cinsiyet);
$$;

revoke all on function public.link_birlikte_profile(
  uuid, bigint, text, text, text, text, text, text, text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.link_birlikte_profile(
  uuid, bigint, text, text, text, text, text, text, text, text, text, text, text
) to service_role;

-- employee_no artık her zaman dolmuyor: birlikte-api'nin GET /api/me
-- yanıtında sicil/employee_no karşılığı bir alan yok (yalnızca kullaniciId,
-- PDKS'nin "sicil" alanından farklı bir kavram). employee_id'yi PDKS geçişinde
-- nullable yaptığımız gerekçenin aynısı burada da geçerli.
alter table public.profiles alter column employee_no drop not null;
