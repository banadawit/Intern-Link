"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { Send, Loader2, Sparkles, Trash2, Copy, Pencil } from "lucide-react";
import api from "@/lib/api/client";
import type { AiChatResponse } from "@/lib/ai/types";
import { formatAiReplyForDisplay } from "@/lib/ai/formatAiReply";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";

export type AiChatRole = "student" | "supervisor" | "coordinator" | "hod" | "admin" | "visitor";

type ChatMsg = { role: "user" | "assistant"; content: string };

type Props = {
  variant: "floating" | "page" | "expanded";
  role: AiChatRole;
  className?: string;
  title?: string;
  hideHeader?: boolean;
  /** Fill parent height instead of using fixed max-height (used inside resizable container) */
  fillHeight?: boolean;
  onClearRef?: (fn: () => void) => void;
};

function mapAuthRoleToChatRole(
  r: string | undefined
): AiChatRole | null {
  const x = r?.toUpperCase();
  if (x === "STUDENT") return "student";
  if (x === "SUPERVISOR") return "supervisor";
  if (x === "COORDINATOR") return "coordinator";
  if (x === "HOD") return "hod";
  if (x === "ADMIN") return "admin";
  return null;
}

export default function AIChat({ variant, role, className, title = "InternLink AI", hideHeader = false, fillHeight = false, onClearRef }: Props) {
  const { user } = useAuth();
  const effectiveRole = role === "visitor" ? "visitor" : (mapAuthRoleToChatRole(user?.role) ?? role);

  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [hydrating, setHydrating] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  /** In-memory typing effect for the latest assistant reply only (does not change stored content). */
  const [liveTyping, setLiveTyping] = useState<{ index: number; full: string; pos: number } | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    if (!liveTyping) return;
    if (liveTyping.pos >= liveTyping.full.length) {
      setLiveTyping(null);
      return;
    }
    const step = Math.max(1, Math.ceil(liveTyping.full.length / 400));
    const t = window.setTimeout(() => {
      setLiveTyping((s) => {
        if (!s) return null;
        const next = Math.min(s.pos + step, s.full.length);
        return next >= s.full.length ? null : { ...s, pos: next };
      });
    }, 12);
    return () => clearTimeout(t);
  }, [liveTyping]);

  useEffect(() => {
    if (liveTyping) scrollToBottom();
  }, [liveTyping?.pos, liveTyping?.index]);

  const loadHistory = useCallback(async () => {
    setHydrating(true);
    setError(null);
    setLiveTyping(null);
    try {
      const { data } = await api.get<{ success: boolean; data?: { messages: ChatMsg[] }; message?: string }>(
        "/ai/chat/history",
        { params: { limit: 100 } }
      );
      if (data.success && data.data?.messages?.length) {
        setMessages(
          data.data.messages.map((m) =>
            m.role === "assistant" ? { ...m, content: formatAiReplyForDisplay(m.content) } : m
          )
        );
      } else {
        setMessages([]);
      }
    } catch {
      setMessages([]);
    } finally {
      setHydrating(false);
    }
  }, []);

  useEffect(() => {
    void loadHistory();
  }, [loadHistory]);

  // Expose clearHistory to parent via ref callback
  useEffect(() => {
    if (onClearRef) onClearRef(clearHistory);
  }, [onClearRef]);

  const clearHistory = async () => {
    if (!confirm("Clear all saved chat messages on the server?")) return;
    setError(null);
    setLiveTyping(null);
    try {
      await api.delete("/ai/chat/history");
      setMessages([]);
    } catch (e: unknown) {
      const msg =
        e && typeof e === "object" && "response" in e
          ? (e as { response?: { data?: { message?: string } } }).response?.data?.message
          : "Failed to clear.";
      setError(msg ?? "Failed to clear.");
    }
  };

  const send = useCallback(async () => {
    const text = input.trim();
    if (!text || loading) return;
    setError(null);
    setInput("");
    setLiveTyping(null);
    const userMsg: ChatMsg = { role: "user", content: text };
    const prior = messages;
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);
    try {
      const conversationHistory = prior.map((m) => ({ role: m.role, content: m.content }));
      const { data } = await api.post<AiChatResponse>("/ai/chat", {
        message: text,
        conversationHistory,
        role: effectiveRole,
      });
      const reply = data.data?.reply ?? (data as { reply?: string }).reply;
      if (!data.success || !reply) {
        setError(data.message ?? "Chat failed.");
        setMessages(prior);
        return;
      }
      const assistantIndex = prior.length + 1;
      const cleaned = formatAiReplyForDisplay(reply);
      setMessages((prev) => [...prev, { role: "assistant", content: cleaned }]);
      setLiveTyping({ index: assistantIndex, full: cleaned, pos: 0 });
      setTimeout(scrollToBottom, 100);
    } catch (e: unknown) {
      const msg =
        e && typeof e === "object" && "response" in e
          ? (e as { response?: { data?: { message?: string } } }).response?.data?.message
          : "Request failed.";
      setError(msg ?? "Request failed.");
      setMessages(prior);
    } finally {
      setLoading(false);
    }
  }, [input, loading, messages, user?.role]);

  const copyText = async (t: string) => {
    try {
      await navigator.clipboard.writeText(t);
    } catch {
      setError("Could not copy to clipboard.");
    }
  };

  const shell =
    variant === "floating" && !fillHeight
      ? "flex flex-col overflow-hidden"
      : variant === "expanded" || fillHeight
      ? "flex h-full flex-col overflow-hidden"
      : "flex min-h-[min(70vh,32rem)] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm";

  return (
    <div className={cn(shell, className)}>
      {variant === "page" && !hideHeader && (
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 bg-slate-50 px-4 py-3">
          <div className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-primary-600" aria-hidden />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">{title}</h1>
            </div>
          </div>
          <button
            type="button"
            onClick={() => void clearHistory()}
            className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50"
          >
            <Trash2 className="h-3.5 w-3.5" />
            Clear history
          </button>
        </div>
      )}

      <div
        className={cn(
          "flex min-h-0 flex-1 flex-col",
          variant === "floating" && "rounded-2xl border border-slate-200 bg-white shadow-2xl"
        )}
      >
        {variant === "floating" && !hideHeader && (
          <div className="flex items-center gap-2 border-b border-slate-100 bg-slate-50 px-4 py-3">
            <Sparkles className="h-4 w-4 text-primary-600" aria-hidden />
            <span className="text-sm font-semibold text-slate-900">{title}</span>
          </div>
        )}

        <div
          className={cn(
            "min-h-0 flex-1 overflow-y-auto overscroll-contain px-3 py-2",
            !fillHeight && variant === "floating" ? "max-h-72 min-h-[200px]" : "px-4 py-4"
          )}
        >
          {hydrating && (
            <p className="py-4 text-center text-xs text-slate-500">Loading conversation…</p>
          )}
          {!hydrating && messages.length === 0 && (
            <p className="py-6 text-center text-xs text-slate-500">
              Say hi, ask a question, or chat about anything you need.
            </p>
          )}
          {!hydrating &&
            messages.map((m, i) => (
              <div
                key={`${i}-${m.role}-${m.content.slice(0, 12)}`}
                className={cn(
                  "mb-4 flex",
                  m.role === "user" ? "justify-end" : "justify-start"
                )}
              >
                <div
                  className={cn(
                    "max-w-[88%] rounded-2xl px-4 py-3 text-sm shadow-sm",
                    m.role === "user"
                      ? "bg-primary-50 text-slate-900"
                      : "border border-slate-200 bg-slate-50 text-slate-800"
                  )}
                >
                  <div className="mb-2 flex items-center justify-between gap-3">
                    <span className="block text-[10px] font-semibold uppercase tracking-wide text-slate-500">
                      {m.role === "user" ? "You" : "Assistant"}
                    </span>
                    {m.role === "assistant" && (
                      <div className="flex gap-1">
                        <button
                          type="button"
                          className="rounded p-0.5 text-slate-500 hover:bg-slate-200 hover:text-slate-800"
                          aria-label="Edit reply"
                          onClick={() => setEditingIndex((x) => (x === i ? null : i))}
                        >
                          <Pencil className="h-3.5 w-3.5" />
                        </button>
                        <button
                          type="button"
                          className="rounded p-0.5 text-slate-500 hover:bg-slate-200 hover:text-slate-800"
                          aria-label="Copy reply"
                          onClick={() => void copyText(m.content)}
                        >
                          <Copy className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    )}
                  </div>
                  {m.role === "assistant" && editingIndex === i ? (
                    <textarea
                      value={m.content}
                      onChange={(e) => {
                        const v = e.target.value;
                        setMessages((prev) => prev.map((x, j) => (j === i ? { ...x, content: v } : x)));
                      }}
                      className="mt-1 w-full min-h-[110px] rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm leading-relaxed text-slate-900"
                      aria-label="Edit assistant message"
                    />
                  ) : (
                    <div className="text-[14px] leading-relaxed">
                      {(() => {
                        const visible =
                          m.role === "assistant" && liveTyping && liveTyping.index === i
                            ? liveTyping.full.slice(0, liveTyping.pos)
                            : m.content;
                        const lines = visible.split("\n");
                        const headingPattern =
                          /^(?:[•*-]\s*)?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday):\s*(.+)?$/i;
                        const sectionHeadingPattern =
                          /^(Key Deliverables|Suggested Daily\/Focus Areas|Important Notes):?\s*$/i;
                        const bulletPattern = /^•\s+/;

                        return (
                          <div className="space-y-1 whitespace-pre-wrap">
                            {lines.map((line, idx) => {
                              const headingMatch = line.trim().match(headingPattern);
                              if (headingMatch) {
                                const day = headingMatch[1];
                                const rest = headingMatch[2]?.trim();
                                return (
                                  <p key={`${idx}-${line}`} className="pt-1 text-[15px] font-extrabold text-slate-950">
                                    {rest ? `${day}: ${rest}` : `${day}:`}
                                  </p>
                                );
                              }
                              if (sectionHeadingPattern.test(line.trim())) {
                                const normalized = line.trim().replace(/:?\s*$/, ":");
                                return (
                                  <p key={`${idx}-${line}`} className="pt-1 text-[15px] font-extrabold text-slate-950">
                                    {normalized}
                                  </p>
                                );
                              }

                              if (!line.trim()) {
                                return <p key={`${idx}-empty`} className="h-1" />;
                              }

                              return (
                                <p
                                  key={`${idx}-${line}`}
                                  className={cn(
                                    "text-slate-800",
                                    bulletPattern.test(line.trim()) ? "ml-5" : "ml-4"
                                  )}
                                >
                                  {line}
                                </p>
                              );
                            })}
                            {m.role === "assistant" &&
                            liveTyping &&
                            liveTyping.index === i &&
                            liveTyping.pos < liveTyping.full.length ? (
                              <span
                                className="ml-px inline-block h-3.5 w-0.5 animate-pulse rounded-sm bg-primary-600 align-middle"
                                aria-hidden
                              />
                            ) : null}
                          </div>
                        );
                      })()}
                    </div>
                  )}
                </div>
              </div>
            ))}
          {loading && (
            <div className="flex items-center gap-2 py-2 text-xs text-slate-500">
              <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
              Thinking…
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {error && (
          <p className="border-t border-red-100 bg-red-50 px-3 py-2 text-xs text-red-700" role="alert">
            {error}
          </p>
        )}

        <div className="flex gap-2 border-t border-slate-100 p-3">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && (e.preventDefault(), void send())}
            placeholder="Type a message…"
            className="min-w-0 flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm"
            disabled={loading || hydrating}
            aria-label="Message"
          />
          <button
            type="button"
            disabled={loading || hydrating || !input.trim()}
            onClick={() => void send()}
            className="rounded-xl bg-primary-600 px-3 py-2 text-white hover:bg-primary-700 disabled:opacity-50"
            aria-label="Send"
          >
            <Send className="h-4 w-4" />
          </button>
        </div>
      </div>

      <p className="sr-only" aria-live="polite">
        Role context: {effectiveRole}
      </p>
    </div>
  );
}
