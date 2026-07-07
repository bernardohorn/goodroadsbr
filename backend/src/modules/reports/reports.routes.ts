import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { ReportsController } from './reports.controller';
import { exportReportSchema } from './reports.schema';

const router = Router();
const controller = new ReportsController();

router.use(authGuard, requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/export', validate(exportReportSchema), asyncHandler(controller.export));

export { router as reportsRoutes };
