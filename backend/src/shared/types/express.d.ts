import { RoleName } from '@prisma/client';

declare global {
  namespace Express {
    interface Request {
      auth?: {
        userId: string;
        role: RoleName;
        municipalityId: string | null;
      };
    }
  }
}

export {};
