import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { ContentSanitizationService } from '../services/contentSanitization.service';
import { PostType, PostVisibility, Role } from '@prisma/client';

/**
 * Common Feed Controller
 * Implements FR-7: Common Page for all stakeholders
 * SRS Sections: 2.2, 3.1, 2.3, 2.6.5, 3.5.2, 3.5.3, 3.5.4
 */

// ==================== POST MANAGEMENT ====================

/**
 * FR-7.2: Create a new post
 * All authenticated users can post
 */
export const createPost = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const {
      postType,
      visibility,
      title,
      content,
      imageUrls,
      documentUrls,
      targetUniversityId,
      targetCompanyId,
      targetRoles,
    } = req.body;

    // Input validation
    const validation = ContentSanitizationService.validatePost({
      title,
      content,
      imageUrls,
      documentUrls,
    });

    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        errors: validation.errors,
      });
    }

    // Rate limiting check
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentPostsCount = await prisma.commonPost.count({
      where: {
        authorId: userId,
        createdAt: { gte: oneHourAgo },
      },
    });

    const rateLimitCheck = ContentSanitizationService.checkRateLimit(recentPostsCount);
    if (!rateLimitCheck.allowed) {
      return res.status(429).json({
        success: false,
        message: rateLimitCheck.error,
      });
    }

    // Sanitize content
    const sanitizedTitle = ContentSanitizationService.sanitizeText(title);
    const sanitizedContent = ContentSanitizationService.sanitizeHTML(content);

    // Create post
    const post = await prisma.commonPost.create({
      data: {
        authorId: userId,
        postType: postType || PostType.GENERAL_UPDATE,
        visibility: visibility || PostVisibility.PUBLIC,
        title: sanitizedTitle,
        content: sanitizedContent,
        imageUrls: imageUrls || [],
        documentUrls: documentUrls || [],
        targetUniversityId,
        targetCompanyId,
        targetRoles: targetRoles || [],
      },
      include: {
        author: {
          select: {
            id: true,
            full_name: true,
            role: true,
            email: true,
          },
        },
      },
    });

    // Log activity
    await prisma.activityLog.upsert({
      where: {
        userId_date: {
          userId,
          date: new Date(new Date().toDateString()),
        },
      },
      update: {
        count: { increment: 1 },
      },
      create: {
        userId,
        date: new Date(new Date().toDateString()),
        count: 1,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: post,
    });
  } catch (error: any) {
    console.error('Create post error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create post',
      error: error.message,
    });
  }
};

/**
 * FR-7.3: Get feed with filtering and chronological order
 * Content visibility logic based on user role and visibility settings
 */
export const getFeed = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const userRole = req.user!.role;
    
    const {
      page = 1,
      limit = 20,
      postType,
      sortBy = 'createdAt',
      order = 'desc',
    } = req.query;

    const skip = (Number(page) - 1) * Number(limit);

    // Get user's university and company associations
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        studentProfile: { select: { universityId: true } },
        coordinatorProfile: { select: { universityId: true } },
        hodProfile: { select: { universityId: true } },
        supervisorProfile: { select: { companyId: true } },
      },
    });

    const userUniversityId = 
      user?.studentProfile?.universityId ||
      user?.coordinatorProfile?.universityId ||
      user?.hodProfile?.universityId;
    
    const userCompanyId = user?.supervisorProfile?.companyId;

    // Build visibility filter
    const visibilityFilter: any = {
      isArchived: false,
      OR: [
        { visibility: PostVisibility.PUBLIC },
        {
          visibility: PostVisibility.UNIVERSITY,
          targetUniversityId: userUniversityId,
        },
        {
          visibility: PostVisibility.COMPANY,
          targetCompanyId: userCompanyId,
        },
        {
          visibility: PostVisibility.ROLE_SPECIFIC,
          targetRoles: { has: userRole },
        },
      ],
    };

    // Add post type filter if specified
    if (postType) {
      visibilityFilter.postType = postType;
    }

    // Get posts
    const [posts, totalCount] = await Promise.all([
      prisma.commonPost.findMany({
        where: visibilityFilter,
        skip,
        take: Number(limit),
        orderBy: { [sortBy as string]: order },
        include: {
          author: {
            select: {
              id: true,
              full_name: true,
              role: true,
              email: true,
            },
          },
          _count: {
            select: {
              comments: true,
              likes: true,
              views: true,
            },
          },
        },
      }),
      prisma.commonPost.count({ where: visibilityFilter }),
    ]);

    // Track views for each post
    const viewPromises = posts.map((post) =>
      prisma.postView.upsert({
        where: {
          postId_userId: {
            postId: post.id,
            userId,
          },
        },
        update: {},
        create: {
          postId: post.id,
          userId,
        },
      }).catch(() => {}) // Ignore errors for view tracking
    );

    await Promise.all(viewPromises);

    // Update view counts
    await Promise.all(
      posts.map((post) =>
        prisma.commonPost.update({
          where: { id: post.id },
          data: { viewCount: { increment: 1 } },
        }).catch(() => {})
      )
    );

    // Check if current user liked each post
    const likedPosts = await prisma.postLike.findMany({
      where: {
        userId,
        postId: { in: posts.map((p) => p.id) },
      },
      select: { postId: true },
    });

    const likedPostIds = new Set(likedPosts.map((l) => l.postId));

    const postsWithLikeStatus = posts.map((post) => ({
      ...post,
      isLikedByUser: likedPostIds.has(post.id),
      commentCount: post._count.comments,
      likeCount: post._count.likes,
      viewCount: post._count.views,
    }));

    res.json({
      success: true,
      data: {
        posts: postsWithLikeStatus,
        pagination: {
          currentPage: Number(page),
          totalPages: Math.ceil(totalCount / Number(limit)),
          totalCount,
          hasMore: skip + posts.length < totalCount,
        },
      },
    });
  } catch (error: any) {
    console.error('Get feed error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch feed',
      error: error.message,
    });
  }
};

/**
 * Get a single post by ID
 */
export const getPostById = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;

    const post = await prisma.commonPost.findUnique({
      where: { id: Number(postId) },
      include: {
        author: {
          select: {
            id: true,
            full_name: true,
            role: true,
            email: true,
          },
        },
        comments: {
          where: { parentId: null },
          include: {
            author: {
              select: {
                id: true,
                full_name: true,
                role: true,
              },
            },
            replies: {
              include: {
                author: {
                  select: {
                    id: true,
                    full_name: true,
                    role: true,
                  },
                },
              },
              orderBy: { createdAt: 'asc' },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: {
            likes: true,
            views: true,
          },
        },
      },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Track view
    await prisma.postView.upsert({
      where: {
        postId_userId: {
          postId: post.id,
          userId,
        },
      },
      update: {},
      create: {
        postId: post.id,
        userId,
      },
    });

    // Check if user liked the post
    const userLike = await prisma.postLike.findUnique({
      where: {
        postId_userId: {
          postId: post.id,
          userId,
        },
      },
    });

    res.json({
      success: true,
      data: {
        ...post,
        isLikedByUser: !!userLike,
        likeCount: post._count.likes,
        viewCount: post._count.views,
      },
    });
  } catch (error: any) {
    console.error('Get post error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch post',
      error: error.message,
    });
  }
};

/**
 * Update a post (only by author or admin)
 */
export const updatePost = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;
    const userRole = req.user!.role;
    const { title, content, imageUrls, documentUrls, isPinned, isArchived } = req.body;

    const post = await prisma.commonPost.findUnique({
      where: { id: Number(postId) },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Check permissions
    const isAuthor = post.authorId === userId;
    const isAdmin = userRole === Role.ADMIN;

    if (!isAuthor && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to edit this post',
      });
    }

    // Validate if content is being updated
    if (title || content) {
      const validation = ContentSanitizationService.validatePost({
        title: title || post.title,
        content: content || post.content,
      });

      if (!validation.valid) {
        return res.status(400).json({
          success: false,
          errors: validation.errors,
        });
      }
    }

    // Update post
    const updatedPost = await prisma.commonPost.update({
      where: { id: Number(postId) },
      data: {
        ...(title && { title: ContentSanitizationService.sanitizeText(title) }),
        ...(content && { content: ContentSanitizationService.sanitizeHTML(content) }),
        ...(imageUrls && { imageUrls }),
        ...(documentUrls && { documentUrls }),
        ...(isAdmin && isPinned !== undefined && { isPinned }),
        ...(isAdmin && isArchived !== undefined && { isArchived }),
      },
      include: {
        author: {
          select: {
            id: true,
            full_name: true,
            role: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Post updated successfully',
      data: updatedPost,
    });
  } catch (error: any) {
    console.error('Update post error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update post',
      error: error.message,
    });
  }
};

/**
 * Delete a post (only by author or admin)
 */
export const deletePost = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;
    const userRole = req.user!.role;

    const post = await prisma.commonPost.findUnique({
      where: { id: Number(postId) },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Check permissions
    const isAuthor = post.authorId === userId;
    const isAdmin = userRole === Role.ADMIN;

    if (!isAuthor && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to delete this post',
      });
    }

    await prisma.commonPost.delete({
      where: { id: Number(postId) },
    });

    res.json({
      success: true,
      message: 'Post deleted successfully',
    });
  } catch (error: any) {
    console.error('Delete post error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete post',
      error: error.message,
    });
  }
};

// ==================== COMMENT MANAGEMENT ====================

/**
 * Add a comment to a post
 */
export const addComment = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;
    const { content, parentId } = req.body;

    // Validate content
    const validation = ContentSanitizationService.validateContent(content);
    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        message: validation.error,
      });
    }

    // Check if post exists
    const post = await prisma.commonPost.findUnique({
      where: { id: Number(postId) },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found',
      });
    }

    // Sanitize content
    const sanitizedContent = ContentSanitizationService.sanitizeHTML(content);

    // Create comment
    const comment = await prisma.postComment.create({
      data: {
        postId: Number(postId),
        authorId: userId,
        content: sanitizedContent,
        parentId: parentId ? Number(parentId) : null,
      },
      include: {
        author: {
          select: {
            id: true,
            full_name: true,
            role: true,
          },
        },
      },
    });

    // Update comment count
    await prisma.commonPost.update({
      where: { id: Number(postId) },
      data: { commentCount: { increment: 1 } },
    });

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: comment,
    });
  } catch (error: any) {
    console.error('Add comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add comment',
      error: error.message,
    });
  }
};

/**
 * Update a comment (only by author)
 */
export const updateComment = async (req: AuthRequest, res: Response) => {
  try {
    const { commentId } = req.params;
    const userId = req.user!.userId;
    const { content } = req.body;

    const comment = await prisma.postComment.findUnique({
      where: { id: Number(commentId) },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found',
      });
    }

    if (comment.authorId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to edit this comment',
      });
    }

    // Validate content
    const validation = ContentSanitizationService.validateContent(content);
    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        message: validation.error,
      });
    }

    const updatedComment = await prisma.postComment.update({
      where: { id: Number(commentId) },
      data: {
        content: ContentSanitizationService.sanitizeHTML(content),
        isEdited: true,
      },
      include: {
        author: {
          select: {
            id: true,
            full_name: true,
            role: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Comment updated successfully',
      data: updatedComment,
    });
  } catch (error: any) {
    console.error('Update comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update comment',
      error: error.message,
    });
  }
};

/**
 * Delete a comment (only by author or admin)
 */
export const deleteComment = async (req: AuthRequest, res: Response) => {
  try {
    const { commentId } = req.params;
    const userId = req.user!.userId;
    const userRole = req.user!.role;

    const comment = await prisma.postComment.findUnique({
      where: { id: Number(commentId) },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found',
      });
    }

    const isAuthor = comment.authorId === userId;
    const isAdmin = userRole === Role.ADMIN;

    if (!isAuthor && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to delete this comment',
      });
    }

    await prisma.postComment.delete({
      where: { id: Number(commentId) },
    });

    // Update comment count
    await prisma.commonPost.update({
      where: { id: comment.postId },
      data: { commentCount: { decrement: 1 } },
    });

    res.json({
      success: true,
      message: 'Comment deleted successfully',
    });
  } catch (error: any) {
    console.error('Delete comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete comment',
      error: error.message,
    });
  }
};

// ==================== ENGAGEMENT ACTIONS ====================

/**
 * Like/Unlike a post
 */
export const toggleLike = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;

    const existingLike = await prisma.postLike.findUnique({
      where: {
        postId_userId: {
          postId: Number(postId),
          userId,
        },
      },
    });

    if (existingLike) {
      // Unlike
      await prisma.postLike.delete({
        where: { id: existingLike.id },
      });

      await prisma.commonPost.update({
        where: { id: Number(postId) },
        data: { likeCount: { decrement: 1 } },
      });

      res.json({
        success: true,
        message: 'Post unliked',
        liked: false,
      });
    } else {
      // Like
      await prisma.postLike.create({
        data: {
          postId: Number(postId),
          userId,
        },
      });

      await prisma.commonPost.update({
        where: { id: Number(postId) },
        data: { likeCount: { increment: 1 } },
      });

      res.json({
        success: true,
        message: 'Post liked',
        liked: true,
      });
    }
  } catch (error: any) {
    console.error('Toggle like error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle like',
      error: error.message,
    });
  }
};

/**
 * Report a post
 */
export const reportPost = async (req: AuthRequest, res: Response) => {
  try {
    const { postId } = req.params;
    const userId = req.user!.userId;
    const { reason, description } = req.body;

    if (!reason) {
      return res.status(400).json({
        success: false,
        message: 'Reason is required',
      });
    }

    const report = await prisma.postReport.create({
      data: {
        postId: Number(postId),
        reporterId: userId,
        reason,
        description: description || null,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Post reported successfully',
      data: report,
    });
  } catch (error: any) {
    console.error('Report post error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to report post',
      error: error.message,
    });
  }
};

// ==================== ADMIN MODERATION ====================

/**
 * Get all reported posts (Admin only)
 */
export const getReportedPosts = async (req: AuthRequest, res: Response) => {
  try {
    const { status = 'PENDING' } = req.query;

    const reports = await prisma.postReport.findMany({
      where: { status: status as string },
      include: {
        post: {
          include: {
            author: {
              select: {
                id: true,
                full_name: true,
                role: true,
                email: true,
              },
            },
          },
        },
        reporter: {
          select: {
            id: true,
            full_name: true,
            role: true,
            email: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      data: reports,
    });
  } catch (error: any) {
    console.error('Get reported posts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reported posts',
      error: error.message,
    });
  }
};

/**
 * Review a report (Admin only)
 */
export const reviewReport = async (req: AuthRequest, res: Response) => {
  try {
    const { reportId } = req.params;
    const { status, action } = req.body; // action: 'archive' | 'delete' | 'ignore'

    const report = await prisma.postReport.update({
      where: { id: Number(reportId) },
      data: {
        status,
        reviewedAt: new Date(),
      },
    });

    // Take action on the post if needed
    if (action === 'archive') {
      await prisma.commonPost.update({
        where: { id: report.postId },
        data: { isArchived: true },
      });
    } else if (action === 'delete') {
      await prisma.commonPost.delete({
        where: { id: report.postId },
      });
    }

    res.json({
      success: true,
      message: 'Report reviewed successfully',
      data: report,
    });
  } catch (error: any) {
    console.error('Review report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to review report',
      error: error.message,
    });
  }
};

/**
 * Get feed statistics (Admin only)
 */
export const getFeedStats = async (req: AuthRequest, res: Response) => {
  try {
    const [
      totalPosts,
      totalComments,
      totalLikes,
      totalViews,
      postsByType,
      recentActivity,
    ] = await Promise.all([
      prisma.commonPost.count(),
      prisma.postComment.count(),
      prisma.postLike.count(),
      prisma.postView.count(),
      prisma.commonPost.groupBy({
        by: ['postType'],
        _count: true,
      }),
      prisma.commonPost.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          title: true,
          postType: true,
          createdAt: true,
          author: {
            select: {
              full_name: true,
              role: true,
            },
          },
        },
      }),
    ]);

    res.json({
      success: true,
      data: {
        totalPosts,
        totalComments,
        totalLikes,
        totalViews,
        postsByType,
        recentActivity,
      },
    });
  } catch (error: any) {
    console.error('Get feed stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch feed statistics',
      error: error.message,
    });
  }
};


// ==================== FILE UPLOAD ====================

/**
 * Upload images for a post
 */
export const uploadImages = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const files = req.files as Express.Multer.File[];

    if (!files || files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files provided',
      });
    }

    const { FileUploadService } = await import('../services/fileUpload.service');
    const result = await FileUploadService.uploadMultipleImages(files, userId);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: 'Failed to upload some images',
        errors: result.errors,
      });
    }

    res.json({
      success: true,
      message: 'Images uploaded successfully',
      data: { urls: result.urls },
    });
  } catch (error: any) {
    console.error('Upload images error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload images',
      error: error.message,
    });
  }
};

/**
 * Upload documents for a post
 */
export const uploadDocuments = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!.userId;
    const files = req.files as Express.Multer.File[];

    if (!files || files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files provided',
      });
    }

    const { FileUploadService } = await import('../services/fileUpload.service');
    const result = await FileUploadService.uploadMultipleDocuments(files, userId);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: 'Failed to upload some documents',
        errors: result.errors,
      });
    }

    res.json({
      success: true,
      message: 'Documents uploaded successfully',
      data: { urls: result.urls },
    });
  } catch (error: any) {
    console.error('Upload documents error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload documents',
      error: error.message,
    });
  }
};
