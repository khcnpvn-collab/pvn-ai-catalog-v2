"use client";
import { useState } from 'react';
import type { CatalogRecord } from '@/lib/catalog';
import { moduleMap, validateRecord, type RecordInput } from '@/lib/catalog';
import type { Dossier, RelatedRecord } from '@/lib/dossier';
import { partnerTimelineEntries } from '@/lib/dossier-summary';
import { recordExcerpt, visibleOperationalStatus, visibleRecordStatus } from '@/lib/record-presentation';
import { api, Badge, date, ErrorBox, Icon, message } from './ui';

function text(value: string | number | null | undefined) { return value == null ? '' : String(value).trim(); }

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
