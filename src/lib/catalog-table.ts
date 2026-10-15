import { matchesSearch } from './overview';

// The behaviour shared by every list on the overview pages: search, select filters, quick filters,
// sorting and CSV export. Each page declares its own columns and filters over its own row type.
export type SortValue = string | number | null | undefined;
export type TableColumn<T> = {
  key: string; label: string;
  // Plain text of the cell: searched, exported to CSV and, without sort, used for sorting.
  text: (row: T) => string;
  // Further names the search should match that the cell does not print, e.g. a unit's full name beside its abbreviation.
  search?: (row: T) => (string | null | undefined)[];
  sort?: (row: T) => SortValue;
  numeric?: boolean;
  wide?: boolean;
};
// A row can match several values, e.g. every unit taking part in an activity.
export type TableFilter<T> = { key: string; label: string; all: string; values: (row: T) => (string | null | undefined)[] | string | null | undefined; order?: readonly string[] };
export type QuickFilter<T> = { key: string; label: string; test: (row: T) => boolean };
export type TableState = { query: string; filters: Record<string, string>; quick: string[]; sort: { key: string; desc: boolean } | null };
export const emptyTableState: TableState = { query: '', filters: {}, quick: [], sort: null };

export function filterValues<T>(filter: TableFilter<T>, row: T): string[] {
  const values = filter.values(row);
  return (Array.isArray(values) ? values : [values]).filter((value): value is string => Boolean(value?.toString().trim())).map(String);
}

// Choices of a select filter, from the data itself: the given order first, then the most frequent.
export function filterOptions<T>(rows: T[], filter: TableFilter<T>): { value: string; count: number }[] {
  const counts = new Map<string, number>();
  for (const row of rows) for (const value of new Set(filterValues(filter, row))) counts.set(value, (counts.get(value) || 0) + 1);
  const order = filter.order || [];
  return [...counts].map(([value, count]) => ({ value, count })).sort((a, b) => {
    const rank = (value: string) => order.includes(value) ? order.indexOf(value) : order.length;
    return rank(a.value) - rank(b.value) || b.count - a.count || a.value.localeCompare(b.value, 'vi');
  });
}

export function isFiltered(state: TableState): boolean {
  return Boolean(state.query.trim() || state.quick.length || Object.values(state.filters).some(Boolean));
}

export function filterRows<T>(rows: T[], state: TableState, columns: TableColumn<T>[], filters: TableFilter<T>[] = [], quick: QuickFilter<T>[] = []): T[] {
  const active = filters.filter(filter => state.filters[filter.key]);
  const tests = quick.filter(item => state.quick.includes(item.key));
  return rows.filter(row => active.every(filter => filterValues(filter, row).includes(state.filters[filter.key]))
    && tests.every(item => item.test(row))
    && matchesSearch(state.query, ...columns.flatMap(column => [column.text(row), ...(column.search?.(row) || [])])));
}

// Empty values always go last, whatever the direction; text compares the Vietnamese way, numbers by value.
export function sortRows<T>(rows: T[], columns: TableColumn<T>[], sort: TableState['sort']): T[] {
  const column = sort && columns.find(item => item.key === sort.key);
  if (!column || !sort) return rows;
  const value = (row: T): SortValue => column.sort ? column.sort(row) : column.text(row);
  const empty = (item: SortValue) => item === null || item === undefined || item === '';
  return [...rows].sort((a, b) => {
    const x = value(a), y = value(b);
    if (empty(x) || empty(y)) return Number(empty(x)) - Number(empty(y));
    const order = typeof x === 'number' && typeof y === 'number' ? x - y : String(x).localeCompare(String(y), 'vi', { numeric: true });
    return sort.desc ? -order : order;
  });
}

// UTF-8 with a byte order mark so Excel reads Vietnamese; cells with separators, quotes or line breaks are quoted.
export function toCsv<T>(columns: TableColumn<T>[], rows: T[]): string {
  const cell = (value: string) => /[",;\r\n]/.test(value) ? `"${value.replace(/"/g, '""')}"` : value;
  const lines = [columns.map(column => cell(column.label)), ...rows.map(row => columns.map(column => cell(column.text(row) ?? '')))];
  return '﻿' + lines.map(line => line.join(',')).join('\r\n');
}

// Days since a date (YYYY-MM-DD or ISO time); null when there is no date.
export function daysSince(value: string | null | undefined, now = new Date()): number | null {
  if (!value) return null;
  const time = new Date(value.length === 10 ? `${value}T00:00:00` : value).getTime();
  return Number.isNaN(time) ? null : Math.floor((now.getTime() - time) / 86400000);
}

// Sort by a list's own order (lifecycle stages, levels); values outside the list follow.
export function rankIn(order: readonly string[], value: string | null | undefined): number | null {
  if (!value) return null;
  const index = order.indexOf(value);
  return index < 0 ? order.length : index;
}
