import { z } from 'zod';

export const listCitizensSchema = {
  query: z.object({
    search: z.string().trim().max(120).optional(),
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(50).default(20)
  })
};

export const citizenIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};

export const updateCitizenStatusSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z.object({ active: z.boolean() })
};
