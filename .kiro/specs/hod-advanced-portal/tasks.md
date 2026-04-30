# Implementation Plan: HoD Advanced Portal

## Overview

Extend the existing HoD module with a full proposal state machine, student lifecycle timeline, placement tracking, reports & analytics, and an enhanced dashboard. The backend adds 11 new endpoints in a new `hodEnhancedController.ts` file; the Flutter app gains three new tabs (Proposals, Tracking, Reports) and enhances the existing Overview and Students tabs, bringing the total bottom-nav count to 5.

Implementation follows the order: database → backend controller → route registration → Flutter repository → Flutter UI tabs.

---

## Tasks

- [x] 1. Database migrations — CANCELLED enum value and flag fields on Student
  - Create a new Prisma migration that adds `CANCELLED` to the `ApprovalStatus` enum via `ALTER TYPE "ApprovalStatus" ADD VALUE 'CANCELLED'`
  - Create a second migration (or extend the same one) that adds `flag_type TEXT` and `flag_note TEXT` columns to the `"Student"` table
  - Update `apps/backend/prisma/schema.prisma`: add `CANCELLED` to `enum ApprovalStatus` and add `flag_type String?` / `flag_note String? @db.Text` fields to `model Student`
  - Run `npx prisma generate` to regenerate the Prisma client so TypeScript picks up the new enum value and fields
  - _Requirements: 3.7, 3.8, 4.1, 4.4, 17.3_

- [x] 2. Backend — `hodEnhancedController.ts` with all 11 new endpoints
  - [x] 2.1 Create `apps/backend/src/controllers/hodEnhancedController.ts` with the shared `getDeptStudentIds` helper and the `getEnhancedStats` handler
    - Implement `getDeptStudentIds(hod)` using `prisma.student.findMany` filtered by `universityId` and `departmentsMatch`
    - Implement `getEnhancedStats`: run parallel queries for students, assignments, proposals (last 30 days), weekly placement trend (8 weeks), reports, and final evaluations
    - Compute `placementRate`, `reportsCompletionRate`, `approvalSuccessRate` — return `0` when denominator is `0`
    - Generate alerts array: UNPLACED (approved > 30 days, not placed), NEEDS_REASSIGNMENT (all proposals rejected/cancelled), INACTIVE (placed, no WeeklyReport in 14 days), OVERDUE (report overdue > 7 days)
    - Return `weeklyPlacementTrend` as an 8-element array with `weekLabel`, `weekStart`, `count`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 17.1_

  - [ ]* 2.2 Write property test for rate computation correctness (Property 3)
    - **Property 3: Rate Computation Correctness** — for any `(numerator, denominator)` pair, rate = `(n/d)*100` when `d > 0`, else `0`
    - Use `fast-check`: `fc.tuple(fc.nat(), fc.nat())` generator, minimum 100 runs
    - Tag: `// Feature: hod-advanced-portal, Property 3: Rate computation correctness`
    - **Validates: Requirements 2.2, 2.3**

  - [ ]* 2.3 Write property test for alert threshold detection (Property 4)
    - **Property 4: Alert Threshold Detection** — approved student unplaced > 30 days → UNPLACED alert present; ≤ 30 days → no alert
    - Use `fast-check`: `fc.record({ daysAgo: fc.integer({ min: 0, max: 60 }) })` generator
    - Tag: `// Feature: hod-advanced-portal, Property 4: Alert threshold detection`
    - **Validates: Requirements 2.4, 12.1**

  - [x] 2.4 Implement `bulkApproveStudents` handler
    - Accept `{ studentIds: number[] }` in request body
    - For each ID: verify department scope; if `hod_approval_status === 'PENDING'` → set to `APPROVED` and `verification_status` to `APPROVED`, send notification; otherwise add to `skipped` array
    - IDs outside department scope go into `outOfScope` array
    - Return `{ approved: [...], skipped: [...], outOfScope: [...] }` with HTTP 200
    - _Requirements: 3.4, 3.5, 17.2_

  - [ ]* 2.5 Write property test for bulk approval only affecting PENDING students (Property 5)
    - **Property 5: Bulk Approval Only Affects PENDING Students** — non-PENDING students remain unchanged; students not in list remain unchanged
    - Use `fast-check`: `fc.array(fc.record({ id: fc.nat(), status: fc.constantFrom('PENDING','APPROVED','REJECTED') }))`
    - Tag: `// Feature: hod-advanced-portal, Property 5: Bulk approval only affects PENDING students`
    - **Validates: Requirements 3.4, 3.5**

  - [x] 2.6 Implement `flagStudent` and `unflagStudent` handlers
    - `flagStudent` (`PATCH /hod/students/:id/flag`): validate `flagType` is `LOW_PERFORMANCE` or `INACTIVE`; verify department scope; update `flag_type` and `flag_note` on the Student record
    - `unflagStudent` (`DELETE /hod/students/:id/flag`): verify department scope; set `flag_type` and `flag_note` to `null`
    - Return 400 with `"flagType must be LOW_PERFORMANCE or INACTIVE."` for invalid flag type
    - _Requirements: 3.7, 3.8, 17.3, 17.4_

  - [x] 2.7 Implement `getStudentTimeline` handler
    - `GET /hod/students/:id/timeline`: verify department scope
    - Derive timeline events from existing timestamps: `created_at` → REGISTERED; `hod_approval_status` change → APPROVED or REJECTED (use student record as proxy); earliest `InternshipProposal.submitted_at` → PROPOSED; earliest `InternshipAssignment.start_date` → PLACED/ACTIVE; `InternshipAssignment.end_date` where `status = COMPLETED` → COMPLETED
    - Return ordered array of `{ state, timestamp, actor }` objects
    - _Requirements: 3.6, 17.5_

  - [x] 2.8 Implement `reprocessStudent` handler
    - `PATCH /hod/students/:id/reprocess`: verify department scope
    - If `hod_approval_status !== 'REJECTED'` → return 400 `"Student is not in REJECTED status."`
    - Set `hod_approval_status` to `PENDING`
    - _Requirements: 3.11, 17.11_

  - [x] 2.9 Implement `transitionProposalState` handler
    - `PATCH /hod/proposals/:id/state`: accept `{ targetState: string }`
    - Encode `VALID_TRANSITIONS` map: `DRAFT→[SENT,CANCELLED]`, `SENT→[PENDING,CANCELLED]`, `PENDING→[APPROVED,REJECTED]`, terminal states have empty arrays
    - Verify proposal belongs to a student in department scope
    - If `targetState` not in `VALID_TRANSITIONS[currentStatus]` → return 400 `"Invalid transition: {current} → {target}"`
    - Update `status`; set `responded_at` for APPROVED/REJECTED/CANCELLED transitions
    - Send notification to student on APPROVED or REJECTED; send notification to supervisor on SENT
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.8, 4.11, 4.12, 17.6_

  - [ ]* 2.10 Write property test for proposal state machine transition validity (Property 6)
    - **Property 6: Proposal State Machine Transition Validity** — valid transitions succeed and update status; invalid transitions return 400 and leave status unchanged
    - Use `fast-check`: `fc.tuple(fc.constantFrom('DRAFT','SENT','PENDING','APPROVED','REJECTED','CANCELLED'), fc.constantFrom('DRAFT','SENT','PENDING','APPROVED','REJECTED','CANCELLED'))`
    - Tag: `// Feature: hod-advanced-portal, Property 6: Proposal state machine transition validity`
    - **Validates: Requirements 4.1**

  - [x] 2.11 Implement `getPlacements` handler
    - `GET /hod/placements`: accept optional `status` query param (`ACTIVE` | `COMPLETED` | `TERMINATED`)
    - Query `InternshipAssignment` where `studentId in deptStudentIds`, optionally filtered by status
    - Include student name, company name, start date, end date, status
    - _Requirements: 6.1, 6.2, 6.6, 17.7_

  - [x] 2.12 Implement `forceEndPlacement` handler
    - `PATCH /hod/placements/:id/force-end`: accept `{ reason: string }`
    - Load assignment; verify student is in department scope
    - If status is `COMPLETED` or `TERMINATED` → return 400 `"Placement is already {status}."`
    - Set `status` to `TERMINATED`, `end_date` to now; update student `internship_status` back to `PENDING` (per Requirement 12.6)
    - _Requirements: 6.4, 6.5, 12.6, 17.8_

  - [ ]* 2.13 Write property test for force-end guard on non-ACTIVE placements (Property 7)
    - **Property 7: Force-End Guard on Non-ACTIVE Placements** — COMPLETED or TERMINATED placements return 4xx and status remains unchanged
    - Use `fast-check`: `fc.constantFrom('COMPLETED', 'TERMINATED')`
    - Tag: `// Feature: hod-advanced-portal, Property 7: Force-end guard on non-ACTIVE placements`
    - **Validates: Requirements 6.5**

  - [x] 2.14 Implement `getWeeklyReports` handler
    - `GET /hod/reports/weekly`: accept optional query params `weekNumber`, `attendanceStatus`, `studentName`
    - Query `WeeklyReport` where `studentId in deptStudentIds`; apply filters; include student name via join
    - `studentName` filter uses case-insensitive partial match on `user.full_name`
    - _Requirements: 7.1, 7.6, 17.9_

  - [x] 2.15 Implement `getReportsSummary` handler
    - `GET /hod/reports/summary`: query all `WeeklyReport` records in scope; count by `attendanceStatus`
    - Query `FinalEvaluation` records in scope; compute arithmetic mean of `technical_score` and `soft_skill_score`
    - Return `{ totalWeeklyReports, attendance: { PRESENT, ABSENT, LATE }, averageTechnicalScore, averageSoftSkillScore, studentsWithFinalReport, studentsPlaced }`
    - _Requirements: 7.4, 17.10_

  - [ ]* 2.16 Write property test for department summary aggregation correctness (Property 8)
    - **Property 8: Department Summary Aggregation Correctness** — `PRESENT + ABSENT + LATE === totalWeeklyReports`; average score equals arithmetic mean
    - Use `fast-check`: `fc.array(fc.record({ attendanceStatus: fc.constantFrom('PRESENT','ABSENT','LATE') }))`
    - Tag: `// Feature: hod-advanced-portal, Property 8: Department summary aggregation correctness`
    - **Validates: Requirements 7.4**

- [x] 3. Backend — Register new routes in `hodRoutes.ts`
  - Import `hodEnhancedController` as `hodEnhanced` in `apps/backend/src/routes/hodRoutes.ts`
  - Register `GET /dashboard-stats/enhanced` **before** the existing `/dashboard-stats` route
  - Register `POST /students/bulk-approve` **before** the existing `/students/:studentId/approve` route (to avoid `:studentId` matching `bulk-approve`)
  - Register `PATCH /students/:id/flag`, `DELETE /students/:id/flag`, `GET /students/:id/timeline`, `PATCH /students/:id/reprocess`
  - Register `PATCH /proposals/:id/state`
  - Register `GET /placements`, `PATCH /placements/:id/force-end`
  - Register `GET /reports/weekly` and `GET /reports/summary` **before** the existing `GET /reports/:id/download` route
  - _Requirements: 17.1–17.11_

- [x] 4. Backend checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Flutter — Expand `HodRepository` with new methods and model classes
  - [x] 5.1 Add `HodEnhancedStats`, `HodAlert`, and `WeeklyTrendPoint` model classes to `hod_repository.dart`
    - `HodEnhancedStats extends HodStats` with fields: `placementRate`, `reportsCompletionRate`, `approvalSuccessRate`, `alerts`, `weeklyPlacementTrend`
    - `HodAlert` with fields: `type`, `message`, `studentId?`, `studentName?`, `daysElapsed?`
    - `WeeklyTrendPoint` with fields: `weekLabel`, `weekStart`, `count`
    - Implement `fromJson` factories for all three classes
    - _Requirements: 13.1, 13.3, 13.4_

  - [x] 5.2 Add `WeeklyReportFilter` value class to `hod_repository.dart`
    - Fields: `weekNumber?`, `attendanceStatus?`, `studentName?`
    - Override `==` and `hashCode` so `FutureProvider.family` can use it as a key
    - _Requirements: 16.3_

  - [x] 5.3 Add new repository methods to `HodRepository`
    - `getEnhancedStats()` → `GET /hod/dashboard-stats/enhanced` → returns `HodEnhancedStats`
    - `bulkApproveStudents(List<int> studentIds)` → `POST /hod/students/bulk-approve`
    - `flagStudent(int studentId, String flagType, {String? note})` → `PATCH /hod/students/:id/flag`
    - `unflagStudent(int studentId)` → `DELETE /hod/students/:id/flag`
    - `getStudentTimeline(int studentId)` → `GET /hod/students/:id/timeline`
    - `reprocessStudent(int studentId)` → `PATCH /hod/students/:id/reprocess`
    - `transitionProposalState(int proposalId, String targetState)` → `PATCH /hod/proposals/:id/state`
    - `getProposalsFiltered({String? status})` → `GET /hod/proposals?status=...`
    - `getPlacements({String? status})` → `GET /hod/placements?status=...`
    - `forceEndPlacement(int placementId, String reason)` → `PATCH /hod/placements/:id/force-end`
    - `getWeeklyReports({int? weekNumber, String? attendanceStatus, String? studentName})` → `GET /hod/reports/weekly`
    - `getReportsSummary()` → `GET /hod/reports/summary`
    - _Requirements: 13.1–13.6, 14.1–14.6, 15.1–15.5, 16.1–16.6_

  - [x] 5.4 Add new Riverpod providers to `hod_repository.dart`
    - `hodEnhancedStatsProvider` — `FutureProvider<HodEnhancedStats>`
    - `hodProposalsFilteredProvider` — `FutureProvider.family<List<Map<String,dynamic>>, String?>`
    - `hodPlacementsProvider` — `FutureProvider.family<List<Map<String,dynamic>>, String?>`
    - `hodWeeklyReportsProvider` — `FutureProvider.family<List<Map<String,dynamic>>, WeeklyReportFilter>`
    - `hodReportsSummaryProvider` — `FutureProvider<Map<String,dynamic>>`
    - `hodStudentTimelineProvider` — `FutureProvider.family<List<Map<String,dynamic>>, int>`
    - _Requirements: 13.1, 14.2, 15.2, 16.2_

- [x] 6. Flutter — Update `HodDashboardScreen` to 5 tabs
  - In `dashboards.dart`, update `HodDashboardScreen` to replace the existing 4-tab layout (`Overview`, `Students`, `Placement`, `Directory`) with 5 tabs: `Overview`, `Students`, `Proposals`, `Tracking`, `Reports`
  - Replace `_HodPlacementTab` and `_HodDirectoryTab` tab entries with `_HodProposalsTab`, `_HodTrackingTab`, and `_HodReportsTab` (stubs are acceptable at this stage — full implementations follow in tasks 8–10)
  - Update the drawer `HEAD OF DEPARTMENT` section to reflect the new tab indices
  - _Requirements: 14.1, 15.1, 16.1_

- [x] 7. Flutter — Enhance `_HodOverviewTab` with alerts, placement rate, and trend chart
  - Switch the tab to consume `hodEnhancedStatsProvider` instead of `hodStatsProvider`
  - Add a Placement Rate metric card to the existing metrics grid (alongside Total Students, Pending Approvals, Placed, Reports)
  - Add an Approval Success Rate indicator below the metrics grid
  - Add an Alerts section: when `alerts` is non-empty, render a list of alert cards each with an icon, description text, and a tap action that navigates to the relevant tab (UNPLACED/NEEDS_REASSIGNMENT → Students tab index 1, INACTIVE/OVERDUE → Tracking tab index 3); when `alerts` is empty, render an "All clear ✅" message
  - Add a Weekly Placement Trend bar chart using the `weeklyPlacementTrend` data (use `fl_chart` or a simple custom bar painter — match the existing chart style in the codebase)
  - Implement pull-to-refresh via `RefreshIndicator` that calls `ref.invalidate(hodEnhancedStatsProvider)`
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_

- [x] 8. Flutter — Enhance `_HodStudentsTab` with bulk approve, flag, timeline, and reprocess
  - Add a "Select All" / multi-select mode to the student list; when students are selected, show a "Bulk Approve" action button that calls `bulkApproveStudents` and refreshes the list
  - Add a flag icon button on each student card: tapping opens a bottom sheet to choose `LOW_PERFORMANCE` or `INACTIVE` with an optional note field; calls `flagStudent`; a filled flag icon indicates an existing flag with a tap to remove via `unflagStudent`
  - Add a "Timeline" action on each student card that opens a modal bottom sheet consuming `hodStudentTimelineProvider(studentId)` and rendering the ordered lifecycle events as a vertical stepper
  - Add a "Reprocess" action on REJECTED student cards that calls `reprocessStudent` and refreshes the list
  - Implement pull-to-refresh
  - _Requirements: 3.4, 3.5, 3.6, 3.7, 3.8, 3.11_

- [x] 9. Flutter — New `_HodProposalsTab` with full state machine UI
  - Create `_HodProposalsTab` as a `ConsumerStatefulWidget` in `dashboards.dart`
  - Display a filter chip row for states: ALL, DRAFT, SENT, PENDING, APPROVED, REJECTED, CANCELLED; selecting a chip calls `hodProposalsFilteredProvider(selectedStatus)`
  - Render each proposal as a card showing student name, company name, status badge, and submission date
  - Tapping a card opens a detail bottom sheet showing the proposal history log and available state-transition action buttons based on current state: DRAFT → "Send" (→ SENT) and "Cancel" (→ CANCELLED); SENT → "Cancel" (→ CANCELLED); REJECTED or CANCELLED → "Resend" (creates new proposal via `sendProposal`) and "Reassign" (opens student picker)
  - Add a FAB "New Proposal" that opens the existing `_SendProposalSheet` pattern (student picker → company picker → role/duration/notes form → saves as DRAFT)
  - Open letters (proposal_type = Open_Letter) are shown in the PENDING filter with APPROVE / REJECT actions calling `updateOpenLetter`
  - Implement pull-to-refresh
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 4.1–4.12, 5.1–5.6_

- [x] 10. Flutter — New `_HodTrackingTab` with Active/Completed/Failed sub-tabs
  - Create `_HodTrackingTab` as a `ConsumerStatefulWidget` in `dashboards.dart`
  - Add a summary row at the top showing counts for Active, Completed, and Failed placements (from `hodPlacementsProvider(null)`)
  - Implement three sub-tabs using `TabBar` + `TabBarView`: Active (`hodPlacementsProvider('ACTIVE')`), Completed (`hodPlacementsProvider('COMPLETED')`), Failed (`hodPlacementsProvider('TERMINATED')`)
  - Each placement card shows student name, company name, start date, end date (if available), and status
  - On the Failed sub-tab, each card has a "Reassign Student" button that navigates to the Proposals tab (index 2) with the student pre-selected in the new proposal flow
  - On the Active sub-tab, each card has a "Force End" button that opens a confirmation dialog with a reason text field, then calls `forceEndPlacement`
  - Implement pull-to-refresh on each sub-tab
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 6.1–6.6_

- [x] 11. Flutter — New `_HodReportsTab` with Weekly/Final sub-tabs and summary card
  - Create `_HodReportsTab` as a `ConsumerStatefulWidget` in `dashboards.dart`
  - Add a department summary card at the top consuming `hodReportsSummaryProvider`: show total weekly reports, attendance breakdown (PRESENT/ABSENT/LATE counts), and average technical and soft-skill scores
  - Implement two sub-tabs: "Weekly Reports" and "Final Reports"
  - Weekly Reports sub-tab: filter chips for attendance status (ALL, PRESENT, ABSENT, LATE) and a week-number text field; list consumes `hodWeeklyReportsProvider(WeeklyReportFilter(...))`; each row shows student name, week number, attendance badge, and remarks
  - Final Reports sub-tab: list consumes `hodReportsProvider`; each row shows student name and a "Download" button that calls `getReportDownload(id)` and opens `pdf_url` via `url_launcher`
  - Implement pull-to-refresh on each sub-tab
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 7.1–7.6_

- [x] 12. Flutter checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Property tests use `fast-check` (already compatible with the Node.js/TypeScript backend)
- Each property test must be tagged with `// Feature: hod-advanced-portal, Property N: ...`
- Route ordering in `hodRoutes.ts` is critical: `/reports/weekly` and `/reports/summary` must precede `/reports/:id/download`; `/students/bulk-approve` must precede `/students/:studentId/approve`
- The `CANCELLED` enum value requires a Prisma migration before any backend code referencing it will compile
- The existing `hodController.ts` is not modified; all new logic lives in `hodEnhancedController.ts`
- Company directory access is preserved inside the "New Proposal" flow in `_HodProposalsTab` — no separate Directory tab is needed
