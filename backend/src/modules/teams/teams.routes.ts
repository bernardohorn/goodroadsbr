import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { TeamsController } from './teams.controller';
import { createTeamSchema } from './teams.schema';

const router = Router();
const controller = new TeamsController();

router.use(authGuard, requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/', asyncHandler(controller.list));
router.post('/', validate(createTeamSchema), asyncHandler(controller.create));

export { router as teamsRoutes };
