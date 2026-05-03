/**
 * File Validation Service
 * Validates file types, sizes, and MIME types before upload
 */

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export class FileValidationService {
  // MIME type mappings
  private static readonly MIME_TYPES = {
    PDF: ['application/pdf'],
    IMAGE: ['image/png', 'image/jpeg', 'image/jpg'],
    PPT: [
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    ],
    DOCUMENT: [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ],
  };

  // Max file size in bytes (10MB)
  private static readonly MAX_SIZE = 10 * 1024 * 1024;

  /**
   * Validate PDF file
   */
  static validatePDF(file: File): ValidationResult {
    if (!this.MIME_TYPES.PDF.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Only PDF files are allowed.',
      };
    }

    return this.validateSize(file);
  }

  /**
   * Validate image file (PNG, JPG, JPEG)
   */
  static validateImage(file: File): ValidationResult {
    if (!this.MIME_TYPES.IMAGE.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Only PNG and JPEG images are allowed.',
      };
    }

    return this.validateSize(file);
  }

  /**
   * Validate presentation file (PPT, PPTX)
   */
  static validatePresentation(file: File): ValidationResult {
    const validTypes = [...this.MIME_TYPES.PPT, ...this.MIME_TYPES.PDF];
    
    if (!validTypes.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Only PDF and PowerPoint files are allowed.',
      };
    }

    return this.validateSize(file);
  }

  /**
   * Validate document file (PDF, DOC, DOCX)
   */
  static validateDocument(file: File): ValidationResult {
    if (!this.MIME_TYPES.DOCUMENT.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Only PDF and Word documents are allowed.',
      };
    }

    return this.validateSize(file);
  }

  /**
   * Validate file size
   */
  static validateSize(file: File, maxSize: number = this.MAX_SIZE): ValidationResult {
    if (file.size > maxSize) {
      const maxSizeMB = maxSize / (1024 * 1024);
      return {
        valid: false,
        error: `File size exceeds ${maxSizeMB}MB limit.`,
      };
    }

    return { valid: true };
  }

  /**
   * Get human-readable file size
   */
  static formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }

  /**
   * Get file extension
   */
  static getFileExtension(filename: string): string {
    return filename.slice(((filename.lastIndexOf('.') - 1) >>> 0) + 2);
  }
}
