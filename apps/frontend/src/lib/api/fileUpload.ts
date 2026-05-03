import { getApiOrigin } from '../apiOrigin';
import { cloudinaryService } from '../services/cloudinary.service';
import { FileValidationService } from '../services/fileValidation.service';

const API_URL = getApiOrigin();

/**
 * Get authorization header with token
 */
function getAuthHeader(): HeadersInit {
  const token = localStorage.getItem('token');
  return token ? { Authorization: `Bearer ${token}` } : {};
}

/**
 * Send file metadata to backend after Cloudinary upload
 */
async function saveFileMetadata(
  url: string,
  publicId: string,
  filename: string,
  mimeType: string,
  size: number,
  type: string,
  additionalData?: Record<string, any>
): Promise<{ success: boolean; error?: string }> {
  try {
    console.log('📤 Sending metadata to backend...', {
      url,
      publicId,
      filename,
      type,
      size: `${(size / 1024 / 1024).toFixed(2)} MB`,
    });

    const response = await fetch(`${API_URL}/api/files/save-metadata`, {
      method: 'POST',
      headers: {
        ...getAuthHeader(),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        url,
        publicId,
        filename,
        mimeType,
        size,
        type,
        ...additionalData,
      }),
    });

    const data = await response.json();

    if (response.ok) {
      console.log('✅ Metadata saved to database successfully!');
      return { success: true };
    } else {
      console.error('❌ Failed to save metadata:', data.error);
      return { success: false, error: data.error || 'Failed to save file metadata' };
    }
  } catch (error: any) {
    console.error('❌ Metadata save error:', error);
    return { success: false, error: error.message || 'Failed to save file metadata' };
  }
}

/**
 * Admin: Upload verification document for organization
 */
export async function uploadVerificationDocument(
  file: File,
  organizationType: 'UNIVERSITY' | 'COMPANY',
  organizationId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    console.log('📋 Starting verification document upload...', {
      organizationType,
      organizationId,
      filename: file.name,
    });

    // Validate file
    const validation = FileValidationService.validatePDF(file);
    if (!validation.valid) {
      console.error('❌ Validation failed:', validation.error);
      return { success: false, error: validation.error };
    }

    console.log('✅ File validation passed');

    // Upload to Cloudinary
    const folder = `internlink/${organizationId}/verification-docs`;
    const uploadResult = await cloudinaryService.uploadDocument(file, folder);

    if (!uploadResult.success) {
      return { success: false, error: uploadResult.error };
    }

    console.log('💾 Saving metadata to backend...');

    // Save metadata to backend
    const metadataResult = await saveFileMetadata(
      uploadResult.url!,
      uploadResult.publicId!,
      uploadResult.filename!,
      file.type,
      uploadResult.size!,
      'VERIFICATION_DOC',
      { organizationType, organizationId }
    );

    if (!metadataResult.success) {
      console.error('❌ Failed to save metadata:', metadataResult.error);
      return { success: false, error: metadataResult.error };
    }

    console.log('✅ Verification document upload complete!');
    console.log('🔗 File URL:', uploadResult.url);

    return { success: true, url: uploadResult.url };
  } catch (error: any) {
    console.error('❌ Upload error:', error);
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Student: Upload weekly presentation
 */
export async function uploadWeeklyPresentation(
  file: File,
  weeklyPlanId: number,
  userId: number,
  organizationId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    console.log('📊 Starting weekly presentation upload...', {
      weeklyPlanId,
      userId,
      organizationId,
      filename: file.name,
    });

    // Validate file
    const validation = FileValidationService.validatePresentation(file);
    if (!validation.valid) {
      console.error('❌ Validation failed:', validation.error);
      return { success: false, error: validation.error };
    }

    console.log('✅ File validation passed');

    // Upload to Cloudinary
    const folder = `internlink/${organizationId}/${userId}/weekly-presentations`;
    const uploadResult = await cloudinaryService.uploadDocument(file, folder);

    if (!uploadResult.success) {
      return { success: false, error: uploadResult.error };
    }

    console.log('💾 Saving metadata to backend...');

    // Save metadata to backend
    const metadataResult = await saveFileMetadata(
      uploadResult.url!,
      uploadResult.publicId!,
      uploadResult.filename!,
      file.type,
      uploadResult.size!,
      'WEEKLY_PRESENTATION',
      { weeklyPlanId, userId, organizationId }
    );

    if (!metadataResult.success) {
      console.error('❌ Failed to save metadata:', metadataResult.error);
      return { success: false, error: metadataResult.error };
    }

    console.log('✅ Weekly presentation upload complete!');
    console.log('🔗 File URL:', uploadResult.url);

    return { success: true, url: uploadResult.url };
  } catch (error: any) {
    console.error('❌ Upload error:', error);
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Supervisor: Upload company stamp
 */
export async function uploadCompanyStamp(
  file: File,
  userId: number,
  organizationId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    console.log('🏢 Starting company stamp upload...', {
      userId,
      organizationId,
      filename: file.name,
    });

    // Validate file
    const validation = FileValidationService.validateImage(file);
    if (!validation.valid) {
      console.error('❌ Validation failed:', validation.error);
      return { success: false, error: validation.error };
    }

    console.log('✅ File validation passed');

    // Upload to Cloudinary
    const folder = `internlink/${organizationId}/${userId}/stamps`;
    const uploadResult = await cloudinaryService.uploadImage(file, folder);

    if (!uploadResult.success) {
      return { success: false, error: uploadResult.error };
    }

    console.log('💾 Saving metadata to backend...');

    // Save metadata to backend
    const metadataResult = await saveFileMetadata(
      uploadResult.url!,
      uploadResult.publicId!,
      uploadResult.filename!,
      file.type,
      uploadResult.size!,
      'COMPANY_STAMP',
      { userId, organizationId }
    );

    if (!metadataResult.success) {
      console.error('❌ Failed to save metadata:', metadataResult.error);
      return { success: false, error: metadataResult.error };
    }

    console.log('✅ Company stamp upload complete!');
    console.log('🔗 File URL:', uploadResult.url);

    return { success: true, url: uploadResult.url };
  } catch (error: any) {
    console.error('❌ Upload error:', error);
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Upload signed final report
 */
export async function uploadSignedReport(
  file: File,
  studentId: number,
  organizationId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    console.log('📝 Starting final report upload...', {
      studentId,
      organizationId,
      filename: file.name,
    });

    // Validate file
    const validation = FileValidationService.validatePDF(file);
    if (!validation.valid) {
      console.error('❌ Validation failed:', validation.error);
      return { success: false, error: validation.error };
    }

    console.log('✅ File validation passed');

    // Upload to Cloudinary
    const folder = `internlink/${organizationId}/${studentId}/final-reports`;
    const uploadResult = await cloudinaryService.uploadDocument(file, folder);

    if (!uploadResult.success) {
      return { success: false, error: uploadResult.error };
    }

    console.log('💾 Saving metadata to backend...');

    // Save metadata to backend
    const metadataResult = await saveFileMetadata(
      uploadResult.url!,
      uploadResult.publicId!,
      uploadResult.filename!,
      file.type,
      uploadResult.size!,
      'FINAL_REPORT',
      { studentId, organizationId }
    );

    if (!metadataResult.success) {
      console.error('❌ Failed to save metadata:', metadataResult.error);
      return { success: false, error: metadataResult.error };
    }

    console.log('✅ Final report upload complete!');
    console.log('🔗 File URL:', uploadResult.url);

    return { success: true, url: uploadResult.url };
  } catch (error: any) {
    console.error('❌ Upload error:', error);
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Generate stamped report for student
 */
export async function generateStampedReport(
  studentId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const response = await fetch(`${API_URL}/api/reports/generate/${studentId}`, {
      method: 'GET',
      headers: {
        ...getAuthHeader(),
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (response.ok) {
      return { success: true, url: data.reportUrl };
    } else {
      return { success: false, error: data.error || data.message || 'Generation failed' };
    }
  } catch (error: any) {
    return { success: false, error: error.message || 'Generation failed' };
  }
}

/**
 * Download file from URL
 */
export function downloadFile(url: string, filename?: string) {
  const link = document.createElement('a');
  link.href = url;
  link.target = '_blank';
  if (filename) {
    link.download = filename;
  }
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
