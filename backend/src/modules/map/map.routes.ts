import { Router } from 'express';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { validate } from '../../core/middlewares/validate';
import { MapController } from './map.controller';
import { mapBoundingBoxSchema } from './map.schema';

const router = Router();
const controller = new MapController();

router.use(authGuard);

router.get('/occurrences', validate(mapBoundingBoxSchema), asyncHandler(controller.search));

export { router as mapRoutes };
