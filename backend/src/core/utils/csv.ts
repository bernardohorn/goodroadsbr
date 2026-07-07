/**
 * Gerador de CSV minimo, sem dependencia externa (o projeto nao tem nenhuma
 * lib de CSV instalada e o sandbox de desenvolvimento nao tem acesso ao
 * registro npm para adicionar uma — ver docs/DECISOES.md). Cobre o
 * necessario: escapamento de aspas/virgula/quebra de linha por celula e
 * separador ';' (mais amigavel ao Excel em pt-BR, que usa ',' como
 * separador decimal).
 */
function escapeCell(value: unknown): string {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (/[";\n\r]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

export function toCsv(headers: string[], rows: unknown[][]): string {
  const lines = [headers.map(escapeCell).join(';')];
  for (const row of rows) {
    lines.push(row.map(escapeCell).join(';'));
  }
  // BOM UTF-8 no inicio para o Excel reconhecer acentuacao corretamente.
  return '﻿' + lines.join('\r\n');
}
