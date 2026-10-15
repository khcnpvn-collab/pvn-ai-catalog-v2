"use client";
import { byId, type Overview, type OverviewActivity } from '@/lib/overview';
import { date } from './ui';

// Lookups shared by every table that lists activities.
export type OverviewMaps = { partners: Map<string, Overview['partners'][number]>; units: Map<string, Overview['units'][number]>; standards: Map<string, Overview['standards'][number]>; workItems: Map<string, Overview['work_items'][number]> };
export function overviewMaps(overview?: Overview): OverviewMaps {
  return { partners: byId(overview?.partners || []), units: byId(overview?.units || []), standards: byId(overview?.standards || []), workItems: byId(overview?.work_items || []) };
}
export const unitName = (maps: OverviewMaps, id: string | null | undefined) => (id && (maps.units.get(id)?.abbreviation || maps.units.get(id)?.title)) || '';
// Every name a search should find a unit or a partner by: full name and abbreviation or short name.
export const unitTerms = (maps: OverviewMaps, ids: (string | null | undefined)[]) => ids.flatMap(id => id ? [maps.units.get(id)?.title, maps.units.get(id)?.abbreviation] : []);
export const partnerTerms = (maps: OverviewMaps, ids: (string | null | undefined)[]) => ids.flatMap(id => id ? [maps.partners.get(id)?.title, maps.partners.get(id)?.short_name] : []);

// Who carries out the activity: a partner, a consortium or a PVN unit.
export function activityPartyText(activity: OverviewActivity, maps: OverviewMaps): string {
  return activity.partner_id ? maps.partners.get(activity.partner_id)?.title || '' : unitName(maps, activity.provider_unit_id);
}
export function ActivityPartyCell({ activity, maps, onOpen, leadOf }: { activity: OverviewActivity; maps: OverviewMaps; onOpen: (id: string) => void; leadOf?: string }) {
  if (activity.partner_id) return <><button className="text-button" onClick={() => onOpen(activity.partner_id!)}>{activityPartyText(activity, maps) || '—'}</button>
    {maps.partners.get(activity.partner_id)?.member_ids.length ? <div className="record-meta">{leadOf && activity.party_lead_id === leadOf ? 'Liên danh · đối tác này là đầu mối' : 'Liên danh'}</div> : null}</>;
  if (activity.provider_unit_id) return <><button className="text-button" onClick={() => onOpen(activity.provider_unit_id!)}>{activityPartyText(activity, maps)}</button><div className="record-meta">Đơn vị PVN</div></>;
  return <>—</>;
}

// The one item an activity is linked to: a standard problem (with its code) or a work item.
export function activityItemText(activity: OverviewActivity, maps: OverviewMaps): string {
  if (activity.standard_id) { const standard = maps.standards.get(activity.standard_id); return [standard?.code, standard?.title].filter(Boolean).join(' · '); }
  return activity.work_item_id ? maps.workItems.get(activity.work_item_id)?.title || '' : '';
}
export function ActivityItemCell({ activity, maps, onOpen }: { activity: OverviewActivity; maps: OverviewMaps; onOpen: (id: string) => void }) {
  const id = activity.standard_id || activity.work_item_id;
  const text = activityItemText(activity, maps);
  return id ? <button className="text-button" title={text} onClick={() => onOpen(id)}>{text || '—'}</button> : <span className="muted">Chưa gắn</span>;
}

// Several linked records in one cell, one per line.
export function RecordLines({ items, onOpen }: { items: { id: string; label: string }[]; onOpen: (id: string) => void }) {
  return items.length ? <ul className="cell-lines">{items.map(item => <li key={item.id}><button className="text-button" onClick={() => onOpen(item.id)}>{item.label}</button></li>)}</ul> : <>—</>;
}

// A date for a table cell and its CSV text; empty when unknown.
export const dayText = (value: string | null | undefined) => value ? date(value) : '';
