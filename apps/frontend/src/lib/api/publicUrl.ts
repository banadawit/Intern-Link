/** Base URL for backend (no /api suffix) — used for static uploads */
export function getApiOrigin(): string {
  const base = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000/api";
  return base.replace(/\/api\/?$/, "");
}

/** Turn stored path from multer (e.g. uploads/presentations/x.pdf) into a browser URL */
export function apiFileUrl(storedPath: string | null | undefined): string {
  if (!storedPath) return "";
  if (storedPath.startsWith("http")) return storedPath;
  const origin = getApiOrigin();
  const clean = storedPath.replace(/\\/g, "/");
  return `${origin}/${clean.replace(/^\//, "")}`;
}
