# Implementation Plan: coordinator-portal-complete

## Overview

Implements the four missing Coordinator Portal features in order: backend endpoints first, then Flutter UI changes that depend on them. Each task is small and independently executable. Backend tasks cover HOD suspend/activate/detail endpoints and route registration. Flutter tasks cover the repository methods, providers, and UI widgets.

## Tasks

- [x] 1. Add `suspendHod` and `activateHod` controller functions
  - In `apps/backend/src/controllers/coordinatorController.ts`, add two new exported async functions: `suspendHod` and `activateHod`
  - `suspendHod`: resolve coordinator's `universityId` via `getCoordinatorUniversityId()`, fetch `HodProfile` where `userId = req.params.userId` including `user`, validate role is `HOD` and university matches, check not already `SUSPENDED` (409), call `prisma.user.update({ institution_access_approval: 'SUSPENDED' })`, return `{ userId, status: 'SUSPENDED' }`
  - `activateHod`: same pattern but validates not already `APPROVED` (409) and sets `institution_access_approval: 'APPROVED'`
  - Follow the existing error response pattern: `res.status(N).json({ error: '...' })`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 1.1 Write property test for `suspendHod` status transition
    - **Property 1: Suspend transitions status to SUSPENDED**
    - **Validates: Requirements 1.1**

  - [ ]* 1.2 Write property test for `activateHod` status transition
    - **Property 2: Activate transitions status to APPROVED**
    - **Validates: Requirements 1.2**

  - [ ]* 1.3 Write property test for suspend/activate round-trip
    - **Property 3: Suspend then activate is a round-trip**
    - **Validates: Requirements 1.1, 1.2**

  - [ ]* 1.4 Write property test for cross-university access denial on suspend/activate
    - **Property 4: Cross-university access is always denied**
    - **Validates: Requirements 1.3**

- [x] 2. Add `getHodDetail` controller function
  - In `apps/backend/src/controllers/coordinatorController.ts`, add a new exported async function `getHodDetail`
  - Resolve coordinator's `universityId`, fetch `HodProfile` where `userId = req.params.userId` with `include: { user: true, _count: { select: { students: true } } }`
  - Validate `universityId` matches (403) and profile exists (404)
  - Return `{ userId, fullName, email, department, phoneNumber, approvalStatus, createdAt, studentCount }` — note `phoneNumber` maps to `hodProfile.phone_number` (which also stores `employeeId` per existing `createHod` behaviour)
  - _Requirements: 2.1, 2.2, 2.3_

  - [ ]* 2.1 Write property test for HOD detail response shape
    - **Property 5: HOD detail response contains all required fields**
    - **Validates: Requirements 2.1**

  - [ ]* 2.2 Write property test for cross-university access denial on `getHodDetail`
    - **Property 4: Cross-university access is always denied**
    - **Validates: Requirements 2.2**

- [x] 3. Register new routes in `coordinatorRoutes.ts`
  - In `apps/backend/src/routes/coordinatorRoutes.ts`, import `getHodDetail`, `suspendHod`, `activateHod` from `coordinatorController`
  - Append after the existing `router.post('/hods', createHod)` line:
    ```typescript
    router.get('/hods/:userId', getHodDetail);
    router.patch('/hods/:userId/suspend', suspendHod);
    router.patch('/hods/:userId/activate', activateHod);
    ```
  - _Requirements: 1.1, 1.2, 2.1_

- [x] 4. Checkpoint — verify backend compiles and routes are reachable
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Add `suspendHod`, `activateHod`, and `getHodDetail` to `coordinator_repository.dart`
  - In `apps/intern_mobile_app/lib/features/dashboard/data/repositories/coordinator_repository.dart`, add three new methods to `CoordinatorRepository`:
    ```dart
    Future<void> suspendHod(int userId) async { ... }
    Future<void> activateHod(int userId) async { ... }
    Future<Map<String, dynamic>> getHodDetail(int userId) async { ... }
    ```
  - Add a new `FutureProvider.family` provider at the bottom of the file:
    ```dart
    final hodDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, userId) {
      return ref.watch(coordinatorRepositoryProvider).getHodDetail(userId);
    });
    ```
  - _Requirements: 1.8, 1.9, 2.4, 2.5_

- [x] 6. Add Suspend/Activate action buttons to `_CoordinatorHodsTab` in `dashboards.dart`
  - In `apps/intern_mobile_app/lib/features/dashboard/presentation/screens/dashboards.dart`, extend `_buildHodList` (or the HOD card builder) to show action buttons based on `institution_access_approval`
  - For HODs with `institution_access_approval == 'APPROVED'`: show a "Suspend" button that calls `suspendHod(userId)` then invalidates `approvedHodsProvider` and `coordinatorStatsProvider`
  - For HODs with `institution_access_approval == 'SUSPENDED'`: show an "Activate" button that calls `activateHod(userId)` then invalidates the same providers
  - Follow the existing `_verify` method pattern for `try/catch` and `SnackBar` error display
  - On success, show a confirmation `SnackBar` and refresh the list
  - _Requirements: 1.8, 1.9, 1.10, 1.11_

- [x] 7. Make HOD cards tappable — navigate to `HodDetailScreen`
  - Wrap each HOD card in `_buildHodList` with a `GestureDetector(onTap: () => Navigator.push(...))` that navigates to `HodDetailScreen(userId: userId)`
  - This applies to cards in all three tabs (Pending, Approved, Rejected)
  - _Requirements: 2.4_

- [x] 8. Implement `HodDetailScreen` widget in `dashboards.dart`
  - Add a new top-level `ConsumerStatefulWidget` class `HodDetailScreen` that accepts `final int userId`
  - Watch `hodDetailProvider(userId)` and handle three states:
    - Loading: `CircularProgressIndicator` centered
    - Error: full-screen error message with a "Retry" button that calls `ref.invalidate(hodDetailProvider(userId))`
    - Data: `ModernSliverAppBar` + detail cards showing name, email, department, phone number, approval status badge (colour-coded), creation date, and student count
  - Action button row based on `approvalStatus`:
    - `APPROVED` → red `FilledButton` labelled "Suspend Account" calling `suspendHod`
    - `SUSPENDED` → green `FilledButton` labelled "Activate Account" calling `activateHod`
    - `PENDING` → "Approve" and "Reject" buttons using the existing `_verify` pattern
  - On action success: `Navigator.pop()` + invalidate `approvedHodsProvider`, `pendingHodsProvider`, `rejectedHodsProvider`, `coordinatorStatsProvider`, and `hodDetailProvider(userId)`
  - On action failure: `SnackBar` with error message
  - _Requirements: 2.5, 2.6, 2.7, 2.8, 2.9, 2.10, 2.11_

  - [ ]* 8.1 Write property test for action button rendering based on `approvalStatus`
    - **Property 6: Action button rendered matches HOD approval status**
    - **Validates: Requirements 2.8, 2.9, 2.10**

- [x] 9. Checkpoint — verify HOD suspend/activate and detail screen work end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Add `url_launcher` dependency and implement report download button
  - Add `url_launcher` to `pubspec.yaml` under `dependencies` in `apps/intern_mobile_app`
  - In `dashboards.dart`, locate the `_ReportsView` report card `Row` and add a trailing `IconButton` with `Icons.download_rounded`
  - Icon is enabled (coloured) when `pdf_url` is non-null and non-empty; disabled (greyed out, `onPressed: null`) otherwise
  - On tap: call `canLaunchUrl(uri)` — if true, call `launchUrl(uri, mode: LaunchMode.externalApplication)` and show `SnackBar('Opening report…')`; if false, show `SnackBar('Unable to open report. The file may not be available.')`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 10.1 Write property test for download icon enabled/disabled state
    - **Property 7: Report download icon state matches pdf_url presence**
    - **Validates: Requirements 3.2, 3.5**

- [x] 11. Add placement status filter sub-tabs to `_CoordinatorPlacementsTab`
  - In `dashboards.dart`, inside `_CoordinatorPlacementsTab` (a `ConsumerStatefulWidget`), add a new `TabController _assignmentTabCtrl` with `length: 3` for the Assignments sub-tab
  - Replace the current single assignments list with a nested tab structure: Active / Completed / Terminated
  - Call `_buildAssignmentsList(async, isDark, 'ACTIVE')`, `_buildAssignmentsList(async, isDark, 'COMPLETED')`, and `_buildAssignmentsList(async, isDark, 'TERMINATED')` for each tab respectively
  - Reuse the existing `SliverTabBarDelegate` pattern for the inner tab bar
  - Default to the "Active" tab (index 0) on first open
  - Update the empty-state message in `_buildAssignmentsList` to be status-aware: "No active placements" / "No completed placements yet" / "No terminated placements"
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ]* 11.1 Write property test for assignment filter showing only matching status
    - **Property 8: Assignment filter shows only matching status**
    - **Validates: Requirements 4.3, 4.4, 4.5**

- [x] 12. Add status badge colour to assignment cards
  - In `dashboards.dart`, update the assignment card status badge colour in `_buildAssignmentsList` (or the card builder) to use:
    - `Colors.green` when `status == 'ACTIVE'`
    - `Colors.blue` when `status == 'COMPLETED'`
    - `Colors.red` when `status == 'TERMINATED'`
  - _Requirements: 4.9_

  - [ ]* 12.1 Write property test for assignment status badge colour consistency
    - **Property 9: Assignment status badge colour is consistent**
    - **Validates: Requirements 4.9**

- [x] 13. Final checkpoint — ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Backend tasks (1–4) must be completed before Flutter tasks (5–13) that call the new endpoints
- Tasks 5–9 cover HOD suspend/activate/detail (Requirements 1 & 2); Tasks 10 covers report download (Requirement 3); Tasks 11–12 cover placement filter tabs (Requirement 4)
- No database migrations are required — all schema fields already exist
- The `pdf_url` field is already returned by the existing `getReportsOverview` endpoint; no backend change is needed for Requirement 3
- The assignments overview endpoint already returns all statuses; no backend change is needed for Requirement 4
- Property tests use `fast-check` (TypeScript backend) and `glados` (Dart/Flutter)
