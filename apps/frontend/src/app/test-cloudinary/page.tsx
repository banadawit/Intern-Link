'use client';

import { useState } from 'react';

export default function TestCloudinaryPage() {
  const [result, setResult] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const testConfig = () => {
    const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

    setResult(`
Configuration:
✓ Cloud Name: ${cloudName || '❌ NOT SET'}
✓ Upload Preset: ${uploadPreset || '❌ NOT SET'}

${!cloudName ? '⚠️ NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME is missing!\n' : ''}
${!uploadPreset ? '⚠️ NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET is missing!\n' : ''}
    `.trim());
  };

  const testUpload = async () => {
    setLoading(true);
    setResult('Testing upload...\n');

    try {
      const cloudName = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME;
      const uploadPreset = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET;

      if (!cloudName || !uploadPreset) {
        setResult('❌ Configuration missing! Check your .env file.');
        return;
      }

      // Create a test file
      const blob = new Blob(['test content'], { type: 'text/plain' });
      const file = new File([blob], 'test.txt', { type: 'text/plain' });

      const formData = new FormData();
      formData.append('file', file);
      formData.append('upload_preset', uploadPreset);
      formData.append('folder', 'internlink/test');

      const url = `https://api.cloudinary.com/v1_1/${cloudName}/raw/upload`;
      
      setResult(prev => prev + `\nUploading to: ${url}\n`);

      const response = await fetch(url, {
        method: 'POST',
        body: formData,
      });

      setResult(prev => prev + `\nResponse Status: ${response.status} ${response.statusText}\n`);

      if (!response.ok) {
        let errorDetails = '';
        try {
          const errorData = await response.json();
          errorDetails = JSON.stringify(errorData, null, 2);
        } catch {
          errorDetails = await response.text();
        }
        
        setResult(prev => prev + `\n❌ Upload Failed!\n\nError Details:\n${errorDetails}\n\n`);
        
        // Provide specific guidance
        if (response.status === 400) {
          setResult(prev => prev + `
Possible causes:
1. Upload preset "internlink_uploads" doesn't exist
2. Upload preset is set to "Signed" instead of "Unsigned"
3. Cloud name is incorrect

Fix:
1. Go to: https://cloudinary.com/console
2. Settings → Upload → Upload presets
3. Create/Edit preset: "internlink_uploads"
4. Set Signing Mode to: "Unsigned"
5. Save and restart your dev server
          `);
        }
        return;
      }

      const data = await response.json();
      setResult(prev => prev + `\n✅ Upload Successful!\n\nResponse:\n${JSON.stringify(data, null, 2)}\n\nURL: ${data.secure_url}`);

    } catch (error: any) {
      setResult(prev => prev + `\n❌ Error: ${error.message}\n\n${error.stack}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Cloudinary Configuration Test</h1>
        
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <div className="space-x-4">
            <button
              onClick={testConfig}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Check Configuration
            </button>
            
            <button
              onClick={testUpload}
              disabled={loading}
              className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:bg-gray-400"
            >
              {loading ? 'Testing...' : 'Test Upload'}
            </button>
          </div>

          {result && (
            <pre className="mt-4 p-4 bg-gray-100 rounded overflow-auto text-sm">
              {result}
            </pre>
          )}

          <div className="mt-8 p-4 bg-blue-50 rounded">
            <h2 className="font-bold mb-2">Setup Instructions:</h2>
            <ol className="list-decimal list-inside space-y-2 text-sm">
              <li>Go to <a href="https://cloudinary.com/console" target="_blank" className="text-blue-600 underline">Cloudinary Console</a></li>
              <li>Settings (gear icon) → Upload → Upload presets</li>
              <li>Create preset named: <code className="bg-gray-200 px-1">internlink_uploads</code></li>
              <li>Set Signing Mode to: <strong>Unsigned</strong></li>
              <li>Save the preset</li>
              <li>Update your <code className="bg-gray-200 px-1">.env</code> file with correct values</li>
              <li>Restart your development server</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
