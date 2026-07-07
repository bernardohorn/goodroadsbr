import { Router } from 'express';
import multer from 'multer';
import { ALLOWED_PHOTO_MIME_TYPES, MAX_PHOTOS_PER_OCCURRENCE, MAX_PHOTO_SIZE_MB } from '../../config/constants';
import { asyncHandler } from '../../core/middlewares/asyncHandler';
import { authGuard } from '../../core/middlewares/authGuard';
import { requireRole } from '../../core/middlewares/rbacGuard';
import { validate } from '../../core/middlewares/validate';
import { AppError } from '../../core/errors/AppError';
import { OccurrencesController } from './occurrences.controller';
import {
  createOccurrenceSchema,
  listOccurrencesSchema,
  occurrenceIdParamSchema,
  updateOccurrenceDetailsSchema,
  updateOccurrenceStatusSchema
} from './occurrences.schema';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_PHOTO_SIZE_MB * 1024 * 1024,
    files: MAX_PHOTOS_PER_OCCURRENCE
  },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_PHOTO_MIME_TYPES.includes(file.mimetype as (typeof ALLOWED_PHOTO_MIME_TYPES)[number])) {
      cb(AppError.validation(`Tipo de arquivo nao suportado: ${file.mimetype}. Envie JPEG, PNG ou WEBP.`));
      return;
    }
    cb(null, true);
  }
});

const router = Router();
const controller = new OccurrencesController();

router.use(authGuard);

router.post('/', upload.array('photos', MAX_PHOTOS_PER_OCCURRENCE), validate(createOccurrenceSchema), asyncHandler(controller.create));
router.get('/', validate(listOccurrencesSchema), asyncHandler(controller.list));
router.get('/:id', validate(occurrenceIdParamSchema), asyncHandler(controller.getById));
router.get('/:id/history', validate(occurrenceIdParamSchema), asyncHandler(controller.getHistory));
router.patch(
  '/:id/status',
  requireRole('FUNCIONARIO', 'ADMIN'),
  validate(updateOccurrenceStatusSchema),
  asyncHandler(controller.updateStatus)
);
router.patch(
  '/:id',
  requireRole('FUNCIONARIO', 'ADMIN'),
  validate(updateOccurrenceDetailsSchema),
  asyncHandler(controller.updateDetails)
);

export { router as occurrencesRoutes };
