"use client";
import { useState, type ReactNode } from 'react';
import type { CatalogRecord, Relation } from '@/lib/catalog';
import type { RelatedRecord } from '@/lib/dossier';
import { directRelationContext } from '@/lib/dossier-summary';
import { activityTitle, byId, unitActivities, type Overview, type OverviewActivity } from '@/lib/overview';
import { rowRecordStatus } from '@/lib/record-presentation';
import { api, Badge, date, ErrorBox, Icon, message } from './ui';
import { invalidateOverview, useOverview } from './use-overview';

type Column = 'partner' | 'unit' | 'standard';
// One row per activity: status, group, partner, lead PVN subject and item at a glance.
// leadOf marks activities signed through a consortium that this partner leads.
export function ActivityTable({ activities, overview, onOpen, hide = [], omit = [], leadOf, label = 'Danh sách hoạt động', showGroup = true, onRemove, canRemove }: { activities: OverviewActivity[]; overview?: Overview; onOpen: (id: string) => void; hide?: Column[]; omit?: (string | null | undefined)[]; leadOf?: string; label?: string; showGroup?: boolean; onRemove?: (activityId: string) => void; canRemove?: (activityId: string) => boolean }) {
  const partners = byId(overview?.partners || []), units = byId(overview?.units || []), standards = byId(overview?.standards || []), workItems = byId(overview?.work_items || []);
  const show = (column: Column) => !hide.includes(column);
  const name = (id: string | null, map: Map<string, { title: string }>) => (id && map.get(id)?.title) || '—';
  const period = (activity: OverviewActivity) => [activity.start_date, activity.end_date].filter(Boolean).map(value => date(value)).join(' – ');
  return <div className="table-scroll" tabIndex={0} role="region" aria-label={label}><table className="activity-table"><thead><tr><th>Hoạt động</th><th className="activity-status">Trạng thái</th>{show('partner') && <th className="activity-party">Bên thực hiện</th>}{show('unit') && <th className="activity-party">Đầu mối PVN</th>}{show('standard') && <th className="activity-standard">Hạng mục</th>}{onRemove && <th aria-label="Thao tác"></th>}</tr></thead>
    <tbody>{activities.map(activity => <tr key={activity.id}>
      <td><button className="record-name" title={activity.title} onClick={() => onOpen(activity.id)}>{activityTitle(activity.title, omit)}</button><div className="record-meta">{[showGroup ? activity.item_group : null, activity.item_category, period(activity)].filter(Boolean).join(' · ')}</div></td>
      <td><Badge>{activity.status}</Badge></td>
      {show('partner') && <td data-label="Bên thực hiện">{activity.partner_id ? <><button className="text-button" onClick={() => onOpen(activity.partner_id!)}>{name(activity.partner_id, partners)}</button>{partners.get(activity.partner_id)?.member_ids.length ? <div className="record-meta">{leadOf && activity.party_lead_id === leadOf ? 'Liên danh · đối tác này là đầu mối' : 'Liên danh'}</div> : null}</>
        : activity.provider_unit_id ? <><button className="text-button" onClick={() => onOpen(activity.provider_unit_id!)}>{units.get(activity.provider_unit_id)?.abbreviation || name(activity.provider_unit_id, units)}</button><div className="record-meta">Đơn vị PVN</div></> : '—'}</td>}
      {show('unit') && <td data-label="Đầu mối PVN">{activity.lead_unit_id ? <button className="text-button" onClick={() => onOpen(activity.lead_unit_id!)}>{units.get(activity.lead_unit_id)?.abbreviation || name(activity.lead_unit_id, units)}</button> : '—'}</td>}
      {show('standard') && <td className="activity-standard" data-label="Hạng mục">{activity.standard_id ? <button className="text-button" title={name(activity.standard_id, standards)} onClick={() => onOpen(activity.standard_id!)}>{[standards.get(activity.standard_id)?.code, name(activity.standard_id, standards)].filter(Boolean).join(' · ')}</button>
        : activity.work_item_id ? <button className="text-button" title={name(activity.work_item_id, workItems)} onClick={() => onOpen(activity.work_item_id!)}>{name(activity.work_item_id, workItems)}</button> : <span className="muted">Chưa gắn</span>}</td>}
      {onRemove && <td>{(!canRemove || canRemove(activity.id)) && <button className="text-button" onClick={() => onRemove(activity.id)}>Gỡ</button>}</td>}
    </tr>)}</tbody></table></div>;
}

function RecordRow({ record, onOpen, note, children }: { record: CatalogRecord; onOpen: (id: string) => void; note?: string; children?: ReactNode }) {
  const status = rowRecordStatus(record);
  return <article className="related-record-row"><div className="related-record-main">
    <button className="related-record-title" onClick={() => onOpen(record.id)}>{record.title}<Icon name="arrow" size={16}/></button>
    {note && <p>{note}</p>}
  </div><div className="related-record-meta">{status && <Badge>{status}</Badge>}{children}</div></article>;
}

function Group({ title, entries, empty, render }: { title: string; entries: RelatedRecord[]; empty?: string; render: (entry: RelatedRecord) => ReactNode }) {
  if (!entries.length && !empty) return null;
  return <section className="related-kind-group"><header className="related-kind-heading"><h3>{title}<span>{entries.length}</span></h3></header>
    {entries.length ? <div className="related-record-list">{entries.map(render)}</div> : <p className="related-group-empty">{empty}</p>}</section>;
}

// limit trims the activity table on the summary page; the section's own view shows every row.
// onChooseLead opens the section's "choose existing" with the lead role ticked.
type SectionProps = { selector: string; record: CatalogRecord; entries: RelatedRecord[]; links: Relation[]; writable: boolean; onOpen: (id: string) => void; refresh: () => void; limit?: number; onShowAll?: () => void; onChooseLead?: () => void };

export default function RoadmapSection({ selector, record, entries, links, writable, onOpen, refresh, limit, onShowAll, onChooseLead }: SectionProps) {
  const overview = useOverview();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const unique = [...new Map(entries.map(entry => [entry.record.id, entry])).values()];
  const role = (entry: RelatedRecord) => entry.via ? 'via' : directRelationContext(record.id, entry, links).subject_role === 'lead' ? 'lead' : 'supporting';
  const linkTo = (entry: RelatedRecord) => links.find(link => link.relation === entry.relation && ((link.source_id === record.id && link.target_id === entry.record.id) || (link.target_id === record.id && link.source_id === entry.record.id)));
  async function run(action: () => Promise<unknown>) {
    setBusy(true); setError(null);
    try { await action(); invalidateOverview(); refresh(); } catch (e) { setError(message(e)); } finally { setBusy(false); }
  }
  const makeLead = (entry: RelatedRecord) => run(() => api('/api/links', { method: 'POST', body: JSON.stringify({ source_id: record.id, target_id: entry.record.id, relation: 'unit', context: { subject_role: 'lead' } }) }));
  const unlink = (entry: RelatedRecord) => { const link = linkTo(entry); if (link) run(() => api(`/api/links/${link.id}`, { method: 'DELETE' })); };
  const removeButton = (entry: RelatedRecord) => writable && !entry.via && linkTo(entry) && <button className="text-button" disabled={busy} onClick={() => unlink(entry)}>Gỡ</button>;

  if (selector === 'activity-list') {
    const ids = new Set(unique.map(entry => entry.record.id));
    const rows = overview.data?.activities.filter(activity => ids.has(activity.id)) || [];
    if (!unique.length) return <p className="related-group-empty">Chưa có hoạt động.</p>;
    if (!overview.data) return <div className="related-record-list">{unique.map(entry => <RecordRow key={entry.record.id} record={entry.record} onOpen={onOpen}/>)}</div>;
    // On a partner page the partner column only matters for activities signed through a consortium.
    const hide: Column[] = ['use_case', 'work_item'].includes(record.kind) ? ['standard'] : record.kind === 'unit' ? ['unit'] : record.kind === 'partner' && unique.every(entry => !entry.via) ? ['partner'] : [];
    const shown = limit ? rows.slice(0, limit) : rows;
    const unit = record.kind === 'unit' ? overview.data.units.find(item => item.id === record.id) : null;
    const omit = record.kind === 'partner' ? [record.title, String(record.data.short_name || '')] : unit ? [unit.title, unit.abbreviation] : [];
    const removable = writable && ['use_case', 'work_item', 'expert'].includes(record.kind);
    const directEntry = (activityId: string) => unique.find(item => item.record.id === activityId && !item.via && linkTo(item));
    const removeActivity = (activityId: string) => { const entry = directEntry(activityId); if (entry) unlink(entry); };
    return <><ErrorBox error={error}/><ActivityTable activities={shown} overview={overview.data} onOpen={onOpen} hide={hide} omit={omit} leadOf={record.kind === 'partner' ? record.id : undefined} onRemove={removable ? removeActivity : undefined} canRemove={activityId => Boolean(directEntry(activityId))}/>{onShowAll && shown.length < rows.length && <button className="text-button related-show-all" onClick={onShowAll}>Xem tất cả {rows.length} hoạt động<Icon name="arrow" size={16}/></button>}</>;
  }
  if (selector === 'unit-roles') {
    const standard = record.kind === 'use_case';
    const labels = standard ? ['Đầu mối ưu tiên triển khai', 'Đơn vị tiềm năng áp dụng'] : ['Đầu mối', 'Phối hợp'];
    const row = (entry: RelatedRecord, tag?: string) => <RecordRow key={entry.record.id} record={entry.record} onOpen={onOpen} note={entry.via ? `Qua hoạt động: ${entry.via.title}` : undefined}>
      {tag && <Badge>{tag}</Badge>}{writable && role(entry) === 'supporting' && <button className="text-button" disabled={busy} onClick={() => makeLead(entry)}>Đặt làm đầu mối</button>}{removeButton(entry)}</RecordRow>;
    // An activity has a handful of units: one list, lead first, each row tagged with its role.
    if (!standard) {
      const ordered = [...unique.filter(entry => role(entry) === 'lead'), ...unique.filter(entry => role(entry) !== 'lead')];
      return <><ErrorBox error={error}/>{ordered.length ? <div className="related-record-list">{ordered.map(entry => row(entry, role(entry) === 'lead' ? labels[0] : labels[1]))}</div> : <p className="related-group-empty">Chưa chọn đơn vị đầu mối.</p>}
        {writable && onChooseLead && !ordered.some(entry => role(entry) === 'lead') && <button className="text-button" onClick={onChooseLead}><Icon name="plus" size={15}/>Chọn đơn vị đầu mối</button>}</>;
    }
    return <><ErrorBox error={error}/><div className="related-kind-groups">
      <Group title={labels[0]} entries={unique.filter(entry => role(entry) === 'lead')} empty="Chưa chọn đầu mối." render={entry => row(entry)}/>
      {writable && onChooseLead && !unique.some(entry => role(entry) === 'lead') && <button className="text-button" onClick={onChooseLead}><Icon name="plus" size={15}/>Chọn đơn vị đầu mối ưu tiên</button>}
      <Group title={labels[1]} entries={unique.filter(entry => role(entry) === 'supporting')} empty="Chưa gắn đơn vị tiềm năng." render={entry => row(entry)}/>
    </div></>;
  }
  if (selector === 'standard-partners') {
    // Partners already working on the problem show in the activity table; this list holds potential partners.
    if (!unique.length) return <p className="related-group-empty">Chưa gắn đối tác tiềm năng.</p>;
    return <><ErrorBox error={error}/><div className="related-record-list">{unique.map(entry => <RecordRow key={entry.record.id} record={entry.record} onOpen={onOpen}>{removeButton(entry)}</RecordRow>)}</div></>;
  }
  if (selector === 'unit-standards') {
    const lead = (entry: RelatedRecord) => directRelationContext(record.id, entry, links).subject_role === 'lead';
    const row = (entry: RelatedRecord) => <RecordRow key={entry.record.id} record={entry.record} onOpen={onOpen}>{removeButton(entry)}</RecordRow>;
    const standards = unique.filter(entry => entry.record.kind === 'use_case');
    return <><ErrorBox error={error}/><div className="related-kind-groups">
      <Group title="Bài toán chuẩn — đầu mối ưu tiên" entries={standards.filter(lead)} render={row}/>
      <Group title="Bài toán chuẩn — tiềm năng áp dụng" entries={standards.filter(entry => !lead(entry))} render={row}/>
      <Group title="Hạng mục áp dụng" entries={unique.filter(entry => entry.record.kind === 'work_item')} render={row}/>
      {!unique.length && <p className="related-group-empty">Chưa có hạng mục liên quan.</p>}
    </div></>;
  }
  if (selector === 'unit-partners') {
    const activities = overview.data ? unitActivities(overview.data, record.id) : [];
    const count = (partnerId: string) => activities.filter(activity => activity.partner_id === partnerId).length;
    if (!unique.length) return <p className="related-group-empty">Chưa có đối tác qua hoạt động.</p>;
    return <div className="related-record-list">{unique.map(entry => <RecordRow key={entry.record.id} record={entry.record} onOpen={onOpen} note={count(entry.record.id) ? `${count(entry.record.id)} hoạt động với đơn vị` : undefined}/>)}</div>;
  }
  if (selector === 'activity-partner') {
    const partner = unique[0];
    const members = partner && overview.data ? (overview.data.partners.find(item => item.id === partner.record.id)?.member_ids || []) : [];
    const partners = byId(overview.data?.partners || []);
    if (!partner) return <p className="related-group-empty">Chưa chọn đối tác, liên danh hoặc đơn vị PVN.</p>;
    const leadId = linkTo(partner)?.context?.lead_member_id;
    const note = [members.length ? `Liên danh: ${members.map(id => partners.get(id)?.title).filter(Boolean).join(', ')}` : '', leadId && partners.get(leadId) ? `Đầu mối của hoạt động: ${partners.get(leadId)!.title}` : ''].filter(Boolean).join(' · ');
    return <><ErrorBox error={error}/><div className="related-record-list"><RecordRow record={partner.record} onOpen={onOpen} note={note || undefined}>{partner.record.kind === 'unit' && <Badge>Đơn vị PVN</Badge>}{removeButton(partner)}</RecordRow></div></>;
  }
  return null;
}
