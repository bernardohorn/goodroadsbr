import { z } from 'zod';

export const createCategorySchema = {
  body: z.object({
    name: z.string().trim().min(2).max(60),
    icon: z.string().trim().max(60).optional(),
    color: z
      .string()
      .trim()
      .regex(/^#[0-9a-fA-F]{6}$/, 'Cor deve estar no formato hexadecimal, ex.: #1B7A3E')
      .optional()
  })
};

export const updateCategorySchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z
    .object({
      name: z.string().trim().min(2).max(60).optional(),
      icon: z.string().trim().max(60).optional(),
      color: z
        .string()
        .trim()
        .regex(/^#[0-9a-fA-F]{6}$/)
        .optional(),
      active: z.boolean().optional()
    })
    .refine((data) => Object.keys(data).length > 0, 'Informe ao menos um campo para atualizar')
};

export const categoryIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};
