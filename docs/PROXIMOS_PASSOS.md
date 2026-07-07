# Próximos passos — do código pronto ao produto no ar

Todo o código das Etapas 0-6 (ver `docs/ARQUITETURA_GOODROADS.md`, seção 10, e `docs/DECISOES.md`) está escrito e revisado estaticamente, mas **nada foi executado de verdade** — o ambiente onde ele foi desenvolvido não tinha acesso a `npm install`, Postgres/Docker reais, Flutter SDK, Firebase ou GitHub Actions. Este documento organiza, em etapas, o que falta para sair do código para um produto rodando de verdade.

## Etapa A — Verificação local do backend

- `npm install` em `backend/`
- `npm run keys:generate`, `npm run prisma:migrate`, `psql ... -f prisma/sql/postgis.sql`, `npm run prisma:seed`
- `npm run lint && npm run typecheck && npm test` (testes unitários, sem depender de banco)
- Subir um Postgres real (`docker compose up -d`) e rodar `npm run test:e2e` (ver `backend/README.md`)
- `npm run build` (garantir que compila limpo para produção)

## Etapa B — Verificação local dos apps Flutter

- `flutter pub get && flutter analyze && flutter test` em `mobile/` e em `desktop/`
- É esperado precisar ajustar a versão exata do pacote `intl` conforme o `flutter_localizations` da versão do Flutter instalada pedir
- Rodar os dois apps em emulador/dispositivo real e testar manualmente os fluxos principais (login, registrar ocorrência com foto, mudar status, mapa, relatórios)

## Etapa C — Configuração do Firebase (push notifications)

- Criar um projeto no [Firebase Console](https://console.firebase.google.com)
- Backend: gerar uma service account (Configurações do projeto → Contas de serviço → Gerar nova chave privada), salvar em `backend/keys/dev/firebase-service-account.json`, definir `PUSH_DRIVER=fcm`
- Mobile: rodar `flutterfire configure` (gera `firebase_options.dart` e os arquivos nativos `google-services.json`/`GoogleService-Info.plist`, que hoje não existem no repositório)
- Testar uma notificação de ponta a ponta (mudar o status de uma ocorrência e confirmar que o celular recebe o push)

## Etapa D — Build e teste da imagem Docker

- `docker build -t goodroads-api backend/`
- `docker compose -f backend/docker-compose.prod.yml up -d --build` localmente, com um `.env.production` de teste
- Confirmar `GET /health`, `GET /health/ready` e `GET /metrics` respondendo, e que `docker-entrypoint.sh` aplicou as migrations sozinho

## Etapa E — Deploy de produção

- Escolher hospedagem (VPS, Cloud Run, Railway, ECS etc.) e um Postgres gerenciado com PostGIS habilitado (RDS, Cloud SQL, Neon, Supabase...)
- Domínio + certificado HTTPS (o backend já assume estar atrás de um reverse proxy — `trust proxy` fica ligado automaticamente com `NODE_ENV=production`)
- Segredos de produção (chaves JWT, credencial do Firebase, senha do banco) fora do repositório, em um cofre de segredos de verdade — nunca reaproveitar as chaves de desenvolvimento
- Rodar as migrations contra o banco de produção (`prisma migrate deploy`, já automático no entrypoint do container)
- Se for escalar para mais de uma instância da API: implementar `S3StorageProvider` (a interface `StorageProvider` já existe, só falta essa implementação) e trocar `STORAGE_DRIVER=s3` — hoje as fotos ficam em disco local, o que não funciona com múltiplas instâncias

## Etapa F — Ativar o CI/CD

- Subir o repositório para o GitHub, se ainda não estiver lá
- Os workflows já existem (`.github/workflows/backend-ci.yml` e `flutter-ci.yml`) — fazer o primeiro push/PR e acompanhar os logs com atenção; é esperado precisar de pequenos ajustes (versão do Postgres/PostGIS, nomes de secrets do repositório etc.)

## Etapa G — Publicar os apps

- **Mobile:** conta de desenvolvedor (Google Play / App Store), build de release assinado, ficha da loja (ícone, screenshots, descrição), envio para revisão
- **Desktop:** empacotar o app Windows (instalador `.exe`/MSIX) e, idealmente, assinatura de código para não disparar alertas do SmartScreen

## Etapa H — Fora do escopo original (melhorias futuras)

- ~~Exportação de relatório em PDF~~ — implementado (`backend/src/core/utils/pdf.ts`, `format=pdf` em `/api/v1/reports/export`, seletor CSV/PDF na tela de Relatórios do desktop).
- Testes automatizados de UI/integração dos apps Flutter (hoje só analyze/test unitário)
- Observabilidade gerenciada em produção real (Grafana/Prometheus hospedado, alertas, dashboards) — hoje só o endpoint `/metrics` existe, sem nada coletando/exibindo

---

Recomendação de ordem: **A → B → D → C → E → F → G**, com a H entrando quando fizer sentido para o negócio. C (Firebase) pode ser feito em paralelo a qualquer momento, já que push é opcional (o app funciona normalmente sem ele, via `PUSH_DRIVER=noop`).
