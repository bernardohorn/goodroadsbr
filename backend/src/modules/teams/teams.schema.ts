import { z } from 'zod';

export const createTeamSchema = {
  body: z.object({
    name: z.string().trim().min(2).max(60)
  })
};

export const teamIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};
