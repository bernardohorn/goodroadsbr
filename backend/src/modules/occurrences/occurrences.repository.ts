import { OccurrencePriority, OccurrenceStatus, Prisma, PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

const occurrenceDetail = Prisma.validator<Prisma.OccurrenceDefaultArgs>()({
  include: {
    photos: { orderBy: { order: 'asc' } },
    category: true,
    team: true,
    citizen: { select: { id: true, name: true, email: true, phone: true } },
    assignedTo: { select: { id: true, name: true, email: true } }
  }
});

export type OccurrenceDetail = Prisma.OccurrenceGetPayload<typeof occurrenceDetail>;

export interface OccurrenceListFilters {
  status?: OccurrenceStatus;
  priority?: OccurrencePriority;
  categoryId?: string;
  search?: string;
  citizenId?: string; // presente apenas quando o solicitante e um cidadao
  municipalityId?: string | null;
}

export interface Pagination {
  page: number;
  pageSize: number;
  sortBy: 'createdAt' | 'updatedAt' | 'priority' | 'status';
  sortOrder: 'asc' | 'desc';
}

function buildWhere(filters: OccurrenceListFilters): Prisma.OccurrenceWhereInput {
  // Cada filtro "OR" (prefeitura, busca textual) vira uma entrada separada
  // de `conditions`, combinada no final com `AND` — nunca um objeto so com
  // duas chaves `OR` (a segunda sobrescreveria a primeira em silencio).
  const conditions: Prisma.OccurrenceWhereInput[] = [];

  if (filters.citizenId) conditions.push({ citizenId: filters.citizenId });
  if (filters.status) conditions.push({ status: filters.status });
  if (filters.priority) conditions.push({ priority: filters.priority });
  if (filters.categoryId) conditions.push({ categoryId: filters.categoryId });
  if (filters.municipalityId) {
    // O cadastro de cidadao hoje nao atribui uma prefeitura (ver
    // occurrences.service.ts, assertAccess), entao toda ocorrencia nasce
    // com municipalityId nulo. Filtrar so por igualdade excluiria TODAS as
    // ocorrencias para qualquer funcionario com prefeitura vinculada —
    // por isso ocorrencias sem prefeitura atribuida tambem entram no
    // resultado, espelhando a mesma leniencia de assertAccess.
    conditions.push({ OR: [{ municipalityId: filters.municipalityId }, { municipalityId: null }] });
  }
  if (filters.search) {
    conditions.push({
      OR: [
        { description: { contains: filters.search, mode: 'insensitive' } },
        { protocolNumber: { contains: filters.search, mode: 'insensitive' } },
        { address: { contains: filters.search, mode: 'insensitive' } }
      ]
    });
  }

  return conditions.length > 0 ? { AND: conditions } : {};
}

export class OccurrencesRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  /**
   * Gera o proximo numero de protocolo do ano de forma atomica, usando
   * INSERT ... ON CONFLICT DO UPDATE (upsert atomico no nivel do banco).
   * Uma abordagem "ler o maior numero existente e somar 1" teria uma
   * condicao de corrida real sob carga (duas ocorrencias criadas quase
   * simultaneamente poderiam calcular o mesmo proximo numero).
   */
  async nextProtocolNumber(year: number): Promise<number> {
    const rows = await this.db.$queryRaw<{ last_value: number }[]>`
      INSERT INTO protocol_sequences (year, last_value)
      VALUES (${year}, 1)
      ON CONFLICT (year)
      DO UPDATE SET last_value = protocol_sequences.last_value + 1
      RETURNING last_value
    `;
    return rows[0].last_value;
  }

  create(data: {
    protocolNumber: string;
    citizenId: string;
    municipalityId?: string | null;
    categoryId?: string;
    description: string;
    latitude: number;
    longitude: number;
    address?: string;
  }) {
    return this.db.occurrence.create({ data, ...occurrenceDetail });
  }

  addPhotos(
    occurrenceId: string,
    photos: Array<{ url: string; thumbnailUrl?: string; storageKey: string; order: number }>
  ) {
    return this.db.occurrencePhoto.createMany({
      data: photos.map((p) => ({ ...p, occurrenceId }))
    });
  }

  findById(id: string): Promise<OccurrenceDetail | null> {
    return this.db.occurrence.findUnique({ where: { id }, ...occurrenceDetail });
  }

  async findMany(filters: OccurrenceListFilters, pagination: Pagination) {
    const where = buildWhere(filters);
    const [items, total] = await this.db.$transaction([
      this.db.occurrence.findMany({
        where,
        orderBy: { [pagination.sortBy]: pagination.sortOrder },
        skip: (pagination.page - 1) * pagination.pageSize,
        take: pagination.pageSize,
        ...occurrenceDetail
      }),
      this.db.occurrence.count({ where })
    ]);
    return { items, total };
  }

  updateStatus(id: string, data: { status: OccurrenceStatus; resolvedAt: Date | null }) {
    return this.db.occurrence.update({ where: { id }, data, ...occurrenceDetail });
  }

  updateDetails(
    id: string,
    data: {
      categoryId?: string;
      priority?: OccurrencePriority;
      teamId?: string;
      assignedToId?: string;
      internalNotes?: string;
    }
  ) {
    return this.db.occurrence.update({ where: { id }, data, ...occurrenceDetail });
  }

  createStatusHistory(data: {
    occurrenceId: string;
    previousStatus: OccurrenceStatus | null;
    newStatus: OccurrenceStatus;
    changedById: string;
    note?: string;
  }) {
    return this.db.occurrenceStatusHistory.create({ data });
  }

  listHistory(occurrenceId: string) {
    return this.db.occurrenceStatusHistory.findMany({
      where: { occurrenceId },
      orderBy: { changedAt: 'asc' },
      include: { changedBy: { select: { id: true, name: true } } }
    });
  }
}
