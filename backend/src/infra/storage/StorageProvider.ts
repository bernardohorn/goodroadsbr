export interface UploadInput {
  buffer: Buffer;
  originalName: string;
  mimeType: string;
}

export interface UploadResult {
  key: string;
  url: string;
}

/**
 * Interface de armazenamento de arquivos (fotos das ocorrencias).
 *
 * Decisao do cliente (docs/DECISOES.md): comecar com armazenamento local em
 * disco (`LocalDiskStorageProvider`) e migrar para um provedor
 * S3-compativel (AWS S3 / Cloudflare R2 / MinIO) quando necessario. Todo o
 * resto da aplicacao depende apenas desta interface — a migracao futura se
 * resume a implementar `S3StorageProvider` e trocar o binding em
 * `storage.provider.ts`, sem tocar em nenhum modulo de negocio.
 */
export interface StorageProvider {
  upload(input: UploadInput): Promise<UploadResult>;
  delete(key: string): Promise<void>;
  getPublicUrl(key: string): string;
}
