import { apiOrigin } from '../apiOrigin';

const API_URL = apiOrigin;

/**
 * Get authorization header with token
 */
function getAuthHeader(): HeadersInit {
  const token = localStorage.getItem('token');
  return token ? { Authorization: `Bearer ${token}` } : {};
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
    const formData = new FormData();
    formData.append('file', file);
    formData.append('organizationType', organizationType);
    formData.append('organizationId', organizationId.toString());

    const response = await fetch(`${API_URL}/api/admin/upload-verification`, {
      method: 'POST',
      headers: getAuthHeader(),
      body: formData,
    });

    const data = await response.json();

    if (response.ok) {
      return { success: true, url: data.url };
    } else {
      return { success: false, error: data.error || 'Upload failed' };
    }
  } catch (error: any) {
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Student: Upload weekly presentation
 */
export async function uploadWeeklyPresentation(
  file: File,
  weeklyPlanId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('weeklyPlanId', weeklyPlanId.toString());

    const response = await fetch(`${API_URL}/api/students/upload-presentation`, {
      method: 'POST',
      headers: getAuthHeader(),
      body: formData,
    });

    const data = await response.json();

    if (response.ok) {
      return { success: true, url: data.url };
    } else {
      return { success: false, error: data.error || 'Upload failed' };
    }
  } catch (error: any) {
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Supervisor: Upload company stamp
 */
export async function uploadCompanyStamp(
  file: File
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${API_URL}/api/supervisors/upload-stamp`, {
      method: 'POST',
      headers: getAuthHeader(),
      body: formData,
    });

    const data = await response.json();

    if (response.ok) {
      return { success: true, url: data.url };
    } else {
      return { success: false, error: data.error || 'Upload failed' };
    }
  } catch (error: any) {
    return { success: false, error: error.message || 'Upload failed' };
  }
}

/**
 * Upload signed final report
 */
export async function uploadSignedReport(
  file: File,
  studentId: number
): Promise<{ success: boolean; url?: string; error?: string }> {
  try {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('studentId', studentId.toString());

    const response = await fetch(`${API_URL}/api/reports/upload-signed`, {
      method: 'POST',
      headers: getAuthHeader(),
      body: formData,
    });

    const data = await response.json();

    if (response.ok) {
      return { success: true, url: data.url };
    } else {
      return { success: false, error: data.error || 'Upload failed' };
    }
  } catch (error: any) {
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
