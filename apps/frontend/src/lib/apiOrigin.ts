/** Base URL for static files (uploads) and non-/api paths. Aligns with api client base URL normalization. */
export function getApiOrigin(): string {
  const raw = (process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000").trim().replace(/\/+$/, "");
  const withApi = raw.endsWith("/api") ? raw : `${raw}/api`;
  return withApi.replace(/\/api\/?$/, "");
}
