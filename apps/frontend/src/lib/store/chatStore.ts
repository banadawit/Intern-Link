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
      const { data } = await api.get<{ count: number }>("/chat/unread-count");
      set({ unreadCount: data.count });
    } catch {
      // ignore
    }
  },
}));
