import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authRateLimiter } from '../../core/middlewares/rateLimiter';
import { validate } from '../../core/middlewares/validate';
import { AuthController } from './auth.controller';
import {
  forgotPasswordSchema,
  loginSchema,
  logoutSchema,
  refreshSchema,
  registerSchema,
  resetPasswordSchema
} from './auth.schema';

const router = Router();
const controller = new AuthController();

router.use(authRateLimiter);

router.post('/register', validate(registerSchema), asyncHandler(controller.register));
router.post('/login', validate(loginSchema), asyncHandler(controller.login));
router.post('/refresh', validate(refreshSchema), asyncHandler(controller.refresh));
router.post('/logout', validate(logoutSchema), asyncHandler(controller.logout));
router.post('/forgot-password', validate(forgotPasswordSchema), asyncHandler(controller.forgotPassword));
router.post('/reset-password', validate(resetPasswordSchema), asyncHandler(controller.resetPassword));

export { router as authRoutes };
