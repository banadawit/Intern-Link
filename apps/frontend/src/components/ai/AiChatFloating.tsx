"use client";

import React, { useState } from "react";
import { MessageCircle, X } from "lucide-react";
import AIChat, { type AiChatRole } from "@/components/ai/AIChat";
import { cn } from "@/lib/utils";

export default function AiChatFloating({ role }: { role: AiChatRole }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "fixed bottom-5 right-5 z-[60] flex h-14 w-14 items-center justify-center rounded-full shadow-lg transition-all",
          "bg-primary-600 text-white hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-400 focus:ring-offset-2",
          open && "ring-2 ring-primary-300"
        )}
        aria-expanded={open}
        aria-label={open ? "Close AI assistant" : "Open AI assistant"}
      >
        {open ? <X className="h-6 w-6" /> : <MessageCircle className="h-6 w-6" />}
      </button>

      {open && (
        <div
          className="fixed bottom-24 right-5 z-[60] w-[min(100vw-2rem,22rem)]"
          role="dialog"
          aria-label="AI assistant chat"
        >
          <AIChat variant="floating" role={role} title="InternLink AI" />
        </div>
      )}
    </>
  );
}
