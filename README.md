# GoodRoads

Plataforma de registro, acompanhamento e gerenciamento de ocorrencias em estradas rurais, conectando cidadaos e prefeituras.

Monorepo com 4 pastas:

- **`mobile/`** — app Flutter para o cidadao (Android/iOS).
- **`desktop/`** — app Flutter para o funcionario da prefeitura (Windows).
- **`backend/`** — API REST (Node.js + Express + Prisma + PostgreSQL/PostGIS).
- **`docs/`** — arquitetura, decisoes do projeto e demais documentos tecnicos.

Comece por `docs/ARQUITETURA_GOODROADS.md` para a visao completa do sistema e `docs/DECISOES.md` para o historico de decisoes tomadas ao longo do projeto.

## Estado atual

- **Etapa 0 — Arquitetura:** concluida.
- **Etapa 1 — Backend base (auth):** concluida.
- **Etapa 2 — Backend: ocorrencias, categorias, times, notificacoes, mapa:** concluida.
- **Etapa 3 — App Mobile (cidadao), as 8 telas:** concluida — ver `mobile/README.md`.
- **Etapa 4 — App Desktop (funcionario), as 10 telas + backend (staff/dashboard/relatorios):** concluida — ver `desktop/README.md`.
- **Etapa 5 — Notificacoes push reais (FCM) + sincronizacao offline (mobile):** concluida — ver `backend/README.md` e `mobile/README.md`. Requer configuracao externa (service account do Firebase no backend, `flutterfire configure` no mobile) que nao pode ser feita neste sandbox.
- **Etapa 6 — Hardening de seguranca, testes end-to-end e producao (Docker, CI/CD, observabilidade):** concluida — ver `backend/README.md` e `docs/ARQUITETURA_GOODROADS.md`, secao 12. Fecha o roadmap original do projeto.

Todas as 6 etapas do roadmap original (`docs/ARQUITETURA_GOODROADS.md`, secao 10) estao concluidas. Nada foi executado neste sandbox de desenvolvimento (sem `npm install`, Postgres/Docker reais, Flutter SDK ou GitHub Actions disponiveis aqui) — todo o codigo foi revisado estaticamente. Antes de ir para producao de verdade, rode as verificacoes descritas em cada README (`backend/README.md`, `mobile/README.md`, `desktop/README.md`): instalar dependencias, aplicar migrations, rodar os testes (unitarios e e2e), `flutter analyze`/`flutter test`, buildar a imagem Docker e configurar o Firebase (push notifications).
