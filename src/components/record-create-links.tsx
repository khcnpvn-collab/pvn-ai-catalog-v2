"use client";
import { useState, type ReactNode } from 'react';
import { STANDARD_GROUP, type CatalogRecord, type RecordInput } from '@/lib/catalog';
import type { DossierContext } from '@/lib/dossier';
import { ActivityLinkFields, emptyActivityLinks, saveActivityLinks, type ActivityLinks } from './activity-link-fields';
import MultiRecordPicker from './multi-record-picker';
import RecordCombobox, { type ComboChoice, type ComboOption } from './record-combobox';
import { api } from './ui';
import { useOverview } from './use-overview';

const SPECIFIC_UNITS = 'Đơn vị cụ thể';
type UnitLinks = { lead: ComboChoice | null; units: ComboOption[] };
const link = (body: Record<string, unknown>) => api('/api/links', { method: 'POST', body: JSON.stringify(body) });

// The first form of an activity or an item also takes its links, written right after the record is saved,
// so nothing has to be saved before it can be completed. Links the page the form was opened from already
// adds are hidden or skipped. kind is null when the form has its own link fields or edits a saved record.
export function useCreateLinks(kind: string | null, context: DossierContext | undefined, data: RecordInput['data']): { fields: ReactNode; save: (record: CatalogRecord) => Promise<void> } {
  const overview = useOverview();
  const [activity, setActivity] = useState<ActivityLinks>(emptyActivityLinks);
  const [unitLinks, setUnitLinks] = useState<UnitLinks>({ lead: null, units: [] });
  // A new item group drops the chosen item, which belonged to the previous group.
  const group = String(data?.item_group || STANDARD_GROUP);
  const [shownGroup, setShownGroup] = useState(group);
  if (group !== shownGroup) { setShownGroup(group); setActivity(value => ({ ...value, item: null })); }
  const skip = context ? [context.parentId] : [];
  const units = (overview.data?.units || []).map(unit => ({ id: unit.id, label: unit.title, detail: unit.abbreviation }));
  const leadId = unitLinks.lead && 'id' in unitLinks.lead ? unitLinks.lead.id : null;
  const specificUnits = data?.apply_scope === SPECIFIC_UNITS;

  let fields: ReactNode = null;
  if (kind === 'collaboration') fields = <ActivityLinkFields group={group} value={activity} onChange={setActivity}
    hidden={{ executor: context?.relation === 'partner', unit: context?.relation === 'unit', item: context?.relation === 'use_case' }}/>;
  if (kind === 'use_case') fields = <section className="panel form-section"><h2>Đơn vị</h2><div className="form-grid">
    <RecordCombobox label="Đầu mối ưu tiên triển khai" options={units} value={unitLinks.lead} placeholder="Gõ tên hoặc viết tắt đơn vị…"
      onChange={lead => setUnitLinks(value => ({ lead, units: value.units.filter(unit => !lead || !('id' in lead) || unit.id !== lead.id) }))}/>
    <MultiRecordPicker label="Đơn vị tiềm năng áp dụng" options={units.filter(unit => unit.id !== leadId)} value={unitLinks.units} onChange={next => setUnitLinks(value => ({ ...value, units: next }))} placeholder="Gõ tên hoặc viết tắt đơn vị…"/>
  </div></section>;
  if (kind === 'work_item' && specificUnits) fields = <section className="panel form-section"><h2>Đơn vị áp dụng</h2><div className="form-grid">
    <MultiRecordPicker label="Đơn vị được ưu tiên áp dụng" options={units} value={unitLinks.units} onChange={next => setUnitLinks(value => ({ ...value, units: next }))} placeholder="Gõ tên hoặc viết tắt đơn vị…"/>
  </div></section>;

  async function save(record: CatalogRecord) {
    if (kind === 'collaboration') return saveActivityLinks(record.id, activity, String(record.data.item_group || STANDARD_GROUP), skip);
    if (kind === 'use_case') {
      if (leadId && !skip.includes(leadId)) await link({ source_id: record.id, target_id: leadId, relation: 'unit', context: { subject_role: 'lead' } });
      for (const unit of unitLinks.units) if (unit.id !== leadId && !skip.includes(unit.id)) await link({ source_id: record.id, target_id: unit.id, relation: 'unit', context: { subject_role: 'supporting' } });
    }
    if (kind === 'work_item' && record.data.apply_scope === SPECIFIC_UNITS) {
      for (const unit of unitLinks.units) if (!skip.includes(unit.id)) await link({ source_id: record.id, target_id: unit.id, relation: 'unit' });
    }
  }
  return { fields, save };
}
