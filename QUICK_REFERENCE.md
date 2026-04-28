# 🚀 File Upload System - Quick Reference

## 📦 Components

### 1. Admin - Verification Documents
```tsx
import VerificationDocumentUpload from '@/components/admin/VerificationDocumentUpload';

<VerificationDocumentUpload
  organizationType="UNIVERSITY" // or "COMPANY"
  organizationId={org.id}
  currentDocUrl={org.verification_doc}
  onUploadSuccess={(url) => console.log(url)}
/>
```

### 2. Student - Weekly Presentations
```tsx
import WeeklyPresentationUpload from '@/components/student/WeeklyPresentationUpload';

<WeeklyPresentationUpload
  weeklyPlanId={plan.id}
  currentFileUrl={plan.presentation?.file_url}
  onUploadSuccess={(url) => refreshData()}
/>
```

### 3. Supervisor - Company Stamp
```tsx
import CompanyStampUpload from '@/components/supervisor/CompanyStampUpload';

<CompanyStampUpload
  currentStampUrl={company.stamp_image_url}
  onUploadSuccess={(url) => updateStamp(url)}
/>
```

### 4. Final Reports
```tsx
import FinalReportUpload from '@/components/shared/FinalReportUpload';

<FinalReportUpload
  studentId={student.id}
  currentReportUrl={report?.pdf_url}
  isLocked={report?.locked}
  showGenerateButton={true} // for supervisors
  onUploadSuccess={(url) => refreshReport()}
/>
```

---

## 🔧 API Functions

```typescript
import {
  uploadVerificationDocument,
  uploadWeeklyPresentation,
  uploadCompanyStamp,
  uploadSignedReport,
  generateStampedReport,
  downloadFile
} from '@/lib/api/fileUpload';

// Admin
await uploadVerificationDocument(file, 'UNIVERSITY', orgId);

// Student
await uploadWeeklyPresentation(file, weeklyPlanId);

// Supervisor
await uploadCompanyStamp(file);

// Reports
await uploadSignedReport(file, studentId);
await generateStampedReport(studentId);

// Download
downloadFile(url, 'filename.pdf');
```

---

## 🌐 API Endpoints

```bash
# Admin
POST /api/admin/upload-verification
Body: file, organizationType, organizationId

# Student
POST /api/students/upload-presentation
Body: file, weeklyPlanId

# Supervisor
POST /api/supervisors/upload-stamp
Body: file

# Reports
POST /api/reports/upload-signed
Body: file, studentId

GET /api/reports/generate/:studentId
```

---

## ✅ File Types & Sizes

| Feature | Types | Max Size |
|---------|-------|----------|
| Verification | PDF | 10MB |
| Presentations | PDF, PPT, PPTX | 10MB |
| Stamps | PNG, JPG, JPEG | 10MB |
| Reports | PDF | 10MB |

---

## 📁 Cloudinary Structure

```
internlink/
└── {orgId}/
    ├── verification-docs/
    └── {userId}/
        ├── weekly-presentations/
        ├── stamps/
        └── final-reports/
```

---

## 🔐 Authentication

All requests require JWT token:
```typescript
headers: {
  'Authorization': `Bearer ${localStorage.getItem('token')}`
}
```

---

## 📚 Documentation

- `COMPLETE_FILE_UPLOAD_SYSTEM.md` - Complete overview
- `IMPLEMENTATION_SUMMARY.md` - What was implemented
- `apps/backend/FILE_UPLOAD_COMPLETE.md` - Backend details
- `apps/frontend/FILE_UPLOAD_FRONTEND_COMPLETE.md` - Frontend details
- `apps/backend/QUICK_START_FILE_UPLOAD.md` - Backend quick start

---

## ✨ Status

✅ Backend: Complete  
✅ Frontend: Complete  
✅ Documentation: Complete  
⏳ Integration: Ready for pages  
⏳ Testing: Ready to test

---

**Last Updated:** April 25, 2026
