"use client";

import { createPortal } from "react-dom";
import { AlertTriangle, CheckCircle2, Info, Trash2, X } from "lucide-react";
import { cn } from "@/lib/utils";

type Variant = "confirm" | "danger" | "success" | "info";

interface Props {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: Variant;
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  extra?: React.ReactNode;
}

const config: Record<Variant, { icon: React.ReactNode; confirmClass: string; iconBg: string }> = {
  confirm: {
    icon: <CheckCircle2 className="h-6 w-6 text-teal-600" />,
    confirmClass: "bg-teal-600 hover:bg-teal-700 focus:ring-teal-500",
    iconBg: "bg-teal-50",
  },
  danger: {
    icon: <Trash2 className="h-6 w-6 text-red-600" />,
    confirmClass: "bg-red-600 hover:bg-red-700 focus:ring-red-500",
    iconBg: "bg-red-50",
  },
  success: {
    icon: <CheckCircle2 className="h-6 w-6 text-emerald-600" />,
    confirmClass: "bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500",
    iconBg: "bg-emerald-50",
  },
  info: {
    icon: <Info className="h-6 w-6 text-blue-600" />,
    confirmClass: "bg-blue-600 hover:bg-blue-700 focus:ring-blue-500",
    iconBg: "bg-blue-50",
  },
};

export default function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  variant = "confirm",
  loading = false,
  onConfirm,
  onCancel,
  extra,
}: Props) {
  if (!open) return null;

  const { icon, confirmClass, iconBg } = config[variant];

  const panel = (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 z-[9998] bg-black/50 backdrop-blur-sm"
        onClick={onCancel}
      />
      {/* Dialog */}
      <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4">
        <div className="w-full max-w-md animate-in fade-in zoom-in-95 duration-200 rounded-2xl bg-white shadow-2xl dark:bg-slate-900">
          {/* Header */}
          <div className="flex items-start gap-4 p-6 pb-4">
            <div className={cn("flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl", iconBg)}>
              {icon}
            </div>
            <div className="min-w-0 flex-1 pt-0.5">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">{title}</h3>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">{message}</p>
            </div>
            <button
              type="button"
              onClick={onCancel}
              className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 transition-colors"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {/* Actions */}
          {extra && (
            <div className="px-6 pb-2">
              {extra}
            </div>
          )}
          <div className="flex gap-3 border-t border-slate-100 dark:border-slate-800 px-6 py-4">
            <button
              type="button"
              onClick={onCancel}
              disabled={loading}
              className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors disabled:opacity-50"
            >
              {cancelLabel}
            </button>
            <button
              type="button"
              onClick={onConfirm}
              disabled={loading}
              className={cn(
                "flex-1 rounded-xl py-2.5 text-sm font-semibold text-white shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-60",
                confirmClass
              )}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
                  </svg>
                  Processing…
                </span>
              ) : confirmLabel}
            </button>
          </div>
        </div>
      </div>
    </>
  );

  return typeof window !== "undefined" ? createPortal(panel, document.body) : null;
}
