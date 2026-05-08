/**
 * POST /api/upload/plan-attachment
 * Upload one or more files for a weekly plan or proposal.
 * Returns an array of attachment metadata objects.
 *
 * Accepts: multipart/form-data with field "attachments" (up to 5 files)
 * Returns: { success, data: [{ url, name, type, size, uploadedAt }] }
 */
import { Router, Response } from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import { uploadPlanAttachments } from '../config/multer.config';
import { AuthRequest } from '../middlewares/authMiddleware';
import { sendSuccess, sendError } from '../utils/responseHelper';

const router = Router();
router.use(authenticate);

router.post(
    '/plan-attachment',
    uploadPlanAttachments,
    async (req: AuthRequest, res: Response) => {
        try {
            const files = (req.files as Express.Multer.File[]) ?? [];
            if (files.length === 0) {
                return sendError(res, 'No files uploaded.', 400);
            }

            const userId = req.user!.userId;
            const { CloudinaryService } = await import('../services/cloudinary.service');

            const results: object[] = [];
            for (const file of files) {
                const upload = await CloudinaryService.uploadDocument(file, {
                    userId,
                    organizationId: userId,
                    fileType: 'WEEKLY_PRESENTATION' as any,
                    folder: `internlink/attachments/${userId}`,
                    resourceType: 'raw',
                });

                if (!upload.success || !upload.url) {
                    return sendError(res, `Failed to upload ${file.originalname}: ${upload.error ?? 'Unknown error'}`, 500);
                }

                results.push({
                    url: upload.url,
                    name: file.originalname,
                    type: file.mimetype,
                    size: file.size,
                    uploadedAt: new Date().toISOString(),
                });
            }

            return sendSuccess(res, results, `${results.length} file(s) uploaded.`, 201);
        } catch (error: any) {
            return sendError(res, error.message, 500);
        }
    },
);

export default router;
