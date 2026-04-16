"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api/client";
import { useAuth } from "@/lib/hooks/useAuth";
import { Send, MessageSquare, Search } from "lucide-react";
import { cn } from "@/lib/utils";
import { format, isToday, isYesterday } from "date-fns";
import { useChatStore } from "@/lib/store/chatStore";

// ─── Types ───────────────────────────────────────────────────────────────────

type Contact = { id: number; full_name: string; role: string };

type Conversation = {
  partner: { id: number; full_name: string; role: string };
  lastMessage: { content: string; created_at: string; senderId: number } | null;
  unreadCount: number;
};

type Message = {
  id: number;
  content: string;
  created_at: string;
  senderId: number;
  receiverId: number;
  is_read: boolean;
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

function roleColor(role: string) {
  const map: Record<string, string> = {
    STUDENT: "bg-emerald-100 text-emerald-700",
    SUPERVISOR: "bg-blue-100 text-blue-700",
    HOD: "bg-violet-100 text-violet-700",
    COORDINATOR: "bg-teal-100 text-teal-700",
    ADMIN: "bg-slate-100 text-slate-700",
  };
  return map[role] ?? "bg-slate-100 text-slate-700";
}

function formatTime(dateStr: string) {
  const d = new Date(dateStr);
  if (isToday(d)) return format(d, "HH:mm");
  if (isYesterday(d)) return "Yesterday";
  return format(d, "MMM d");
}

function formatMessageTime(dateStr: string) {
  return format(new Date(dateStr), "HH:mm");
}

// ─── Component ───────────────────────────────────────────────────────────────

export default function ChatPage() {
  const { user } = useAuth();
  const { fetchUnread } = useChatStore();

  const [contacts, setContacts] = useState<Contact[]>([]);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [activeId, setActiveId] = useState<number | null>(null);
  const [input, setInput] = useState("");
  const [search, setSearch] = useState("");
  const [sending, setSending] = useState(false);
  const [loading, setLoading] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Get my actual user id from auth store
  const [meId, setMeId] = useState<number>(0);
  useEffect(() => {
    // Read from localStorage since useAuth profile may not have id directly
    try {
      const raw = localStorage.getItem("auth-storage");
      if (raw) {
        const parsed = JSON.parse(raw);
        setMeId(parsed?.state?.user?.id ?? 0);
      }
    } catch { /* ignore */ }
  }, []);

  const loadSidebar = useCallback(async () => {
    try {
      const [convRes, contactRes] = await Promise.all([
        api.get<Conversation[]>("/chat/conversations"),
        api.get<Contact[]>("/chat/contacts"),
      ]);
      setConversations(convRes.data);
      // Merge contacts not yet in conversations
      const existingIds = new Set(convRes.data.map((c) => c.partner.id));
      const newContacts = contactRes.data.filter((c) => !existingIds.has(c.id));
      setContacts(newContacts);
    } finally {
      setLoading(false);
    }
  }, []);

  const loadMessages = useCallback(async (userId: number) => {
    const res = await api.get<Message[]>(`/chat/${userId}`);
    setMessages(res.data);
    setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: "smooth" }), 50);
  }, []);

  useEffect(() => { void loadSidebar(); }, [loadSidebar]);

  // Poll messages every 3s when a conversation is open
  useEffect(() => {
    if (pollRef.current) clearInterval(pollRef.current);
    if (!activeId) return;
    pollRef.current = setInterval(() => {
      void loadMessages(activeId);
      void loadSidebar();
      void fetchUnread();
    }, 3000);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [activeId, loadMessages, loadSidebar]);

  const openConversation = async (userId: number) => {
    setActiveId(userId);
    await loadMessages(userId);
    void fetchUnread(); // decrement badge after marking as read
  };

  const send = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !activeId || sending) return;
    setSending(true);
    const content = input.trim();
    setInput("");
    try {
      await api.post(`/chat/${activeId}`, { content });
      await loadMessages(activeId);
      await loadSidebar();
    } finally {
      setSending(false);
    }
  };

  // All people to show in sidebar: conversations + new contacts
  const allSidebarItems = [
    ...conversations.map((c) => ({ id: c.partner.id, full_name: c.partner.full_name, role: c.partner.role, lastMessage: c.lastMessage, unreadCount: c.unreadCount })),
    ...contacts.map((c) => ({ id: c.id, full_name: c.full_name, role: c.role, lastMessage: null, unreadCount: 0 })),
  ].filter((item) => item.full_name.toLowerCase().includes(search.toLowerCase()));

  const activePerson = allSidebarItems.find((i) => i.id === activeId);

  return (
    <div className="flex h-[calc(100vh-120px)] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      {/* Sidebar */}
      <div className="flex w-72 shrink-0 flex-col border-r border-slate-100">
        <div className="border-b border-slate-100 p-4">
          <h2 className="text-lg font-bold text-slate-900">Messages</h2>
          <div className="relative mt-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search…"
              className="w-full rounded-xl border border-slate-200 bg-slate-50 pl-9 pr-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <p className="p-4 text-sm text-slate-400">Loading…</p>
          ) : allSidebarItems.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
              <MessageSquare className="h-8 w-8 text-slate-300 mb-2" />
              <p className="text-sm text-slate-400">No contacts yet.</p>
            </div>
          ) : (
            allSidebarItems.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => void openConversation(item.id)}
                className={cn(
                  "flex w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-slate-50",
                  activeId === item.id && "bg-primary-50 border-r-2 border-primary-600"
                )}
              >
                <div className={cn("flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-bold", roleColor(item.role))}>
                  {initials(item.full_name)}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-1">
                    <p className="truncate text-sm font-semibold text-slate-900">{item.full_name}</p>
                    {item.lastMessage && (
                      <span className="shrink-0 text-[10px] text-slate-400">{formatTime(item.lastMessage.created_at)}</span>
                    )}
                  </div>
                  <div className="flex items-center justify-between gap-1">
                    <p className="truncate text-xs text-slate-500">
                      {item.lastMessage ? item.lastMessage.content : <span className="italic text-slate-400">{item.role.charAt(0) + item.role.slice(1).toLowerCase()}</span>}
                    </p>
                    {item.unreadCount > 0 && (
                      <span className="shrink-0 rounded-full bg-primary-600 px-1.5 py-0.5 text-[10px] font-bold text-white">
                        {item.unreadCount > 9 ? "9+" : item.unreadCount}
                      </span>
                    )}
                  </div>
                </div>
              </button>
            ))
          )}
        </div>
      </div>

      {/* Chat area */}
      {activeId && activePerson ? (
        <div className="flex flex-1 flex-col min-w-0">
          {/* Header */}
          <div className="flex items-center gap-3 border-b border-slate-100 px-5 py-3.5">
            <div className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold", roleColor(activePerson.role))}>
              {initials(activePerson.full_name)}
            </div>
            <div>
              <p className="font-semibold text-slate-900">{activePerson.full_name}</p>
              <p className="text-xs text-slate-400 capitalize">{activePerson.role.toLowerCase()}</p>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3">
            {messages.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-center">
                <MessageSquare className="h-10 w-10 text-slate-200 mb-3" />
                <p className="text-sm text-slate-400">No messages yet. Say hello!</p>
              </div>
            ) : (
              messages.map((msg) => {
                const isMine = msg.senderId === meId;
                return (
                  <div key={msg.id} className={cn("flex", isMine ? "justify-end" : "justify-start")}>
                    <div className={cn(
                      "max-w-[70%] rounded-2xl px-4 py-2.5 text-sm",
                      isMine
                        ? "rounded-br-sm bg-primary-600 text-white"
                        : "rounded-bl-sm bg-slate-100 text-slate-900"
                    )}>
                      <p className="leading-relaxed">{msg.content}</p>
                      <p className={cn("mt-1 text-[10px]", isMine ? "text-primary-200 text-right" : "text-slate-400")}>
                        {formatMessageTime(msg.created_at)}
                        {isMine && <span className="ml-1">{msg.is_read ? "✓✓" : "✓"}</span>}
                      </p>
                    </div>
                  </div>
                );
              })
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <form onSubmit={(e) => void send(e)} className="flex items-center gap-3 border-t border-slate-100 px-4 py-3">
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Type a message…"
              className="flex-1 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
              autoComplete="off"
            />
            <button
              type="submit"
              disabled={!input.trim() || sending}
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary-600 text-white hover:bg-primary-700 disabled:opacity-50 transition-colors"
            >
              <Send className="h-4 w-4" />
            </button>
          </form>
        </div>
      ) : (
        <div className="flex flex-1 flex-col items-center justify-center text-center">
          <MessageSquare className="h-12 w-12 text-slate-200 mb-3" />
          <p className="text-base font-semibold text-slate-500">Select a conversation</p>
          <p className="text-sm text-slate-400 mt-1">Choose someone from the left to start chatting.</p>
        </div>
      )}
    </div>
  );
}
