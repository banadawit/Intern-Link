import { Router } from 'express';
import * as commonFeedCtrl from '../controllers/commonFeedController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { upload } from '../middlewares/uploadMiddleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// ==================== POST ROUTES ====================

/**
 * FR-7.1: Get common feed (accessible to all roles)
 * FR-7.3: Chronological order with filtering
 */
router.get(
  '/',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.getFeed
);

/**
 * FR-7.2: Create a new post (all roles can post)
 */
router.post(
  '/',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.createPost
);

/**
 * Get a single post by ID
 */
router.get(
  '/:postId',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.getPostById
);

/**
 * Update a post (author or admin only)
 */
router.put(
  '/:postId',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.updatePost
);

/**
 * Delete a post (author or admin only)
 */
router.delete(
  '/:postId',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.deletePost
);

// ==================== COMMENT ROUTES ====================

/**
 * Add a comment to a post
 */
router.post(
  '/:postId/comments',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.addComment
);

/**
 * Update a comment (author only)
 */
router.put(
  '/comments/:commentId',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.updateComment
);

/**
 * Delete a comment (author or admin only)
 */
router.delete(
  '/comments/:commentId',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.deleteComment
);

// ==================== ENGAGEMENT ROUTES ====================

/**
 * Like/Unlike a post
 */
router.post(
  '/:postId/like',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.toggleLike
);

/**
 * Report a post
 */
router.post(
  '/:postId/report',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  commonFeedCtrl.reportPost
);

// ==================== FILE UPLOAD ROUTES ====================

/**
 * Upload images for posts
 */
router.post(
  '/upload/images',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  upload.array('images', 5),
  commonFeedCtrl.uploadImages
);

/**
 * Upload documents for posts
 */
router.post(
  '/upload/documents',
  authorize([Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT]),
  upload.array('documents', 3),
  commonFeedCtrl.uploadDocuments
);

// ==================== ADMIN MODERATION ROUTES ====================

/**
 * Get all reported posts (Admin only)
 */
router.get(
  '/admin/reports',
  authorize([Role.ADMIN]),
  commonFeedCtrl.getReportedPosts
);

/**
 * Review a report (Admin only)
 */
router.put(
  '/admin/reports/:reportId',
  authorize([Role.ADMIN]),
  commonFeedCtrl.reviewReport
);

/**
 * Get feed statistics (Admin only)
 */
router.get(
  '/admin/stats',
  authorize([Role.ADMIN]),
  commonFeedCtrl.getFeedStats
);

export default router;
