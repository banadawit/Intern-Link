/**
 * Cloudinary Frontend Upload Service
 * Handles direct uploads from browser to Cloudinary
 */

interface CloudinaryUploadResponse {
  secure_url: string;
  public_id: string;
  resource_type: string;
  format: string;
  bytes: number;
  original_filename: string;
}

interface UploadResult {
  success: boolean;
  url?: string;
  publicId?: string;
  error?: string;
  filename?: string;
  size?: number;
  format?: string;
}

export class CloudinaryService {
  private cloudName: string;
  private uploadPreset: string;

  constructor() {
    this.cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME || '';
    this.uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET || 'internlink_uploads';
    
    if (!this.cloudName) {
      console.error('NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME is not set');
    }
  }

  /**
   * Upload file directly to Cloudinary from browser
   */
  async uploadFile(
    file: File,
    folder: string,
    resourceType: 'image' | 'raw' = 'raw'
  ): Promise<UploadResult> {
    try {
      // Verify configuration
      if (!this.cloudName) {
        throw new Error('Cloudinary cloud name is not configured. Please set NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME in .env');
      }
      
      if (!this.uploadPreset) {
        throw new Error('Cloudinary upload preset is not configured. Please set NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET in .env');
      }

      console.log('🚀 Starting Cloudinary upload...', {
        filename: file.name,
        size: `${(file.size / 1024 / 1024).toFixed(2)} MB`,
        type: file.type,
        folder: folder,
        resourceType: resourceType,
        cloudName: this.cloudName,
        uploadPreset: this.uploadPreset,
      });

      const formData = new FormData();
      formData.append('file', file);
      formData.append('upload_preset', this.uploadPreset);
      formData.append('folder', folder);
      formData.append('resource_type', resourceType);

      const uploadStartTime = Date.now();

      const response = await fetch(
        `https://api.cloudinary.com/v1_1/${this.cloudName}/${resourceType}/upload`,
        {
          method: 'POST',
          body: formData,
        }
      );

      if (!response.ok) {
        console.error('❌ Cloudinary upload failed with status:', response.status, response.statusText);
        let errorMessage = `Upload failed with status ${response.status}`;
        
        try {
          const error = await response.json();
          console.error('❌ Error details:', error);
          errorMessage = error.error?.message || error.message || errorMessage;
        } catch (parseError) {
          // Response might not be JSON
          const textError = await response.text();
          console.error('❌ Error response (text):', textError);
          errorMessage = textError || errorMessage;
        }
        
        throw new Error(errorMessage);
      }

      const data: CloudinaryUploadResponse = await response.json();
      const uploadDuration = ((Date.now() - uploadStartTime) / 1000).toFixed(2);

      console.log('✅ File uploaded to Cloudinary successfully!', {
        url: data.secure_url,
        publicId: data.public_id,
        filename: data.original_filename,
        size: `${(data.bytes / 1024 / 1024).toFixed(2)} MB`,
        format: data.format,
        duration: `${uploadDuration}s`,
        folder: folder,
      });

      console.log('📎 Direct URL:', data.secure_url);

      return {
        success: true,
        url: data.secure_url,
        publicId: data.public_id,
        filename: data.original_filename,
        size: data.bytes,
        format: data.format,
      };
    } catch (error: any) {
      console.error('❌ Cloudinary upload error:', error);
      return {
        success: false,
        error: error.message || 'Upload failed',
      };
    }
  }

  /**
   * Upload image (PNG, JPG, JPEG)
   */
  async uploadImage(file: File, folder: string): Promise<UploadResult> {
    console.log('📸 Uploading image to Cloudinary...');
    return this.uploadFile(file, folder, 'image');
  }

  /**
   * Upload document (PDF, PPT, DOCX, etc.)
   */
  async uploadDocument(file: File, folder: string): Promise<UploadResult> {
    console.log('📄 Uploading document to Cloudinary...');
    return this.uploadFile(file, folder, 'raw');
  }

  /**
   * Delete file from Cloudinary (requires backend call for security)
   */
  async deleteFile(publicId: string): Promise<boolean> {
    // This should be called through backend API for security
    console.warn('Delete operation should be handled by backend');
    return false;
  }
}

// Export singleton instance
export const cloudinaryService = new CloudinaryService();
