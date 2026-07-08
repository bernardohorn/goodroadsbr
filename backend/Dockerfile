# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# GoodRoads API — build multi-estagio (Etapa 6).
#
# 1) deps:    instala TODAS as dependencias (dev incluidas) uma unica vez,
#             reaproveitado tanto pelo estagio de build quanto, via cache do
#             Docker, evita reinstalar quando so o codigo-fonte muda.
# 2) build:   gera o Prisma Client e compila o TypeScript (`tsc`) para dist/.
# 3) runtime: imagem final minima — so `node_modules` de producao + dist/ +
#             o schema do Prisma (necessario em runtime pelo Client) e o
#             script de entrypoint. Sem devDependencies, sem codigo-fonte
#             TypeScript, sem ferramentas de build.
#
# Nao foi possivel construir esta imagem neste sandbox de desenvolvimento
# (sem acesso ao registro npm nem a um daemon Docker) — revisado
# estaticamente. Rode `docker build -t goodroads-api .` no seu ambiente
# como primeira verificacao.
# ---------------------------------------------------------------------------

FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
# Alpine nao traz libssl como pacote instalado por padrao, o que faz o
# Prisma falhar ao detectar a versao do OpenSSL (cai num engine
# openssl-1.1.x incompativel com o OpenSSL 3.x desta imagem) e quebrar em
# runtime com "Could not parse schema engine response".
RUN apk add --no-cache openssl
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

# curl e usado apenas pelo HEALTHCHECK abaixo; openssl e necessario para o
# schema engine do Prisma detectar corretamente o OpenSSL 3.x desta imagem
# (ver comentario no estagio "build"); postgresql-client (psql) e usado pelo
# docker-entrypoint.sh para aplicar prisma/sql/postgis.sql apos as migrations.
RUN apk add --no-cache curl openssl postgresql-client \
  && addgroup -S goodroads && adduser -S goodroads -G goodroads

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY prisma ./prisma
COPY docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh

# Diretorios graváveis em runtime (uploads locais em dev/staging sem S3
# configurado, e onde as chaves JWT/FCM devem ser montadas como volume —
# nunca copiadas para dentro da imagem).
RUN mkdir -p uploads keys/dev && chown -R goodroads:goodroads /app

USER goodroads

EXPOSE 3333

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3333/health || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/src/server.js"]
