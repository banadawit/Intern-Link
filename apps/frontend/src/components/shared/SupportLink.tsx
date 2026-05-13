"use client";

import { useState } from "react";
import { HelpCircle } from "lucide-react";
import ContactSupportModal from "./ContactSupportModal";
import { useAuth } from "@/lib/hooks/useAuth";

export default function SupportLink() {
  const [open, setOpen] = useState(false);
  const { user } = useAuth();

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex w-full items-center gap-2 px-4 py-2 text-xs text-slate-400 hover:text-teal-600 dark:text-slate-500 dark:hover:text-teal-400 transition-colors"
      >
        <HelpCircle className="h-3.5 w-3.5 shrink-0" />
        Help & Support
      </button>
      <ContactSupportModal
        open={open}
        onClose={() => setOpen(false)}
        prefillName={user?.fullName ?? ""}
        prefillEmail={user?.email ?? ""}
      />
    </>
  );
}
