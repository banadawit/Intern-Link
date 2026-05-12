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
<<<<<<< Updated upstream
      const { data } = await api.get<{ data: unknown[] } | unknown[]>("/coordinator/pending-hods");
      const list = Array.isArray(data) ? data : (data as { data: unknown[] })?.data ?? [];
      set({ pendingHodCount: list.length });
=======
      const { data } = await api.get<{ id: number }[]>("/coordinator/pending-hods");
      set({ pendingHodCount: Array.isArray(data) ? data.length : 0 });
>>>>>>> Stashed changes
    } catch {
      // ignore
    }
  },
}));
