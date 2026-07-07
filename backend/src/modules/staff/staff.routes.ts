import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { StaffController } from './staff.controller';
import { createStaffSchema, listStaffSchema, updateStaffSchema } from './staff.schema';

const router = Router();
const controller = new StaffController();

router.use(authGuard);
// Leitura liberada para qualquer membro da equipe (necessario para popular o
// seletor de "Atribuido a" na tela de Detalhes da Ocorrencia). Escrita
// (criar/editar contas) fica restrita a ADMIN, unico papel que gerencia
// o time na tela "Usuarios" do desktop.
router.use(requireRole('FUNCIONARIO', 'ADMIN'));

router.get('/', validate(listStaffSchema), asyncHandler(controller.list));
router.get('/:id', asyncHandler(controller.getById));
router.post('/', requireRole('ADMIN'), validate(createStaffSchema), asyncHandler(controller.create));
router.patch('/:id', requireRole('ADMIN'), validate(updateStaffSchema), asyncHandler(controller.update));

export { router as staffRoutes };
