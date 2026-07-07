import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { validate } from '../../core/middlewares/validate';
import { NotificationsController } from './notifications.controller';
import {
  listNotificationsSchema,
  notificationIdParamSchema,
  registerDeviceTokenSchema,
  removeDeviceTokenSchema
} from './notifications.schema';

const router = Router();
const controller = new NotificationsController();

router.use(authGuard);

router.get('/', validate(listNotificationsSchema), asyncHandler(controller.list));
router.patch('/:id/read', validate(notificationIdParamSchema), asyncHandler(controller.markRead));

// Registro/remocao do token FCM do device (Etapa 5). O registro acontece no
// login/restauracao de sessao do app mobile; a remocao, no logout — para
// nao continuar enviando push para um device onde o usuario ja saiu.
router.post('/devices', validate(registerDeviceTokenSchema), asyncHandler(controller.registerDevice));
router.delete('/devices', validate(removeDeviceTokenSchema), asyncHandler(controller.unregisterDevice));

export { router as notificationsRoutes };
