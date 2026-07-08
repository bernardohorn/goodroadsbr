#!/bin/sh
# Entrypoint de producao (Etapa 6): aplica as migrations pendentes do
# Prisma (`migrate deploy` — nunca `migrate dev`, que pode fazer perguntas
# interativas e nao deve rodar fora do ambiente do desenvolvedor) e so
# entao inicia o processo da API. Falha rapido (e derruba o container,
# permitindo o orquestrador reiniciar/alertar) se a migration falhar, em
# vez de subir uma API apontando para um schema desatualizado.
set -e

echo "[entrypoint] Aplicando migrations pendentes..."
npx prisma migrate deploy

# prisma/sql/postgis.sql precisa rodar DEPOIS das migrations (depende da
# tabela `occurrences`, criada por elas) — por isso nao pode ser um script
# de inicializacao do container do Postgres (docker-entrypoint-initdb.d roda
# uma unica vez, na criacao do banco, antes de qualquer migration existir).
# E idempotente (CREATE EXTENSION IF NOT EXISTS, ADD COLUMN IF NOT EXISTS,
# CREATE OR REPLACE FUNCTION, DROP/CREATE TRIGGER, CREATE INDEX IF NOT
# EXISTS), entao pode rodar em todo start do container sem risco.
echo "[entrypoint] Aplicando prisma/sql/postgis.sql..."
# psql (libpq) nao reconhece o parametro de query "?schema=" que o Prisma usa
# na DATABASE_URL — precisa ser removido antes de passar a URI para o psql.
PSQL_DATABASE_URL=$(echo "$DATABASE_URL" | cut -d'?' -f1)
psql "$PSQL_DATABASE_URL" -v ON_ERROR_STOP=1 -f prisma/sql/postgis.sql

echo "[entrypoint] Iniciando: $@"
exec "$@"
