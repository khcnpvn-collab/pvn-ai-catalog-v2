"use client";
import { useEffect, useState } from "react";
import { modules, moduleMap, type CatalogRecord } from "@/lib/catalog";
import { summaryRecordDescription } from "@/lib/dossier-summary";
import { readListViewState, writeListViewState } from "@/lib/list-view-state";
import { Badge, date, Empty, ErrorBox, Heading, Icon, Loading, RecordAvatar, useResource, useDebounce } from "./ui";
import { recordExcerpt, recordShortName, recordTypeLabel, visibleOperationalStatus, visibleRecordStatus } from "@/lib/record-presentation";

export type RecordResult = { data: CatalogRecord[]; total: number; page: number; pageSize: number };
// Catalog pages show a classification column; cross-catalog search keeps the source date instead.
export function RecordTable({ records, onOpen, showKind = false, showType = false }: { records: CatalogRecord[]; onOpen: (id: string) => void; showKind?: boolean; showType?: boolean }) {
  return <div className="table-scroll" tabIndex={0} role="region" aria-label="Bảng hồ sơ"><table><thead><tr><th>Hồ sơ</th>{showKind && <th>Danh mục</th>}{showType && <th>Phân loại</th>}<th>Cập nhật</th><th aria-hidden="true"></th></tr></thead><tbody>{records.map(record => <tr key={record.id}><td><button className="record-name" onClick={() => onOpen(record.id)}>{record.title}</button><div className="record-meta">{visibleRecordStatus(record)}</div></td>{showKind && <td>{moduleMap[record.kind]?.label || record.kind}</td>}{showType && <td>{recordTypeLabel(record) || "—"}</td>}<td>{date(record.updated_at)}</td><td><button className="icon-button" tabIndex={-1} aria-hidden="true" onClick={() => onOpen(record.id)}><Icon name="arrow"/></button></td></tr>)}</tbody></table></div>;
}

// Catalogs with a navy banner and a card view; the description says what the catalog is for.
const catalogDescriptions: Record<string, string> = {
  partner: "Tra cứu năng lực đối tác và theo dõi các hoạt động từ một nơi.",
  unit: "Thông tin, đầu mối và các đợt làm việc của từng đơn vị trong cùng một hồ sơ.",
  expert: "Năng lực, kinh nghiệm và các hoạt động với chuyên gia.",
  use_case: "Danh mục bài toán AI và nhu cầu áp dụng trong Tập đoàn.",
  collaboration: "Các bên tham gia, hoạt động, mốc làm việc và tài liệu.",
};

function RecordCards({ records, onOpen }: { records: CatalogRecord[]; onOpen: (id: string) => void }) {
  return <div className="catalog-card-grid">{records.map(record => {
    const status = visibleRecordStatus(record);
    const type = recordTypeLabel(record);
    const description = summaryRecordDescription(record);
    return <button className="catalog-record-card" key={record.id} onClick={() => onOpen(record.id)}>
      <span className="catalog-card-top"><RecordAvatar title={record.title} short={recordShortName(record)}/>{status && <Badge>{status}</Badge>}</span>
      <strong className="catalog-card-title">{record.title}</strong>
      <span className="catalog-card-description">{description ? recordExcerpt(description, 145) : "Chưa bổ sung thông tin giới thiệu."}</span>
      {type && type !== description && <span className="catalog-card-tags"><span>{recordExcerpt(type, 64)}</span></span>}
      <span className="catalog-card-foot"><span>Cập nhật {date(record.updated_at)}</span><Icon name="arrow" size={16}/></span>
    </button>;
  })}</div>;
}

export default function RecordList({ kind, initialQuery = "", canWrite, onOpen, onCreate }: { kind?: string; initialQuery?: string; canWrite: boolean; onOpen: (id: string) => void; onCreate: (kind: string) => void }) {
  // Catalog lists remember their state; cross-catalog search is driven by the URL instead.
  const storageKey = kind ? `module:${kind}` : null;
  const [saved] = useState(() => storageKey ? readListViewState(storageKey) : {});
  const description = kind ? catalogDescriptions[kind] : undefined;
  const [query, setQuery] = useState(saved.query ?? initialQuery);
  const [submitted, setSubmitted] = useState(saved.query ?? initialQuery);
  const debounce = useDebounce();
  const [status, setStatus] = useState(saved.status ?? "");
  const [selectedKind, setSelectedKind] = useState(kind || saved.kind || "");
  const [page, setPage] = useState(saved.page ?? 1);
  const [view, setView] = useState<'cards' | 'table'>(description ? saved.view ?? 'cards' : 'table');
  useEffect(() => {
    if (storageKey) writeListViewState(storageKey, { query: submitted, status, kind: selectedKind, page, view });
  }, [storageKey, submitted, status, selectedKind, page, view]);
  const params = new URLSearchParams({ q: submitted, page: String(page), ...(selectedKind ? {kind:selectedKind} : {}), ...(status ? {status} : {}) });
  const resource = useResource<RecordResult>(`/api/records?${params}`, true);
  const mod = kind ? moduleMap[kind] : null;
  const activeModule = selectedKind ? moduleMap[selectedKind] : null;
  const operationalStatuses = (activeModule?.kind === "reference" ? [] : activeModule?.statuses || [...new Set(modules.filter(m => m.kind !== "reference").flatMap(m => m.statuses))]).filter(status => visibleOperationalStatus(status));
  const filtered = Boolean(submitted || status);
  const data = resource.data;
  const pages = data ? Math.max(1, Math.ceil(data.total / data.pageSize)) : 1;
  const createButton = canWrite && <button className="button primary" onClick={() => onCreate(selectedKind || "unit")}><Icon name="plus"/>Thêm {mod?.singular || 'hồ sơ'}</button>;
  function goToPage(next: number) { setPage(next); window.scrollTo({ top: 0 }); }
  return <div className="catalog-list">
    {description && mod ? <section className="catalog-banner"><div className="catalog-banner-copy"><h1>{mod.label}</h1><p>{description}</p></div><div className="catalog-banner-side">{data && <div className="catalog-stat"><strong>{data.total.toLocaleString('vi-VN')}</strong><span>{filtered ? 'hồ sơ theo bộ lọc' : 'hồ sơ hiện hành'}</span></div>}{createButton}</div></section>
      : <Heading title={mod?.label || "Tra cứu hồ sơ"} description={mod?.description || "Tìm trong tất cả danh mục."}>{createButton}</Heading>}
    <section className="catalog-results"><form className="toolbar" onSubmit={e => { e.preventDefault(); setSubmitted(query.trim()); setPage(1); }}>
      <label className="search-field"><Icon name="search"/><input aria-label="Tìm tên hoặc nội dung hồ sơ" value={query} onChange={e => { const value = e.target.value; setQuery(value); debounce(() => { setSubmitted(value.trim()); setPage(1); }); }} placeholder="Tìm tên hoặc nội dung…"/></label>
      {!kind && <select aria-label="Danh mục" value={selectedKind} onChange={e => {setSelectedKind(e.target.value); setStatus(""); setPage(1);}}><option value="">Tất cả danh mục</option>{modules.map(m => <option key={m.kind} value={m.kind}>{m.label}</option>)}</select>}
      {operationalStatuses.length > 0 && <select aria-label="Tình trạng hoạt động" value={status} onChange={e => {setStatus(e.target.value); setPage(1);}}><option value="">Tất cả tình trạng</option>{operationalStatuses.map(s => <option key={s}>{s}</option>)}</select>}
      {description && <div className="view-switch" role="group" aria-label="Kiểu xem"><button type="button" aria-label="Xem dạng thẻ" aria-pressed={view === 'cards'} onClick={() => setView('cards')}><Icon name="grid"/></button><button type="button" aria-label="Xem dạng bảng" aria-pressed={view === 'table'} onClick={() => setView('table')}><Icon name="menu"/></button></div>}
    </form>
      {resource.loading && !data ? <Loading/> : resource.error && !resource.loading ? <ErrorBox error={resource.error} retry={resource.refresh}/> : data && <div className={`catalog-results-body${resource.loading ? " is-refreshing" : ""}`} aria-busy={resource.loading}>
        {!description && <div className="catalog-results-label"><span>{data.total.toLocaleString('vi-VN')} hồ sơ</span></div>}
        {data.data.length ? view === 'cards' && description ? <RecordCards records={data.data} onOpen={onOpen}/> : <RecordTable records={data.data} onOpen={onOpen} showKind={!kind} showType={Boolean(description)}/>
          : page > 1 && data.total > 0 ? <Empty title="Trang này không còn hồ sơ" text="Danh mục đã thay đổi kể từ lần xem trước."><button className="button" onClick={() => goToPage(1)}>Về trang đầu</button></Empty>
          : <Empty title={submitted || status ? "Không tìm thấy hồ sơ" : "Chưa có hồ sơ trong danh mục"} text={submitted || status ? "Thử đổi từ khóa hoặc bỏ bộ lọc để tra cứu lại." : "Bổ sung hồ sơ từ thông tin, biên bản và tài liệu đã có."}>{canWrite && <button className="button" onClick={() => onCreate(selectedKind || "unit")}><Icon name="plus"/>Thêm hồ sơ</button>}</Empty>}
        {pages > 1 && <footer className="pagination"><span>Trang {page} / {pages}</span><div className="actions"><button className="button small" disabled={page === 1 || resource.loading} onClick={() => goToPage(page - 1)}>Trước</button><button className="button small" disabled={page >= pages || resource.loading} onClick={() => goToPage(page + 1)}>Sau</button></div></footer>}
      </div>}
    </section></div>;
}
