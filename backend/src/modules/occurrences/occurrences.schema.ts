import { OccurrencePriority, OccurrenceStatus } from '@prisma/client';
import { z } from 'zod';

export const createOccurrenceSchema = {
  body: z.object({
    description: z.string().trim().min(10, 'Descreva o problema com ao menos 10 caracteres').max(500),
    latitude: z.coerce.number().min(-90).max(90),
    longitude: z.coerce.number().min(-180).max(180),
    address: z.string().trim().max(255).optional(),
    categoryId: z.string().uuid().optional()
  })
};

export const listOccurrencesSchema = {
  query: z.object({
    status: z.nativeEnum(OccurrenceStatus).optional(),
    priority: z.nativeEnum(OccurrencePriority).optional(),
    categoryId: z.string().uuid().optional(),
    search: z.string().trim().max(120).optional(),
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(100).default(20),
    sortBy: z.enum(['createdAt', 'updatedAt', 'priority', 'status']).default('createdAt'),
    sortOrder: z.enum(['asc', 'desc']).default('desc')
  })
};

export const occurrenceIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};

export const updateOccurrenceStatusSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z.object({
    status: z.nativeEnum(OccurrenceStatus),
    note: z.string().trim().max(500).optional()
  })
};

export const updateOccurrenceDetailsSchema = {
  params: z.object({ id: z.string().uuid() }),
  body: z
    .object({
      categoryId: z.string().uuid().optional(),
      priority: z.nativeEnum(OccurrencePriority).optional(),
      teamId: z.string().uuid().optional(),
      assignedToId: z.string().uuid().optional(),
      internalNotes: z.string().trim().max(2000).optional()
    })
    .refine((data) => Object.keys(data).length > 0, 'Informe ao menos um campo para atualizar')
};
