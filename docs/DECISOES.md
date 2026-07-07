# Decisões do Projeto

Registro cronológico de decisões tomadas pelo cliente que alteram ou detalham a arquitetura descrita em `ARQUITETURA_GOODROADS.md`.

## 2026-07-03 — Etapa 6 concluída (hardening, testes e2e, produção) — roadmap original completo

Última etapa prevista em `ARQUITETURA_GOODROADS.md`, seção 10. Detalhes técnicos completos na nova seção 12 do documento de arquitetura; resumo aqui:

**Segurança/produção:** `trust proxy` em produção (IP real atrás de load balancer), HSTS via `helmet` quando `NODE_ENV=production`, `X-Request-Id` por requisição (correlação de logs), `GET /health` (liveness) e `GET /health/ready` (readiness, checa o Postgres), desligamento gracioso no `SIGTERM`/`SIGINT` (`src/server.ts`) fechando conexões HTTP e Prisma antes de encerrar o processo.

**Observabilidade:** `GET /metrics` no formato Prometheus (`prom-client`), com métricas padrão do processo Node + duração/contagem de requisições HTTP por rota. A rota não tem autenticação própria — é responsabilidade do deploy mantê-la fora do acesso público (rede interna/VPC).

**Testes end-to-end:** `backend/tests/e2e/`, com config e comando (`npm run test:e2e`) separados dos testes unitários, porque sobem a aplicação real e batem contra um Postgres/PostGIS real via `supertest` (ao contrário dos unitários, que mockam o repository). Cobrem o fluxo de autenticação (incluindo rotação/reuso de refresh token) e de ocorrências (foto obrigatória, RBAC de rota e de posse, transições de status). Como o endpoint público de registro só cria contas `CIDADAO`, o usuário `FUNCIONARIO` usado no teste de ocorrências é inserido diretamente via Prisma, do mesmo jeito que `prisma/seed.ts` já fazia.

**Decisão técnica registrada — dois arquivos de setup para os testes e2e:** `tests/e2e/setupEnv.e2e.ts` (só variáveis de ambiente, sem importar nada de `src/`, rodando via `setupFiles`) e `tests/e2e/setupE2e.ts` (importa `prisma`, roda via `setupFilesAfterEnv`). Motivo: declarações `import` de nível superior em TypeScript/JavaScript são "hoisted" para o topo do módulo compilado independentemente de onde aparecem no arquivo-fonte — se as variáveis de ambiente e o `import { prisma }` estivessem no mesmo arquivo, o import executaria primeiro, e `src/config/env.ts` leria `process.env` no estado errado (sem a URL do banco de testes). Separar em dois módulos, executados em sequência pelo Jest, evita isso.

**Docker:** `backend/Dockerfile` multi-estágio (deps → build → runtime), imagem final sem devDependencies e sem código-fonte TypeScript, usuário não-root, `HEALTHCHECK` embutido batendo em `/health`. `docker-entrypoint.sh` roda `prisma migrate deploy` antes de iniciar o processo — por isso o pacote `prisma` (CLI) foi movido de `devDependencies` para `dependencies` (precisa estar presente na imagem de runtime). `backend/docker-compose.prod.yml` sobe Postgres+API juntos; as chaves JWT/FCM são montadas via volume (`./keys:/app/keys:ro`), nunca copiadas para dentro da imagem.

**CI/CD:** `.github/workflows/backend-ci.yml` (lint, typecheck, testes unitários, testes e2e contra um Postgres/PostGIS real como service container do próprio GitHub Actions, build e validação da imagem Docker) e `.github/workflows/flutter-ci.yml` (matrix `mobile`/`desktop`, `flutter analyze` + `flutter test`).

**Limitação do ambiente:** como em todas as etapas anteriores, nada disso foi executado de verdade neste sandbox — sem Docker, sem GitHub Actions, sem Postgres real disponível aqui. Todo o código (incluindo os workflows YAML e o Dockerfile) foi revisado estaticamente. Antes de considerar esta etapa "pronta para produção" de fato: rode `docker build -t goodroads-api backend/` localmente, suba `docker compose -f backend/docker-compose.prod.yml up --build` contra variáveis de ambiente reais, e faça o primeiro push que dispara os workflows do GitHub Actions com atenção redobrada aos logs (é esperado precisar de pequenos ajustes, como a versão exata do Postgres/PostGIS disponível ou nomes de secrets do repositório).

## 2026-07-03 — Etapa 5 concluída (push real + sincronização offline)

**Backend:** `FcmPushProvider` real (Firebase Admin SDK), ligado via `PUSH_DRIVER=fcm` (padrão continua `noop`, sem exigir credenciais — ver `backend/.env.example`). Novo modelo `DeviceToken` (um usuário pode ter vários devices) e endpoints `POST/DELETE /api/v1/notifications/devices`. Tokens que o FCM reporta como inválidos/não registrados são removidos automaticamente a cada envio.

**Mobile:** duas features novas, ambas sob `core/` por serem transversais (não pertencem a uma tela especifica):

- **Push** (`core/push/`): registro/remoção do token FCM no login/logout, notificação em foreground via `flutter_local_notifications` (Android não exibe notificação de FCM sozinho quando o app está aberto), navegação até a ocorrência ao tocar na notificação.
- **Sincronização offline** (`core/offline/`): fila local de ocorrências que falharam por falta de conexão (`NetworkFailure`), sincronizada automaticamente quando a conectividade volta (`connectivity_plus`) ou manualmente pelo banner "N ocorrência(s) aguardando envio" na Home.

**Decisão técnica registrada:** a arquitetura original (seção 7.6) previa Drift para o cache local. Trocado por `sqflite` (SQL cru) — Drift depende de codegen (`build_runner`), e este sandbox de desenvolvimento não tem como rodar/validar o `.g.dart` gerado, pela mesma razão que o projeto já evita codegen no Riverpod desde a Etapa 3. `sqflite` cobre a necessidade (uma tabela simples de fila) sem essa dependência.

**Limitação do ambiente:** além da limitação usual (sem `npm install`/Postgres real/Flutter SDK), esta etapa depende de configuração externa que não pode ser feita neste sandbox: uma service account do Firebase (backend, `FCM_SERVICE_ACCOUNT_PATH`) e rodar `flutterfire configure` no mobile (gera `firebase_options.dart` e os arquivos nativos `google-services.json`/`GoogleService-Info.plist`, específicos de um projeto Firebase real). Sem essas duas configurações, o backend usa `NoopPushProvider` e o mobile funciona normalmente, apenas sem push — ver `backend/README.md` e `mobile/README.md` para o passo a passo.

## 2026-07-02 — Decisões pós Etapa 0

1. **Estrutura do repositório:** monorepo único, com 4 pastas na raiz: `mobile/` (app Flutter do cidadão), `desktop/` (app Flutter do funcionário), `backend/` (API Node.js) e `docs/` (documentação). Substitui a recomendação inicial de um único app Flutter com shell condicional por plataforma.
2. **Storage de imagens:** local em disco durante o desenvolvimento (`backend/uploads/`), acessado exclusivamente através da interface `StorageProvider`. Migração futura para S3/R2/MinIO deve exigir apenas uma nova implementação da interface, sem tocar nos módulos de negócio.
3. **Notificações push:** Firebase Cloud Messaging (FCM) para o app mobile, acessado exclusivamente através da interface `PushProvider`, para permitir troca de provedor no futuro.

## Nota sobre arquivos legados no repositório

Durante a reorganização para o formato de monorepo, o ambiente de arquivos apresentou uma inconsistência de sincronização que impediu a remoção de alguns artefatos temporários criados durante os testes de escrita:

- `ARQUITETURA_GOODROADS.md` (cópia antiga, na raiz do repositório — a versão atual está em `docs/ARQUITETURA_GOODROADS.md`)
- `docs2/` (pasta de teste vazia)
- `backend/.probe` e `backend/probe2.json` (arquivos de teste de escrita)

Esses itens são inofensivos e podem ser apagados manualmente pelo usuário a qualquer momento (o Cowork não tem permissão para excluir arquivos já gravados no seu computador).

## 2026-07-02 — Etapa 1 concluída (backend base)

Implementado: schema completo do banco (`backend/prisma/schema.prisma`), módulo de autenticação completo (registro, login, refresh com rotação e detecção de reuso, logout, esqueci minha senha, redefinição de senha), middlewares centrais (auth guard JWT RS256, RBAC, rate limiting, validação zod, tratamento de erros, auditoria), abstrações `StorageProvider` e `PushProvider` já seguindo as decisões acima, endpoint `GET/PATCH /api/v1/users/me`, e testes unitários do `AuthService` com repository mockado.

**Limitação do ambiente:** o sandbox usado para gerar este código não teve acesso ao registro npm nem a um banco PostgreSQL real, então não foi possível rodar `npm install`, `npm run typecheck`, `npm test` ou `prisma migrate` de ponta a ponta durante o desenvolvimento. A verificação feita foi estática (balanceamento de chaves/parênteses, resolução de todos os imports relativos, checagem de que todo import nomeado corresponde a um export existente, validação de JSON dos arquivos de configuração). Rode `npm install && npm run typecheck && npm test` no seu ambiente como primeiro passo antes de avançar para a Etapa 2.

## 2026-07-02 — Etapa 2 concluída (ocorrências, categorias, times, notificações, mapa)

Implementado: módulo completo de ocorrências (criação com upload de 1 a 5 fotos via `StorageProvider`, listagem escopada por papel com filtros/paginação/ordenação, detalhe com checagem de posse, histórico de status, atualização de status com validação de transição de estado e disparo de notificação, atualização de categoria/prioridade/equipe/responsável/observações internas), numeração de protocolo atômica (`ProtocolSequence`, sem condição de corrida), módulos de categorias e times (CRUD leve), módulo de notificações in-app (registro consultável pelo cidadão, já acionando `PushProvider`), módulo de mapa (busca geoespacial por bounding box via PostGIS), tratamento de erros do Multer, e testes unitários adicionais (`tests/occurrences.service.test.ts`) cobrindo as regras mais sensíveis (foto obrigatória, transições de status válidas/inválidas, checagem de posse, notificação ao mudar status).

Mesma limitação de ambiente da Etapa 1 se aplica: verificação estática apenas (sem `npm install`/banco real disponível no sandbox). A consulta geoespacial do módulo de mapa (`ST_Intersects` sobre a coluna `location`) é a parte com maior risco de precisar de ajuste fino contra um Postgres real — recomendo testá-la com atenção especial ao rodar `npm run prisma:migrate` + `prisma/sql/postgis.sql` pela primeira vez.

## 2026-07-02 — Escopo do app Desktop expandido (pré-Etapa 4)

O cliente solicitou explicitamente, ao autorizar o início da Etapa 4, que o app desktop tivesse mais telas do que as 6 originalmente especificadas no briefing: "quero que crie as outras telas que precisaria no desktop... categorias, usuários, relatórios e configurações e mais a tela do próprio usuário da prefeitura".

Isso substitui a regra original de "exatamente 6 telas" do briefing (que fez com que a v1 deste projeto desenhasse Categorias e Configurações como dialogs, sem tela própria, e não previsse tela de Perfil nem de Relatórios no desktop). Passa a valer o desenho de **10 telas**, descrito em `docs/ARQUITETURA_GOODROADS.md`, seção 7.5:

1. Login · 2. Dashboard · 3. Ocorrências · 4. Detalhes da Ocorrência · 5. Mapa · 6. Categorias · 7. Usuários · 8. Relatórios · 9. Configurações · 10. Perfil.

Duas dessas telas (Usuários/gestão de funcionários e Relatórios) e o Dashboard dependem de endpoints que ainda não existiam no backend (previstos na tabela da seção 5 desde a Etapa 0, mas não implementados nas Etapas 1-2, que cobriram apenas auth/ocorrências/categorias/times/notificações/mapa). Por isso a Etapa 4 inclui três módulos novos de backend antes do app desktop em si: `staff` (gestão de funcionários), `dashboard` (estatísticas agregadas) e `reports` (exportação). Ver entrada "Etapa 4" abaixo para detalhes de escopo de cada um.

## 2026-07-03 — Etapa 4 concluída (backend staff/dashboard/relatórios + app Desktop, 10 telas)

**Backend:** três módulos novos, detalhados em `backend/README.md` — `staff` (`GET /api/v1/staff` liberado a qualquer `FUNCIONARIO`/`ADMIN`, `POST`/`PATCH` restritos a `ADMIN`), `dashboard` (`GET /api/v1/dashboard/stats`: cards agregados, série mensal dos últimos 6 meses via `generate_series` + `LEFT JOIN` para não perder meses sem ocorrência, contagem por categoria, 5 ocorrências mais recentes) e `reports` (`GET /api/v1/reports/export?format=csv`: CSV gerado sem dependência externa em `src/core/utils/csv.ts`, com separador `;` e BOM UTF-8 para o Excel em pt-BR). Seed atualizado para criar também uma conta `ADMIN` de teste.

**Desktop (`desktop/`):** as 10 telas descritas na entrada anterior, com Clean Architecture completa por feature, barra lateral fixa de navegação (`AppShell`), `go_router` com `StatefulShellRoute`, Riverpod sem codegen, e rejeição no cliente de login de conta `CIDADAO` (mensagem clara em vez de tela cheia de erros 403 — o RBAC real continua sendo aplicado pelo backend). Ver `desktop/README.md` para a lista completa de decisões técnicas desta etapa (CSV-only para relatórios, Configurações restrita a preferências reais do cliente, sem tela própria de "Times").

**Limitação do ambiente:** mesma de todas as etapas anteriores — sem acesso a `npm install`/banco Postgres real (backend) nem ao Flutter SDK/pub.dev (desktop) neste sandbox. Verificação estática apenas. Rode `npm install && npm run typecheck && npm test` no backend e `flutter pub get && flutter analyze && flutter test` no desktop como primeiro passo antes de seguir para a próxima etapa.

## 2026-07-02 — Etapa 3 concluída (app Mobile — cidadão, 8 telas)

Implementado em `mobile/`: as 8 telas principais (Login, Cadastro, Início, Registrar ocorrência, Mapa, Histórico, Detalhes da ocorrência, Perfil), com Clean Architecture completa em cada feature (`domain/data/presentation`), Riverpod (sem codegen — `Notifier`/`AsyncNotifier` manuais, para não depender de `build_runner`), `go_router` com shell de navegação inferior e redirecionamento automático conforme sessão (login/logout, incluindo logout automático quando o refresh token expira), camada de mapas desacoplada (`MapProviderContract` + `OsmMapProvider`, OpenStreetMap + Nominatim), compressão de imagem antes do upload, tema Material 3 claro/escuro, skeleton loading e empty states reutilizáveis.

Decisão técnica registrada: a aba "Todas as ocorrências" do Histórico reaproveita o endpoint `/map/occurrences` (que não é escopado por cidadão) para mostrar uma lista de ocorrências próximas de todos os cidadãos, já que o backend não expõe (nem deveria expor, por padrão) uma listagem completa de ocorrências para o papel `CIDADAO` em `/occurrences`.

**Limitação do ambiente:** sem acesso ao Flutter/Dart SDK nem ao pub.dev neste sandbox, não foi possível rodar `flutter pub get`, `flutter analyze` ou `flutter test`. Verificação estática apenas (balanceamento de chaves/parênteses em todos os `.dart`, resolução de 100% dos imports relativos, checagem de que cada classe/provider referenciado no `go_router` e nos widgets tem exatamente uma definição). Rode `flutter pub get && flutter analyze && flutter test` no seu ambiente como primeiro passo — é esperado ajustar a versão do pacote `intl` conforme o Flutter SDK instalado pedir.
