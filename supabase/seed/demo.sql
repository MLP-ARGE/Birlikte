-- Demo verisi: geliştirme ve gösterim için.
--
-- ÜRETİMDE ÇALIŞTIRMAYIN. TCKN'ler algoritmik olarak geçerli ama gerçek
-- kişilere ait değil; telefonlar Supabase'in test OTP listesiyle eşleşiyor.
--
-- Yeniden çalıştırılabilir (idempotent).

-- ---------------------------------------------------------- çalışanlar
insert into private.employees (
  employee_no, tckn_hash, tckn_last2, full_name, phone, email,
  institution_id, department, region, facility, status, hired_at
) values
  ('MP-9843102', private.hash_tckn('10000000078'), '78', 'Ayşe Yılmaz',
   '+905321234548', 'ayse.yilmaz@mlpcare.com', 1, 'Bilgi Teknolojileri',
   'İstanbul Bölge', 'Göztepe Hastanesi', 'active', '2023-03-01'),
  ('LH-5551234', private.hash_tckn('20000000046'), '46', 'Mehmet Demir',
   '+905339998877', 'mehmet.demir@mlpcare.com', 2, 'Radyoloji',
   'Ankara Bölge', 'Liv Hospital Ulus', 'active', '2024-01-15'),
  ('IU-7742001', private.hash_tckn('30000000014'), '14', 'Zeynep Kaya',
   '+905447776655', 'zeynep.kaya@mlpcare.com', 4, 'Öğrenci İşleri',
   'İstanbul Bölge', 'Topkapı Kampüsü', 'active', '2022-09-12')
on conflict (employee_no) do nothing;

-- --------------------------------------------------------------- markalar
insert into public.brands (id, slug, name, category_label) values
  ('b0000000-0000-4000-8000-000000000001','istinye-uni','İstinye Üniversitesi','Eğitim Kurumu'),
  ('b0000000-0000-4000-8000-000000000002','starbucks','Starbucks','Yeme & İçme'),
  ('b0000000-0000-4000-8000-000000000003','karcher','Kärcher Türkiye','Ev ve Bahçe Ürünleri'),
  ('b0000000-0000-4000-8000-000000000004','arabam','arabam.com','Garaj Oto Kuaför'),
  ('b0000000-0000-4000-8000-000000000005','liv-koleji','Liv Koleji','Eğitim Kurumu'),
  ('b0000000-0000-4000-8000-000000000006','mlpcare','MLPCare','Sağlık & Wellness'),
  ('b0000000-0000-4000-8000-000000000007','opet','OPET','Akaryakıt İstasyonları'),
  ('b0000000-0000-4000-8000-000000000008','enuygun','EnUygun','Seyahat & Konaklama'),
  ('b0000000-0000-4000-8000-000000000009','petcity','Petcity','Evcil Hayvan'),
  ('b0000000-0000-4000-8000-00000000000a','dod','DOD','İkinci El Araç Platformu')
on conflict (id) do nothing;

-- ------------------------------------------------------------ kampanyalar
-- category_id → public.campaign_categories (ilgi alanları DEĞİL).
insert into public.campaigns (
  id, slug, brand_id, category_id, title, discount_label, discount_percent,
  description, status, starts_at, ends_at, institution_id, points_cost,
  redemption, per_user_limit, tags, steps, who_qualifies, rules,
  cancellation_note
) values
  ('c0000000-0000-4000-8000-000000000001','istinye-yuksek-lisans',
   'b0000000-0000-4000-8000-000000000001', 4,
   'Yüksek Lisans Fırsatı %50 İndirimli','%50', 50,
   'MLP Care, Medical Park, Liv Hospital ve Liv Koleji çalışanlarına İstinye '
   'Üniversitesi yüksek lisans programlarında %50 indirim. Geçerli bölümler: '
   'Bilgisayar Mühendisliği, Yapay Zeka, İşletme Yüksek Lisans.',
   'active', now() - interval '30 days', now() + interval '45 days',
   null, null, 'online', 1,
   array['Eğitim','Tüm Çalışanlara Özel','Yüksek Lisans'],
   array['MLPCARE Birlikte uygulamasından başvuru formunu doldur.',
         'İstinye Üniversitesi kayıt ofisine başvurunu ilet.',
         'Kayıt tamamlandıktan sonra %50 indirimli ücretle eğitime başla.'],
   array['MLP Care bünyesinde kadrolu çalışan tüm personel',
         'En az 3 ay çalışma süresini tamamlamış olanlar',
         'Çalışanın 1. derece yakınları (eş, çocuk, anne, baba)'],
   array['İndirim 2026–2027 güz ve bahar dönemi kayıtlarında geçerlidir.',
         'Diğer indirim, burs ve kampanyalarla birleştirilemez.',
         'Kupon oluşturulduktan sonra 30 gün içinde kullanılmalıdır.',
         'Her çalışan kampanya süresince bir kez yararlanabilir.',
         'Kayıt sırasında MLP Care personel kimliği ibraz edilmelidir.',
         'Kontenjan sınırlıdır, başvurular başvuru sırasına göre değerlendirilir.'],
   'Kayıt iptalinde indirim hakkı yeniden kullanılamaz.'),

  ('c0000000-0000-4000-8000-000000000002','starbucks-buyuk-boy',
   'b0000000-0000-4000-8000-000000000002', 1,
   'Starbucks''ta Büyük Boy İçeceklerde %25 İndirim','%25', 25,
   null,'active', now() - interval '10 days', now() + interval '30 days',
   null, 750, 'in_store', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000003','karcher-ev-bahce',
   'b0000000-0000-4000-8000-000000000003', 2,
   'MLPCare''e Özel Kärcher Ev ve Bahçe Ürünlerinde %20 Ayrıcalık','%20', 20,
   null,'active', now() - interval '5 days', now() + interval '24 days',
   null, null, 'both', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000004','arabam-garaj',
   'b0000000-0000-4000-8000-000000000004', 5,
   'arabam Garaj Oto Kuaför Kategorisinde Net 250 TL Ayrıcalık','250 TL', null,
   null,'active', now() - interval '3 days', now() + interval '18 days',
   null, null, 'online', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000005','liv-koleji-egitim',
   'b0000000-0000-4000-8000-000000000005', 4,
   'Liv Koleji''nde Eğitim Fırsatı %50 İndirimli','%50', 50,
   null,'active', now() - interval '20 days', now() + interval '60 days',
   null, null, 'online', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000006','mlpcare-psikolog',
   'b0000000-0000-4000-8000-000000000006', 3,
   'MLPCare''den Ücretsiz Psikolog Seansı','Ücretsiz', null,
   null,'active', now() - interval '15 days', now() + interval '90 days',
   null, null, 'online', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000007','opet-akaryakit',
   'b0000000-0000-4000-8000-000000000007', 7,
   'OPET İstasyonlarında Akaryakıtta 150 TL İndirim','150 TL', null,
   null,'active', now() - interval '8 days', now() + interval '21 days',
   null, null, 'in_store', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000008','enuygun-seyahat',
   'b0000000-0000-4000-8000-000000000008', 6,
   'EnUygun''da Otel ve Araç Kiralamada %10 İndirim','%10', 10,
   null,'active', now() - interval '12 days', now() + interval '40 days',
   null, null, 'online', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-000000000009','petcity-mama',
   'b0000000-0000-4000-8000-000000000009', 8,
   'Petcity''de Mama ve Aksesuar Alışverişinde %30 İndirim','%30', 30,
   null,'active', now() - interval '6 days', now() + interval '15 days',
   null, null, 'both', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null),

  ('c0000000-0000-4000-8000-00000000000a','dod-ikinci-el',
   'b0000000-0000-4000-8000-00000000000a', 5,
   'DOD''da İkinci El Araç Alım Satımında Komisyonsuz İşlem','Komisyonsuz', null,
   null,'active', now() - interval '4 days', now() + interval '12 days',
   null, null, 'in_store', 1, array[]::text[], array[]::text[],
   array[]::text[], array[]::text[], null)
on conflict (id) do nothing;

-- İstinye kampanyasının kampüsleri.
insert into public.campaign_branches (campaign_id, name, address, opening_hours, sort_order) values
  ('c0000000-0000-4000-8000-000000000001','Topkapı Kampüsü',
   'Maltepe Mah. Edirne Çırpıcı Yolu Sok. No:9, Zeytinburnu / İstanbul',
   'Hafta içi 09:00 – 18:00', 1),
  ('c0000000-0000-4000-8000-000000000001','Güney Kampüs — Sağlık Bilimleri',
   'Cevizlibağ, Teyyareci Sami Sok. No:3, Zeytinburnu / İstanbul',
   'Hafta içi 09:00 – 17:30', 2),
  ('c0000000-0000-4000-8000-000000000001','Topkapı Liv Hospital Uygulama Kampüsü',
   'Kaptanpaşa Mah. Darülaceze Cad. No:25, Şişli / İstanbul',
   'Hafta içi 09:00 – 18:00', 3),
  ('c0000000-0000-4000-8000-000000000001','Vadistanbul Kampüsü',
   'Ayazağa Mah. Azerbaycan Cad. No:3-1, Sarıyer / İstanbul',
   'Hafta içi 08:30 – 17:00', 4)
on conflict do nothing;

-- ------------------------------------------------------------ hastaneler
insert into public.hospitals (id, name, city, district, institution_id) values
  ('40000000-0000-4000-8000-000000000001','Medical Park Göztepe','İstanbul','Kadıköy',1),
  ('40000000-0000-4000-8000-000000000002','Çam Sakura Şehir Hastanesi','İstanbul','Başakşehir',null),
  ('40000000-0000-4000-8000-000000000003','Liv Hospital Ulus','İstanbul','Beşiktaş',2)
on conflict (id) do nothing;

-- ----------------------------------------------------------- yasal metinler
insert into public.legal_documents (kind, version, locale, title, body_md) values
  ('terms_of_use','v1','tr','Kullanım Koşulları',
   '# Kullanım Koşulları\n\nDemo içerik.'),
  ('privacy_kvkk','v1','tr','KVKK Aydınlatma Metni',
   '# KVKK Aydınlatma Metni\n\nDemo içerik.'),
  ('blood_health_data','v1','tr','Kan Grubu Verisi Açık Rızası',
   '# Açık Rıza\n\nKan grubu bilgisi KVKK m.6 kapsamında özel nitelikli '
   'kişisel veridir. Demo içerik.')
on conflict (kind, version, locale) do nothing;
