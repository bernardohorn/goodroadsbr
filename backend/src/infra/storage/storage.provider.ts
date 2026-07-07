import { env } from '../../config/env';
import { LocalDiskStorageProvider } from './LocalDiskStorageProvider';
import { StorageProvider } from './StorageProvider';

/**
 * Unico ponto de decisao de qual implementacao de storage usar, baseado em
 * `STORAGE_DRIVER`. Quando a implementacao S3-compativel for adicionada
 * (Etapa 2 ou posterior), o novo `case 's3'` e o unico lugar que muda.
 */
function createStorageProvider(): StorageProvider {
  switch (env.STORAGE_DRIVER) {
    case 'local':
      return new LocalDiskStorageProvider();
    case 's3':
      throw new Error(
        'STORAGE_DRIVER=s3 ainda nao implementado. Ver docs/DECISOES.md — implementar S3StorageProvider quando a migracao for decidida.'
      );
    default:
      return new LocalDiskStorageProvider();
  }
}

export const storageProvider: StorageProvider = createStorageProvider();
