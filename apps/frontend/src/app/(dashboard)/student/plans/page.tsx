import { Suspense } from "react";
import WeeklyPlans from "../WeeklyPlans";

export default function StudentPlansPage() {
  return (
    <Suspense fallback={<div className="py-12 text-center text-sm text-text-muted">Loading weekly plans…</div>}>
      <WeeklyPlans />
    </Suspense>
  );
}

