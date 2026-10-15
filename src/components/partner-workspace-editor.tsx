"use client";

import { useCallback, useMemo, useRef, useState } from "react";
import { STANDARD_GROUP, type CatalogRecord, type Membership, type RecordInput, type Relation } from "@/lib/catalog";
import type { Dossier, RelatedRecord } from "@/lib/dossier";
import { canWriteRecord } from "@/lib/record-files";
import { DocumentItems, UploadForm } from "./document-library";
import RecordEditor from "./record-editor";
import { RecordPicker } from "./record-relations";
import { ActivityLinkFields, emptyActivityLinks, ItemLinker, PartyChoice, partyContext, saveActivityLinks, type ActivityLinks, type Party } from "./activity-link-fields";
import { api, Badge, confirmDiscardChanges, ErrorBox, hasUnsavedChanges, Icon, Loading, message, useResource } from "./ui";

type WorkspaceKind = "collaboration" | "engagement";

function directOther(recordId: string, link: Relation) {
  return link.source_id === recordId ? link.target : link.source;
}

function directLinks(dossier: Dossier | null | undefined, relation: string, kind: string) {
  if (!dossier) return [];
  return dossier.links.filter(link => link.relation === relation && directOther(dossier.data.id, link)?.kind === kind);
}

function RelationRows({ recordId, links, label, onRemove, onLead, busy }: {
  recordId: string; links: Relation[]; label: string; onRemove: (link: Relation) => void;
  onLead?: (link: Relation) => void; busy: boolean;
}) {
  const [confirming, setConfirming] = useState<string | null>(null);
  const list = useRef<HTMLDivElement>(null);
  // Return focus to the row's "Bỏ" button so keyboard users stay inside the dialog.
  function keep(id: string) { setConfirming(null); window.setTimeout(() => list.current?.querySelector<HTMLButtonElement>(`[data-remove-link="${id}"]`)?.focus()); }
  if (!links.length) return <p className="related-group-empty">Chưa có {label}.</p>;
  return <div className="workspace-relation-list" ref={list}>{links.map(link => {
    const other = directOther(recordId, link);
    const lead = link.context?.subject_role === "lead";
    return other && <div className="workspace-relation-row" key={link.id}>
      <div><strong>{other.title}</strong>{lead && <Badge>Đầu mối</Badge>}<small>{other.data.abbreviation || other.data.sector || "Hồ sơ trong danh mục"}</small></div>
      {confirming === link.id ? <div className="actions workspace-relation-confirm" role="group" aria-label={`Xác nhận bỏ liên kết với ${other.title}`} onKeyDown={event => { if (event.key === "Escape") { event.stopPropagation(); keep(link.id); } }}><span>Bỏ liên kết với “{other.title}”?</span><button className="button small danger" disabled={busy} onClick={() => { setConfirming(null); onRemove(link); }}>Bỏ liên kết</button><button className="button small" autoFocus disabled={busy} onClick={() => keep(link.id)}>Giữ lại</button></div>
        : <div className="actions">{onLead && !lead && <button className="text-button" disabled={busy} onClick={() => onLead(link)}>Đặt làm đầu mối</button>}<button className="text-button danger-text" data-remove-link={link.id} disabled={busy} onClick={() => setConfirming(link.id)}>Bỏ</button></div>}
    </div>;
  })}</div>;
}

// Existing records open on the overview of links and files; "Sửa thông tin" opens the form and its Hủy returns here.
// New records start with the form, then continue to the overview once saved.
export default function PartnerWorkspaceEditor({ kind, record, partner, cooperationEntries, membership, onDone, onOpen }: {
  kind: WorkspaceKind; record?: CatalogRecord; partner: CatalogRecord; cooperationEntries: RelatedRecord[];
  membership: Membership; onDone: () => void; onOpen: (id: string) => void;
}) {
  const [working, setWorking] = useState<CatalogRecord | null>(record || null);
  const [editingInformation, setEditingInformation] = useState(!record);
  const [adding, setAdding] = useState<"unit" | "new_content" | "upload" | null>(null);
  const [links, setLinks] = useState<ActivityLinks>(emptyActivityLinks);
  // The item list in the create form follows the group chosen in the form; a new group drops the chosen item.
  const [formGroup, setFormGroup] = useState(STANDARD_GROUP);
  const shownGroup = useRef(STANDARD_GROUP);
  const followGroup = useCallback((data: RecordInput["data"]) => {
    const next = String(data?.item_group || STANDARD_GROUP);
    if (next === shownGroup.current) return;
    shownGroup.current = next; setFormGroup(next); setLinks(value => ({ ...value, item: null }));
  }, []);
  const [partyDraft, setPartyDraft] = useState<Party | null>(null);
  const [unitLead, setUnitLead] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const resource = useResource<Dossier>(working ? `/api/records/${working.id}/dossier` : null);
  const dossier = resource.data;
  const unitLinks = directLinks(dossier, "unit", "unit");
  const partyLink = dossier?.links.find(link => link.source_id === working?.id && link.relation === "partner");
  const useCaseLinks = [...directLinks(dossier, "use_case", "use_case"), ...directLinks(dossier, "use_case", "work_item")];
  const collaborationLinks = directLinks(dossier, "collaboration", "collaboration").filter(link => link.source_id === working?.id);
  const linkedContentIds = new Set(collaborationLinks.map(link => link.target_id));
  const availableContents = useMemo(() => {
    const unique = new Map<string, CatalogRecord>();
    for (const entry of cooperationEntries) unique.set(entry.record.id, entry.record);
    return [...unique.values()];
  }, [cooperationEntries]);
  const writable = Boolean(working) && canWriteRecord(membership);
  const root = useRef<HTMLDivElement>(null);
  // Leaving the overview drops any inline create form still open below it.
  function leave(next: () => void) { if (confirmDiscardChanges(hasUnsavedChanges(root.current))) next(); }

  function saved(next: CatalogRecord) {
    setWorking(next); setEditingInformation(false); setAdding(null); setError(null);
    setTimeout(resource.refresh, 0);
  }

  async function addRelation(target: CatalogRecord, relation: string, context?: Record<string, string>) {
    if (!working) return;
    setBusy(true); setError(null);
    try {
      await api("/api/links", { method: "POST", body: JSON.stringify({ source_id: working.id, target_id: target.id, relation, ...(context ? { context } : {}) }) });
      setAdding(null); setUnitLead(false); resource.refresh();
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }

  async function removeRelation(link: Relation) {
    setBusy(true); setError(null);
    try { await api(`/api/links/${link.id}`, { method: "DELETE" }); resource.refresh(); }
    catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }

  async function makeLead(link: Relation) {
    if (!working) return;
    setBusy(true); setError(null);
    try {
      const target = directOther(working.id, link);
      if (target) await api("/api/links", { method: "POST", body: JSON.stringify({ source_id: working.id, target_id: target.id, relation: "unit", context: { ...link.context, subject_role: "lead" } }) });
      resource.refresh();
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }

  async function toggleContent(content: CatalogRecord) {
    if (!working) return;
    const existing = collaborationLinks.find(link => link.target_id === content.id);
    if (existing) return removeRelation(existing);
    return addRelation(content, "collaboration");
  }

  // A new activity is linked to this partner, or to a consortium it belongs to, when it is created.
  async function created(next: CatalogRecord) {
    let failure: string | null = null;
    if (kind === "collaboration") { try { await saveActivityLinks(next.id, links, String(next.data.item_group || STANDARD_GROUP)); } catch (cause) { failure = `Đã lưu hoạt động nhưng chưa gắn được liên kết: ${message(cause)}`; } }
    saved(next);
    if (failure) setError(failure);
  }

  async function changeParty(draft: Party) {
    if (!working) return;
    setBusy(true); setError(null);
    try {
      if (partyLink) await api(`/api/links/${partyLink.id}`, { method: "DELETE" });
      await api("/api/links", { method: "POST", body: JSON.stringify({ source_id: working.id, target_id: draft.consortiumId || partner.id, relation: "partner", ...(partyContext(draft, partner.id) ? { context: partyContext(draft, partner.id) } : {}) }) });
      setPartyDraft(null); resource.refresh();
    } catch (cause) { setError(message(cause)); } finally { setBusy(false); }
  }

  if (!working || editingInformation) {
    const party = !working && links.party.consortiumId ? links.party : null;
    return <div className="workspace-editor-step">
      <RecordEditor kind={kind} record={working || undefined} embedded hideHeading
        context={!working ? { parentId: party?.consortiumId || partner.id, parentTitle: partner.title, parentKind: "partner", relation: "partner", direction: "to-parent", ...(party && partyContext(party, partner.id) ? { context: partyContext(party, partner.id) } : {}) } : undefined}
        onCancel={() => working ? setEditingInformation(false) : onDone()} onSave={working ? saved : created} onDataChange={!working && kind === "collaboration" ? followGroup : undefined}>
        {!working && kind === "collaboration" && <ActivityLinkFields partner={partner} group={formGroup} value={links} onChange={setLinks}/>}
      </RecordEditor>
    </div>;
  }

  if (resource.loading && !dossier) return <Loading label="Đang tải liên kết và file…"/>;
  if (resource.error && !dossier) return <ErrorBox error={resource.error} retry={resource.refresh}/>;

  return <div className="partner-workspace-editor" ref={root}>
    <div className="workspace-editor-toolbar"><div><Badge>{kind === "collaboration" ? "Hoạt động" : "Mốc làm việc"}</Badge><h3>{working.title}</h3></div><div className="actions"><button className="button" onClick={() => leave(() => { setAdding(null); setEditingInformation(true); })}><Icon name="edit" size={15}/>Sửa thông tin</button><button className="button primary" onClick={() => leave(onDone)}>Hoàn tất</button></div></div>
    <ErrorBox error={error || resource.error}/>

    {kind === "collaboration" && <>
      <section className="workspace-editor-section"><header><div><h3>Chủ thể PVN</h3><p>Chọn nhiều đơn vị hoặc Tập đoàn và đánh dấu một chủ thể đầu mối khi cần.</p></div>{writable && !adding && <button className="button small" onClick={() => setAdding("unit")}><Icon name="plus" size={15}/>Thêm chủ thể</button>}</header>
        <RelationRows recordId={working.id} links={unitLinks} label="chủ thể PVN" onRemove={removeRelation} onLead={makeLead} busy={busy}/>
        {adding === "unit" && <div className="inline-form"><div className="section-heading"><h3>Chọn chủ thể trong danh mục đơn vị</h3><button className="icon-button" onClick={() => setAdding(null)} aria-label="Đóng"><Icon name="close"/></button></div><label className="checkbox-label"><input type="checkbox" checked={unitLead} onChange={event => setUnitLead(event.target.checked)}/>Chủ thể đầu mối</label><RecordPicker fixedKind="unit" onSelect={target => addRelation(target, "unit", { subject_role: unitLead ? "lead" : "supporting" })}/></div>}
      </section>

      <section className="workspace-editor-section"><header><div><h3>Bên thực hiện</h3><p>Chính đối tác này, hoặc một liên danh đối tác tham gia.</p></div>{writable && !partyDraft && <button className="text-button" onClick={() => setPartyDraft({ consortiumId: partyLink && partyLink.target_id !== partner.id ? partyLink.target_id : "", lead: partyLink?.context?.lead_member_id === partner.id })}>Đổi</button>}</header>
        {partyDraft ? <div className="party-editor"><PartyChoice partner={partner} value={partyDraft} onChange={setPartyDraft}/><div className="actions"><button className="button small primary" disabled={busy} onClick={() => changeParty(partyDraft)}>Lưu bên thực hiện</button><button className="button small" disabled={busy} onClick={() => setPartyDraft(null)}>Hủy</button></div></div>
          : partyLink?.target ? <div className="workspace-relation-row"><div><strong>{partyLink.target.title}</strong>{partyLink.target_id !== partner.id && <Badge>Liên danh</Badge>}{partyLink.context?.lead_member_id === partner.id && <Badge>Đối tác này là đầu mối</Badge>}</div></div>
          : <p className="related-group-empty">Chưa chọn bên thực hiện.</p>}
      </section>

      <section className="workspace-editor-section"><header><div><h3>Hạng mục</h3><p>Bài toán chuẩn hoặc hạng mục thuộc nhóm {String(working.data.item_group || STANDARD_GROUP)}; để trống nếu chưa xác định.</p></div></header>
        <RelationRows recordId={working.id} links={useCaseLinks} label="hạng mục" onRemove={removeRelation} busy={busy}/>
        {writable && !useCaseLinks.length && <ItemLinker activity={working} onLinked={resource.refresh}/>}
      </section>
    </>}

    {kind === "engagement" && <section className="workspace-editor-section"><header><div><h3>Hoạt động liên quan</h3><p>Một mốc có thể thuộc nhiều nội dung; để trống nếu đây là mốc làm việc chung với đối tác.</p></div>{writable && !adding && <button className="text-button" onClick={() => setAdding("new_content")}><Icon name="plus" size={15}/>Tạo hoạt động mới</button>}</header>
      {availableContents.length ? <div className="workspace-check-grid">{availableContents.map(content => <label key={content.id}><input type="checkbox" checked={linkedContentIds.has(content.id)} disabled={busy} onChange={() => toggleContent(content)}/><span><strong>{content.title}</strong><small>{content.data.item_group || content.status}</small></span></label>)}</div> : <p className="related-group-empty">Đối tác chưa có hoạt động.</p>}
      {adding === "new_content" && <div className="inline-form"><RecordEditor kind="collaboration" embedded context={{ parentId: partner.id, parentTitle: partner.title, parentKind: "partner", relation: "partner", direction: "to-parent" }} onCancel={() => setAdding(null)} onSave={async created => { await addRelation(created, "collaboration"); }}/></div>}
    </section>}

    <section className="workspace-editor-section"><header><div><h3>File đính kèm</h3><p>File tải tại đây được lưu trực tiếp trong {kind === "collaboration" ? "thư mục hoạt động" : "mốc làm việc"}.</p></div>{writable && !adding && <button className="button small" onClick={() => setAdding("upload")}><Icon name="upload" size={15}/>Đính kèm file</button>}</header>
      {adding === "upload" && <UploadForm recordId={working.id} onDone={() => { setAdding(null); resource.refresh(); }} onCancel={() => setAdding(null)}/>} 
      {dossier?.documents.length ? <DocumentItems documents={dossier.documents} membership={membership} onOpen={onOpen} onRefresh={resource.refresh} recordId={working.id} showLinkedRecords={false}/> : adding !== "upload" && <p className="related-group-empty">Chưa có file đính kèm trực tiếp.</p>}
    </section>
  </div>;
}
