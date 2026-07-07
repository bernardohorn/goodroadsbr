export type AppErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'TOO_MANY_REQUESTS'
  | 'INTERNAL_ERROR';

const STATUS_BY_CODE: Record<AppErrorCode, number> = {
  VALIDATION_ERROR: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_ERROR: 500
};

/**
 * Erro de dominio/aplicacao. Controllers nunca lancam `Error` cru; sempre
 * `AppError`, para que o `errorHandler` central saiba como mapear para HTTP
 * sem que cada modulo precise conhecer detalhes de status code.
 */
export class AppError extends Error {
  readonly code: AppErrorCode;
  readonly statusCode: number;
  readonly details?: unknown;

  constructor(code: AppErrorCode, message: string, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.statusCode = STATUS_BY_CODE[code];
    this.details = details;
  }

  static validation(message: string, details?: unknown) {
    return new AppError('VALIDATION_ERROR', message, details);
  }

  static unauthorized(message = 'Nao autenticado') {
    return new AppError('UNAUTHORIZED', message);
  }

  static forbidden(message = 'Acesso negado') {
    return new AppError('FORBIDDEN', message);
  }

  static notFound(message = 'Recurso nao encontrado') {
    return new AppError('NOT_FOUND', message);
  }

  static conflict(message: string) {
    return new AppError('CONFLICT', message);
  }
}
