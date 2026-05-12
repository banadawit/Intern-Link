"use client";

import { create } from "zustand";
import api from "@/lib/api/client";

interface HodStore {
  pendingStudents: number;
  fetchCounts: () => Promise<void>;
}

export const useHodStore = create<HodStore>((set) => ({
  pendingStudents: 0,
  fetchCounts: async () => {
    try {
      const { data } = await api.get<{ data: unknown[] }>("/hod/students", { params: { status: "pending" } });
      const list = Array.isArray(data?.data) ? data.data : [];
      set({ pendingStudents: list.length });
    } catch {
      // ignore
    }
  },
}));
