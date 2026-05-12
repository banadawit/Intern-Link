"use client";

import { create } from "zustand";
import api from "@/lib/api/client";

interface ChatStore {
  unreadCount: number;
  fetchUnread: () => Promise<void>;
}

export const useChatStore = create<ChatStore>((set) => ({
  unreadCount: 0,
  fetchUnread: async () => {
    try {
      const { data } = await api.get<{ data: { count: number } }>("/chat/unread-count");
      set({ unreadCount: data?.data?.count ?? 0 });
    } catch {
      // ignore
    }
  },
}));
