"use client";
import { useState } from 'react';
import { validateRecord, type CatalogRecord, type RecordInput } from '@/lib/catalog';
import type { RelatedRecord } from '@/lib/dossier';
import { api, Badge, ErrorBox, Icon, message } from './ui';

const text = (value: unknown) => value == null ? '' : String(value).trim();
const WORK_STATUSES = ['Đang công tác', 'Đã chuyển công tác', 'Đã nghỉ'];
// One field per piece of contact information, in the order they are read and typed.
const FIELDS: { key: string; label: string; type?: string; placeholder?: string }[] = [
  { key: 'position', label: 'Chức vụ', placeholder: 'VD: Trưởng ban, Giám đốc kinh doanh' },
  { key: 'department', label: 'Ban / phòng / văn phòng', placeholder: 'VD: Ban CNTT & CĐS' },
  { key: 'role', label: 'Vai trò đầu mối', placeholder: 'VD: Đầu mối giải pháp AI' },
  { key: 'email', label: 'Email', type: 'email', placeholder: 'ten@congty.vn' },
  { key: 'phone', label: 'Điện thoại', type: 'tel', placeholder: 'VD: 0912 345 678' },
];

function draftOf(record?: CatalogRecord): RecordInput {
  return record ? { id: record.id, version: record.version, kind: record.kind, title: record.title, code: record.code, summary: record.summary, status: record.status, data: { ...record.data } }
    : { kind: 'contact', title: '', status: 'Còn hiệu lực', data: { work_status: 'Đang công tác' } };
}

// Contacts of a unit or partner: one column per field, a separate labelled form to add or edit, and delete.
export function PartnerContacts({ entries, owner, writable, canEdit, onRefresh }: { entries: RelatedRecord[]; owner?: CatalogRecord; writable?: boolean; canEdit?: (record: CatalogRecord) => boolean; onRefresh?: () => void }) {
  const [editing, setEditing] = useState<CatalogRecord | 'new' | null>(null);
  const [draft, setDraft] = useState<RecordInput | null>(null);
  const [deleting, setDeleting] = useState<CatalogRecord | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  function begin(record?: CatalogRecord) { setDraft(draftOf(record)); setEditing(record || 'new'); setDeleting(null); setError(null); }
  function close() { setEditing(null); setDraft(null); setError(null); }
  const set = (key: string, value: string) => setDraft(current => current && (key === 'title' ? { ...current, title: value } : { ...current, data: { ...current.data, [key]: value || null } }));
  async function run(action: () => Promise<unknown>) {
    setBusy(true); setError(null);
    try { await action(); close(); setDeleting(null); onRefresh?.(); } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  function save() {
    if (!draft || !owner) return;
    const invalid = validateRecord({ ...draft, title: draft.title.trim() });
    if (invalid) { setError(invalid); return; }
    run(() => api(editing === 'new' ? `/api/records/${owner.id}/related` : `/api/records/${draft.id}`, {
      method: editing === 'new' ? 'POST' : 'PATCH',
      body: JSON.stringify(editing === 'new' ? { record: { ...draft, title: draft.title.trim() }, relation: 'contact', direction: 'from-parent' } : { ...draft, title: draft.title.trim() }),
    }));
  }
  const contacts = [...entries].map(entry => entry.record).sort((a, b) => Number(text(b.data.is_primary) === 'Có') - Number(text(a.data.is_primary) === 'Có') || a.title.localeCompare(b.title, 'vi'));
  const editable = (record: CatalogRecord) => writable && (!canEdit || canEdit(record));
  return <div className="contact-table">
    {writable && owner && !editing && <div className="partner-contact-toolbar"><button className="button small" type="button" onClick={() => begin()}><Icon name="plus" size={15}/>Thêm đầu mối</button></div>}
    {editing && draft && <form className="panel form-section contact-form" onSubmit={event => { event.preventDefault(); save(); }}>
      <h3>{editing === 'new' ? 'Thêm đầu mối' : `Sửa đầu mối: ${editing.title}`}</h3>
      <div className="form-grid">
        <label className="field full"><span>Họ tên <span className="required" aria-hidden="true">*</span></span><input required autoFocus maxLength={250} value={draft.title} onChange={event => set('title', event.target.value)}/></label>
        {FIELDS.map(field => <label className="field" key={field.key}>{field.label}<input type={field.type || 'text'} maxLength={1000} placeholder={field.placeholder} value={text(draft.data?.[field.key])} onChange={event => set(field.key, event.target.value)}/></label>)}
        <label className="field">Tình trạng công tác<select value={text(draft.data?.work_status)} onChange={event => set('work_status', event.target.value)}><option value="">Chưa ghi nhận</option>{text(draft.data?.work_status) && !WORK_STATUSES.includes(text(draft.data?.work_status)) && <option>{text(draft.data?.work_status)}</option>}{WORK_STATUSES.map(item => <option key={item}>{item}</option>)}</select></label>
        <label className="checkbox-label full contact-primary"><input type="checkbox" checked={draft.data?.is_primary === 'Có'} onChange={event => set('is_primary', event.target.checked ? 'Có' : 'Không')}/>Đầu mối chính</label>
      </div>
      <ErrorBox error={error}/>
      <div className="actions"><button className="button" type="button" disabled={busy} onClick={close}>Hủy</button><button className="button primary" disabled={busy}>{busy ? 'Đang lưu…' : 'Lưu đầu mối'}</button></div>
    </form>}
    {!editing && <ErrorBox error={error}/>}
    {contacts.length > 0 ? <div className="table-scroll partner-contact-table"><table><thead><tr><th>Họ tên</th><th>Chức vụ</th><th>Ban / phòng</th><th>Vai trò đầu mối</th><th>Email</th><th>Điện thoại</th>{writable && <th><span className="sr-only">Thao tác</span></th>}</tr></thead>
      <tbody>{contacts.map(record => <tr key={record.id}>
        <td><strong>{record.title}</strong>{text(record.data.is_primary) === 'Có' && <Badge>Đầu mối chính</Badge>}{text(record.data.work_status) && text(record.data.work_status) !== 'Đang công tác' && <div className="record-meta">{text(record.data.work_status)}</div>}</td>
        <td>{text(record.data.position) || '—'}</td>
        <td>{text(record.data.department) || '—'}</td>
        <td>{text(record.data.role) || '—'}</td>
        <td>{text(record.data.email) ? <a href={`mailto:${text(record.data.email)}`}>{text(record.data.email)}</a> : '—'}</td>
        <td>{text(record.data.phone) ? <a href={`tel:${text(record.data.phone).replace(/[^+\d]/g, '')}`}>{text(record.data.phone)}</a> : '—'}</td>
        {writable && <td>{editable(record) && (deleting?.id === record.id
          ? <div className="actions contact-delete-confirm"><span>Xoá hẳn?</span><button className="button small danger" disabled={busy} onClick={() => run(() => api(`/api/records/${record.id}`, { method: 'DELETE', body: JSON.stringify({ version: record.version }) }))}>Xoá</button><button className="button small" disabled={busy} onClick={() => setDeleting(null)}>Giữ lại</button></div>
          : <div className="actions contact-row-buttons"><button className="icon-button" onClick={() => begin(record)} aria-label={`Sửa ${record.title}`} disabled={busy || Boolean(editing)}><Icon name="edit" size={15}/></button><button className="text-button danger-text" onClick={() => setDeleting(record)} disabled={busy || Boolean(editing)}>Xoá</button></div>)}</td>}
      </tr>)}</tbody></table></div>
      : !editing && <p className="related-group-empty">Chưa có đầu mối.</p>}
  </div>;
}
