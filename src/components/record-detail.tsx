"use client";
import { useEffect, useRef, useState } from 'react';
import { moduleMap, type CatalogRecord, type Membership } from '@/lib/catalog';
import { consortiumSections, contactOrganisation, dossierPath, dossierSections, type Dossier, type DossierCrumb } from '@/lib/dossier';
import { recordShortName, resolveDossierTab, visibleRecordStatus } from '@/lib/record-presentation';
import { canWriteRecord, isPrimaryDossier } from '@/lib/record-files';
import { summarySections, withDirectLinks } from '@/lib/dossier-summary';
import { api, ApiError, Badge, ErrorBox, Icon, Loading, message, RecordAvatar, useResource } from './ui';
import DossierSection from './dossier-section';
import RecordOverview from './record-overview';
import RecordFiles from './record-files';
import UnitSurvey from './unit-survey';
import RecordSummary from './record-summary';
import { invalidateOverview } from './use-overview';

export default function RecordDetail({ id, membership, onOpen: openRecord, onEdit, onBack, onDeleted, activeTab, onTab, onKind }: {
  id: string; membership: Membership; onOpen: (id: string, origin?: DossierCrumb) => void;
  onEdit: (record: CatalogRecord) => void; onBack: (kind?: string) => void; onDeleted: (kind: string) => void; activeTab: string; onTab: (tab: string) => void; onKind?: (kind: string) => void;
}) {
  // A refresh after linking or editing keeps the page on screen, so the reader stays where they were.
  const resource = useResource<Dossier>(`/api/records/${id}/dossier`, true);
  useEffect(() => { if (resource.data) onKind?.(resource.data.data.kind); }, [resource.data, onKind]);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const cancelRef = useRef<HTMLButtonElement>(null);
  const deleteRef = useRef<HTMLButtonElement>(null);
  const operationPending = useRef(false);
  const [stale, setStale] = useState(false);
  useEffect(() => { if (confirmDelete) cancelRef.current?.focus(); }, [confirmDelete]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    if (!resource.data || resource.loading || isPrimaryDossier(resource.data.data.kind) || activeTab === 'overview') return;
    const sectionId = activeTab === 'references' ? 'documents' : activeTab;
    const target = document.getElementById(`record-section-${sectionId}`);
    const disclosure = target?.closest('details');
    if (disclosure) disclosure.open = true;
    target?.scrollIntoView({ block: 'start' });
    target?.focus({ preventScroll: true });
  }, [id, activeTab, resource.data, resource.loading]);
  // A contact is a row of its unit or partner, never a page of its own: opening one shows its organisation's
  // contacts, or the directory when it belongs to none. The redirect replaces history so Back still works.
  const contactOwner = resource.data?.data.kind === 'contact' ? contactOrganisation(resource.data) : undefined;
  useEffect(() => {
    if (contactOwner === undefined) return;
    window.location.replace(`#${contactOwner ? dossierPath(contactOwner, 'contacts', []) : 'directory'}`);
  }, [contactOwner]);
  if (contactOwner !== undefined || (resource.loading && !resource.data)) return <Loading/>;
  if (resource.error && !resource.data) return <><button className="text-button back" onClick={() => onBack()}><Icon name="back"/>Quay lại</button><ErrorBox error={resource.error} retry={resource.refresh}/></>;
  if (!resource.data) return null;
  const dossier = withDirectLinks(resource.data);
  const { data: record, documents, related } = dossier;
  const mod = moduleMap[record.kind];
  const primary = isPrimaryDossier(record.kind);
  const partnerSinglePage = record.kind === 'partner';
  const reference = record.kind === 'reference';
  const sections = (record.kind === 'partner' && record.data.partner_type === 'Liên danh' ? consortiumSections : dossierSections[record.kind] || []).filter(section => section.id !== 'references');
  const allowSurvey = record.kind === 'unit' && membership.role === 'admin';
  const tab = resolveDossierTab(activeTab, ['information', ...sections.map(section => section.id)], allowSurvey);
  const selected = sections.find(section => section.id === tab);
  const status = reference ? null : visibleRecordStatus(record, documents.length);
  const writable = canWriteRecord(membership);
  const groups = summarySections(sections, related);
  const populated = groups.filter(group => group.count > 0);
  const empty = groups.filter(group => !group.count && ((writable && group.section.actions.length) || group.section.id === tab));
  const tabs = [
    { id: 'overview', label: 'Hồ sơ tổng hợp', count: null as number | null },
    { id: 'information', label: 'Thông tin đầy đủ', count: null },
    ...(allowSurvey ? [{ id: 'survey', label: 'Kết quả khảo sát', count: null }] : []),
    ...groups.map(({section, count}) => ({ id: section.id, label: section.label, count })),
    { id: 'documents', label: 'File & tài liệu', count: null },
  ];
  function onOpen(nextId: string) { openRecord(nextId, { id: record.id, title: record.title, tab }); }
  async function deleteRecord() {
    if (operationPending.current || !writable || stale) return;
    operationPending.current = true; setBusy(true); setError(null);
    try {
      await api(`/api/records/${id}`, { method: 'DELETE', body: JSON.stringify({ version: record.version }) });
      setConfirmDelete(false);
      invalidateOverview();
      onDeleted(record.kind);
    } catch (e) {
      setError(message(e)); setStale(e instanceof ApiError && e.status === 409);
    } finally { operationPending.current = false; setBusy(false); }
  }
  function cancelDelete() { setConfirmDelete(false); setError(null); setStale(false); requestAnimationFrame(() => deleteRef.current?.focus()); }
  function reloadRecord() { setConfirmDelete(false); setError(null); setStale(false); resource.refresh(); }
  const files = <RecordFiles dossier={dossier} membership={membership} onOpen={onOpen} onRefresh={resource.refresh}/>;
  const fullInformation = <RecordOverview record={record} onSurvey={allowSurvey ? () => onTab('survey') : undefined}/>;
  return <>
    <button className="text-button back" onClick={() => onBack(record.kind)}><Icon name="back"/>Quay lại</button>
    <header className="dossier-heading">
      <div className="dossier-identity-row">{primary && <RecordAvatar title={record.title} short={recordShortName(record)} large/>}<div className="dossier-identity"><div className="tags"><span className="module-label">{mod.label}</span>{status && <Badge>{status}</Badge>}</div>
        <h1>{record.title}</h1>
        <p className="dossier-subtitle">{[record.data.partner_type, record.data.country, record.kind === 'expert' ? record.data.current_position : null, record.kind === 'collaboration' ? record.data.item_category || record.data.item_group : null, record.kind === 'work_item' ? record.data.item_group : null, record.kind === 'use_case' ? record.code : null, record.kind === 'use_case' ? record.data.program : null].filter(Boolean).join(' · ')}</p>
      </div></div>
      {writable && <div className="actions dossier-edit dossier-lifecycle-actions"><>{!primary && <button className="button" disabled={busy || confirmDelete} onClick={() => onEdit(record)}><Icon name="edit"/>Chỉnh sửa</button>}<button ref={deleteRef} className="button danger-quiet" disabled={busy || confirmDelete} onClick={() => { setError(null); setStale(false); setConfirmDelete(true); }}><Icon name="trash"/>Xóa hồ sơ</button></></div>}
    </header>
    {confirmDelete && writable && <section className="lifecycle-confirm" role="region" aria-labelledby="delete-record-title" aria-describedby="delete-record-description" onKeyDown={event => { if (event.key === 'Escape' && !busy) { event.preventDefault(); cancelDelete(); } }}>
      <h2 id="delete-record-title">Xóa hồ sơ “{record.title}”?</h2><p id="delete-record-description">Hồ sơ và các liên kết của nó sẽ bị xóa hẳn, không khôi phục được. Các hồ sơ liên quan vẫn giữ nguyên; file đã tải vẫn còn trong kho File & tài liệu.</p>
      <ErrorBox error={error}/>{stale && <p>Hồ sơ đã thay đổi. Tải lại và kiểm tra thông tin trước khi xác nhận lại.</p>}
      <div className="actions"><button ref={cancelRef} className="button" disabled={busy} onClick={cancelDelete}>Hủy</button>{stale ? <button className="button" disabled={busy} onClick={reloadRecord}>Tải lại hồ sơ</button> : <button className="button danger" disabled={busy} onClick={deleteRecord}>{busy ? 'Đang xóa…' : 'Xác nhận xóa'}</button>}</div>
    </section>}
    {!confirmDelete && error && <div className="lifecycle-error"><ErrorBox error={error}/><button className="button" onClick={reloadRecord}>Tải lại hồ sơ</button></div>}
    {primary ? <>
      {!partnerSinglePage && tab !== 'overview' && <nav className="dossier-section-switcher" aria-label="Chuyển phần hồ sơ"><button className="text-button" onClick={() => onTab('overview')}><Icon name="back"/>Hồ sơ tổng hợp</button><label>Xem mục<select value={tab} onChange={event => onTab(event.target.value)}>{tabs.map(item => <option key={item.id} value={item.id}>{item.label}{item.count != null ? ` (${item.count})` : ''}</option>)}</select></label></nav>}
      {partnerSinglePage || tab === 'overview' ? <RecordSummary dossier={dossier} sections={sections} writable={writable} allowSurvey={allowSurvey} membership={membership} onRefresh={resource.refresh} onSection={onTab} onOpen={onOpen}/> : <section className="panel detail-panel">
        {tab === 'information' && fullInformation}
        {tab === 'survey' && allowSurvey && <UnitSurvey recordId={record.id}/>}
        {selected && <DossierSection key={selected.id} section={selected} record={record} related={related} links={dossier.links} membership={membership} attachments={dossier.attachments} writable={writable} onOpen={onOpen} refresh={resource.refresh}/>}
        {tab === 'documents' && files}
      </section>}
    </> : reference ? <div className="flat-record">
      <section className="panel detail-panel" id="record-section-documents" tabIndex={-1}>{files}</section>
      <details className="panel flat-record-metadata" id="record-section-information" tabIndex={-1} open={activeTab === 'information'}><summary>Thông tin tài liệu</summary><div>{fullInformation}</div></details>
    </div> : <div className="flat-record">
      <section className="panel detail-panel" id="record-section-information" tabIndex={-1}>{fullInformation}</section>
      {populated.map(({section}) => <section className="panel detail-panel" id={`record-section-${section.id}`} tabIndex={-1} key={section.id}><DossierSection section={section} record={record} related={related} links={dossier.links} membership={membership} attachments={dossier.attachments} writable={writable} onOpen={onOpen} refresh={resource.refresh}/></section>)}
      <section className="panel detail-panel" id="record-section-documents" tabIndex={-1}>{files}</section>
      {empty.length > 0 && <details className="panel flat-record-additions"><summary>Bổ sung liên kết khác</summary>{empty.map(({section}) => <section id={`record-section-${section.id}`} tabIndex={-1} key={section.id}><DossierSection section={section} record={record} related={related} links={dossier.links} membership={membership} attachments={dossier.attachments} writable={writable} onOpen={onOpen} refresh={resource.refresh}/></section>)}</details>}
    </div>}
  </>;
}
