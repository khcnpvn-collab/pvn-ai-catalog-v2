"use client";
import { useState } from 'react';
import type { CatalogRecord, Relation } from '@/lib/catalog';
import { isConsortium } from '@/lib/overview';
import RecordCombobox, { type ComboChoice } from './record-combobox';
import { api, Badge, ErrorBox, Icon, message } from './ui';
import { invalidateOverview, useOverview } from './use-overview';
import AddMenu from './add-menu';

const isLead = (relation?: Relation) => ['lead', 'Đầu mối liên danh', 'Đứng đầu liên danh'].includes(String(relation?.context?.consortium_role || relation?.context?.['Vai trò'] || ''));

// A consortium is a light group of peer partners with one lead. On a partner page this lists the
// consortia the partner belongs to; on a consortium's own page it manages the members.
export default function ConsortiumSection({ record, links, writable, onOpen, refresh }: { record: CatalogRecord; links: Relation[]; writable: boolean; onOpen: (id: string) => void; refresh: () => void }) {
  const overview = useOverview();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [mode, setMode] = useState<'join' | 'create' | null>(null);
  const [name, setName] = useState('');
  const [lead, setLead] = useState(true);
  const all = overview.data?.partners || [];
  const partners = new Map(all.map(partner => [partner.id, partner]));
  const own = isConsortium({ partner_type: String(record.data.partner_type || '') || null });
  const active = (other?: CatalogRecord) => other?.kind === 'partner';
  const memberLinks = links.filter(link => link.relation === 'partner' && link.source_id === record.id && active(link.target));
  const joined = links.filter(link => link.relation === 'partner' && link.target_id === record.id && active(link.source));
  const companies = (exclude: string[]) => all.filter(partner => !isConsortium(partner) && !exclude.includes(partner.id)).map(partner => ({ id: partner.id, label: partner.title, detail: partner.partner_type }));
  async function run(action: () => Promise<unknown>) {
    setBusy(true); setError(null);
    try { await action(); setMode(null); setName(''); invalidateOverview(); refresh(); } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }
  const link = (consortiumId: string, memberId: string, role: 'lead' | 'member') => api('/api/links', { method: 'POST', body: JSON.stringify({ source_id: consortiumId, target_id: memberId, relation: 'partner', context: { consortium_role: role } }) });
  const unlink = (relation: Relation) => api(`/api/links/${relation.id}`, { method: 'DELETE' });
  const picked = (handle: (id: string) => Promise<unknown>) => (choice: ComboChoice | null) => { if (choice && !('create' in choice)) run(() => handle(choice.id)); };
  const memberRow = (id: string, title: string, leadMember: boolean, actions?: React.ReactNode) => <article className="related-record-row" key={id}><div className="related-record-main">
    {id === record.id ? <strong>{title}</strong> : <button className="related-record-title" onClick={() => onOpen(id)}>{title}<Icon name="arrow" size={16}/></button>}</div>
    <div className="related-record-meta">{leadMember && <Badge>Đầu mối liên danh</Badge>}{actions}</div></article>;

  if (own) return <div className="consortium-section"><ErrorBox error={error}/>
    {memberLinks.length ? <div className="related-record-list">{memberLinks.map(relation => memberRow(relation.target_id, relation.target!.title, isLead(relation), writable && <>
      {!isLead(relation) && <button className="text-button" disabled={busy} onClick={() => run(async () => { await unlink(relation); await link(record.id, relation.target_id, 'lead'); })}>Đặt làm đầu mối</button>}
      <button className="text-button danger-text" disabled={busy} onClick={() => run(() => unlink(relation))}>Gỡ</button></>))}</div> : <p className="related-group-empty">Liên danh chưa có thành viên.</p>}
    {writable && <div className="consortium-add"><RecordCombobox label="Thêm đối tác vào liên danh" options={companies(memberLinks.map(relation => relation.target_id))} value={null} onChange={picked(id => link(record.id, id, memberLinks.length ? 'member' : 'lead'))} placeholder="Gõ tên đối tác…"/></div>}
  </div>;

  return <div className="consortium-section">
    {writable && !mode && <div className="section-toolbar"><AddMenu disabled={busy} options={[{ label: 'Tham gia liên danh có sẵn', onSelect: () => setMode('join') }, { label: 'Tạo liên danh mới', onSelect: () => setMode('create') }]}/></div>}
    <ErrorBox error={error}/>
    {mode && <div className="consortium-form">
      <label className="checkbox-label"><input type="checkbox" checked={lead} onChange={event => setLead(event.target.checked)}/>{record.title} là đầu mối liên danh</label>
      {mode === 'join' ? <RecordCombobox label="Chọn liên danh" options={all.filter(partner => isConsortium(partner) && !joined.some(relation => relation.source_id === partner.id)).map(partner => ({ id: partner.id, label: partner.title, detail: `${partner.member_ids.length} thành viên` }))} value={null} onChange={picked(id => link(id, record.id, lead ? 'lead' : 'member'))} placeholder="Gõ tên liên danh…"/>
        : <form className="consortium-create" onSubmit={event => { event.preventDefault(); if (name.trim()) run(() => api(`/api/records/${record.id}/related`, { method: 'POST', body: JSON.stringify({ record: { kind: 'partner', title: name.trim(), status: 'Tiềm năng', data: { partner_type: 'Liên danh' } }, relation: 'partner', direction: 'to-parent', context: { consortium_role: lead ? 'lead' : 'member' } }) })); }}>
          <label className="field">Tên liên danh<input value={name} onChange={event => setName(event.target.value)} placeholder="Ví dụ: Liên danh VNPT – Qualcomm" maxLength={250}/></label><button className="button small primary" disabled={busy || !name.trim()}>Tạo và tham gia</button></form>}
      <button className="text-button" onClick={() => setMode(null)}>Đóng</button>
    </div>}
    {joined.length ? joined.map(relation => {
      const group = partners.get(relation.source_id);
      const memberIds = group?.member_ids.length ? group.member_ids : [record.id];
      return <section className="consortium-group" key={relation.id}>
        <header className="related-kind-heading"><h3><button className="text-button" onClick={() => onOpen(relation.source_id)}>{relation.source!.title}</button><span>{memberIds.length}</span></h3>
          {writable && <button className="text-button danger-text" disabled={busy} onClick={() => run(() => unlink(relation))}>Rời liên danh</button>}</header>
        <div className="related-record-list">{memberIds.map(id => memberRow(id, id === record.id ? record.title : partners.get(id)?.title || 'Đối tác', id === record.id ? isLead(relation) : group?.lead_member_id === id))}</div>
        {writable && <div className="consortium-add"><RecordCombobox label="Thêm đối tác vào liên danh" options={companies(memberIds)} value={null} onChange={picked(id => link(relation.source_id, id, 'member'))} placeholder="Gõ tên đối tác…"/></div>}
      </section>;
    }) : <p className="related-group-empty">Chưa tham gia liên danh nào.</p>}
  </div>;
}
