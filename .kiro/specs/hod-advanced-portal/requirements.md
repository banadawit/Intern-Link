# Requirements Document

## Introduction

The HoD Advanced Portal is a comprehensive department-level management layer within the InternLink mobile app (Flutter + Node.js/Prisma). The Head of Department (HoD) acts as the primary orchestrator of the student internship lifecycle within their department: approving students, creating and managing internship proposals, handling open letter requests, tracking placements, reviewing reports, and communicating with all stakeholders.

The portal enhances and extends the existing partial implementation (dashboard stats, student approve/reject, basic proposals, open letters, company directory) with a full proposal state machine, student lifecycle timeline, placement tracking, reports & analytics, AI-assisted suggestions, and event-driven notifications.

---

## Glossary

- **HoD**: Head of Department — the authenticated user with role `HOD`, scoped to a single university department.
- **HoD_Portal**: The Flutter + backend system described in this document.
- **Student**: A registered user with role `STUDENT` belonging to the HoD's university and department.
- **Proposal**: An `InternshipProposal` record linking a Student to a Company, managed by the HoD.
- **Proposal_State_Machine**: The ordered set of states a Proposal transitions through: `DRAFT → SENT → PENDING → APPROVED → REJECTED`.
- **Open_Letter**: A student-initiated placement request (`proposal_type = 'Open_Letter'`) awaiting HoD decision.
- **Placement**: An `InternshipAssignment` record representing an active, completed, or terminated internship.
- **Report**: A `Report` or `WeeklyReport` record submitted by a student during their internship.
- **Dashboard**: The HoD Overview tab displaying aggregated department metrics, alerts, and trends.
- **AI_Assistant**: The existing AI chat endpoint used to generate HoD-specific suggestions and predictions.
- **Notification**: A `Notification` record delivered to a user's notification feed.
- **Department_Scope**: The constraint that the HoD may only access Students, Proposals, Placements, and Reports belonging to their own university and department.
- **Duplicate_Proposal**: A Proposal where the same `studentId` and `companyId` combination already has an active (non-rejected, non-cancelled) Proposal.
- **Placement_Rate**: The ratio of `PLACED` students to `APPROVED` students in the department, expressed as a percentage.
- **Alert**: A time-sensitive dashboard notification surfaced when a business rule threshold is breached (e.g., student unplaced > 30 days after approval).
- **Bulk_Approval**: A single HoD action that approves multiple PENDING students simultaneously.
- **Student_Flag**: A marker attached to a Student record indicating low performance or inactivity.
- **Coordinator**: A university-level administrator who can communicate with the HoD.
- **Supervisor**: A company-side user linked to one or more students via `InternshipAssignment`.

---

## Requirements

### Requirement 1: Department-Scoped Data Access

**User Story:** As a HoD, I want all data I access to be automatically filtered to my university and department, so that I cannot view or modify data belonging to other departments or universities.

#### Acceptance Criteria

1. THE HoD_Portal SHALL restrict all student queries to students whose `universityId` matches the HoD's `universityId` AND whose `department` matches the HoD's `department`.
2. THE HoD_Portal SHALL restrict all proposal queries to proposals whose `studentId` belongs to a student within the HoD's department scope.
3. THE HoD_Portal SHALL restrict all placement queries to placements whose `studentId` belongs to a student within the HoD's department scope.
4. THE HoD_Portal SHALL restrict all report queries to reports whose `studentId` belongs to a student within the HoD's department scope.
5. IF a HoD attempts to access a resource outside their department scope, THEN THE HoD_Portal SHALL return an HTTP 403 response with a descriptive error message.
6. THE HoD_Portal SHALL prevent a HoD from modifying an approved `InternshipAssignment` record.

---

### Requirement 2: Enhanced Dashboard with Metrics, Alerts, and Trends

**User Story:** As a HoD, I want an intelligent dashboard that shows key department metrics, actionable alerts, and weekly trends, so that I can make informed decisions without manually querying each section.

#### Acceptance Criteria

1. THE Dashboard SHALL display the following metrics: Total Students, Pending Approvals count, Placement Rate (%), Active Internships count, Rejected Proposals count, and Reports Completion Rate (%).
2. THE Dashboard SHALL compute Placement Rate as `(placedStudents / approvedStudents) * 100`, returning `0` when `approvedStudents` equals `0`.
3. THE Dashboard SHALL compute Reports Completion Rate as `(studentsWithFinalReport / placedStudents) * 100`, returning `0` when `placedStudents` equals `0`.
4. WHEN a Student has been in `APPROVED` status for more than 30 days without a Placement, THE Dashboard SHALL surface an alert identifying that student by name and days elapsed.
5. WHEN a Proposal has status `REJECTED` and the associated Student has no other active Proposal, THE Dashboard SHALL surface an alert indicating the student needs reassignment.
6. WHEN a placed Student has submitted no `WeeklyReport` in the past 14 days, THE Dashboard SHALL surface an alert identifying that student as inactive.
7. WHEN a placed Student has a `WeeklyReport` or `FinalEvaluation` that is overdue by more than 7 days, THE Dashboard SHALL surface an alert for that report.
8. THE Dashboard SHALL display a weekly placement trend showing the count of new placements per week for the past 8 weeks.
9. THE Dashboard SHALL display an approval success rate showing the ratio of `APPROVED` proposals to total proposals submitted in the past 30 days.
10. THE Dashboard SHALL refresh all metrics when the HoD performs a pull-to-refresh gesture.

---

### Requirement 3: Student Lifecycle Management

**User Story:** As a HoD, I want to manage the full lifecycle of students in my department — from registration approval through placement — so that I can ensure every student progresses correctly.

#### Acceptance Criteria

1. THE HoD_Portal SHALL support the following student lifecycle states in order: `REGISTERED → APPROVED → PROPOSED → PLACED → ACTIVE → COMPLETED`, with `REJECTED` as a terminal state reachable from `REGISTERED`.
2. WHEN a HoD approves a Student, THE HoD_Portal SHALL set `hod_approval_status` to `APPROVED` and `verification_status` to `APPROVED`, then send a notification to the student.
3. WHEN a HoD rejects a Student, THE HoD_Portal SHALL set `hod_approval_status` to `REJECTED`, record the rejection reason, and send a notification to the student containing the reason.
4. THE HoD_Portal SHALL support bulk approval: WHEN a HoD submits a list of student IDs with action `APPROVED`, THE HoD_Portal SHALL approve all students in the list who are in `PENDING` status and belong to the HoD's department scope.
5. IF a HoD attempts to approve a Student who is not in `PENDING` status, THEN THE HoD_Portal SHALL return an error indicating the student's current status.
6. THE HoD_Portal SHALL display a full student timeline showing each lifecycle state transition with timestamp and actor for a given student.
7. THE HoD_Portal SHALL allow a HoD to attach a flag (`LOW_PERFORMANCE` or `INACTIVE`) to a Student, storing the flag type and an optional note.
8. THE HoD_Portal SHALL allow a HoD to remove a flag from a Student.
9. IF a HoD attempts to create a Proposal for a Student whose `hod_approval_status` is not `APPROVED`, THEN THE HoD_Portal SHALL reject the request with an error message.
10. IF a HoD attempts to place a Student who already has an active Placement, THEN THE HoD_Portal SHALL reject the request with an error message.
11. THE HoD_Portal SHALL allow a previously `REJECTED` student to be reprocessed by setting their status back to `PENDING` for re-evaluation.

---

### Requirement 4: Proposal Engine with Full State Machine

**User Story:** As a HoD, I want to create, manage, and track internship proposals through a defined state machine, so that I have full visibility and control over every proposal's lifecycle.

#### Acceptance Criteria

1. THE Proposal_State_Machine SHALL enforce the following state transitions only: `DRAFT → SENT`, `SENT → PENDING`, `PENDING → APPROVED`, `PENDING → REJECTED`, `DRAFT → CANCELLED`, `SENT → CANCELLED`.
2. WHEN a HoD creates a Proposal with action `DRAFT`, THE HoD_Portal SHALL create an `InternshipProposal` record with status `DRAFT` without notifying the company.
3. WHEN a HoD sends a Proposal (transitions `DRAFT → SENT`), THE HoD_Portal SHALL update the proposal status to `SENT` and send a notification to the linked Supervisor (if assigned) or company contact.
4. WHEN a HoD cancels a Proposal in `DRAFT` or `SENT` state, THE HoD_Portal SHALL set the proposal status to `CANCELLED` and record the cancellation timestamp.
5. WHEN a HoD resends a `CANCELLED` or `REJECTED` Proposal, THE HoD_Portal SHALL create a new Proposal record (preserving the original as history) with status `SENT`.
6. WHEN a HoD reassigns a Proposal to a different Student, THE HoD_Portal SHALL cancel the original Proposal and create a new Proposal for the new Student with status `DRAFT`.
7. IF a HoD attempts to create a Proposal where a non-rejected, non-cancelled Proposal already exists for the same `studentId` and `companyId`, THEN THE HoD_Portal SHALL reject the request with a duplicate prevention error.
8. THE HoD_Portal SHALL maintain a proposal history log recording every state transition with timestamp and actor for each Proposal.
9. THE HoD_Portal SHALL allow filtering proposals by status (`DRAFT`, `SENT`, `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`).
10. THE HoD_Portal SHALL allow a HoD to add a role/position title and notes when creating or editing a Proposal in `DRAFT` state.
11. WHEN a Proposal transitions to `APPROVED`, THE HoD_Portal SHALL send a notification to the associated Student.
12. WHEN a Proposal transitions to `REJECTED`, THE HoD_Portal SHALL send a notification to the associated Student and surface a reassignment alert on the Dashboard.

---

### Requirement 5: Open Letter Handling

**User Story:** As a HoD, I want to review and act on open letter requests submitted by students, so that I can approve self-sourced placements or reject them with a reason.

#### Acceptance Criteria

1. THE HoD_Portal SHALL list all `InternshipProposal` records with `proposal_type = 'Open_Letter'` belonging to the HoD's department scope, ordered by submission date descending.
2. WHEN a HoD approves an Open Letter, THE HoD_Portal SHALL set the proposal status to `APPROVED`, record `responded_at`, and send a notification to the student.
3. WHEN a HoD rejects an Open Letter, THE HoD_Portal SHALL set the proposal status to `REJECTED`, record `responded_at` and the rejection reason, and send a notification to the student containing the reason.
4. WHEN a HoD approves an Open Letter, THE HoD_Portal SHALL offer the option to convert the Open Letter into a formal HoD-initiated Proposal by creating a new `InternshipProposal` with `proposal_type = 'HoD_Initiated'` and status `SENT`.
5. IF a HoD attempts to approve an Open Letter for a Student who already has an active Placement, THEN THE HoD_Portal SHALL reject the action with an error message.
6. THE HoD_Portal SHALL display the student name, company name, submission date, and current status for each Open Letter in the list.

---

### Requirement 6: Placement Tracking

**User Story:** As a HoD, I want to view and manage all active, completed, and failed placements in my department, so that I can monitor internship progress and intervene when necessary.

#### Acceptance Criteria

1. THE HoD_Portal SHALL display placements grouped into three categories: `ACTIVE` (AssignmentStatus = `ACTIVE`), `COMPLETED` (AssignmentStatus = `COMPLETED`), and `FAILED` (AssignmentStatus = `TERMINATED`).
2. THE HoD_Portal SHALL display for each placement: student name, company name, start date, end date (if available), and current status.
3. WHEN a placement has status `TERMINATED` (failed), THE HoD_Portal SHALL allow the HoD to reassign the student by initiating a new Proposal for that student.
4. THE HoD_Portal SHALL allow a HoD to force-end an `ACTIVE` placement by setting its status to `TERMINATED` and recording an end date and reason.
5. IF a HoD attempts to force-end a placement that is already `COMPLETED` or `TERMINATED`, THEN THE HoD_Portal SHALL reject the action with an error message.
6. THE HoD_Portal SHALL display a summary count of Active, Completed, and Failed placements at the top of the placement tracking view.

---

### Requirement 7: Reports and Analytics

**User Story:** As a HoD, I want to view, filter, and export student reports for my department, so that I can monitor academic progress and generate department summaries.

#### Acceptance Criteria

1. THE HoD_Portal SHALL list all `WeeklyReport` records for students in the HoD's department scope, with filters for week number, attendance status (`PRESENT`, `ABSENT`, `LATE`), and student name.
2. THE HoD_Portal SHALL list all `Report` (final report) records for students in the HoD's department scope.
3. WHEN a HoD requests a final report download, THE HoD_Portal SHALL return the `pdf_url` for the report if it exists, or an error if the report has no PDF.
4. THE HoD_Portal SHALL display a department summary showing: total weekly reports submitted, attendance breakdown (present/absent/late counts), and average technical and soft-skill scores from `FinalEvaluation` records.
5. THE HoD_Portal SHALL display attendance trends as a weekly breakdown of present/absent/late counts for the past 8 weeks.
6. THE HoD_Portal SHALL allow filtering reports by student name using a case-insensitive partial match.

---

### Requirement 8: Company Directory

**User Story:** As a HoD, I want to search and browse the company directory and invite new companies, so that I can identify suitable placement partners for my students.

#### Acceptance Criteria

1. THE HoD_Portal SHALL list all companies with `approval_status = 'APPROVED'`, displaying name, address, supervisor count, and active placement count.
2. THE HoD_Portal SHALL support case-insensitive partial-match search on company name.
3. THE HoD_Portal SHALL display for each company: industry (if available), total past accepted proposals count (acceptance rate numerator), and total proposals sent count (acceptance rate denominator).
4. WHEN a HoD submits an invitation with a company name and email, THE HoD_Portal SHALL create a `Company` record with `approval_status = 'PENDING'` and send an invitation email to the provided address.
5. IF a HoD attempts to invite a company using an email address already registered in the system, THEN THE HoD_Portal SHALL reject the request with a duplicate email error.

---

### Requirement 9: Communication

**User Story:** As a HoD, I want to communicate via chat with coordinators, students in my department, and supervisors linked to my students, so that I can coordinate internship activities efficiently.

#### Acceptance Criteria

1. THE HoD_Portal SHALL allow a HoD to initiate or continue a chat conversation with any Coordinator at the same university.
2. THE HoD_Portal SHALL allow a HoD to initiate or continue a chat conversation with any Student in the HoD's department scope.
3. THE HoD_Portal SHALL allow a HoD to initiate or continue a chat conversation with any Supervisor linked to a Student in the HoD's department scope via an active `InternshipAssignment`.
4. THE HoD_Portal SHALL prevent a HoD from initiating a chat with users outside the above three categories.
5. THE HoD_Portal SHALL display unread message counts per conversation in the chat list.

---

### Requirement 10: Event-Driven Notifications

**User Story:** As a HoD, I want to receive and send notifications for key internship events, so that all stakeholders are informed in real time.

#### Acceptance Criteria

1. WHEN a new Student registers in the HoD's department, THE HoD_Portal SHALL create a Notification for the HoD with the student's name and registration date.
2. WHEN a Proposal submitted by the HoD receives a result (`APPROVED` or `REJECTED`), THE HoD_Portal SHALL create a Notification for the HoD with the proposal result and company name.
3. WHEN a Student submits a `WeeklyReport`, THE HoD_Portal SHALL create a Notification for the HoD identifying the student and the week number.
4. WHEN a Company accepts an invitation (sets `approval_status` to `APPROVED`), THE HoD_Portal SHALL create a Notification for the HoD with the company name.
5. WHEN a HoD sends a Proposal, THE HoD_Portal SHALL create a Notification for the linked Supervisor (if assigned) with the student name and proposal details.
6. WHEN a HoD approves a Student, THE HoD_Portal SHALL create a Notification for the Student confirming approval.
7. WHEN a HoD rejects a Student, THE HoD_Portal SHALL create a Notification for the Student containing the rejection reason.

---

### Requirement 11: AI Assistant Integration

**User Story:** As a HoD, I want AI-powered suggestions and predictions specific to my department context, so that I can make better placement and proposal decisions.

#### Acceptance Criteria

1. THE AI_Assistant SHALL accept a HoD-specific prompt requesting company suggestions for a given student, returning a ranked list of companies with justification based on the student's department and available company data.
2. THE AI_Assistant SHALL accept a HoD-specific prompt requesting generated proposal text for a given student-company pair, returning a draft `expected_outcomes` field value.
3. THE AI_Assistant SHALL accept a HoD-specific prompt requesting rejection risk prediction for a given Proposal, returning a risk level (`LOW`, `MEDIUM`, `HIGH`) with reasoning.
4. THE AI_Assistant SHALL accept a HoD-specific prompt requesting identification of inactive students, returning a list of students with no `WeeklyReport` in the past 14 days.
5. WHEN the AI_Assistant generates a suggestion, THE HoD_Portal SHALL display the suggestion in the existing AI chat interface without creating a new screen.

---

### Requirement 12: Edge Case Enforcement

**User Story:** As a HoD, I want the system to enforce business rules for edge cases, so that data integrity is maintained and invalid states are prevented.

#### Acceptance Criteria

1. IF a Student has been `APPROVED` but has no Proposal after 30 days, THEN THE Dashboard SHALL surface an alert for that student.
2. IF a Proposal has been `APPROVED` but the associated Student has no `InternshipAssignment`, THEN THE HoD_Portal SHALL surface a warning and allow the HoD to manually trigger assignment creation.
3. IF a HoD attempts to approve a Student who already has `hod_approval_status = 'APPROVED'`, THEN THE HoD_Portal SHALL return an error indicating the student is already approved.
4. IF a Proposal is created for a Student who has no linked Supervisor at the target Company, THEN THE HoD_Portal SHALL display a warning that no supervisor is assigned and block the transition from `SENT` to `PENDING` until a Supervisor is linked.
5. THE HoD_Portal SHALL prevent a Student from having more than one non-rejected, non-cancelled Proposal at the same time for the same Company.
6. WHEN a Student's `InternshipAssignment` is set to `TERMINATED`, THE HoD_Portal SHALL automatically update the Student's `internship_status` back to `PENDING` to allow reassignment.

---

### Requirement 13: Flutter UI — Enhanced Dashboard Tab

**User Story:** As a HoD using the mobile app, I want the Overview tab to show alerts, trends, and a placement rate metric, so that I have actionable intelligence at a glance.

#### Acceptance Criteria

1. THE Dashboard SHALL display a Placement Rate percentage metric card alongside the existing Total Students, Pending Approvals, Placed, and Reports cards.
2. THE Dashboard SHALL display an Alerts section below the metrics grid, listing each active alert with an icon, description, and a tap action that navigates to the relevant tab.
3. THE Dashboard SHALL display a Weekly Placement Trend chart (bar or line) showing new placements per week for the past 8 weeks.
4. THE Dashboard SHALL display an Approval Success Rate indicator showing the percentage of proposals approved in the past 30 days.
5. WHEN there are no active alerts, THE Dashboard SHALL display an "All clear" message in the Alerts section.
6. THE Dashboard SHALL support pull-to-refresh to reload all metrics and alerts.

---

### Requirement 14: Flutter UI — Proposal Engine Tab

**User Story:** As a HoD using the mobile app, I want a dedicated Proposals tab with full CRUD and state machine controls, so that I can manage proposals without leaving the app.

#### Acceptance Criteria

1. THE HoD_Portal SHALL add a "Proposals" tab to the HoD dashboard bottom navigation, replacing or augmenting the existing Placement tab.
2. THE Proposals tab SHALL display proposals grouped or filterable by state: `DRAFT`, `SENT`, `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`.
3. THE Proposals tab SHALL provide a "New Proposal" action that opens a form to select a Student, Company, role/position title, duration, and notes, saving as `DRAFT`.
4. WHEN a proposal card is tapped, THE HoD_Portal SHALL display a detail sheet showing the full proposal history log and available state transition actions.
5. THE Proposals tab SHALL display available actions per proposal based on current state: `DRAFT` → Send, Cancel; `SENT` → Cancel; `PENDING` → (awaiting external); `REJECTED` → Resend, Reassign; `CANCELLED` → Resend.
6. THE Proposals tab SHALL support pull-to-refresh to reload the proposals list.

---

### Requirement 15: Flutter UI — Placement Tracking Tab

**User Story:** As a HoD using the mobile app, I want a Placement Tracking tab showing active, completed, and failed placements with management actions, so that I can monitor all internships in one place.

#### Acceptance Criteria

1. THE HoD_Portal SHALL add a "Tracking" tab to the HoD dashboard bottom navigation for placement tracking.
2. THE Tracking tab SHALL display three sub-tabs: Active, Completed, and Failed, each showing the relevant placements.
3. WHEN a Failed placement card is tapped, THE HoD_Portal SHALL offer a "Reassign Student" action that opens the proposal creation flow pre-filled with the student's details.
4. THE Tracking tab SHALL display a summary row at the top showing counts for Active, Completed, and Failed placements.
5. THE Tracking tab SHALL support pull-to-refresh to reload placement data.

---

### Requirement 16: Flutter UI — Reports Tab

**User Story:** As a HoD using the mobile app, I want a Reports tab with filters and download capability, so that I can review student progress and export final reports.

#### Acceptance Criteria

1. THE HoD_Portal SHALL add a "Reports" tab to the HoD dashboard bottom navigation.
2. THE Reports tab SHALL display two sub-tabs: Weekly Reports and Final Reports.
3. THE Weekly Reports sub-tab SHALL support filtering by week number and attendance status.
4. THE Final Reports sub-tab SHALL display each student's final report with a download button that opens the `pdf_url` in the device browser.
5. THE Reports tab SHALL display a department summary card showing total reports, attendance breakdown, and average evaluation scores.
6. THE Reports tab SHALL support pull-to-refresh to reload report data.

---

### Requirement 17: Backend — New API Endpoints

**User Story:** As a backend developer, I want new and enhanced API endpoints to support the advanced HoD portal features, so that the Flutter app has all the data it needs.

#### Acceptance Criteria

1. THE HoD_Portal SHALL expose `GET /hod/dashboard-stats/enhanced` returning all existing stats plus: `placementRate`, `reportsCompletionRate`, `alerts` array, `weeklyPlacementTrend` array (8 weeks), and `approvalSuccessRate`.
2. THE HoD_Portal SHALL expose `POST /hod/students/bulk-approve` accepting an array of `studentIds` and approving all eligible students in one request.
3. THE HoD_Portal SHALL expose `PATCH /hod/students/:id/flag` accepting `flagType` (`LOW_PERFORMANCE` | `INACTIVE`) and optional `note`, storing the flag on the student record.
4. THE HoD_Portal SHALL expose `DELETE /hod/students/:id/flag` removing the flag from the student record.
5. THE HoD_Portal SHALL expose `GET /hod/students/:id/timeline` returning the ordered list of lifecycle state transitions for a student.
6. THE HoD_Portal SHALL expose `PATCH /hod/proposals/:id/state` accepting a `targetState` and applying the Proposal_State_Machine transition, returning the updated proposal.
7. THE HoD_Portal SHALL expose `GET /hod/placements` returning all `InternshipAssignment` records for the HoD's department scope, with an optional `status` query parameter.
8. THE HoD_Portal SHALL expose `PATCH /hod/placements/:id/force-end` accepting `reason` and setting the assignment status to `TERMINATED`.
9. THE HoD_Portal SHALL expose `GET /hod/reports/weekly` returning all `WeeklyReport` records for the HoD's department scope, with optional filters for `weekNumber`, `attendanceStatus`, and `studentName`.
10. THE HoD_Portal SHALL expose `GET /hod/reports/summary` returning the department summary: total weekly reports, attendance breakdown, and average evaluation scores.
11. THE HoD_Portal SHALL expose `PATCH /hod/students/:id/reprocess` setting a `REJECTED` student's `hod_approval_status` back to `PENDING`.
