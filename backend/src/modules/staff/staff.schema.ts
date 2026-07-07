import { z } from 'zod';

export const createStaffSchema = {
  body: z.object({
    name: z.string().trim().min(3).max(120),
    email: z.string().trim().toLowerCase().email(),
    phone: z.string().trim().max(20).optional(),
    password: z
      .string()
      .min(8)
      .max(72)
      .regex(/[a-z]/, 'A senha deve conter ao menos uma letra minuscula')
      .regex(/[A-Z]/, 'A senha deve conter ao menos uma letra maiuscula')
      .regex(/[0-9]/, 'A senha deve conter ao menos um numero'),
    role: z.enum(['FUNCIONARIO', 'ADMIN'])
  })
};

export const updateStaffSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z
    .object({
      name: z.string().trim().min(3).max(120).optional(),
      phone: z.string().trim().max(20).optional(),
      role: z.enum(['FUNCIONARIO', 'ADMIN']).optional(),
      active: z.boolean().optional()
    })
    .refine((data) => Object.keys(data).length > 0, 'Informe ao menos um campo para atualizar')
};

export const listStaffSchema = {
  query: z.object({
    search: z.string().trim().max(120).optional(),
    role: z.enum(['FUNCIONARIO', 'ADMIN']).optional()
  })
};
