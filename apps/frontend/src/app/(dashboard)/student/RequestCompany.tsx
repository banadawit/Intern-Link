"use client";

import React, { useEffect, useRef, useState } from 'react';
import {
  Building,
  Send,
  CheckCircle2,
  Clock,
  XCircle,
  AlertCircle,
  Mail,
  MapPin,
  FileText,
  ImageIcon,
  Upload,
} from 'lucide-react';
import api from '@/lib/api/client';
import { cn } from '@/lib/utils';
import StudentPageHero from './StudentPageHero';

type ProposalApi = {
  id: number;
  status: string;
  proposal_type: string;
  submitted_at: string;
  company: { name: string };
};

const StatusBadge = ({ status }: { status: string }) => {
  const cfg: Record<string, { cls: string; label: string }> = {
    PENDING:  { cls: 'bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300',  label: 'Pending'  },
    APPROVED: { cls: 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300',  label: 'Approved' },
    REJECTED: { cls: 'bg-red-100   text-red-800   dark:bg-red-900/40   dark:text-red-300',    label: 'Rejected' },
  };
  const { cls, label } = cfg[status] ?? { cls: 'bg-slate-100 text-slate-700', label: status };
  return (
    <span className={cn('px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider', cls)}>
      {label}
    </span>
  );
};

const ProposalCard = ({ p }: { p: ProposalApi }) => (
  <div className="card p-5 flex items-center justify-between hover:border-primary-base/30 transition-all">
    <div className="flex items-center gap-4">
      <div className={cn(
        'p-3 rounded-xl',
        p.status === 'APPROVED' ? 'bg-green-50 text-green-600 dark:bg-green-900/30' :
        p.status === 'REJECTED' ? 'bg-red-50 text-red-600 dark:bg-red-900/30' :
        'bg-amber-50 text-amber-600 dark:bg-amber-900/30'
      )}>
        {p.status === 'APPROVED' ? <CheckCircle2 className="w-5 h-5" /> :
         p.status === 'REJECTED' ? <XCircle className="w-5 h-5" /> :
         <Clock className="w-5 h-5" />}
      </div>
      <div>
        <h4 className="font-bold text-text-heading">{p.company.name}</h4>
        <p className="text-xs text-text-muted">
          Submitted {new Date(p.submitted_at).toLocaleDateString()}
        </p>
      </div>
    </div>
    <StatusBadge status={p.status} />
  </div>
);

type FileInputProps = {
  label: string;
  hint: string;
  icon: React.ReactNode;
  accept: string;
  file: File | null;
  onChange: (f: File | null) => void;
};

const FileInput = ({ label, hint, icon, accept, file, onChange }: FileInputProps) => {
  const ref = useRef<HTMLInputElement>(null);
  return (
    <div className="space-y-1">
      <label className="text-sm font-bold text-text-muted">{label}</label>
      <div
        onClick={() => ref.current?.click()}
        className={cn(
          'flex items-center gap-3 cursor-pointer rounded-xl border-2 border-dashed px-4 py-3 transition-colors',
          file
            ? 'border-primary-base/50 bg-primary-base/5'
            : 'border-border-default hover:border-primary-base/40 bg-transparent'
        )}
      >
        <span className="text-text-muted">{icon}</span>
        <div className="min-w-0 flex-1">
          {file ? (
            <p className="text-sm font-medium text-text-heading truncate">{file.name}</p>
          ) : (
            <p className="text-sm text-text-muted">{hint}</p>
          )}
        </div>
        <Upload className="w-4 h-4 text-text-muted shrink-0" />
      </div>
      <input
        ref={ref}
        type="file"
        accept={accept}
        className="hidden"
        onChange={(e) => onChange(e.target.files?.[0] ?? null)}
      />
    </div>
  );
};

const RequestCompany = () => {
  const [openLetters, setOpenLetters] = useState<ProposalApi[]>([]);
  const [placements, setPlacements] = useState<ProposalApi[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    companyName: '',
    companyEmail: '',
    companyAddress: '',
    coverLetter: '',
  });
  const [stampFile, setStampFile] = useState<File | null>(null);
  const [docFile, setDocFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const loadProposals = async () => {
    try {
      const { data } = await api.get<{ success: boolean; data: ProposalApi[] }>('/placements/my-proposals');
      const rows = Array.isArray(data.data) ? data.data : [];
      setOpenLetters(rows.filter((p) => p.proposal_type === 'Open_Letter'));
      setPlacements(rows.filter((p) => p.proposal_type !== 'Open_Letter'));
    } catch {
      setOpenLetters([]);
      setPlacements([]);
    }
  };

  useEffect(() => {
    (async () => {
      setLoading(true);
      await loadProposals();
      setLoading(false);
    })();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);
    setSubmitting(true);
    try {
      const form = new FormData();
      form.append('company_name', formData.companyName);
      form.append('company_email', formData.companyEmail);
      form.append('company_address', formData.companyAddress);
      form.append('cover_letter', formData.coverLetter);
      if (stampFile) form.append('stamp', stampFile);
      if (docFile) form.append('verification_doc', docFile);

      await api.post('/students/open-letter', form);
      setFormData({ companyName: '', companyEmail: '', companyAddress: '', coverLetter: '' });
      setStampFile(null);
      setDocFile(null);
      setSuccessMsg('Open letter submitted. Your HOD will review it.');
      await loadProposals();
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message ??
        'Something went wrong. Please try again.';
      setErrorMsg(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Open letter"
        title="Request a Company"
        description="Submit an open letter to request an internship at a company of your choice. Your HOD will review the details."
      />

      {loading && <p className="text-sm text-text-muted">Loading proposals…</p>}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Form */}
        <div className="card p-8">
          <h3 className="text-lg font-bold mb-6 flex items-center gap-2">
            <Building className="w-5 h-5 text-primary-base" />
            Submit open letter
          </h3>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Company name */}
            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Company Name *</label>
              <div className="relative">
                <Building className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
                <input
                  type="text"
                  required
                  className="input-field w-full pl-10"
                  placeholder="e.g. Ethio Telecom"
                  value={formData.companyName}
                  onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
                />
              </div>
            </div>

            {/* Company email */}
            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Company Official Email *</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
                <input
                  type="email"
                  required
                  className="input-field w-full pl-10"
                  placeholder="hr@company.com"
                  value={formData.companyEmail}
                  onChange={(e) => setFormData({ ...formData, companyEmail: e.target.value })}
                />
              </div>
            </div>

            {/* Company address */}
            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Company Address</label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted" />
                <input
                  type="text"
                  className="input-field w-full pl-10"
                  placeholder="e.g. Addis Ababa, Bole Sub-city"
                  value={formData.companyAddress}
                  onChange={(e) => setFormData({ ...formData, companyAddress: e.target.value })}
                />
              </div>
            </div>

            {/* Stamp */}
            <FileInput
              label="Company Stamp (image)"
              hint="Upload company stamp — JPG or PNG"
              icon={<ImageIcon className="w-4 h-4" />}
              accept="image/jpeg,image/jpg,image/png"
              file={stampFile}
              onChange={setStampFile}
            />

            {/* Verification doc */}
            <FileInput
              label="Verification Document"
              hint="Upload acceptance letter or company doc — PDF, JPG, PNG"
              icon={<FileText className="w-4 h-4" />}
              accept="application/pdf,image/jpeg,image/jpg,image/png"
              file={docFile}
              onChange={setDocFile}
            />

            {/* Cover letter */}
            <div className="space-y-2">
              <label className="text-sm font-bold text-text-muted">Cover Letter *</label>
              <textarea
                required
                className="input-field w-full min-h-[120px] text-sm"
                placeholder="Write your motivation and why you want to intern at this company..."
                value={formData.coverLetter}
                onChange={(e) => setFormData({ ...formData, coverLetter: e.target.value })}
              />
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="w-full btn-primary flex items-center justify-center gap-2 disabled:opacity-60"
            >
              <Send className="w-4 h-4" />
              {submitting ? 'Submitting…' : 'Submit open letter'}
            </button>

            {successMsg && (
              <div className="p-4 bg-green-50 border border-green-100 rounded-xl flex items-start gap-3 animate-in fade-in slide-in-from-top-2 dark:bg-green-900/20 dark:border-green-900/50">
                <CheckCircle2 className="w-5 h-5 text-green-600 shrink-0 mt-0.5" />
                <p className="text-sm font-medium text-green-900 dark:text-green-200">{successMsg}</p>
              </div>
            )}

            {errorMsg && (
              <div className="p-4 bg-red-50 border border-red-100 rounded-xl flex items-start gap-3 animate-in fade-in slide-in-from-top-2 dark:bg-red-900/20 dark:border-red-900/50">
                <AlertCircle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
                <p className="text-sm font-medium text-red-900 dark:text-red-200">{errorMsg}</p>
              </div>
            )}
          </form>
        </div>

        {/* Right side lists */}
        <div className="space-y-8">
          <div className="space-y-4">
            <h3 className="text-lg font-bold">Open letter requests</h3>
            {!loading && openLetters.length === 0 ? (
              <div className="card p-10 text-center text-text-muted">
                <Send className="w-10 h-10 mx-auto mb-3 opacity-20" />
                <p className="text-sm font-medium">No open letters submitted yet.</p>
              </div>
            ) : (
              openLetters.map((p) => <ProposalCard key={p.id} p={p} />)
            )}
          </div>

          <div className="space-y-4">
            <h3 className="text-lg font-bold">Placement proposals</h3>
            {!loading && placements.length === 0 ? (
              <div className="card p-10 text-center text-text-muted">
                <Building className="w-10 h-10 mx-auto mb-3 opacity-20" />
                <p className="text-sm font-medium">No placement proposals yet.</p>
              </div>
            ) : (
              placements.map((p) => <ProposalCard key={p.id} p={p} />)
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestCompany;
