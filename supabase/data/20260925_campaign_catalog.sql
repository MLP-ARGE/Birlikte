-- Kampanya kataloğu içeriği — Figma'nın 24 Eylül 2026 güncellemesi.
--
-- Bu bir MIGRATION DEĞİLDİR, bilerek. Şema değişikliği içermiyor; yalnızca
-- içerik. Migration'a konsaydı supabase/tests/run.sh'in kurduğu temiz
-- veritabanına da girer ve testlerin kendi kurguladığı kampanya sayımlarını
-- bozardı (nitekim ilk denemede bozdu: "beklenen 2, gelen 9").
--
-- Canlıya elle uygulanır:
--   psql "$CONNSTR" -f supabase/data/20260925_campaign_catalog.sql
--
-- Tekrar çalıştırılabilir: hepsi upsert ya da koşullu update.

-- ---------------------------------------------------------------- markalar
insert into public.brands (slug, name, category_label) values
  ('camlica-kulesi',        'Çamlıca Kulesi',        'Gezi & Deneyim'),
  ('cookshop',              'Cookshop',              'Yeme & İçme'),
  ('maltepe-american-vip',  'Maltepe American VIP',  'Yabancı Dil Eğitimi'),
  ('the-open-air',          'The Open Air',          'Etkinlik & Konser'),
  ('villafors-resort',      'VillaFors Resort',      'Konaklama'),
  ('wish-english',          'Wish English',          'Online İngilizce')
on conflict (slug) do update set
  name = excluded.name, category_label = excluded.category_label;

-- Kärcher tasarımda kaldı; adı ve kategorisi güncellendi.
update public.brands
   set name = 'Kärcher Türkiye', category_label = 'Ev & Bahçe Ürünleri'
 where slug = 'karcher';

-- ------------------------------------------------------ eski kampanyalar
-- Yeni tasarımda yeri olmayanlar yayından kalkıyor.
update public.campaigns set status = 'ended'
 where slug in (
   'arabam-garaj', 'dod-ikinci-el', 'enuygun-seyahat', 'istinye-yuksek-lisans',
   'liv-koleji-egitim', 'mlpcare-psikolog', 'opet-akaryakit', 'petcity-mama',
   'starbucks-buyuk-boy'
 );

-- ------------------------------------------------------- yeni kampanyalar
-- Metinler Figma'daki detay ekranlarından birebir alındı.
-- institution_id null: hepsi tüm MLPCARE çalışanlarına açık ("Tüm
-- Çalışanlara Özel" / "Çalışan + 3 Kişi").
-- hero_image_path ayrı bir adımda yazılıyor (görseller Storage'a yüklenince).

insert into public.campaigns (
  slug, brand_id, category_id, title, discount_label, discount_percent,
  description, status, starts_at, ends_at, per_user_limit, tags, rules
) values
(
  'camlica-kulesi-ziyaret',
  (select id from public.brands where slug = 'camlica-kulesi'),
  9, 'Çamlıca Kulesi Biletli Ziyaretlerde %25 Ayrıcalık', '%25', 25,
  'MLPCare çalışanları, Çamlıca Kulesi''ndeki biletli ziyaretlerde %25 '
  'ayrıcalıktan yararlanabilir. Kapsama Seyir Terası, Seyyah 360, Kule '
  'Lounge ve Hedef Ay (Uzay Simülasyonu) dâhil.',
  'active', now(), now() + interval '1 year', 1,
  array['Kimlikle Geçerli','Çalışan + 3 Kişi','Etkinlik'],
  array['Geçerlilik: 1 yıl boyunca · Bilet gişesinde']
),
(
  'cookshop-restoran',
  (select id from public.brands where slug = 'cookshop'),
  1, 'Cookshop Restoranlarında %15 Ayrıcalık', '%15', 15,
  'Cookshop restoranlarında %15 ayrıcalıktan yararlanmak için Cookshoppers '
  'uygulamasını indir. Kurumsal Üyelik Doğrulama bölümünde MLPCare''i seç ve '
  'e-posta doğrulamanı tamamla. Hesabı öderken oluşturulan kodu Cookshop '
  'personeliyle paylaş.',
  'active', now(), now() + interval '1 year', 99,
  array['Uygulama ile','Tüm Çalışanlara Özel','Yeme & İçme'],
  array['Kod tek kullanımlıktır; her ziyarette yeni kod oluşturulur']
),
(
  'maltepe-american-vip-dil',
  (select id from public.brands where slug = 'maltepe-american-vip'),
  4, 'Yabancı Dil Eğitimlerinde %50 Ayrıcalık', '%50', 50,
  'Genel İngilizce, iş İngilizcesi, akademik İngilizce, çocuklara yönelik '
  'kurslar ve diğer yabancı dil eğitimleri dâhil tüm programlarda %50 '
  'ayrıcalık sunuluyor. Sana uygun program ve kayıt detayları için kurumla '
  'iletişime geçebilirsin.',
  'active', now(), now() + interval '1 year', 1,
  array['Eğitim','Tüm Çalışanlara Özel','Kayıtta Geçerli'],
  array['İletişim: 0216 212 55 75 · WhatsApp: 0532 729 55 75']
),
(
  'the-open-air-20',
  (select id from public.brands where slug = 'the-open-air'),
  9, 'The Open Air Biletlerinde %20 Ayrıcalık', '%20', 20,
  '20 Eylül''de Tuzla''da düzenlenen The Open Air''de Ceza, Can Bonomo ve '
  'M Lisa sahnede. MLPCare çalışanları Bubilet''te medicalpark koduyla '
  'biletlerde %20 ayrıcalıktan yararlanabilir.',
  'active', now(), now() + interval '1 year', 1,
  array['Kupon Kodlu','Tüm Çalışanlara Özel','Etkinlik'],
  array['Etkinlik: 20 Eylül · Tuzla']
),
(
  'the-open-air-30',
  (select id from public.brands where slug = 'the-open-air'),
  9, 'The Open Air Biletlerinde %30 Ayrıcalık', '%30', 30,
  '20 Eylül''de Tuzla''da düzenlenen The Open Air''de Ceza, Can Bonomo ve '
  'M Lisa sahnede. MLPCare çalışanları Bubilet''te medicalpark koduyla '
  'biletlerde %30 ayrıcalıktan yararlanabilir.',
  'active', now(), now() + interval '1 year', 1,
  array['Kupon Kodlu','Tüm Çalışanlara Özel','Etkinlik'],
  array['Etkinlik: 20 Eylül · Tuzla']
),
(
  'villafors-resort-konaklama',
  (select id from public.brands where slug = 'villafors-resort'),
  6, 'VillaFors Resort Konaklamada %30 Ayrıcalık', '%30', 30,
  'VillaFors Resort''ta MLPCare çalışanlarına özel %30 ayrıcalıkla konaklama '
  'seçeneklerini inceleyebilirsin. Havuz, açık büfe kahvaltı, canlı müzik ve '
  'barbekü alanları seni bekliyor.',
  'active', now(), timestamptz '2027-12-31 23:59:59+03', 1,
  array['Rezervasyonla','Tüm Çalışanlara Özel','Seyahat'],
  array['Geçerlilik: 31 Aralık 2027''ye kadar']
),
(
  'wish-english-online',
  (select id from public.brands where slug = 'wish-english'),
  4, 'Online İngilizce Derslerinde %45 Ayrıcalık', '%45', 45,
  'Online hızlandırılmış özel ders, bire bir İngilizce dersi ve çocuklara '
  'yönelik ders seçeneklerinde %45 ayrıcalığı inceleyebilirsin. Ücretsiz '
  'deneme dersi hakkında da bilgi alabilirsin.',
  'active', now(), timestamptz '2026-10-31 23:59:59+03', 1,
  array['Eğitim','Tüm Çalışanlara Özel','Online'],
  array['Son başvuru: 31 Ekim 2026']
)
on conflict (slug) do update set
  brand_id         = excluded.brand_id,
  category_id      = excluded.category_id,
  title            = excluded.title,
  discount_label   = excluded.discount_label,
  discount_percent = excluded.discount_percent,
  description      = excluded.description,
  status           = excluded.status,
  ends_at          = excluded.ends_at,
  tags             = excluded.tags,
  rules            = excluded.rules,
  updated_at       = now();

-- Kärcher tasarımda kaldı ama metni ve kategorisi değişti (Alışveriş).
update public.campaigns set
  category_id      = 2,
  title            = 'Kärcher Ev & Bahçe Ürünlerinde %20 Ayrıcalık',
  discount_label   = '%20',
  discount_percent = 20,
  description      = 'Kärcher''in resmi Türkiye sitesindeki Ev & Bahçe '
                     'ürünlerinde MLPCARETE20 koduyla %20 ayrıcalıktan '
                     'yararlanabilirsin. Kod, sitedeki mevcut kampanyalara '
                     'ek olarak kullanılabilir.',
  status           = 'active',
  ends_at          = timestamptz '2026-10-31 23:59:59+03',
  tags             = array['Kupon Kodlu','Tüm Çalışanlara Özel','Alışveriş'],
  rules            = array['Geçerlilik: 1 Temmuz – 31 Ekim 2026 · Stoklarla sınırlı'],
  updated_at       = now()
 where slug = 'karcher-ev-bahce';
