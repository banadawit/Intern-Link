"use client";

import React, { useCallback, useEffect, useState } from "react";
import {
  Settings,
  Mail,
  CheckCircle2,
  XCircle,
  Loader2,
  Download,
  Megaphone,
  ToggleLeft,
  ToggleRight,
  AlertTriangle,
  RefreshCw,
  Save,
} from "lucide-react";
import api from "@/lib/api/client";
import AdminPageHero from "./AdminPageHero";
import { cn } from "@/lib/utils";

interface Config {
  registration_student_open: string;
  registration_coordinator_open: string;
  registration_supervisor_open: string;
  registration_hod_open: string;
  internship_min_weeks: string;
  internship_max_weeks: string;
  weekly_plan_deadline_day: string;
  max_weekly_plans: string;
  platform_name: string;
  support_email: string;
  maintenance_mode: string;
  maintenance_message: string;
  [key: string]: string;
}

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

function Toggle({ value, onChange, label }: { value: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!value)}
      className={cn(
        "flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all",
        value
          ? "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200"
          : "bg-slate-100 text-slate-500 ring-1 ring-slate-200"
      )}
    >
      {value ? <ToggleRight className="h-5 w-5" /> : <ToggleLeft className="h-5 w-5" />}
      {label}
    </button>
  );
}

function Section({ title, icon: Icon, children }: { title: string; icon: React.ComponentType<{ className?: string }>; children: React.ReactNode }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="flex items-center gap-3 border-b border-slate-100 bg-slate-50 px-6 py-4">
        <div className="rounded-xl bg-teal-50 p-2">
          <Icon className="h-5 w-5 text-teal-600" />
        </div>
        <h2 className="text-base font-bold text-slate-900">{title}</h2>
      </div>
      <div className="p-6">{children}</div>
    </div>
  );
}

export default function SystemSettings() {
  const [config, setConfig] = useState<Config | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [smtpStatus, setSmtpStatus] = useState<"idle" | "testing" | "ok" | "fail">("idle");
  const [exportLoading, setExportLoading] = useState(false);
  const [broadcast, setBroadcast] = useState({ title: "", content: "" });
  const [broadcastSending, setBroadcastSending] = useState(false);
  const [broadcastSuccess, setBroadcastSuccess] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get<{ success: boolean; data: Config }>("/admin/config");
      setConfig(data.data);
    } catch {
      setError("Failed to load configuration.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const set = (key: keyof Config, value: string) => {
    setConfig((prev) => prev ? { ...prev, [key]: value } : prev);
  };

  const save = async () => {
    if (!config) return;
    setSaving(true);
    setError(null);
    setSaveSuccess(false);
    try {
      await api.patch("/admin/config", config);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch {
      setError("Failed to save configuration.");
    } finally {
      setSaving(false);
    }
  };

  const testSmtp = async () => {
    setSmtpStatus("testing");
    try {
      const { data } = await api.post<{ success: boolean }>("/admin/config/test-smtp");
      setSmtpStatus(data.success ? "ok" : "fail");
    } catch {
      setSmtpStatus("fail");
    }
  };

  const exportCsv = async () => {
    setExportLoading(true);
    try {
      const response = await api.get("/admin/config/export-audit-csv", { responseType: "blob" });
      const url = URL.createObjectURL(new Blob([response.data]));
      const a = document.createElement("a");
      a.href = url;
      a.download = `audit-log-${Date.now()}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      setError("Failed to export audit log.");
    } finally {
      setExportLoading(false);
    }
  };

  const sendBroadcast = async () => {
    if (!broadcast.title.trim() || !broadcast.content.trim()) return;
    setBroadcastSending(true);
    setBroadcastSuccess(false);
    setError(null);
    try {
      await api.post("/admin/config/broadcast", broadcast);
      setBroadcastSuccess(true);
      setBroadcast({ title: "", content: "" });
      setTimeout(() => setBroadcastSuccess(false), 4000);
    } catch {
      setError("Failed to send broadcast.");
    } finally {
      setBroadcastSending(false);
    }
  };

  if (loading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <Loader2 className="h-10 w-10 animate-spin text-teal-600" />
      </div>
    );
  }

  if (!config) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">
        {error ?? "Could not load configuration."}
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <AdminPageHero
        badge="Settings"
        title="System Configuration"
        description="Manage platform-wide settings, registration controls, and operational parameters."
      />

      {error && (
        <div className="flex items-center gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          <XCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {/* ── Registration Controls ── */}
      <Section title="Registration Controls" icon={ToggleRight}>
        <p className="mb-4 text-sm text-slate-500">
          Enable or disable new registrations per role. Existing accounts are not affected.
        </p>
        <div className="flex flex-wrap gap-3">
          {(["student", "coordinator", "hod", "supervisor"] as const).map((role) => {
            const key = `registration_${role}_open` as keyof Config;
            const isOpen = config[key] === "true";
            return (
              <Toggle
                key={role}
                value={isOpen}
                onChange={(v) => set(key, v ? "true" : "false")}
                label={`${role.charAt(0).toUpperCase() + role.slice(1)} registration ${isOpen ? "open" : "closed"}`}
              />
            );
          })}
        </div>
      </Section>

      {/* ── Maintenance Mode ── */}
      <Section title="Maintenance Mode" icon={AlertTriangle}>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-slate-900">Enable maintenance mode</p>
              <p className="text-xs text-slate-500">Blocks all new registrations and shows a message to users.</p>
            </div>
            <Toggle
              value={config.maintenance_mode === "true"}
              onChange={(v) => set("maintenance_mode", v ? "true" : "false")}
              label={config.maintenance_mode === "true" ? "Active" : "Inactive"}
            />
          </div>
          {config.maintenance_mode === "true" && (
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-700">Maintenance message</label>
              <textarea
                value={config.maintenance_message}
                onChange={(e) => set("maintenance_message", e.target.value)}
                rows={2}
                className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20 resize-none"
              />
            </div>
          )}
        </div>
      </Section>

      {/* ── Internship Rules ── */}
      <Section title="Internship Rules" icon={Settings}>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { key: "internship_min_weeks", label: "Min duration (weeks)", type: "number", min: 1, max: 52 },
            { key: "internship_max_weeks", label: "Max duration (weeks)", type: "number", min: 1, max: 52 },
            { key: "max_weekly_plans", label: "Max weekly plans", type: "number", min: 1, max: 52 },
          ].map(({ key, label, min, max }) => (
            <div key={key} className="space-y-1">
              <label className="text-xs font-semibold text-slate-700">{label}</label>
              <input
                type="number"
                min={min}
                max={max}
                value={config[key]}
                onChange={(e) => set(key as keyof Config, e.target.value)}
                className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
              />
            </div>
          ))}
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700">Weekly plan deadline</label>
            <select
              value={config.weekly_plan_deadline_day}
              onChange={(e) => set("weekly_plan_deadline_day", e.target.value)}
              className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            >
              {DAYS.map((d) => <option key={d}>{d}</option>)}
            </select>
          </div>
        </div>
      </Section>

      {/* ── Platform Info ── */}
      <Section title="Platform Information" icon={Settings}>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700">Platform name</label>
            <input
              type="text"
              value={config.platform_name}
              onChange={(e) => set("platform_name", e.target.value)}
              className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700">Support email</label>
            <input
              type="email"
              value={config.support_email}
              onChange={(e) => set("support_email", e.target.value)}
              className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
        </div>
      </Section>

      {/* ── Email / SMTP ── */}
      <Section title="Email & SMTP" icon={Mail}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-slate-900">SMTP connection status</p>
            <p className="text-xs text-slate-500">Tests the current SMTP configuration from your .env file.</p>
          </div>
          <div className="flex items-center gap-3">
            {smtpStatus === "ok" && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
                <CheckCircle2 className="h-4 w-4" /> Connected
              </span>
            )}
            {smtpStatus === "fail" && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-red-600">
                <XCircle className="h-4 w-4" /> Failed
              </span>
            )}
            <button
              type="button"
              onClick={() => void testSmtp()}
              disabled={smtpStatus === "testing"}
              className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60 transition-colors"
            >
              {smtpStatus === "testing" ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <RefreshCw className="h-4 w-4" />
              )}
              Test SMTP
            </button>
          </div>
        </div>
      </Section>

      {/* ── Broadcast Announcement ── */}
      <Section title="Broadcast Announcement" icon={Megaphone}>
        <p className="mb-4 text-sm text-slate-500">
          Send an in-app notification to all users on the platform.
        </p>
        <div className="space-y-3">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700">Title</label>
            <input
              type="text"
              value={broadcast.title}
              onChange={(e) => setBroadcast((b) => ({ ...b, title: e.target.value }))}
              placeholder="e.g., System maintenance scheduled"
              className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700">Message</label>
            <textarea
              value={broadcast.content}
              onChange={(e) => setBroadcast((b) => ({ ...b, content: e.target.value }))}
              placeholder="Write your announcement here…"
              rows={3}
              className="w-full rounded-xl border border-slate-200 px-4 py-2.5 text-sm text-slate-900 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20 resize-none"
            />
          </div>
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => void sendBroadcast()}
              disabled={broadcastSending || !broadcast.title.trim() || !broadcast.content.trim()}
              className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60 transition-colors"
            >
              {broadcastSending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Megaphone className="h-4 w-4" />}
              Send to all users
            </button>
            {broadcastSuccess && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
                <CheckCircle2 className="h-4 w-4" /> Sent successfully
              </span>
            )}
          </div>
        </div>
      </Section>

      {/* ── Data & Compliance ── */}
      <Section title="Data & Compliance" icon={Download}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-slate-900">Export audit log</p>
            <p className="text-xs text-slate-500">Download the last 5,000 audit entries as a CSV file.</p>
          </div>
          <button
            type="button"
            onClick={() => void exportCsv()}
            disabled={exportLoading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-60 transition-colors"
          >
            {exportLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
            Download CSV
          </button>
        </div>
      </Section>

      {/* ── Save button ── */}
      <div className="flex items-center justify-end gap-3 pb-8">
        {saveSuccess && (
          <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
            <CheckCircle2 className="h-4 w-4" /> Settings saved
          </span>
        )}
        <button
          type="button"
          onClick={() => void save()}
          disabled={saving}
          className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-6 py-3 text-sm font-bold text-white shadow-lg shadow-teal-600/20 hover:bg-teal-700 disabled:opacity-60 transition-all"
        >
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Save all settings
        </button>
      </div>
    </div>
  );
}
