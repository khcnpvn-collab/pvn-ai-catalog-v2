"use client";
import { useState } from 'react';
import { validateRecord, type CatalogRecord, type RecordInput } from '@/lib/catalog';
import type { RelatedRecord } from '@/lib/dossier';
import { api, Badge, ErrorBox, Icon, message } from './ui';

const text = (value: unknown) => value == null ? '' : String(value).trim();
const WORK_STATUSES = ['Đang công tác', 'Đã chuyển công tác', 'Đã nghỉ'];
// One column per piece of contact information, edited in the same cell it is shown in.
const COLUMNS: { key: string; label: string; type?: string; placeholder?: string }[] = [
  { key: 'position', label: 'Chức vụ', placeholder: 'Trưởng ban…' },
  { key: 'department', label: 'Ban / phòng', placeholder: 'Ban CNTT…' },
  { key: 'role', label: 'Vai trò đầu mối', placeholder: 'Đầu mối giải pháp AI…' },
  { key: 'email', label: 'Email', type: 'email', placeholder: 'ten@congty.vn' },
  { key: 'phone', label: 'Điện thoại', type: 'tel', placeholder: '0912 345 678' },
];

function draftOf(record?: CatalogRecord): RecordInput {
  return record ? { id: record.id, version: record.version, kind: record.kind, title: record.title, code: record.code, summary: record.summary, status: record.status, data: { ...record.data } }
    : { kind: 'contact', title: '', status: 'Còn hiệu lực', data: { work_status: 'Đang công tác' } };
}

function Value({ name, value }: { name: string; value: string }) {
  if (!value) return <>—</>;
  if (name === 'email') return <a href={`mailto:${value}`}>{value}</a>;
  if (name === 'phone') return <a href={`tel:${value.replace(/[^+\d]/g, '')}`}>{value}</a>;
  return <>{value}</>;
}

// Contacts of a unit or partner: add, edit and delete right in the table rows. The section heading's add
// button raises addSignal, which opens an empty row at the top.
export function PartnerContacts({ entries, owner, writable, canEdit, onRefresh, addSignal = 0 }: { entries: RelatedRecord[]; owner?: CatalogRecord; writable?: boolean; canEdit?: (record: CatalogRecord) => boolean; onRefresh?: () => void; addSignal?: number }) {
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState<RecordInput | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  function begin(record: CatalogRecord) { setDraft(draftOf(record)); setEditing(record.id); setDeleting(null); setError(null); }
  function close() { setEditing(null); setDraft(null); setError(null); }
  const [seenSignal, setSeenSignal] = useState(addSignal);
  if (addSignal !== seenSignal) { setSeenSignal(addSignal); setDraft(draftOf()); setEditing('new'); setDeleting(null); setError(null); }
  const set = (key: string, value: string) => setDraft(current => current && (key === 'title' ? { ...current, title: value } : { ...current, data: { ...current.data, [key]: value || null } }));
  async function run(action: () => Promise<unknown>) {
    setBusy(true); setError(null);
    try { await action(); close(); setDeleting(null); onRefresh?.(); } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  function save() {
    if (!draft || !owner) return;
    const input = { ...draft, title: draft.title.trim() };
    const invalid = validateRecord(input);
    if (invalid) { setError(invalid); return; }
    run(() => api(editing === 'new' ? `/api/records/${owner.id}/related` : `/api/records/${draft.id}`, {
      method: editing === 'new' ? 'POST' : 'PATCH',
      body: JSON.stringify(editing === 'new' ? { record: input, relation: 'contact', direction: 'from-parent' } : input),
    }));
  }
  const contacts = [...entries].map(entry => entry.record).sort((a, b) => Number(text(b.data.is_primary) === 'Có') - Number(text(a.data.is_primary) === 'Có') || a.title.localeCompare(b.title, 'vi'));
  const editable = (record: CatalogRecord) => writable && (!canEdit || canEdit(record));
  // Enter saves and Escape cancels from any field of the row being edited.
  const editRow = (key: string) => draft && <tr key={key} className="contact-edit-row" onKeyDown={event => { if (event.key === 'Enter' && (event.target as HTMLElement).tagName === 'INPUT' && (event.target as HTMLInputElement).type !== 'checkbox') { event.preventDefault(); save(); } if (event.key === 'Escape') { event.stopPropagation(); close(); } }}>
    <td><input aria-label="Họ tên" placeholder="Họ tên *" autoFocus maxLength={250} value={draft.title} disabled={busy} onChange={event => set('title', event.target.value)}/>
      <div className="contact-edit-extra"><label className="checkbox-label"><input type="checkbox" checked={draft.data?.is_primary === 'Có'} disabled={busy} onChange={event => set('is_primary', event.target.checked ? 'Có' : 'Không')}/>Đầu mối chính</label>
        <select aria-label="Tình trạng công tác" value={text(draft.data?.work_status)} disabled={busy} onChange={event => set('work_status', event.target.value)}><option value="">Tình trạng: chưa ghi nhận</option>{text(draft.data?.work_status) && !WORK_STATUSES.includes(text(draft.data?.work_status)) && <option>{text(draft.data?.work_status)}</option>}{WORK_STATUSES.map(item => <option key={item}>{item}</option>)}</select></div></td>
    {COLUMNS.map(column => <td key={column.key}><input aria-label={column.label} type={column.type || 'text'} maxLength={1000} placeholder={column.placeholder} value={text(draft.data?.[column.key])} disabled={busy} onChange={event => set(column.key, event.target.value)}/></td>)}
    <td><div className="contact-row-buttons"><button type="button" className="icon-button" title="Lưu" aria-label="Lưu đầu mối" disabled={busy} onClick={save}><Icon name="check" size={17}/></button><button type="button" className="icon-button" title="Hủy" aria-label="Hủy" disabled={busy} onClick={close}><Icon name="close" size={17}/></button></div></td>
  </tr>;
  return <div className="contact-table">
    <ErrorBox error={error}/>
    {contacts.length > 0 || editing === 'new' ? <div className="table-scroll partner-contact-table"><table><thead><tr><th>Họ tên</th>{COLUMNS.map(column => <th key={column.key}>{column.label}</th>)}{writable && <th><span className="sr-only">Thao tác</span></th>}</tr></thead>
      <tbody>{editing === 'new' && editRow('new')}{contacts.map(record => editing === record.id ? editRow(record.id) : <tr key={record.id}>
        <td><strong>{record.title}</strong>{text(record.data.is_primary) === 'Có' && <Badge>Đầu mối chính</Badge>}{text(record.data.work_status) && text(record.data.work_status) !== 'Đang công tác' && <div className="record-meta">{text(record.data.work_status)}</div>}</td>
        {COLUMNS.map(column => <td key={column.key}><Value name={column.key} value={text(record.data[column.key])}/></td>)}
        {writable && <td>{editable(record) && (deleting === record.id
          ? <div className="contact-row-buttons"><span>Xoá hẳn?</span><button className="button small danger" disabled={busy} onClick={() => run(() => api(`/api/records/${record.id}`, { method: 'DELETE', body: JSON.stringify({ version: record.version }) }))}>Xoá</button><button className="button small" disabled={busy} onClick={() => setDeleting(null)}>Giữ</button></div>
          : <div className="contact-row-buttons"><button className="icon-button" title="Sửa" onClick={() => begin(record)} aria-label={`Sửa ${record.title}`} disabled={busy || editing !== null}><Icon name="edit" size={16}/></button><button className="icon-button danger-text" title="Xoá" onClick={() => setDeleting(record.id)} aria-label={`Xoá ${record.title}`} disabled={busy || editing !== null}><Icon name="trash" size={16}/></button></div>)}</td>}
      </tr>)}</tbody></table></div>
      : <p className="related-group-empty">Chưa có đầu mối.</p>}
  </div>;
}
