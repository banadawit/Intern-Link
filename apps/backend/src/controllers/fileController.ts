import { Request, Response } from 'express';
import prisma from '../config/db';

/**
 * Save file metadata after frontend upload to Cloudinary
 */
export const saveFileMetadata = async (req: Request, res: Response) => {
  try {
    const {
      url,
      publicId,
      filename,
      mimeType,
      size,
      type,
      organizationType,
      organizationId,
      weeklyPlanId,
      studentId,
      userId,
    } = req.body;

    // Validate required fields
    if (!url || !publicId || !filename || !mimeType || !size || !type) {
      return res.status(400).json({
        error: 'Missing required fields',
      });
    }

    // Get user from auth middleware
    const authUserId = (req as any).user?.userId;

    // Use a transaction to ensure both file and related record are updated
    const result = await prisma.$transaction(async (tx) => {
      // Create file record
      const file = await tx.file.create({
        data: {
          url,
          publicId,
          filename,
          mimeType,
          size,
          type: type as any,
          userId: userId ? parseInt(userId.toString()) : authUserId,
          organizationId: organizationId ? parseInt(organizationId.toString()) : null,
        },
      });

      // Update specific models based on type
      // Handle both VERIFICATION_DOC (backend enum) and VERIFICATION_DOCUMENT (frontend potential)
      if (type === 'VERIFICATION_DOC' || type === 'VERIFICATION_DOCUMENT') {
        if (organizationType === 'UNIVERSITY' && organizationId) {
          await tx.university.update({
            where: { id: parseInt(organizationId.toString()) },
            data: { 
              verification_doc: url, 
              approval_status: 'PENDING' 
            },
          });
        } else if (organizationType === 'COMPANY' && organizationId) {
          await tx.company.update({
            where: { id: parseInt(organizationId.toString()) },
            data: { 
              verification_doc: url, 
              approval_status: 'PENDING' 
            },
          });
        }
      } else if (type === 'COMPANY_STAMP' && organizationId) {
        await tx.company.update({
          where: { id: parseInt(organizationId.toString()) },
          data: { stamp_image_url: url },
        });
      } else if (type === 'WEEKLY_PRESENTATION' && weeklyPlanId) {
        await tx.weeklyPresentation.upsert({
          where: { weeklyPlanId: parseInt(weeklyPlanId.toString()) },
          update: { file_url: url, uploaded_at: new Date() },
          create: {
            weeklyPlanId: parseInt(weeklyPlanId.toString()),
            file_url: url,
            uploaded_at: new Date(),
          },
        });
      } else if (type === 'FINAL_REPORT' && studentId) {
        await tx.report.upsert({
          where: { studentId: parseInt(studentId.toString()) },
          update: { pdf_url: url, generated_at: new Date() },
          create: {
            studentId: parseInt(studentId.toString()),
            pdf_url: url,
            stamped: false,
          },
        });
      }

      return file;
    });

    res.status(201).json({
      message: 'File metadata saved and records updated successfully',
      file: result,
    });
  } catch (error: any) {
    console.error('Save file metadata error:', error);
    res.status(500).json({
      error: 'Failed to save file metadata',
      details: error.message,
    });
  }
};

/**
 * Delete file and its Cloudinary resource
 */
export const deleteFile = async (req: Request, res: Response) => {
  try {
    const fileId = req.params.fileId as string;
    const authUserId = (req as any).user?.userId;

    // Find file
    const file = await prisma.file.findUnique({
      where: { id: fileId },
    });

    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Check authorization
    if (file.userId !== authUserId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Delete from Cloudinary
    const cloudinary = require('../services/cloudinary.service');
    await cloudinary.deleteFile(file.publicId);

    // Delete from database
    await prisma.file.delete({
      where: { id: fileId },
    });

    res.json({ message: 'File deleted successfully' });
  } catch (error: any) {
    console.error('Delete file error:', error);
    res.status(500).json({
      error: 'Failed to delete file',
      details: error.message,
    });
  }
};

/**
 * Get user files
 */
export const getUserFiles = async (req: Request, res: Response) => {
  try {
    const authUserId = (req as any).user?.userId;
    const { type } = req.query;

    const files = await prisma.file.findMany({
      where: {
        userId: authUserId,
        ...(type && { type: type as any }),
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ files });
  } catch (error: any) {
    console.error('Get user files error:', error);
    res.status(500).json({
      error: 'Failed to fetch files',
      details: error.message,
    });
  }
};
