import { Request } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../infra/database/prisma.client';
import { logger } from '../logger/logger';

/**
 * Registra uma acao sensivel na tabela `audit_logs`. Chamado explicitamente
 * pelos services (nao como middleware global), pois cada acao precisa de
 * metadata especifica (ex.: status anterior/novo em uma mudanca de status).
 * Uma unica tabela/funcao de auditoria serve qualquer entidade futura sem
 * precisar de uma tabela de log por modulo.
 */
export async function recordAuditLog(params: {
  req: Request;
  action: string;
  entity: string;
  entityId?: string;
  metadata?: Record<string, unknown>;
}) {
  try {
    await prisma.auditLog.create({
      data: {
        userId: params.req.auth?.userId,
        action: params.action,
        entity: params.entity,
        entityId: params.entityId,
        metadata: params.metadata as Prisma.InputJsonValue | undefined,
        ipAddress: params.req.ip
      }
    });
  } catch (err) {
    // Auditoria nunca deve derrubar a requisicao principal.
    logger.error({ err }, 'Falha ao gravar audit log');
  }
}
