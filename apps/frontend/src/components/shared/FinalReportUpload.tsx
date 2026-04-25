'use client';

import FileUpload from './FileUpload';
import { uploadSignedReport, generateStampedReport, downloadFile } from '@/lib/api/fileUpload';
import { useState } from 'react';
import { FileText, Download } from 'lucide-react';

interface FinalReportUploadProps {
  studentId: number;
  currentReportUrl?: string;
  isLocked?: boolean;
  onUploadSuccess?: (url: string) => void;
  showGenerateButton?: boolean;
}

export default function FinalReportUpload({
  studentId,
  currentReportUrl,
  isLocked = false,
  onUploadSuccess,
  showGenerateButton = false,
}: FinalReportUploadProps) {
  const [generating, setGenerating] = useState(false);
  const [generateStatus, setGenerateStatus] = useState<{
    type: 'success' | 'error' | null;
    message: string;
  }>({ type: null, message: '' });

  const handleUpload = async (file: File) => {
    const result = await uploadSignedReport(file, studentId);

    if (result.success && result.url && onUploadSuccess) {
      onUploadSuccess(result.url);
    }

    return result;
  };

  const handleGenerate = async () => {
    setGenerating(true);
    setGenerateStatus({ type: null, message: '' });

    try {
      const result = await generateStampedReport(studentId);

      if (result.success) {
        setGenerateStatus({
          type: 'success',
          message: 'Report generated successfully!',
        });
        if (result.url && onUploadSuccess) {
          onUploadSuccess(result.url);
        }
      } else {
        setGenerateStatus({
          type: 'error',
          message: result.error || 'Generation failed',
        });
      }
    } catch (error: any) {
      setGenerateStatus({
        type: 'error',
        message: error.message || 'Generation failed',
      });
    } finally {
      setGenerating(false);
    }
  };

  const handleDownload = () => {
    if (currentReportUrl) {
      downloadFile(currentReportUrl, `final-report-${studentId}.pdf`);
    }
  };

  return (
    <div className="space-y-6">
      {/* Current Report Display */}
      {currentReportUrl && (
        <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <FileText className="w-5 h-5 text-green-600" />
              <div>
                <p className="text-sm font-medium text-gray-900">
                  Final Report Available
                </p>
                <p className="text-xs text-gray-600">
                  {isLocked ? 'Report is locked (sent to university)' : 'Report can be replaced'}
                </p>
              </div>
            </div>
            <button
              onClick={handleDownload}
              className="inline-flex items-center px-3 py-2 border border-green-600 rounded-md text-sm font-medium text-green-600 hover:bg-green-100"
            >
              <Download className="w-4 h-4 mr-2" />
              Download
            </button>
          </div>
        </div>
      )}

      {/* Generate Button */}
      {showGenerateButton && !isLocked && (
        <div>
          <button
            onClick={handleGenerate}
            disabled={generating}
            className={`
              w-full inline-flex items-center justify-center px-4 py-3 border border-transparent rounded-md shadow-sm text-sm font-medium text-white
              ${
                generating
                  ? 'bg-blue-400 cursor-not-allowed'
                  : 'bg-blue-600 hover:bg-blue-700'
              }
            `}
          >
            {generating ? (
              <>
                <svg
                  className="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  ></circle>
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                Generating Report...
              </>
            ) : (
              <>
                <FileText className="w-4 h-4 mr-2" />
                Generate Stamped Report
              </>
            )}
          </button>

          {generateStatus.type && (
            <div
              className={`mt-3 p-3 rounded-lg text-sm ${
                generateStatus.type === 'success'
                  ? 'bg-green-50 border border-green-200 text-green-800'
                  : 'bg-red-50 border border-red-200 text-red-800'
              }`}
            >
              {generateStatus.message}
            </div>
          )}
        </div>
      )}

      {/* Manual Upload */}
      {!isLocked && (
        <div>
          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-sm font-medium text-gray-900 mb-4">
              Or Upload Signed Report Manually
            </h3>
            <FileUpload
              accept=".pdf"
              maxSize={10}
              onUpload={handleUpload}
              label="Signed Final Report"
              description="Upload a manually signed final report (PDF only, max 10MB)"
              currentFileUrl={currentReportUrl}
              fileType="document"
              disabled={isLocked}
            />
          </div>
        </div>
      )}

      {isLocked && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">
            This report has been sent to the university and is locked. No further modifications are allowed.
          </p>
        </div>
      )}
    </div>
  );
}
