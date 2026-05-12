"use client";

import { create } from "zustand";
import api from "@/lib/api/client";

interface SupervisorStore {
  pendingProposals: number;
  pendingPlans: number;
  fetchCounts: () => Promise<void>;
}

export const useSupervisorStore = create<SupervisorStore>((set) => ({
  pendingProposals: 0,
  pendingPlans: 0,
  fetchCounts: async () => {
    try {
      const { data } = await api.get<{
        success: boolean;
        data: { stats: { pendingProposalsCount: number; pendingWeeklyPlansCount: number } };
      }>("/supervisor/me");
      set({
        pendingProposals: data.data.stats.pendingProposalsCount,
        pendingPlans: data.data.stats.pendingWeeklyPlansCount,
      });
    } catch {
      // ignore
    }
  },
}));
