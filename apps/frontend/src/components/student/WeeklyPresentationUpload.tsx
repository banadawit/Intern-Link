'use client';

import FileUpload from '../shared/FileUpload';
import { uploadWeeklyPresentation } from '@/lib/api/fileUpload';

interface WeeklyPresentationUploadProps {
  weeklyPlanId: number;
  currentFileUrl?: string;
  onUploadSuccess?: (url: string) => void;
}

export default function WeeklyPresentationUpload({
  weeklyPlanId,
  currentFileUrl,
  onUploadSuccess,
}: WeeklyPresentationUploadProps) {
  const handleUpload = async (file: File) => {
    const result = await uploadWeeklyPresentation(file, weeklyPlanId);

    if (result.success && result.url && onUploadSuccess) {
      onUploadSuccess(result.url);
    }

    return result;
  };

  return (
    <FileUpload
      accept=".pdf,.ppt,.pptx"
      maxSize={10}
      onUpload={handleUpload}
      label="Weekly Presentation"
      description="Upload your weekly presentation (PDF, PPT, or PPTX, max 10MB). You can re-upload to replace the previous file."
      currentFileUrl={currentFileUrl}
      fileType="document"
    />
  );
}
