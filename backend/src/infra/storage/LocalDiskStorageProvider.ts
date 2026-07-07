import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { env } from '../../config/env';
import { StorageProvider, UploadInput, UploadResult } from './StorageProvider';

/**
 * Implementacao de desenvolvimento: grava os arquivos em disco, dentro de
 * `LOCAL_STORAGE_DIR`, e serve via rota estatica (`/uploads`) registrada em
 * `app.ts`. Nao deve ser usada em producao com multiplas instancias (cada
 * instancia teria seu proprio disco) — para isso, ver `S3StorageProvider`
 * (a ser implementado quando a migracao para S3/R2/MinIO for decidida).
 */
export class LocalDiskStorageProvider implements StorageProvider {
  private readonly baseDir: string;

  constructor() {
    this.baseDir = path.resolve(process.cwd(), env.LOCAL_STORAGE_DIR);
    fs.mkdirSync(this.baseDir, { recursive: true });
  }

  async upload(input: UploadInput): Promise<UploadResult> {
    const extension = path.extname(input.originalName) || '';
    const key = `${randomUUID()}${extension}`;
    const filePath = path.join(this.baseDir, key);

    await fs.promises.writeFile(filePath, input.buffer);

    return { key, url: this.getPublicUrl(key) };
  }

  async delete(key: string): Promise<void> {
    const filePath = path.join(this.baseDir, key);
    await fs.promises.rm(filePath, { force: true });
  }

  getPublicUrl(key: string): string {
    return `${env.LOCAL_STORAGE_PUBLIC_URL.replace(/\/$/, '')}/${key}`;
  }
}
