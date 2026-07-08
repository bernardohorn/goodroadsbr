# GoodRoads — Guia para Claude Code

## Visão geral

GoodRoads é um sistema para registro, acompanhamento e gerenciamento de
ocorrências em estradas rurais (buracos, pontes danificadas, deslizamentos,
alagamentos etc.), conectando cidadãos e prefeituras.

Monorepo com três partes independentes que compartilham contratos de API:

```
goodroads/
├── mobile/          # App Flutter (cidadãos) — iOS/Android
├── desktop/         # App Flutter Desktop (funcionários da prefeitura) — Windows
├── backend/         # API Node.js + Express + PostgreSQL + Prisma
├── docs/            # ADRs, contratos de API, diagramas
└── CLAUDE.md        # este arquivo
```

Cada subpasta tem seu próprio `CLAUDE.md` com regras específicas de stack.
Claude deve ler o `CLAUDE.md` da subpasta relevante além deste antes de
editar código nela.

## Stack e restrições inegociáveis

- **Mapas: somente OpenStreetMap.** `flutter_map`, `Geolocator`, `Nominatim`
  (geocoding). **Nunca** sugerir, importar ou referenciar Google Maps SDK,
  `google_maps_flutter` ou APIs do Google Maps — mesmo "só para comparar" ou
  como fallback.
- **Backend:** Node.js + Express + PostgreSQL + Prisma ORM.
- **Auth:** JWT (access + refresh token), RBAC (papéis: `cidadao`,
  `funcionario`, `admin_prefeitura`, `admin_sistema` — ajustar conforme
  evoluir).
- **Frontend:** Flutter (mobile e desktop), Material Design 3.
- **Arquitetura:** Clean Architecture + princípios SOLID em todas as
  camadas (mobile, desktop e backend).

## Papéis e separação de acesso

- App **mobile** é exclusivo de cidadãos. Nunca adicionar funcionalidades
  administrativas nele.
- App **desktop** é exclusivo de funcionários/prefeitura. Nunca adicionar
  fluxos de registro de ocorrência "como cidadão" nele.
- O **backend** é a única fonte de verdade de autorização. RBAC deve ser
  validado no servidor, nunca confiar apenas em checagem de papel no
  cliente.

## Convenções de código gerais

- Commits: [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`).
- Branches: `feature/<escopo>-<descricao>`, `fix/<escopo>-<descricao>`.
- Nunca commitar `.env`, chaves, tokens ou credenciais. Sempre usar
  `.env.example` como referência.
- PRs pequenos e focados; preferir múltiplos PRs pequenos a um PR gigante.
- Toda função pública/exportada relevante deve ter teste correspondente
  antes de ser considerada concluída.

## Fluxo de trabalho esperado do Claude

1. Antes de codar, ler o `CLAUDE.md` da subpasta afetada.
2. Para mudanças que tocam contrato de API (rotas, DTOs, schemas), atualizar
   `docs/api-contract.md` (ou equivalente) e avisar explicitamente que os
   três projetos podem precisar de ajuste.
3. Rodar lint/testes da subpasta afetada antes de considerar a tarefa
   concluída (ver comandos em cada `CLAUDE.md` filho).
4. Nunca introduzir uma dependência nova sem justificar em 1 linha por que
   ela é necessária (evitar inchaço de pacotes, especialmente no Flutter).
5. Preferir editar código existente a reescrever do zero, a menos que
   explicitamente pedido.

## O que NÃO fazer

- Não usar Google Maps em nenhuma hipótese.
- Não misturar lógica de cidadão e de funcionário no mesmo app.
- Não fazer chamadas diretas ao banco a partir do Flutter — tudo passa pelo
  backend.
- Não desabilitar validação de JWT/RBAC "temporariamente" para testar.
- Não gerar migrations destrutivas (`DROP TABLE`, `DROP COLUMN`) sem
  confirmação explícita do usuário.
