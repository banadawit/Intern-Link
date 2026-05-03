'use client';

import { useState } from 'react';
import FileUpload from '../shared/FileUpload';
import { uploadWeeklyPresentation } from '@/lib/api/fileUpload';

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
          Weekly Presentation Guidelines
        </h3>
        <ul className="text-sm text-green-700 space-y-1">
          <li>• Accepted formats: PDF, PPT, PPTX</li>
          <li>• Maximum file size: 10MB</li>
          <li>• Include weekly progress and learnings</li>
          <li>• You can re-upload to replace previous submission</li>
        </ul>
      </div>

      <FileUpload
        accept=".pdf,.ppt,.pptx"
        maxSize={10}
        onUpload={handleUpload}
        label="Upload Weekly Presentation"
        description="Upload your weekly progress presentation"
        currentFileUrl={currentPresentationUrl}
        disabled={uploading}
        fileType="document"
      />

      {currentPresentationUrl && (
        <div className="text-sm text-gray-600">
          <p>
            Note: Uploading a new presentation will replace the previous one.
          </p>
        </div>
      )}
    </div>
  );
}
