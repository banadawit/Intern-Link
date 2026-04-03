"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { Send, Loader2, Sparkles, Trash2, Copy, Pencil } from "lucide-react";
import api from "@/lib/api/client";
import type { AiChatResponse } from "@/lib/ai/types";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";

export type AiChatRole = "student" | "supervisor" | "coordinator" | "hod" | "admin";

type ChatMsg = { role: "user" | "assistant"; content: string };

type Props = {
  variant: "floating" | "page";
  role: AiChatRole;
  className?: string;
  /** Shown in page variant header */
  title?: string;
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

export default function AIChat({ variant, role, className, title = "InternLink AI" }: Props) {
  const { user } = useAuth();
  const effectiveRole = mapAuthRoleToChatRole(user?.role) ?? role;

  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [hydrating, setHydrating] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const loadHistory = useCallback(async () => {
    setHydrating(true);
    setError(null);
    try {
      const { data } = await api.get<{ success: boolean; data?: { messages: ChatMsg[] }; message?: string }>(
        "/ai/chat/history",
        { params: { limit: 100 } }
      );
      if (data.success && data.data?.messages?.length) {
        setMessages(data.data.messages);
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

  const clearHistory = async () => {
    if (!confirm("Clear all saved chat messages on the server?")) return;
    setError(null);
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
    const userMsg: ChatMsg = { role: "user", content: text };
    const prior = messages;
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);
    try {
      const conversationHistory = prior.map((m) => ({ role: m.role, content: m.content }));
      const { data } = await api.post<AiChatResponse>("/ai/chat", {
        message: text,
        conversationHistory,
        role: user?.role,
      });
      const reply = data.data?.reply ?? (data as { reply?: string }).reply;
      if (!data.success || !reply) {
        setError(data.message ?? "Chat failed.");
        setMessages(prior);
        return;
      }
      setMessages((prev) => [...prev, { role: "assistant", content: reply }]);
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

  const shell = variant === "floating" ? "flex flex-col overflow-hidden" : "flex min-h-[min(70vh,32rem)] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm";

  return (
    <div className={cn(shell, className)}>
      {variant === "page" && (
        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 bg-slate-50 px-4 py-3">
          <div className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-primary-600" aria-hidden />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">{title}</h1>
              <p className="text-xs text-slate-500">
                Chat naturally. You can edit or copy replies before using them elsewhere.
              </p>
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
        {variant === "floating" && (
          <div className="flex items-center gap-2 border-b border-slate-100 bg-slate-50 px-4 py-3">
            <Sparkles className="h-4 w-4 text-primary-600" aria-hidden />
            <span className="text-sm font-semibold text-slate-900">{title}</span>
          </div>
        )}

        <div
          className={cn(
            "min-h-0 flex-1 overflow-y-auto px-3 py-2",
            variant === "floating" ? "max-h-72 min-h-[200px]" : "px-4 py-4"
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
                  "mb-3 rounded-xl px-3 py-2 text-sm",
                  m.role === "user" ? "ml-4 bg-primary-50 text-slate-900" : "mr-4 bg-slate-100 text-slate-800"
                )}
              >
                <div className="mb-1 flex items-center justify-between gap-2">
                  <span className="block text-[10px] font-semibold uppercase text-slate-500">
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
                    className="mt-1 w-full min-h-[100px] rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-sm text-slate-900"
                    aria-label="Edit assistant message"
                  />
                ) : (
                  <span className="whitespace-pre-wrap">{m.content}</span>
                )}
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
