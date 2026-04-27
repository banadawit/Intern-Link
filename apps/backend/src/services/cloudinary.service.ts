import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import prisma from '../config/db';

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export interface UploadOptions {
  userId?: number;
  organizationId?: number;
  fileType: 'VERIFICATION_DOC' | 'WEEKLY_PRESENTATION' | 'COMPANY_STAMP' | 'FINAL_REPORT' | 'COMMON_FEED_IMAGE' | 'COMMON_FEED_DOCUMENT';
  folder: string;
  resourceType?: 'image' | 'raw' | 'auto';
}

export interface UploadResult {
  success: boolean;
  url?: string;
  publicId?: string;
  fileId?: string;
  error?: string;
}

export class CloudinaryService {
  private static readonly ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png'];
  private static readonly ALLOWED_DOCUMENT_TYPES = [
    'application/pdf',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  ];
  private static readonly MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

  /**
   * Validate file before upload
   */
  static validateFile(
    file: Express.Multer.File,
    allowedTypes: string[]
  ): { valid: boolean; error?: string } {
    // Check file size
    if (file.size > this.MAX_FILE_SIZE) {
      return { valid: false, error: 'File size exceeds 10MB limit' };
    }

    // Check MIME type
    if (!allowedTypes.includes(file.mimetype)) {
      return {
        valid: false,
        error: `Invalid file type. Allowed types: ${allowedTypes.join(', ')}`,
      };
    }

    return { valid: true };
  }

  /**
   * Upload image to Cloudinary
   */
  static async uploadImage(
    file: Express.Multer.File,
    options: UploadOptions
  ): Promise<UploadResult> {
    try {
      // Validate
      const validation = this.validateFile(file, this.ALLOWED_IMAGE_TYPES);
      if (!validation.valid) {
        return { success: false, error: validation.error };
      }

      // Upload to Cloudinary
      const result = await new Promise<UploadApiResponse>((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder: options.folder,
            resource_type: 'image',
            transformation: [{ quality: 'auto', fetch_format: 'auto' }],
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result!);
          }
        );
        uploadStream.end(file.buffer);
      });

      // Save to database
      const fileRecord = await prisma.file.create({
        data: {
          userId: options.userId,
          organizationId: options.organizationId,
          type: options.fileType,
          url: result.secure_url,
          publicId: result.public_id,
          filename: file.originalname,
          mimeType: file.mimetype,
          size: file.size,
        },
      });

      return {
        success: true,
        url: result.secure_url,
        publicId: result.public_id,
        fileId: fileRecord.id,
      };
    } catch (error: any) {
      console.error('Cloudinary upload error:', error);
      return { success: false, error: error.message || 'Upload failed' };
    }
  }

  /**
   * Upload document (PDF, PPT) to Cloudinary
   */
  static async uploadDocument(
    file: Express.Multer.File,
    options: UploadOptions
  ): Promise<UploadResult> {
    try {
      // Validate
      const validation = this.validateFile(file, this.ALLOWED_DOCUMENT_TYPES);
      if (!validation.valid) {
        return { success: false, error: validation.error };
      }

      // Upload to Cloudinary as raw resource
      const result = await new Promise<UploadApiResponse>((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
          {
            folder: options.folder,
            resource_type: 'raw',
            format: file.originalname.split('.').pop(),
          },
          (error, result) => {
            if (error) reject(error);
            else resolve(result!);
          }
        );
        uploadStream.end(file.buffer);
      });

      // Save to database
      const fileRecord = await prisma.file.create({
        data: {
          userId: options.userId,
          organizationId: options.organizationId,
          type: options.fileType,
          url: result.secure_url,
          publicId: result.public_id,
          filename: file.originalname,
          mimeType: file.mimetype,
          size: file.size,
        },
      });

      return {
        success: true,
        url: result.secure_url,
        publicId: result.public_id,
        fileId: fileRecord.id,
      };
    } catch (error: any) {
      console.error('Cloudinary upload error:', error);
      return { success: false, error: error.message || 'Upload failed' };
    }
  }

  /**
   * Delete file from Cloudinary and database
   */
  static async deleteFile(publicId: string): Promise<boolean> {
    try {
      // Determine resource type from public_id
      const resourceType = publicId.includes('/stamps/') ? 'image' : 'raw';

      // Delete from Cloudinary
      await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });

      // Delete from database
      await prisma.file.deleteMany({
        where: { publicId },
      });

      return true;
    } catch (error) {
      console.error('Delete file error:', error);
      return false;
    }
  }

  /**
   * Replace existing file (delete old, upload new)
   */
  static async replaceFile(
    oldPublicId: string,
    newFile: Express.Multer.File,
    options: UploadOptions
  ): Promise<UploadResult> {
    try {
      // Upload new file first
      const uploadResult =
        options.resourceType === 'image'
          ? await this.uploadImage(newFile, options)
          : await this.uploadDocument(newFile, options);

      if (!uploadResult.success) {
        return uploadResult;
      }

      // Delete old file
      await this.deleteFile(oldPublicId);

      return uploadResult;
    } catch (error: any) {
      return { success: false, error: error.message || 'Replace failed' };
    }
  }

  /**
   * Get file URL from database
   */
  static async getFileUrl(fileId: string): Promise<string | null> {
    try {
      const file = await prisma.file.findUnique({
        where: { id: fileId },
        select: { url: true },
      });
      return file?.url || null;
    } catch (error) {
      console.error('Get file URL error:', error);
      return null;
    }
  }

  /**
   * Download file from URL as buffer
   */
  static async downloadFile(url: string): Promise<Buffer> {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to download file: ${response.statusText}`);
    }
    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }
}
