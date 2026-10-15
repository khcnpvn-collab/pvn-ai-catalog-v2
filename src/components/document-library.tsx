"use client";
import { useState, type FormEvent } from "react";
import { type CatalogDocument, type Membership } from "@/lib/catalog";
import { DOCUMENT_ACCEPT, validateUploadFiles } from "@/lib/document-upload";
import { canPreviewFile, currentFile } from "@/lib/document-presentation";
import { api, date, Empty, ErrorBox, Heading, Icon, Loading, message, useDebounce, useResource } from "./ui";
function bytes(value: number) { return value >= 1048576 ? `${(value / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(value / 1024))} KB`; }
export function UploadForm({ recordId, document, onUploaded, onDone, onCancel }: { recordId?: string; document?: CatalogDocument; onUploaded?: () => void; onDone: () => void; onCancel: () => void }) {
  const [title, setTitle] = useState(document?.title || "");
  const [files, setFiles] = useState<File[]>([]); const [busy, setBusy] = useState(false); const [error, setError] = useState<string | null>(null);
  async function upload(event: FormEvent) {
    event.preventDefault();
    const invalid = validateUploadFiles(files);
    if (invalid) { setError(invalid); return; }
    setBusy(true); setError(null); let completed = 0;
    try {
      for (const file of files) {
        const body = new FormData(); body.set("file", file); body.set("title", title.trim() || file.name);
        if (recordId) body.set("record_id", recordId); if (document) body.set("document_id", document.id);
        await api("/api/documents", { method: "POST", body }); completed++; onUploaded?.();
      }
      onDone();
    } catch (e) { setFiles(files.slice(completed)); setError(`${completed ? `Đã tải ${completed} tệp. ` : ""}${message(e)}`); } finally { setBusy(false); }
  }
  return <form className="inline-form" onSubmit={upload} aria-label="Đính kèm tệp tài liệu"><div className="section-heading"><h3>{document ? `Thêm phiên bản: ${document.title}` : "Đính kèm tệp tài liệu"}</h3><button className="icon-button" type="button" onClick={onCancel} aria-label="Đóng biểu mẫu tải lên" disabled={busy}><Icon name="close"/></button></div><div className="form-grid"><label className="field full">{document ? "Tệp phiên bản mới" : "Chọn tệp từ máy tính"}<input type="file" accept={DOCUMENT_ACCEPT} required disabled={busy} multiple={!document} onChange={e => { setFiles(Array.from(e.target.files || [])); setError(null); }}/><small>PDF, Word, Excel, PowerPoint, TXT, CSV hoặc ảnh PNG/JPG. Tối đa 20 MB mỗi tệp.</small></label>
    {files.length > 0 && <div className="field full" aria-live="polite"><strong>{files.length} tệp đã chọn</strong><ul>{files.map((file, index) => <li key={`${file.name}-${index}`}>{file.name} · {bytes(file.size)}</li>)}</ul></div>}
    <label className="field full">Tên tài liệu<input maxLength={250} disabled={busy} value={title} onChange={e => setTitle(e.target.value)} placeholder="Để trống để dùng tên tệp"/></label></div><ErrorBox error={error}/><div className="actions"><button className="button primary" disabled={busy || !files.length}>{busy ? "Đang lưu tệp…" : `Lưu${files.length > 1 ? ` ${files.length}` : ""} tệp đính kèm`}</button><button className="button" type="button" onClick={onCancel} disabled={busy}>Hủy</button></div></form>;
}
export function DocumentItems({ documents, membership, onOpen, onRefresh, recordId, showLinkedRecords = true, allowChanges = true }: { documents: CatalogDocument[]; membership: Membership; onOpen: (id: string) => void; onRefresh: () => void; recordId?: string; showLinkedRecords?: boolean; allowChanges?: boolean }) {
  const [confirm, setConfirm] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  async function remove(documentId: string) {
    setBusy(true); setError(null);
    try {
      await api(recordId ? `/api/documents/${documentId}/link` : `/api/documents/${documentId}`, { method: 'DELETE', ...(recordId ? { body: JSON.stringify({ record_id: recordId }) } : {}) });
      setConfirm(null); onRefresh();
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  return <><ErrorBox error={error}/><div className="document-list">{documents.map(document => {
    const file = currentFile(document);
    const canRemove = allowChanges && (recordId ? membership.role !== 'reader' : membership.role === 'admin' || document.created_by === membership.user_id);
    return <article className="document-item" key={document.id}><div className="document-icon"><Icon name="file" size={24}/></div><div className="document-body"><h3>{document.title}</h3><p>{file ? [file.filename, bytes(file.size_bytes), date(file.created_at), document.created_by_name ? `Tải lên: ${document.created_by_name}` : ''].filter(Boolean).join(' · ') : 'Chưa có file'}</p>{showLinkedRecords && (document.linked_records?.length ?? 0) > 0 && <div className="document-links">Được dùng trong: {document.linked_records?.map(record => <button key={record.id} className="text-button" onClick={() => onOpen(record.id)}>{record.title}</button>)}</div>}{confirm === document.id && <div className="document-confirm"><p>{recordId ? 'Gỡ file khỏi hồ sơ này? File vẫn còn ở kho chung và các hồ sơ khác.' : 'Xóa file khỏi kho chung và tất cả hồ sơ đang dùng?'}</p><div className="actions"><button className="button small danger" onClick={() => remove(document.id)} disabled={busy}>{busy ? 'Đang xóa…' : 'Xác nhận'}</button><button className="button small" onClick={() => setConfirm(null)} disabled={busy}>Hủy</button></div></div>}</div><div className="document-actions">{file && canPreviewFile(file) && <a className="icon-button" href={`/api/documents/${file.id}/download?preview=1`} target="_blank" rel="noopener noreferrer" title="Xem trước" aria-label={`Xem trước ${document.title}`}><Icon name="eye" size={17}/></a>}{file && <a className="icon-button" href={`/api/documents/${file.id}/download`} title="Tải về" aria-label={`Tải về ${document.title}`}><Icon name="download" size={17}/></a>}{canRemove && <button className="icon-button danger-text" onClick={() => setConfirm(document.id)} disabled={busy} title={recordId ? 'Gỡ khỏi hồ sơ' : 'Xóa file'} aria-label={`${recordId ? 'Gỡ khỏi hồ sơ' : 'Xóa file'} ${document.title}`}><Icon name="trash" size={17}/></button>}</div></article>;
  })}</div></>;
}
export function ReuseDocument({ recordId, onDone, onCancel }: { recordId: string; onDone: () => void; onCancel: () => void }) {
  const [query, setQuery] = useState(""); const [search, setSearch] = useState(""); const [selected, setSelected] = useState("");
  const debounce = useDebounce();
  const [busy, setBusy] = useState(false); const [error, setError] = useState<string | null>(null);
  const resource = useResource<{ data: CatalogDocument[] }>(`/api/documents?q=${encodeURIComponent(search)}`);
  const document = resource.data?.data.find(d => d.id === selected);
  async function attach() { if (!document) return; setBusy(true); setError(null); try { await api("/api/documents/link", {method:"POST",body:JSON.stringify({record_id:recordId,document_id:document.id,version_id:currentFile(document)?.id || null})}); onDone(); } catch(e) {setError(message(e));} finally {setBusy(false);} }
  return <div className="inline-form"><div className="section-heading"><h3>Dùng lại file có sẵn</h3><button className="icon-button" onClick={onCancel} aria-label="Đóng chọn tài liệu"><Icon name="close"/></button></div><form className="toolbar compact" onSubmit={e => {e.preventDefault(); setSearch(query); setSelected("");}}><label className="search-field"><Icon name="search"/><input aria-label="Tìm tài liệu để liên kết" value={query} onChange={e => { const value = e.target.value; setQuery(value); debounce(() => { setSearch(value.trim()); setSelected(""); }); }} placeholder="Tên file…"/></label></form>{resource.loading && !resource.data ? <Loading/> : resource.error ? <ErrorBox error={resource.error} retry={resource.refresh}/> : <div className="reuse-document-results"><p className="muted">{resource.data?.data.length || 0} file{(resource.data?.data.length || 0) >= 200 ? " mới nhất; tìm theo tên để thu hẹp" : ""}</p><div className="picker-results" role="group" aria-label="Chọn file">{resource.data?.data.length ? resource.data.data.map(d => { const file = currentFile(d); return <button type="button" className="picker-row" aria-pressed={d.id === selected} key={d.id} onClick={() => setSelected(d.id)}><span><strong>{d.title}</strong><small>{file ? `${file.filename} · ${bytes(file.size_bytes)} · ${date(file.created_at)}` : "Chưa có file"}</small></span>{d.id === selected && <Icon name="check" size={18}/>}</button>; }) : <p className="muted">Không có file phù hợp.</p>}</div></div>}<ErrorBox error={error}/><button className="button primary" onClick={attach} disabled={!document || busy}>{busy ? "Đang liên kết…" : "Gắn file vào hồ sơ"}</button></div>;
}
export default function DocumentLibrary({ membership, onOpen }: { membership: Membership; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState(""); const [search, setSearch] = useState(""); const [upload, setUpload] = useState(false);
  const debounce = useDebounce();
  const resource = useResource<{ data: CatalogDocument[] }>(`/api/documents?q=${encodeURIComponent(search)}`);
  return <><Heading title="Tài liệu dùng chung" description="Tra cứu file và tài liệu đã lưu.">{membership.role !== "reader" && <button className="button primary" onClick={() => setUpload(true)}><Icon name="upload"/>Tải tài liệu</button>}</Heading>{upload && <UploadForm onCancel={() => setUpload(false)} onDone={() => {setUpload(false);resource.refresh();}}/>}<section className="panel"><form className="toolbar" onSubmit={e => {e.preventDefault();setSearch(query.trim());}}><label className="search-field"><Icon name="search"/><input aria-label="Tìm tài liệu" placeholder="Tìm tên tài liệu…" value={query} onChange={e => { const value = e.target.value; setQuery(value); debounce(() => setSearch(value.trim())); }}/></label></form>{resource.loading && !resource.data ? <Loading/> : resource.error ? <ErrorBox error={resource.error} retry={resource.refresh}/> : resource.data?.data.length ? <DocumentItems documents={resource.data.data} membership={membership} onOpen={onOpen} onRefresh={resource.refresh}/> : <Empty title="Chưa có tài liệu phù hợp" text="Tài liệu được tải lên từ hồ sơ hoặc trực tiếp tại kho dùng chung."/>}</section></>;
}
