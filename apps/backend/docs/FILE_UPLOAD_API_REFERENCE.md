# File Upload API Reference

## Quick Reference

### Endpoints Summary

| Endpoint | Method | Role | Purpose |
|----------|--------|------|---------|
| `/api/admin/upload-verification` | POST | ADMIN | Upload verification documents |
| `/api/students/upload-presentation` | POST | STUDENT | Upload weekly presentations |
| `/api/supervisors/upload-stamp` | POST | SUPERVISOR | Upload company stamp |
| `/api/reports/upload-signed` | POST | STUDENT/SUPERVISOR/ADMIN | Upload signed final report |
| `/api/reports/generate/:studentId` | GET | ADMIN/COORDINATOR/SUPERVISOR | Generate stamped report |

---

## 1. Upload Verification Document

**Endpoint:** `POST /api/admin/upload-verification`

**Authorization:** Admin only

**Content-Type:** `multipart/form-data`

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | File | Yes | PDF document (max 10MB) |
| organizationType | String | Yes | "UNIVERSITY" or "COMPANY" |
| organizationId | Number | Yes | Organization ID |

**Example Request:**

```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('organizationType', 'UNIVERSITY');
formData.append('organizationId', '1');

fetch('/api/admin/upload-verification', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});
```

**Success Response (200):**

```json
{
  "message": "Verification document uploaded successfully",
  "url": "https://res.cloudinary.com/dhhlz8ruy/raw/upload/v1234567890/internlink/1/verification-docs/abc123.pdf",
  "fileId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Error Responses:**

- `400`: No file uploaded / Invalid parameters
- `403`: Unauthorized
- `500`: Upload failed

---

## 2. Upload Weekly Presentation

**Endpoint:** `POST /api/students/upload-presentation`

**Authorization:** Student only

**Content-Type:** `multipart/form-data`

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|------