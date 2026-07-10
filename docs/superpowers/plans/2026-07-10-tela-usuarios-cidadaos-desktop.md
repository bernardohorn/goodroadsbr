# Tela "Usuários" com cidadãos no desktop — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer a tela "Usuários" do desktop mostrar também as contas de cidadão (mobile), organizadas em 3 seções separadas (Administradores, Funcionários, Cidadãos), com uma tela de detalhe somente-leitura por cidadão que permite a um ADMIN ativar/desativar a conta.

**Architecture:** Novo módulo backend `citizens` (espelha `staff`, mas paginado e com escrita restrita a ativar/desativar) expõe `GET /citizens`, `GET /citizens/:id` e `PATCH /citizens/:id/status`. Nova feature desktop `citizens` (Clean Architecture, espelha `staff` para leitura e `occurrences` para paginação) consome essas rotas. A tela `staff_page.dart` existente é reestruturada em 3 seções sem mudar de rota. A formatação de CPF (hoje duplicada implicitamente) é extraída para um utilitário compartilhado.

**Tech Stack:** Backend: Node + Express + Prisma + Zod + Jest. Desktop: Flutter + Riverpod (`AsyncNotifier`) + Equatable + `flutter_test`.

## Global Constraints

- Mapas: não se aplica a este plano (sem mudanças de mapa/geolocalização).
- Backend: Clean Architecture — `citizens.repository.ts` isolado, `citizens.service.ts` não importa Prisma diretamente.
- RBAC sempre validado no servidor: `GET /citizens` e `GET /citizens/:id` exigem `FUNCIONARIO` ou `ADMIN`; `PATCH /citizens/:id/status` exige `ADMIN`.
- Nenhuma migration: todos os campos (`cpf`, `phone`, `avatarUrl`, `active`, `createdAt`) já existem em `User`.
- Conta de cidadão continua sendo criada/editada exclusivamente pelo cidadão no mobile — o desktop só lê e ativa/desativa.
- Toda rota nova documentada em `docs/api-contract.md` antes de considerar a tarefa concluída (regra do `CLAUDE.md` raiz).
- Commits: Conventional Commits (`feat:`, `test:`, `docs:`, `refactor:`).
- Nenhuma dependência nova (nem backend nem desktop) — tudo usa pacotes já presentes em `package.json`/`pubspec.yaml`.

---

## Backend

### Task 1: `CitizensRepository` + schemas de validação

**Files:**
- Create: `backend/src/modules/citizens/citizens.repository.ts`
- Create: `backend/src/modules/citizens/citizens.schema.ts`

**Interfaces:**
- Consumes: `prisma` de `backend/src/infra/database/prisma.client.ts`; `Prisma`, `PrismaClient`, `RoleName` de `@prisma/client`.
- Produces: `export type Citizen` (via `Prisma.UserGetPayload`), `export class CitizensRepository` com métodos `findAll(filters: { search?: string }, pagination: { page: number; pageSize: number }): Promise<{ items: Citizen[]; total: number }>`, `findById(id: string): Promise<Citizen | null>`, `updateStatus(id: string, active: boolean): Promise<Citizen>`. `export const listCitizensSchema`, `export const citizenIdParamSchema`, `export const updateCitizenStatusSchema` (usados pela Task 3).

- [ ] **Step 1: Criar `citizens.repository.ts`**

```typescript
import { Prisma, PrismaClient, RoleName } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

const citizenSelect = Prisma.validator<Prisma.UserSelect>()({
  id: true,
  name: true,
  email: true,
  phone: true,
  cpf: true,
  avatarUrl: true,
  active: true,
  createdAt: true
});

export type Citizen = Prisma.UserGetPayload<{ select: typeof citizenSelect }>;

export class CitizensRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  async findAll(
    filters: { search?: string },
    pagination: { page: number; pageSize: number }
  ): Promise<{ items: Citizen[]; total: number }> {
    const where: Prisma.UserWhereInput = {
      role: { name: RoleName.CIDADAO },
      ...(filters.search
        ? {
            OR: [
              { name: { contains: filters.search, mode: 'insensitive' } },
              { email: { contains: filters.search, mode: 'insensitive' } }
            ]
          }
        : {})
    };

    const [items, total] = await this.db.$transaction([
      this.db.user.findMany({
        where,
        select: citizenSelect,
        orderBy: { name: 'asc' },
        skip: (pagination.page - 1) * pagination.pageSize,
        take: pagination.pageSize
      }),
      this.db.user.count({ where })
    ]);

    return { items, total };
  }

  findById(id: string): Promise<Citizen | null> {
    return this.db.user.findFirst({ where: { id, role: { name: RoleName.CIDADAO } }, select: citizenSelect });
  }

  updateStatus(id: string, active: boolean): Promise<Citizen> {
    return this.db.user.update({ where: { id }, data: { active }, select: citizenSelect });
  }
}
```

- [ ] **Step 2: Criar `citizens.schema.ts`**

```typescript
import { z } from 'zod';

export const listCitizensSchema = {
  query: z.object({
    search: z.string().trim().max(120).optional(),
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(50).default(20)
  })
};

export const citizenIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};

export const updateCitizenStatusSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z.object({ active: z.boolean() })
};
```

- [ ] **Step 3: Verificar que compila**

Run: `cd backend && npx tsc --noEmit`
Expected: sem erros (arquivo ainda não é importado por ninguém, mas deve compilar isoladamente).

- [ ] **Step 4: Commit**

```bash
git add backend/src/modules/citizens/citizens.repository.ts backend/src/modules/citizens/citizens.schema.ts
git commit -m "feat(backend): adiciona repository e schemas do modulo citizens"
```

---

### Task 2: `CitizensService` (TDD)

**Files:**
- Create: `backend/tests/citizens.service.test.ts`
- Create: `backend/src/modules/citizens/citizens.service.ts`

**Interfaces:**
- Consumes: `CitizensRepository`, `Citizen` de `./citizens.repository` (Task 1); `AppError` de `backend/src/core/errors/AppError.ts` (métodos estáticos `.notFound(message)`, com propriedade `.code` — ver uso em `occurrences.service.test.ts`).
- Produces: `export class CitizensService` com `list(filters: { search?: string }, pagination: { page: number; pageSize: number })`, `getById(id: string): Promise<Citizen>` (lança `AppError.notFound` se não existir), `updateStatus(id: string, active: boolean): Promise<Citizen>` (lança `AppError.notFound` se não existir; senão delega a `repo.updateStatus`). Usado pela Task 3 (`CitizensController`).

- [ ] **Step 1: Escrever o teste (falhando)**

```typescript
import { CitizensService } from '../src/modules/citizens/citizens.service';
import { CitizensRepository, Citizen } from '../src/modules/citizens/citizens.repository';

type MockedRepo = {
  [K in keyof CitizensRepository]: jest.Mock;
};

function createMockRepo(): MockedRepo {
  return {
    findAll: jest.fn(),
    findById: jest.fn(),
    updateStatus: jest.fn()
  } as unknown as MockedRepo;
}

function buildCitizen(overrides: Partial<Citizen> = {}): Citizen {
  return {
    id: 'citizen-1',
    name: 'Maria Cidada',
    email: 'maria@example.com',
    phone: null,
    cpf: '12345678900',
    avatarUrl: null,
    active: true,
    createdAt: new Date('2026-07-08T12:00:00.000Z'),
    ...overrides
  } as Citizen;
}

describe('CitizensService', () => {
  let repo: MockedRepo;
  let service: CitizensService;

  beforeEach(() => {
    repo = createMockRepo();
    service = new CitizensService(repo as unknown as CitizensRepository);
  });

  describe('list', () => {
    it('delega paginacao e busca ao repositorio', async () => {
      const page = { items: [buildCitizen()], total: 1 };
      repo.findAll.mockResolvedValue(page);

      const result = await service.list({ search: 'maria' }, { page: 2, pageSize: 10 });

      expect(repo.findAll).toHaveBeenCalledWith({ search: 'maria' }, { page: 2, pageSize: 10 });
      expect(result).toBe(page);
    });
  });

  describe('getById', () => {
    it('lanca NOT_FOUND quando o cidadao nao existe', async () => {
      repo.findById.mockResolvedValue(null);
      await expect(service.getById('missing')).rejects.toMatchObject({ code: 'NOT_FOUND' });
    });

    it('retorna o cidadao quando encontrado', async () => {
      repo.findById.mockResolvedValue(buildCitizen());
      await expect(service.getById('citizen-1')).resolves.toMatchObject({ id: 'citizen-1' });
    });
  });

  describe('updateStatus', () => {
    it('lanca NOT_FOUND quando o cidadao nao existe', async () => {
      repo.findById.mockResolvedValue(null);
      await expect(service.updateStatus('missing', false)).rejects.toMatchObject({ code: 'NOT_FOUND' });
      expect(repo.updateStatus).not.toHaveBeenCalled();
    });

    it('desativa a conta chamando o repositorio', async () => {
      repo.findById.mockResolvedValue(buildCitizen());
      repo.updateStatus.mockResolvedValue(buildCitizen({ active: false }));

      const result = await service.updateStatus('citizen-1', false);

      expect(repo.updateStatus).toHaveBeenCalledWith('citizen-1', false);
      expect(result.active).toBe(false);
    });
  });
});
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `cd backend && npx jest tests/citizens.service.test.ts --runInBand`
Expected: FAIL — `Cannot find module '../src/modules/citizens/citizens.service'`

- [ ] **Step 3: Implementar `citizens.service.ts`**

```typescript
import { AppError } from '../../core/errors/AppError';
import { Citizen, CitizensRepository } from './citizens.repository';

export class CitizensService {
  constructor(private readonly repo: CitizensRepository = new CitizensRepository()) {}

  list(filters: { search?: string }, pagination: { page: number; pageSize: number }) {
    return this.repo.findAll(filters, pagination);
  }

  async getById(id: string): Promise<Citizen> {
    const citizen = await this.repo.findById(id);
    if (!citizen) {
      throw AppError.notFound('Cidadao nao encontrado.');
    }
    return citizen;
  }

  async updateStatus(id: string, active: boolean): Promise<Citizen> {
    const citizen = await this.repo.findById(id);
    if (!citizen) {
      throw AppError.notFound('Cidadao nao encontrado.');
    }
    return this.repo.updateStatus(id, active);
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `cd backend && npx jest tests/citizens.service.test.ts --runInBand`
Expected: PASS — 5 testes.

- [ ] **Step 5: Commit**

```bash
git add backend/tests/citizens.service.test.ts backend/src/modules/citizens/citizens.service.ts
git commit -m "feat(backend): adiciona citizens.service com testes"
```

---

### Task 3: Controller + rotas + montagem no app + contrato de API

**Files:**
- Create: `backend/src/modules/citizens/citizens.controller.ts`
- Create: `backend/src/modules/citizens/citizens.routes.ts`
- Modify: `backend/src/app.ts`
- Modify: `docs/api-contract.md`

**Interfaces:**
- Consumes: `CitizensService` (Task 2); `asyncHandler` de `backend/src/core/middlewares/asyncHandler.ts` (assinatura `(handler: (req, res, next) => Promise<unknown>) => RequestHandler`); `authGuard` de `backend/src/core/middlewares/authGuard.ts`; `requireRole(...roles: RoleName[])` de `backend/src/core/middlewares/rbacGuard.ts`; `validate(schema)` de `backend/src/core/middlewares/validate.ts`; os 3 schemas da Task 1.
- Produces: `export { router as citizensRoutes }`, montado em `${env.API_PREFIX}/citizens`.

- [ ] **Step 1: Criar `citizens.controller.ts`**

```typescript
import { Request, Response } from 'express';
import { CitizensService } from './citizens.service';

export class CitizensController {
  constructor(private readonly service: CitizensService = new CitizensService()) {}

  list = async (req: Request, res: Response) => {
    const { search, page, pageSize } = req.query as unknown as {
      search?: string;
      page: number;
      pageSize: number;
    };
    const result = await this.service.list({ search }, { page, pageSize });
    return res.status(200).json(result);
  };

  getById = async (req: Request, res: Response) => {
    const citizen = await this.service.getById(req.params.id);
    return res.status(200).json(citizen);
  };

  updateStatus = async (req: Request, res: Response) => {
    const citizen = await this.service.updateStatus(req.params.id, req.body.active as boolean);
    return res.status(200).json(citizen);
  };
}
```

- [ ] **Step 2: Criar `citizens.routes.ts`**

```typescript
import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { CitizensController } from './citizens.controller';
import { citizenIdParamSchema, listCitizensSchema, updateCitizenStatusSchema } from './citizens.schema';

const router = Router();
const controller = new CitizensController();

router.use(authGuard);
// Leitura liberada para qualquer membro da equipe (mesmo padrao de
// staff.routes.ts). Ativar/desativar conta fica restrito a ADMIN — mesma
// restricao ja aplicada a criacao/edicao de contas de staff.
router.use(requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/', validate(listCitizensSchema), asyncHandler(controller.list));
router.get('/:id', validate(citizenIdParamSchema), asyncHandler(controller.getById));
router.patch(
  '/:id/status',
  requireRole('ADMIN'),
  validate(updateCitizenStatusSchema),
  asyncHandler(controller.updateStatus)
);

export { router as citizensRoutes };
```

- [ ] **Step 3: Montar as rotas em `backend/src/app.ts`**

Adicionar o import junto aos demais (ordem alfabética, ao lado de `categoriesRoutes`):

```typescript
import { citizensRoutes } from './modules/citizens/citizens.routes';
```

E a montagem junto às demais `app.use` de rotas (logo após a linha `app.use(\`${env.API_PREFIX}/categories\`, categoriesRoutes);`):

```typescript
app.use(`${env.API_PREFIX}/citizens`, citizensRoutes);
```

- [ ] **Step 4: Rodar toda a suíte de testes e o typecheck**

Run: `cd backend && npx tsc --noEmit && npm run lint && npm test`
Expected: sem erros de tipo, lint limpo, todos os testes (incluindo os 5 novos de `citizens.service.test.ts`) passando.

- [ ] **Step 5: Atualizar `docs/api-contract.md`**

Adicionar ao final do arquivo (após a seção de `GET /api/v1/occurrences/:id`):

```markdown

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
```

- [ ] **Step 6: Commit**

```bash
git add backend/src/modules/citizens/citizens.controller.ts backend/src/modules/citizens/citizens.routes.ts backend/src/app.ts docs/api-contract.md
git commit -m "feat(backend): expoe rotas GET/PATCH de citizens e documenta contrato"
```

---

## Desktop

### Task 4: Extrair `formatCpf` para utilitário compartilhado (TDD)

**Files:**
- Create: `desktop/test/core/utils/cpf_formatter_test.dart`
- Create: `desktop/lib/core/utils/cpf_formatter.dart`
- Modify: `desktop/lib/features/occurrences/presentation/pages/occurrence_details_page.dart`

**Interfaces:**
- Produces: `String? formatCpf(String? cpf)` — usado por `occurrence_details_page.dart` (Task 4) e por `citizen_details_dialog.dart`/`staff_page.dart` (Tasks 8 e 9).

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/core/utils/cpf_formatter.dart';

void main() {
  group('formatCpf', () {
    test('formata 11 digitos como 123.456.789-00', () {
      expect(formatCpf('12345678900'), '123.456.789-00');
    });

    test('retorna null quando a entrada e nula', () {
      expect(formatCpf(null), isNull);
    });

    test('retorna o valor original quando nao tem 11 digitos', () {
      expect(formatCpf('123'), '123');
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `cd desktop && flutter test test/core/utils/cpf_formatter_test.dart`
Expected: FAIL — `Error: URI doesn't exist: 'package:goodroads_desktop/core/utils/cpf_formatter.dart'`

- [ ] **Step 3: Criar `cpf_formatter.dart`**

```dart
/// CPF chega do backend so como 11 digitos (validado por `/^\d{11}$/` no
/// cadastro do mobile) — formata para exibicao (`123.456.789-00`) sem
/// precisar de uma dependencia de mascara.
String? formatCpf(String? cpf) {
  if (cpf == null || cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `cd desktop && flutter test test/core/utils/cpf_formatter_test.dart`
Expected: PASS — 3 testes.

- [ ] **Step 5: Atualizar `occurrence_details_page.dart` para usar o utilitário**

Em `desktop/lib/features/occurrences/presentation/pages/occurrence_details_page.dart`, adicionar o import junto aos demais (ordem alfabética, após o import de `osm_map_provider.dart`):

```dart
import '../../../../core/utils/cpf_formatter.dart';
```

Remover a função privada `_formatCpf` (o bloco abaixo, hoje logo antes de `_statusLabel`):

```dart
/// CPF chega do backend so como 11 digitos (validado por `/^\d{11}$/` no
/// cadastro do mobile) — formata para exibicao (`123.456.789-00`) sem
/// precisar de uma dependencia de mascara.
String? _formatCpf(String? cpf) {
  if (cpf == null || cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
}

```

E trocar a chamada `_formatCpf(occurrence.citizenCpf)` por `formatCpf(occurrence.citizenCpf)` na linha do `_InfoRow` de CPF.

- [ ] **Step 6: Rodar os testes existentes da tela de detalhes de ocorrência e o analyze**

Run: `cd desktop && flutter test test/features/occurrences/ && flutter analyze lib test`
Expected: todos os testes continuam passando (o texto renderizado não muda) e `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add desktop/lib/core/utils/cpf_formatter.dart desktop/test/core/utils/cpf_formatter_test.dart desktop/lib/features/occurrences/presentation/pages/occurrence_details_page.dart
git commit -m "refactor(desktop): extrai formatCpf para core/utils compartilhado"
```

---

### Task 5: Domínio da feature `citizens` (entities, repository interface, use cases)

**Files:**
- Create: `desktop/lib/features/citizens/domain/entities/citizen.dart`
- Create: `desktop/lib/features/citizens/domain/entities/paginated_citizens.dart`
- Create: `desktop/lib/features/citizens/domain/repositories/citizens_repository.dart`
- Create: `desktop/lib/features/citizens/domain/usecases/list_citizens_usecase.dart`
- Create: `desktop/lib/features/citizens/domain/usecases/update_citizen_status_usecase.dart`

**Interfaces:**
- Consumes: `Result<T>` de `desktop/lib/core/error/result.dart` (já existe: `Result.success(T)`, `Result.failure(Failure)`, `.fold(onFailure, onSuccess)`).
- Produces: `class Citizen extends Equatable` (`id, name, email, phone, cpf, avatarUrl, active, createdAt`); `class PaginatedCitizens` (`items, total, page, pageSize`, getters `hasNextPage`, `totalPages`); `abstract class CitizensRepository` com `list({required int page, String? search})` e `updateStatus({required String id, required bool active})`; `class ListCitizensUseCase` (`call({required int page, String? search})`); `class UpdateCitizenStatusUseCase` (`call({required String id, required bool active})`). Consumidos pela Task 6 (impl) e Task 7 (providers/controller).

- [ ] **Step 1: Criar `citizen.dart`**

```dart
import 'package:equatable/equatable.dart';

/// Visao de uma conta de cidadao (mobile) sob a otica do painel
/// administrativo — somente leitura, exceto pelo campo `active` (ver
/// UpdateCitizenStatusUseCase). A conta continua sendo criada e editada
/// exclusivamente pelo proprio cidadao no app mobile.
class Citizen extends Equatable {
  const Citizen({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.cpf,
    this.avatarUrl,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? cpf;
  final String? avatarUrl;
  final bool active;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, email, phone, cpf, avatarUrl, active, createdAt];
}
```

- [ ] **Step 2: Criar `paginated_citizens.dart`**

```dart
import 'citizen.dart';

class PaginatedCitizens {
  const PaginatedCitizens({required this.items, required this.total, required this.page, required this.pageSize});

  final List<Citizen> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasNextPage => page * pageSize < total;
  int get totalPages => total == 0 ? 1 : (total / pageSize).ceil();
}
```

- [ ] **Step 3: Criar `citizens_repository.dart`**

```dart
import '../../../../core/error/result.dart';
import '../entities/citizen.dart';
import '../entities/paginated_citizens.dart';

abstract class CitizensRepository {
  Future<Result<PaginatedCitizens>> list({required int page, String? search});
  Future<Result<Citizen>> updateStatus({required String id, required bool active});
}
```

- [ ] **Step 4: Criar `list_citizens_usecase.dart`**

```dart
import '../../../../core/error/result.dart';
import '../entities/paginated_citizens.dart';
import '../repositories/citizens_repository.dart';

class ListCitizensUseCase {
  const ListCitizensUseCase(this._repo);
  final CitizensRepository _repo;

  Future<Result<PaginatedCitizens>> call({required int page, String? search}) {
    return _repo.list(page: page, search: search);
  }
}
```

- [ ] **Step 5: Criar `update_citizen_status_usecase.dart`**

```dart
import '../../../../core/error/result.dart';
import '../entities/citizen.dart';
import '../repositories/citizens_repository.dart';

class UpdateCitizenStatusUseCase {
  const UpdateCitizenStatusUseCase(this._repo);
  final CitizensRepository _repo;

  Future<Result<Citizen>> call({required String id, required bool active}) {
    return _repo.updateStatus(id: id, active: active);
  }
}
```

- [ ] **Step 6: Rodar analyze**

Run: `cd desktop && flutter analyze lib`
Expected: `No issues found!` (nenhum arquivo aqui é consumido ainda, mas deve compilar isoladamente).

- [ ] **Step 7: Commit**

```bash
git add desktop/lib/features/citizens/domain
git commit -m "feat(desktop): adiciona camada de dominio da feature citizens"
```

---

### Task 6: Camada de dados da feature `citizens` (model com TDD, data source, repository impl)

**Files:**
- Create: `desktop/test/features/citizens/data/models/citizen_model_test.dart`
- Create: `desktop/lib/features/citizens/data/models/citizen_model.dart`
- Create: `desktop/lib/features/citizens/data/datasources/citizens_remote_data_source.dart`
- Create: `desktop/lib/features/citizens/data/repositories/citizens_repository_impl.dart`

**Interfaces:**
- Consumes: `Citizen`, `PaginatedCitizens`, `CitizensRepository` (Task 5); `mapErrorToFailure(Object)` de `desktop/lib/core/network/failure_mapper.dart` (já existe).
- Produces: `class CitizenModel extends Citizen` com `factory CitizenModel.fromJson(Map<String, dynamic>)`; `class CitizensRemoteDataSource` com `list({required int page, String? search})` (retorna `({List<CitizenModel> items, int total})`) e `updateStatus({required String id, required bool active})` (retorna `CitizenModel`); `class CitizensRepositoryImpl implements CitizensRepository`. Consumidos pela Task 7 (`citizens_providers.dart`).

- [ ] **Step 1: Escrever o teste do model (falhando)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/citizens/data/models/citizen_model.dart';

void main() {
  group('CitizenModel.fromJson', () {
    test('parseia todos os campos presentes', () {
      final model = CitizenModel.fromJson({
        'id': 'citizen-1',
        'name': 'Maria Cidada',
        'email': 'maria@example.com',
        'phone': '(45) 99999-0000',
        'cpf': '12345678900',
        'avatarUrl': null,
        'active': true,
        'createdAt': '2026-07-08T12:00:00.000Z',
      });

      expect(model.id, 'citizen-1');
      expect(model.name, 'Maria Cidada');
      expect(model.email, 'maria@example.com');
      expect(model.phone, '(45) 99999-0000');
      expect(model.cpf, '12345678900');
      expect(model.active, true);
      expect(model.createdAt, DateTime.parse('2026-07-08T12:00:00.000Z'));
    });

    test('phone e cpf ficam nulos quando ausentes, active assume true por padrao', () {
      final model = CitizenModel.fromJson({
        'id': 'citizen-2',
        'name': 'Ana',
        'email': 'ana@example.com',
        'createdAt': '2026-07-08T12:00:00.000Z',
      });

      expect(model.phone, isNull);
      expect(model.cpf, isNull);
      expect(model.active, true);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `cd desktop && flutter test test/features/citizens/data/models/citizen_model_test.dart`
Expected: FAIL — `Error: URI doesn't exist: 'package:goodroads_desktop/features/citizens/data/models/citizen_model.dart'`

- [ ] **Step 3: Criar `citizen_model.dart`**

```dart
import '../../domain/entities/citizen.dart';

class CitizenModel extends Citizen {
  const CitizenModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.cpf,
    super.avatarUrl,
    required super.active,
    required super.createdAt,
  });

  factory CitizenModel.fromJson(Map<String, dynamic> json) {
    return CitizenModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      cpf: json['cpf'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `cd desktop && flutter test test/features/citizens/data/models/citizen_model_test.dart`
Expected: PASS — 2 testes.

- [ ] **Step 5: Criar `citizens_remote_data_source.dart`**

```dart
import 'package:dio/dio.dart';
import '../models/citizen_model.dart';

class CitizensRemoteDataSource {
  const CitizensRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<CitizenModel> items, int total})> list({required int page, String? search}) async {
    final response = await _dio.get(
      '/citizens',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>).map((item) => CitizenModel.fromJson(item as Map<String, dynamic>)).toList();
    return (items: items, total: data['total'] as int);
  }

  Future<CitizenModel> updateStatus({required String id, required bool active}) async {
    final response = await _dio.patch('/citizens/$id/status', data: {'active': active});
    return CitizenModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

- [ ] **Step 6: Criar `citizens_repository_impl.dart`**

```dart
import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/citizen.dart';
import '../../domain/entities/paginated_citizens.dart';
import '../../domain/repositories/citizens_repository.dart';
import '../datasources/citizens_remote_data_source.dart';

class CitizensRepositoryImpl implements CitizensRepository {
  const CitizensRepositoryImpl(this._remote);
  final CitizensRemoteDataSource _remote;

  static const _pageSize = 20;

  @override
  Future<Result<PaginatedCitizens>> list({required int page, String? search}) async {
    try {
      final result = await _remote.list(page: page, search: search);
      return Result.success(
        PaginatedCitizens(items: result.items, total: result.total, page: page, pageSize: _pageSize),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<Citizen>> updateStatus({required String id, required bool active}) async {
    try {
      return Result.success(await _remote.updateStatus(id: id, active: active));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
```

- [ ] **Step 7: Rodar analyze**

Run: `cd desktop && flutter analyze lib`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add desktop/lib/features/citizens/data desktop/test/features/citizens/data
git commit -m "feat(desktop): adiciona camada de dados da feature citizens com testes"
```

---

### Task 7: Providers e controller paginado da tela "Cidadãos"

**Files:**
- Create: `desktop/lib/features/citizens/presentation/controllers/citizens_providers.dart`
- Create: `desktop/lib/features/citizens/presentation/controllers/citizens_list_controller.dart`

**Interfaces:**
- Consumes: `dioProvider` de `desktop/lib/core/di/providers.dart` (já existe); `CitizensRemoteDataSource`, `CitizensRepositoryImpl`, `CitizensRepository`, `ListCitizensUseCase`, `UpdateCitizenStatusUseCase` (Tasks 5 e 6).
- Produces: `final citizensRepositoryProvider = Provider<CitizensRepository>(...)`; `final listCitizensUseCaseProvider = Provider(...)`; `final updateCitizenStatusUseCaseProvider = Provider(...)`; `class CitizensListController extends AsyncNotifier<PaginatedCitizens>` com `page`, `search`, `refresh()`, `setPage(int)`, `setSearch(String?)`; `final citizensListControllerProvider = AsyncNotifierProvider<CitizensListController, PaginatedCitizens>(...)`. Consumidos pelas Tasks 8 e 9.

- [ ] **Step 1: Criar `citizens_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/citizens_remote_data_source.dart';
import '../../data/repositories/citizens_repository_impl.dart';
import '../../domain/repositories/citizens_repository.dart';
import '../../domain/usecases/list_citizens_usecase.dart';
import '../../domain/usecases/update_citizen_status_usecase.dart';

final citizensRemoteDataSourceProvider = Provider((ref) => CitizensRemoteDataSource(ref.watch(dioProvider)));

final citizensRepositoryProvider = Provider<CitizensRepository>((ref) {
  return CitizensRepositoryImpl(ref.watch(citizensRemoteDataSourceProvider));
});

final listCitizensUseCaseProvider = Provider((ref) => ListCitizensUseCase(ref.watch(citizensRepositoryProvider)));
final updateCitizenStatusUseCaseProvider =
    Provider((ref) => UpdateCitizenStatusUseCase(ref.watch(citizensRepositoryProvider)));
```

- [ ] **Step 2: Criar `citizens_list_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/paginated_citizens.dart';
import 'citizens_providers.dart';

/// Estado paginado da secao "Cidadaos" na tela "Usuarios". Mesmo padrao de
/// paginas explicitas do OccurrencesListController (nao scroll infinito),
/// ja que a tela usa uma DataTable.
class CitizensListController extends AsyncNotifier<PaginatedCitizens> {
  int _page = 1;
  String? _search;

  int get page => _page;
  String? get search => _search;

  @override
  Future<PaginatedCitizens> build() => _fetch();

  Future<PaginatedCitizens> _fetch() async {
    final result = await ref.read(listCitizensUseCaseProvider)(page: _page, search: _search);
    return result.fold((failure) => throw failure, (data) => data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setPage(int page) async {
    _page = page;
    await refresh();
  }

  Future<void> setSearch(String? search) async {
    _search = (search == null || search.isEmpty) ? null : search;
    _page = 1;
    await refresh();
  }
}

final citizensListControllerProvider =
    AsyncNotifierProvider<CitizensListController, PaginatedCitizens>(CitizensListController.new);
```

- [ ] **Step 3: Rodar analyze**

Run: `cd desktop && flutter analyze lib`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add desktop/lib/features/citizens/presentation/controllers
git commit -m "feat(desktop): adiciona providers e controller paginado de citizens"
```

---

### Task 8: `CitizenDetailsDialog` (TDD)

**Files:**
- Create: `desktop/test/features/citizens/presentation/widgets/citizen_details_dialog_test.dart`
- Create: `desktop/lib/features/citizens/presentation/widgets/citizen_details_dialog.dart`

**Interfaces:**
- Consumes: `Citizen` (Task 5); `formatCpf` de `desktop/lib/core/utils/cpf_formatter.dart` (Task 4); `authControllerProvider`/`AuthController` de `desktop/lib/features/auth/presentation/controllers/auth_controller.dart` (já existe: `AsyncNotifier<StaffUser?>`, `.valueOrNull?.isAdmin`); `StaffUser` de `desktop/lib/features/auth/domain/entities/staff_user.dart` (já existe); `citizensListControllerProvider`, `updateCitizenStatusUseCaseProvider` (Task 7); `CitizensRepository` (Task 5, para o fake de teste); `Result`, `Failure`/`UnknownFailure` de `desktop/lib/core/error/result.dart` e `desktop/lib/core/error/failure.dart` (já existem).
- Produces: `class CitizenDetailsDialog` com `static Future<void> show(BuildContext, {required Citizen citizen})`. Consumido pela Task 9.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/core/error/failure.dart';
import 'package:goodroads_desktop/core/error/result.dart';
import 'package:goodroads_desktop/features/auth/domain/entities/staff_user.dart';
import 'package:goodroads_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/citizen.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/paginated_citizens.dart';
import 'package:goodroads_desktop/features/citizens/domain/repositories/citizens_repository.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_list_controller.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_providers.dart';
import 'package:goodroads_desktop/features/citizens/presentation/widgets/citizen_details_dialog.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final StaffUser _user;

  @override
  Future<StaffUser?> build() async => _user;
}

class _EmptyCitizensListController extends CitizensListController {
  @override
  Future<PaginatedCitizens> build() async => const PaginatedCitizens(items: [], total: 0, page: 1, pageSize: 20);
}

class _RecordingCitizensRepository implements CitizensRepository {
  (String, bool)? calledWith;

  @override
  Future<Result<PaginatedCitizens>> list({required int page, String? search}) => throw UnimplementedError();

  @override
  Future<Result<Citizen>> updateStatus({required String id, required bool active}) async {
    calledWith = (id, active);
    return Result.success(
      Citizen(id: id, name: 'Ana Cidada', email: 'ana@example.com', active: active, createdAt: DateTime(2026, 7, 8)),
    );
  }
}

final _citizen = Citizen(
  id: 'citizen-1',
  name: 'Ana Cidada',
  email: 'ana@example.com',
  phone: '(45) 98888-0000',
  cpf: '12345678900',
  active: true,
  createdAt: DateTime(2026, 7, 8),
);

Future<_RecordingCitizensRepository> _pumpDialog(WidgetTester tester, {required bool isAdmin}) async {
  final repo = _RecordingCitizensRepository();
  final user = StaffUser(
    id: 'staff-1',
    name: isAdmin ? 'Maria Admin' : 'Joao Funcionario',
    email: 'staff@prefeitura.gov',
    role: isAdmin ? 'ADMIN' : 'FUNCIONARIO',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(user)),
        citizensListControllerProvider.overrideWith(() => _EmptyCitizensListController()),
        citizensRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CitizenDetailsDialog.show(context, citizen: _citizen),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('mostra os dados do cidadao formatados', (tester) async {
    await _pumpDialog(tester, isAdmin: false);

    expect(find.text('Ana Cidada'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('(45) 98888-0000'), findsOneWidget);
    expect(find.text('123.456.789-00'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('botao Desativar conta nao aparece para FUNCIONARIO', (tester) async {
    await _pumpDialog(tester, isAdmin: false);

    expect(find.text('Desativar conta'), findsNothing);
  });

  testWidgets('ADMIN ve o botao e ele chama o use case ao ser tocado', (tester) async {
    final repo = await _pumpDialog(tester, isAdmin: true);

    expect(find.text('Desativar conta'), findsOneWidget);

    await tester.tap(find.text('Desativar conta'));
    await tester.pumpAndSettle();

    expect(repo.calledWith, ('citizen-1', false));
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `cd desktop && flutter test test/features/citizens/presentation/widgets/citizen_details_dialog_test.dart`
Expected: FAIL — `Error: URI doesn't exist: 'package:goodroads_desktop/features/citizens/presentation/widgets/citizen_details_dialog.dart'`

- [ ] **Step 3: Criar `citizen_details_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/cpf_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/citizen.dart';
import '../controllers/citizens_list_controller.dart';
import '../controllers/citizens_providers.dart';

/// Dialog somente-leitura com as informacoes de um cidadao (conta gerenciada
/// exclusivamente pelo app mobile). O unico controle de escrita disponivel
/// aqui e ativar/desativar a conta, restrito a ADMIN — mesma restricao do
/// backend (ver backend/src/modules/citizens/citizens.routes.ts).
class CitizenDetailsDialog extends ConsumerStatefulWidget {
  const CitizenDetailsDialog({super.key, required this.citizen});

  final Citizen citizen;

  static Future<void> show(BuildContext context, {required Citizen citizen}) {
    return showDialog(context: context, builder: (_) => CitizenDetailsDialog(citizen: citizen));
  }

  @override
  ConsumerState<CitizenDetailsDialog> createState() => _CitizenDetailsDialogState();
}

class _CitizenDetailsDialogState extends ConsumerState<CitizenDetailsDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _toggleActive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(updateCitizenStatusUseCaseProvider)(
      id: widget.citizen.id,
      active: !widget.citizen.active,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) {
        ref.read(citizensListControllerProvider.notifier).refresh();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final citizen = widget.citizen;
    final isAdmin = ref.watch(authControllerProvider).valueOrNull?.isAdmin ?? false;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: const Text('Cidadão'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            _DetailRow(label: 'Nome', value: citizen.name),
            _DetailRow(label: 'E-mail', value: citizen.email),
            _DetailRow(label: 'Telefone', value: citizen.phone ?? '—'),
            _DetailRow(label: 'CPF', value: formatCpf(citizen.cpf) ?? '—'),
            _DetailRow(label: 'Cadastrado em', value: dateFormat.format(citizen.createdAt)),
            _DetailRow(label: 'Status', value: citizen.active ? 'Ativo' : 'Inativo'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        if (isAdmin)
          FilledButton.icon(
            onPressed: _isLoading ? null : _toggleActive,
            icon: Icon(citizen.active ? Icons.block : Icons.check_circle_outline),
            label: Text(_isLoading ? 'Aguarde...' : (citizen.active ? 'Desativar conta' : 'Reativar conta')),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
          Text(value),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `cd desktop && flutter test test/features/citizens/presentation/widgets/citizen_details_dialog_test.dart`
Expected: PASS — 3 testes.

- [ ] **Step 5: Rodar analyze**

Run: `cd desktop && flutter analyze lib test`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add desktop/lib/features/citizens/presentation/widgets desktop/test/features/citizens/presentation/widgets
git commit -m "feat(desktop): adiciona CitizenDetailsDialog com testes"
```

---

### Task 9: Reestruturar `staff_page.dart` em 3 seções (TDD)

**Files:**
- Create: `desktop/test/features/staff/presentation/pages/staff_page_test.dart`
- Modify: `desktop/lib/features/staff/presentation/pages/staff_page.dart`

**Interfaces:**
- Consumes: `staffListProvider` de `desktop/lib/features/staff/presentation/controllers/staff_providers.dart` (já existe: `FutureProvider.autoDispose<List<StaffMember>>`); `StaffMember` (já existe, campo `role` é `'ADMIN'` ou `'FUNCIONARIO'`); `StaffFormDialog` (já existe); `authControllerProvider` (já existe); `citizensListControllerProvider` (Task 7); `CitizenDetailsDialog` (Task 8); `formatCpf` (Task 4); `EmptyState`, `SectionHeader`, `SkeletonRow` (já existem).
- Produces: `StaffPage` continua sendo o widget montado na rota `/usuarios` (nenhuma mudança em `app_router.dart`/`app_routes.dart`).

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/features/auth/domain/entities/staff_user.dart';
import 'package:goodroads_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/citizen.dart';
import 'package:goodroads_desktop/features/citizens/domain/entities/paginated_citizens.dart';
import 'package:goodroads_desktop/features/citizens/presentation/controllers/citizens_list_controller.dart';
import 'package:goodroads_desktop/features/staff/domain/entities/staff_member.dart';
import 'package:goodroads_desktop/features/staff/presentation/controllers/staff_providers.dart';
import 'package:goodroads_desktop/features/staff/presentation/pages/staff_page.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._user);
  final StaffUser _user;

  @override
  Future<StaffUser?> build() async => _user;
}

class _FakeCitizensListController extends CitizensListController {
  @override
  Future<PaginatedCitizens> build() async => PaginatedCitizens(
        items: [
          Citizen(
            id: 'citizen-1',
            name: 'Ana Cidada',
            email: 'ana@example.com',
            active: true,
            createdAt: DateTime(2026, 7, 8),
          ),
        ],
        total: 1,
        page: 1,
        pageSize: 20,
      );
}

const _admin = StaffUser(id: 'admin-1', name: 'Maria Admin', email: 'maria@prefeitura.gov', role: 'ADMIN');

const _staff = [
  StaffMember(id: 'admin-1', name: 'Maria Admin', email: 'maria@prefeitura.gov', role: 'ADMIN'),
  StaffMember(id: 'func-1', name: 'Joao Funcionario', email: 'joao@prefeitura.gov', role: 'FUNCIONARIO'),
];

Future<void> _pumpUsersPage(WidgetTester tester) async {
  // Layout desktop assume janela larga (ver desktop/CLAUDE.md); o viewport
  // padrao de teste (800x600) estoura a DataTable de cidadaos.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(_admin)),
        staffListProvider.overrideWith((ref) async => _staff),
        citizensListControllerProvider.overrideWith(() => _FakeCitizensListController()),
      ],
      child: const MaterialApp(home: StaffPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('separa administradores, funcionarios e cidadaos em secoes', (tester) async {
    await _pumpUsersPage(tester);

    expect(find.text('Administradores'), findsOneWidget);
    expect(find.text('Funcionários'), findsOneWidget);
    expect(find.text('Cidadãos'), findsOneWidget);

    expect(find.text('Maria Admin'), findsOneWidget);
    expect(find.text('Joao Funcionario'), findsOneWidget);
    expect(find.text('Ana Cidada'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `cd desktop && flutter test test/features/staff/presentation/pages/staff_page_test.dart`
Expected: FAIL — não encontra os textos "Administradores"/"Funcionários" (tela atual não tem essas seções) ou não encontra "Ana Cidada"/"Cidadãos" (nenhuma seção de cidadãos existe ainda).

- [ ] **Step 3: Reescrever `staff_page.dart`**

Substituir todo o conteúdo do arquivo por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/cpf_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../citizens/presentation/controllers/citizens_list_controller.dart';
import '../../../citizens/presentation/widgets/citizen_details_dialog.dart';
import '../../domain/entities/staff_member.dart';
import '../controllers/staff_providers.dart';
import '../widgets/staff_form_dialog.dart';

/// Tela 7/10 do desktop: gestao de usuarios do sistema. Reune tres grupos —
/// Administradores e Funcionarios (contas de staff, GET /staff) e Cidadaos
/// (contas do app mobile, GET /citizens) — ver spec
/// docs/superpowers/specs/2026-07-10-tela-usuarios-cidadaos-desktop-design.md.
/// Leitura de staff liberada para qualquer FUNCIONARIO/ADMIN; criar/editar
/// conta de staff e ativar/desativar cidadao ficam restritos a ADMIN — mesma
/// regra do backend, reforcada aqui so para UX.
class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  final _citizenSearchController = TextEditingController();

  @override
  void dispose() {
    _citizenSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final isAdmin = ref.watch(authControllerProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Usuários',
              subtitle: 'Administradores, funcionários e cidadãos cadastrados no sistema.',
              action: isAdmin
                  ? FilledButton.icon(
                      onPressed: () => StaffFormDialog.show(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Novo funcionário'),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            staffAsync.when(
              loading: () => const Column(children: [SkeletonRow(), SkeletonRow()]),
              error: (error, _) => Text('Não foi possível carregar a equipe: $error'),
              data: (staff) {
                final admins = staff.where((m) => m.role == 'ADMIN').toList();
                final funcionarios = staff.where((m) => m.role == 'FUNCIONARIO').toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StaffGroupSection(title: 'Administradores', members: admins, isAdmin: isAdmin),
                    const SizedBox(height: 24),
                    _StaffGroupSection(title: 'Funcionários', members: funcionarios, isAdmin: isAdmin),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Cidadãos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _citizenSearchController,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nome ou e-mail',
                ),
                onSubmitted: (value) => ref.read(citizensListControllerProvider.notifier).setSearch(value),
              ),
            ),
            const SizedBox(height: 12),
            const _CitizensSection(),
          ],
        ),
      ),
    );
  }
}

class _StaffGroupSection extends StatelessWidget {
  const _StaffGroupSection({required this.title, required this.members, required this.isAdmin});

  final String title;
  final List<StaffMember> members;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum registro.', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          )
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?')),
                  title: Text(member.name),
                  subtitle: Text('${member.email}${member.active ? '' : ' · Inativo'}'),
                  trailing: isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => StaffFormDialog.show(context, staff: member),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CitizensSection extends ConsumerWidget {
  const _CitizensSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizensAsync = ref.watch(citizensListControllerProvider);
    final controller = ref.read(citizensListControllerProvider.notifier);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return citizensAsync.when(
      loading: () => const Column(children: [SkeletonRow(), SkeletonRow()]),
      error: (error, _) => Text('Não foi possível carregar os cidadãos: $error'),
      data: (page) {
        if (page.items.isEmpty) {
          return const EmptyState(icon: Icons.groups_outlined, title: 'Nenhum cidadão encontrado');
        }
        return Column(
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nome')),
                    DataColumn(label: Text('E-mail')),
                    DataColumn(label: Text('Telefone')),
                    DataColumn(label: Text('CPF')),
                    DataColumn(label: Text('Cadastrado em')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final citizen in page.items)
                      DataRow(
                        onSelectChanged: (_) => CitizenDetailsDialog.show(context, citizen: citizen),
                        cells: [
                          DataCell(Text(citizen.name)),
                          DataCell(Text(citizen.email)),
                          DataCell(Text(citizen.phone ?? '—')),
                          DataCell(Text(formatCpf(citizen.cpf) ?? '—')),
                          DataCell(Text(dateFormat.format(citizen.createdAt))),
                          DataCell(Text(citizen.active ? 'Ativo' : 'Inativo')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${page.total} cidadão(s) · página ${page.page} de ${page.totalPages}'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: page.page > 1 ? () => controller.setPage(page.page - 1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: page.hasNextPage ? () => controller.setPage(page.page + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `cd desktop && flutter test test/features/staff/presentation/pages/staff_page_test.dart`
Expected: PASS — 1 teste.

- [ ] **Step 5: Commit**

```bash
git add desktop/lib/features/staff/presentation/pages/staff_page.dart desktop/test/features/staff/presentation/pages/staff_page_test.dart
git commit -m "feat(desktop): reestrutura tela Usuarios em 3 secoes com cidadaos"
```

---

### Task 10: Verificação final completa

**Files:** nenhum (apenas comandos de verificação — nenhuma mudança de código esperada).

- [ ] **Step 1: Backend — typecheck, lint e testes completos**

Run: `cd backend && npx tsc --noEmit && npm run lint && npm test`
Expected: sem erros de tipo, lint limpo, todos os testes passando (suíte completa, incluindo os 5 novos de `citizens.service.test.ts`).

- [ ] **Step 2: Desktop — analyze e testes completos**

Run: `cd desktop && flutter analyze lib test && flutter test`
Expected: `No issues found!` e todos os testes passando (suíte completa, incluindo os novos de `cpf_formatter_test.dart`, `citizen_model_test.dart`, `citizen_details_dialog_test.dart` e `staff_page_test.dart`).

- [ ] **Step 3: Conferir que nenhuma referência a Google Maps foi introduzida (regra do `desktop/CLAUDE.md`)**

Run: `cd desktop && grep -ril "google_maps\|GoogleMap" lib || echo "OK: nenhuma referencia encontrada"`
Expected: `OK: nenhuma referencia encontrada`.

- [ ] **Step 4: Conferir `git status` — nada solto fora do que foi commitado nas tasks anteriores**

Run: `git status --short`
Expected: working tree limpo (todas as mudanças já commitadas nas Tasks 1–9).
