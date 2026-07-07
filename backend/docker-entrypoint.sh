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

echo "[entrypoint] Iniciando: $@"
exec "$@"
