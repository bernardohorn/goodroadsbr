import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { DashboardController } from './dashboard.controller';

const router = Router();
const controller = new DashboardController();

router.use(authGuard, requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/stats', asyncHandler(controller.getStats));

export { router as dashboardRoutes };
