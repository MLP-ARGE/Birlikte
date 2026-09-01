-- TCKN pepper'ını Supabase Vault'tan oku.
--
-- İlk tasarım pepper'ı `app.tckn_pepper` GUC'unda tutuyordu; Supabase'de
-- `postgres` rolü superuser olmadığı için `ALTER DATABASE ... SET` yetkisi
-- yok. Vault zaten bu iş için var: sırrı diskte şifreli tutar, anahtarı
-- veritabanının dışında saklar, yani `pg_dump` çıktısına düz metin sızmaz.
--
-- Yerel doğrulama koşumunda (supabase/tests) Vault bulunmadığı için GUC'a
-- düşülüyor — üretimde Vault, testte GUC.

create or replace function private.hash_tckn(raw text)
returns bytea
language plpgsql
stable
as $$
declare
  pepper text;
begin
  -- Önce Vault (üretim).
  begin
    select decrypted_secret into pepper
    from vault.decrypted_secrets
    where name = 'tckn_pepper'
    limit 1;
  exception when undefined_table or insufficient_privilege then
    pepper := null;  -- Vault yok (yerel Postgres) — GUC'a düşülecek.
  end;

  -- Yerel doğrulama için GUC yedeği.
  if pepper is null then
    pepper := current_setting('app.tckn_pepper', true);
  end if;

  if pepper is null or length(pepper) < 32 then
    raise exception
      'TCKN pepper bulunamadı. Üretimde: vault.create_secret(...,''tckn_pepper''). '
      'Yerelde: set app.tckn_pepper = ''...''';
  end if;

  if not private.is_valid_tckn(raw) then
    raise exception 'Geçersiz TCKN';
  end if;

  return extensions.hmac(raw, pepper, 'sha256');
end;
$$;
