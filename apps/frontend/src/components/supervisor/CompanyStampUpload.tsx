'use client';

import FileUpload from '../shared/FileUpload';
import { uploadCompanyStamp } from '@/lib/api/fileUpload';

interface CompanyStampUploadProps {
  currentStampUrl?: string;
  onUploadSuccess?: (url: string) => void;
}

export default function CompanyStampUpload({
  currentStampUrl,
  onUploadSuccess,
}: CompanyStampUploadProps) {
  const handleUpload = async (file: File) => {
    const result = await uploadCompanyStamp(file);

    if (result.success && result.url && onUploadSuccess) {
      onUploadSuccess(result.url);
    }

    return result;
  };

  return (
    <FileUpload
      accept=".png,.jpg,.jpeg"
      maxSize={10}
      onUpload={handleUpload}
      label="Company Stamp"
      description="Upload your company's official stamp (PNG or JPG, max 10MB). This will be used to stamp final reports."
      currentFileUrl={currentStampUrl}
      fileType="image"
    />
  );
}
