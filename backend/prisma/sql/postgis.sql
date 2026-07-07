-- Configuracao geoespacial complementar ao schema.prisma.
--
-- O Prisma ORM ainda nao modela o tipo `geography` do PostGIS nativamente,
-- entao a tabela `occurrences` guarda latitude/longitude como colunas
-- comuns (via schema.prisma) e este script adiciona uma coluna geoespacial
-- indexada, mantida em sincronia por trigger. As queries de proximidade do
-- modulo `map` (ST_DWithin / bounding box) usam a coluna `location`.
--
-- Executar uma vez, apos `npx prisma migrate dev`:
--   psql "$DATABASE_URL" -f prisma/sql/postgis.sql

CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE occurrences
  ADD COLUMN IF NOT EXISTS location geography(Point, 4326);

CREATE OR REPLACE FUNCTION occurrences_sync_location()
RETURNS trigger AS $$
BEGIN
  NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_occurrences_sync_location ON occurrences;
CREATE TRIGGER trg_occurrences_sync_location
  BEFORE INSERT OR UPDATE OF latitude, longitude ON occurrences
  FOR EACH ROW
  EXECUTE FUNCTION occurrences_sync_location();

-- backfill de linhas existentes
UPDATE occurrences
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography;

CREATE INDEX IF NOT EXISTS occurrences_location_gix
  ON occurrences USING GIST (location);
