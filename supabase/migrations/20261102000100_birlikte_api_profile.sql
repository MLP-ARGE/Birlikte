-- birlikte-api entegrasyonu için profil alanları.
--
-- PDKS entegrasyonu "tut" kararıyla kodda kalıyor (pdks_username, branch_code
-- vb.); bu yüzden birlikte-api alanları ayrı adlarla ekleniyor, iki
-- entegrasyon birbirinin verisini ezmesin.
--
-- kullaniciId (API'nin /api/me yanıtındaki) JWT'deki `uid`/`sub` claim'iyle
-- aynı — giriş sırasında doğrulanan kimlik.
alter table public.profiles
  add column if not exists birlikte_kullanici_id bigint unique,
  add column if not exists kurum_kodu            text,
  add column if not exists sube_kodu             text,
  add column if not exists sube_adi              text,
  add column if not exists kayit_tipi            text,
  add column if not exists cinsiyet              text;

comment on column public.profiles.kayit_tipi is
  '/api/me''nin kayitTipi alanı: CALISAN, OGRENCI, vb. Aynı kişi birden '
  'fazla kayda sahip olabiliyor (çalışan + öğrenci + yakın); şimdilik yalnızca '
  'CALISAN kaydı işleniyor.';

-- Kilit tetikleyicisine dahil et: bu alanlar da PDKS alanları gibi yalnızca
-- service_role tarafından (Edge Function) yazılabilir.
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
  new.department      := old.department;
  new.region          := old.region;
  new.facility         := old.facility;

  new.pdks_username  := old.pdks_username;
  new.position       := old.position;
  new.email          := old.email;
  new.manager_name   := old.manager_name;
  new.branch_code    := old.branch_code;
  new.person_type    := old.person_type;
  new.hired_at       := old.hired_at;

  new.birlikte_kullanici_id := old.birlikte_kullanici_id;
  new.kurum_kodu            := old.kurum_kodu;
  new.sube_kodu             := old.sube_kodu;
  new.sube_adi              := old.sube_adi;
  new.kayit_tipi            := old.kayit_tipi;
  new.cinsiyet              := old.cinsiyet;

  return new;
end;
$$;

-- -------------------------------------------- kurum kodu → kurum eşlemesi
--
-- Eski pdks_branch_map'ten BİLEREK ayrı: o tablo PDKS'nin sayısal
-- subekodu'na göreydi (101, 3785...). Bu yeni API `kurumKodu` diye kısa bir
-- METİN kodu veriyor (örn. "MLP") — tamamen farklı bir anahtar uzayı.
--
-- Yalnızca canlı /api/me yanıtından doğrulanan "MLP" → Medical Park (1)
-- eşlemesi tohumlanıyor. LIV/İSÜ/Liv Koleji'nin kurumKodu değerlerini
-- TAHMİN ETMİYORUZ — geçen seferki yanlış tahmin (GroupName'den kurum
-- çıkarmak) düzeltme gerektirmişti. Aynı hatayı tekrarlamamak için
-- eşlemesi olmayan kod, giriş engellenmeden varsayılana düşüyor ve
-- kendini listeye yazıyor.
create table if not exists public.birlikte_kurum_map (
  kurum_kodu     text primary key,
  kurum_adi      text,
  institution_id smallint not null references public.institutions (id),
  is_confirmed   boolean not null default false
);

insert into public.birlikte_kurum_map (kurum_kodu, kurum_adi, institution_id, is_confirmed)
values ('MLP', 'MLP Care', 1, true)
on conflict (kurum_kodu) do nothing;

alter table public.birlikte_kurum_map enable row level security;
create policy birlikte_kurum_map_read on public.birlikte_kurum_map
  for select using (true);

create or replace view public.birlikte_unmapped_kurumlar as
  select kurum_kodu, kurum_adi, institution_id
  from public.birlikte_kurum_map
  where not is_confirmed
  order by kurum_kodu;

comment on view public.birlikte_unmapped_kurumlar is
  'Girişte varsayılan kuruma atanmış kurumKodu değerleri. Boşalana kadar '
  'iş bitmemiştir — bkz. pdks_unmapped_branches''daki aynı desen.';
