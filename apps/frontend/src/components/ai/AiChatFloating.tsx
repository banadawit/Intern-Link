"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { MessageCircle, X, Maximize2, Minimize2, Trash2 } from "lucide-react";
import AIChat, { type AiChatRole } from "@/components/ai/AIChat";
import { cn } from "@/lib/utils";

const MIN_W = 280;
const MAX_W = 700;
const MIN_H = 260;
const MAX_H = typeof window !== "undefined" ? window.innerHeight - 120 : 700;
const EXPANDED_MIN_W = 320;
const EXPANDED_MAX_W = typeof window !== "undefined" ? window.innerWidth - 64 : 900;

export default function AiChatFloating({ role }: { role: AiChatRole }) {
  const [open, setOpen] = useState(false);
  const [expanded, setExpanded] = useState(false);

  // Resizable dimensions for the floating panel
  const [panelW, setPanelW] = useState(352);
  const [panelH, setPanelH] = useState(420);
  // Resizable width for the expanded panel
  const [expandedW, setExpandedW] = useState(420);

  const clearRef = useRef<(() => void) | null>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  // ── Drag-to-resize: expanded panel left edge ───────────────────────────────
  const startResizeExpanded = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.clientX;
    const startW = expandedW;

    const onMove = (ev: MouseEvent) => {
      const delta = startX - ev.clientX; // dragging left = wider
      const maxW = window.innerWidth - 64; // leave at least 64px for content
      setExpandedW(Math.min(maxW, Math.max(MIN_W, startW + delta)));
    };
    const onUp = () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, [expandedW]);

  // ── Drag-to-resize: left edge (width) ──────────────────────────────────────
  const startResizeW = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.clientX;
    const startW = panelW;

    const onMove = (ev: MouseEvent) => {
      const delta = startX - ev.clientX; // dragging left = wider
      setPanelW(Math.min(MAX_W, Math.max(MIN_W, startW + delta)));
    };
    const onUp = () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, [panelW]);

  // ── Drag-to-resize: top edge (height) ──────────────────────────────────────
  const startResizeH = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startY = e.clientY;
    const startH = panelH;

    const onMove = (ev: MouseEvent) => {
      const delta = startY - ev.clientY; // dragging up = taller
      const maxH = window.innerHeight - 120;
      setPanelH(Math.min(maxH, Math.max(MIN_H, startH + delta)));
    };
    const onUp = () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, [panelH]);

  // ── Drag-to-resize: top-left corner (both) ─────────────────────────────────
  const startResizeCorner = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.clientX;
    const startY = e.clientY;
    const startW = panelW;
    const startH = panelH;

    const onMove = (ev: MouseEvent) => {
      const dw = startX - ev.clientX;
      const dh = startY - ev.clientY;
      const maxH = window.innerHeight - 120;
      setPanelW(Math.min(MAX_W, Math.max(MIN_W, startW + dw)));
      setPanelH(Math.min(maxH, Math.max(MIN_H, startH + dh)));
    };
    const onUp = () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
  }, [panelW, panelH]);

  // Keep max height in sync with window resize
  useEffect(() => {
    const onResize = () => {
      const maxH = window.innerHeight - 120;
      setPanelH((h) => Math.min(h, maxH));
    };
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  return (
    <>
      {/* Toggle button — hidden when expanded */}
      {!expanded && (
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
      )}

      {/* ── Floating compact/resizable panel ── */}
      {open && !expanded && (
        <div
          ref={panelRef}
          className="fixed bottom-24 right-5 z-[60] flex flex-col rounded-2xl border border-slate-200 bg-white shadow-2xl overflow-hidden"
          style={{ width: panelW, height: panelH }}
          role="dialog"
          aria-label="AI assistant chat"
        >
          {/* Top resize handle */}
          <div
            onMouseDown={startResizeH}
            className="absolute top-0 left-4 right-4 h-1.5 cursor-n-resize rounded-full bg-transparent hover:bg-primary-200 transition-colors z-10"
            title="Drag to resize height"
          />

          {/* Left resize handle */}
          <div
            onMouseDown={startResizeW}
            className="absolute top-4 bottom-4 left-0 w-1.5 cursor-w-resize rounded-full bg-transparent hover:bg-primary-200 transition-colors z-10"
            title="Drag to resize width"
          />

          {/* Top-left corner handle */}
          <div
            onMouseDown={startResizeCorner}
            className="absolute top-0 left-0 h-4 w-4 cursor-nw-resize z-20"
            title="Drag to resize"
          />
          <div className="flex shrink-0 items-center justify-between border-b border-slate-100 bg-slate-50 px-4 py-2.5">
            <div className="flex items-center gap-2">
              <MessageCircle className="h-4 w-4 text-primary-600" />
              <span className="text-sm font-semibold text-slate-900">InternLink AI</span>
            </div>
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => clearRef.current?.()}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Clear chat history"
                title="Clear history"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                onClick={() => setExpanded(true)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Expand to full panel"
                title="Expand"
              >
                <Maximize2 className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Close AI assistant"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

          {/* Chat — fills remaining height */}
          <div className="min-h-0 flex-1 flex flex-col overflow-hidden">
            <AIChat
              variant="floating"
              role={role}
              hideHeader
              fillHeight
              onClearRef={(fn) => { clearRef.current = fn; }}
            />
          </div>
        </div>
      )}

      {/* ── Expanded full right-panel ── */}
      {expanded && (
        <div
          className="fixed inset-y-0 right-0 z-[60] flex flex-col border-l border-slate-200 bg-white shadow-2xl"
          style={{ width: expandedW }}
          role="dialog"
          aria-label="AI assistant chat"
        >
          {/* Left resize handle for expanded panel */}
          <div
            onMouseDown={startResizeExpanded}
            className="absolute inset-y-0 left-0 w-1.5 cursor-w-resize hover:bg-primary-200 transition-colors z-10"
            title="Drag to resize width"
          />
          <div className="flex shrink-0 items-center justify-between border-b border-slate-100 bg-slate-50 px-5 py-3.5">
            <div className="flex items-center gap-2">
              <MessageCircle className="h-5 w-5 text-primary-600" />
              <span className="text-base font-semibold text-slate-900">InternLink AI</span>
            </div>
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => clearRef.current?.()}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Clear chat history"
                title="Clear history"
              >
                <Trash2 className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => setExpanded(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Collapse to floating"
                title="Collapse"
              >
                <Minimize2 className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => { setExpanded(false); setOpen(false); }}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors"
                aria-label="Close AI assistant"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
          <div className="min-h-0 flex-1 flex flex-col overflow-hidden">
            <AIChat
              variant="expanded"
              role={role}
              hideHeader
              fillHeight
              onClearRef={(fn) => { clearRef.current = fn; }}
            />
          </div>
        </div>
      )}
    </>
  );
}
