-- PDKS şube kodu → kurum eşlemesi (İK listesi, 1 Ekim 2026).
--
-- Bu eşleme İŞLEVSEL: kampanya görünürlüğü RLS'te kuruma göre filtreleniyor
-- (bkz. private.current_institution_id). Yanlış eşlenen bir şubenin çalışanı
-- başka kurumun kampanyalarını görür.
--
-- Migration değil, içerik betiği: liste İK'dan geliyor ve değiştikçe
-- uygulama derlemesi gerektirmemeli.
--
-- GroupName sütunu çoğu satır için yeterli ayrımı veriyor:
--   LIV -> Liv Hospital (2),  MLP/MER -> Medical Park (1)
-- İstisnalar aşağıda ayrıca işaretlendi.

insert into public.pdks_branch_map (branch_code, branch_name, institution_id, is_confirmed) values
  -- ---------------------------------------------------- Liv Hospital (LIV)
  ( 3785, 'Liv Ankara',               2, true),
  (10868, 'Liv Bona Dea Bakü',        2, true),
  ( 9327, 'Liv Gaziantep',            2, true),
  ( 6867, 'Liv Samsun',               2, true),
  ( 3404, 'Liv Ulus',                 2, true),
  ( 9688, 'Liv Vadi',                 2, true),

  -- ------------------------------------------------- Medical Park (MLP/MER)
  (  101, 'MLPCare Merkez',           1, true),
  (11889, 'Antalya Konuk Evi',        1, true),
  (10949, 'MP Adana',                 1, true),
  ( 6147, 'MP Ankara',                1, true),
  (11528, 'MP Ankara İncek',          1, true),
  (  105, 'MP Antalya',               1, true),
  (11669, 'MP Ataşehir',              1, true),
  (  103, 'MP Bahçelievler',          1, true),
  ( 9187, 'MP Çanakkale',             1, true),
  ( 2122, 'MP Gebze',                 1, true),
  (  102, 'MP Göztepe',               1, true),
  (11629, 'MP İzmir',                 1, true),
  (11750, 'MP Kosova',                1, true),
  (12469, 'MP Onkoloji',              1, true),
  ( 4187, 'MP Ordu',                  1, true),
  (10948, 'MP Seyhan',                1, true),
  (12249, 'MP Tem',                   1, true),
  (  108, 'MP Tokat',                 1, true),
  ( 4607, 'MP Trabzon Karadeniz',     1, true),
  ( 4327, 'MP Trabzon Yıldızlı',      1, true),
  ( 9427, 'VM-MP Ankara',             1, true),
  (  104, 'VM-MP Bursa',              1, true),
  (11689, 'VM-MP Fatih',              1, true),
  ( 6649, 'VM-MP Florya',             1, true),
  ( 4847, 'VM-MP Kocaeli',            1, true),
  ( 9227, 'VM-MP Maltepe',            1, true),
  ( 7627, 'VM-MP Mersin',             1, true),
  ( 7389, 'VM-MP Pendik',             1, true),
  (  114, 'VM-MP Samsun',             1, true)
on conflict (branch_code) do update
  set branch_name    = excluded.branch_name,
      institution_id = excluded.institution_id,
      is_confirmed   = excluded.is_confirmed;

-- -------------------------------------------- İSÜ adı geçen şubeler
-- Bu altı şubenin adında "İSÜ"/"Istinye" geçiyor ama kurum ataması
-- GroupName'e göre yapıldı (kararı İK verdi):
--   MLP grubundakiler -> Medical Park,  LIV grubundakiler -> Liv Hospital
--
-- Not: İstinye Üniversitesi (kurum 4) ve Liv Koleji (kurum 3) için listede
-- HİÇ şube yok. O kurumların çalışanları PDKS'de ayrı bir şube kodu
-- taşıyorsa eşlemeleri henüz tanımlı değil; giriş yapan ilk kişide kod
-- public.pdks_unmapped_branches listesine düşecek.
insert into public.pdks_branch_map (branch_code, branch_name, institution_id, is_confirmed) values
  (11809, 'Istinye Dental Hospital',  1, true),   -- MLP
  (12353, 'İSÜ GOP Diyaliz Merkezi',  1, true),   -- MLP
  ( 7827, 'İSÜ Medicalpark',          1, true),   -- MLP
  (12349, 'İSÜ Tıp Fakültesi',        1, true),   -- MLP
  ( 6468, 'Liv İSÜ Bahçeşehir',       2, true),   -- LIV
  (12090, 'Liv İSÜ Topkapı',          2, true)    -- LIV
on conflict (branch_code) do update
  set branch_name    = excluded.branch_name,
      institution_id = excluded.institution_id,
      is_confirmed   = excluded.is_confirmed;

-- Mevcut profilleri de düzelt: kurum ataması giriş anında yapılıyor, yoksa
-- daha önce giriş yapmış kullanıcılar bir sonraki girişlerine kadar eski
-- (varsayılana düşmüş) kurumlarında kalırdı.
update public.profiles p
   set institution_id = m.institution_id,
       updated_at     = now()
  from public.pdks_branch_map m
 where m.branch_code = p.branch_code
   and p.institution_id is distinct from m.institution_id;
