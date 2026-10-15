// Remembers a catalog list's search, filters, page and view per tab, so returning from a record restores it.
// The trash filter is deliberately not remembered: a catalog reopened from the menu should show active records.
// Session storage can be unavailable (private mode, blocked site data); the list then simply starts fresh.
export type ListViewState = { query: string; status: string; kind: string; page: number; view: 'cards' | 'table' };

const prefix = 'pvn-ai-catalog:list:';

export function readListViewState(key: string): Partial<ListViewState> {
  try {
    const value: unknown = JSON.parse(window.sessionStorage.getItem(prefix + key) || '{}');
    if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
    const saved = value as Record<string, unknown>;
    return {
      ...(typeof saved.query === 'string' ? { query: saved.query.slice(0, 250) } : {}),
      ...(typeof saved.status === 'string' ? { status: saved.status } : {}),
      ...(typeof saved.kind === 'string' ? { kind: saved.kind } : {}),
      ...(Number.isInteger(saved.page) && Number(saved.page) >= 1 ? { page: Number(saved.page) } : {}),
      ...(saved.view === 'cards' || saved.view === 'table' ? { view: saved.view } : {}),
    };
  } catch { return {}; }
}

export function writeListViewState(key: string, state: ListViewState) {
  try { window.sessionStorage.setItem(prefix + key, JSON.stringify(state)); } catch { /* Storage is optional. */ }
}
