import { OccurrenceStatus } from '@prisma/client';
import { z } from 'zod';

export const mapBoundingBoxSchema = {
  query: z.object({
    north: z.coerce.number().min(-90).max(90),
    south: z.coerce.number().min(-90).max(90),
    east: z.coerce.number().min(-180).max(180),
    west: z.coerce.number().min(-180).max(180),
    status: z.nativeEnum(OccurrenceStatus).optional(),
    categoryId: z.string().uuid().optional()
  })
};
