'use client';

import { useState } from 'react';
import FileUpload from '../shared/FileUpload';
import { uploadVerificationDocument } from '@/lib/api/fileUpload';

interface VerificationDocumentUploadProps {
  organizationType: 'UNIVERSITY' | 'COMPANY';
  organizationId: number;
  currentDocUrl?: string;
  onUploadSuccess?: (url: string) => void;
}

export default function VerificationDocumentUpload({
  organizationType,
  organizationId,
  currentDocUrl,
  onUploadSuccess,
}: VerificationDocumentUploadProps) {
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (file: File) => {
    setUploading(true);
    try {
      const result = await uploadVerificationDocument(
        file,
        organizationType,
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
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 className="text-sm font-medium text-blue-900 mb-2">
          Verification Document Requirements
        </h3>
        <ul className="text-sm text-blue-700 space-y-1">
          <li>• PDF format only</li>
          <li>• Maximum file size: 10MB</li>
          <li>• Official documents with stamps/signatures</li>
          <li>• Clear and readable scans</li>
        </ul>
      </div>

      <FileUpload
        accept=".pdf"
        maxSize={10}
        onUpload={handleUpload}
        label="Upload Verification Document"
        description="Upload official verification documents for organization approval"
        currentFileUrl={currentDocUrl}
        disabled={uploading}
        fileType="document"
      />
    </div>
  );
}
