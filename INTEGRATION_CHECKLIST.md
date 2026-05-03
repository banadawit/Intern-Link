# ✅ File Upload Integration Checklist

## Pre-Integration Verification

### Backend Verification
- [ ] Cloudinary credentials in `.env` are correct
- [ ] Backend server starts without errors (`npm run dev`)
- [ ] Database migrations are applied (`npx prisma migrate dev`)
- [ ] File model exists in database
- [ ] Test one endpoint with Postman/cURL

### Frontend Verification
- [ ] All components created without errors
- [ ] No TypeScript errors in components
- [ ] API utilities file created
- [ ] Frontend server starts without errors

---

## Integration Steps

### Step 1: Admin Dashboard

#### Files to Update
- [ ] `apps/frontend/src/app/(dashboard)/admin/universities/page.tsx`
- [ ] `apps/frontend/src/app/(dashboard)/admin/companies/page.tsx`

#### What to Add
```tsx
import VerificationDocumentUpload from '@/components/admin/VerificationDocumentUpload';

// In organization details modal/section
<VerificationDocumentUpload
  organizationType="UNIVERSITY" // or "COMPANY"
  organizationId={organization.id}
  currentDocUrl={organization.verification_doc}
  onUploadSuccess={(url) => {
    // Refresh organization data
    refreshOrganizations();
    // Show success message
    toast.success('Document uploaded successfully!');
  }}
/>
```

#### Testing
- [ ] Can select PDF file
- [ ] Upload button appears
- [ ] Upload succeeds
- [ ] Success message shows
- [ ] File appears in Cloudinary
- [ ] Database record created
- [ ] Can view uploaded file

---

### Step 2: Student Dashboard

#### Files to Update
- [ ] `apps/frontend/src/app/(dashboard)/student/weekly-plans/page.tsx`
- [ ] `apps/frontend/src/components/student/WeeklyPlanForm.tsx`

#### What to Add
```tsx
import WeeklyPresentationUpload from '@/components/student/WeeklyPresentationUpload';

// In weekly plan submission form
<WeeklyPresentationUpload
  weeklyPlanId={weeklyPlan.id}
  currentFileUrl={weeklyPlan.presentation?.file_url}
  onUploadSuccess={(url) => {
    // Refresh weekly plans
    refreshWeeklyPlans();
    // Show success message
    toast.success('Presentation uploaded successfully!');
  }}
/>
```

#### Testing
- [ ] Can select PDF/PPT/PPTX file
- [ ] Upload button appears
- [ ] Upload succeeds
- [ ] Success message shows
- [ ] File appears in Cloudinary
- [ ] Database record created
- [ ] Can re-upload (replacement works)
- [ ] Old file deleted on replacement

---

### Step 3: Supervisor Dashboard

#### Files to Update
- [ ] `apps/frontend/src/app/(dashboard)/supervisor/settings/page.tsx`
- [ ] `apps/frontend/src/app/(dashboard)/supervisor/profile/page.tsx`

#### What to Add
```tsx
import CompanyStampUpload from '@/components/supervisor/CompanyStampUpload';

// In company settings section
<CompanyStampUpload
  currentStampUrl={company.stamp_image_url}
  onUploadSuccess={(url) => {
    // Update company state
    setCompany({ ...company, stamp_image_url: url });
    // Show success message
    toast.success('Stamp uploaded successfully!');
  }}
/>
```

#### Testing
- [ ] Can select PNG/JPG file
- [ ] Image preview shows
- [ ] Upload button appears
- [ ] Upload succeeds
- [ ] Success message shows
- [ ] File appears in Cloudinary
- [ ] Database record created
- [ ] Can replace stamp
- [ ] Old stamp deleted on replacement

---

### Step 4: Final Reports

#### Files to Update
- [ ] `apps/frontend/src/app/(dashboard)/student/report/page.tsx`
- [ ] `apps/frontend/src/app/(dashboard)/supervisor/reports/[studentId]/page.tsx`

#### What to Add

**For Supervisors (with generate button):**
```tsx
import FinalReportUpload from '@/components/shared/FinalReportUpload';

<FinalReportUpload
  studentId={student.id}
  currentReportUrl={report?.pdf_url}
  isLocked={report?.locked}
  showGenerateButton={true}
  onUploadSuccess={(url) => {
    // Refresh report data
    refreshReport();
    // Show success message
    toast.success('Report updated successfully!');
  }}
/>
```

**For Students (upload only):**
```tsx
import FinalReportUpload from '@/components/shared/FinalReportUpload';

<FinalReportUpload
  studentId={currentUser.studentId}
  currentReportUrl={report?.pdf_url}
  isLocked={report?.locked}
  showGenerateButton={false}
  onUploadSuccess={(url) => {
    refreshReport();
    toast.success('Report uploaded successfully!');
  }}
/>
```

#### Testing
- [ ] Generate button works (supervisor)
- [ ] Report generates with stamp
- [ ] Can upload manual report
- [ ] Download button works
- [ ] Locked state prevents upload
- [ ] Success messages show
- [ ] File appears in Cloudinary
- [ ] Database record created

---

## Post-Integration Testing

### Functional Testing

#### Admin Tests
- [ ] Upload university verification doc
- [ ] Upload company verification doc
- [ ] View uploaded documents
- [ ] Replace documents
- [ ] Check audit logs

#### Student Tests
- [ ] Upload weekly presentation (PDF)
- [ ] Upload weekly presentation (PPT)
- [ ] Upload weekly presentation (PPTX)
- [ ] Re-upload presentation (replacement)
- [ ] View uploaded presentation
- [ ] Download presentation

#### Supervisor Tests
- [ ] Upload company stamp (PNG)
- [ ] Upload company stamp (JPG)
- [ ] View stamp preview
- [ ] Replace stamp
- [ ] Generate stamped report
- [ ] Verify stamp appears on report

#### Report Tests
- [ ] Generate report without stamp
- [ ] Generate report with stamp
- [ ] Upload manual report
- [ ] Download report
- [ ] Lock report
- [ ] Verify locked report cannot be modified

---

### Validation Testing

#### File Size Validation
- [ ] Upload file < 10MB (should succeed)
- [ ] Upload file > 10MB (should fail with error)
- [ ] Error message is clear

#### File Type Validation
- [ ] Upload correct file type (should succeed)
- [ ] Upload wrong file type (should fail with error)
- [ ] Error message is clear

#### Access Control
- [ ] Student can only upload to own weekly plans
- [ ] Supervisor can only upload to own company
- [ ] Admin can upload for any organization
- [ ] Unauthorized access is blocked

---

### UI/UX Testing

#### Desktop
- [ ] Components render correctly
- [ ] Buttons are clickable
- [ ] File selection works
- [ ] Upload progress shows
- [ ] Success/error messages display
- [ ] Current file displays
- [ ] Download works

#### Mobile
- [ ] Components are responsive
- [ ] Touch interactions work
- [ ] File selection works on mobile
- [ ] Upload works on mobile
- [ ] Messages are readable

#### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Focus indicators visible
- [ ] Error messages announced

---

### Performance Testing

- [ ] Upload completes in reasonable time
- [ ] No memory leaks
- [ ] Multiple uploads work
- [ ] Large files (near 10MB) upload successfully
- [ ] UI remains responsive during upload

---

### Error Handling Testing

- [ ] Network error handled gracefully
- [ ] Server error shows clear message
- [ ] Validation errors display correctly
- [ ] Can retry after error
- [ ] No console errors

---

## Cloudinary Verification

- [ ] Files appear in Cloudinary dashboard
- [ ] Folder structure is correct
- [ ] File names are unique
- [ ] Old files deleted on replacement
- [ ] CDN URLs work
- [ ] Files are accessible

---

## Database Verification

```sql
-- Check File records
SELECT * FROM files ORDER BY "createdAt" DESC LIMIT 10;

-- Check by type
SELECT * FROM files WHERE type = 'COMPANY_STAMP';

-- Check by user
SELECT * FROM files WHERE "userId" = 1;

-- Check organization files
SELECT * FROM files WHERE "organizationId" = 1;
```

- [ ] File records created
- [ ] Correct file type
- [ ] Correct user/organization ID
- [ ] URL is correct
- [ ] publicId is stored
- [ ] Timestamps are correct

---

## Security Verification

- [ ] JWT token required for all uploads
- [ ] Unauthorized requests blocked
- [ ] Users can only access own files
- [ ] File validation works
- [ ] No sensitive data in responses
- [ ] Cloudinary credentials not exposed

---

## Documentation Review

- [ ] Read `COMPLETE_FILE_UPLOAD_SYSTEM.md`
- [ ] Read `IMPLEMENTATION_SUMMARY.md`
- [ ] Read `QUICK_REFERENCE.md`
- [ ] Understand component props
- [ ] Understand API functions
- [ ] Know where to find help

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] No console errors
- [ ] No TypeScript errors
- [ ] Environment variables set
- [ ] Database migrations applied

### Production Environment
- [ ] Cloudinary credentials in production `.env`
- [ ] Database connection string correct
- [ ] JWT secret set
- [ ] CORS configured
- [ ] File size limits appropriate

### Post-Deployment
- [ ] Test file upload in production
- [ ] Verify Cloudinary storage
- [ ] Check database records
- [ ] Monitor error logs
- [ ] Test from different devices

---

## Troubleshooting

### Common Issues

**Issue:** Upload fails with "No file uploaded"
- [ ] Check file input name is "file"
- [ ] Check FormData is created correctly
- [ ] Check multer middleware is attached

**Issue:** "File size exceeds limit"
- [ ] Verify file is < 10MB
- [ ] Check client-side validation
- [ ] Check server-side validation

**Issue:** "Invalid file type"
- [ ] Check file extension
- [ ] Check MIME type
- [ ] Verify accept attribute

**Issue:** "Access denied"
- [ ] Check JWT token is valid
- [ ] Verify user role
- [ ] Check resource ownership

**Issue:** Files not appearing in Cloudinary
- [ ] Verify Cloudinary credentials
- [ ] Check Cloudinary dashboard
- [ ] Review server logs
- [ ] Check network requests

---

## Support Resources

### Documentation
- `COMPLETE_FILE_UPLOAD_SYSTEM.md` - Complete overview
- `IMPLEMENTATION_SUMMARY.md` - What was implemented
- `QUICK_REFERENCE.md` - Quick component reference
- `SYSTEM_ARCHITECTURE.md` - System architecture
- `apps/backend/FILE_UPLOAD_COMPLETE.md` - Backend details
- `apps/frontend/FILE_UPLOAD_FRONTEND_COMPLETE.md` - Frontend details

### Code Examples
- Component files have usage examples
- API utility functions have JSDoc comments
- Backend controllers have inline comments

### External Resources
- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Multer Documentation](https://github.com/expressjs/multer)
- [pdf-lib Documentation](https://pdf-lib.js.org/)

---

## Sign-Off

### Backend Integration
- [ ] All endpoints tested
- [ ] Database verified
- [ ] Cloudinary verified
- [ ] Security verified
- [ ] Signed off by: ________________

### Frontend Integration
- [ ] All components integrated
- [ ] UI/UX tested
- [ ] Responsive design verified
- [ ] Accessibility checked
- [ ] Signed off by: ________________

### Final Approval
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Ready for production
- [ ] Approved by: ________________
- [ ] Date: ________________

---

**Status:** Ready for Integration  
**Last Updated:** April 25, 2026
