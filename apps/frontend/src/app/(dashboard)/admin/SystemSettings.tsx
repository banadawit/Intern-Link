"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
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
import { useTranslations } from "next-intl";

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

function Toggle({ value, onChange, label }: { value: boolean; onChange: (v: boolean) => void; label: string }) {
  return (
    <button
      type="button"
      onClick={() => onChange(!value)}
      className={cn(
        "flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all",
        value
          ? "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400 dark:ring-emerald-800"
          : "bg-slate-100 text-slate-500 ring-1 ring-slate-200 dark:bg-slate-800 dark:text-slate-400 dark:ring-slate-700"
      )}
    >
      {value ? <ToggleRight className="h-5 w-5" /> : <ToggleLeft className="h-5 w-5" />}
      {label}
    </button>
  );
}

function Section({ title, icon: Icon, children }: { title: string; icon: React.ComponentType<{ className?: string }>; children: React.ReactNode }) {
  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
      <div className="flex items-center gap-3 border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-6 py-4">
        <div className="rounded-xl bg-teal-50 dark:bg-teal-900/30 p-2">
          <Icon className="h-5 w-5 text-teal-600 dark:text-teal-400" />
        </div>
        <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">{title}</h2>
      </div>
      <div className="p-6">{children}</div>
    </div>
  );
}

export default function SystemSettings() {
  const t = useTranslations("AdminPortal.settings");
  const days = t.raw("days") as string[];
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
  // Keep a stable ref to t so load doesn't need it as a dep
  const tRef = useRef(t);
  useEffect(() => { tRef.current = t; });

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get<{ success: boolean; data: Config }>("/admin/config");
      setConfig(data.data);
    } catch {
      setError(tRef.current("loadFailed"));
    } finally {
      setLoading(false);
    }
  }, []); // stable — no deps

  useEffect(() => { void load(); }, []); // run once on mount

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
      setError(t("saveFailed"));
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
      setError(t("exportFailed"));
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
      setError(t("broadcastFailed"));
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
        {error ?? t("couldNotLoad")}
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      <AdminPageHero
        badge={t("heroBadge")}
        title={t("heroTitle")}
        description={t("heroDescription")}
      />

      {error && (
        <div className="flex items-center gap-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          <XCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {/* ── Registration Controls ── */}
      <Section title={t("sectionRegistration")} icon={ToggleRight}>
        <p className="mb-4 text-sm text-slate-500 dark:text-slate-400">
          {t("sectionRegistrationLead")}
        </p>
        <div className="flex flex-wrap gap-3">
          {(["student", "coordinator", "hod", "supervisor"] as const).map((role) => {
            const key = `registration_${role}_open` as keyof Config;
            const isOpen = config[key] === "true";
            const roleLabel =
              role === "student"
                ? t("roleStudent")
                : role === "coordinator"
                  ? t("roleCoordinator")
                  : role === "hod"
                    ? t("roleHod")
                    : t("roleSupervisor");
            return (
              <Toggle
                key={role}
                value={isOpen}
                onChange={(v) => set(key, v ? "true" : "false")}
                label={t("registrationToggle", {
                  role: roleLabel,
                  state: isOpen ? t("registrationStateOpen") : t("registrationStateClosed"),
                })}
              />
            );
          })}
        </div>
      </Section>

      {/* ── Maintenance Mode ── */}
      <Section title={t("sectionMaintenance")} icon={AlertTriangle}>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold text-slate-900 dark:text-slate-100">{t("maintenanceEnableTitle")}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">{t("maintenanceEnableHint")}</p>
            </div>
            <Toggle
              value={config.maintenance_mode === "true"}
              onChange={(v) => set("maintenance_mode", v ? "true" : "false")}
              label={config.maintenance_mode === "true" ? t("toggleActive") : t("toggleInactive")}
            />
          </div>
          {config.maintenance_mode === "true" && (
            <div className="space-y-1">
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("maintenanceMessageLabel")}</label>
              <textarea
                value={config.maintenance_message}
                onChange={(e) => set("maintenance_message", e.target.value)}
                rows={2}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20 resize-none"
              />
            </div>
          )}
        </div>
      </Section>

      {/* ── Internship Rules ── */}
      <Section title={t("sectionInternship")} icon={Settings}>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { key: "internship_min_weeks" as const, label: t("labelMinWeeks"), type: "number", min: 1, max: 52 },
            { key: "internship_max_weeks" as const, label: t("labelMaxWeeks"), type: "number", min: 1, max: 52 },
            { key: "max_weekly_plans" as const, label: t("labelMaxWeeklyPlans"), type: "number", min: 1, max: 52 },
          ].map(({ key, label, min, max }) => (
            <div key={key} className="space-y-1">
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{label}</label>
              <input
                type="number"
                min={min}
                max={max}
                value={config[key]}
                onChange={(e) => set(key as keyof Config, e.target.value)}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
              />
            </div>
          ))}
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("labelWeeklyDeadline")}</label>
            <select
              value={config.weekly_plan_deadline_day}
              onChange={(e) => set("weekly_plan_deadline_day", e.target.value)}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            >
              {days.map((d) => <option key={d}>{d}</option>)}
            </select>
          </div>
        </div>
      </Section>

      {/* ── Platform Info ── */}
      <Section title={t("sectionPlatform")} icon={Settings}>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("labelPlatformName")}</label>
            <input
              type="text"
              value={config.platform_name}
              onChange={(e) => set("platform_name", e.target.value)}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("labelSupportEmail")}</label>
            <input
              type="email"
              value={config.support_email}
              onChange={(e) => set("support_email", e.target.value)}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
        </div>
      </Section>

      {/* ── Email / SMTP ── */}
      <Section title={t("sectionEmailSmtp")} icon={Mail}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-slate-900 dark:text-slate-100">{t("smtpStatusTitle")}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400">{t("smtpStatusHint")}</p>
          </div>
          <div className="flex items-center gap-3">
            {smtpStatus === "ok" && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
                <CheckCircle2 className="h-4 w-4" /> {t("smtpConnected")}
              </span>
            )}
            {smtpStatus === "fail" && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-red-600">
                <XCircle className="h-4 w-4" /> {t("smtpFailed")}
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
              {t("testSmtp")}
            </button>
          </div>
        </div>
      </Section>

      {/* ── Broadcast Announcement ── */}
      <Section title={t("sectionBroadcast")} icon={Megaphone}>
        <p className="mb-4 text-sm text-slate-500 dark:text-slate-400">
          {t("broadcastLead")}
        </p>
        <div className="space-y-3">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("broadcastTitleLabel")}</label>
            <input
              type="text"
              value={broadcast.title}
              onChange={(e) => setBroadcast((b) => ({ ...b, title: e.target.value }))}
              placeholder={t("broadcastTitlePlaceholder")}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20"
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">{t("broadcastMessageLabel")}</label>
            <textarea
              value={broadcast.content}
              onChange={(e) => setBroadcast((b) => ({ ...b, content: e.target.value }))}
              placeholder={t("broadcastMessagePlaceholder")}
              rows={3}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20 resize-none"
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
              {t("broadcastSend")}
            </button>
            {broadcastSuccess && (
              <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
                <CheckCircle2 className="h-4 w-4" /> {t("broadcastSent")}
              </span>
            )}
          </div>
        </div>
      </Section>

      {/* ── Data & Compliance ── */}
      <Section title={t("sectionDataCompliance")} icon={Download}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-slate-900 dark:text-slate-100">{t("exportAuditTitle")}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400">{t("exportAuditHint")}</p>
          </div>
          <button
            type="button"
            onClick={() => void exportCsv()}
            disabled={exportLoading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-2.5 text-sm font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-60 transition-colors"
          >
            {exportLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
            {t("downloadCsv")}
          </button>
        </div>
      </Section>

      {/* ── Save button ── */}
      <div className="flex items-center justify-end gap-3 pb-8">
        {saveSuccess && (
          <span className="flex items-center gap-1.5 text-sm font-semibold text-emerald-600">
            <CheckCircle2 className="h-4 w-4" /> {t("settingsSaved")}
          </span>
        )}
        <button
          type="button"
          onClick={() => void save()}
          disabled={saving}
          className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-6 py-3 text-sm font-bold text-white shadow-lg shadow-teal-600/20 hover:bg-teal-700 disabled:opacity-60 transition-all"
        >
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          {t("saveAllSettings")}
        </button>
      </div>
    </div>
  );
}
