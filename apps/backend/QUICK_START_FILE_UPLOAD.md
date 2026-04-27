# 🚀 Quick Start - File Upload System

## Prerequisites

✅ All dependencies installed (`npm install` already run)  
✅ Cloudinary credentials configured in `.env`  
✅ Database migrated (`npx prisma migrate dev`)  
✅ Backend server running (`npm run dev`)

---

## 🔑 Cloudinary Configuration

Your Cloudinary credentials are already configured in `apps/backend/.env`:

```env
CLOUDINARY_CLOUD_NAME=dhhlz8ruy
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=Qslki13xaLg-RjbS8SGCeibXBZ4
```

⚠️ **IMPORTANT:** Make sure to add your actual Cloudinary API Key in the `.env` file.

You can find your credentials at: https://console.cloudinary.com/

---

## 📍 Available Endpoints

### 1. Admin - Upload Verification Document
```
POST /api/admin/upload-verification
Authorization: Bearer {admin_token}
Content-Type: multipart/form-data

Body:
- file: PDF file (max 10MB)
- organizationType: "UNIVERSITY" or "COMPANY"
- organizationId: number
```

### 2. Student - Upload Weekly Presentation
```
POST /api/students/upload-presentation
Authorization: Bearer {student_token}
Content-Type: multipart/form-data

Body:
- file: PDF/PPT/PPTX file (max 10MB)
- weeklyPlanId: number
```

### 3. Supervisor - Upload Company Stamp
```
POST /api/supervisors/upload-stamp
Authorization: Bearer {supervisor_token}
Content-Type: multipart/form-data

Body:
- file: PNG/JPG image (max 10MB)
```

### 4. Upload Signed Final Report
```
POST /api/reports/upload-signed
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- file: PDF file (max 10MB)
- studentId: number
```

### 5. Generate Stamped Report
```
GET /api/reports/generate/:studentId
Authorization: Bearer {token}
```

---

## 🧪 Testing with Postman

### Step 1: Get Authentication Token

First, login to get a JWT token:

```
POST http://localhost:5000/api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "your_password"
}
```

Copy the `token` from the response.

### Step 2: Test File Upload

**Example: Upload Company Stamp**

1. Create a new POST request in Postman
2. URL: `http://localhost:5000/api/supervisors/upload-stamp`
3. Headers:
   - `Authorization`: `Bearer YOUR_TOKEN_HERE`
4. Body:
   - Select "form-data"
   - Add key: `file`, Type: File, Value: Select your image file
5. Click "Send"

**Expected Response:**
```json
{
  "message": "Company stamp uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/image/upload/v1234567890/internlink/1/123/stamps/stamp.png",
  "fileId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## 🧪 Testing with cURL

### Upload Verification Document
```bash
curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@/path/to/document.pdf" \
  -F "organizationType=UNIVERSITY" \
  -F "organizationId=1"
```

### Upload Weekly Presentation
```bash
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@/path/to/presentation.pdf" \
  -F "weeklyPlanId=1"
```

### Upload Company Stamp
```bash
curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -F "file=@/path/to/stamp.png"
```

### Upload Signed Report
```bash
curl -X POST http://localhost:5000/api/reports/upload-signed \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/signed-report.pdf" \
  -F "studentId=1"
```

### Generate Stamped Report
```bash
curl -X GET http://localhost:5000/api/reports/generate/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🧪 Testing with Frontend (React)

### Example: Upload Company Stamp

```typescript
const handleStampUpload = async (file: File) => {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const response = await fetch('http://localhost:5000/api/supervisors/upload-stamp', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: formData
    });

    const data = await response.json();
    
    if (response.ok) {
      console.log('Upload successful:', data.url);
      alert('Stamp uploaded successfully!');
    } else {
      console.error('Upload failed:', data.error);
      alert(`Upload failed: ${data.error}`);
    }
  } catch (error) {
    console.error('Upload error:', error);
    alert('Upload failed. Please try again.');
  }
};

// Usage in component
<input 
  type="file" 
  accept="image/png,image/jpeg,image/jpg"
  onChange={(e) => {
    if (e.target.files?.[0]) {
      handleStampUpload(e.target.files[0]);
    }
  }}
/>
```

---

## ✅ Validation Rules

### File Size
- Maximum: 10MB
- Exceeding this will return: `400 Bad Request - File size exceeds 10MB limit`

### File Types

| Feature | Allowed Types | MIME Types |
|---------|--------------|------------|
| Verification Docs | PDF | `application/pdf` |
| Weekly Presentations | PDF, PPT, PPTX | `application/pdf`, `application/vnd.ms-powerpoint`, `application/vnd.openxmlformats-officedocument.presentationml.presentation` |
| Company Stamps | PNG, JPG, JPEG | `image/png`, `image/jpeg`, `image/jpg` |
| Final Reports | PDF | `application/pdf` |

---

## 🔍 Checking Uploads

### 1. Check Database
```sql
-- View all uploaded files
SELECT * FROM files ORDER BY "createdAt" DESC;

-- View files by type
SELECT * FROM files WHERE type = 'COMPANY_STAMP';

-- View files by user
SELECT * FROM files WHERE "userId" = 1;
```

### 2. Check Cloudinary Dashboard
Visit: https://console.cloudinary.com/console/media_library

Navigate to the `internlink` folder to see your uploaded files.

### 3. Check File URLs
All uploaded files return a URL in the response. You can:
- Copy the URL and paste it in your browser to view the file
- Use the URL in your frontend to display images
- Use the URL for PDF downloads

---

## 🐛 Troubleshooting

### Error: "Invalid file type"
- Check that your file has the correct extension
- Verify the MIME type matches allowed types
- Try re-saving the file in the correct format

### Error: "File size exceeds 10MB limit"
- Compress your file
- For PDFs: Use a PDF compressor
- For images: Resize or compress the image

### Error: "Access denied"
- Verify you're using the correct authentication token
- Check that your user role matches the endpoint requirements
- Ensure you have permission to upload for the specified resource

### Error: "Upload failed"
- Check your Cloudinary credentials in `.env`
- Verify your Cloudinary account is active
- Check server logs for detailed error messages
- Ensure your Cloudinary storage quota hasn't been exceeded

### Error: "Weekly plan not found"
- Verify the `weeklyPlanId` exists in the database
- Check that the weekly plan belongs to the authenticated student

### Error: "Report is locked"
- The report has been sent to the university and cannot be modified
- Contact an administrator if you need to unlock the report

---

## 📊 File Storage Structure

Files are organized in Cloudinary with the following structure:

```
internlink/
├── {organizationId}/
│   ├── verification-docs/
│   │   └── document_abc123.pdf
│   └── {userId}/
│       ├── weekly-presentations/
│       │   ├── week1_def456.pdf
│       │   └── week2_ghi789.pptx
│       ├── stamps/
│       │   └── stamp_jkl012.png
│       └── final-reports/
│           ├── report_mno345.pdf
│           └── report_stamped_pqr678.pdf
```

---

## 🔐 Security Notes

1. **Never expose Cloudinary credentials to frontend**
   - All uploads go through backend API
   - Frontend only sends files to backend
   - Backend handles Cloudinary communication

2. **Authentication required**
   - All endpoints require valid JWT token
   - Token must match the user role for the endpoint

3. **Scope validation**
   - Students can only upload to their own resources
   - Supervisors can only upload for their company
   - Admins have full access

4. **File validation**
   - MIME type checked on backend
   - File size enforced
   - Malicious files rejected

---

## 📚 Additional Resources

- **API Reference:** `apps/backend/docs/FILE_UPLOAD_API_REFERENCE.md`
- **Implementation Summary:** `apps/backend/docs/FILE_UPLOAD_IMPLEMENTATION_SUMMARY.md`
- **System Architecture:** `apps/backend/docs/FILE_UPLOAD_SYSTEM.md`
- **Testing Guide:** `apps/backend/docs/FILE_UPLOAD_TESTING_GUIDE.md`
- **Complete Status:** `apps/backend/FILE_UPLOAD_COMPLETE.md`

---

## ✨ Next Steps

1. ✅ Verify Cloudinary credentials in `.env`
2. ✅ Start the backend server: `npm run dev`
3. ✅ Test endpoints using Postman or cURL
4. ✅ Integrate file upload UI in frontend
5. ✅ Test complete workflow end-to-end
6. ✅ Deploy to production

---

**Status:** ✅ Ready for Testing  
**Last Updated:** April 25, 2026
