-- Row Level Security.
--
-- Kural: public şemasındaki HER tabloda RLS açık ve en az bir politika var.
-- Politikasız + RLS açık tablo = kimse okuyamaz (güvenli varsayılan), ama
-- sessizce boş liste döndüğü için burada her tabloyu açıkça ele alıyoruz.

alter table public.institutions            enable row level security;
alter table public.interest_categories     enable row level security;
alter table public.legal_documents         enable row level security;
alter table public.profiles                enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.profile_interests       enable row level security;
alter table public.consents                enable row level security;
alter table public.devices                 enable row level security;
alter table public.brands                  enable row level security;
alter table public.campaigns               enable row level security;
alter table public.campaign_branches       enable row level security;
alter table public.campaign_favorites      enable row level security;
alter table public.coupons                 enable row level security;
alter table public.point_entries           enable row level security;
alter table public.family_members          enable row level security;
alter table public.hospitals               enable row level security;
alter table public.blood_requests          enable row level security;
alter table public.blood_request_supports  enable row level security;
alter table public.blood_donations         enable row level security;

-- Giriş yapmış kullanıcının kurum kimliği. RLS içinde profiles'a doğrudan
-- select yazmak politikaların birbirini tetiklemesine yol açtığı için
-- SECURITY DEFINER yardımcı kullanılıyor. STABLE olduğundan sorgu başına
-- bir kez değerlendirilir.
create or replace function private.current_institution_id()
returns smallint
language sql
stable
security definer
set search_path = public, private
as $$
  select institution_id from public.profiles where id = auth.uid();
$$;

-- Referans/katalog tabloları: giriş yapmış herkes okur, kimse yazmaz.
-- (Yazma yalnızca service_role ile; RLS service_role'u atlar.)
create policy institutions_read on public.institutions
  for select to authenticated using (true);

create policy interest_categories_read on public.interest_categories
  for select to authenticated using (is_active);

create policy legal_documents_read on public.legal_documents
  for select to authenticated using (true);

create policy brands_read on public.brands
  for select to authenticated using (true);

create policy hospitals_read on public.hospitals
  for select to authenticated using (is_active);

-- ------------------------------------------------------------- profiles
-- Kullanıcı yalnızca kendi profilini görür.
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (id = auth.uid());

-- Güncelleme serbest DEĞİL: bordrodan gelen alanlar (ad, sicil, kurum,
-- departman) istemci tarafından değiştirilemez.
--
-- Bunu WITH CHECK içinde alt sorguyla yapmak CAZİP ama YANLIŞ: bir
-- politikanın kendi tablosunu sorgulaması sonsuz özyinelemeye yol açar
-- (Postgres'te belgelenmiş tuzak). Bu yüzden kolon kilidi tetikleyiciyle
-- uygulanıyor — politika yalnızca "kendi satırın mı" sorusunu yanıtlıyor.
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Bordro alanları istemci güncellemesinde eski değerine sabitlenir.
-- service_role (İK senkronu, link_profile) bu tetikleyiciyi atlar.
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

  return new;
end;
$$;

create trigger profiles_lock_payroll
  before update on public.profiles
  for each row execute function private.lock_payroll_columns();

-- INSERT politikası yok: profil yalnızca giriş Edge Function'ı tarafından
-- (service_role ile) oluşturulur.

-- --------------------------------------------- kullanıcıya ait alt tablolar
create policy notification_preferences_own on public.notification_preferences
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy profile_interests_own on public.profile_interests
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy devices_own on public.devices
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy campaign_favorites_own on public.campaign_favorites
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

create policy family_members_own on public.family_members
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- Rızalar: okunur ve eklenir, ama DEĞİŞTİRİLEMEZ/SİLİNEMEZ.
-- KVKK ispat yükümlülüğü geçmişin korunmasını gerektiriyor.
create policy consents_select_own on public.consents
  for select to authenticated using (profile_id = auth.uid());

create policy consents_insert_own on public.consents
  for insert to authenticated with check (profile_id = auth.uid());

-- ------------------------------------------------------------ kampanyalar
-- Yayında olan ve kullanıcının kurumuna açık kampanyalar görünür.
create policy campaigns_read_visible on public.campaigns
  for select to authenticated
  using (
    status = 'active'
    and now() between starts_at and ends_at
    and (institution_id is null
         or institution_id = private.current_institution_id())
  );

create policy campaign_branches_read on public.campaign_branches
  for select to authenticated
  using (
    exists (
      select 1 from public.campaigns c
      where c.id = campaign_id
        and c.status = 'active'
        and (c.institution_id is null
             or c.institution_id = private.current_institution_id())
    )
  );

-- ---------------------------------------------------------------- kuponlar
-- Kullanıcı kendi kuponlarını okur. Oluşturma ve "kullanıldı" işaretleme
-- sunucuda yapılır (kod üretimi, kontenjan ve limit kontrolü istemciye
-- bırakılamaz), bu yüzden insert/update politikası YOK.
create policy coupons_select_own on public.coupons
  for select to authenticated
  using (profile_id = auth.uid());

-- ------------------------------------------------------------------ puan
-- Defter yalnızca okunur. Puan yazma yetkisi kesinlikle sunucuda.
create policy point_entries_select_own on public.point_entries
  for select to authenticated
  using (profile_id = auth.uid());

-- ---------------------------------------------------------------- Kandaş
-- Açık talepler herkese görünür (uygulamanın amacı bu), kapananlar yalnızca
-- sahibine.
create policy blood_requests_read on public.blood_requests
  for select to authenticated
  using (status = 'open' or profile_id = auth.uid());

create policy blood_requests_insert_own on public.blood_requests
  for insert to authenticated
  with check (profile_id = auth.uid());

create policy blood_requests_update_own on public.blood_requests
  for update to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- Destek olanlar: kullanıcı kendi desteğini görür; talep sahibi de
-- kendi talebine gelen destekleri görür (Figma: "blood-supporters").
create policy blood_request_supports_read on public.blood_request_supports
  for select to authenticated
  using (
    profile_id = auth.uid()
    or exists (
      select 1 from public.blood_requests r
      where r.id = request_id and r.profile_id = auth.uid()
    )
  );

create policy blood_request_supports_insert_own on public.blood_request_supports
  for insert to authenticated
  with check (profile_id = auth.uid());

create policy blood_donations_select_own on public.blood_donations
  for select to authenticated
  using (profile_id = auth.uid());
