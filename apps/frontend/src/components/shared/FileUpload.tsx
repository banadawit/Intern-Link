'use client';

import { useState, useRef } from 'react';
import { Upload, X, FileText, Image as ImageIcon, CheckCircle, AlertCircle } from 'lucide-react';

interface FileUploadProps {
  accept?: string;
  maxSize?: number; // in MB
  onUpload: (file: File) => Promise<{ success: boolean; url?: string; error?: string }>;
  label?: string;
  description?: string;
  currentFileUrl?: string;
  disabled?: boolean;
  fileType?: 'image' | 'document';
}

export default function FileUpload({
  accept = '.pdf,.doc,.docx,.ppt,.pptx',
  maxSize = 10,
  onUpload,
  label = 'Upload File',
  description,
  currentFileUrl,
  disabled = false,
  fileType = 'document',
}: FileUploadProps) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadStatus, setUploadStatus] = useState<{
    type: 'success' | 'error' | null;
    message: string;
  }>({ type: null, message: '' });
  const [preview, setPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file size
    if (file.size > maxSize * 1024 * 1024) {
      setUploadStatus({
        type: 'error',
        message: `File size exceeds ${maxSize}MB limit`,
      });
      return;
    }

    setSelectedFile(file);
    setUploadStatus({ type: null, message: '' });

    // Generate preview for images
    if (fileType === 'image' && file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    setUploading(true);
    setUploadStatus({ type: null, message: '' });

    try {
      const result = await onUpload(selectedFile);

      if (result.success) {
        setUploadStatus({
          type: 'success',
          message: 'File uploaded successfully!',
        });
        setSelectedFile(null);
        setPreview(null);
        if (fileInputRef.current) {
          fileInputRef.current.value = '';
        }
      } else {
        setUploadStatus({
          type: 'error',
          message: result.error || 'Upload failed',
        });
      }
    } catch (error: any) {
      setUploadStatus({
        type: 'error',
        message: error.message || 'Upload failed',
      });
    } finally {
      setUploading(false);
    }
  };

  const handleCancel = () => {
    setSelectedFile(null);
    setPreview(null);
    setUploadStatus({ type: null, message: '' });
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="space-y-4 relative">
      {/* Uploading Overlay */}
      {uploading && (
        <div className="absolute inset-0 bg-white/60 z-10 flex flex-col items-center justify-center rounded-lg backdrop-blur-[1px]">
          <div className="bg-white p-6 rounded-xl shadow-xl border border-gray-100 flex flex-col items-center space-y-4 max-w-sm">
            <div className="relative">
              <svg
                className="animate-spin h-10 w-10 text-blue-600"
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
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="h-4 w-4 bg-blue-100 rounded-full animate-pulse"></div>
              </div>
            </div>
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-900">
                Processing Upload
              </p>
              <p className="text-xs text-gray-500 mt-1 px-4 leading-relaxed">
                We're uploading your file to Cloudinary and securing it in our database. 
                <span className="block font-medium text-blue-600 mt-1">Please do not close this page.</span>
              </p>
            </div>
          </div>
        </div>
      )}

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          {label}
        </label>
        {description && (
          <p className="text-sm text-gray-500 mb-3">{description}</p>
        )}

        {/* Current File Display */}
        {currentFileUrl && !selectedFile && (
          <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                {fileType === 'image' ? (
                  <ImageIcon className="w-5 h-5 text-blue-600" />
                ) : (
                  <FileText className="w-5 h-5 text-blue-600" />
                )}
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    Current File
                  </p>
                  <a
                    href={currentFileUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-blue-600 hover:underline"
                  >
                    View File
                  </a>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* File Input */}
        <div className="flex items-center space-x-4">
          <input
            ref={fileInputRef}
            type="file"
            accept={accept}
            onChange={handleFileSelect}
            disabled={disabled || uploading}
            className="hidden"
            id={`file-upload-${label.replace(/\s/g, '-')}`}
          />
          <label
            htmlFor={`file-upload-${label.replace(/\s/g, '-')}`}
            className={`
              inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium
              ${
                disabled || uploading
                  ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                  : 'bg-white text-gray-700 hover:bg-gray-50 cursor-pointer'
              }
            `}
          >
            <Upload className="w-4 h-4 mr-2" />
            Choose File
          </label>

          {selectedFile && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">{selectedFile.name}</span>
              <button
                onClick={handleCancel}
                disabled={uploading}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>

        {/* Image Preview */}
        {preview && fileType === 'image' && (
          <div className="mt-4">
            <img
              src={preview}
              alt="Preview"
              className="max-w-xs max-h-48 rounded-lg border border-gray-300"
            />
          </div>
        )}

        {/* Upload Button */}
        {selectedFile && (
          <button
            onClick={handleUpload}
            disabled={uploading || disabled}
            className={`
              mt-4 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white
              ${
                uploading || disabled
                  ? 'bg-blue-400 cursor-not-allowed'
                  : 'bg-blue-600 hover:bg-blue-700'
              }
            `}
          >
            {uploading ? (
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
                Uploading...
              </>
            ) : (
              <>
                <Upload className="w-4 h-4 mr-2" />
                Upload File
              </>
            )}
          </button>
        )}

        {/* Status Messages */}
        {uploadStatus.type && (
          <div
            className={`mt-4 p-4 rounded-lg flex items-start space-x-3 ${
              uploadStatus.type === 'success'
                ? 'bg-green-50 border border-green-200'
                : 'bg-red-50 border border-red-200'
            }`}
          >
            {uploadStatus.type === 'success' ? (
              <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
            ) : (
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
            )}
            <p
              className={`text-sm ${
                uploadStatus.type === 'success'
                  ? 'text-green-800'
                  : 'text-red-800'
              }`}
            >
              {uploadStatus.message}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
