-- Şemanın davranış doğrulaması. `supabase/tests/run.sh` ile çalıştırılır.
--
-- Buradaki her kontrol, gerçekten kırılabilecek bir varsayımı sınıyor:
-- yalnızca "tablo var mı" değil, RLS'in izole ettiğini, tetikleyicilerin
-- limitleri tuttuğunu ve istemcinin yasak yolları kullanamadığını.

\set ON_ERROR_STOP on
\timing off
\pset tuples_only on
\pset format unaligned

-- TCKN pepper'ı (üretimde ALTER DATABASE ile, sır yöneticisinden).
set app.tckn_pepper = 'test-pepper-en-az-32-karakter-olmali-xyz';

create or replace function pg_temp.check(label text, actual anyelement, expected anyelement)
returns void language plpgsql as $$
begin
  if actual::text is distinct from expected::text then
    raise exception 'BAŞARISIZ: % → beklenen %, gelen %', label, expected, actual;
  end if;
  raise notice 'OK  %', label;
end $$;

-- ------------------------------------------------------- yardımcı fonksiyonlar
select pg_temp.check('normalize_phone: uluslararası',
  private.normalize_phone('+90 532 123 45 48'), '+905321234548');
select pg_temp.check('normalize_phone: baştaki sıfır',
  private.normalize_phone('0532 123 45 48'), '+905321234548');
select pg_temp.check('normalize_phone: ham 10 hane',
  private.normalize_phone('5321234548'), '+905321234548');
select pg_temp.check('normalize_phone: sabit hat reddedilir',
  private.normalize_phone('+90 212 123 45 48'), null::text);
select pg_temp.check('is_valid_tckn: geçerli',
  private.is_valid_tckn('10000000078'), true);
select pg_temp.check('is_valid_tckn: sağlama hatalı',
  private.is_valid_tckn('12345678901'), false);
select pg_temp.check('is_valid_tckn: sıfırla başlayamaz',
  private.is_valid_tckn('01234567890'), false);

-- ------------------------------------------------------------- test verisi
insert into private.employees (employee_no, tckn_hash, tckn_last2, full_name,
  phone, email, institution_id, department, region, facility, status, hired_at)
values
  ('MP-9843102', private.hash_tckn('10000000078'), '78', 'Ayşe Yılmaz',
   '+905321234548', 'ayse@mlpcare.com', 1, 'Bilgi Teknolojileri',
   'İstanbul Bölge', 'Göztepe Hastanesi', 'active', '2023-03-01'),
  ('LH-5551234', private.hash_tckn('12345678950'), '50', 'Mehmet Demir',
   '+905339998877', null, 2, 'Radyoloji', null, null, 'active', '2024-01-15');

insert into auth.users (id, phone) values
  ('11111111-1111-1111-1111-111111111111', '+905321234548'),
  ('22222222-2222-2222-2222-222222222222', '+905339998877');

-- --------------------------------------------------------- giriş akışı
select pg_temp.check('lookup: telefonla bulunur',
  (select found from private.lookup_employee('+90 532 123 45 48')), true);
select pg_temp.check('lookup: TCKN ile de aynı kişi',
  (select masked_phone from private.lookup_employee('10000000078')),
  '+90 532 *** ** 48');
select pg_temp.check('lookup: olmayan numara sızdırmaz',
  (select found from private.lookup_employee('+90 555 000 00 00')), false);

select private.link_profile('11111111-1111-1111-1111-111111111111',
  (select id from private.employees where employee_no='MP-9843102'));
select private.link_profile('22222222-2222-2222-2222-222222222222',
  (select id from private.employees where employee_no='LH-5551234'));

select pg_temp.check('link_profile: bordro alanları geldi',
  (select department from public.profiles
   where id='11111111-1111-1111-1111-111111111111'), 'Bilgi Teknolojileri');
select pg_temp.check('link_profile: bildirim tercihleri açıldı',
  (select count(*) from public.notification_preferences), 2::bigint);

-- Tekrar giriş profil çoğaltmamalı.
select private.link_profile('11111111-1111-1111-1111-111111111111',
  (select id from private.employees where employee_no='MP-9843102'));
select pg_temp.check('link_profile: idempotent',
  (select count(*) from public.profiles), 2::bigint);

-- ------------------------------------------------------------ kampanyalar
insert into public.brands (id, slug, name)
values ('aaaaaaaa-0000-0000-0000-000000000001','starbucks','Starbucks');

insert into public.campaigns (id, slug, brand_id, category_id, title,
  discount_label, status, starts_at, ends_at, institution_id, per_user_limit)
values
  ('cccccccc-0000-0000-0000-000000000001','herkese',
   'aaaaaaaa-0000-0000-0000-000000000001',1,'Herkese açık','%25','active',
   now()-interval '1 day', now()+interval '30 days', null, 1),
  ('cccccccc-0000-0000-0000-000000000002','sadece-mp',
   'aaaaaaaa-0000-0000-0000-000000000001',1,'Sadece Medical Park','%50','active',
   now()-interval '1 day', now()+interval '30 days', 1, 1),
  ('cccccccc-0000-0000-0000-000000000003','taslak',
   'aaaaaaaa-0000-0000-0000-000000000001',1,'Taslak','%10','draft',
   now()-interval '1 day', now()+interval '30 days', null, 1);

grant select, insert, update, delete on all tables in schema public to authenticated;

-- -------------------------------------------------------------------- RLS
set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select pg_temp.check('RLS: yalnızca kendi profilini görür',
  (select count(*) from public.profiles), 1::bigint);
select pg_temp.check('RLS: kuruma özel kampanya görünür (Medical Park)',
  (select count(*) from public.campaigns), 2::bigint);

-- Bordro alanlarını değiştirme girişimi sessizce yok sayılmalı.
update public.profiles set full_name='HACKER', institution_id=4, theme='dark'
where id='11111111-1111-1111-1111-111111111111';
select pg_temp.check('tetikleyici: ad değiştirilemedi',
  (select full_name from public.profiles), 'Ayşe Yılmaz');
select pg_temp.check('tetikleyici: kurum değiştirilemedi',
  (select institution_id from public.profiles), 1::smallint);
select pg_temp.check('tetikleyici: tema değişti (izinli alan)',
  (select theme::text from public.profiles), 'dark');

-- Kupon kuralları.
select pg_temp.check('kupon: oluşturuldu',
  (select left(code,6) from public.create_coupon(
     'cccccccc-0000-0000-0000-000000000002')), 'BRLKT-');

do $$ begin
  perform public.create_coupon('cccccccc-0000-0000-0000-000000000002');
  raise exception 'BAŞARISIZ: kişi başı limit uygulanmadı';
exception when others then
  if sqlerrm like 'BAŞARISIZ%' then raise; end if;
  raise notice 'OK  kupon: kişi başı limit uygulandı';
end $$;

do $$ begin
  perform public.create_coupon('cccccccc-0000-0000-0000-000000000003');
  raise exception 'BAŞARISIZ: taslak kampanyadan kupon üretildi';
exception when others then
  if sqlerrm like 'BAŞARISIZ%' then raise; end if;
  raise notice 'OK  kupon: taslak kampanya reddedildi';
end $$;

-- İstemci coupons tablosuna doğrudan yazamamalı.
do $$ begin
  insert into public.coupons (profile_id, campaign_id, code, expires_at)
  values ('11111111-1111-1111-1111-111111111111',
          'cccccccc-0000-0000-0000-000000000001','SAHTE', now()+interval '1 day');
  raise exception 'BAŞARISIZ: istemci doğrudan kupon yazabildi';
exception when others then
  if sqlerrm like 'BAŞARISIZ%' then raise; end if;
  raise notice 'OK  RLS: doğrudan kupon yazımı engellendi';
end $$;

-- Kuponu kendi kendine "kullanıldı" yapamamalı (UPDATE politikası yok →
-- RLS satırı filtreler, hata vermez ama 0 satır etkilenir).
update public.coupons set status='used', used_at=now();
select pg_temp.check('RLS: kupon kendi kendine kullanılamaz',
  (select status::text from public.coupons), 'active');

-- Aile limiti.
insert into public.consents (id, profile_id, kind, version, granted)
values ('dddddddd-0000-0000-0000-00000000000a',
        '11111111-1111-1111-1111-111111111111','family_member','v1',true);

insert into public.family_members (profile_id, full_name, relation, tckn_hash,
  tckn_last2, phone, consent_id)
select '11111111-1111-1111-1111-111111111111', 'Yakın '||i, 'child',
       decode(md5('yakin'||i),'hex'), lpad(i::text,2,'0'),
       '+9053300000'||lpad(i::text,2,'0'),
       'dddddddd-0000-0000-0000-00000000000a'
from generate_series(1,3) i;

do $$ begin
  insert into public.family_members (profile_id, full_name, relation, tckn_hash,
    tckn_last2, phone, consent_id)
  values ('11111111-1111-1111-1111-111111111111','Dördüncü','child',
          decode(md5('dorduncu'),'hex'),'99','+905330000099',
          'dddddddd-0000-0000-0000-00000000000a');
  raise exception 'BAŞARISIZ: 4. yakın eklenebildi';
exception when others then
  if sqlerrm like 'BAŞARISIZ%' then raise; end if;
  raise notice 'OK  tetikleyici: azami 3 yakın uygulandı';
end $$;

-- Rıza kayıtları değiştirilemez/silinemez (append-only).
update public.consents set granted=false;
select pg_temp.check('rıza: değiştirilemez',
  (select granted from public.consents), true);
delete from public.consents;
select pg_temp.check('rıza: silinemez',
  (select count(*) from public.consents), 1::bigint);

reset role;

-- Puan defteri → Figma'daki bakiye.
insert into public.point_entries (profile_id, amount, reason, available_at, expires_at) values
 ('11111111-1111-1111-1111-111111111111', 2000,'program_enrollment', now()-interval '10 days', now()+interval '60 days'),
 ('11111111-1111-1111-1111-111111111111',  200,'blood_donation',     now()-interval '5 days',  now()+interval '90 days'),
 ('11111111-1111-1111-1111-111111111111',  300,'campaign_usage',     now()+interval '5 days',  now()+interval '90 days'),
 ('11111111-1111-1111-1111-111111111111',  -50,'coupon_used',        now()-interval '1 day',   null);

set role authenticated;
set request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
select pg_temp.check('puan: toplam',          (select total from public.point_balances), 2450);
select pg_temp.check('puan: kullanılabilir',  (select usable from public.point_balances), 2150);
select pg_temp.check('puan: bekleyen',        (select pending from public.point_balances), 300);
reset role;

-- Diğer kullanıcı izolasyonu.
set role authenticated;
set request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select pg_temp.check('RLS: diğer kullanıcı yalnızca kendini görür',
  (select full_name from public.profiles), 'Mehmet Demir');
select pg_temp.check('RLS: kuruma kapalı kampanya görünmez (Liv Hospital)',
  (select count(*) from public.campaigns), 1::bigint);
select pg_temp.check('RLS: diğer kullanıcının kuponunu görmez',
  (select count(*) from public.coupons), 0::bigint);
reset role;

\echo ''
\echo 'TUM KONTROLLER GECTI'
