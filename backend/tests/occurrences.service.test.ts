import { OccurrencePriority, OccurrenceStatus, RoleName } from '@prisma/client';
import { OccurrencesService } from '../src/modules/occurrences/occurrences.service';
import { OccurrencesRepository, OccurrenceDetail } from '../src/modules/occurrences/occurrences.repository';
import { NotificationsService } from '../src/modules/notifications/notifications.service';

jest.mock('../src/infra/storage/storage.provider', () => ({
  storageProvider: {
    upload: jest.fn().mockResolvedValue({ key: 'fake-key.jpg', url: 'http://localhost:3333/uploads/fake-key.jpg' })
  }
}));

type MockedRepo = {
  [K in keyof OccurrencesRepository]: jest.Mock;
};

function createMockRepo(): MockedRepo {
  return {
    nextProtocolNumber: jest.fn(),
    create: jest.fn(),
    addPhotos: jest.fn(),
    findById: jest.fn(),
    findMany: jest.fn(),
    updateStatus: jest.fn(),
    updateDetails: jest.fn(),
    createStatusHistory: jest.fn(),
    listHistory: jest.fn()
  } as unknown as MockedRepo;
}

function buildOccurrence(overrides: Partial<OccurrenceDetail> = {}): OccurrenceDetail {
  return {
    id: 'occ-1',
    protocolNumber: 'GR-2026-000001',
    municipalityId: null,
    citizenId: 'citizen-1',
    categoryId: null,
    teamId: null,
    assignedToId: null,
    description: 'Buraco grande na estrada',
    status: OccurrenceStatus.PENDENTE,
    priority: OccurrencePriority.MEDIA,
    latitude: -24.7,
    longitude: -53.1,
    address: null,
    internalNotes: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    resolvedAt: null,
    photos: [],
    category: null,
    team: null,
    citizen: { id: 'citizen-1', name: 'Maria', email: 'maria@example.com', phone: null },
    assignedTo: null,
    ...overrides
  } as OccurrenceDetail;
}

const citizenAuth = { userId: 'citizen-1', role: RoleName.CIDADAO, municipalityId: null };
const staffAuth = { userId: 'staff-1', role: RoleName.FUNCIONARIO, municipalityId: null };
const staffAuthMunA = { userId: 'staff-a', role: RoleName.FUNCIONARIO, municipalityId: 'municipio-a' };
const staffAuthMunB = { userId: 'staff-b', role: RoleName.FUNCIONARIO, municipalityId: 'municipio-b' };

describe('OccurrencesService', () => {
  let repo: MockedRepo;
  let notifications: { notifyStatusChange: jest.Mock };
  let service: OccurrencesService;

  beforeEach(() => {
    repo = createMockRepo();
    notifications = { notifyStatusChange: jest.fn().mockResolvedValue(undefined) };
    service = new OccurrencesService(
      repo as unknown as OccurrencesRepository,
      notifications as unknown as NotificationsService
    );
  });

  describe('create', () => {
    it('rejeita criacao sem nenhuma foto anexada', async () => {
      await expect(
        service.create(citizenAuth, { description: 'Buraco grande na via', latitude: -24.7, longitude: -53.1 }, [])
      ).rejects.toMatchObject({ code: 'VALIDATION_ERROR' });

      expect(repo.create).not.toHaveBeenCalled();
    });

    it('gera protocolo, cria a ocorrencia, envia fotos e registra o historico inicial', async () => {
      repo.nextProtocolNumber.mockResolvedValue(7);
      const created = buildOccurrence();
      repo.create.mockResolvedValue(created);
      repo.findById.mockResolvedValue(created);

      const file = { buffer: Buffer.from('fake-image'), originalname: 'foto.jpg', mimetype: 'image/jpeg' };

      await service.create(
        citizenAuth,
        { description: 'Buraco grande na via', latitude: -24.7, longitude: -53.1 },
        [file]
      );

      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({ citizenId: 'citizen-1', protocolNumber: expect.stringContaining('GR-') })
      );
      expect(repo.addPhotos).toHaveBeenCalledTimes(1);
      expect(repo.createStatusHistory).toHaveBeenCalledWith(
        expect.objectContaining({ previousStatus: null, newStatus: OccurrenceStatus.PENDENTE })
      );
    });
  });

  describe('getById', () => {
    it('permite que o proprio cidadao veja sua ocorrencia', async () => {
      repo.findById.mockResolvedValue(buildOccurrence());
      await expect(service.getById(citizenAuth, 'occ-1')).resolves.toMatchObject({ id: 'occ-1' });
    });

    it('bloqueia um cidadao de ver ocorrencia de outro cidadao', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ citizenId: 'outro-cidadao' }));
      await expect(service.getById(citizenAuth, 'occ-1')).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });

    it('permite que a equipe da prefeitura veja qualquer ocorrencia (staff sem prefeitura vinculada = admin de sistema)', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ citizenId: 'outro-cidadao' }));
      await expect(service.getById(staffAuth, 'occ-1')).resolves.toMatchObject({ id: 'occ-1' });
    });

    it('permite que funcionario veja ocorrencia da propria prefeitura', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ citizenId: 'outro-cidadao', municipalityId: 'municipio-a' }));
      await expect(service.getById(staffAuthMunA, 'occ-1')).resolves.toMatchObject({ id: 'occ-1' });
    });

    it('bloqueia funcionario de ver ocorrencia de outra prefeitura', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ citizenId: 'outro-cidadao', municipalityId: 'municipio-a' }));
      await expect(service.getById(staffAuthMunB, 'occ-1')).rejects.toMatchObject({ code: 'FORBIDDEN' });
    });

    it('permite que funcionario com prefeitura vinculada veja ocorrencia ainda sem prefeitura atribuida (cadastro de cidadao hoje nao atribui uma)', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ citizenId: 'outro-cidadao', municipalityId: null }));
      await expect(service.getById(staffAuthMunA, 'occ-1')).resolves.toMatchObject({ id: 'occ-1' });
    });
  });

  describe('updateStatus', () => {
    it('rejeita transicao invalida (RESOLVIDA -> PENDENTE)', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ status: OccurrenceStatus.RESOLVIDA }));

      await expect(
        service.updateStatus(staffAuth, 'occ-1', { status: OccurrenceStatus.PENDENTE })
      ).rejects.toMatchObject({ code: 'VALIDATION_ERROR' });

      expect(repo.updateStatus).not.toHaveBeenCalled();
    });

    it('aplica transicao valida, grava historico e notifica o cidadao', async () => {
      const occurrence = buildOccurrence({ status: OccurrenceStatus.PENDENTE });
      repo.findById.mockResolvedValue(occurrence);
      repo.updateStatus.mockResolvedValue({ ...occurrence, status: OccurrenceStatus.EM_ANDAMENTO });

      await service.updateStatus(staffAuth, 'occ-1', { status: OccurrenceStatus.EM_ANDAMENTO, note: 'Equipe a caminho' });

      expect(repo.updateStatus).toHaveBeenCalledWith('occ-1', { status: OccurrenceStatus.EM_ANDAMENTO, resolvedAt: null });
      expect(repo.createStatusHistory).toHaveBeenCalledWith(
        expect.objectContaining({ previousStatus: OccurrenceStatus.PENDENTE, newStatus: OccurrenceStatus.EM_ANDAMENTO })
      );
      expect(notifications.notifyStatusChange).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'citizen-1', occurrenceId: 'occ-1' })
      );
    });

    it('define resolvedAt ao mover para RESOLVIDA', async () => {
      const occurrence = buildOccurrence({ status: OccurrenceStatus.EM_ANDAMENTO });
      repo.findById.mockResolvedValue(occurrence);
      repo.updateStatus.mockResolvedValue({ ...occurrence, status: OccurrenceStatus.RESOLVIDA });

      await service.updateStatus(staffAuth, 'occ-1', { status: OccurrenceStatus.RESOLVIDA });

      expect(repo.updateStatus).toHaveBeenCalledWith('occ-1', {
        status: OccurrenceStatus.RESOLVIDA,
        resolvedAt: expect.any(Date)
      });
    });

    it('bloqueia funcionario de mudar status de ocorrencia de outra prefeitura', async () => {
      repo.findById.mockResolvedValue(
        buildOccurrence({ status: OccurrenceStatus.PENDENTE, municipalityId: 'municipio-a' })
      );

      await expect(
        service.updateStatus(staffAuthMunB, 'occ-1', { status: OccurrenceStatus.EM_ANDAMENTO })
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });

      expect(repo.updateStatus).not.toHaveBeenCalled();
    });
  });

  describe('updateDetails', () => {
    it('permite que funcionario da mesma prefeitura atualize detalhes', async () => {
      const occurrence = buildOccurrence({ municipalityId: 'municipio-a' });
      repo.findById.mockResolvedValue(occurrence);
      repo.updateDetails.mockResolvedValue({ ...occurrence, priority: OccurrencePriority.ALTA });

      await service.updateDetails(staffAuthMunA, 'occ-1', { priority: OccurrencePriority.ALTA });

      expect(repo.updateDetails).toHaveBeenCalledWith('occ-1', { priority: OccurrencePriority.ALTA });
    });

    it('bloqueia funcionario de outra prefeitura de atualizar detalhes', async () => {
      repo.findById.mockResolvedValue(buildOccurrence({ municipalityId: 'municipio-a' }));

      await expect(
        service.updateDetails(staffAuthMunB, 'occ-1', { priority: OccurrencePriority.ALTA })
      ).rejects.toMatchObject({ code: 'FORBIDDEN' });

      expect(repo.updateDetails).not.toHaveBeenCalled();
    });
  });
});
