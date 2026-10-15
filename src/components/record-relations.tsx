"use client";
import { useState } from "react";
import { modules, moduleMap, type CatalogRecord } from "@/lib/catalog";
import { type RecordResult } from "./record-list";
import { ErrorBox, Icon, Loading, useDebounce, useResource } from "./ui";

export function RecordPicker({ onSelect, exclude, fixedKind, canSelect }: { onSelect: (record: CatalogRecord) => void; exclude?: string; fixedKind?: string; canSelect?: (record: CatalogRecord) => boolean }) {
  const [query, setQuery] = useState(""); const [search, setSearch] = useState(""); const [kind, setKind] = useState(""); const [page, setPage] = useState(1);
  const debounce = useDebounce();
  const resource = useResource<RecordResult>(`/api/records?${new URLSearchParams({ q: search, kind: fixedKind || kind, page: String(page) })}`);
  const results = resource.data?.data.filter(record => record.id !== exclude) || [];
  return <div className="record-picker"><form className="toolbar compact" onSubmit={e => {e.preventDefault();setSearch(query);setPage(1);}}><label className="search-field"><Icon name="search"/><input aria-label="Tìm hồ sơ liên kết" placeholder="Tìm tên hồ sơ…" value={query} onChange={e => { const value = e.target.value; setQuery(value); debounce(() => { setSearch(value.trim()); setPage(1); }); }}/></label>{!fixedKind && <select aria-label="Loại hồ sơ liên kết" value={kind} onChange={e => {setKind(e.target.value);setPage(1);}}><option value="">Tất cả danh mục</option>{modules.map(m => <option key={m.kind} value={m.kind}>{m.label}</option>)}</select>}</form>{resource.loading && !resource.data ? <Loading/> : resource.error ? <ErrorBox error={resource.error} retry={resource.refresh}/> : <><div className="picker-results">{results.map(record => { const selectable = !canSelect || canSelect(record); return <button className="picker-row" key={record.id} disabled={!selectable} onClick={() => onSelect(record)}><span><strong>{record.title}</strong><small>{selectable ? moduleMap[record.kind]?.label : 'Bạn không có quyền cập nhật hồ sơ liên danh này'}</small></span><Icon name="plus"/></button>; })}{!results.length && <p className="muted">Không có hồ sơ phù hợp.</p>}</div><div className="pagination"><span>Trang {page}</span><div className="actions"><button className="button small" disabled={page === 1} onClick={() => setPage(p => p-1)}>Trước</button><button className="button small" disabled={!resource.data || page * resource.data.pageSize >= resource.data.total} onClick={() => setPage(p => p+1)}>Sau</button></div></div></>}</div>;
}
