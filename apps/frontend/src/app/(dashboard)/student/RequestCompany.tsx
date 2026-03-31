"use client";

import React, { useEffect, useState } from 'react';
import {
  Building,
  Mail,
  Send,
  CheckCircle2,
  Clock,
  AlertCircle,
  Info,
  ArrowRight,
} from 'lucide-react';
import api from '@/lib/api/client';
import { mapPlacementToCompanyRequest, type PlacementProposalApi } from '@/lib/api/mappers';
import { CompanyRequest } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import StudentPageHero from './StudentPageHero';

const RequestCompany = () => {
  const [requests, setRequests] = useState<CompanyRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    companyName: '',
    contactEmail: '',
    description: '',
  });
  const [infoMessage, setInfoMessage] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const { data } = await api.get('/placements/my-proposals');
        const rows = (data as PlacementProposalApi[]) ?? [];
        setRequests(rows.map(mapPlacementToCompanyRequest));
      } catch {
        setRequests([]);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setInfoMessage(
      'Placement proposals are created by your university coordinator. Please contact your coordinator with the company details you entered.'
    );
    setFormData({ companyName: '', contactEmail: '', description: '' });
    setTimeout(() => setInfoMessage(null), 8000);
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Request company"
        title="Request Company"
        description="Track placement proposals your school sends to companies."
      />

      {loading && <p className="text-sm text-text-muted">Loading proposals…</p>}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="card p-8">
          <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
            <Building className="w-5 h-5 text-primary-base" />
            Suggest a company
          </h3>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Company Name</label>
              <div className="relative">
                <Building className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
                <input
                  type="text"
                  className="input-field w-full pl-10"
                  placeholder="Enter company name..."
                  value={formData.companyName}
                  onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Contact Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
                <input
                  type="email"
                  className="input-field w-full pl-10"
                  placeholder="Enter HR or supervisor email..."
                  value={formData.contactEmail}
                  onChange={(e) => setFormData({ ...formData, contactEmail: e.target.value })}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Additional Information (Optional)</label>
              <textarea
                className="input-field w-full min-h-[100px] text-sm"
                placeholder="Notes for your coordinator..."
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            <div className="p-4 bg-blue-50 border border-blue-100 rounded-xl flex items-start gap-3">
              <Info className="w-5 h-5 text-blue-600 mt-0.5 shrink-0" />
              <p className="text-xs text-blue-700 leading-relaxed">
                Official placement proposals are sent by your coordinator. Use this form to collect details you can share with them.
              </p>
            </div>

            <button type="submit" className="w-full btn-primary flex items-center justify-center gap-2">
              <Send className="w-4 h-4" />
              Save draft / remind coordinator
            </button>

            {infoMessage && (
              <div className="p-4 bg-amber-50 border border-amber-100 rounded-xl flex items-start gap-3 animate-in fade-in slide-in-from-top-2">
                <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
                <p className="text-sm font-medium text-amber-900">{infoMessage}</p>
              </div>
            )}
          </form>
        </div>

        <div className="space-y-6">
          <h3 className="text-lg font-bold">Placement proposals</h3>
          <div className="space-y-4">
            {requests.map((request) => (
              <div
                key={request.id}
                className="card p-6 flex items-center justify-between hover:border-primary-base/30 transition-all"
              >
                <div className="flex items-center gap-4">
                  <div
                    className={cn(
                      'p-3 rounded-xl',
                      request.status === 'Onboarded'
                        ? 'bg-green-50 text-green-600'
                        : request.status === 'Invited'
                          ? 'bg-blue-50 text-blue-600'
                          : 'bg-yellow-50 text-yellow-600'
                    )}
                  >
                    {request.status === 'Onboarded' ? (
                      <CheckCircle2 className="w-5 h-5" />
                    ) : request.status === 'Invited' ? (
                      <Send className="w-5 h-5" />
                    ) : (
                      <Clock className="w-5 h-5" />
                    )}
                  </div>
                  <div>
                    <h4 className="font-bold text-text-heading">{request.companyName}</h4>
                    <p className="text-xs text-text-muted">
                      Requested on {new Date(request.requestedAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <span
                    className={cn(
                      'px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider',
                      request.status === 'Onboarded'
                        ? 'bg-green-100 text-green-700'
                        : request.status === 'Invited'
                          ? 'bg-blue-100 text-blue-700'
                          : 'bg-yellow-100 text-yellow-700'
                    )}
                  >
                    {request.status}
                  </span>
                </div>
              </div>
            ))}
            {!loading && requests.length === 0 && (
              <div className="card p-12 text-center text-text-muted">
                <Building className="w-12 h-12 mx-auto mb-4 opacity-20" />
                <p className="text-sm font-medium">No placement proposals yet.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestCompany;
