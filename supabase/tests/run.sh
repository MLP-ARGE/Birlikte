#!/usr/bin/env bash
# Şemayı geçici bir Postgres örneğinde kurup davranış testlerini koşar.
#
# Supabase CLI veya Docker gerektirmez — yalnızca yerel bir Postgres 17.
# Amaç: migration'ları üretime göndermeden önce gerçekten çalıştığını ve
# RLS'in izole ettiğini doğrulamak.
#
#   brew install postgresql@17
#   supabase/tests/run.sh
set -euo pipefail

export LC_ALL=C
PG_BIN="${PG_BIN:-/opt/homebrew/opt/postgresql@17/bin}"
export PATH="$PG_BIN:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d)"
PORT="${PGPORT:-54399}"
DB=birlikte_verify

cleanup() {
  pg_ctl -D "$WORK/data" stop -m immediate >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

echo "→ geçici Postgres kuruluyor ($WORK)"
initdb -D "$WORK/data" -A trust --locale=C -E UTF8 >/dev/null
pg_ctl -D "$WORK/data" \
  -o "-p $PORT -k $WORK -c listen_addresses=''" \
  -l "$WORK/pg.log" start >/dev/null

for _ in $(seq 1 20); do
  pg_isready -p "$PORT" -h "$WORK" >/dev/null 2>&1 && break
  sleep 0.3
done

createdb -p "$PORT" -h "$WORK" "$DB"

echo "→ Supabase ortamı taklit ediliyor"
psql -p "$PORT" -h "$WORK" -d "$DB" -v ON_ERROR_STOP=1 -q \
  -f "$ROOT/supabase/tests/stub_supabase.sql"

echo "→ migration'lar uygulanıyor"
for f in "$ROOT"/supabase/migrations/*.sql; do
  printf '   %s\n' "$(basename "$f")"
  psql -p "$PORT" -h "$WORK" -d "$DB" -v ON_ERROR_STOP=1 -q -f "$f"
done

echo "→ davranış testleri"
# NOTICE'lar stderr'a gider; birleştirip okunur hâle getiriyoruz.
psql -p "$PORT" -h "$WORK" -d "$DB" -v ON_ERROR_STOP=1 \
     -c 'set client_min_messages to notice' \
     -f "$ROOT/supabase/tests/verify.sql" 2>&1 |
  sed -n -e 's/^.*NOTICE:  OK  /  ✓ /p' \
         -e 's/^.*ERROR:  /  ✗ /p' \
         -e 's/^TUM KONTROLLER GECTI/  ── TÜM KONTROLLER GEÇTİ/p'
