"use client";

import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { CheckCircle2, X } from "lucide-react";
import { cn } from "@/lib/utils";

interface Props {
  message: string;
  show: boolean;
  onClose: () => void;
  duration?: number;
}

export default function SuccessToast({ message, show, onClose, duration = 3000 }: Props) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (show) {
      setVisible(true);
      const t = setTimeout(() => {
        setVisible(false);
        setTimeout(onClose, 300);
      }, duration);
      return () => clearTimeout(t);
    }
  }, [show, duration, onClose]);

  if (!show && !visible) return null;

  const toast = (
    <div
      className={cn(
        "fixed bottom-6 left-1/2 z-[99999] -translate-x-1/2 transition-all duration-300",
        visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
      )}
    >
      <div className="flex items-center gap-3 rounded-2xl bg-slate-900 px-5 py-3.5 shadow-2xl dark:bg-slate-800">
        <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-500">
          <CheckCircle2 className="h-4 w-4 text-white" />
        </div>
        <p className="text-sm font-semibold text-white">{message}</p>
        <button
          type="button"
          onClick={() => { setVisible(false); setTimeout(onClose, 300); }}
          className="ml-1 rounded-lg p-1 text-slate-400 hover:text-white transition-colors"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  );

  return typeof window !== "undefined" ? createPortal(toast, document.body) : null;
}
