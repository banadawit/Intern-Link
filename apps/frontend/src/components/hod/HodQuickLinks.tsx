"use client";

import Link from "next/link";
import {
  Users,
  Building2,
  Send,
  Mail,
  FileText,
  FileCheck,
  ChevronRight,
} from "lucide-react";

const links = [
  { href: "/hod/students", label: "Student approvals", desc: "Review department registrations", icon: Users },
  { href: "/hod/companies", label: "Companies", desc: "Verified company directory", icon: Building2 },
  { href: "/hod/placements", label: "Placements", desc: "Send proposals and track status", icon: Send },
  { href: "/hod/invite", label: "Invite company", desc: "Email a company to join InternLink", icon: Mail },
  { href: "/hod/open-letters", label: "Open letters", desc: "External internship requests", icon: FileCheck },
  { href: "/hod/reports", label: "Final reports", desc: "Stamped PDFs and downloads", icon: FileText },
];

export default function HodQuickLinks() {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-lg font-bold text-slate-900">Department tools</h2>
      <p className="mt-1 text-sm text-slate-500">Jump to a section from the sidebar or below.</p>
      <ul className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {links.map((item) => (
          <li key={item.href}>
            <Link
              href={item.href}
              className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 text-left transition-colors hover:border-primary-200 hover:bg-primary-50/40"
            >
              <span className="flex min-w-0 items-center gap-3">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary-50 text-primary-600">
                  <item.icon className="h-5 w-5" aria-hidden />
                </span>
                <span className="min-w-0">
                  <span className="block font-semibold text-slate-900">{item.label}</span>
                  <span className="block truncate text-xs text-slate-500">{item.desc}</span>
                </span>
              </span>
              <ChevronRight className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
