import { WEEKLY_SUBMISSION_DEADLINE_LABEL } from "./weeklyDeadline";

const OPT_IN_KEY = "internlink-student-desktop-notify-opt-in";

export function getDesktopNotifyOptIn(): boolean {
  if (typeof window === "undefined") return false;
  try {
    return localStorage.getItem(OPT_IN_KEY) === "1";
  } catch {
    return false;
  }
}

export function setDesktopNotifyOptIn(enabled: boolean): void {
  if (typeof window === "undefined") return;
  try {
    if (enabled) localStorage.setItem(OPT_IN_KEY, "1");
    else localStorage.removeItem(OPT_IN_KEY);
  } catch {
    /* ignore */
  }
}

export function canUseDesktopNotify(): boolean {
  return typeof window !== "undefined" && "Notification" in window;
}

export async function requestDesktopNotifyPermission(): Promise<NotificationPermission> {
  if (!canUseDesktopNotify()) return "denied";
  if (Notification.permission === "granted") return "granted";
  if (Notification.permission === "denied") return "denied";
  return Notification.requestPermission();
}

export function notifyDesktop(title: string, body: string, tag?: string): void {
  if (!canUseDesktopNotify()) return;
  if (!getDesktopNotifyOptIn()) return;
  if (Notification.permission !== "granted") return;
  try {
    new Notification(title, {
      body,
      tag: tag ?? "internlink-student",
      icon: "/favicon.ico",
    });
  } catch {
    /* ignore */
  }
}

const SESSION_MISSED_KEY = "internlink-notified-missed-weeks";

/** One browser notification per distinct missed-week set per tab session (throttled). */
export function maybeNotifyMissedDeadlines(missedWeeks: number[]): void {
  if (missedWeeks.length === 0 || typeof sessionStorage === "undefined") return;
  if (!getDesktopNotifyOptIn() || !canUseDesktopNotify() || Notification.permission !== "granted") return;
  const key = missedWeeks.slice().sort((a, b) => a - b).join(",");
  if (sessionStorage.getItem(SESSION_MISSED_KEY) === key) return;
  const body =
    missedWeeks.length === 1
      ? `You have no submission for week ${missedWeeks[0]}. Submit as soon as possible.`
      : `You have no submissions for weeks ${missedWeeks.join(", ")}.`;
  notifyDesktop("Internship — missed weekly deadline", body, `missed-${key}`);
  sessionStorage.setItem(SESSION_MISSED_KEY, key);
}

const LS_LAST_DUE = "internlink-notified-current-week-due";

/** At most one reminder per calendar day per current internship week (when still no submission). */
export function maybeNotifyCurrentWeekDue(currentInternshipWeek: number, hasSubmissionForWeek: boolean): void {
  if (hasSubmissionForWeek) return;
  if (!getDesktopNotifyOptIn() || !canUseDesktopNotify() || Notification.permission !== "granted") return;
  if (typeof localStorage === "undefined") return;
  const today = new Date().toDateString();
  const mark = `${today}-w${currentInternshipWeek}`;
  try {
    if (localStorage.getItem(LS_LAST_DUE) === mark) return;
  } catch {
    return;
  }
  notifyDesktop(
    "Internship — weekly plan due",
    `Submit your Week ${currentInternshipWeek} plan before ${WEEKLY_SUBMISSION_DEADLINE_LABEL}.`,
    `due-w${currentInternshipWeek}`
  );
  try {
    localStorage.setItem(LS_LAST_DUE, mark);
  } catch {
    /* ignore */
  }
}
