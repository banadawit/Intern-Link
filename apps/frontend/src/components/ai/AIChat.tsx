"use client";
// AIChat v3 — with session history sidebar + new chat

import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  Send, Loader2, Sparkles, Trash2, Copy, Pencil,
  Plus, MessageSquare, Check, X, Bot, History, ChevronLeft,
} from "lucide-react";
import api from "@/lib/api/client";
import type { AiChatResponse } from "@/lib/ai/types";
import { formatAiReplyForDisplay } from "@/lib/ai/formatAiReply";
import { cn } from "@/lib/utils";
import { useAuth } from "@/lib/hooks/useAuth";

export type AiChatRole = "student" | "supervisor" | "coordinator" | "hod" | "admin" | "visitor";

type ChatMsg = { role: "user" | "assistant"; content: string };

// ── Session types ─────────────────────────────────────────────────────────────
type ChatSession = {
  id: string;
  title: string;
  messages: ChatMsg[];
  createdAt: string;
};

const SESSIONS_KEY = "ai_chat_sessions";

function loadSessions(): ChatSession[] {
  if (typeof window === "undefined") return [];
  try { return JSON.parse(localStorage.getItem(SESSIONS_KEY) ?? "[]"); } catch { return []; }
}

function saveSessions(sessions: ChatSession[]) {
  if (typeof window === "undefined") return;
  localStorage.setItem(SESSIONS_KEY, JSON.stringify(sessions.slice(0, 30)));
}

function generateTitle(messages: ChatMsg[]): string {
  const first = messages.find((m) => m.role === "user")?.content ?? "New chat";
  return first.slice(0, 50) + (first.length > 50 ? "…" : "");
}

type Props = {
  variant: "floating" | "page" | "expanded";
  role: AiChatRole;
  className?: string;
  title?: string;
  hideHeader?: boolean;
  fillHeight?: boolean;
  onClearRef?: (fn: () => void) => void;
};

function mapAuthRoleToChatRole(role?: string): AiChatRole | null {
  const map: Record<string, AiChatRole> = {
    STUDENT: "student", SUPERVISOR: "supervisor",
    COORDINATOR: "coordinator", HOD: "hod", ADMIN: "admin",
  };
  return role ? (map[role] ?? null) : null;
}

// ── Inline bold renderer ──────────────────────────────────────────────────────
function renderInline(text: string, key: string) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return (
    <span key={key}>
      {parts.map((part, pi) =>
        part.startsWith("**") && part.endsWith("**") ? (
          <strong key={pi} className="font-bold text-slate-900 dark:text-slate-100">
            {part.slice(2, -2)}
          </strong>
        ) : (
          <span key={pi}>{part}</span>
        )
      )}
    </span>
  );
}

// ── Message content renderer ──────────────────────────────────────────────────
function MessageContent({ content }: { content: string }) {
  const lines = content.split("\n");
  return (
    <div className="space-y-1.5">
      {lines.map((line, idx) => {
        const t = line.trim();
        if (!t) return <div key={`${idx}-empty`} className="h-1" />;
        if (/^\*\*[^*]+\*\*$/.test(t)) {
          return (
            <p key={`${idx}-h`} className="pt-2 pb-0.5 text-[15px] font-extrabold text-slate-900 dark:text-slate-100">
              {t.slice(2, -2)}
            </p>
          );
        }
        if (t.startsWith("• ")) {
          return (
            <div key={`${idx}-b`} className="flex items-start gap-2 ml-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary-500" />
              <p className="text-sm leading-relaxed text-slate-800 dark:text-slate-200">
                {renderInline(t.slice(2), `${idx}-bi`)}
              </p>
            </div>
          );
        }
        const numMatch = t.match(/^(\d+)\.\s+(.+)$/);
        if (numMatch) {
          return (
            <div key={`${idx}-n`} className="flex items-start gap-2 ml-2">
              <span className="mt-0.5 shrink-0 text-xs font-bold text-primary-600 dark:text-primary-400 min-w-[18px]">{numMatch[1]}.</span>
              <p className="text-sm leading-relaxed text-slate-800 dark:text-slate-200">
                {renderInline(numMatch[2], `${idx}-ni`)}
              </p>
            </div>
          );
        }
        return (
          <p key={`${idx}-p`} className="text-sm leading-relaxed text-slate-800 dark:text-slate-200">
            {renderInline(line, `${idx}-pi`)}
          </p>
        );
      })}
    </div>
  );
}

// ── Confirm dialog ────────────────────────────────────────────────────────────
function ConfirmModal({
  title, message, confirmLabel = "Delete", onConfirm, onCancel,
}: {
  title: string; message: string; confirmLabel?: string;
  onConfirm: () => void; onCancel: () => void;
}) {
  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="w-full max-w-sm rounded-2xl bg-white dark:bg-slate-900 p-6 shadow-2xl mx-4 space-y-4 border border-slate-200 dark:border-slate-700">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400">
            <Trash2 className="h-5 w-5" />
          </div>
          <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">{title}</h3>
        </div>
        <p className="text-sm text-slate-500 dark:text-slate-400">{message}</p>
        <div className="flex gap-3 pt-1">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 transition-colors"
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Suggested prompts ─────────────────────────────────────────────────────────
const SUGGESTED_PROMPTS = [
  "📅 Suggest a weekly plan for my project",
  "✅ What tasks should I focus on today?",
  "📊 Summarize my progress so far",
  "🚧 I'm facing a blocker, can you help?",
];

// ── Main component ────────────────────────────────────────────────────────────
export default function AIChat({
  variant, role, className, title = "InternLink AI",
  hideHeader = false, fillHeight = false, onClearRef,
}: Props) {
  const { user } = useAuth();
  const effectiveRole = role === "visitor" ? "visitor" : (mapAuthRoleToChatRole(user?.role) ?? role);

  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [hydrating, setHydrating] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);
  const [liveTyping, setLiveTyping] = useState<{ index: number; full: string; pos: number } | null>(null);
  const [showClearConfirm, setShowClearConfirm] = useState(false);
  const [showNewChatConfirm, setShowNewChatConfirm] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [deleteSessionId, setDeleteSessionId] = useState<string | null>(null);

  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = () => bottomRef.current?.scrollIntoView({ behavior: "smooth" });

  // Typing animation
  useEffect(() => {
    if (!liveTyping) return;
    if (liveTyping.pos >= liveTyping.full.length) { setLiveTyping(null); return; }
    const delay = liveTyping.full[liveTyping.pos] === "\n" ? 8 : 4;
    const t = setTimeout(() => setLiveTyping((p) => p ? { ...p, pos: p.pos + 1 } : null), delay);
    return () => clearTimeout(t);
  }, [liveTyping]);

  useEffect(() => { if (liveTyping) scrollToBottom(); }, [liveTyping?.pos, liveTyping?.index]);

  const loadHistory = useCallback(async () => {
    setHydrating(true);
    try {
      const { data } = await api.get<{ success: boolean; data: { messages: ChatMsg[] } }>("/ai/chat/history");
      setMessages(
        (data.data?.messages ?? []).map((m) =>
          m.role === "assistant" ? { ...m, content: formatAiReplyForDisplay(m.content) } : m
        )
      );
    } catch { /* ignore */ }
    finally { setHydrating(false); }
  }, []);

  useEffect(() => { void loadHistory(); }, [loadHistory]);

  useEffect(() => {
    if (onClearRef) onClearRef(clearHistory);
  }, [onClearRef]);

  const clearHistory = async () => {
    setShowClearConfirm(false);
    setError(null);
    try {
      await api.delete("/ai/chat/history");
      setMessages([]);
      setLiveTyping(null);
    } catch { setError("Could not clear history."); }
  };

  const startNewChat = () => {
    setShowNewChatConfirm(false);
    // Save current messages as a session before clearing
    if (messages.length > 0) {
      const session: ChatSession = {
        id: Date.now().toString(),
        title: generateTitle(messages),
        messages: [...messages],
        createdAt: new Date().toISOString(),
      };
      const updated = [session, ...loadSessions()];
      saveSessions(updated);
      setSessions(updated);
    }
    setMessages([]);
    setLiveTyping(null);
    setError(null);
    inputRef.current?.focus();
  };

  // Load sessions from localStorage on mount
  useEffect(() => { setSessions(loadSessions()); }, []);

  const restoreSession = (session: ChatSession) => {
    if (messages.length > 0) {
      const current: ChatSession = {
        id: Date.now().toString(),
        title: generateTitle(messages),
        messages: [...messages],
        createdAt: new Date().toISOString(),
      };
      const updated = [current, ...sessions.filter((s) => s.id !== session.id)];
      saveSessions(updated);
      setSessions(updated);
    }
    setMessages(session.messages);
    setShowHistory(false);
    setLiveTyping(null);
  };

  const deleteSession = (id: string) => {
    const updated = sessions.filter((s) => s.id !== id);
    saveSessions(updated);
    setSessions(updated);
    setDeleteSessionId(null);
  };

  const sendMessage = useCallback(async (text?: string) => {
    const msg = (text ?? input).trim();
    if (!msg || loading) return;
    setInput("");
    setError(null);
    const userMsg: ChatMsg = { role: "user", content: msg };
    const prior = messages;
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);
    try {
      const conversationHistory = prior.map((m) => ({ role: m.role, content: m.content }));
      const { data } = await api.post<AiChatResponse>("/ai/chat", {
        message: msg, conversationHistory, role: effectiveRole,
      });
      const reply = data.reply ?? data.data?.reply ?? "";
      if (!reply) throw new Error("Empty response");
      const assistantIndex = prior.length + 1;
      const cleaned = formatAiReplyForDisplay(reply);
      setMessages((prev) => [...prev, { role: "assistant", content: cleaned }]);
      setLiveTyping({ index: assistantIndex, full: cleaned, pos: 0 });
      setTimeout(scrollToBottom, 100);
    } catch (e: unknown) {
      const msg2 = e && typeof e === "object" && "response" in e
        ? String((e as { response?: { data?: { message?: string } } }).response?.data?.message ?? "")
        : "";
      setError(msg2 || "Could not reach the AI. Please try again.");
      setMessages((prev) => prev.slice(0, -1));
    } finally { setLoading(false); }
  }, [input, loading, messages, effectiveRole]);

  const copyText = async (t: string, idx: number) => {
    try {
      await navigator.clipboard.writeText(t);
      setCopiedIndex(idx);
      setTimeout(() => setCopiedIndex(null), 2000);
    } catch { /* ignore */ }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); void sendMessage(); }
  };

  const isEmpty = messages.length === 0 && !hydrating;

  const shell =
    variant === "floating" && !fillHeight
      ? "flex flex-col overflow-hidden"
      : variant === "expanded" || fillHeight
        ? "flex h-full flex-col overflow-hidden"
        : "flex min-h-[min(70vh,32rem)] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900";

  return (
    <div className={cn(shell, className)}>
      {/* ── Header ── */}
      {!hideHeader && (variant === "page" || variant === "floating") && (
        <div className={cn(
          "flex items-center justify-between gap-2 border-b border-slate-100 dark:border-slate-700 px-4 py-3",
          variant === "page"
            ? "bg-gradient-to-r from-primary-50 to-slate-50 dark:from-primary-900/20 dark:to-slate-900"
            : "bg-slate-50 dark:bg-slate-950"
        )}>
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-primary-600 shadow-sm">
              <Bot className="h-4 w-4 text-white" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900 dark:text-slate-100">{title}</p>
              <p className="text-[10px] text-slate-500 dark:text-slate-400 flex items-center gap-1">
                <span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500" />
                Online · Powered by Groq
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1">
            {/* History */}
            <button
              type="button"
              title="Chat history"
              onClick={() => setShowHistory((v) => !v)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs font-medium transition-colors",
                showHistory
                  ? "border-primary-300 bg-primary-50 text-primary-700 dark:border-primary-700 dark:bg-primary-900/30 dark:text-primary-300"
                  : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              )}
            >
              <History className="h-3.5 w-3.5" />
              <span>History</span>
              {sessions.length > 0 && (
                <span className="ml-0.5 rounded-full bg-primary-100 dark:bg-primary-900/50 px-1.5 py-0.5 text-[10px] font-bold text-primary-700 dark:text-primary-300">
                  {sessions.length}
                </span>
              )}
            </button>
            {/* New chat */}
            <button
              type="button"
              title="New chat"
              onClick={() => messages.length > 0 ? setShowNewChatConfirm(true) : startNewChat()}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-2.5 py-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-primary-50 hover:text-primary-700 hover:border-primary-200 dark:hover:bg-primary-900/20 dark:hover:text-primary-300 transition-colors"
            >
              <Plus className="h-3.5 w-3.5" />
              <span>New chat</span>
            </button>
            {/* Clear history */}
            <button
              type="button"
              title="Clear history"
              onClick={() => messages.length > 0 ? setShowClearConfirm(true) : undefined}
              disabled={messages.length === 0}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-2.5 py-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-red-50 hover:text-red-600 hover:border-red-200 dark:hover:bg-red-950/30 dark:hover:text-red-400 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              <Trash2 className="h-3.5 w-3.5" />
              <span>Clear</span>
            </button>
          </div>
        </div>
      )}

      {/* ── History sidebar ── */}
      {showHistory && (
        <div className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-950">
          <div className="flex items-center justify-between px-4 py-2.5">
            <p className="text-xs font-bold uppercase tracking-wide text-slate-500 dark:text-slate-400">
              💬 Previous chats ({sessions.length})
            </p>
            <button
              type="button"
              onClick={() => setShowHistory(false)}
              className="rounded-lg p-1 text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-800"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
          </div>
          {sessions.length === 0 ? (
            <p className="px-4 pb-3 text-xs text-slate-400 dark:text-slate-500">No saved chats yet. Start a new chat to save history.</p>
          ) : (
            <div className="max-h-52 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800">
              {sessions.map((s) => (
                <div key={s.id} className="flex items-center gap-2 px-4 py-2.5 hover:bg-white dark:hover:bg-slate-900 transition-colors group">
                  <button
                    type="button"
                    onClick={() => restoreSession(s)}
                    className="flex-1 min-w-0 text-left"
                  >
                    <p className="truncate text-xs font-medium text-slate-800 dark:text-slate-200">{s.title}</p>
                    <p className="text-[10px] text-slate-400 dark:text-slate-500 mt-0.5">
                      {new Date(s.createdAt).toLocaleDateString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                      {" · "}{s.messages.length} messages
                    </p>
                  </button>
                  <button
                    type="button"
                    onClick={() => setDeleteSessionId(s.id)}
                    className="shrink-0 rounded p-1 text-slate-300 hover:text-red-500 dark:text-slate-600 dark:hover:text-red-400 opacity-0 group-hover:opacity-100 transition-all"
                    title="Delete session"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ── Messages area ── */}
      <div className={cn(
        "min-h-0 flex-1 overflow-y-auto overscroll-contain",
        !fillHeight && variant === "floating" ? "max-h-72 min-h-[200px] px-3 py-2" : "px-4 py-4"
      )}>
        {hydrating ? (
          <div className="flex h-full items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-primary-400" />
          </div>
        ) : isEmpty ? (
          /* ── Welcome screen ── */
          <div className="flex flex-col items-center justify-center py-8 text-center space-y-5">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 to-primary-700 shadow-lg shadow-primary-900/20">
              <Sparkles className="h-8 w-8 text-white" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">How can I help you?</h2>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 max-w-xs">
                Ask me anything about your internship, plans, or progress.
              </p>
            </div>
            {/* Suggested prompts */}
            <div className="grid grid-cols-1 gap-2 w-full max-w-sm sm:grid-cols-2">
              {SUGGESTED_PROMPTS.map((prompt) => (
                <button
                  key={prompt}
                  type="button"
                  onClick={() => void sendMessage(prompt)}
                  className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2.5 text-left text-xs font-medium text-slate-700 dark:text-slate-300 hover:border-primary-300 hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors"
                >
                  {prompt}
                </button>
              ))}
            </div>
          </div>
        ) : (
          /* ── Message list ── */
          <div className="space-y-4">
            {messages.map((m, i) => (
              <div
                key={`${i}-${m.role}-${m.content.slice(0, 12)}`}
                className={cn("flex gap-3", m.role === "user" ? "flex-row-reverse" : "flex-row")}
              >
                {/* Avatar */}
                <div className={cn(
                  "flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold",
                  m.role === "user"
                    ? "bg-primary-600 text-white"
                    : "bg-gradient-to-br from-primary-500 to-primary-700 text-white shadow-sm"
                )}>
                  {m.role === "user"
                    ? (user?.fullName?.slice(0, 1).toUpperCase() ?? "U")
                    : <Bot className="h-4 w-4" />
                  }
                </div>

                {/* Bubble */}
                <div className={cn(
                  "group relative max-w-[85%] rounded-2xl px-4 py-3 text-sm shadow-sm",
                  m.role === "user"
                    ? "bg-primary-600 text-white"
                    : "border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800"
                )}>
                  {/* Action buttons for assistant */}
                  {m.role === "assistant" && (
                    <div className="absolute -top-2 right-2 hidden group-hover:flex items-center gap-1 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-1.5 py-1 shadow-sm">
                      <button
                        type="button"
                        title="Edit"
                        className="rounded p-0.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800 dark:hover:text-slate-200"
                        onClick={() => setEditingIndex((x) => (x === i ? null : i))}
                      >
                        <Pencil className="h-3 w-3" />
                      </button>
                      <button
                        type="button"
                        title="Copy"
                        className="rounded p-0.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800 dark:hover:text-slate-200"
                        onClick={() => void copyText(m.content, i)}
                      >
                        {copiedIndex === i ? <Check className="h-3 w-3 text-emerald-500" /> : <Copy className="h-3 w-3" />}
                      </button>
                    </div>
                  )}

                  {/* Content */}
                  {m.role === "assistant" && editingIndex === i ? (
                    <textarea
                      value={m.content}
                      rows={4}
                      onChange={(e) => {
                        const v = e.target.value;
                        setMessages((prev) => prev.map((x, j) => (j === i ? { ...x, content: v } : x)));
                      }}
                      className="w-full min-h-[110px] rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
                    />
                  ) : m.role === "assistant" ? (
                    <>
                      <MessageContent
                        content={
                          liveTyping && liveTyping.index === i
                            ? liveTyping.full.slice(0, liveTyping.pos)
                            : m.content
                        }
                      />
                      {liveTyping && liveTyping.index === i && liveTyping.pos < liveTyping.full.length && (
                        <span className="ml-0.5 inline-block h-4 w-0.5 animate-pulse bg-primary-500 align-middle" />
                      )}
                    </>
                  ) : (
                    <p className="text-sm leading-relaxed text-white">{m.content}</p>
                  )}
                </div>
              </div>
            ))}

            {/* Loading indicator */}
            {loading && (
              <div className="flex gap-3">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-primary-500 to-primary-700 text-white shadow-sm">
                  <Bot className="h-4 w-4" />
                </div>
                <div className="rounded-2xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800 px-4 py-3">
                  <div className="flex items-center gap-1.5">
                    <span className="h-2 w-2 rounded-full bg-primary-400 animate-bounce [animation-delay:0ms]" />
                    <span className="h-2 w-2 rounded-full bg-primary-400 animate-bounce [animation-delay:150ms]" />
                    <span className="h-2 w-2 rounded-full bg-primary-400 animate-bounce [animation-delay:300ms]" />
                  </div>
                </div>
              </div>
            )}

            <div ref={bottomRef} />
          </div>
        )}
      </div>

      {/* ── Error banner ── */}
      {error && (
        <div className="mx-4 mb-2 flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 dark:border-red-800 dark:bg-red-950/30 dark:text-red-300">
          <span className="flex-1">{error}</span>
          <button type="button" onClick={() => setError(null)} className="shrink-0 text-red-400 hover:text-red-600">
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}

      {/* ── Input area ── */}
      <div className="border-t border-slate-100 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3">
        <div className="flex items-end gap-2 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2 focus-within:border-primary-400 focus-within:ring-2 focus-within:ring-primary-500/20 transition-all">
          <textarea
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask me anything… (Shift+Enter for new line)"
            rows={1}
            className="flex-1 resize-none bg-transparent text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:outline-none max-h-32 overflow-y-auto"
            style={{ minHeight: "24px" }}
            onInput={(e) => {
              const el = e.currentTarget;
              el.style.height = "auto";
              el.style.height = `${Math.min(el.scrollHeight, 128)}px`;
            }}
          />
          <button
            type="button"
            onClick={() => void sendMessage()}
            disabled={!input.trim() || loading}
            className="shrink-0 flex h-8 w-8 items-center justify-center rounded-xl bg-primary-600 text-white hover:bg-primary-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors shadow-sm"
          >
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
          </button>
        </div>
        <p className="mt-1.5 text-center text-[10px] text-slate-400 dark:text-slate-500">
          AI can make mistakes. Review important information.
        </p>
      </div>

      {/* ── Confirm: Clear history ── */}
      {showClearConfirm && (
        <ConfirmModal
          title="Clear chat history?"
          message="All saved messages will be permanently deleted. This cannot be undone."
          confirmLabel="Clear history"
          onConfirm={() => void clearHistory()}
          onCancel={() => setShowClearConfirm(false)}
        />
      )}

      {/* ── Confirm: New chat ── */}
      {showNewChatConfirm && (
        <ConfirmModal
          title="Start a new chat?"
          message="Your current conversation will be saved to history. You can restore it anytime."
          confirmLabel="New chat"
          onConfirm={startNewChat}
          onCancel={() => setShowNewChatConfirm(false)}
        />
      )}

      {/* ── Confirm: Delete session ── */}
      {deleteSessionId && (
        <ConfirmModal
          title="Delete this chat?"
          message="This saved conversation will be permanently removed."
          confirmLabel="Delete"
          onConfirm={() => deleteSession(deleteSessionId)}
          onCancel={() => setDeleteSessionId(null)}
        />
      )}
    </div>
  );
}
