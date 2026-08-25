-- Temel: şemalar, uzantılar, ortak yardımcılar.
--
-- İki şema kullanıyoruz:
--   public  → PostgREST üzerinden istemciye açık. Her tabloda RLS zorunlu.
--   private → API'ye KAPALI. Bordro kayıtları gibi istemcinin asla doğrudan
--             sorgulamaması gereken veriler burada durur; yalnızca
--             SECURITY DEFINER fonksiyonlar ve service_role erişir.
--
-- ÖNEMLİ: Supabase yalnızca API ayarlarında listelenen şemaları yayınlar
-- (varsayılan: public, graphql_public). `private` şemasını oraya EKLEMEYİN.

create schema if not exists private;

revoke all on schema private from anon, authenticated;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;

-- updated_at'i otomatik güncelleyen ortak tetikleyici.
create or replace function private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Telefon numarasını E.164'e indirger: "+90 532 123 45 48" → "+905321234548".
-- Kullanıcı girişi ile bordro kaydını karşılaştırırken biçim farkları
-- yüzünden eşleşme kaçırmamak için tek biçim kullanıyoruz.
create or replace function private.normalize_phone(raw text)
returns text
language plpgsql
immutable
as $$
declare
  digits text;
begin
  if raw is null then
    return null;
  end if;

  digits := regexp_replace(raw, '\D', '', 'g');

  -- Baştaki ülke kodu/sıfır varyasyonlarını tekilleştir.
  if length(digits) = 10 and left(digits, 1) = '5' then
    digits := '90' || digits;
  elsif length(digits) = 11 and left(digits, 1) = '0' then
    digits := '90' || substr(digits, 2);
  end if;

  if length(digits) <> 12 or left(digits, 3) <> '905' then
    return null; -- geçersiz TR cep numarası
  end if;

  return '+' || digits;
end;
$$;

-- TCKN algoritmik doğrulaması (11 hane, ilk hane 0 olamaz, iki sağlama hanesi).
-- Bordro içe aktarımında bozuk kayıtları erken yakalamak için.
create or replace function private.is_valid_tckn(raw text)
returns boolean
language plpgsql
immutable
as $$
declare
  d int[];
  i int;
  odd_sum int := 0;
  even_sum int := 0;
  total int := 0;
begin
  if raw is null or raw !~ '^[1-9][0-9]{10}$' then
    return false;
  end if;

  for i in 1..11 loop
    d[i] := substr(raw, i, 1)::int;
  end loop;

  for i in 1..9 by 2 loop odd_sum := odd_sum + d[i]; end loop;
  for i in 2..8 by 2 loop even_sum := even_sum + d[i]; end loop;

  if ((odd_sum * 7) - even_sum) % 10 <> d[10] then
    return false;
  end if;

  for i in 1..10 loop total := total + d[i]; end loop;
  return total % 10 = d[11];
end;
$$;
