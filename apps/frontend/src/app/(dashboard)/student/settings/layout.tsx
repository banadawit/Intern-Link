import React from "react";
import StudentSettingsShell from "../StudentSettingsShell";

export default function StudentSettingsLayout({ children }: { children: React.ReactNode }) {
  return <StudentSettingsShell>{children}</StudentSettingsShell>;
}
