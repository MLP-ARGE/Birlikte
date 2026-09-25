-- Kampanya kataloğunun Figma'daki 24 Eylül güncellemesine göre yenilenmesi.
--
-- Tasarımda kampanya kümesi tamamen değişti: 10 kampanya yerine 8, ve
-- markaların çoğu farklı. Kategoriler de 8'den 5'e indi, "Etkinlik" eklendi.
--
-- ESKİ KAMPANYALAR SİLİNMİYOR, 'ended' yapılıyor. Sebebi: gerçek
-- kullanıcıların bu kampanyalardan aldığı kuponlar var (public.coupons →
-- campaigns FK). Silmek onları da götürürdü. 'ended' olanlar RLS'teki
-- campaigns_read_visible politikası gereği uygulamada görünmez ama kupon
-- geçmişi bozulmaz.

-- ------------------------------------------------------------- kategori
insert into public.campaign_categories (id, code, name, sort_order) values
  (9, 'event', 'Etkinlik', 9)
on conflict (id) do update set code = excluded.code, name = excluded.name;

-- Tasarımda artık kullanılmayan kategoriler gizleniyor. Silmiyoruz: eski
-- kampanyalar hâlâ onlara işaret ediyor (FK) ve kupon geçmişi korunmalı.
update public.campaign_categories set is_active = false
  where code in ('health', 'automotive', 'fuel', 'pets');
update public.campaign_categories set is_active = true
  where code in ('food_drink', 'shopping', 'education', 'travel', 'event');
