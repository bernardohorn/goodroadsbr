# Tela "Usuários" no desktop: incluir cidadãos (mobile), separados por grupo

## Contexto

A tela "Usuários" do desktop (`staff_page.dart`, rota `/usuarios`) hoje lista
apenas contas `FUNCIONARIO`/`ADMIN`, vindas de `GET /staff`
(`staff.repository.ts`, `staffSelect` filtra `role.name IN
(FUNCIONARIO, ADMIN)`). Contas `CIDADAO` (cadastradas pelo app mobile via
`POST /auth/register`) não aparecem em lugar nenhum do desktop hoje.

O pedido é: mostrar também os usuários do mobile (cidadãos) nessa tela,
organizados em grupos separados — Administradores, Funcionários e Cidadãos —
e permitir ver as informações de um cidadão.

`User.active` já existe no schema e já é usado tanto para contas de staff
(`staff.service.ts`) quanto verificado no login/refresh
(`auth.service.ts:90,125`) — nenhuma conta inativa consegue autenticar.

## Escopo

### Backend — novo módulo `citizens`

Espelha a estrutura de `backend/src/modules/staff/` (repository, service,
controller, routes, schema).

- **`GET /api/v1/citizens`** — lista paginada de contas `CIDADAO`.
  - Query: `search` (nome/e-mail, opcional), `page` (default 1), `pageSize`
    (default 20, máx. 50).
  - Response: `{ items: Citizen[], total: number }`.
  - `Citizen`: `{ id, name, email, phone, cpf, avatarUrl, active, createdAt }`
    (mesmos campos já expostos em `citizen` de `occurrenceDetail`, mais
    `active`/`createdAt`/`avatarUrl` que já existem no `User`).
  - RBAC: `FUNCIONARIO` e `ADMIN` (`requireRole('FUNCIONARIO', 'ADMIN')`,
    igual à leitura de `/staff` hoje).
- **`GET /api/v1/citizens/:id`** — detalhe de um cidadão. Mesmo RBAC. 404 se
  não existir ou não for `CIDADAO`.
- **`PATCH /api/v1/citizens/:id/status`** — corpo `{ active: boolean }`.
  Ativa/desativa a conta. RBAC: **somente `ADMIN`** (mesma restrição que já
  existe para criar/editar contas de staff). Reaproveita `User.active` — sem
  efeito colateral adicional a implementar, pois login/refresh já bloqueiam
  `active: false`.
- Nenhuma migration: todos os campos já existem no `User`.
- `docs/api-contract.md` ganha as 3 rotas novas, com nota de que é uma adição
  (nenhuma rota/campo existente muda).

### Desktop — nova feature `citizens`

Espelha `features/staff/` (Clean Architecture: domain/data/presentation),
mas com paginação (como `features/occurrences`, já que a base de cidadãos de
uma cidade pode ser grande, diferente do time interno):

- `domain/entities/citizen.dart` — `id, name, email, phone, cpf, avatarUrl,
  active, createdAt`.
- `domain/entities/paginated_citizens.dart` — mesmo formato de
  `paginated_occurrences.dart` (`items, total, page, pageSize`,
  `hasNextPage`, `totalPages`).
- `domain/repositories/citizens_repository.dart` — `list({page, search})`,
  `updateStatus({id, active})`.
- `domain/usecases/list_citizens_usecase.dart`,
  `update_citizen_status_usecase.dart`.
- `data/models/citizen_model.dart` (`fromJson`).
- `data/datasources/citizens_remote_data_source.dart`,
  `data/repositories/citizens_repository_impl.dart`.
- `presentation/controllers/citizens_list_controller.dart` —
  `AsyncNotifier<PaginatedCitizens>` com `page`/`search` internos, mesmo
  padrão de `OccurrencesListController` (páginas explícitas, não scroll
  infinito).
- `presentation/widgets/citizen_details_dialog.dart` — dialog somente
  leitura: Nome, E-mail, Telefone, CPF (formatado), Cadastrado em, Status
  (chip Ativo/Inativo). Se o usuário logado for `ADMIN`, mostra um botão
  "Desativar conta" / "Reativar conta" (conforme o estado atual) que chama
  `updateCitizenStatusUseCase` e fecha o dialog ao concluir.

### Utilitário compartilhado — `core/utils/cpf_formatter.dart`

A função `_formatCpf` hoje é privada em `occurrence_details_page.dart`. Vira
uma função pública `formatCpf(String?)` em
`desktop/lib/core/utils/cpf_formatter.dart`, usada tanto por
`occurrence_details_page.dart` quanto pela nova tela de cidadãos — evita
duplicar a mesma lógica de formatação em dois arquivos.

### Tela "Usuários" (`staff_page.dart`, rota `/usuarios` inalterada)

Reestruturada em 3 seções empilhadas (uma `Column` rolável), sem mudar a
rota nem o arquivo de entrada:

1. **Administradores** — partição local (client-side) da lista de staff já
   existente (`staffListProvider`, sem mudança de API): `staff.where((m) =>
   m.role == 'ADMIN')`.
2. **Funcionários** — idem, `role == 'FUNCIONARIO'`. Ambas as seções mantêm
   o botão de editar (ADMIN-only) e o botão "Novo funcionário" no topo,
   exatamente como hoje.
3. **Cidadãos** — nova seção com campo de busca (nome/e-mail) e uma
   `DataTable` paginada (colunas: Nome, E-mail, Telefone, CPF, Cadastrado
   em, Status), botões de página anterior/próxima (mesmo padrão visual de
   `occurrences_list_page.dart`). Clicar numa linha abre
   `CitizenDetailsDialog`.

Cada seção usa `EmptyState` quando vazia e `SkeletonRow`/`SkeletonLoader`
durante o carregamento, consistente com o resto do app.

## Fora de escopo

- Editar nome/e-mail/telefone/CPF de um cidadão pelo desktop — essa conta
  continua sendo gerenciada exclusivamente pelo próprio cidadão no mobile
  (edição de perfil). O desktop só visualiza e ativa/desativa.
- Excluir permanentemente uma conta de cidadão (só desativar).
- Qualquer nova permissão/papel além dos três já existentes
  (`CIDADAO`/`FUNCIONARIO`/`ADMIN`).
- Notificar o cidadão (e-mail/push) quando a conta é desativada.
- Alterar o comportamento de `GET /staff` (continua devolvendo só
  `FUNCIONARIO`/`ADMIN`, como hoje) — o novo endpoint `/citizens` é separado,
  não uma extensão dele.

## Teste

- **Backend** (`tests/citizens.service.test.ts`, mock do repo, mesmo estilo
  de `occurrences.service.test.ts`):
  - `list` aplica paginação e busca corretamente (delega ao repo).
  - `getById` lança 404 quando não encontrado.
  - `updateStatus` lança 404 quando não encontrado; caso contrário chama
    `repo.update` com `{ active }`.
- **Backend** (rota, via `staff.routes.ts`/`citizens.routes.ts` — revisão
  manual de RBAC, sem precisar de teste e2e novo além do já existente para
  `requireRole`, que é testado indiretamente pelos testes e2e de staff/
  ocorrências já no repositório).
- **Desktop**:
  - Unit test de `CitizenModel.fromJson` (campos presentes/ausentes, igual
    ao padrão usado em `staff_occurrence_model_test.dart`).
  - Unit test de `formatCpf` (11 dígitos formata; entrada nula/inválida
    retorna como veio).
  - Widget test da tela "Usuários": dado um staff misto (admin +
    funcionário) e uma página de cidadãos mockados via override de
    `citizensListControllerProvider`, verifica que os 3 títulos de seção
    aparecem e que cada pessoa aparece na seção certa.
  - Widget test do `CitizenDetailsDialog`: mostra os dados formatados; botão
    "Desativar conta" só aparece para ADMIN e chama o use case ao ser
    tocado.
