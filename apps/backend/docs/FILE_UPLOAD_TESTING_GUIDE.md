# File Upload System - Testing Guide

## Quick Start

This guide provides step-by-step instructions for testing all file upload endpoints.

---

## Prerequisites

1. **Backend Running:**
   ```bash
   cd apps/backend
   npm run dev
   ```

2. **Database Seeded:**
   ```bash
   npm run seed
   ```

3. **Test Files Prepared:**
   - `test-verification.pdf` (< 10MB)
   - `test-presentation.pdf` or `test-presentation.ppt` (< 10MB)
   - `test-stamp.png` or `test-stamp.jpg` (< 10MB)
   - `test-report.pdf` (< 10MB)

4. **Authentication Tokens:**
   - Admin token
   - Student token
   - Supervisor token

---

## Test Scenarios

### 1. Admin: Upload Verification Document

#### Test Case 1.1: Successful Upload

**Request:**
```bash
curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@test-verification.pdf" \
  -F "organizationType=UNIVERSITY" \
  -F "organizationId=1"
```

**Expected Response (200):**
```json
{
  "message": "Verification document uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../document.pdf",
  "fileId": "uuid-here"
}
```

**Verification Steps:**
1. ✅ Check response contains valid Cloudinary URL
2. ✅ Visit URL to verify file is accessible
3. ✅ Check database: `SELECT * FROM files WHERE type = 'VERIFICATION_DOC'`
4. ✅ Check organization: `SELECT verification_doc FROM "University" WHERE id = 1`
5. ✅ Check audit log: `SELECT * FROM "AuditLog" WHERE action = 'UPLOADED_VERIFICATION_DOC'`

#### Test Case 1.2: Invalid File Type

**Request:**
```bash
curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@test-image.png" \
  -F "organizationType=UNIVERSITY" \
  -F "organizationId=1"
```

**Expected Response (400):**
```json
{
  "error": "Invalid file type. Only PDF files are allowed for verification."
}
```

#### Test Case 1.3: File Too Large

**Request:**
```bash
# Create a large file (> 10MB)
dd if=/dev/zero of=large-file.pdf bs=1M count=11

curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@large-file.pdf" \
  -F "organizationType=UNIVERSITY" \
  -F "organizationId=1"
```

**Expected Response (400):**
```json
{
  "error": "File size exceeds 10MB limit"
}
```

#### Test Case 1.4: Missing Parameters

**Request:**
```bash
curl -X POST http://localhost:5000/api/admin/upload-verification \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@test-verification.pdf"
```

**Expected Response (400):**
```json
{
  "error": "organizationType and organizationId are required"
}
```

---

### 2. Student: Upload Weekly Presentation

#### Test Case 2.1: Initial Upload

**Setup:**
1. Create a weekly plan for the student
2. Get the `weeklyPlanId`

**Request:**
```bash
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@test-presentation.pdf" \
  -F "weeklyPlanId=1"
```

**Expected Response (200):**
```json
{
  "message": "Weekly presentation uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../presentation.pdf",
  "fileId": "uuid-here"
}
```

**Verification Steps:**
1. ✅ Check response contains valid URL
2. ✅ Check database: `SELECT * FROM "WeeklyPresentation" WHERE "weeklyPlanId" = 1`
3. ✅ Check file record: `SELECT * FROM files WHERE type = 'WEEKLY_PRESENTATION'`

#### Test Case 2.2: Re-upload (Replace)

**Request:**
```bash
# Upload a different file to the same weekly plan
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@test-presentation-v2.pdf" \
  -F "weeklyPlanId=1"
```

**Expected Response (200):**
```json
{
  "message": "Weekly presentation replaced successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../presentation-v2.pdf",
  "fileId": "new-uuid-here"
}
```

**Verification Steps:**
1. ✅ Check new URL is different from first upload
2. ✅ Check database: Only one record exists for `weeklyPlanId = 1`
3. ✅ Verify old file is deleted from Cloudinary (visit old URL → 404)
4. ✅ Verify new file is accessible

#### Test Case 2.3: Access Control (Wrong Student)

**Request:**
```bash
# Use a different student's token with another student's weekly plan
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer DIFFERENT_STUDENT_TOKEN" \
  -F "file=@test-presentation.pdf" \
  -F "weeklyPlanId=1"
```

**Expected Response (403):**
```json
{
  "error": "Weekly plan not found or access denied"
}
```

#### Test Case 2.4: Invalid File Type

**Request:**
```bash
curl -X POST http://localhost:5000/api/students/upload-presentation \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@test-image.png" \
  -F "weeklyPlanId=1"
```

**Expected Response (400):**
```json
{
  "error": "Invalid file type. Only PDF and PPT files are allowed."
}
```

---

### 3. Supervisor: Upload Company Stamp

#### Test Case 3.1: Initial Upload

**Request:**
```bash
curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -F "file=@test-stamp.png"
```

**Expected Response (200):**
```json
{
  "message": "Company stamp uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/image/upload/v.../stamp.png",
  "fileId": "uuid-here"
}
```

**Verification Steps:**
1. ✅ Check response contains valid URL
2. ✅ Visit URL to verify image is accessible
3. ✅ Check database: `SELECT stamp_image_url FROM "Company" WHERE id = <companyId>`
4. ✅ Check file record: `SELECT * FROM files WHERE type = 'COMPANY_STAMP'`

#### Test Case 3.2: Replace Stamp

**Request:**
```bash
curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -F "file=@test-stamp-v2.png"
```

**Expected Response (200):**
```json
{
  "message": "Company stamp replaced successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/image/upload/v.../stamp-v2.png",
  "fileId": "new-uuid-here"
}
```

**Verification Steps:**
1. ✅ Check new URL is different
2. ✅ Verify old stamp is deleted from Cloudinary
3. ✅ Check company record updated with new URL

#### Test Case 3.3: Invalid File Type

**Request:**
```bash
curl -X POST http://localhost:5000/api/supervisors/upload-stamp \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -F "file=@test-document.pdf"
```

**Expected Response (400):**
```json
{
  "error": "Invalid file type. Only JPG and PNG images are allowed."
}
```

---

### 4. Final Report: Generate with Stamp

#### Test Case 4.1: Generate Report (With Stamp)

**Prerequisites:**
1. Student has completed internship
2. Supervisor has submitted final evaluation
3. Company has uploaded stamp

**Request:**
```bash
curl -X GET http://localhost:5000/api/reports/generate/1 \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN"
```

**Expected Response (200):**
```json
{
  "message": "PDF Generated Successfully",
  "reportUrl": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../report-stamped.pdf",
  "stamped": true
}
```

**Verification Steps:**
1. ✅ Download PDF from URL
2. ✅ Open PDF and verify content
3. ✅ Check last page has company stamp
4. ✅ Verify "Company Verified" text appears
5. ✅ Check database: `SELECT * FROM "Report" WHERE "studentId" = 1`
6. ✅ Verify `stamped = true` in database

#### Test Case 4.2: Generate Report (Without Stamp)

**Prerequisites:**
1. Company has NOT uploaded stamp

**Request:**
```bash
curl -X GET http://localhost:5000/api/reports/generate/2 \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN"
```

**Expected Response (200):**
```json
{
  "message": "PDF Generated Successfully",
  "reportUrl": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../report.pdf",
  "stamped": false
}
```

**Verification Steps:**
1. ✅ Download PDF
2. ✅ Verify no stamp on last page
3. ✅ Check database: `stamped = false`

---

### 5. Final Report: Upload Signed Report

#### Test Case 5.1: Upload Signed Report

**Request:**
```bash
curl -X POST http://localhost:5000/api/reports/upload-signed \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@signed-report.pdf" \
  -F "studentId=1"
```

**Expected Response (200):**
```json
{
  "message": "Final report uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../signed-report.pdf",
  "fileId": "uuid-here"
}
```

**Verification Steps:**
1. ✅ Check response contains valid URL
2. ✅ Download and verify PDF
3. ✅ Check database: `SELECT * FROM "Report" WHERE "studentId" = 1`

#### Test Case 5.2: Replace Existing Report

**Request:**
```bash
curl -X POST http://localhost:5000/api/reports/upload-signed \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@signed-report-v2.pdf" \
  -F "studentId=1"
```

**Expected Response (200):**
```json
{
  "message": "Final report replaced successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v.../signed-report-v2.pdf",
  "fileId": "new-uuid-here"
}
```

**Verification Steps:**
1. ✅ Verify old file deleted
2. ✅ Verify new file accessible
3. ✅ Check database updated

#### Test Case 5.3: Upload to Locked Report

**Setup:**
1. Send report to university first

**Request:**
```bash
# First, lock the report
curl -X POST http://localhost:5000/api/reports/send-to-university \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"studentId": 1}'

# Then try to upload
curl -X POST http://localhost:5000/api/reports/upload-signed \
  -H "Authorization: Bearer YOUR_STUDENT_TOKEN" \
  -F "file=@signed-report.pdf" \
  -F "studentId=1"
```

**Expected Response (400):**
```json
{
  "error": "This report has been sent to the university and is locked."
}
```

---

### 6. Send Report to University

#### Test Case 6.1: Successful Send

**Request:**
```bash
curl -X POST http://localhost:5000/api/reports/send-to-university \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"studentId": 1}'
```

**Expected Response (200):**
```json
{
  "message": "Report sent to the university. Coordinators have been notified."
}
```

**Verification Steps:**
1. ✅ Check database: `SELECT locked, sent_at FROM "Report" WHERE "studentId" = 1`
2. ✅ Verify `locked = true`
3. ✅ Verify `sent_at` is set
4. ✅ Check notifications: `SELECT * FROM "Notification" WHERE message LIKE '%final internship report%'`

#### Test Case 6.2: Already Sent

**Request:**
```bash
# Try to send again
curl -X POST http://localhost:5000/api/reports/send-to-university \
  -H "Authorization: Bearer YOUR_SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"studentId": 1}'
```

**Expected Response (400):**
```json
{
  "message": "Report has already been sent to the university."
}
```

---

## Automated Testing Script

Create a test script `test-file-uploads.sh`:

```bash
#!/bin/bash

# Configuration
BASE_URL="http://localhost:5000/api"
ADMIN_TOKEN="your_admin_token"
STUDENT_TOKEN="your_student_token"
SUPERVISOR_TOKEN="your_supervisor_token"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Test function
test_endpoint() {
  local name=$1
  local method=$2
  local endpoint=$3
  local token=$4
  local data=$5
  local expected_status=$6

  echo "Testing: $name"
  
  response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" \
    -H "Authorization: Bearer $token" \
    $data)
  
  status=$(echo "$response" | tail -n1)
  body=$(echo "$response" | head -n-1)
  
  if [ "$status" -eq "$expected_status" ]; then
    echo -e "${GREEN}✓ PASSED${NC} (Status: $status)"
    ((PASSED++))
  else
    echo -e "${RED}✗ FAILED${NC} (Expected: $expected_status, Got: $status)"
    echo "Response: $body"
    ((FAILED++))
  fi
  echo ""
}

# Run tests
echo "Starting File Upload Tests..."
echo "=============================="
echo ""

# Test 1: Admin upload verification
test_endpoint \
  "Admin: Upload Verification Document" \
  "POST" \
  "/admin/upload-verification" \
  "$ADMIN_TOKEN" \
  "-F 'file=@test-verification.pdf' -F 'organizationType=UNIVERSITY' -F 'organizationId=1'" \
  200

# Test 2: Student upload presentation
test_endpoint \
  "Student: Upload Weekly Presentation" \
  "POST" \
  "/students/upload-presentation" \
  "$STUDENT_TOKEN" \
  "-F 'file=@test-presentation.pdf' -F 'weeklyPlanId=1'" \
  200

# Test 3: Supervisor upload stamp
test_endpoint \
  "Supervisor: Upload Company Stamp" \
  "POST" \
  "/supervisors/upload-stamp" \
  "$SUPERVISOR_TOKEN" \
  "-F 'file=@test-stamp.png'" \
  200

# Test 4: Generate report
test_endpoint \
  "Generate Final Report" \
  "GET" \
  "/reports/generate/1" \
  "$SUPERVISOR_TOKEN" \
  "" \
  200

# Summary
echo "=============================="
echo "Test Summary:"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "=============================="
```

**Usage:**
```bash
chmod +x test-file-uploads.sh
./test-file-uploads.sh
```

---

## Manual Testing Checklist

### Pre-Testing Setup
- [ ] Backend server running
- [ ] Database seeded with test data
- [ ] Test files prepared
- [ ] Authentication tokens obtained
- [ ] Cloudinary credentials configured

### Admin Tests
- [ ] Upload verification document (success)
- [ ] Upload with invalid file type (error)
- [ ] Upload with oversized file (error)
- [ ] Upload without parameters (error)
- [ ] Verify file in Cloudinary
- [ ] Verify database record
- [ ] Verify audit log

### Student Tests
- [ ] Upload initial presentation (success)
- [ ] Re-upload presentation (replace)
- [ ] Verify old file deleted
- [ ] Test access control (wrong student)
- [ ] Upload invalid file type (error)
- [ ] Upload without weekly plan ID (error)

### Supervisor Tests
- [ ] Upload initial stamp (success)
- [ ] Replace stamp
- [ ] Verify old stamp deleted
- [ ] Upload invalid file type (error)
- [ ] Test access control

### Report Tests
- [ ] Generate report with stamp
- [ ] Generate report without stamp
- [ ] Upload signed report
- [ ] Replace signed report
- [ ] Test locked report (cannot modify)
- [ ] Send report to university
- [ ] Verify notifications sent

### Integration Tests
- [ ] Complete workflow: stamp → generate → send
- [ ] File replacement workflow
- [ ] Access control across all endpoints
- [ ] Error handling and recovery

---

## Troubleshooting

### Issue: "Upload failed"

**Possible Causes:**
1. Cloudinary credentials incorrect
2. Network connectivity issues
3. File size too large
4. Invalid file type

**Solution:**
1. Check `.env` file for correct credentials
2. Test Cloudinary connection
3. Verify file size < 10MB
4. Check file MIME type

### Issue: "Access denied"

**Possible Causes:**
1. Invalid or expired token
2. Wrong role for endpoint
3. User doesn't own the resource

**Solution:**
1. Refresh authentication token
2. Verify user role matches endpoint requirements
3. Check resource ownership

### Issue: "File not found in Cloudinary"

**Possible Causes:**
1. File was deleted
2. Wrong public_id
3. Cloudinary account issue

**Solution:**
1. Check Cloudinary dashboard
2. Verify public_id in database
3. Check Cloudinary account status

---

## Performance Testing

### Load Testing with Apache Bench

```bash
# Test concurrent uploads
ab -n 100 -c 10 -p test-file.pdf -T multipart/form-data \
  -H "Authorization: Bearer TOKEN" \
  http://localhost:5000/api/students/upload-presentation
```

### Expected Performance
- Upload time: < 2 seconds for 5MB file
- Concurrent uploads: 10+ simultaneous
- Success rate: > 99%

---

## Security Testing

### Test Cases
1. [ ] Upload without authentication (401)
2. [ ] Upload with wrong role (403)
3. [ ] Upload malicious file (rejected)
4. [ ] SQL injection in parameters (sanitized)
5. [ ] XSS in filename (sanitized)
6. [ ] Path traversal in filename (blocked)

---

## Monitoring

### Logs to Check
```bash
# Backend logs
tail -f apps/backend/logs/app.log

# Cloudinary uploads
grep "Cloudinary upload" apps/backend/logs/app.log

# Errors
grep "ERROR" apps/backend/logs/app.log
```

### Database Queries
```sql
-- Check recent uploads
SELECT * FROM files ORDER BY "createdAt" DESC LIMIT 10;

-- Check file types
SELECT type, COUNT(*) FROM files GROUP BY type;

-- Check file sizes
SELECT AVG(size), MAX(size), MIN(size) FROM files;
```

---

## Success Criteria

All tests should pass with:
- ✅ Correct HTTP status codes
- ✅ Valid response bodies
- ✅ Files uploaded to Cloudinary
- ✅ Database records created
- ✅ Old files deleted on replacement
- ✅ Access control enforced
- ✅ Error handling working

---

**Last Updated:** April 25, 2026
