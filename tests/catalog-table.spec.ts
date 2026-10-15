import { test, expect } from '@playwright/test';
import { daysSince, emptyTableState, filterOptions, filterRows, isFiltered, rankIn, sortRows, toCsv, type QuickFilter, type TableColumn, type TableFilter } from '../src/lib/catalog-table';

type Row = { id: string; title: string; status: string; units: string[]; count: number | null; note: string };
const rows: Row[] = [
  { id: '1', title: 'Đánh giá địa chấn', status: 'POC', units: ['PVEP', 'BSR'], count: 3, note: '' },
  { id: '2', title: 'Ác quy dữ liệu', status: 'Đề xuất', units: ['BSR'], count: null, note: 'Họp, ký "MOU"\nquý 4' },
  { id: '3', title: 'Bảo trì dự đoán', status: 'Vận hành', units: [], count: 10, note: '' },
];
const columns: TableColumn<Row>[] = [
  { key: 'title', label: 'Tên', text: row => row.title },
  { key: 'count', label: 'Số', numeric: true, text: row => row.count == null ? '' : String(row.count), sort: row => row.count },
  { key: 'note', label: 'Ghi chú', text: row => row.note },
];
const unitFilter: TableFilter<Row> = { key: 'unit', label: 'Đơn vị', all: 'Mọi đơn vị', values: row => row.units };
const quick: QuickFilter<Row>[] = [{ key: 'empty', label: 'Chưa có đơn vị', test: row => !row.units.length }];

test('filters match any of several values and combine with quick filters and accent-free search', () => {
  const state = { ...emptyTableState, filters: { unit: 'BSR' } };
  expect(filterRows(rows, state, columns, [unitFilter], quick).map(row => row.id)).toEqual(['1', '2']);
  expect(filterRows(rows, { ...state, query: 'dia chan' }, columns, [unitFilter], quick).map(row => row.id)).toEqual(['1']);
  expect(filterRows(rows, { ...emptyTableState, quick: ['empty'] }, columns, [unitFilter], quick).map(row => row.id)).toEqual(['3']);
  expect(isFiltered(emptyTableState)).toBe(false);
  expect(isFiltered({ ...emptyTableState, filters: { unit: '' } })).toBe(false);
  expect(isFiltered(state)).toBe(true);
});

test('filter options are counted from the data, the given order first', () => {
  expect(filterOptions(rows, unitFilter)).toEqual([{ value: 'BSR', count: 2 }, { value: 'PVEP', count: 1 }]);
  expect(filterOptions(rows, { ...unitFilter, order: ['PVEP'] })[0].value).toBe('PVEP');
});

test('sorting keeps empty values last in both directions and compares Vietnamese text', () => {
  expect(sortRows(rows, columns, { key: 'count', desc: false }).map(row => row.id)).toEqual(['1', '3', '2']);
  expect(sortRows(rows, columns, { key: 'count', desc: true }).map(row => row.id)).toEqual(['3', '1', '2']);
  expect(sortRows(rows, columns, { key: 'title', desc: false }).map(row => row.title)).toEqual(['Ác quy dữ liệu', 'Bảo trì dự đoán', 'Đánh giá địa chấn']);
  expect(sortRows(rows, columns, null)).toBe(rows);
  expect(rankIn(['Đề xuất', 'POC'], 'POC')).toBe(1);
  expect(rankIn(['Đề xuất'], 'Khác')).toBe(1);
  expect(rankIn(['Đề xuất'], null)).toBeNull();
});

test('CSV opens in Excel with Vietnamese text, quoted separators and line breaks', () => {
  const csv = toCsv(columns, rows.slice(1, 2));
  expect(csv.startsWith('﻿')).toBe(true);
  expect(csv.slice(1).split('\r\n')).toEqual(['Tên,Số,Ghi chú', 'Ác quy dữ liệu,,"Họp, ký ""MOU""\nquý 4"']);
});

test('days since a date ignore missing or invalid values', () => {
  const now = new Date('2026-10-15T12:00:00');
  expect(daysSince('2026-10-05', now)).toBe(10);
  expect(daysSince(null, now)).toBeNull();
  expect(daysSince('không rõ', now)).toBeNull();
});

test('search also matches names a column lists for search only, such as a unit full name beside its abbreviation', () => {
  const units: TableColumn<Row> = { key: 'units', label: 'Đơn vị', text: row => row.units.join(', '), search: row => row.units.map(unit => unit === 'BSR' ? 'Công ty Cổ phần Lọc hóa dầu Bình Sơn' : unit) };
  expect(filterRows(rows, { ...emptyTableState, query: 'binh son' }, [units]).map(row => row.id)).toEqual(['1', '2']);
  expect(filterRows(rows, { ...emptyTableState, query: 'bsr' }, [units]).map(row => row.id)).toEqual(['1', '2']);
});
