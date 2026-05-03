# Requirements Document

## Introduction

This document covers the four missing features needed to complete the Coordinator Portal in the InternLink Flutter mobile app. The existing portal already handles dashboard stats, HOD approval/rejection/creation, student overview, company directory, active placements, proposals, reports listing, chat, notifications, and AI assistant. The gaps are:

1. **HOD Suspend/Activate** — coordinators cannot currently suspend an approved HOD or reactivate a suspended one.
2. **HOD Detail Screen** — no screen exists to view a single HOD's profile, department, student count, or account status.
3. **Report Download** — the reports list shows PDF metadata but provides no way to open or download the actual PDF file.
4. **Placement Status Filter Tabs** — the Assignments tab only shows ACTIVE records; COMPLETED and TERMINATED assignments are invisible.

All changes span the Node.js/Express backend (new or modified endpoints) and the Flutter frontend (Riverpod providers + UI widgets following existing patterns: `FutureProvider`, `ConsumerWidget`, `ModernSliverAppBar`, `SliverTabBarDelegate`).

---

## Glossary

- **Coordinator**: A university staff member with the `COORDINATOR` role who manages HODs and monitors internship activity for their university.
- **HOD**: Head of Department — a university staff member with the `HOD` role, linked to a `HodProfile` record and a specific department.
- **HOD_Manager**: The backend subsystem (routes + controller) that handles HOD lifecycle operations for coordinators.
- **Portal_API**: The backend subsystem at `/coordinator-portal/*` that serves read-only overview data to the coordinator dashboard.
- **Assignment_Service**: The backend logic that queries `InternshipAssignment` records filtered by university.
- **Report_Service**: The backend logic that queries `Report` records and exposes PDF download URLs.
- **Flutter_UI**: The Flutter mobile application's coordinator dashboard screens.
- **ApprovalStatus**: The Prisma enum `{ PENDING, APPROVED, REJECTED, SUSPENDED }` stored on `User.institution_access_approval`.
- **AssignmentStatus**: The Prisma enum `{ ACTIVE, COMPLETED, TERMINATED }` stored on `InternshipAssignment.status`.
- **pdf_url**: The `Report.pdf_url` field — a Cloudinary or storage URL pointing to the student's final report PDF.

---

## Requirements

### Requirement 1: HOD Suspend and Activate

**User Story:** As a Coordinator, I want to suspend an approved HOD account and later reactivate it, so that I can temporarily revoke access without permanently rejecting the HOD.

#### Acceptance Criteria

1. WHEN a Coordinator sends a PATCH request to `/coordinator/hods/:userId/suspend`, THE HOD_Manager SHALL set `User.institution_access_approval` to `SUSPENDED` for the target HOD.

2. WHEN a Coordinator sends a PATCH request to `/coordinator/hods/:userId/activate`, THE HOD_Manager SHALL set `User.institution_access_approval` to `APPROVED` for the target HOD.

3. IF the target HOD does not belong to the Coordinator's university, THEN THE HOD_Manager SHALL return HTTP 403 with an error message.

4. IF the target user does not have the `HOD` role, THEN THE HOD_Manager SHALL return HTTP 400 with an error message.

5. IF the target HOD's current status is already `SUSPENDED` and a suspend request is received, THEN THE HOD_Manager SHALL return HTTP 409 indicating the account is already suspended.

6. IF the target HOD's current status is already `APPROVED` and an activate request is received, THEN THE HOD_Manager SHALL return HTTP 409 indicating the account is already active.

7. WHEN a suspend or activate operation succeeds, THE HOD_Manager SHALL return HTTP 200 with the updated `userId` and new `status`.

8. WHEN the Flutter_UI renders the Approved HODs list, THE Flutter_UI SHALL display a "Suspend" action for each HOD whose `institution_access_approval` is `APPROVED`.

9. WHEN the Flutter_UI renders the Approved HODs list, THE Flutter_UI SHALL display an "Activate" action for each HOD whose `institution_access_approval` is `SUSPENDED`.

10. WHEN a suspend or activate action completes successfully, THE Flutter_UI SHALL invalidate the `approvedHodsProvider` and `coordinatorStatsProvider` so the list refreshes automatically.

11. IF a suspend or activate request fails, THEN THE Flutter_UI SHALL display a `SnackBar` with the error message returned by the server.

---

### Requirement 2: HOD Detail Screen

**User Story:** As a Coordinator, I want to tap on any HOD in the list and view their full profile, so that I can review their department, contact details, student count, and account status before taking action.

#### Acceptance Criteria

1. THE HOD_Manager SHALL expose a GET endpoint at `/coordinator/hods/:userId` that returns the HOD's full profile including: `userId`, `fullName`, `email`, `department`, `phoneNumber`, `employeeId`, `approvalStatus`, `createdAt`, and `studentCount` (number of students linked to that HOD).

2. IF the requested HOD does not belong to the Coordinator's university, THEN THE HOD_Manager SHALL return HTTP 403.

3. IF no HOD profile exists for the given `userId`, THEN THE HOD_Manager SHALL return HTTP 404.

4. WHEN a Coordinator taps an HOD card in any tab (Pending, Approved, Rejected), THE Flutter_UI SHALL navigate to the HOD Detail Screen passing the HOD's `userId`.

5. WHEN the HOD Detail Screen loads, THE Flutter_UI SHALL fetch HOD details from `/coordinator/hods/:userId` and display: full name, email, department, phone number (if present), employee ID (if present), account status badge, account creation date, and student count.

6. WHILE the HOD Detail Screen is loading data, THE Flutter_UI SHALL display a loading indicator.

7. IF the HOD Detail Screen fetch fails, THEN THE Flutter_UI SHALL display an error message with a retry button.

8. WHERE the HOD's `approvalStatus` is `APPROVED`, THE Flutter_UI SHALL display a "Suspend Account" button on the HOD Detail Screen.

9. WHERE the HOD's `approvalStatus` is `SUSPENDED`, THE Flutter_UI SHALL display an "Activate Account" button on the HOD Detail Screen.

10. WHERE the HOD's `approvalStatus` is `PENDING`, THE Flutter_UI SHALL display "Approve" and "Reject" action buttons on the HOD Detail Screen.

11. WHEN an action button (Approve, Reject, Suspend, Activate) is tapped on the HOD Detail Screen and the operation succeeds, THE Flutter_UI SHALL pop the detail screen and invalidate the relevant HOD list providers.

---

### Requirement 3: Report Download

**User Story:** As a Coordinator, I want to open or download a student's final report PDF directly from the reports list, so that I can review the document without leaving the app.

#### Acceptance Criteria

1. THE Report_Service SHALL include the `pdf_url` field in every record returned by `GET /coordinator-portal/reports/overview`.

2. WHEN the Flutter_UI renders a report list item, THE Flutter_UI SHALL display a download/open icon button if `pdf_url` is non-null and non-empty.

3. WHEN a Coordinator taps the download icon on a report card, THE Flutter_UI SHALL attempt to open the `pdf_url` in the device's default browser or PDF viewer using the `url_launcher` package.

4. IF the `pdf_url` cannot be launched (e.g., unsupported scheme or null value), THEN THE Flutter_UI SHALL display a `SnackBar` with the message "Unable to open report. The file may not be available."

5. IF a report record has `pdf_url` as null or empty, THEN THE Flutter_UI SHALL display the download icon in a disabled state (greyed out) and SHALL NOT attempt to launch a URL when tapped.

6. WHEN the download icon is tapped and the URL launches successfully, THE Flutter_UI SHALL display a `SnackBar` with the message "Opening report…" to confirm the action.

---

### Requirement 4: Placement Assignment Status Filter Tabs

**User Story:** As a Coordinator, I want to filter the assignments list by status (Active, Completed, Terminated), so that I can review the full history of placements, not just currently active ones.

#### Acceptance Criteria

1. THE Assignment_Service SHALL return all `InternshipAssignment` records for the coordinator's university regardless of status when responding to `GET /coordinator-portal/assignments/overview` (current behavior already does this — no backend change required).

2. WHEN the Flutter_UI renders the Placements tab, THE Flutter_UI SHALL display three filter tabs labelled "Active", "Completed", and "Terminated" within the Assignments sub-tab.

3. WHEN the "Active" filter tab is selected, THE Flutter_UI SHALL display only assignments where `status == 'ACTIVE'`.

4. WHEN the "Completed" filter tab is selected, THE Flutter_UI SHALL display only assignments where `status == 'COMPLETED'`.

5. WHEN the "Terminated" filter tab is selected, THE Flutter_UI SHALL display only assignments where `status == 'TERMINATED'`.

6. WHEN a filter tab is selected and no assignments match that status, THE Flutter_UI SHALL display an empty-state message appropriate to the selected status (e.g., "No completed placements yet").

7. THE Flutter_UI SHALL default to the "Active" filter tab when the Placements screen is first opened.

8. WHEN the user pulls to refresh on any filter tab, THE Flutter_UI SHALL invalidate `coordinatorAssignmentsProvider` and reload all assignments, then re-apply the active filter.

9. WHEN the Flutter_UI renders an assignment card, THE Flutter_UI SHALL display a status badge whose colour matches the assignment status: green for ACTIVE, blue for COMPLETED, red for TERMINATED.
