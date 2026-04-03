import { createClient } from '@supabase/supabase-js';
import { ContentSanitizationService } from './contentSanitization.service';

/**
 * File Upload Service for Common Feed
 * Handles image and document uploads with validation
 */

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_KEY || ''
);

export class FileUploadService {
  private static readonly ALLOWED_IMAGE_TYPES = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  private static readonly ALLOWED_DOCUMENT_TYPES = ['pdf', 'doc', 'docx', 'ppt', 'pptx'];
  private static readonly MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

  /**
   * Upload an image file
   */
  static async uploadImage(
    file: Express.Multer.File,
    userId: number
  ): Promise<{ success: boolean; url?: string; error?: string }> {
    try {
      // Validate file
      const validation = ContentSanitizationService.validateFileUpload(
        file.originalname,
        file.size,
        this.ALLOWED_IMAGE_TYPES
      );

      if (!validation.valid) {
        return { success: false, error: validation.error };
      }

      // Generate unique filename
      const timestamp = Date.now();
      const ext = file.originalname.split('.').pop();
      const filename = `common-feed/images/${userId}/${timestamp}.${ext}`;

      // Upload to Supabase
      const { data, error } = await supabase.storage
        .from('internlink-uploads')
        .upload(filename, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
        });

      if (error) {
        console.error('Supabase upload error:', error);
        return { success: false, error: 'Failed to upload image' };
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('internlink-uploads')
        .getPublicUrl(filename);

      return { success: true, url: urlData.publicUrl };
    } catch (error: any) {
      console.error('Upload image error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Upload a document file
   */
  static async uploadDocument(
    file: Express.Multer.File,
    userId: number
  ): Promise<{ success: boolean; url?: string; error?: string }> {
    try {
      // Validate file
      const validation = ContentSanitizationService.validateFileUpload(
        file.originalname,
        file.size,
        this.ALLOWED_DOCUMENT_TYPES
      );

      if (!validation.valid) {
        return { success: false, error: validation.error };
      }

      // Generate unique filename
      const timestamp = Date.now();
      const ext = file.originalname.split('.').pop();
      const filename = `common-feed/documents/${userId}/${timestamp}.${ext}`;

      // Upload to Supabase
      const { data, error } = await supabase.storage
        .from('internlink-uploads')
        .upload(filename, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
        });

      if (error) {
        console.error('Supabase upload error:', error);
        return { success: false, error: 'Failed to upload document' };
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('internlink-uploads')
        .getPublicUrl(filename);

      return { success: true, url: urlData.publicUrl };
    } catch (error: any) {
      console.error('Upload document error:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Upload multiple images
   */
  static async uploadMultipleImages(
    files: Express.Multer.File[],
    userId: number
  ): Promise<{ success: boolean; urls?: string[]; errors?: string[] }> {
    const results = await Promise.all(
      files.map((file) => this.uploadImage(file, userId))
    );

    const urls = results.filter((r) => r.success).map((r) => r.url!);
    const errors = results.filter((r) => !r.success).map((r) => r.error!);

    return {
      success: errors.length === 0,
      urls,
      errors: errors.length > 0 ? errors : undefined,
    };
  }

  /**
   * Upload multiple documents
   */
  static async uploadMultipleDocuments(
    files: Express.Multer.File[],
    userId: number
  ): Promise<{ success: boolean; urls?: string[]; errors?: string[] }> {
    const results = await Promise.all(
      files.map((file) => this.uploadDocument(file, userId))
    );

    const urls = results.filter((r) => r.success).map((r) => r.url!);
    const errors = results.filter((r) => !r.success).map((r) => r.error!);

    return {
      success: errors.length === 0,
      urls,
      errors: errors.length > 0 ? errors : undefined,
    };
  }

  /**
   * Delete a file from storage
   */
  static async deleteFile(fileUrl: string): Promise<boolean> {
    try {
      // Extract filename from URL
      const urlParts = fileUrl.split('/');
      const bucketIndex = urlParts.findIndex((part) => part === 'internlink-uploads');
      const filename = urlParts.slice(bucketIndex + 1).join('/');

      const { error } = await supabase.storage
        .from('internlink-uploads')
        .remove([filename]);

      if (error) {
        console.error('Delete file error:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Delete file error:', error);
      return false;
    }
  }
}
