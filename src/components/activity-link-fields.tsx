"use client";
import { useState } from 'react';
import { STANDARD_GROUP, type CatalogRecord } from '@/lib/catalog';
import type { Overview } from '@/lib/overview';
import MultiRecordPicker from './multi-record-picker';
import RecordCombobox, { type ComboChoice, type ComboOption } from './record-combobox';
import { api, ErrorBox, message } from './ui';
import { invalidateOverview, useOverview } from './use-overview';

// Who carries out an activity opened from a partner page: the partner itself, or one of the
// consortia it belongs to, optionally as that activity's lead within the consortium.
export type Party = { consortiumId: string; lead: boolean };
// executor is used when the form is not opened from a partner (whose party choice is then in party).
export type ActivityLinks = { party: Party; executor: ComboChoice | null; unit: ComboChoice | null; supporting: ComboOption[]; experts: ComboOption[]; item: ComboChoice | null };
export const emptyActivityLinks: ActivityLinks = { party: { consortiumId: '', lead: true }, executor: null, unit: null, supporting: [], experts: [], item: null };
// Fields the parent record already fills: an activity added from a unit has its lead, from an item its item.
export type ActivityLinkHidden = { executor?: boolean; unit?: boolean; item?: boolean };

// Items an activity of this group can take: standard problems for "Bài toán", otherwise the group's work items.
export function itemOptions(overview: Overview | undefined, group: string) {
  if (group === STANDARD_GROUP) return (overview?.standards || []).map(standard => ({ id: standard.id, label: standard.title, detail: [standard.code, standard.program].filter(Boolean).join(' · ') }));
  return (overview?.work_items || []).filter(item => item.item_group === group).map(item => ({ id: item.id, label: item.title, detail: [item.scope_level, item.owner].filter(Boolean).join(' · ') }));
}

function ItemCombobox({ group, value, onChange }: { group: string; value: ComboChoice | null; onChange: (choice: ComboChoice | null) => void }) {
  const overview = useOverview();
  const standard = group === STANDARD_GROUP;
  return <RecordCombobox label={standard ? 'Bài toán chuẩn' : `Hạng mục — ${group}`} options={itemOptions(overview.data, group)} value={value} onChange={onChange}
    placeholder={standard ? 'Gõ tên hoặc mã BTC…' : 'Gõ tên hạng mục…'} createLabel={standard ? 'Thêm bài toán chuẩn mới' : 'Thêm hạng mục mới'}
    hint={`Hạng mục thuộc nhóm "${group}"; hạng mục mới được thêm vào nhóm này.`}/>;
}

export function partnerConsortia(overview: Overview | undefined, partnerId: string) {
  return (overview?.partners || []).filter(item => item.member_ids.includes(partnerId));
}

// Relation context stored on the activity → consortium link.
export function partyContext(party: Party, partnerId: string): Record<string, string> | undefined {
  return party.consortiumId && party.lead ? { lead_member_id: partnerId } : undefined;
}

export function PartyChoice({ partner, value, onChange }: { partner: CatalogRecord; value: Party; onChange: (party: Party) => void }) {
  const overview = useOverview();
  const consortia = partnerConsortia(overview.data, partner.id);
  if (!consortia.length) return <div className="field full"><span>Bên thực hiện</span><p className="party-only"><strong>{partner.title}</strong><small>Đối tác chưa tham gia liên danh nào. Thêm ở mục Liên danh nếu cần ký qua liên danh.</small></p></div>;
  return <fieldset className="field full party-choice"><legend>Bên thực hiện</legend>
    <label className="checkbox-label"><input type="radio" name="party" checked={!value.consortiumId} onChange={() => onChange({ consortiumId: '', lead: true })}/>{partner.title}</label>
    <label className="checkbox-label"><input type="radio" name="party" checked={Boolean(value.consortiumId)} onChange={() => onChange({ consortiumId: consortia[0].id, lead: value.lead })}/>Qua liên danh</label>
    {value.consortiumId && <div className="party-consortium">
      {consortia.length > 1 ? <select aria-label="Liên danh" value={value.consortiumId} onChange={event => onChange({ ...value, consortiumId: event.target.value })}>{consortia.map(item => <option key={item.id} value={item.id}>{item.title}</option>)}</select> : <strong>{consortia[0].title}</strong>}
      <label className="checkbox-label"><input type="checkbox" checked={value.lead} onChange={event => onChange({ ...value, lead: event.target.checked })}/>{partner.title} là đầu mối của hoạt động này trong liên danh</label>
    </div>}
  </fieldset>;
}

// group is the item group picked in the activity form above, so the item list follows it.
export function ActivityLinkFields({ partner, group, value, onChange, hidden = {} }: { partner?: CatalogRecord; group: string; value: ActivityLinks; onChange: (links: ActivityLinks) => void; hidden?: ActivityLinkHidden }) {
  const overview = useOverview();
  const units = (overview.data?.units || []).map(unit => ({ id: unit.id, label: unit.title, detail: unit.abbreviation }));
  const executors = [...(overview.data?.partners || []).map(item => ({ id: item.id, label: item.title, detail: [item.partner_type || 'Đối tác', item.short_name].filter(Boolean).join(' · ') })), ...units.map(unit => ({ ...unit, detail: ['Đơn vị PVN', unit.detail].filter(Boolean).join(' · ') }))];
  const experts = (overview.data?.experts || []).map(item => ({ id: item.id, label: item.title, detail: [item.current_position, item.organization].filter(Boolean).join(' · ') }));
  const leadId = value.unit && 'id' in value.unit ? value.unit.id : null;
  return <section className="panel form-section"><h2>Bên tham gia và hạng mục</h2><div className="form-grid">
    {partner ? <PartyChoice partner={partner} value={value.party} onChange={party => onChange({ ...value, party })}/>
      : !hidden.executor && <RecordCombobox label="Bên thực hiện" options={executors} value={value.executor} onChange={executor => onChange({ ...value, executor })} placeholder="Gõ tên đối tác, liên danh hoặc đơn vị PVN…"/>}
    {!hidden.unit && <RecordCombobox label="Đơn vị đầu mối PVN" options={units} value={value.unit} onChange={unit => onChange({ ...value, unit, supporting: value.supporting.filter(item => !unit || !('id' in unit) || item.id !== unit.id) })} placeholder="Gõ tên hoặc viết tắt đơn vị…"/>}
    {!hidden.item && <ItemCombobox key={group} group={group} value={value.item} onChange={item => onChange({ ...value, item })}/>}
    <MultiRecordPicker label="Đơn vị phối hợp" options={units.filter(unit => unit.id !== leadId)} value={value.supporting} onChange={supporting => onChange({ ...value, supporting })} placeholder="Gõ tên hoặc viết tắt đơn vị…"/>
    <MultiRecordPicker label="Chuyên gia tham gia" options={experts} value={value.experts} onChange={next => onChange({ ...value, experts: next })} placeholder="Gõ tên chuyên gia…"/>
  </div></section>;
}

const link = (body: Record<string, unknown>) => api('/api/links', { method: 'POST', body: JSON.stringify(body) });

// Links chosen in the create form, written once the activity exists. A new item joins the activity's group.
// skip holds records the create call already linked (the page the form was opened from).
export async function saveActivityLinks(activityId: string, links: ActivityLinks, group: string, skip: string[] = []) {
  const leadId = links.unit && 'id' in links.unit ? links.unit.id : null;
  if (leadId && !skip.includes(leadId)) await link({ source_id: activityId, target_id: leadId, relation: 'unit', context: { subject_role: 'lead' } });
  for (const unit of links.supporting) if (unit.id !== leadId && !skip.includes(unit.id)) await link({ source_id: activityId, target_id: unit.id, relation: 'unit', context: { subject_role: 'supporting' } });
  if (links.executor && 'id' in links.executor && !skip.includes(links.executor.id)) await link({ source_id: activityId, target_id: links.executor.id, relation: 'partner' });
  for (const expert of links.experts) if (!skip.includes(expert.id)) await link({ source_id: activityId, target_id: expert.id, relation: 'expert' });
  if (links.item && 'create' in links.item) {
    const record = group === STANDARD_GROUP ? { kind: 'use_case', title: links.item.create, status: 'Đang thực hiện', data: {} }
      : { kind: 'work_item', title: links.item.create, status: 'Đang thực hiện', data: { item_group: group } };
    await api(`/api/records/${activityId}/related`, { method: 'POST', body: JSON.stringify({ record, relation: 'use_case', direction: 'from-parent' }) });
  } else if (links.item && !skip.includes(links.item.id)) await link({ source_id: activityId, target_id: links.item.id, relation: 'use_case' });
}

// On an activity: pick an item of the activity's group, or add one to that group, and link it straight away.
export function ItemLinker({ activity, onLinked }: { activity: CatalogRecord; onLinked: () => void }) {
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const group = String(activity.data.item_group || STANDARD_GROUP);
  async function choose(choice: ComboChoice | null) {
    if (!choice || busy) return;
    setBusy(true); setError(null);
    try { await saveActivityLinks(activity.id, { ...emptyActivityLinks, item: choice }, group); invalidateOverview(); onLinked(); }
    catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  return <div className="standard-linker" aria-busy={busy}><ItemCombobox group={group} value={null} onChange={choose}/><small className="muted">Đổi nhóm hạng mục ở phần Thông tin chính của hoạt động.</small><ErrorBox error={error}/></div>;
}
