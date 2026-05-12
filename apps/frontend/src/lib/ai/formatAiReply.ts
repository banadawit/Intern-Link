/**
 * Normalises AI replies for the rich-text chat renderer.
 * Preserves **bold**, ## headings, bullet lists, and emojis.
 */
export function formatAiReplyForDisplay(raw: string): string {
  if (!raw) return "";

  let s = raw.replace(/\r\n/g, "\n");

  // Fenced code blocks: keep inner text only
  s = s.replace(/```[\w]*\n?([\s\S]*?)```/g, (_, inner: string) => `\n${inner.trim()}\n`);

  // Inline code → plain text
  s = s.replace(/`([^`]+)`/g, "$1");

  const lines = s.split("\n");
  const out: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();

    // Skip standalone decorative rules (---, ***, ___)
    if (/^[-*_]{3,}$/.test(trimmed)) continue;

    // Normalise ATX headings: ## Title → **Title** (bold heading)
    const headingMatch = line.match(/^\s*#{1,6}\s+(.+)$/);
    if (headingMatch) {
      if (out.length > 0 && out[out.length - 1] !== "") out.push("");
      out.push(`**${headingMatch[1].trim()}**`);
      out.push("");
      continue;
    }

    // Numbered list: "1. Item" or "1) Item"
    const numMatch = trimmed.match(/^(\d{1,3})([.)]) (.*)$/);
    if (numMatch) {
      out.push(`${numMatch[1]}. ${numMatch[3].trim()}`);
      continue;
    }

    // Bullet: "- item" or "* item" (but not bold **)
    const bulletMatch = trimmed.match(/^[-*]\s+(.*)$/) && !trimmed.startsWith("**");
    if (bulletMatch) {
      const content = trimmed.replace(/^[-*]\s+/, "");
      out.push(`• ${content}`);
      continue;
    }

    out.push(line.trimEnd());
  }

  let result = out.join("\n");
  result = result.replace(/\n{3,}/g, "\n\n");
  return result.trim();
}
