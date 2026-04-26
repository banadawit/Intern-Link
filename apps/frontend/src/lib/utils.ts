export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}

export function getFileUrl(url: string | null | undefined): string {
  if (!url) return "#";
  if (url.startsWith("http")) return url;
  
  const backendUrl = process.env.NEXT_PUBLIC_API_URL?.replace("/api", "") || "http://localhost:5000";
  return `${backendUrl}/${url.replace(/\\/g, "/")}`;
}

export function getViewerUrl(url: string | null | undefined): string {
  if (!url || url === "#") return "#";
  return `/view-document?url=${encodeURIComponent(url)}`;
}
