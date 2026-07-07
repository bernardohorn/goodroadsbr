export const PASSWORD_RESET_TOKEN_TTL_MINUTES = 30;

// Parametros recomendados pela OWASP para Argon2id em servicos web (2024+).
// O tipo (argon2id) e aplicado no local de uso (auth.service.ts) via
// `argon2.argon2id`, para nao acoplar este modulo de configuracao a
// constantes internas da lib.
export const ARGON2_OPTIONS = {
  memoryCost: 19456, // ~19 MB
  timeCost: 2,
  parallelism: 1
} as const;

// --- Ocorrencias / upload de fotos -----------------------------------------

export const OCCURRENCE_PROTOCOL_PREFIX = 'GR';

export const MAX_PHOTOS_PER_OCCURRENCE = 5;
export const MAX_PHOTO_SIZE_MB = 8;
export const ALLOWED_PHOTO_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;

export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

// Transicoes de status permitidas. RESOLVIDA e CANCELADA sao estados
// terminais (nao ha caminho de volta) — se no futuro for necessario
// "reabrir" uma ocorrencia resolvida, isso deve ser uma decisao de produto
// explicita, nao um efeito colateral de uma transicao generica.
export const ALLOWED_STATUS_TRANSITIONS: Record<string, string[]> = {
  PENDENTE: ['EM_ANDAMENTO', 'CANCELADA'],
  EM_ANDAMENTO: ['RESOLVIDA', 'CANCELADA', 'PENDENTE'],
  RESOLVIDA: [],
  CANCELADA: []
};

export const OCCURRENCE_STATUS_LABELS: Record<string, string> = {
  PENDENTE: 'Pendente',
  EM_ANDAMENTO: 'Em andamento',
  RESOLVIDA: 'Resolvida',
  CANCELADA: 'Cancelada'
};
