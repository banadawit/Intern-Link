# File Upload and Document Processing System

## Overview

This document describes the complete file upload and document processing system integrated into the InternLink workflow. The system uses Cloudinary for cloud storage and pdf-lib for PDF manipulation.

## Architecture

### Components

1. **CloudinaryService** (`src/services/cloudinary.service.ts`)
   - Handles all file uploads to Cloudinary
   - Manages file deletion and replacement
   - Validates file types and sizes

2. **PDFStampingService** (`src/services/pdfStamping.service.ts`)
   - Stamps PDFs with company logos
   - Downloads and processes PDF documents
   - Uploads stamped PDFs back to Cloudinary

3. **File Model** (Prisma)
   - Tracks all uploaded files in the database
   - Links files to users and organizations
   - Stores Cloudinary public_id for deletion

4. **Multer Configuration** (`src/config/multer.config.ts`)
   - Memory storage for Cloudinary uploads
   - File type validation
   - Size limits (10MB max)

## Integration Points

### 1. Super Admin / Organization Verification

**Endpoint:** `POST /api/admin/upload-verification`

**Purpose:** Upload verification documents (PDF) for universities/companies

**Storage Path:** `internlink/{organizationId}/verification-docs/`

**Request:**
```bash
curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer {token}" \
  -F "file=@document.pdf" \
  -F "organizationType=UNIVERSITY" \
  -F "organizationId=1"
```

**Response:**
```json
{
  "message": "Verification document uploaded successfully",
  "url": "https://res.cloudinary.com/...",
  "fileId": "uuid"
}
```

### 2. Student Dashboard - Weekly Presentations

**Endpoint:** `POST /api/students/upload-presentation`

**Purpose:** Upload weekly presentations (PDF/PPT) with re-submission support

**Storage Path:** `internlink/{universityId}/{userId}/weekly-presentations/`

**Features:**
- Allows re-submission (replaces old file)
- Automatically deletes previous version
- Links to WeeklyPlan record

**Request:**
```bash
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer {token}" \
  -F "file=@presentation.pptx" \
  -F "weeklyPlanId=5"
```

**Response:**
```json
{
  "message": "Weekly presentation uploaded successfully",
  "url": "https://res.cloudinary.com/...",
  "fileId": "uuid"
}
```

### 3. Supervisor Module - Company Stamp

**Endpoint:** `POST /api/supervisors/upload-stamp`

**Purpose:** Upload company stamp image (PNG/JPG) for report stamping

**Storage Path:** `internlink/{companyId}/{userId}/stamps/`

**Features:**
- Replaces existing stamp
- Used for PDF stamping
- Image optimization via Cloudinary

**Request:**
```bash
curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
  -H "Authorization: Bearer {token}" \
  -F "file=@company-stamp.png"
```

**Response:**
```json
{
  "message": "Company stamp uploaded successfully",
  "url": "https://res.cloudinary.com/...",
  "fileId": "uuid"
}
```

### 4. Final Report Submission

#### A. Generate Report with Stamp

**Endpoint:** `GET /api/reports/generate/:studentId`

**Purpose:** Generate PDF report and automatically apply company stamp

**Storage Path:** `internlink/{universityId}/{userId}/final-reports/`

**Process:**
1. Generate PDF using PDFKit
2. Upload to Cloudinary
3. If company has stamp, download PDF and stamp it
4. Upload stamped version
5. Delete unstamped version
6. Save URL in database

**Request:**
```bash
curl -X GET http://localhost:5000/api/reports/generate/123 \
  -H "Authorization: Bearer {token}"
```

**Response:**
```json
{
  "message": "PDF Generated Successfully",
  "reportUrl": "https://res.cloudinary.com/...",
  "stamped": true
}
```

#### B. Upload Signed Report

**Endpoint:** `POST /api/reports/upload-signed`

**Purpose:** Upload manually signed final report (PDF)

**Storage Path:** `internlink/{universityId}/{userId}/final-reports/`

**Request:**
```bash
curl -X POST http://localhost:5000/api/reports/upload-signed \
  -H "Authorization: Bearer {token}" \
  -F "file=@signed-report.pdf" \
  -F "studentId=123"
```

**Response:**
```json
{
  "message": "Final report uploaded successfully",
  "url": "https://res.cloudinary.com/...",
  "fileId": "uuid"
}
```

## File Validation

### Supported File Types

**Images:**
- `image/jpeg`
- `image/jpg`
- `image/png`

**Documents:**
- `application/pdf`
- `application/vnd.ms-powerpoint` (PPT)
- `application/vnd.openxmlformats-officedocument.presentationml.presentation` (PPTX)

### Size Limits

- Maximum file size: **10MB**
- Enforced at multer middleware level
- Additional validation in CloudinaryService

### Validation Flow

```typescript
// 1. Multer validates MIME type and size
uploadDocument.single('file')

// 2. CloudinaryService validates again
CloudinaryService.validateFile(file, allowedTypes)

// 3. Upload to Cloudinary
CloudinaryService.uploadDocument(file, options)
```

## Security

### Access Control

1. **Authentication Required:** All endpoints require valid JWT token
2. **Role-Based Authorization:** Each endpoint checks user role
3. **Ownership Verification:** Users can only upload to their own scope

### Examples

```typescript
// Student can only upload their own presentations
const student = await prisma.student.findUnique({
  where: { userId },
  include: { weeklyPlans: { where: { id: weeklyPlanId } } }
});

if (!student || student.weeklyPlans.length === 0) {
  return res.status(403).json({ error: 'Access denied' });
}
```

### Environment Variables

```env
# Never expose these to frontend
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## Database Schema

### File Model

```prisma
model File {
  id             String   @id @default(uuid())
  userId         Int?
  organizationId Int?
  type           FileType
  url            String
  publicId       String   // For Cloudinary deletion
  filename       String
  mimeType       String
  size           Int
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt

  @@index([userId, type])
  @@index([organizationId, type])
  @@map("files")
}

enum FileType {
  VERIFICATION_DOC
  WEEKLY_PRESENTATION
  COMPANY_STAMP
  FINAL_REPORT
  COMMON_FEED_IMAGE
  COMMON_FEED_DOCUMENT
}
```

## PDF Stamping Process

### Workflow

1. **Generate Base PDF**
   ```typescript
   const doc = new PDFDocument();
   // Add content...
   doc.end();
   ```

2. **Upload to Cloudinary**
   ```typescript
   const uploadResult = await CloudinaryService.uploadDocument(pdfFile, options);
   ```

3. **Apply Stamp (if available)**
   ```typescript
   const stampResult = await PDFStampingService.stampAndUploadPDF(
     pdfUrl,
     stampImageUrl,
     uploadOptions
   );
   ```

4. **Delete Unstamped Version**
   ```typescript
   await CloudinaryService.deleteFile(unstampedPublicId);
   ```

### Stamp Position

- **Location:** Bottom-right corner of last page
- **Default Size:** 150x100 pixels
- **Offset:** 50px from edges
- **Text:** "Company Verified" above stamp

### Customization

```typescript
const stampOptions: StampOptions = {
  stampImageUrl: 'https://...',
  position: { x: 400, y: 50 },
  size: { width: 150, height: 100 }
};
```

## File Replacement Logic

### When Re-uploading

1. **Check for existing file**
   ```typescript
   const existingFile = await prisma.file.findFirst({
     where: { url: existingUrl }
   });
   ```

2. **Replace if exists**
   ```typescript
   if (existingFile) {
     uploadResult = await CloudinaryService.replaceFile(
       existingFile.publicId,
       newFile,
       options
     );
   }
   ```

3. **Update database record**
   ```typescript
   await prisma.weeklyPresentation.update({
     where: { weeklyPlanId },
     data: { file_url: uploadResult.url, uploaded_at: new Date() }
   });
   ```

## Error Handling

### Common Errors

1. **File Too Large**
   ```json
   {
     "error": "File size exceeds 10MB limit"
   }
   ```

2. **Invalid File Type**
   ```json
   {
     "error": "Invalid file type. Allowed types: application/pdf, ..."
   }
   ```

3. **Upload Failed**
   ```json
   {
     "error": "Failed to upload document"
   }
   ```

4. **Access Denied**
   ```json
   {
     "error": "Access denied"
   }
   ```

### Error Response Format

```typescript
try {
  // Upload logic
} catch (error: any) {
  console.error('Upload error:', error);
  res.status(500).json({ error: error.message });
}
```

## Testing

### Manual Testing

1. **Test File Upload**
   ```bash
   # Upload verification document
   curl -X POST http://localhost:5000/api/admin/upload-verification \
     -H "Authorization: Bearer {token}" \
     -F "file=@test.pdf" \
     -F "organizationType=UNIVERSITY" \
     -F "organizationId=1"
   ```

2. **Test File Replacement**
   ```bash
   # Upload presentation twice
   curl -X POST http://localhost:5000/api/students/upload-presentation \
     -H "Authorization: Bearer {token}" \
     -F "file=@presentation1.pptx" \
     -F "weeklyPlanId=5"
   
   # Second upload should replace first
   curl -X POST http://localhost:5000/api/students/upload-presentation \
     -H "Authorization: Bearer {token}" \
     -F "file=@presentation2.pptx" \
     -F "weeklyPlanId=5"
   ```

3. **Test PDF Stamping**
   ```bash
   # First upload stamp
   curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
     -H "Authorization: Bearer {token}" \
     -F "file=@stamp.png"
   
   # Then generate report
   curl -X GET http://localhost:5000/api/reports/generate/123 \
     -H "Authorization: Bearer {token}"
   ```

## Monitoring

### Cloudinary Dashboard

- Monitor storage usage
- View upload statistics
- Check transformation usage
- Review bandwidth consumption

### Database Queries

```sql
-- Count files by type
SELECT type, COUNT(*) FROM files GROUP BY type;

-- Find large files
SELECT * FROM files WHERE size > 5000000 ORDER BY size DESC;

-- Recent uploads
SELECT * FROM files ORDER BY "createdAt" DESC LIMIT 10;
```

## Maintenance

### Cleanup Old Files

```typescript
// Delete files older than 90 days
const oldFiles = await prisma.file.findMany({
  where: {
    createdAt: { lt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) }
  }
});

for (const file of oldFiles) {
  await CloudinaryService.deleteFile(file.publicId);
}
```

### Orphaned Files

```typescript
// Find files not linked to any record
const orphanedFiles = await prisma.file.findMany({
  where: {
    AND: [
      { userId: null },
      { organizationId: null }
    ]
  }
});
```

## Best Practices

1. **Always validate files** before uploading
2. **Delete old files** when replacing
3. **Use appropriate file types** for each use case
4. **Monitor storage usage** regularly
5. **Implement retry logic** for failed uploads
6. **Log all upload operations** for audit trail
7. **Never expose Cloudinary credentials** to frontend
8. **Use signed URLs** for sensitive documents
9. **Implement rate limiting** on upload endpoints
10. **Compress images** before uploading when possible

## Troubleshooting

### Upload Fails

1. Check Cloudinary credentials
2. Verify file size and type
3. Check network connectivity
4. Review Cloudinary quota

### Stamp Not Applied

1. Verify stamp image exists
2. Check stamp image format (PNG/JPG only)
3. Review PDF generation logs
4. Ensure pdf-lib is installed

### File Not Deleted

1. Check publicId is correct
2. Verify Cloudinary permissions
3. Review deletion logs
4. Check if file exists in Cloudinary

## Future Enhancements

1. **Image Compression:** Automatic compression for large images
2. **Virus Scanning:** Integrate antivirus scanning
3. **Batch Uploads:** Support multiple file uploads
4. **Progress Tracking:** Real-time upload progress
5. **File Versioning:** Keep history of file changes
6. **CDN Integration:** Faster file delivery
7. **Thumbnail Generation:** Auto-generate thumbnails
8. **Watermarking:** Add watermarks to sensitive documents
