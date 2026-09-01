-- Kampanya kategorilerini ilgi alanlarından ayır.
--
-- İlk tasarımda `campaigns.category_id` → `interest_categories` idi. Bu
-- yanlış: ikisi farklı taksonomi.
--   * interest_categories (17): kullanıcının seçtiği ilgi alanları
--     (Figma `interest-selection` — Müzik, Sanat, Yoga, Dans...).
--   * campaign_categories (8): kampanya listesinin filtre çipleri
--     (Figma `chips-row` ve `campaigns-*` kareleri — Alışveriş,
--     Otomotiv, Akaryakıt, Evcil Hayvan...).
--
-- Aynı tabloya bağlamak, kampanya filtresinde "Yoga" gibi anlamsız
-- seçenekler çıkmasına ve uygulamadaki CampaignCategory enum'ının
-- veritabanıyla eşleşmemesine yol açıyordu.

create table public.campaign_categories (
  id         smallint primary key,
  code       text not null unique,
  name       text not null,
  sort_order smallint not null default 0,
  is_active  boolean not null default true
);

-- Kodlar uygulamadaki CampaignCategory enum'ı ile birebir.
insert into public.campaign_categories (id, code, name, sort_order) values
  (1,'food_drink','Yeme & İçme',1),
  (2,'shopping','Alışveriş',2),
  (3,'health','Sağlık',3),
  (4,'education','Eğitim',4),
  (5,'automotive','Otomotiv',5),
  (6,'travel','Seyahat',6),
  (7,'fuel','Akaryakıt',7),
  (8,'pets','Evcil Hayvan',8);

alter table public.campaign_categories enable row level security;

create policy campaign_categories_read on public.campaign_categories
  for select to authenticated using (is_active);

-- Mevcut kampanyaları yeni taksonomiye taşı. Demo verisinde eski id'ler
-- interest_categories'e göre verilmişti; eşleyerek çeviriyoruz.
alter table public.campaigns drop constraint campaigns_category_id_fkey;

update public.campaigns set category_id = case category_id
  when 1  then 1   -- Yeme & İçme  → Yeme & İçme
  when 2  then 3   -- Sağlık       → Sağlık
  when 3  then 4   -- Eğitim       → Eğitim
  when 5  then 5   -- Teknoloji    → Otomotiv (demo: arabam/DOD)
  when 7  then 6   -- Sanat        → Seyahat  (demo: OPET yanlış eşlenmişti)
  when 8  then 6   -- Seyahat      → Seyahat
  when 13 then 8   -- Doğa         → Evcil Hayvan (demo: Petcity)
  else 2           -- kalanlar     → Alışveriş
end;

alter table public.campaigns
  add constraint campaigns_category_id_fkey
  foreign key (category_id) references public.campaign_categories (id);
