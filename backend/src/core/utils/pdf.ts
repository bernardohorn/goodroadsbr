import PDFDocument from 'pdfkit';

/**
 * Gerador de PDF tabular generico (usado hoje so pela exportacao de
 * relatorios de ocorrencias). `pdfkit` nao tem suporte nativo a tabelas —
 * cada celula e desenhada manualmente, com quebra de linha calculada via
 * `heightOfString` para saber a altura de cada linha antes de desenha-la e
 * decidir se cabe na pagina atual ou se precisa paginar (repetindo o
 * cabecalho na pagina seguinte).
 */

const PAGE_MARGIN = 24;
const HEADER_ROW_COLOR = '#1f2933';
const HEADER_TEXT_COLOR = '#ffffff';
const ROW_ALT_COLOR = '#f4f6f8';
const BORDER_COLOR = '#d3d9df';
const CELL_PADDING = 4;

export interface PdfTableOptions {
  title: string;
  subtitle?: string;
  headers: string[];
  /** Peso relativo de cada coluna (ex.: [2, 1, 1]) — nao precisa somar 100. */
  columnWeights: number[];
  rows: unknown[][];
}

function cellText(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value);
}

export function toPdfTable(options: PdfTableOptions): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: PAGE_MARGIN, size: 'A4', layout: 'landscape' });
    const chunks: Buffer[] = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const pageWidth = doc.page.width - PAGE_MARGIN * 2;
    const totalWeight = options.columnWeights.reduce((sum, w) => sum + w, 0);
    const columnWidths = options.columnWeights.map((w) => (w / totalWeight) * pageWidth);

    doc.fontSize(16).fillColor('#000000').text(options.title, { align: 'left' });
    if (options.subtitle) {
      doc.moveDown(0.2);
      doc.fontSize(9).fillColor('#52606d').text(options.subtitle);
    }
    doc.moveDown(0.8);

    const drawRow = (cells: string[], { header = false, shaded = false }: { header?: boolean; shaded?: boolean } = {}) => {
      const x0 = doc.page.margins.left;
      doc.fontSize(8).font(header ? 'Helvetica-Bold' : 'Helvetica');

      const rowHeight =
        Math.max(
          ...cells.map((text, i) => doc.heightOfString(text, { width: columnWidths[i] - CELL_PADDING * 2 }))
        ) +
        CELL_PADDING * 2;

      if (doc.y + rowHeight > doc.page.height - doc.page.margins.bottom) {
        doc.addPage();
        doc.y = doc.page.margins.top;
      }

      const y0 = doc.y;
      if (header) {
        doc.rect(x0, y0, pageWidth, rowHeight).fill(HEADER_ROW_COLOR);
      } else if (shaded) {
        doc.rect(x0, y0, pageWidth, rowHeight).fill(ROW_ALT_COLOR);
      }

      let x = x0;
      for (let i = 0; i < cells.length; i++) {
        doc
          .fillColor(header ? HEADER_TEXT_COLOR : '#102a43')
          .text(cells[i], x + CELL_PADDING, y0 + CELL_PADDING, { width: columnWidths[i] - CELL_PADDING * 2 });
        x += columnWidths[i];
      }

      doc
        .strokeColor(BORDER_COLOR)
        .lineWidth(0.5)
        .rect(x0, y0, pageWidth, rowHeight)
        .stroke();

      doc.y = y0 + rowHeight;
    };

    drawRow(options.headers, { header: true });
    options.rows.forEach((row, index) => {
      drawRow(row.map(cellText), { shaded: index % 2 === 1 });
    });

    doc.end();
  });
}
