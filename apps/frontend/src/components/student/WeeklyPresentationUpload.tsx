'use client';

import { useState } from 'react';
import FileUpload from '../shared/FileUpload';
import { uploadWeeklyPresentation } from '@/lib/api/fileUpload';
import { useTranslations } from 'next-intl';

interface WeeklyPresentationUploadProps {
  weeklyPlanId: number;
  userId: number;
  organizationId: number;
  currentPresentationUrl?: string;
  onUploadSuccess?: (url: string) => void;
}

export default function WeeklyPresentationUpload({
  weeklyPlanId,
  userId,
  organizationId,
  currentPresentationUrl,
  onUploadSuccess,
}: WeeklyPresentationUploadProps) {
  const t = useTranslations('StudentPortal.weeklyPresentation');
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (file: File) => {
    setUploading(true);
    try {
      const result = await uploadWeeklyPresentation(
        file,
        weeklyPlanId,
        userId,
        organizationId
      );

      if (result.success && result.url) {
        onUploadSuccess?.(result.url);
      }

      return result;
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="bg-green-50 border border-green-200 rounded-lg p-4">
        <h3 className="text-sm font-medium text-green-900 mb-2">
          {t('guidelinesTitle')}
        </h3>
        <ul className="text-sm text-green-700 space-y-1">
          <li>• {t('formats')}</li>
          <li>• {t('maxSize')}</li>
          <li>• {t('includeProgress')}</li>
          <li>• {t('canReupload')}</li>
        </ul>
      </div>

      <FileUpload
        accept=".pdf,.ppt,.pptx"
        maxSize={10}
        onUpload={handleUpload}
        label={t('uploadTitle')}
        description={t('uploadDesc')}
        currentFileUrl={currentPresentationUrl}
        disabled={uploading}
        fileType="document"
      />

      {currentPresentationUrl && (
        <div className="text-sm text-gray-600">
          <p>
            {t('replaceNote')}
          </p>
        </div>
      )}
    </div>
  );
}
