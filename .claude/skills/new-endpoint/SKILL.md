---
name: new-endpoint
description: Cria um novo endpoint REST no backend (Node + Express + Prisma) seguindo Clean Architecture, com validação de entrada (zod), autenticação JWT, RBAC, tratamento de erro padronizado e teste. Use quando o usuário pedir para adicionar/criar uma rota, endpoint, API, controller ou caso de uso no backend.
---

## Objetivo

Adicionar um endpoint completo e consistente com a arquitetura do projeto,
sem pular camadas nem validação.

## Camadas a criar/editar (nesta ordem)

1. **Domain** (`src/domain/`)
   - Entidade e/ou interface de repositório, se ainda não existir.
   - Sem nenhum import de Express, Prisma ou libs externas.

2. **Application** (`src/application/`)
   - Um caso de uso (`use case`) com uma única responsabilidade.
   - Recebe repositórios por injeção (abstração), nunca instancia Prisma
     diretamente.

3. **Infrastructure** (`src/infrastructure/`)
   - Implementação concreta do repositório via Prisma, se necessário.

4. **Interfaces / HTTP** (`src/interfaces/http/`)
   - **DTO / schema zod** validando o corpo/params/query ANTES do controller.
   - Controller fino: só orquestra (valida → chama use case → formata
     resposta). Sem regra de negócio aqui.
   - Registrar a rota com os middlewares na ordem:
     `router.<verbo>(path, requireAuth, requireRole([...]), validate(schema), controller)`.

5. **Teste** (`tests/`)
   - Ao menos um teste do caso de uso (unit) e, se a rota for crítica, um
     teste de integração cobrindo 200 + 401 (sem token) + 403 (papel
     errado) + 400 (payload inválido).

## Regras obrigatórias

- **RBAC no servidor**: toda rota decide quem pode acessar via
  `requireRole`. Definir explicitamente os papéis permitidos. Nunca deixar
  rota administrativa sem checagem de papel.
- **Versionamento**: caminho sob `/api/v1/...`.
- **Erros** no formato padrão: `{ "error": { "code": "...", "message": "..." } }`.
- **Listagens** sempre paginadas (`page`, `limit`, `total`) e com índice no
  banco para as colunas filtradas.
- Nunca logar dados sensíveis (senha, token) nem retornar hash de senha.

## Ao finalizar

1. `npm run lint && npm test`.
2. Se criou/alterou contrato de rota, disparar a skill `api-contract-sync`
   (atualizar `docs/api-contract.md` e avisar sobre impacto em mobile/desktop).
3. Se a rota envolve localização de ocorrência, revisar com `osm-guard`.
