"use client";
import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { statusTone } from "@/lib/status-tone";

export class ApiError extends Error { constructor(message: string, public status: number) { super(message); } }
export async function api<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(url, { ...options, headers: { ...(options?.body instanceof FormData ? {} : { "Content-Type": "application/json" }), ...options?.headers }, cache: "no-store" });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) throw new ApiError(result.error || "Không thể hoàn tất yêu cầu. Vui lòng thử lại.", response.status);
  return result as T;
}
// keepPrevious keeps the last successful result visible while the next request loads, so lists do not flash empty.
export function useResource<T>(url: string | null, keepPrevious = false) {
  const [revision, setRevision] = useState(0);
  const key = `${url}:${revision}`;
  const [state, setState] = useState<{ key: string; data?: T; error?: Error }>({ key: "" });
  useEffect(() => {
    if (!url) return;
    const controller = new AbortController();
    api<T>(url, { signal: controller.signal }).then(data => setState({ key, data })).catch(error => { if (!controller.signal.aborted) setState({ key, error }); });
    return () => controller.abort();
  }, [url, key]);
  const current = state.key === key;
  return { data: current || keepPrevious ? state.data : undefined, error: current ? state.error : undefined, loading: Boolean(url) && !current, refresh: () => setRevision(v => v + 1) };
}
const DISCARD_PROMPT = "Thay đổi chưa lưu sẽ bị mất. Bạn vẫn muốn rời biểu mẫu?";
// Forms mark themselves with data-dirty="true" while they hold unsaved input.
export function hasUnsavedChanges(scope: ParentNode | null | undefined) { return Boolean(scope?.querySelector('[data-dirty="true"]')); }
export function confirmDiscardChanges(dirty = typeof document !== "undefined" && hasUnsavedChanges(document)) { return !dirty || window.confirm(DISCARD_PROMPT); }
export function message(error: unknown) { return error instanceof Error ? error.message : "Đã có lỗi xảy ra."; }
export function date(value: string | null | undefined) { return value ? new Date(value).toLocaleDateString("vi-VN") : "Chưa ghi nhận"; }
export function Icon({ name = "file", size = 20 }: { name?: string; size?: number }) {
  const paths: Record<string, ReactNode> = {
    search: <><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4 4"/></>,
    plus: <path d="M12 5v14M5 12h14"/>, check: <path d="m5 12 5 5 9-10"/>, close: <path d="m6 6 12 12M6 18 18 6"/>,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5"/>, back: <path d="M19 12H5m5-5-5 5 5 5"/>,
    grid: <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></>,
    folder: <path d="M3 7V4h6l3 3h9v13H3V7Z"/>,
    file: <><path d="M14 3H5v18h14V8l-5-5Z"/><path d="M14 3v5h5M8 12h8M8 16h6"/></>,
    building: <><path d="M3 21h18M5 21V7l7-4 7 4v14M9 21v-5h6v5M9 8h.01M15 8h.01M9 12h.01M15 12h.01"/></>,
    people: <><circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6M18 15a5 5 0 0 1 3 4v2"/></>,
    user: <><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>,
    spark: <><path d="M11 3 12.8 8.2 18 10l-5.2 1.8L11 17l-1.8-5.2L4 10l5.2-1.8L11 3Z"/><path d="m18.5 14 .8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2Z"/></>,
    refresh: <><path d="M20 11a8 8 0 0 0-14.9-3M4 13a8 8 0 0 0 14.9 3"/><path d="M5 3v5h5M19 21v-5h-5"/></>,
    link: <><path d="m9 15 6-6M8 16l-1 1a4 4 0 0 1-6-6l4-4a4 4 0 0 1 6 0M16 8l1-1a4 4 0 0 1 6 6l-4 4a4 4 0 0 1-6 0" transform="translate(1 0) scale(.92 1)"/></>,
    database: <><ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v14c0 4 16 4 16 0V5M4 12c0 4 16 4 16 0"/></>,
    book: <><path d="M12 5v16M12 5C8 2 3 3 3 3v16s5-1 9 2c4-3 9-2 9-2V3s-5-1-9 2Z"/></>,
    upload: <><path d="M12 16V3m-5 5 5-5 5 5M3 16v5h18v-5"/></>,
    download: <><path d="M12 3v13m-5-5 5 5 5-5M3 16v5h18v-5"/></>,
    eye: <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></>,
    logout: <><path d="M9 3H4v18h5M9 12h12m-4-4 4 4-4 4"/></>,
    menu: <path d="M4 6h16M4 12h16M4 18h16"/>,
    clock: <><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></>,
    shield: <><path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Z"/><path d="m8 12 3 3 5-6"/></>,
    trash: <><path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/></>,
    restore: <><path d="M3 10a9 9 0 1 1 2 8M3 4v6h6M12 7v5l3 2"/></>,
    edit: <><path d="m15 4 5 5M4 20l5-1L21 7l-5-5L4 14v6Z"/></>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] || paths.file}</svg>;
}
export function ErrorBox({ error, retry }: { error?: Error | string | null; retry?: () => void }) { return error ? <div className="notice error" role="alert"><div>{typeof error === "string" ? error : error.message}</div>{retry && <button className="button small" onClick={retry}>Thử lại</button>}</div> : null; }
export function Loading({ label = "Đang tải dữ liệu…" }: { label?: string }) { return <div className="loading" role="status"><span>{label}</span><div className="skeleton"/><div className="skeleton"/><div className="skeleton short"/></div>; }
export function Empty({ title = "Chưa có hồ sơ", text = "Dữ liệu sẽ xuất hiện tại đây khi được bổ sung.", children }: { title?: string; text?: string; children?: ReactNode }) { return <div className="empty"><Icon name="file" size={32}/><h3>{title}</h3><p>{text}</p>{children}</div>; }
// A known status gets its colour automatically, the same one used in charts.
// Runs the latest scheduled task once typing pauses, so a search follows the keyboard without a request per key.
export function useDebounce(delay = 300) {
  const timer = useRef<number | undefined>(undefined);
  useEffect(() => () => window.clearTimeout(timer.current), []);
  return useCallback((run: () => void) => { window.clearTimeout(timer.current); timer.current = window.setTimeout(run, delay); }, [delay]);
}

export function Badge({ children }: { children: ReactNode }) { const tone = typeof children === 'string' ? statusTone(children) : null; return <span className={tone ? `badge tone-${tone}` : 'badge'}>{children}</span>; }
// A short name such as PVEP identifies a record better than generic initials ("CT" for every "Công ty ...").
export function RecordAvatar({ title, short, large = false }: { title: string; short?: string | null; large?: boolean }) {
  const initials = short || title.trim().split(/\s+/).slice(0, 2).map(word => Array.from(word)[0]).join('');
  return <span className={`record-avatar${large ? ' large' : ''}`} aria-hidden="true">{initials.toLocaleUpperCase('vi')}</span>;
}
export function Heading({ title, description, children }: { title: string; description?: string; children?: ReactNode }) { return <header className="page-heading"><div><h1>{title}</h1>{description && <p>{description}</p>}</div>{children && <div className="actions">{children}</div>}</header>; }
