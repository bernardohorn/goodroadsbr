import { OccurrencePriority, OccurrenceStatus, RoleName } from '@prisma/client';
import {
  ALLOWED_STATUS_TRANSITIONS,
  MAX_PHOTOS_PER_OCCURRENCE,
  OCCURRENCE_PROTOCOL_PREFIX,
  OCCURRENCE_STATUS_LABELS
} from '../../config/constants';
import { AppError } from '../../core/errors/AppError';
import { storageProvider } from '../../infra/storage/storage.provider';
import { NotificationsService } from '../notifications/notifications.service';
import { OccurrenceListFilters, OccurrencesRepository, Pagination } from './occurrences.repository';

interface AuthContext {
  userId: string;
  role: RoleName;
  municipalityId: string | null;
}

interface UploadedFile {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
}

function assertOwnershipOrStaff(auth: AuthContext, citizenId: string) {
  const isOwner = auth.userId === citizenId;
  const isStaff = auth.role === RoleName.FUNCIONARIO || auth.role === RoleName.ADMIN;
  if (!isOwner && !isStaff) {
    throw AppError.forbidden('Voce nao tem permissao para acessar esta ocorrencia.');
  }
}

/**
 * Regras de negocio do dominio de ocorrencias — o coracao do produto.
 * Depende de OccurrencesRepository (Prisma isolado), StorageProvider
 * (upload de fotos, ja abstraido para trocar de provedor) e
 * NotificationsService (registra + dispara a notificacao de mudanca de
 * status, requisito explicito do briefing).
 */
export class OccurrencesService {
  constructor(
    private readonly repo: OccurrencesRepository = new OccurrencesRepository(),
    private readonly notifications: NotificationsService = new NotificationsService()
  ) {}

  async create(
    auth: AuthContext,
    dto: { description: string; latitude: number; longitude: number; address?: string; categoryId?: string },
    files: UploadedFile[]
  ) {
    if (files.length === 0) {
      throw AppError.validation('E obrigatorio anexar ao menos uma foto do problema.');
    }
    if (files.length > MAX_PHOTOS_PER_OCCURRENCE) {
      throw AppError.validation(`Envie no maximo ${MAX_PHOTOS_PER_OCCURRENCE} fotos por ocorrencia.`);
    }

    const year = new Date().getFullYear();
    const sequence = await this.repo.nextProtocolNumber(year);
    const protocolNumber = `${OCCURRENCE_PROTOCOL_PREFIX}-${year}-${String(sequence).padStart(6, '0')}`;

    const occurrence = await this.repo.create({
      protocolNumber,
      citizenId: auth.userId,
      municipalityId: auth.municipalityId,
      categoryId: dto.categoryId,
      description: dto.description,
      latitude: dto.latitude,
      longitude: dto.longitude,
      address: dto.address
    });

    const uploads = await Promise.all(
      files.map((file, index) =>
        storageProvider.upload({ buffer: file.buffer, originalName: file.originalname, mimeType: file.mimetype }).then((result) => ({
          url: result.url,
          thumbnailUrl: result.url,
          storageKey: result.key,
          order: index
        }))
      )
    );

    await this.repo.addPhotos(occurrence.id, uploads);

    // Registro inicial no historico (facilita mostrar "Pendente desde ..." na timeline).
    await this.repo.createStatusHistory({
      occurrenceId: occurrence.id,
      previousStatus: null,
      newStatus: OccurrenceStatus.PENDENTE,
      changedById: auth.userId,
      note: 'Ocorrencia registrada pelo cidadao.'
    });

    return this.repo.findById(occurrence.id);
  }

  async list(
    auth: AuthContext,
    filters: Omit<OccurrenceListFilters, 'citizenId' | 'municipalityId'>,
    pagination: Pagination
  ) {
    const isStaff = auth.role === RoleName.FUNCIONARIO || auth.role === RoleName.ADMIN;

    const scopedFilters: OccurrenceListFilters = {
      ...filters,
      citizenId: isStaff ? undefined : auth.userId,
      municipalityId: isStaff ? auth.municipalityId : undefined
    };

    const { items, total } = await this.repo.findMany(scopedFilters, pagination);
    return { items, total, page: pagination.page, pageSize: pagination.pageSize };
  }

  async getById(auth: AuthContext, id: string) {
    const occurrence = await this.repo.findById(id);
    if (!occurrence) {
      throw AppError.notFound('Ocorrencia nao encontrada.');
    }
    assertOwnershipOrStaff(auth, occurrence.citizenId);
    return occurrence;
  }

  async updateStatus(auth: AuthContext, id: string, dto: { status: OccurrenceStatus; note?: string }) {
    const occurrence = await this.repo.findById(id);
    if (!occurrence) {
      throw AppError.notFound('Ocorrencia nao encontrada.');
    }

    const allowedNextStatuses = ALLOWED_STATUS_TRANSITIONS[occurrence.status] ?? [];
    if (!allowedNextStatuses.includes(dto.status)) {
      throw AppError.validation(
        `Nao e possivel mudar o status de "${occurrence.status}" para "${dto.status}".`
      );
    }

    const previousStatus = occurrence.status;
    const resolvedAt = dto.status === OccurrenceStatus.RESOLVIDA ? new Date() : null;

    const updated = await this.repo.updateStatus(id, { status: dto.status, resolvedAt });

    await this.repo.createStatusHistory({
      occurrenceId: id,
      previousStatus,
      newStatus: dto.status,
      changedById: auth.userId,
      note: dto.note
    });

    await this.notifications.notifyStatusChange({
      userId: occurrence.citizenId,
      occurrenceId: id,
      protocolNumber: occurrence.protocolNumber,
      newStatusLabel: OCCURRENCE_STATUS_LABELS[dto.status] ?? dto.status
    });

    return updated;
  }

  async updateDetails(
    id: string,
    dto: {
      categoryId?: string;
      priority?: OccurrencePriority;
      teamId?: string;
      assignedToId?: string;
      internalNotes?: string;
    }
  ) {
    const occurrence = await this.repo.findById(id);
    if (!occurrence) {
      throw AppError.notFound('Ocorrencia nao encontrada.');
    }
    return this.repo.updateDetails(id, dto);
  }

  async getHistory(auth: AuthContext, id: string) {
    const occurrence = await this.repo.findById(id);
    if (!occurrence) {
      throw AppError.notFound('Ocorrencia nao encontrada.');
    }
    assertOwnershipOrStaff(auth, occurrence.citizenId);
    return this.repo.listHistory(id);
  }
}
