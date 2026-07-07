import { OccurrencePriority, OccurrenceStatus } from '@prisma/client';
import { ReportsService } from '../src/modules/reports/reports.service';
import { ReportsRepository } from '../src/modules/reports/reports.repository';

type MockedRepo = { [K in keyof ReportsRepository]: jest.Mock };

function createMockRepo(): MockedRepo {
  return { findForExport: jest.fn() } as unknown as MockedRepo;
}

function buildOccurrence() {
  return {
    protocolNumber: 'GR-2026-000001',
    status: OccurrenceStatus.PENDENTE,
    priority: OccurrencePriority.ALTA,
    category: { name: 'Buraco' },
    team: { name: 'Equipe Norte' },
    assignedTo: { name: 'Joao Funcionario' },
    citizen: { name: 'Maria Cidada', email: 'maria@example.com' },
    address: 'Rua das Flores, 123',
    latitude: -23.55,
    longitude: -46.63,
    createdAt: new Date('2026-01-10T10:00:00Z'),
    resolvedAt: null
  };
}

describe('ReportsService', () => {
  let repo: MockedRepo;
  let service: ReportsService;

  beforeEach(() => {
    repo = createMockRepo();
    service = new ReportsService(repo as unknown as ReportsRepository);
  });

  it('gera um CSV com cabecalho, BOM UTF-8 e uma linha por ocorrencia', async () => {
    repo.findForExport.mockResolvedValue([buildOccurrence()]);

    const csv = await service.exportCsv({});

    expect(csv.charCodeAt(0)).toBe(0xfeff);
    expect(csv).toContain('Protocolo;Status;Prioridade');
    expect(csv).toContain('GR-2026-000001');
    expect(csv).toContain('Maria Cidada');
  });

  it('gera um PDF valido (assinatura %PDF) contendo os dados das ocorrencias', async () => {
    repo.findForExport.mockResolvedValue([buildOccurrence(), buildOccurrence()]);

    const pdf = await service.exportPdf({ status: OccurrenceStatus.PENDENTE });

    expect(Buffer.isBuffer(pdf)).toBe(true);
    expect(pdf.subarray(0, 5).toString('utf-8')).toBe('%PDF-');
    expect(pdf.length).toBeGreaterThan(500);
  });

  it('gera um PDF valido mesmo sem nenhuma ocorrencia (apenas cabecalho)', async () => {
    repo.findForExport.mockResolvedValue([]);

    const pdf = await service.exportPdf({});

    expect(pdf.subarray(0, 5).toString('utf-8')).toBe('%PDF-');
  });
});
