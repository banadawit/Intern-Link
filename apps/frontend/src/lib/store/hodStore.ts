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
<<<<<<< Updated upstream
      const { data } = await api.get<{ data: unknown[] }>("/hod/students", { params: { status: "pending" } });
      const list = Array.isArray(data?.data) ? data.data : [];
      set({ pendingStudents: list.length });
=======
      const { data } = await api.get<{ success: boolean; data: { pendingApprovals?: number } }>("/hod/dashboard-stats");
      set({ pendingStudents: data.data?.pendingApprovals ?? 0 });
>>>>>>> Stashed changes
    } catch {
      // ignore
    }
  },
}));
