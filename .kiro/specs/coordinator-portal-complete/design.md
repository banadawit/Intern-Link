# Design Document

## Feature: coordinator-portal-complete

---

## Overview

This document covers the technical design for the four missing Coordinator Portal features in InternLink:

1. **HOD Suspend/Activate** — two new PATCH endpoints + Flutter action buttons in the HOD list and detail screen.
2. **HOD Detail Screen** — a new GET endpoint + a new `HodDetailScreen` Flutter widget.
3. **Report Download** — expose `pdf_url` in the existing reports endpoint + `url_launcher` integration in the Flutter reports list.
4. **Placement Status Filter Tabs** — add Active / Completed / Terminated sub-tabs inside the existing `_CoordinatorPlacementsTab` Assignments view.

All backend changes are additive (new functions + new routes). All Flutter changes follow the existing patterns: `FutureProvider.family` for parameterised data, `ConsumerStatefulWidget` for screens with tabs, and the existing card/badge UI patterns from `_buildHodList`.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App (intern_mobile_app)                                │
│                                                                 │
│  coordinator_repository.dart                                    │
│    suspendHod(userId)  ──────────────────────────────────────┐  │
│    activateHod(userId) ──────────────────────────────────────┤  │
│    getHodDetail(userId) ─────────────────────────────────────┤  │
│                                                               │  │
│  Providers                                                    │  │
│    hodDetailProvider (FutureProvider.family<int>)             │  │
│                                                               │  │
│  dashboards.dart                                              │  │
│    _CoordinatorHodsTab  (adds Suspend/Activate buttons)       │  │
│    HodDetailScreen      (new ConsumerStatefulWidget)          │  │
│    _CoordinatorPlacementsTab (adds status filter sub-tabs)    │  │
│    _ReportsView         (adds url_launcher download button)   │  │
└───────────────────────────────────────────────────────────────┘
                              │ HTTP
┌─────────────────────────────▼───────────────────────────────────┐
│  Node.js / Express Backend (apps/backend)                       │
│                                                                 │
│  coordinatorController.ts                                       │
│    suspendHod   PATCH /coordinator/hods/:userId/suspend         │
│    activateHod  PATCH /coordinator/hods/:userId/activate        │
│    getHodDetail GET   /coordinator/hods/:userId                 │
│                                                                 │
│  coordinatorPortalController.ts                                 │
│    getReportsOverview  (already returns pdf_url via select *)   │
│                                                                 │
│  coordinatorRoutes.ts  (new route registrations)                │
└─────────────────────────────────────────────────────────────────┘
                              │ Prisma
┌─────────────────────────────▼───────────────────────────────────┐
│  PostgreSQL                                                     │
│    User.institution_access_approval  (ApprovalStatus enum)      │
│    HodProfile.phone_number, .department                         │
│    Student (count linked to HodProfile)                         │
│    InternshipAssignment.status  (AssignmentStatus enum)         │
│    Report.pdf_url                                               │
└─────────────────────────────────────────────────────────────────┘
```

No new database migrations are required. All fields used (`institution_access_approval`, `pdf_url`, `AssignmentStatus`) already exist in the schema.

---

## Components and Interfaces

### Backend — coordinatorController.ts

Three new exported async functions are added, following the existing `async (req: AuthRequest, res: Response)` pattern:

#### `suspendHod`
```
PATCH /coordinator/hods/:userId/suspend
Auth: COORDINATOR role required (via existing router middleware)

Steps:
1. Resolve coordinator's universityId via getCoordinatorUniversityId()
2. Fetch HodProfile where userId = :userId, include user
3. Validate: role == HOD, universityId matches, status != SUSPENDED
4. prisma.user.update({ institution_access_approval: 'SUSPENDED' })
5. Return 200 { userId, status: 'SUSPENDED' }

Error cases:
  403 — coordinator not linked to university, or HOD belongs to different university
  400 — target user is not HOD role
  404 — HodProfile not found
  409 — already SUSPENDED
```

#### `activateHod`
```
PATCH /coordinator/hods/:userId/activate
Auth: COORDINATOR role required

Steps:
1. Resolve coordinator's universityId
2. Fetch HodProfile where userId = :userId, include user
3. Validate: role == HOD, universityId matches, status != APPROVED
4. prisma.user.update({ institution_access_approval: 'APPROVED' })
5. Return 200 { userId, status: 'APPROVED' }

Error cases:
  403 — cross-university access
  400 — not HOD role
  404 — not found
  409 — already APPROVED
```

#### `getHodDetail`
```
GET /coordinator/hods/:userId
Auth: COORDINATOR role required

Steps:
1. Resolve coordinator's universityId
2. Fetch HodProfile where userId = :userId, include user + _count students
3. Validate: universityId matches
4. Return 200 {
     userId, fullName, email, department,
     phoneNumber, employeeId (from HodProfile.phone_number field — note: the
     existing createHod stores employeeId in phone_number column),
     approvalStatus, createdAt, studentCount
   }

Error cases:
  403 — cross-university access or coordinator not linked
  404 — HodProfile not found
```

### Backend — coordinatorRoutes.ts

Three new route registrations appended after the existing `router.post('/hods', createHod)` line:

```typescript
router.get('/hods/:userId', getHodDetail);
router.patch('/hods/:userId/suspend', suspendHod);
router.patch('/hods/:userId/activate', activateHod);
```

### Backend — coordinatorPortalController.ts (getReportsOverview)

The existing `getReportsOverview` already uses `prisma.report.findMany` with `include` — the `Report` model's `pdf_url` field is a non-optional `String` column, so it is already included in the response. No backend change is needed for Requirement 3 beyond confirming this.

### Flutter — coordinator_repository.dart

Three new repository methods and one new provider:

```dart
// Repository methods
Future<void> suspendHod(int userId) async {
  await apiClient.dio.patch('/coordinator/hods/$userId/suspend');
}

Future<void> activateHod(int userId) async {
  await apiClient.dio.patch('/coordinator/hods/$userId/activate');
}

Future<Map<String, dynamic>> getHodDetail(int userId) async {
  final res = await apiClient.dio.get('/coordinator/hods/$userId');
  return res.data as Map<String, dynamic>;
}

// Provider
final hodDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, userId) {
  return ref.watch(coordinatorRepositoryProvider).getHodDetail(userId);
});
```

### Flutter — dashboards.dart changes

#### 1. `_CoordinatorHodsTab` — Suspend/Activate buttons

The `_buildHodList` method is extended to accept an optional `onSuspend` / `onActivate` callback. For the Approved tab, each HOD card shows a "Suspend" button when `institution_access_approval == 'APPROVED'` and an "Activate" button when `institution_access_approval == 'SUSPENDED'`. The existing `_verify` method pattern is followed for the new `_suspend` and `_activate` methods.

HOD cards in all tabs become tappable (`GestureDetector` wrapping the card) to navigate to `HodDetailScreen`.

#### 2. `HodDetailScreen` — new `ConsumerStatefulWidget`

A new top-level widget class added inside `dashboards.dart`:

```
HodDetailScreen(userId: int)
  - Watches hodDetailProvider(userId)
  - Loading state: CircularProgressIndicator
  - Error state: error message + retry button (ref.invalidate(hodDetailProvider(userId)))
  - Data state: ModernSliverAppBar + detail cards
    - Name, email, department, phone, employeeId, createdAt, studentCount
    - Status badge (colour-coded by approvalStatus)
    - Action button row based on approvalStatus:
        APPROVED  → "Suspend Account" (red FilledButton)
        SUSPENDED → "Activate Account" (green FilledButton)
        PENDING   → "Approve" + "Reject" (existing _verify pattern)
    - On action success: Navigator.pop() + invalidate relevant providers
```

Navigation: HOD cards in `_buildHodList` wrap with `GestureDetector(onTap: () => Navigator.push(...HodDetailScreen(userId: userId)))`.

#### 3. `_CoordinatorPlacementsTab` — status filter sub-tabs

The existing "Active" tab in the Assignments sub-tab is replaced with a nested `TabController` of length 3 (Active, Completed, Terminated). The outer `_tabCtrl` (length 3: Active/Proposals/Analytics) is unchanged. A new inner `_assignmentTabCtrl` (length 3) is added.

The `_buildAssignmentsList` method already accepts a `statusFilter` string — it is called three times, once per status. The existing `SliverTabBarDelegate` pattern is reused for the inner tab bar.

Structure after change:
```
Placements tab (outer _tabCtrl, length 3)
  ├── Assignments (inner _assignmentTabCtrl, length 3)
  │     ├── Active    → _buildAssignmentsList(async, isDark, 'ACTIVE')
  │     ├── Completed → _buildAssignmentsList(async, isDark, 'COMPLETED')
  │     └── Terminated→ _buildAssignmentsList(async, isDark, 'TERMINATED')
  ├── Proposals
  └── Analytics
```

The `_buildAssignmentsList` empty-state message is updated to be status-aware:
- ACTIVE: "No active placements"
- COMPLETED: "No completed placements yet"
- TERMINATED: "No terminated placements"

#### 4. `_ReportsView` — download button

The existing report card `Row` gains a trailing `IconButton` after the stamped/pending badge:

```dart
IconButton(
  icon: Icon(
    Icons.download_rounded,
    color: pdfUrl != null && pdfUrl.isNotEmpty ? color : Colors.grey.shade300,
  ),
  onPressed: pdfUrl != null && pdfUrl.isNotEmpty
      ? () async {
          final uri = Uri.parse(pdfUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening report…')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open report. The file may not be available.')),
            );
          }
        }
      : null,  // null disables the button (greyed out automatically)
)
```

`url_launcher` is added to `pubspec.yaml` dependencies.

---

## Data Models

### HOD Detail Response (new)

```typescript
interface HodDetailResponse {
  userId: number;
  fullName: string;
  email: string;
  department: string;
  phoneNumber: string | null;   // HodProfile.phone_number
  employeeId: string | null;    // also stored in HodProfile.phone_number (existing createHod behaviour)
  approvalStatus: 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
  createdAt: string;            // ISO 8601
  studentCount: number;         // _count.students from Prisma
}
```

> Note: The existing `createHod` stores `employeeId` in the `phone_number` column of `HodProfile`. The detail endpoint exposes this as `phoneNumber`. A separate `employeeId` field is not present in the schema; the design reflects the actual data model.

### Suspend/Activate Response

```typescript
interface StatusUpdateResponse {
  userId: number;
  status: 'SUSPENDED' | 'APPROVED';
}
```

### Flutter `HodDetail` (Dart, informal)

```dart
// Accessed as Map<String, dynamic> — no separate model class needed,
// consistent with existing coordinator_repository.dart patterns.
{
  'userId': int,
  'fullName': String,
  'email': String,
  'department': String,
  'phoneNumber': String?,
  'approvalStatus': String,   // 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED'
  'createdAt': String,
  'studentCount': int,
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Suspend transitions status to SUSPENDED

*For any* HOD belonging to the coordinator's university whose current `institution_access_approval` is `APPROVED`, calling `PATCH /coordinator/hods/:userId/suspend` SHALL result in that HOD's `institution_access_approval` being `SUSPENDED`.

**Validates: Requirements 1.1**

---

### Property 2: Activate transitions status to APPROVED

*For any* HOD belonging to the coordinator's university whose current `institution_access_approval` is `SUSPENDED`, calling `PATCH /coordinator/hods/:userId/activate` SHALL result in that HOD's `institution_access_approval` being `APPROVED`.

**Validates: Requirements 1.2**

---

### Property 3: Suspend then activate is a round-trip

*For any* HOD with `APPROVED` status, suspending and then activating SHALL return the HOD's `institution_access_approval` to `APPROVED`, leaving the record in the same state as before the suspend.

**Validates: Requirements 1.1, 1.2**

---

### Property 4: Cross-university access is always denied

*For any* coordinator and *any* HOD whose `universityId` differs from the coordinator's `universityId`, both `suspend` and `activate` and `getHodDetail` SHALL return HTTP 403, regardless of the HOD's current status.

**Validates: Requirements 1.3, 2.2**

---

### Property 5: HOD detail response contains all required fields

*For any* HOD belonging to the coordinator's university, `GET /coordinator/hods/:userId` SHALL return a response object that contains all of: `userId`, `fullName`, `email`, `department`, `approvalStatus`, `createdAt`, and `studentCount`, with `studentCount` equal to the number of `Student` records whose `hodId` references that HOD's profile.

**Validates: Requirements 2.1**

---

### Property 6: Action button rendered matches HOD approval status

*For any* HOD detail data, the HOD Detail Screen SHALL render exactly one of the following action sets based on `approvalStatus`:
- `APPROVED` → "Suspend Account" button only
- `SUSPENDED` → "Activate Account" button only
- `PENDING` → "Approve" and "Reject" buttons

No other combination is valid.

**Validates: Requirements 2.8, 2.9, 2.10**

---

### Property 7: Report download icon state matches pdf_url presence

*For any* report record, the download icon button SHALL be in an enabled (tappable) state if and only if `pdf_url` is non-null and non-empty; otherwise it SHALL be in a disabled (greyed-out) state.

**Validates: Requirements 3.2, 3.5**

---

### Property 8: Assignment filter shows only matching status

*For any* list of `InternshipAssignment` records with mixed statuses, selecting a filter tab (Active, Completed, or Terminated) SHALL display only the assignments whose `status` field exactly matches the selected filter label, and SHALL display zero assignments from the other two statuses.

**Validates: Requirements 4.3, 4.4, 4.5**

---

### Property 9: Assignment status badge colour is consistent

*For any* assignment card rendered in the list, the status badge colour SHALL be:
- Green (`Colors.green`) when `status == 'ACTIVE'`
- Blue (`Colors.blue`) when `status == 'COMPLETED'`
- Red (`Colors.red`) when `status == 'TERMINATED'`

No other colour mapping is valid.

**Validates: Requirements 4.9**

---

## Error Handling

### Backend

| Scenario | HTTP Status | Response body |
|---|---|---|
| Coordinator not linked to university | 403 | `{ error: 'Your coordinator account is not linked to a university.' }` |
| HOD belongs to different university | 403 | `{ error: 'You can only manage HoDs from your own university.' }` |
| Target user is not HOD role | 400 | `{ error: 'Target user is not an HOD.' }` |
| HodProfile not found | 404 | `{ error: 'HoD profile not found.' }` |
| Already SUSPENDED (on suspend) | 409 | `{ error: 'This HOD account is already suspended.' }` |
| Already APPROVED (on activate) | 409 | `{ error: 'This HOD account is already active.' }` |
| Unexpected server error | 500 | `{ error: error.message }` |

All error responses follow the existing `res.status(N).json({ error: '...' })` pattern used throughout `coordinatorController.ts`.

### Flutter

- **Network errors** from `suspendHod` / `activateHod` / `getHodDetail`: caught in `try/catch`, displayed via `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')))` — consistent with the existing `_verify` error handler.
- **HOD Detail loading error**: full-screen error widget with a "Retry" button that calls `ref.invalidate(hodDetailProvider(userId))`.
- **Report URL launch failure**: `SnackBar` with `'Unable to open report. The file may not be available.'`
- **Report URL launch success**: `SnackBar` with `'Opening report…'`

---

## Testing Strategy

### Unit Tests

- `suspendHod` controller: verify status transition, 403 cross-university, 400 non-HOD, 409 already-suspended.
- `activateHod` controller: verify status transition, 403 cross-university, 400 non-HOD, 409 already-active.
- `getHodDetail` controller: verify response shape, 403 cross-university, 404 not-found.
- Flutter `_buildHodList` widget: verify Suspend button appears for APPROVED HODs, Activate for SUSPENDED HODs.
- Flutter `HodDetailScreen`: verify correct action buttons per `approvalStatus`.
- Flutter `_ReportsView`: verify download icon enabled/disabled based on `pdf_url`.
- Flutter `_CoordinatorPlacementsTab`: verify filter tabs render and filter correctly.

### Property-Based Tests

Property-based testing is applicable here because the core logic — status transitions, access control, filter correctness, and UI rendering rules — all involve universal properties that should hold across a wide range of inputs (different HOD users, different assignment lists, different report data).

**Library**: `fast_check` (TypeScript backend) and `glados` (Dart/Flutter).

Each property test runs a minimum of **100 iterations**.

Tag format: `// Feature: coordinator-portal-complete, Property N: <property_text>`

**Property 1 — Suspend transitions status to SUSPENDED**
Generate random HOD users with `APPROVED` status. Call `suspendHod`. Assert `institution_access_approval == 'SUSPENDED'`.

**Property 2 — Activate transitions status to APPROVED**
Generate random HOD users with `SUSPENDED` status. Call `activateHod`. Assert `institution_access_approval == 'APPROVED'`.

**Property 3 — Suspend then activate is a round-trip**
Generate random HOD users with `APPROVED` status. Call `suspendHod` then `activateHod`. Assert final status is `APPROVED`.

**Property 4 — Cross-university access is always denied**
Generate random (coordinator, HOD) pairs where `universityId` differs. Assert all three endpoints return 403.

**Property 5 — HOD detail response contains all required fields**
Generate random HOD profiles. Call `getHodDetail`. Assert all required keys are present and `studentCount` matches the actual student count.

**Property 6 — Action button rendered matches HOD approval status**
Generate random `approvalStatus` values. Render `HodDetailScreen` with mocked data. Assert the correct button set is shown.

**Property 7 — Report download icon state matches pdf_url presence**
Generate random report data with varying `pdf_url` values (null, empty string, valid URL). Render `_ReportsView`. Assert icon enabled/disabled state matches `pdf_url` presence.

**Property 8 — Assignment filter shows only matching status**
Generate random lists of assignments with mixed `AssignmentStatus` values. Select each filter tab. Assert only matching-status assignments are displayed.

**Property 9 — Assignment status badge colour is consistent**
Generate random `AssignmentStatus` values. Render assignment card. Assert badge colour matches the expected colour mapping.

### Integration Tests

- End-to-end: coordinator suspends HOD → HOD login returns 403 → coordinator activates HOD → HOD login succeeds.
- Report download: verify `pdf_url` is present in the reports overview response for reports that have a PDF.
- Assignments overview: verify records with all three `AssignmentStatus` values are returned by the existing endpoint.
