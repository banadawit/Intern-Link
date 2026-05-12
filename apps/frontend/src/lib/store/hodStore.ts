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
      const { data } = await api.get<{ success: boolean; data: { pendingApprovals?: number } }>("/hod/dashboard-stats");
      set({ pendingStudents: data.data?.pendingApprovals ?? 0 });
    } catch {
      // ignore
    }
  },
}));
