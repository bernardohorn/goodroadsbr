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
