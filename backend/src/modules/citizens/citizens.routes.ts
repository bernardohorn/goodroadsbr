import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { CitizensController } from './citizens.controller';
import { citizenIdParamSchema, listCitizensSchema, updateCitizenStatusSchema } from './citizens.schema';

const router = Router();
const controller = new CitizensController();

router.use(authGuard);
// Leitura liberada para qualquer membro da equipe (mesmo padrao de
// staff.routes.ts). Ativar/desativar conta fica restrito a ADMIN — mesma
// restricao ja aplicada a criacao/edicao de contas de staff.
router.use(requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/', validate(listCitizensSchema), asyncHandler(controller.list));
router.get('/:id', validate(citizenIdParamSchema), asyncHandler(controller.getById));
router.patch(
  '/:id/status',
  requireRole('ADMIN'),
  validate(updateCitizenStatusSchema),
  asyncHandler(controller.updateStatus)
);

export { router as citizensRoutes };
