import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { CategoriesController } from './categories.controller';
import { createCategorySchema, updateCategorySchema } from './categories.schema';

const router = Router();
const controller = new CategoriesController();

router.use(authGuard);

router.get('/', asyncHandler(controller.list));
router.post('/', requireRole('FUNCIONARIO', 'ADMIN'), validate(createCategorySchema), asyncHandler(controller.create));
router.patch(
  '/:id',
  requireRole('FUNCIONARIO', 'ADMIN'),
  validate(updateCategorySchema),
  asyncHandler(controller.update)
);

export { router as categoriesRoutes };
