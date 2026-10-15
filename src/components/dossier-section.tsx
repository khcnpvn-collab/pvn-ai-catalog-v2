"use client";
import { useState } from 'react';
import { moduleMap, type CatalogRecord, type Membership, type Relation } from '@/lib/catalog';
import type { Dossier, DossierSection as Section, RelatedRecord, SectionAction } from '@/lib/dossier';
import { cleanGeneratedRecordText, isGeneratedRecordCode, recordExcerpt, rowRecordStatus } from '@/lib/record-presentation';
import { sectionEntries } from '@/lib/dossier-summary';
import { canWriteRecord } from '@/lib/record-files';
import { api, Badge, Empty, ErrorBox, Icon, message } from './ui';
import RecordEditor from './record-editor';
import { RecordPicker } from './record-relations';
import { PartnerContacts, PartnerTimeline, TimelineInlineEditor } from './partner-sections';
import ConsortiumSection from './consortium-section';
import PartnerWorkspaceEditor from './partner-workspace-editor';
import EditorDialog from './editor-dialog';
import RoadmapSection from './roadmap-sections';
import { invalidateOverview } from './use-overview';
import { ItemLinker } from './activity-link-fields';

const roadmapSelectors = new Set(['activity-list', 'unit-roles', 'standard-partners', 'unit-standards', 'unit-partners', 'activity-partner']);
const partnerSelectors = new Set(['contact-grid', 'partner-contact', 'partner-collaboration', 'partner-engagement', 'partner-consortium', 'consortium-members']);

function description(record: CatalogRecord) {
  if (record.kind === 'expert') return [record.data.current_position, record.data.academic_title, record.data.country].filter(Boolean).join(' · ');
  if (record.kind === 'reference') return [record.data.reference_type, record.data.date_note, record.data.edition].filter(Boolean).join(' · ');
  if (record.kind === 'contact') return [record.data.position, record.data.department, record.data.email, record.data.phone].filter(Boolean).join(' · ');
  const mainFields: Record<string, string[]> = { unit: ['sector'], partner: ['specialties'], use_case: ['program', 'objective'], collaboration: ['scope'], engagement: ['conclusions', 'location'] };
  const value = (mainFields[record.kind] || []).map(key => record.data[key]).find(value => value != null && String(value).trim());
  return recordExcerpt(value ? String(value) : cleanGeneratedRecordText(record.summary, isGeneratedRecordCode(record.code)));
}

// On the summary page the heading is one compact row (title, count, actions); previewLimit trims long lists and
// onShowAll opens the section's own view with every entry.
export default function DossierSection({ section, record, related, links, membership, writable, onOpen, refresh, attachments = [], compactCount, previewLimit, onShowAll }: {
  section: Section; record: CatalogRecord; related: RelatedRecord[]; writable: boolean;
  links: Relation[]; membership: Membership; onOpen: (id: string) => void; refresh: () => void; attachments?: Dossier['attachments']; compactCount?: number;
  previewLimit?: number; onShowAll?: () => void;
}) {
  const [action, setAction] = useState<{ mode: 'create' | 'link'; spec: SectionAction } | null>(null);
  // A unit role link (activity or standard problem ↔ unit) can be made the lead while it is chosen.
  const [asLead, setAsLead] = useState(false);
  const roleLink = Boolean(action?.spec.context?.subject_role) && ((action?.spec.kind === 'unit' && ['collaboration', 'use_case'].includes(record.kind)) || (action?.spec.kind === 'use_case' && record.kind === 'unit'));
  const chooseLead = () => { const spec = section.actions.find(item => item.context?.subject_role); if (spec) { setError(null); setSelectedTarget(null); setAsLead(true); setAction({ mode: 'link', spec }); } };
  const [editingRecord, setEditingRecord] = useState<CatalogRecord | null>(null);
  const [selectedTarget, setSelectedTarget] = useState<CatalogRecord | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const entries = sectionEntries(section, related);
  const done = () => { invalidateOverview(); refresh(); };
  const editRecord = (target: CatalogRecord) => { if (canWriteRecord(membership)) setEditingRecord(target); };
  async function link() {
    if (!action || !selectedTarget || busy) return;
    const target = selectedTarget;
    if (target.id === record.id) {
      setError('Không thể liên kết hồ sơ với chính nó.'); return;
    }
    setBusy(true); setError(null);
    try {
      await api('/api/links', { method: 'POST', body: JSON.stringify({
        source_id: action.spec.direction === 'to-parent' ? target.id : record.id,
        target_id: action.spec.direction === 'to-parent' ? record.id : target.id,
        relation: action.spec.relation,
        ...(action.spec.context ? { context: roleLink && asLead ? { ...action.spec.context, subject_role: 'lead' } : action.spec.context } : {}),
      }) });
      setAction(null); setSelectedTarget(null); setAsLead(false); done();
    } catch (e) { setError(message(e)); } finally { setBusy(false); }
  }
  if (editingRecord && record.kind === 'partner' && ['collaboration', 'engagement'].includes(editingRecord.kind)) return <EditorDialog title={`Chỉnh sửa ${editingRecord.kind === 'collaboration' ? 'hoạt động' : 'mốc làm việc'}`} onClose={() => setEditingRecord(null)}><PartnerWorkspaceEditor kind={editingRecord.kind as 'collaboration' | 'engagement'} record={editingRecord} partner={record} cooperationEntries={related.filter(entry => entry.record.kind === 'collaboration' && !entry.via)} membership={membership} onOpen={onOpen} onDone={() => { setEditingRecord(null); done(); }}/></EditorDialog>;
  if (editingRecord?.kind === 'engagement') return <TimelineInlineEditor record={editingRecord} onCancel={() => setEditingRecord(null)} onSaved={() => { setEditingRecord(null); done(); }}/>;
  if (editingRecord) return <RecordEditor kind={editingRecord.kind} record={editingRecord} embedded onCancel={() => setEditingRecord(null)} onSave={() => { setEditingRecord(null); done(); }}/>;
  if (action?.mode === 'create' && record.kind === 'partner' && ['collaboration', 'engagement'].includes(action.spec.kind)) return <EditorDialog title={`Thêm ${action.spec.kind === 'collaboration' ? 'hoạt động' : 'mốc làm việc'}`} onClose={() => setAction(null)}><PartnerWorkspaceEditor kind={action.spec.kind as 'collaboration' | 'engagement'} partner={record} cooperationEntries={related.filter(entry => entry.record.kind === 'collaboration' && !entry.via)} membership={membership} onOpen={onOpen} onDone={() => { setAction(null); done(); }}/></EditorDialog>;
  if (action?.mode === 'create') return <div className="section-editor-form"><RecordEditor kind={action.spec.kind} embedded
    context={{ parentId: record.id, parentTitle: record.title, parentKind: record.kind, relation: action.spec.relation, direction: action.spec.direction, ...(action.spec.context ? { context: action.spec.context } : {}) }}
    onCancel={() => setAction(null)} onSave={() => { setAction(null); done(); }}/></div>;
  // An activity's item is one list whatever its kind: a standard problem is just one of the item groups.
  const itemSection = record.kind === 'collaboration' && section.id === 'contents';
  const groups = itemSection ? [{ kind: entries[0]?.record.kind || section.kinds[0], entries, actions: [] as SectionAction[] }]
    : section.kinds.map(kind => ({ kind, entries: [...new Map(entries.filter(entry => entry.record.kind === kind).map(entry => [entry.record.id, entry])).values()], actions: section.actions.filter(spec => spec.kind === kind) }));
  const directLink = (entry: RelatedRecord) => entry.via ? undefined : links.find(link => link.relation === entry.relation
    && ((link.source_id === record.id && link.target_id === entry.record.id) || (link.target_id === record.id && link.source_id === entry.record.id)));
  async function unlink(entry: RelatedRecord) {
    const existing = directLink(entry);
    if (!existing || busy) return;
    setBusy(true); setError(null);
    try { await api(`/api/links/${existing.id}`, { method: 'DELETE' }); done(); } catch (e) { setError(message(e)); } finally { setBusy(false); }
  }
  function renderActions(actions: SectionAction[]) {
    if (['partner', 'unit'].includes(record.kind) && ['partner-contact', 'contact-grid'].includes(section.selector || '')) return null;
    // The consortium view carries its own join / create / add actions.
    if (['partner-consortium', 'consortium-members'].includes(section.selector || '')) return null;
    if (record.kind === 'partner' && ['partner-collaboration', 'partner-engagement'].includes(section.selector || '')) return writable && <div className="related-kind-actions"><button className="button small" disabled={busy} onClick={() => { setError(null); setAction({ mode: 'create', spec: actions[0] }); }}><Icon name="plus" size={16}/>{section.selector === 'partner-collaboration' ? 'Thêm hoạt động' : 'Thêm mốc làm việc'}</button></div>;
    // An activity has at most one partner and one standard problem.
    if (section.selector === 'activity-partner' && entries.length) return null;
    if (record.kind === 'collaboration' && section.id === 'contents') return null;
    return writable && <div className="related-kind-actions">{actions.map(spec => <div className="actions" key={`${spec.relation}-${spec.direction}-${spec.kind}`}>
      {spec.label && <span className="related-action-label">{spec.label}</span>}
      <button className="button small" disabled={busy} onClick={() => { setError(null); setSelectedTarget(null); setAction({ mode: 'create', spec }); }}><Icon name="plus" size={16}/>Thêm mới</button>
      <button className="text-button" disabled={busy} onClick={() => { setError(null); setSelectedTarget(null); setAsLead(false); setAction({ mode: 'link', spec }); }}>Chọn có sẵn</button>
    </div>)}</div>;
  }
  const partnerView = section.selector && partnerSelectors.has(section.selector) && (record.kind === 'partner' || (record.kind === 'unit' && section.selector === 'contact-grid'));
  const roadmapView = section.selector && roadmapSelectors.has(section.selector);
  const milestoneView = section.selector === 'milestones';
  // On the summary page an empty section is just its heading row: the 0 count already says it.
  // An activity without a standard problem searches the catalogue in place of the add/choose buttons.
  const standardLinker = record.kind === 'collaboration' && section.id === 'contents' && writable && !entries.length;
  // Contacts and consortia keep their own add buttons inside the section, so they stay open even when empty.
  const collapsed = compactCount === 0 && !action && !standardLinker && !['partner-contact', 'contact-grid', 'partner-consortium', 'consortium-members'].includes(section.selector || '');
  const preview = <T,>(items: T[]) => previewLimit ? items.slice(0, previewLimit) : items;
  const showAll = (total: number, kind: string) => previewLimit && onShowAll && total > previewLimit && <button className="text-button related-show-all" onClick={onShowAll}>Xem tất cả {total} {moduleMap[kind].singular}<Icon name="arrow" size={16}/></button>;
  return <>
    {compactCount == null && <div className="section-heading"><div><h2>{section.label}{section.kinds.length === 1 && <span className="section-record-count">{entries.length}</span>}</h2><p>{section.description}</p></div>{(section.kinds.length === 1 || roadmapView) && renderActions(section.actions)}</div>}
    {compactCount != null && <header className="cv-section-heading"><h2>{section.label}<span className="cv-count">{compactCount}</span></h2>{(section.kinds.length === 1 || roadmapView) && renderActions(section.actions)}</header>}
    <ErrorBox error={error}/>
    {action?.mode === 'link' && <div className="inline-form"><div className="section-heading"><h3>Chọn {moduleMap[action.spec.kind].singular}</h3><div className="actions"><button className="button small" disabled={busy} onClick={() => { setAction(null); setSelectedTarget(null); }}>Hủy</button></div></div>{selectedTarget ? <div className="selected-record"><div><strong>{selectedTarget.title}</strong><p>{moduleMap[selectedTarget.kind]?.label}</p></div><button className="button small" onClick={() => setSelectedTarget(null)}>Chọn lại</button></div> : <div inert={busy}><RecordPicker key={action.spec.kind} fixedKind={action.spec.kind} exclude={record.id} onSelect={setSelectedTarget}/></div>}{roleLink && <label className="checkbox-label"><input type="checkbox" checked={asLead} onChange={event => setAsLead(event.target.checked)}/>{record.kind === 'collaboration' ? 'Đặt làm đơn vị đầu mối' : 'Đặt làm đầu mối ưu tiên triển khai'}</label>}{selectedTarget && <div className="actions link-review-actions"><button className="button primary" disabled={busy} onClick={link}>{busy ? 'Đang lưu…' : 'Lưu liên kết'}</button></div>}</div>}
    {standardLinker && <ItemLinker activity={record} onLinked={done}/>}
    {!collapsed && !standardLinker && (roadmapView ? <div className="partner-section-content"><RoadmapSection selector={section.selector!} record={record} entries={entries} links={links} writable={writable} onOpen={onOpen} refresh={done} limit={previewLimit} onShowAll={onShowAll} onChooseLead={chooseLead}/></div> : milestoneView ? <div className="partner-section-content">{entries.length ? <PartnerTimeline entries={preview(entries)} attachments={attachments} onOpen={onOpen} onRefresh={done} onEdit={membership.role !== 'reader' ? editRecord : undefined} canEdit={() => canWriteRecord(membership)}/> : <p className="related-group-empty">Chưa có mốc làm việc.</p>}</div> : partnerView ? <div className="partner-section-content">
      {['partner-contact', 'contact-grid'].includes(section.selector || '') && <PartnerContacts entries={entries} owner={record} writable={writable} onRefresh={refresh} canEdit={() => canWriteRecord(membership)}/>}
      {section.selector === 'partner-collaboration' && <RoadmapSection selector="activity-list" record={record} entries={entries} links={links} writable={writable} onOpen={onOpen} refresh={done} limit={previewLimit} onShowAll={onShowAll}/>}
      {section.selector === 'partner-engagement' && (entries.length ? <PartnerTimeline entries={entries} attachments={attachments} onOpen={onOpen} onRefresh={refresh} onEdit={membership.role !== 'reader' ? editRecord : undefined} canEdit={() => canWriteRecord(membership)}/> : <p className="related-group-empty">Chưa có mốc làm việc.</p>)}
      {['partner-consortium', 'consortium-members'].includes(section.selector || '') && <ConsortiumSection record={record} links={links} writable={writable} onOpen={onOpen} refresh={done}/>}
    </div> : <div className="related-kind-groups">{groups.filter(group => group.entries.length || (writable && group.actions.length)).map(group => <section className="related-kind-group" key={group.kind}>
      {section.kinds.length > 1 && !itemSection && <header className="related-kind-heading"><h3>{moduleMap[group.kind].label}<span>{group.entries.length}</span></h3>{renderActions(group.actions)}</header>}

      {group.entries.length ? <div className="related-record-list">{preview(group.entries).map(entry => {
        const status = rowRecordStatus(entry.record);
        const excerpt = description(entry.record);
        return <article key={entry.record.id} className="related-record-row"><div className="related-record-main">
          <button className="related-record-title" onClick={() => onOpen(entry.record.id)}>{entry.record.title}<Icon name="arrow" size={16}/></button>
          {excerpt && <p>{excerpt}</p>}
          {entry.via && <div className="related-record-via">Qua <button className="text-button" onClick={() => onOpen(entry.via!.id)}>{entry.via.title}</button></div>}
        </div><div className="related-record-meta">{status && <Badge>{status}</Badge>}{entry.relation === 'parent' && !entry.via && <Badge>{entry.direction === 'incoming' ? 'Hồ sơ con' : 'Hồ sơ cha'}</Badge>}{canWriteRecord(membership) && <button className="icon-button record-inline-edit" onClick={() => editRecord(entry.record)} aria-label={`Chỉnh sửa ${entry.record.title}`}><Icon name="edit" size={15}/></button>}{writable && directLink(entry) && <button className="text-button" disabled={busy} onClick={() => unlink(entry)}>Gỡ</button>}</div></article>;
      })}</div> : <p className="related-group-empty">Chưa có hồ sơ trong nhóm này.</p>}
      {showAll(group.entries.length, group.kind)}
    </section>)}</div>)}
    {!collapsed && !entries.length && !writable && !partnerView && !roadmapView && !milestoneView && <Empty title={`Chưa có ${section.label.toLowerCase()}`} text="Các hồ sơ đã kết nối sẽ hiển thị tại đây."/>}
  </>;
}
