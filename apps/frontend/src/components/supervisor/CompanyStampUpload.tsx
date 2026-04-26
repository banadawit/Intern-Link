'use client';

import { useState } from 'react';
import FileUpload from '../shared/FileUpload';
import { uploadCompanyStamp } from '@/lib/api/fileUpload';

interface CompanyStampUploadProps {
  userId: number;
  organizationId: number;
  currentStampUrl?: string;
  onUploadSuccess?: (url: string) => void;
}

export default function CompanyStampUpload({
  userId,
  organizationId,
  currentStampUrl,
  onUploadSuccess,
}: CompanyStampUploadProps) {
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (file: File) => {
    setUploading(true);
    try {
      const result = await uploadCompanyStamp(file, userId, organizationId);

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
      <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
        <h3 className="text-sm font-medium text-purple-900 mb-2">
          Company Stamp Requirements
        </h3>
        <ul className="text-sm text-purple-700 space-y-1">
          <li>• Image formats: PNG, JPG, JPEG</li>
          <li>• Maximum file size: 10MB</li>
          <li>• High resolution for clear stamping</li>
          <li>• Transparent background recommended (PNG)</li>
        </ul>
      </div>

      <FileUpload
        accept=".png,.jpg,.jpeg"
        maxSize={10}
        onUpload={handleUpload}
        label="Company Stamp"
        description="Upload your company's official stamp. This will be used to stamp final reports."
        currentFileUrl={currentStampUrl}
        disabled={uploading}
        fileType="image"
      />
    </div>
  );
}
