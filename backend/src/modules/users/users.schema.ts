import { z } from 'zod';

export const updateMeSchema = {
  body: z
    .object({
      name: z.string().trim().min(3).max(120).optional(),
      phone: z.string().trim().max(20).optional(),
      avatarUrl: z.string().url().optional()
    })
    .refine((data) => Object.keys(data).length > 0, 'Informe ao menos um campo para atualizar')
};
