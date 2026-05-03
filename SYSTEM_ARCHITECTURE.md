# 🏗️ File Upload System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐ │
│  │ Admin Components │  │Student Components│  │Supervisor Comp│ │
│  │                  │  │                  │  │               │ │
│  │ • Verification   │  │ • Weekly         │  │ • Company     │ │
│  │   Document       │  │   Presentation   │  │   Stamp       │ │
│  │   Upload         │  │   Upload         │  │   Upload      │ │
│  └────────┬─────────┘  └────────┬─────────┘  └───────┬───────┘ │
│           │                     │                     │         │
│           └─────────────────────┼─────────────────────┘         │
│                                 │                               │
│                    ┌────────────▼────────────┐                  │
│                    │   FileUpload Component  │                  │
│                    │   (Base Component)      │                  │
│                    └────────────┬────────────┘                  │
│                                 │                               │
│                    ┌────────────▼────────────┐                  │
│                    │   API Utilities         │                  │
│                    │   (fileUpload.ts)       │                  │
│                    └────────────┬────────────┘                  │
└─────────────────────────────────┼─────────────────────────────┘
                                  │
                                  │ HTTP/FormData
                                  │ JWT Token
                                  │
┌─────────────────────────────────▼─────────────────────────────┐
│                         BACKEND                                │
├───────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │                    Express Routes                         │ │
│  │  • /api/admin/upload-verification                        │ │
│  │  • /api/students/upload-presentation                     │ │
│  │  • /api/supervisors/upload-stamp                         │ │
│  │  • /api/reports/upload-signed                            │ │
│  │  • /api/reports/generate/:studentId                      │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│  ┌────────────────────────▼─────────────────────────────────┐ │
│  │              Multer Middleware                            │ │
│  │  • Memory Storage                                         │ │
│  │  • File Type Filtering                                    │ │
│  │  • Size Validation (10MB)                                 │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│  ┌────────────────────────▼─────────────────────────────────┐ │
│  │                   Controllers                             │ │
│  │  • adminController.uploadVerificationDocument()          │ │
│  │  • studentController.uploadWeeklyPresentation()          │ │
│  │  • supervisorController.uploadCompanyStamp()             │ │
│  │  • reportController.uploadSignedReport()                 │ │
│  │  • reportController.generateStudentReport()              │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│  ┌────────────────────────▼─────────────────────────────────┐ │
│  │                CloudinaryService                          │ │
│  │  • uploadImage()                                          │ │
│  │  • uploadDocument()                                       │ │
│  │  • deleteFile()                                           │ │
│  │  • replaceFile()                                          │ │
│  │  • downloadFile()                                         │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                            │                                   │
│                            ├──────────────────┐                │
│                            │                  │                │
│  ┌────────────────────────▼────────┐  ┌──────▼──────────────┐ │
│  │    PDFStampingService           │  │   Prisma ORM        │ │
│  │  • stampPDF()                   │  │  • File Model       │ │
│  │  • stampAndUploadPDF()          │  │  • Database Ops     │ │
│  └─────────────────────────────────┘  └─────────────────────┘ │
└───────────────────────────┬───────────────────┬───────────────┘
                            │                   │
                            │                   │
┌───────────────────────────▼─────┐  ┌──────────▼──────────────┐
│         Cloudinary              │  │    PostgreSQL           │
│  • Image Storage                │  │  • File Records         │
│  • Document Storage             │  │  • Metadata             │
│  • CDN Delivery                 │  │  • Relationships        │
│  • Transformation               │  │                         │
└─────────────────────────────────┘  └─────────────────────────┘
```

---

## Data Flow

### Upload Flow

```
1. User selects file
   ↓
2. Frontend validates (size, type)
   ↓
3. FormData created with file + metadata
   ↓
4. API call with JWT token
   ↓
5. Backend receives request
   ↓
6. Multer processes file to memory
   ↓
7. Controller validates access
   ↓
8. CloudinaryService uploads to Cloudinary
   ↓
9. File record saved to database
   ↓
10. URL returned to frontend
   ↓
11. Success message displayed
```

### PDF Stamping Flow

```
1. Generate report request
   ↓
2. Controller creates PDF with PDFKit
   ↓
3. Upload unstamped PDF to Cloudinary
   ↓
4. Check if company has stamp
   ↓
5. If yes: Download stamp image
   ↓
6. PDFStampingService applies stamp
   ↓
7. Upload stamped PDF to Cloudinary
   ↓
8. Delete unstamped version
   ↓
9. Save final URL to database
   ↓
10. Return stamped PDF URL
```

### File Replacement Flow

```
1. User uploads new file
   ↓
2. Check for existing file
   ↓
3. Upload new file to Cloudinary
   ↓
4. If successful: Delete old file
   ↓
5. Update database record
   ↓
6. Return new URL
```

---

## Component Hierarchy

```
FileUpload (Base)
├── VerificationDocumentUpload
│   └── Used by: Admin Dashboard
│
├── WeeklyPresentationUpload
│   └── Used by: Student Dashboard
│
├── CompanyStampUpload
│   └── Used by: Supervisor Settings
│
└── FinalReportUpload
    ├── Used by: Student Report Page
    └── Used by: Supervisor Report Management
```

---

## Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 1: Frontend Validation           │
│  • File size check                      │
│  • File type check                      │
│  • User feedback                        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Layer 2: Authentication                │
│  • JWT token required                   │
│  • Token validation                     │
│  • User identification                  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Layer 3: Authorization                 │
│  • Role-based access control            │
│  • Resource ownership check             │
│  • Scope validation                     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Layer 4: File Validation               │
│  • MIME type validation                 │
│  • File size validation                 │
│  • Extension check                      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  Layer 5: Upload & Storage              │
│  • Cloudinary upload                    │
│  • Database record                      │
│  • Audit logging                        │
└─────────────────────────────────────────┘
```

---

## Database Schema

```
┌─────────────────────────────────────────┐
│              File                        │
├─────────────────────────────────────────┤
│ id: String (UUID)                       │
│ userId: Int?                            │
│ organizationId: Int?                    │
│ type: FileType                          │
│ url: String                             │
│ publicId: String                        │
│ filename: String                        │
│ mimeType: String                        │
│ size: Int                               │
│ createdAt: DateTime                     │
│ updatedAt: DateTime                     │
└─────────────────────────────────────────┘
         │
         │ type
         ▼
┌─────────────────────────────────────────┐
│           FileType (Enum)                │
├─────────────────────────────────────────┤
│ • VERIFICATION_DOC                      │
│ • WEEKLY_PRESENTATION                   │
│ • COMPANY_STAMP                         │
│ • FINAL_REPORT                          │
│ • COMMON_FEED_IMAGE                     │
│ • COMMON_FEED_DOCUMENT                  │
└─────────────────────────────────────────┘
```

---

## File Organization

```
Cloudinary: internlink/
│
├── {organizationId}/
│   │
│   ├── verification-docs/
│   │   └── document_{timestamp}.pdf
│   │
│   └── {userId}/
│       │
│       ├── weekly-presentations/
│       │   ├── week1_{timestamp}.pdf
│       │   ├── week2_{timestamp}.pptx
│       │   └── week3_{timestamp}.pdf
│       │
│       ├── stamps/
│       │   └── stamp_{timestamp}.png
│       │
│       └── final-reports/
│           ├── report_{timestamp}.pdf
│           └── report_stamped_{timestamp}.pdf
```

---

## Technology Stack

### Frontend
- **React** - UI framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Lucide Icons** - Icons

### Backend
- **Node.js** - Runtime
- **Express** - Web framework
- **TypeScript** - Type safety
- **Multer** - File upload middleware
- **Cloudinary SDK** - Cloud storage
- **pdf-lib** - PDF manipulation
- **PDFKit** - PDF generation
- **Prisma** - ORM

### Storage
- **Cloudinary** - File storage & CDN
- **PostgreSQL** - Database

---

## API Response Format

### Success Response
```json
{
  "success": true,
  "url": "https://res.cloudinary.com/.../file.pdf",
  "fileId": "uuid-here",
  "message": "File uploaded successfully"
}
```

### Error Response
```json
{
  "success": false,
  "error": "File size exceeds 10MB limit"
}
```

---

## Performance Considerations

1. **Memory Storage**
   - Files stored in memory (not disk)
   - Fast upload processing
   - No cleanup needed

2. **CDN Delivery**
   - Cloudinary CDN for fast delivery
   - Automatic optimization
   - Global distribution

3. **Async Operations**
   - Non-blocking file uploads
   - Background processing
   - Promise-based API

4. **File Replacement**
   - Upload first, delete old
   - No data loss
   - Atomic operations

---

## Monitoring & Logging

### Backend Logging
- Upload attempts
- Success/failure
- Error messages
- User actions

### Audit Trail
- Admin actions logged
- Organization changes tracked
- File operations recorded

### Cloudinary Metrics
- Storage usage
- Bandwidth usage
- Transformation usage
- API calls

---

## Scalability

### Horizontal Scaling
- Stateless backend
- No local file storage
- Load balancer ready

### Vertical Scaling
- Memory-efficient
- Streaming uploads
- Optimized queries

### Storage Scaling
- Cloudinary handles scaling
- CDN distribution
- Automatic optimization

---

**Last Updated:** April 25, 2026  
**Status:** ✅ Production Ready
