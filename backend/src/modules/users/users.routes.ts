import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { validate } from '../../core/middlewares/validate';
import { UsersController } from './users.controller';
import { updateMeSchema } from './users.schema';

const router = Router();
const controller = new UsersController();

router.use(authGuard);

router.get('/me', asyncHandler(controller.getMe));
router.patch('/me', validate(updateMeSchema), asyncHandler(controller.updateMe));

export { router as usersRoutes };
