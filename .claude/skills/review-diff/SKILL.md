---
name: review-diff
description: Faz uma revisão de código do diff atual (não commitado) ancorada no código real do repositório, aplicando as regras do GoodRoads (OSM-only, RBAC no servidor, Clean Architecture, sem segredos commitados). Use quando o usuário pedir para revisar mudanças, gerar mensagem de commit, ou antes de abrir um PR.
---

## Mudanças atuais

!`git diff HEAD`

## Como revisar

Analise o diff acima e reporte em três blocos curtos.

### 1. Resumo
Duas ou três linhas do que mudou. Se o diff estiver vazio, diga que não há
mudanças não commitadas e pare.

### 2. Riscos e violações de regra do projeto
Sinalize (com arquivo:linha) qualquer:

- **Google Maps** / `google_maps_flutter` / `AIza...` → violação bloqueante.
- **RBAC ausente**: rota nova sem `requireAuth`/`requireRole`, ou lógica de
  autorização feita só no cliente.
- **Segredos**: `.env`, chaves, tokens ou senhas no diff; senha logada ou
  retornada.
- **Camadas violadas**: `domain` importando Prisma/Express; Flutter acessando
  banco direto; regra de negócio dentro do controller.
- **Migration destrutiva** (`DROP`) sem confirmação.
- **App errado**: fluxo administrativo no `mobile/` ou registro de cidadão no
  `desktop/`.
- Falta de tratamento de erro/loading, `print` esquecido, valores hardcoded,
  ausência de teste para código novo.

### 3. Sugestões
Melhorias objetivas. Ofereça uma mensagem de commit no formato Conventional
Commits (`feat:`, `fix:`, `refactor:`...).

## Importante
Baseie-se apenas no que está no diff acima — não invente arquivos que não
aparecem. Se algo precisar de verificação em arquivo não incluído no diff,
diga explicitamente que precisa lê-lo.
