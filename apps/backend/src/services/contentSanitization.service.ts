import DOMPurify from 'isomorphic-dompurify';
import validator from 'validator';

/**
 * Content Sanitization Service
 * Implements XSS Protection and Input Validation (SRS Section 3.5.3 & 3.5.4)
 */

export class ContentSanitizationService {
  /**
   * Sanitize HTML content to prevent XSS attacks
   */
  static sanitizeHTML(content: string): string {
    if (!content) return '';
    
    // Configure DOMPurify with strict settings
    const config = {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'blockquote'],
      ALLOWED_ATTR: ['href', 'target', 'rel'],
      ALLOW_DATA_ATTR: false,
      ALLOW_UNKNOWN_PROTOCOLS: false,
    };
    
    return DOMPurify.sanitize(content, config);
  }

  /**
   * Sanitize plain text (escape special characters)
   */
  static sanitizeText(text: string): string {
    if (!text) return '';
    return validator.escape(text);
  }

  /**
   * Validate post title
   */
  static validateTitle(title: string): { valid: boolean; error?: string } {
    if (!title || title.trim().length === 0) {
      return { valid: false, error: 'Title is required' };
    }
    
    if (title.length < 3) {
      return { valid: false, error: 'Title must be at least 3 characters' };
    }
    
    if (title.length > 200) {
      return { valid: false, error: 'Title must not exceed 200 characters' };
    }
    
    return { valid: true };
  }

  /**
   * Validate post content
   */
  static validateContent(content: string): { valid: boolean; error?: string } {
    if (!content || content.trim().length === 0) {
      return { valid: false, error: 'Content is required' };
    }
    
    if (content.length < 10) {
      return { valid: false, error: 'Content must be at least 10 characters' };
    }
    
    if (content.length > 10000) {
      return { valid: false, error: 'Content must not exceed 10,000 characters' };
    }
    
    return { valid: true };
  }

  /**
   * Validate URL
   */
  static validateURL(url: string): boolean {
    return validator.isURL(url, {
      protocols: ['http', 'https'],
      require_protocol: true,
    });
  }

  /**
   * Validate file upload
   */
  static validateFileUpload(
    filename: string,
    filesize: number,
    allowedTypes: string[]
  ): { valid: boolean; error?: string } {
    const ext = filename.split('.').pop()?.toLowerCase();
    
    if (!ext || !allowedTypes.includes(ext)) {
      return {
        valid: false,
        error: `Invalid file type. Allowed: ${allowedTypes.join(', ')}`,
      };
    }
    
    // Max file size: 10MB
    const maxSize = 10 * 1024 * 1024;
    if (filesize > maxSize) {
      return {
        valid: false,
        error: 'File size must not exceed 10MB',
      };
    }
    
    return { valid: true };
  }

  /**
   * Detect and filter profanity/inappropriate content
   */
  static containsInappropriateContent(text: string): boolean {
    // Basic profanity filter - in production, use a comprehensive library
    const inappropriateWords = [
      'spam', 'scam', 'fraud', 'hack', 'phishing',
      // Add more as needed
    ];
    
    const lowerText = text.toLowerCase();
    return inappropriateWords.some(word => lowerText.includes(word));
  }

  /**
   * Rate limiting check for spam prevention
   */
  static checkRateLimit(
    recentPosts: number,
    timeWindowMinutes: number = 60
  ): { allowed: boolean; error?: string } {
    const maxPostsPerHour = 10;
    
    if (recentPosts >= maxPostsPerHour) {
      return {
        allowed: false,
        error: `Rate limit exceeded. Maximum ${maxPostsPerHour} posts per ${timeWindowMinutes} minutes.`,
      };
    }
    
    return { allowed: true };
  }

  /**
   * Comprehensive validation for creating a post
   */
  static validatePost(data: {
    title: string;
    content: string;
    imageUrls?: string[];
    documentUrls?: string[];
  }): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    // Validate title
    const titleValidation = this.validateTitle(data.title);
    if (!titleValidation.valid) {
      errors.push(titleValidation.error!);
    }
    
    // Validate content
    const contentValidation = this.validateContent(data.content);
    if (!contentValidation.valid) {
      errors.push(contentValidation.error!);
    }
    
    // Check for inappropriate content
    if (this.containsInappropriateContent(data.title) || 
        this.containsInappropriateContent(data.content)) {
      errors.push('Content contains inappropriate or prohibited words');
    }
    
    // Validate URLs if provided
    if (data.imageUrls) {
      data.imageUrls.forEach((url, index) => {
        if (!this.validateURL(url)) {
          errors.push(`Invalid image URL at position ${index + 1}`);
        }
      });
    }
    
    if (data.documentUrls) {
      data.documentUrls.forEach((url, index) => {
        if (!this.validateURL(url)) {
          errors.push(`Invalid document URL at position ${index + 1}`);
        }
      });
    }
    
    return {
      valid: errors.length === 0,
      errors,
    };
  }
}
