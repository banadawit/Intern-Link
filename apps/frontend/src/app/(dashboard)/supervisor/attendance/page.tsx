import { redirect } from "next/navigation";

/** Default attendance landing: student check-ins (heatmap). */
export default function SupervisorAttendanceIndexPage() {
  redirect("/supervisor/attendance/students");
}
