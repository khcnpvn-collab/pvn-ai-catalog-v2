"use client";
import { useState, type ReactNode } from 'react';
import { emptyTableState, filterOptions, filterRows, isFiltered, sortRows, toCsv, type QuickFilter, type TableColumn, type TableFilter, type TableState } from '@/lib/catalog-table';
import { dashboardStyles as styles } from './dashboard-primitives';
import { Icon } from './ui';

export type CatalogColumn<T> = TableColumn<T> & { render?: (row: T) => ReactNode };

// Filters survive opening a record and coming back to the list, for the whole browser session.
const memory = new Map<string, TableState>();
export function useTableState(key: string): [TableState, (next: TableState) => void] {
  const [state, setState] = useState<TableState>(() => memory.get(key) || emptyTableState);
  return [state, next => { memory.set(key, next); setState(next); }];
}

function download(name: string, content: string) {
  const url = URL.createObjectURL(new Blob([content], { type: 'text/csv;charset=utf-8' }));
  const link = document.createElement('a');
  link.href = url; link.download = `${name}-${new Date().toLocaleDateString('sv-SE')}.csv`;
  link.click(); URL.revokeObjectURL(url);
}

// One list of an overview page: search, select filters, quick filters, sortable headers, count and CSV export.
// The page owns the state, so its figures and charts can set the same filters.
export default function CatalogTable<T extends { id: string }>({ label, unit, rows, columns, filters = [], quick = [], state, onState, exportName, searchPlaceholder }: {
  label: string; unit: string; rows: T[]; columns: CatalogColumn<T>[]; filters?: TableFilter<T>[]; quick?: QuickFilter<T>[];
  state: TableState; onState: (state: TableState) => void; exportName: string; searchPlaceholder: string;
}) {
  const shown = sortRows(filterRows(rows, state, columns, filters, quick), columns, state.sort);
  const setFilter = (key: string, value: string) => onState({ ...state, filters: { ...state.filters, [key]: value } });
  const toggleQuick = (key: string) => onState({ ...state, quick: state.quick.includes(key) ? state.quick.filter(item => item !== key) : [...state.quick, key] });
  const sortBy = (key: string) => onState({ ...state, sort: state.sort?.key !== key ? { key, desc: false } : state.sort.desc ? null : { key, desc: true } });
  return <>
    <div className={styles.filters}>
      <label className="search-field"><Icon name="search"/><input aria-label={`Tìm trong ${label.toLocaleLowerCase('vi')}`} value={state.query} onChange={event => onState({ ...state, query: event.target.value })} placeholder={searchPlaceholder}/></label>
      {filters.map(filter => {
        const options = filterOptions(rows, filter);
        const value = state.filters[filter.key] || '';
        return <select key={filter.key} aria-label={filter.label} value={value} onChange={event => setFilter(filter.key, event.target.value)}>
          <option value="">{filter.all}</option>
          {value && !options.some(option => option.value === value) && <option value={value}>{value} (0)</option>}
          {options.map(option => <option key={option.value} value={option.value}>{option.value} ({option.count})</option>)}
        </select>;
      })}
    </div>
    {quick.length > 0 && <div className={styles.quickFilters} role="group" aria-label="Lọc nhanh"><span>Lọc nhanh</span>
      {quick.map(item => <button key={item.key} type="button" className={styles.quickChip} aria-pressed={state.quick.includes(item.key)} onClick={() => toggleQuick(item.key)}>
        {item.label}<span>{rows.filter(item.test).length}</span></button>)}
    </div>}
    <div className={styles.tableBar}>
      <p className={styles.count}>{shown.length} / {rows.length} {unit}</p>
      <div className="actions">
        {isFiltered(state) && <button type="button" className="text-button" onClick={() => onState({ ...emptyTableState, sort: state.sort })}><Icon name="close" size={15}/>Xóa bộ lọc</button>}
        <button type="button" className="button small" disabled={!shown.length} onClick={() => download(exportName, toCsv(columns, shown))}><Icon name="download" size={15}/>Xuất CSV</button>
      </div>
    </div>
    <div className="table-scroll" tabIndex={0} role="region" aria-label={label}><table className={styles.catalogTable}>
      <thead><tr>{columns.map(column => {
        const sorted = state.sort?.key === column.key ? (state.sort.desc ? 'descending' : 'ascending') : 'none';
        return <th key={column.key} aria-sort={sorted} className={`${column.numeric ? styles.numeric : ''} ${column.wide ? styles.wideColumn : ''}`}>
          <button type="button" className={styles.sortButton} onClick={() => sortBy(column.key)} title="Bấm để sắp xếp">{column.label}<span aria-hidden="true">{sorted === 'ascending' ? '↑' : sorted === 'descending' ? '↓' : '↕'}</span></button></th>;
      })}</tr></thead>
      <tbody>{shown.map(row => <tr key={row.id}>{columns.map(column => <td key={column.key} className={column.numeric ? styles.numeric : undefined} data-label={column.label}>{column.render ? column.render(row) : column.text(row) || '—'}</td>)}</tr>)}</tbody>
    </table></div>
    {!shown.length && <p className="related-group-empty">{rows.length ? 'Không có dòng nào khớp bộ lọc.' : `Chưa có ${unit}.`}</p>}
  </>;
}
