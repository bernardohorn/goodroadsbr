import { toCsv } from '../../core/utils/csv';
import { toPdfTable } from '../../core/utils/pdf';
import { ReportFilters, ReportsRepository } from './reports.repository';

const STATUS_LABEL: Record<string, string> = {
  PENDENTE: 'Pendente',
  EM_ANDAMENTO: 'Em andamento',
  RESOLVIDA: 'Resolvida',
  CANCELADA: 'Cancelada'
};

const PRIORITY_LABEL: Record<string, string> = {
  BAIXA: 'Baixa',
  MEDIA: 'Media',
  ALTA: 'Alta',
  URGENTE: 'Urgente'
};

const REPORT_HEADERS = [
  'Protocolo',
  'Status',
  'Prioridade',
  'Categoria',
  'Equipe',
  'Responsavel',
  'Cidadao',
  'E-mail do cidadao',
  'Endereco',
  'Latitude',
  'Longitude',
  'Criada em',
  'Resolvida em'
];

// Peso relativo de cada coluna no PDF (colunas com texto mais longo, como
// e-mail e endereco, recebem mais espaco; lat/long ficam estreitas).
const REPORT_COLUMN_WEIGHTS = [2, 1.3, 1, 1.3, 1.2, 1.3, 1.5, 2, 2.2, 1, 1, 1.4, 1.4];

export class ReportsService {
  constructor(private readonly repo: ReportsRepository = new ReportsRepository()) {}

  private async buildRows(filters: ReportFilters) {
    const occurrences = await this.repo.findForExport(filters);

    return occurrences.map((o) => [
      o.protocolNumber,
      STATUS_LABEL[o.status] ?? o.status,
      PRIORITY_LABEL[o.priority] ?? o.priority,
      o.category?.name ?? '',
      o.team?.name ?? '',
      o.assignedTo?.name ?? '',
      o.citizen?.name ?? '',
      o.citizen?.email ?? '',
      o.address ?? '',
      o.latitude,
      o.longitude,
      o.createdAt.toISOString(),
      o.resolvedAt ? o.resolvedAt.toISOString() : ''
    ]);
  }

  async exportCsv(filters: ReportFilters): Promise<string> {
    const rows = await this.buildRows(filters);
    return toCsv(REPORT_HEADERS, rows);
  }

  async exportPdf(filters: ReportFilters): Promise<Buffer> {
    const rows = await this.buildRows(filters);

    const filterParts: string[] = [];
    if (filters.status) filterParts.push(`Status: ${STATUS_LABEL[filters.status] ?? filters.status}`);
    if (filters.categoryId) filterParts.push('Categoria filtrada');
    if (filters.dateFrom) filterParts.push(`De: ${filters.dateFrom.toISOString().slice(0, 10)}`);
    if (filters.dateTo) filterParts.push(`Ate: ${filters.dateTo.toISOString().slice(0, 10)}`);

    return toPdfTable({
      title: 'Relatorio de Ocorrencias — GoodRoads',
      subtitle: [
        `Gerado em ${new Date().toLocaleString('pt-BR')}`,
        `${rows.length} ocorrencia(s)`,
        ...filterParts
      ].join('  •  '),
      headers: REPORT_HEADERS,
      columnWeights: REPORT_COLUMN_WEIGHTS,
      rows
    });
  }
}
