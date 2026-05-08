# Design Document — HoD Advanced Portal

## Overview

The HoD Advanced Portal extends the existing partial HoD implementation in InternLink with a full proposal state machine, student lifecycle timeline, placement tracking, reports & analytics, and enhanced dashboard intelligence. The system is built on the existing Node.js/TypeScript + Prisma/PostgreSQL backend and Flutter/Riverpod frontend.

The design adds 11 new backend endpoints under the `/hod/` prefix, two new Prisma schema fields, and three new Flutter tabs (Proposals, Tracking, Reports) while enhancing the existing Overview and Students tabs. The total bottom-nav tab count is kept at 5: **Overview → Students → Proposals → Tracking → Reports** (Directory is folded into the Proposals tab as a company-picker sub-flow).

### Key Design Decisions

| Decision | Rationale |
|---|---|
| `CANCELLED` added to `ApprovalStatus` enum | Reuses the existing enum rather than adding a separate field; keeps proposal status as a single source of truth |
| `flag_type` / `flag_note` as nullable String fields on `Student` | Simple, low-overhead flagging without a separate join table; one flag per student is sufficient for the current requirements |
| Student timeline derived from existing records | No separate audit table needed; timeline is computed from `hod_approval_status`, `internship_status`, `InternshipProposal`, and `InternshipAssignment` timestamps |
| Proposal history as in-memory log in enhanced endpoint | Avoids a new `ProposalHistory` table for MVP; state transitions are recorded via `responded_at` and `submitted_at` timestamps already on the model |
| Directory tab folded into Proposals | Keeps total tabs ≤ 5; company search is accessible from the "New Proposal" flow |
| Enhanced stats as a separate endpoint | Preserves backward compatibility with the existing `/hod/dashboard-stats` endpoint |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter App (Riverpod)                       │
│                                                                  │
│  HodDashboardScreen (5 tabs)                                     │
│  ┌──────────┬──────────┬───────────┬──────────┬──────────────┐  │
│  │ Overview │ Students │ Proposals │ Tracking │   Reports    │  │
│  └──────────┴──────────┴───────────┴──────────┴──────────────┘  │
│                                                                  │
│  HodRepository ──► HodStats (enhanced) / new model classes      │
│  Providers: hodEnhancedStatsProvider, hodPlacementsProvider,     │
│             hodWeeklyReportsProvider, hodReportsSummaryProvider, │
│             hodProposalStateProvider, hodStudentTimelineProvider │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS / Dio
┌────────────────────────────▼────────────────────────────────────┐
│                  Express API  (Node.js / TypeScript)             │
│                                                                  │
│  /hod/* routes  ──► authenticate + authorize([HOD])             │
│                                                                  │
│  hodController (existing, extended)                              │
│  hodEnhancedController (new file)                                │
│                                                                  │
│  Shared utilities:                                               │
│    departmentsMatch()   — existing scope helper                  │
│    getHodOr403()        — existing profile loader                │
│    getDeptStudentIds()  — new shared helper                      │
└────────────────────────────┬────────────────────────────────────┘
                             │ Prisma Client
┌────────────────────────────▼────────────────────────────────────┐
│                     PostgreSQL (Supabase)                        │
│                                                                  │
│  Student (+flag_type, +flag_note)                                │
│  InternshipProposal (status: ApprovalStatus + CANCELLED)        │
│  InternshipAssignment, WeeklyReport, FinalEvaluation, Report     │
└─────────────────────────────────────────────────────────────────┘
```

### Request Flow

1. Flutter calls `HodRepository` method → Dio sends authenticated request
2. Express middleware: `authenticate` (JWT) → `authorize([HOD])` (role check)
3. Controller calls `getHodOr403()` to load `HodProfile` with university
4. Controller calls `getDeptStudentIds()` to get the scoped student ID list
5. Business logic executes with scoped data
6. `sendSuccess` / `sendError` response helpers format the JSON response
7. Flutter provider receives data → Riverpod state updates → UI rebuilds

---

## Components and Interfaces

### Backend — New Controller File: `hodEnhancedController.ts`

All new endpoints are implemented in a new file to keep the existing `hodController.ts` stable.

#### Shared Helper: `getDeptStudentIds`

```typescript
async function getDeptStudentIds(hod: HodProfile & { university: University }): Promise<number[]> {
  const students = await prisma.student.findMany({
    where: { universityId: hod.universityId, department: { not: null } },
    select: { id: true, department: true },
  });
  return students
    .filter(s => departmentsMatch(s.department, hod.department))
    .map(s => s.id);
}
```

#### New Endpoints

| Method | Path | Handler | Description |
|---|---|---|---|
| GET | `/hod/dashboard-stats/enhanced` | `getEnhancedStats` | Full stats + alerts + trends |
| POST | `/hod/students/bulk-approve` | `bulkApproveStudents` | Approve array of studentIds |
| PATCH | `/hod/students/:id/flag` | `flagStudent` | Attach LOW_PERFORMANCE or INACTIVE flag |
| DELETE | `/hod/students/:id/flag` | `unflagStudent` | Remove flag |
| GET | `/hod/students/:id/timeline` | `getStudentTimeline` | Lifecycle timeline |
| PATCH | `/hod/proposals/:id/state` | `transitionProposalState` | State machine transition |
| GET | `/hod/placements` | `getPlacements` | All placements with optional status filter |
| PATCH | `/hod/placements/:id/force-end` | `forceEndPlacement` | Force-terminate active placement |
| GET | `/hod/reports/weekly` | `getWeeklyReports` | Weekly reports with filters |
| GET | `/hod/reports/summary` | `getReportsSummary` | Department summary stats |
| PATCH | `/hod/students/:id/reprocess` | `reprocessStudent` | Reset REJECTED → PENDING |

#### Route Registration (additions to `hodRoutes.ts`)

```typescript
// Enhanced stats
router.get('/dashboard-stats/enhanced', hodEnhanced.getEnhancedStats);

// Student management
router.post('/students/bulk-approve',    hodEnhanced.bulkApproveStudents);
router.patch('/students/:id/flag',       hodEnhanced.flagStudent);
router.delete('/students/:id/flag',      hodEnhanced.unflagStudent);
router.get('/students/:id/timeline',     hodEnhanced.getStudentTimeline);
router.patch('/students/:id/reprocess',  hodEnhanced.reprocessStudent);

// Proposal state machine
router.patch('/proposals/:id/state',     hodEnhanced.transitionProposalState);

// Placement tracking
router.get('/placements',                hodEnhanced.getPlacements);
router.patch('/placements/:id/force-end', hodEnhanced.forceEndPlacement);

// Reports
router.get('/reports/weekly',            hodEnhanced.getWeeklyReports);
router.get('/reports/summary',           hodEnhanced.getReportsSummary);
```

> **Route ordering note:** `/reports/weekly` and `/reports/summary` must be registered **before** the existing `/reports/:id/download` route to avoid Express matching `weekly`/`summary` as an `:id` parameter.

### Backend — Proposal State Machine

The valid transitions are encoded as a constant map:

```typescript
const VALID_TRANSITIONS: Record<string, string[]> = {
  DRAFT:    ['SENT', 'CANCELLED'],
  SENT:     ['PENDING', 'CANCELLED'],
  PENDING:  ['APPROVED', 'REJECTED'],
  APPROVED: [],
  REJECTED: [],
  CANCELLED:[],
};
```

The `transitionProposalState` handler:
1. Loads the proposal and verifies department scope
2. Looks up `VALID_TRANSITIONS[currentStatus]`
3. If `targetState` is not in the list → 400 error with message `"Invalid transition: {current} → {target}"`
4. Updates `status` and `responded_at` (for terminal states)
5. Fires notifications for `APPROVED` and `REJECTED` transitions
6. Returns the updated proposal

### Backend — Enhanced Dashboard Stats

`getEnhancedStats` computes in a single async batch:

```typescript
// Parallel queries
const [students, assignments, proposals30d, weeklyTrend, reports, evaluations] = await Promise.all([
  prisma.student.findMany({ where: { id: { in: deptStudentIds } }, include: { ... } }),
  prisma.internshipAssignment.findMany({ where: { studentId: { in: deptStudentIds } } }),
  prisma.internshipProposal.findMany({ where: { studentId: { in: deptStudentIds }, submitted_at: { gte: thirtyDaysAgo } } }),
  prisma.internshipAssignment.groupBy({ by: ['start_date'], where: { studentId: { in: deptStudentIds }, start_date: { gte: eightWeeksAgo } } }),
  prisma.report.findMany({ where: { studentId: { in: deptStudentIds } } }),
  prisma.finalEvaluation.findMany({ where: { studentId: { in: deptStudentIds } } }),
]);
```

Alert generation logic:
- **Unplaced > 30 days**: `approvedStudents.filter(s => s.internship_status !== 'PLACED' && daysSince(s.hod_approval_updated_at) > 30)`
- **Needs reassignment**: students whose only proposals are all REJECTED/CANCELLED
- **Inactive placed**: placed students with no WeeklyReport in past 14 days
- **Overdue report**: placed students with WeeklyReport or FinalEvaluation overdue > 7 days

### Flutter — Repository Extensions (`hod_repository.dart`)

New methods added to `HodRepository`:

```dart
// Enhanced stats
Future<HodEnhancedStats> getEnhancedStats();

// Student management
Future<void> bulkApproveStudents(List<int> studentIds);
Future<void> flagStudent(int studentId, String flagType, {String? note});
Future<void> unflagStudent(int studentId);
Future<List<Map<String, dynamic>>> getStudentTimeline(int studentId);
Future<void> reprocessStudent(int studentId);

// Proposals
Future<Map<String, dynamic>> transitionProposalState(int proposalId, String targetState);
Future<List<Map<String, dynamic>>> getProposalsFiltered({String? status});

// Placements
Future<List<Map<String, dynamic>>> getPlacements({String? status});
Future<void> forceEndPlacement(int placementId, String reason);

// Reports
Future<List<Map<String, dynamic>>> getWeeklyReports({int? weekNumber, String? attendanceStatus, String? studentName});
Future<Map<String, dynamic>> getReportsSummary();
```

### Flutter — New Model: `HodEnhancedStats`

```dart
class HodEnhancedStats extends HodStats {
  final double placementRate;
  final double reportsCompletionRate;
  final double approvalSuccessRate;
  final List<HodAlert> alerts;
  final List<WeeklyTrendPoint> weeklyPlacementTrend;
  // ... fromJson factory
}

class HodAlert {
  final String type;       // 'UNPLACED' | 'NEEDS_REASSIGNMENT' | 'INACTIVE' | 'OVERDUE'
  final String message;
  final int? studentId;
  final String? studentName;
  // ... fromJson factory
}

class WeeklyTrendPoint {
  final String weekLabel;  // e.g. "W1", "W2"
  final int count;
  // ... fromJson factory
}
```

### Flutter — New Providers

```dart
// Enhanced stats (replaces hodStatsProvider on Overview tab)
final hodEnhancedStatsProvider = FutureProvider<HodEnhancedStats>((ref) =>
    ref.watch(hodRepositoryProvider).getEnhancedStats());

// Proposals with status filter
final hodProposalsFilteredProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) =>
        ref.watch(hodRepositoryProvider).getProposalsFiltered(status: status));

// Placements with status filter
final hodPlacementsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) =>
        ref.watch(hodRepositoryProvider).getPlacements(status: status));

// Weekly reports with filter params
class WeeklyReportFilter {
  final int? weekNumber;
  final String? attendanceStatus;
  final String? studentName;
  // equality + hashCode for FutureProvider.family key
}
final hodWeeklyReportsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, WeeklyReportFilter>((ref, filter) =>
        ref.watch(hodRepositoryProvider).getWeeklyReports(...));

// Reports summary
final hodReportsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) =>
    ref.watch(hodRepositoryProvider).getReportsSummary());

// Student timeline
final hodStudentTimelineProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, studentId) =>
        ref.watch(hodRepositoryProvider).getStudentTimeline(studentId));
```

### Flutter — Tab Structure Changes

```
HodDashboardScreen (5 tabs)
├── Overview   → _HodOverviewTab        (enhanced: alerts, trend chart, placement rate)
├── Students   → _HodStudentsTab        (enhanced: bulk approve, flag, timeline, reprocess)
├── Proposals  → _HodProposalsTab       (new: full state machine CRUD + open letters)
├── Tracking   → _HodTrackingTab        (new: Active/Completed/Failed sub-tabs)
└── Reports    → _HodReportsTab         (new: Weekly/Final sub-tabs + summary card)
```

The existing `_HodPlacementTab` and `_HodDirectoryTab` are replaced. Company directory access is preserved inside the "New Proposal" bottom sheet (existing `_SendProposalSheet` pattern).

---

## Data Models

### Schema Changes

#### 1. Add `CANCELLED` to `ApprovalStatus` enum

```prisma
enum ApprovalStatus {
  PENDING
  APPROVED
  REJECTED
  SUSPENDED
  CANCELLED   // NEW — for proposal cancellation
}
```

Migration SQL:
```sql
ALTER TYPE "ApprovalStatus" ADD VALUE 'CANCELLED';
```

#### 2. Add flag fields to `Student` model

```prisma
model Student {
  // ... existing fields ...
  flag_type   String?   // 'LOW_PERFORMANCE' | 'INACTIVE' | null
  flag_note   String?   @db.Text
}
```

Migration SQL:
```sql
ALTER TABLE "Student" ADD COLUMN "flag_type" TEXT;
ALTER TABLE "Student" ADD COLUMN "flag_note" TEXT;
```

### API Response Shapes

#### `GET /hod/dashboard-stats/enhanced`

```json
{
  "success": true,
  "data": {
    "totalStudents": 42,
    "pendingApprovals": 5,
    "approvedStudents": 30,
    "rejectedStudents": 3,
    "placedStudents": 20,
    "approvedNotPlaced": 10,
    "reports": 18,
    "proposals": { "pending": 4, "approved": 12, "rejected": 3 },
    "placementRate": 66.67,
    "reportsCompletionRate": 90.0,
    "approvalSuccessRate": 80.0,
    "alerts": [
      {
        "type": "UNPLACED",
        "message": "Ali Hassan has been approved for 35 days without a placement",
        "studentId": 101,
        "studentName": "Ali Hassan",
        "daysElapsed": 35
      }
    ],
    "weeklyPlacementTrend": [
      { "weekLabel": "W1", "weekStart": "2025-06-01", "count": 2 },
      { "weekLabel": "W2", "weekStart": "2025-06-08", "count": 4 }
    ],
    "recentPendingStudents": [],
    "university": { "name": "University of Example" },
    "department": "Computer Science"
  }
}
```

#### `PATCH /hod/proposals/:id/state` — Request

```json
{ "targetState": "SENT" }
```

#### `GET /hod/students/:id/timeline` — Response

```json
{
  "success": true,
  "data": [
    { "state": "REGISTERED",  "timestamp": "2025-04-01T10:00:00Z", "actor": "student" },
    { "state": "APPROVED",    "timestamp": "2025-04-03T09:00:00Z", "actor": "hod" },
    { "state": "PROPOSED",    "timestamp": "2025-04-10T11:00:00Z", "actor": "hod" },
    { "state": "PLACED",      "timestamp": "2025-04-15T08:00:00Z", "actor": "system" }
  ]
}
```

#### `GET /hod/reports/summary` — Response

```json
{
  "success": true,
  "data": {
    "totalWeeklyReports": 84,
    "attendance": { "PRESENT": 70, "ABSENT": 8, "LATE": 6 },
    "averageTechnicalScore": 78.4,
    "averageSoftSkillScore": 82.1,
    "studentsWithFinalReport": 18,
    "studentsPlaced": 20
  }
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Department Scope Filter

*For any* HoD profile with a given `universityId` and `department`, every student returned by any HoD student query SHALL have a `universityId` equal to the HoD's `universityId` AND a `department` that matches the HoD's `department` (case-insensitive).

**Validates: Requirements 1.1, 1.2, 1.3, 1.4**

---

### Property 2: Out-of-Scope Resource Returns 403

*For any* resource ID (student, proposal, placement, or report) that belongs to a different university or department than the requesting HoD, the HoD_Portal SHALL return an HTTP 403 status code.

**Validates: Requirements 1.5**

---

### Property 3: Rate Computation Correctness

*For any* non-negative integer pair `(numerator, denominator)`:
- If `denominator > 0`, the computed rate SHALL equal `(numerator / denominator) * 100` (rounded to two decimal places).
- If `denominator == 0`, the computed rate SHALL equal `0`.

This property applies to both `placementRate` (placed / approved) and `reportsCompletionRate` (withReport / placed).

**Validates: Requirements 2.2, 2.3**

---

### Property 4: Alert Threshold Detection

*For any* student with `hod_approval_status = APPROVED` and `internship_status ≠ PLACED`:
- If the number of days since approval exceeds 30, the enhanced dashboard response SHALL include an alert of type `UNPLACED` for that student.
- If the number of days since approval is 30 or fewer, no `UNPLACED` alert SHALL be present for that student.

**Validates: Requirements 2.4, 12.1**

---

### Property 5: Bulk Approval Only Affects PENDING Students

*For any* list of student IDs submitted to `POST /hod/students/bulk-approve`:
- Every student in the list whose `hod_approval_status` was `PENDING` SHALL have their status set to `APPROVED` after the operation.
- Every student in the list whose `hod_approval_status` was NOT `PENDING` SHALL remain unchanged.
- Students not in the list SHALL remain unchanged regardless of their status.

**Validates: Requirements 3.4, 3.5**

---

### Property 6: Proposal State Machine Transition Validity

*For any* proposal in state `S` and any requested target state `T`:
- If `T` is in `VALID_TRANSITIONS[S]`, the transition SHALL succeed and the proposal's status SHALL equal `T`.
- If `T` is NOT in `VALID_TRANSITIONS[S]`, the transition SHALL fail with a 400 error and the proposal's status SHALL remain `S`.

Valid transitions: `DRAFT→SENT`, `DRAFT→CANCELLED`, `SENT→PENDING`, `SENT→CANCELLED`, `PENDING→APPROVED`, `PENDING→REJECTED`.

**Validates: Requirements 4.1**

---

### Property 7: Force-End Guard on Non-ACTIVE Placements

*For any* `InternshipAssignment` with status `COMPLETED` or `TERMINATED`, a call to `PATCH /hod/placements/:id/force-end` SHALL return an error response (4xx) and the assignment's status SHALL remain unchanged.

**Validates: Requirements 6.5**

---

### Property 8: Department Summary Aggregation Correctness

*For any* set of `WeeklyReport` records belonging to the HoD's department scope, the `GET /hod/reports/summary` response SHALL satisfy:
- `totalWeeklyReports` equals the count of all WeeklyReport records in scope.
- `attendance.PRESENT + attendance.ABSENT + attendance.LATE` equals `totalWeeklyReports`.
- `averageTechnicalScore` equals the arithmetic mean of all `FinalEvaluation.technical_score` values in scope (or `null` if none exist).

**Validates: Requirements 7.4**

---

### Property 9: Duplicate Proposal Prevention

*For any* `(studentId, companyId)` pair where a non-rejected, non-cancelled `InternshipProposal` already exists, a request to create a new proposal for the same pair SHALL be rejected with a 400 error, and no new proposal record SHALL be created.

**Validates: Requirements 4.7, 12.5**

---

## Error Handling

### HTTP Status Code Conventions

| Scenario | Status | Message Pattern |
|---|---|---|
| JWT missing or invalid | 401 | `"Unauthorized"` |
| HOD profile not found | 403 | `"HOD profile not found."` |
| Resource outside dept scope | 403 | `"Student/Proposal/Placement not in your department."` |
| Resource not found | 404 | `"{Resource} not found."` |
| Invalid state transition | 400 | `"Invalid transition: {current} → {target}"` |
| Duplicate proposal | 400 | `"A non-rejected proposal already exists for this student and company."` |
| Student not PENDING (bulk approve) | 200 | Partial success: returns `{ approved: [...], skipped: [...] }` |
| Force-end non-ACTIVE placement | 400 | `"Placement is already {status}."` |
| Reprocess non-REJECTED student | 400 | `"Student is not in REJECTED status."` |
| Flag invalid type | 400 | `"flagType must be LOW_PERFORMANCE or INACTIVE."` |

### Bulk Approve Partial Success

`POST /hod/students/bulk-approve` returns HTTP 200 with a partial-success body rather than failing the entire batch:

```json
{
  "success": true,
  "data": {
    "approved": [101, 102],
    "skipped": [{ "studentId": 103, "reason": "Already APPROVED" }],
    "outOfScope": [104]
  }
}
```

### Student Timeline Derivation

The timeline is computed (not stored) from existing timestamps:

```
REGISTERED  → student.created_at
APPROVED    → derived from hod_approval_status change (approximated by student.created_at + offset, or stored via a new updated_at field)
PROPOSED    → earliest InternshipProposal.submitted_at for this student
PLACED      → earliest InternshipAssignment.start_date for this student
ACTIVE      → same as PLACED (assignment is ACTIVE)
COMPLETED   → InternshipAssignment.end_date where status = COMPLETED
REJECTED    → if hod_approval_status = REJECTED, use student record timestamp
```

Since Prisma does not auto-track field-level change timestamps, the timeline endpoint uses the best available proxy timestamps. A future migration can add `hod_approval_updated_at` to `Student` for precision.

---

## Testing Strategy

### Unit Tests (Example-Based)

Focus on specific scenarios and edge cases:

- `getDeptStudentIds` returns correct IDs for a known dataset
- `getEnhancedStats` returns `placementRate = 0` when `approvedStudents = 0`
- `transitionProposalState` returns 400 for `APPROVED → SENT`
- `bulkApproveStudents` skips already-APPROVED students and returns them in `skipped`
- `forceEndPlacement` returns 400 for a COMPLETED placement
- `reprocessStudent` returns 400 for a PENDING student
- `flagStudent` returns 400 for an invalid `flagType`
- `getReportsSummary` returns correct attendance breakdown for a known dataset

### Property-Based Tests

Property-based testing is applicable here because the core business logic (scoping, rate computation, state machine, aggregation) consists of pure or near-pure functions that can be exercised with generated inputs.

**Library:** [fast-check](https://github.com/dubzzz/fast-check) (TypeScript, already compatible with the Node.js backend)

**Configuration:** Minimum 100 iterations per property test.

**Tag format:** `// Feature: hod-advanced-portal, Property {N}: {property_text}`

Each correctness property maps to one property-based test:

| Property | Test Description | Generator |
|---|---|---|
| P1: Dept scope filter | Generate random student arrays with mixed universityId/dept, verify filter | `fc.array(fc.record({ universityId: fc.integer(), department: fc.string() }))` |
| P2: 403 on out-of-scope | Generate random IDs not in dept scope, verify 403 | `fc.integer({ min: 1 })` |
| P3: Rate computation | Generate (numerator, denominator) pairs including (0,0) | `fc.tuple(fc.nat(), fc.nat())` |
| P4: Alert threshold | Generate students with varying approval ages | `fc.record({ daysAgo: fc.integer({ min: 0, max: 60 }) })` |
| P5: Bulk approve | Generate mixed-status student lists | `fc.array(fc.record({ id: fc.nat(), status: fc.constantFrom('PENDING','APPROVED','REJECTED') }))` |
| P6: State machine | Generate (currentState, targetState) pairs | `fc.tuple(fc.constantFrom(...states), fc.constantFrom(...states))` |
| P7: Force-end guard | Generate placements in COMPLETED/TERMINATED state | `fc.constantFrom('COMPLETED', 'TERMINATED')` |
| P8: Summary aggregation | Generate random WeeklyReport arrays | `fc.array(fc.record({ attendanceStatus: fc.constantFrom('PRESENT','ABSENT','LATE') }))` |
| P9: Duplicate prevention | Generate (studentId, companyId) pairs with existing proposals | `fc.tuple(fc.nat(), fc.nat())` |

### Integration Tests

- Full request/response cycle for each new endpoint using a test database
- Verify JWT authentication and HOD role authorization on all new routes
- Verify `CANCELLED` enum value is accepted by Prisma after migration
- Verify `flag_type` and `flag_note` fields persist and clear correctly

### Flutter Widget Tests

- `_HodOverviewTab` renders alerts section when `alerts` is non-empty
- `_HodOverviewTab` renders "All clear" when `alerts` is empty
- `_HodProposalsTab` shows correct action buttons per proposal state
- `_HodTrackingTab` sub-tab counts match summary row
- `_HodReportsTab` filter chips update the displayed list
