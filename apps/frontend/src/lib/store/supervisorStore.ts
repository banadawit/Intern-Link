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
      const [proposalsRes, plansRes] = await Promise.allSettled([
        api.get<{ data: { status: string }[] } | { status: string }[]>("/placements/incoming"),
        api.get<{ data: { status: string }[] } | { status: string }[]>("/supervisor/weekly-plans"),
      ]);

      if (proposalsRes.status === "fulfilled") {
        const raw = proposalsRes.value.data;
        const list: { status: string }[] = Array.isArray(raw) ? raw : (raw as { data: { status: string }[] })?.data ?? [];
        set({ pendingProposals: list.filter((p) => p.status === "PENDING").length });
      }

      if (plansRes.status === "fulfilled") {
        const raw = plansRes.value.data;
        const list: { status?: string }[] = Array.isArray(raw) ? raw : (raw as { data: { status?: string }[] })?.data ?? [];
        set({ pendingPlans: list.filter((p) => !p.status || p.status === "PENDING" || p.status === "SUBMITTED").length });
      }
    } catch {
      // ignore
    }
  },
}));
