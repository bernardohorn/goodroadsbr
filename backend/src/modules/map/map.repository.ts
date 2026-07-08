import { PrismaClient } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';

export interface MapPin {
  id: string;
  protocolNumber: string;
  status: string;
  priority: string;
  latitude: number;
  longitude: number;
}

// Numero maximo de pontos retornados por consulta, para nao sobrecarregar o
// cliente (app mobile / desktop) quando o viewport do mapa for muito amplo.
// Em uma proxima iteracao, isso pode evoluir para clustering feito no
// proprio banco (ST_ClusterKMeans) quando o volume de ocorrencias crescer.
const MAX_PINS = 500;

export class MapRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  /**
   * Busca ocorrencias dentro de uma bounding box usando o indice GiST da
   * coluna geoespacial `location` (ver prisma/sql/postgis.sql). Filtros de
   * status/categoria sao aplicados via COALESCE (parametro nulo = filtro
   * desativado), mantendo a query parametrizada (sem risco de SQL
   * injection mesmo sendo raw SQL).
   */
  async findInBoundingBox(
    bbox: { north: number; south: number; east: number; west: number },
    filters: { status?: string; categoryId?: string }
  ): Promise<MapPin[]> {
    return this.db.$queryRaw<MapPin[]>`
      SELECT
        id,
        protocol_number AS "protocolNumber",
        status::text AS status,
        priority::text AS priority,
        latitude,
        longitude
      FROM occurrences
      WHERE ST_Intersects(
        location,
        ST_MakeEnvelope(${bbox.west}, ${bbox.south}, ${bbox.east}, ${bbox.north}, 4326)::geography
      )
      AND (${filters.status ?? null}::text IS NULL OR status::text = ${filters.status ?? null})
      AND (${filters.categoryId ?? null}::text IS NULL OR category_id = ${filters.categoryId ?? null})
      ORDER BY created_at DESC
      LIMIT ${MAX_PINS}
    `;
  }
}
