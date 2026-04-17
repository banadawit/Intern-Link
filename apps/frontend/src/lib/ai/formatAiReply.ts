/**
 * Cleans common markdown/decorative noise from AI replies for a professional plain-text chat UI.
 */
export function formatAiReplyForDisplay(raw: string): string {
  if (!raw) return "";

  let s = raw.replace(/\r\n/g, "\n");
  // If AI returns multiple day headings in one sentence, split them into separate lines.
  s = s.replace(
    /,\s*(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\s*:/gi,
    "\n$1:"
  );
  const weekdayLabels: Record<string, string> = {
    monday: "Monday",
    tuesday: "Tuesday",
    wednesday: "Wednesday",
    thursday: "Thursday",
    friday: "Friday",
    saturday: "Saturday",
    sunday: "Sunday",
  };

  // Fenced code blocks: keep inner text only
  s = s.replace(/```[\w]*\n?([\s\S]*?)```/g, (_, inner: string) => `\n${inner.trim()}\n`);

  // Bold / strong
  s = s.replace(/\*\*([^*]+)\*\*/g, "$1");
  s = s.replace(/__([^_]+)__/g, "$1");

  // Inline code
  s = s.replace(/`([^`]+)`/g, "$1");

  const lines = s.split("\n");
  const out: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();

    // Skip standalone decorative rules (---, ***, ___)
    if (/^[-*_]{3,}$/.test(trimmed)) {
      continue;
    }

    // Strip ATX heading markers at line start
    let body = line.replace(/^\s*#{1,6}\s+/, "");
    const t = body.trim();

    // Keep weekday section titles consistent (e.g. "monday", "**MONDAY**", "Tuesday -")
    const dayOnlyMatch = t.match(/^(?:\*\*)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*(?:\*\*)?\s*[:\-]?\s*$/i);
    if (dayOnlyMatch) {
      const day = weekdayLabels[dayOnlyMatch[1].toLowerCase()];
      if (out.length > 0 && out[out.length - 1] !== "") {
        out.push("");
      }
      out.push(`${day}:`);
      continue;
    }

    // Convert "Monday: task..." into a clean heading + aligned task line
    const dayInlineTaskMatch = t.match(/^(?:\*\*)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*(?:\*\*)?\s*[:\-]\s+(.+)$/i);
    if (dayInlineTaskMatch) {
      const day = weekdayLabels[dayInlineTaskMatch[1].toLowerCase()];
      if (out.length > 0 && out[out.length - 1] !== "") {
        out.push("");
      }
      out.push(`${day}:`);
      out.push(`• ${dayInlineTaskMatch[2].trim()}`);
      continue;
    }

    // Numbered list: "1. Item" or "1) Item"
    const numMatch = t.match(/^(\d{1,3})([.)])\s+(.*)$/);
    if (numMatch && (numMatch[2] === "." || numMatch[2] === ")")) {
      out.push(`${numMatch[1]}. ${numMatch[3].trim()}`);
      continue;
    }

    // Bullet: "- item" or "* item"
    const bulletMatch = t.match(/^[-*]\s+(.*)$/);
    if (bulletMatch) {
      out.push(`• ${bulletMatch[1].trim()}`);
      continue;
    }

    out.push(body.trimEnd());
  }

  let result = out.join("\n");
  result = result.replace(/\n{3,}/g, "\n\n");
  return result.trim();
}
