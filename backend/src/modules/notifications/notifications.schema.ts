import { z } from 'zod';

export const listNotificationsSchema = {
  query: z.object({
    unreadOnly: z.coerce.boolean().default(false),
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(100).default(20)
  })
};

export const notificationIdParamSchema = {
  params: z.object({ id: z.string().uuid() })
};

export const registerDeviceTokenSchema = {
  body: z.object({
    token: z.string().trim().min(10),
    platform: z.enum(['android', 'ios']).optional()
  })
};

export const removeDeviceTokenSchema = {
  body: z.object({
    token: z.string().trim().min(10)
  })
};
