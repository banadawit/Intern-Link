'use client';

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
  const handleUpload = async (file: File) => {
    const result = await uploadVerificationDocument(
      file,
      organizationType,
      organizationId
    );

    if (result.success && result.url && onUploadSuccess) {
      onUploadSuccess(result.url);
    }

    return result;
  };

  return (
    <FileUpload
      accept=".pdf"
      maxSize={10}
      onUpload={handleUpload}
      label="Verification Document"
      description="Upload official verification document (PDF only, max 10MB)"
      currentFileUrl={currentDocUrl}
      fileType="document"
    />
  );
}
