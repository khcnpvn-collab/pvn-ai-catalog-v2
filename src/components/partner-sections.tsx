"use client";
import { useState } from 'react';
import type { CatalogRecord } from '@/lib/catalog';
import { moduleMap, validateRecord, type RecordInput } from '@/lib/catalog';
import type { Dossier, RelatedRecord } from '@/lib/dossier';
import { partnerTimelineEntries } from '@/lib/dossier-summary';
import { recordExcerpt, visibleOperationalStatus, visibleRecordStatus } from '@/lib/record-presentation';
import { api, Badge, date, ErrorBox, Icon, message } from './ui';

function text(value: string | number | null | undefined) { return value == null ? '' : String(value).trim(); }

type ContactKey = 'role' | 'position' | 'department' | 'email' | 'phone' | 'is_primary' | 'work_status';
function contactDraft(record?: CatalogRecord): RecordInput {
  return record ? { id: record.id, version: record.version, kind: record.kind, title: record.title, code: record.code, summary: record.summary, status: record.status, data: { ...record.data } }
    : { kind: 'contact', title: '', status: 'Còn hiệu lực', data: {} };
}

export function PartnerContacts({ entries, owner, writable, canEdit, onRefresh, limit }: { entries: RelatedRecord[]; owner?: CatalogRecord; writable?: boolean; canEdit?: (record: CatalogRecord) => boolean; onRefresh?: () => void; limit?: number }) {
  const [editing, setEditing] = useState<string | null>(null);
  const [draft, setDraft] = useState<RecordInput | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  function begin(record?: CatalogRecord) { setDraft(contactDraft(record)); setEditing(record?.id || 'new'); setError(null); }
  function update(key: string, value: string) {
    setDraft(current => current && (key === 'title' ? { ...current, title: value } : { ...current, data: { ...current.data, [key]: value || null } }));
  }
  async function save() {
    if (!draft || !owner || busy) return;
    const invalid = validateRecord(draft);
    if (invalid) { setError(invalid); return; }
    setBusy(true); setError(null);
    try {
      await api(editing === 'new' ? `/api/records/${owner.id}/related` : `/api/records/${editing}`, {
        method: editing === 'new' ? 'POST' : 'PATCH',
        body: JSON.stringify(editing === 'new' ? { record: draft, relation: 'contact', direction: 'from-parent' } : draft),
      });
      setEditing(null); setDraft(null); onRefresh?.();
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  const cell = (key: ContactKey | 'title', label: string) => <input aria-label={label} value={key === 'title' ? draft?.title || '' : String(draft?.data?.[key] || '')} onChange={event => update(key, event.target.value)} disabled={busy} maxLength={key === 'title' ? 250 : 1000} type={key === 'email' ? 'email' : 'text'}/>;
  const editRow = (key: string) => <tr key={key} className="contact-edit-row"><td><div className="contact-cell-stack">{cell('title', 'Họ tên')}<label><input type="checkbox" checked={draft?.data?.is_primary === 'Có'} onChange={event => update('is_primary', event.target.checked ? 'Có' : 'Không')} disabled={busy}/> Đầu mối chính</label>{cell('work_status', 'Trạng thái công tác')}</div></td><td><div className="contact-cell-stack">{cell('role', 'Vai trò')}{cell('position', 'Chức vụ')}{cell('department', 'Đơn vị / phòng ban')}</div></td><td><div className="contact-cell-stack">{cell('email', 'Email')}{cell('phone', 'Điện thoại')}</div></td><td><div className="contact-row-actions"><button className="button small primary" type="button" disabled={busy} onClick={save}>{busy ? 'Đang lưu…' : 'Lưu'}</button><button className="text-button" type="button" disabled={busy} onClick={() => { setEditing(null); setDraft(null); setError(null); }}>Hủy</button></div></td></tr>;
  const contacts = [...entries].sort((a, b) => {
    const primary = Number(text(b.record.data.is_primary) === 'Có') - Number(text(a.record.data.is_primary) === 'Có');
    return primary || a.record.title.localeCompare(b.record.title, 'vi');
  }).slice(0, limit);
  return <div className="partner-contact-grid-editor">{writable && owner && <div className="partner-contact-toolbar"><button className="button small" type="button" onClick={() => begin()} disabled={busy || editing !== null}><Icon name="plus" size={15}/>Thêm đầu mối</button></div>}<ErrorBox error={error}/>{(contacts.length > 0 || editing === 'new') && <div className="table-scroll partner-contact-table"><table><thead><tr><th>Họ tên</th><th>Vai trò / chức vụ</th><th>Liên hệ</th>{writable && <th><span className="sr-only">Thao tác</span></th>}</tr></thead><tbody>{contacts.map(({record}) => editing === record.id ? editRow(record.id) : <tr key={record.id}>
    <td><strong>{record.title}</strong>{text(record.data.is_primary) === 'Có' && <Badge>Đầu mối chính</Badge>}{text(record.data.work_status) && text(record.data.work_status) !== 'Đang công tác' && <Badge>{text(record.data.work_status)}</Badge>}</td>
    <td>{[record.data.role, record.data.position, text(record.data.department) !== owner?.title ? record.data.department : null].filter(Boolean).join(' · ') || '—'}</td>
    <td><div className="partner-contact-links">{text(record.data.email) && <a href={`mailto:${record.data.email}`}>{record.data.email}</a>}{text(record.data.phone) && <a href={`tel:${String(record.data.phone).replace(/[^+\d]/g, '')}`}>{record.data.phone}</a>}{!text(record.data.email) && !text(record.data.phone) && '—'}</div></td>
    {writable && <td>{(!canEdit || canEdit(record)) && <button className="icon-button record-inline-edit" onClick={() => begin(record)} aria-label={`Chỉnh sửa ${record.title}`} disabled={editing !== null}><Icon name="edit" size={15}/></button>}</td>}
  </tr>)}{editing === 'new' && editRow('new')}</tbody></table></div>}</div>;
}

export function TimelineInlineEditor({ record, onCancel, onSaved }: { record: CatalogRecord; onCancel: () => void; onSaved: () => void }) {
  const [draft, setDraft] = useState<RecordInput>({ id: record.id, version: record.version, kind: record.kind, title: record.title, code: record.code, summary: record.summary, status: record.status, data: { ...record.data } });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  function update(key: string, value: string) { setDraft(current => key === 'title' || key === 'summary' || key === 'status' ? { ...current, [key]: value } : { ...current, data: { ...current.data, [key]: value || null } }); }
  async function save() {
    const invalid = validateRecord(draft);
    if (invalid) { setError(invalid); return; }
    setBusy(true); setError(null);
    try { await api(`/api/records/${record.id}`, { method: 'PATCH', body: JSON.stringify(draft) }); onSaved(); }
    catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  const input = (key: string, label: string, type = 'text') => <label className="field" key={key}>{label}<input type={type} value={String(key === 'title' ? draft.title : draft.data?.[key] || '')} onChange={event => update(key, event.target.value)} disabled={busy}/></label>;
  return <div className="timeline-inline-editor" aria-label={`Chỉnh sửa mốc ${record.title}`}>
    <div className="form-grid">{input('title', 'Tên mốc')}{input('start_date', 'Ngày bắt đầu', 'date')}{input('end_date', 'Ngày kết thúc', 'date')}{input('period_label', 'Thời gian khác')}{input('location', 'Địa điểm / hình thức')}{input('responsible', 'Đầu mối phụ trách')}
      <label className="field">Trạng thái<select value={draft.status} onChange={event => update('status', event.target.value)} disabled={busy}>{!visibleOperationalStatus(draft.status) && <option value={draft.status}>Chưa ghi nhận</option>}{moduleMap.engagement.statuses.filter(status => visibleOperationalStatus(status)).map(status => <option key={status}>{status}</option>)}</select></label>
      <label className="field full">Thành phần<textarea rows={2} value={String(draft.data?.participants || '')} onChange={event => update('participants', event.target.value)} disabled={busy}/></label>
      <label className="field full">Nội dung và kết quả<textarea rows={3} value={String(draft.data?.conclusions || '')} onChange={event => update('conclusions', event.target.value)} disabled={busy}/></label>
      <label className="field full">Bước tiếp theo<textarea rows={2} value={String(draft.data?.next_notes || '')} onChange={event => update('next_notes', event.target.value)} disabled={busy}/></label>
    </div><ErrorBox error={error}/><div className="actions"><button className="button small primary" disabled={busy} onClick={save}>{busy ? 'Đang lưu…' : 'Lưu mốc'}</button><button className="button small" disabled={busy} onClick={onCancel}>Hủy</button></div>
  </div>;
}

function timelineLabel(record: CatalogRecord) {
  const start = text(record.data.start_date), end = text(record.data.end_date);
  if (start) return end && end !== start ? `${date(start)} – ${date(end)}` : date(start);
  return text(record.data.period_label) || 'Chưa xác định ngày';
}

// One row per milestone: date, title, status and files, then the result and next step in a single note.
export function PartnerTimeline({ entries, attachments, onOpen, onRefresh, limit, onEdit, canEdit }: { entries: RelatedRecord[]; attachments: Dossier['attachments']; onOpen: (id: string) => void; onRefresh?: () => void; limit?: number; onEdit?: (record: CatalogRecord) => void; canEdit?: (record: CatalogRecord) => boolean }) {
  const [editing, setEditing] = useState<string | null>(null);
  const timeline = partnerTimelineEntries(entries).slice(0, limit);
  return <ol className="milestone-rows">{timeline.map(({record, via}) => {
    const fileCount = attachments.filter(item => item.record.id === record.id).length;
    const status = visibleRecordStatus(record);
    const note = [text(record.data.conclusions) || text(record.summary), text(record.data.next_notes) && `Tiếp theo: ${text(record.data.next_notes)}`].filter(Boolean).join(' · ');
    return <li key={record.id}><time>{timelineLabel(record)}</time><div className="milestone-body">
      <div className="record-title-actions"><button className="related-record-title" onClick={() => onOpen(record.id)}>{record.title}<Icon name="arrow" size={16}/></button>{status && <Badge>{status}</Badge>}{fileCount > 0 && <span className="milestone-files"><Icon name="file" size={14}/>{fileCount}</span>}{onEdit && (!canEdit || canEdit(record)) && <button className="icon-button record-inline-edit" onClick={() => onRefresh ? setEditing(record.id) : onEdit(record)} aria-label={`Chỉnh sửa ${record.title}`}><Icon name="edit" size={15}/></button>}</div>
      {via && <div className="milestone-context">Hoạt động: <button className="text-button" onClick={() => onOpen(via.id)}>{via.title}</button></div>}
      {note && <p>{recordExcerpt(note, 280)}</p>}
      {editing === record.id && <TimelineInlineEditor record={record} onCancel={() => setEditing(null)} onSaved={() => { setEditing(null); onRefresh?.(); }}/>}
    </div></li>;
  })}</ol>;
}
