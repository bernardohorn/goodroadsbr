# Contrato de API — GoodRoads

Este documento registra o contrato das rotas consumidas pelos apps mobile
(cidadão) e desktop (prefeitura). Toda mudança de request/response deve ser
refletida aqui (ver `CLAUDE.md`, seção "Fluxo de trabalho esperado do
Claude").

## `GET /api/v1/occurrences`

Lista ocorrências paginada, escopada por papel (`assertAccess` /
`buildWhere` em `occurrences.repository.ts`).

- **RBAC**: `CIDADAO` vê só as próprias ocorrências (`citizenId` forçado ao
  do token); `FUNCIONARIO`/`ADMIN` vêem as da própria prefeitura (ou sem
  prefeitura atribuída — ver nota em `occurrences.repository.ts`).
- **Response 200** — `{ items: Occurrence[], total: number }`, cada item no
  formato `OccurrenceDetail` abaixo.

## `GET /api/v1/occurrences/:id`

Detalhe de uma ocorrência.

- **RBAC**: mesmo escopo de acesso do `assertAccess` (dono da ocorrência ou
  staff da mesma prefeitura). 403 caso contrário.
- **Response 200** — `OccurrenceDetail`:

```jsonc
{
  "id": "string",
  "protocolNumber": "string",
  "description": "string",
  "status": "PENDENTE | EM_ANDAMENTO | RESOLVIDA | CANCELADA",
  "priority": "BAIXA | MEDIA | ALTA",
  "latitude": 0,
  "longitude": 0,
  "address": "string | null",
  "photos": [{ "id": "string", "url": "string", "thumbnailUrl": "string | null", "order": 0 }],
  "category": { "id": "string", "name": "string" } | null,
  "team": { "id": "string", "name": "string" } | null,
  "assignedTo": { "id": "string", "name": "string", "email": "string" } | null,
  "citizen": {
    "id": "string",
    "name": "string",
    "email": "string",
    "phone": "string | null",
    "cpf": "string | null" // 11 digitos, sem pontuacao — ver nota abaixo
  },
  "internalNotes": "string | null",
  "createdAt": "ISO 8601",
  "resolvedAt": "ISO 8601 | null"
}
```

**Nota de versão (2026-07-10)**: campo `citizen.cpf` adicionado (mudança
aditiva, não quebra clientes existentes). Motivo: painel desktop passou a
exibir o CPF do cidadão que registrou a ocorrência, no card "Cidadão" da
tela de detalhes. O CPF já existia no model `User` do Prisma
(`cpf String? @unique`) e já era coletado no cadastro do cidadão (mobile,
`POST /auth/register`), como 11 dígitos sem pontuação
(`/^\d{11}$/` em `auth.schema.ts`) — não houve migration nem mudança de
RBAC, apenas inclusão do campo no `select` do `citizen` em
`occurrences.repository.ts`.

- **Impacto no mobile**: nenhum. O app do cidadão não lê `citizen` no
  `OccurrenceModel` hoje; o campo novo é ignorado silenciosamente pelo
  parser JSON.
- **Impacto no desktop**: `StaffOccurrence`/`StaffOccurrenceModel` ganham o
  campo `citizenCpf`; `occurrence_details_page.dart` exibe o CPF formatado
  (`123.456.789-00`) no card "Cidadão".

## `GET /api/v1/citizens`

Lista paginada de contas de cidadão (usuários do app mobile), para a tela
"Usuários" do desktop.

- **RBAC**: `FUNCIONARIO` e `ADMIN` (mesma regra de leitura de `/staff`).
- **Query**: `search` (nome/e-mail, opcional), `page` (default `1`),
  `pageSize` (default `20`, máx. `50`).
- **Response 200** — `{ items: Citizen[], total: number }`:

```jsonc
{
  "id": "string",
  "name": "string",
  "email": "string",
  "phone": "string | null",
  "cpf": "string | null",
  "avatarUrl": "string | null",
  "active": true,
  "createdAt": "ISO 8601"
}
```

## `GET /api/v1/citizens/:id`

Detalhe de um cidadão. Mesmo RBAC de `GET /api/v1/citizens`. 404 se não
existir ou não for uma conta `CIDADAO`.

## `PATCH /api/v1/citizens/:id/status`

Ativa ou desativa a conta de um cidadão.

- **RBAC**: somente `ADMIN`.
- **Body**: `{ "active": boolean }`.
- **Response 200** — `Citizen` atualizado.

**Nota de versão (2026-07-10)**: rotas novas (nenhuma rota/campo existente
muda). Motivo: painel desktop passou a listar também os cidadãos cadastrados
pelo app mobile, na tela "Usuários", separados de administradores e
funcionários. Nenhuma migration — todos os campos já existiam em `User`.
Login/refresh já bloqueiam contas com `active: false`
(`auth.service.ts:90,125`), então desativar pelo painel já tem efeito
imediato sem trabalho adicional no fluxo de autenticação.

- **Impacto no mobile**: nenhum — nenhuma rota/campo consumido pelo mobile
  muda.
- **Impacto no desktop**: nova feature `features/citizens/`; tela
  "Usuários" (`staff_page.dart`) ganha uma terceira seção "Cidadãos".
