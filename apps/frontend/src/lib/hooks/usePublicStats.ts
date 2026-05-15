import { useState, useEffect } from 'react';
import api from '@/lib/api/client';

export interface PublicStats {
  totalStudents: number;
  activeStudents: number;
  placedStudents: number;
  completedStudents: number;
  placementRate: number;
  partnerCompanies: number;
  partnerUniversities: number;
  reportsGenerated: number;
}

export function usePublicStats() {
  const [stats, setStats] = useState<PublicStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<{ success: boolean; data: PublicStats }>('/public/stats')
      .then(({ data }) => { if (data.success) setStats(data.data); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return { stats, loading };
}
