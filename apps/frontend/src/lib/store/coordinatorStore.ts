"use client";

import { create } from "zustand";
import api from "@/lib/api/client";

interface CoordinatorStore {
  pendingHodCount: number;
  fetchCounts: () => Promise<void>;
}

export const useCoordinatorStore = create<CoordinatorStore>((set) => ({
  pendingHodCount: 0,
  fetchCounts: async () => {
    try {
      const { data } = await api.get<{ id: number }[]>("/coordinator/pending-hods");
      set({ pendingHodCount: Array.isArray(data) ? data.length : 0 });
    } catch {
      // ignore
    }
  },
}));
