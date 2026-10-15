"use client";
import { Fragment, useEffect, useRef, useState, type FormEvent, type ReactNode } from "react";
import { groupFields, ITEM_CATEGORIES, moduleMap, modules, splitTags, STANDARD_GROUP, validateRecord, type CatalogRecord, type RecordInput } from "@/lib/catalog";
import TagInput from "./tag-input";
import { useCreateLinks } from "./record-create-links";
import { cleanGeneratedRecordText, isGeneratedRecordCode, visibleOperationalStatus } from "@/lib/record-presentation";
import type { DossierContext } from "@/lib/dossier";
import { editorPresentation, visibleEditorDataKeys } from "@/lib/editor-presentation";
import { api, confirmDiscardChanges, ErrorBox, Heading, Icon, message } from "./ui";
import { invalidateOverview, useOverview } from "./use-overview";
import type { Overview } from "@/lib/overview";

// Free tags suggest the values already in use, so one wording wins over time.
function tagSuggestions(kind: string, key: string, base: string[] = [], overview?: Overview) {
  const used = !overview ? [] : kind === "use_case" && key === "category" ? overview.standards.map(item => item.category)
    : kind === "partner" && key === "specialties" ? overview.partners.flatMap(item => splitTags(item.specialties)) : [];
  return [...new Set([...base, ...used].filter((value): value is string => Boolean(value?.trim())))].sort((a, b) => a.localeCompare(b, "vi"));
}

// Lists with a natural default start filled in, so required choices are rarely empty. An activity
// added from an item takes that item's group; preset carries values chosen before the form opened.
function startingData(kind: string, context: DossierContext | undefined, overview: Overview | undefined, preset: Record<string, string> = {}): Record<string, string> {
  if (kind === "unit") return { unit_type: "Đơn vị thành viên", ...preset };
  if (kind === "collaboration") {
    const parentItem = context?.parentKind === "work_item" ? overview?.work_items.find(item => item.id === context.parentId) : null;
    return { item_group: parentItem?.item_group || STANDARD_GROUP, ...preset };
  }
  return { ...preset };
}

function startingStatus(kind: string) {
  if (kind === "partner") return "Tiềm năng";
  const statuses = moduleMap[kind].statuses;
  return ['Chưa xác minh', 'Chưa liên hệ', 'Chưa ghi nhận', 'Chưa đính kèm'].find(status => statuses.includes(status)) || statuses[0];
}

function recordInput(record: CatalogRecord): RecordInput {
  // Only registry fields are sent back; hidden fields keep their stored values.
  const keys = new Set(moduleMap[record.kind].fields.map(field => field.key));
  const data = Object.fromEntries(Object.entries(record.data).filter(([key]) => keys.has(key)));
  return { id: record.id, version: record.version, kind: record.kind, title: record.title, code: record.code, summary: record.summary, status: record.status, data };
}

// children adds a section of linked records (for example who carries out an activity) after the first group of fields,
// where an activity picks its item group; a new record without children gets the standard link fields there.
export default function RecordEditor({ kind, record, context, onSave, onCancel, embedded = false, hideHeading = false, preset, onDataChange, children }: { kind: string; record?: CatalogRecord; context?: DossierContext; onSave: (record: CatalogRecord) => void | Promise<void>; onCancel: () => void; embedded?: boolean; hideHeading?: boolean; children?: ReactNode; preset?: Record<string, string>; onDataChange?: (data: RecordInput["data"]) => void }) {
  const overview = useOverview();
  const [form, setForm] = useState<RecordInput>(() => record ? recordInput(record) : { kind, title: "", status: startingStatus(kind), data: startingData(kind, context, overview.data, preset) });
  useEffect(() => { onDataChange?.(form.data); }, [form.data, onDataChange]);
  const [editedFields, setEditedFields] = useState<Set<string>>(() => new Set());
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  // Set when a new record was saved but some of its links were not: the form offers to open it instead of saving twice.
  const [savedRecord, setSavedRecord] = useState<CatalogRecord | null>(null);
  const createLinks = useCreateLinks(record || children ? null : form.kind, context, form.data);
  const formRef = useRef<HTMLFormElement>(null);
  const dirty = editedFields.size > 0;
  useEffect(() => {
    if (!dirty) return;
    const warn = (event: BeforeUnloadEvent) => { event.preventDefault(); event.returnValue = ""; };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty]);
  // Clear the unsaved marker before handing control back, so the parent's navigation does not ask again.
  function release() { formRef.current?.removeAttribute("data-dirty"); }
  function cancel() { if (!confirmDiscardChanges(dirty)) return; release(); onCancel(); }
  const mod = moduleMap[form.kind];
  const presentation = editorPresentation(form.kind, context?.parentKind);
  const operationalStatuses = mod.kind === "reference" ? [] : mod.statuses.filter(status => visibleOperationalStatus(status));
  const visibleFieldKeys = visibleEditorDataKeys(form.kind, context?.parentKind, mod.fields.map(field => field.key));
  const visibleFields = visibleFieldKeys.flatMap(key => {
    const field = mod.fields.find(candidate => candidate.key === key);
    // The unit's declared title only exists for problems imported from the survey.
    return field && !field.hidden && !(field.key === 'declared_title' && !record?.data.declared_title) ? [field] : [];
  });
  const fieldGroups = groupFields(visibleFields, `Nội dung ${mod.singular}`);
  const generated = isGeneratedRecordCode(record?.code);
  function displayedText(key: string, value: string | null | undefined) { return cleanGeneratedRecordText(value, generated && !editedFields.has(key)); }
  function markEdited(key: string) { setEditedFields(current => new Set([...current, key])); }
  function update(key: string, value: string) { markEdited(key); setForm(current => ({ ...current, [key]: value })); }
  async function submit(event: FormEvent) {
    event.preventDefault();
    const input = { ...form, title: form.title.trim() };
    const invalid = validateRecord(input);
    if (invalid) { setError(invalid); return; }
    setBusy(true); setError(null);
    try { const result = await api<{ data: CatalogRecord }>(record ? `/api/records/${record.id}` : context ? `/api/records/${context.parentId}/related` : "/api/records", { method: record ? "PATCH" : "POST", body: JSON.stringify(context && !record ? { record: input, relation: context.relation, direction: context.direction, ...(context.context ? { context: context.context } : {}) } : input) }); release(); setEditedFields(new Set());
      const linkError = record ? null : await createLinks.save(result.data).then(() => null, (cause: unknown) => message(cause));
      if (linkError) { invalidateOverview(); setSavedRecord(result.data); setError(`Đã lưu ${mod.singular} nhưng chưa gắn được một số liên kết: ${linkError}. Mở hồ sơ để gắn tiếp.`); return; }
      await onSave(result.data); invalidateOverview(); }
    catch (e) { setError(message(e)); } finally { setBusy(false); }
  }
  const editorTitle = `${record ? "Chỉnh sửa" : "Thêm"} ${mod.singular}`;
  return <>{embedded ? !hideHeading && <div className="embedded-editor-heading"><div><h3>{editorTitle}</h3>{context && <p>Hồ sơ sẽ được lưu và gắn vào: {context.parentTitle}.</p>}</div><button className="icon-button" type="button" onClick={cancel} aria-label="Đóng biểu mẫu"><Icon name="close"/></button></div> : <><button className="text-button back" onClick={cancel}><Icon name="back"/>Quay lại</button><Heading title={editorTitle} description={context ? `Hồ sơ sẽ được lưu và gắn vào: ${context.parentTitle}.` : "Chỉ nhập thông tin đã biết. Có thể bổ sung nội dung và tài liệu sau."}/></>}
    <form ref={formRef} data-dirty={dirty ? "true" : undefined} className={`editor${presentation.compact ? " compact-editor" : ""}${embedded ? " embedded-editor" : ""}`} onSubmit={submit}>
      <section className="panel form-section"><h2>Thông tin nhận diện</h2><div className="form-grid">
        {!record && !context && <label className="field full">Loại hồ sơ<select value={form.kind} onChange={e => { const next = moduleMap[e.target.value]; setEditedFields(new Set(form.title.trim() ? ["title"] : [])); setForm({ kind: next.kind, title: form.title, status: startingStatus(next.kind), data: startingData(next.kind, context, overview.data) }); }}>{modules.filter(m => m.kind !== 'contact').map(m => <option key={m.kind} value={m.kind}>{m.label}</option>)}</select></label>}
        <label className="field full"><span>{({expert:"Họ tên chuyên gia",reference:"Tên thư mục hoặc tài liệu",collaboration:"Tên hoạt động",partner:"Tên đối tác",use_case:"Tên bài toán chuẩn",unit:"Tên đơn vị"} as Record<string,string>)[form.kind] || "Tên hồ sơ"} <span className="required" aria-hidden="true">*</span></span><input required autoFocus={!embedded} name="title" maxLength={250} value={form.title} onChange={e => update("title", e.target.value)} placeholder={`Nhập tên ${mod.singular}`}/></label>
        {presentation.showStatus && operationalStatuses.length > 0 && <label className="field">{({ partner: "Trạng thái hợp tác", collaboration: "Trạng thái", use_case: "Tình trạng danh mục" } as Record<string, string>)[form.kind] || "Tình trạng hoạt động"}<select value={form.status} onChange={e => update("status", e.target.value)}>{!visibleOperationalStatus(form.status) && <option value={form.status}>Chưa ghi nhận</option>}{operationalStatuses.map(s => <option key={s}>{s}</option>)}</select></label>}
        {presentation.showSummary && <label className="field full">{form.kind === 'partner' ? 'Giới thiệu ngắn' : 'Tóm tắt'}<textarea rows={presentation.compact ? 2 : 3} maxLength={10000} value={displayedText("summary", form.summary)} onChange={e => update("summary", e.target.value)}/>{form.kind === 'partner' && <small>Mô tả ngắn về đối tác; năng lực chi tiết ghi ở phần dưới.</small>}</label>}
      </div></section>
      {fieldGroups.map((group, index) => <Fragment key={group.label}><section className="panel form-section"><h2>{group.label}</h2><div className="form-grid">{group.fields.map(field => {
        const value = form.data?.[field.key] ?? "";
        const change = (value: string) => { markEdited(field.key); setForm(current => {
          const data = { ...current.data, [field.key]: value === "" ? null : field.type === "number" ? Number(value) : value };
          if (field.key === "item_group" && data.item_category && !ITEM_CATEGORIES[value]?.includes(String(data.item_category))) data.item_category = null;
          return { ...current, data };
        }); };
        if (field.key === "item_category") field = { ...field, options: ITEM_CATEGORIES[String(form.data?.item_group || "")] || [] };
        if (field.type === "tags") return <TagInput key={field.key} label={field.label} hint={field.hint} value={String(value)} suggestions={tagSuggestions(form.kind, field.key, field.suggestions, overview.data)} onChange={change}/>;
        return <label className={`field ${field.type === "textarea" ? "full" : ""}`} key={field.key}>{field.label}{field.type === "textarea" ? <textarea rows={presentation.compact ? 2 : 4} maxLength={10000} value={value} onChange={e => change(e.target.value)}/> : field.type === "select" ? <select value={value} onChange={e => change(e.target.value)}><option value="">Chưa ghi nhận</option>{value && field.options && !field.options.includes(String(value)) && <option value={String(value)}>{String(value)} (dữ liệu hiện có)</option>}{field.options?.map(option => <option key={option}>{option}</option>)}</select> : field.suggestions ? <><input list={`tag-${field.key}`} maxLength={1000} value={value} onChange={e => change(e.target.value)} placeholder="Chọn giá trị đã có hoặc nhập mới"/><datalist id={`tag-${field.key}`}>{tagSuggestions(form.kind, field.key, field.suggestions, overview.data).map(option => <option key={option} value={option}/>)}</datalist></> : <input type={field.type || "text"} min={field.type === "number" ? 0 : undefined} max={field.type === "number" ? 100000000 : undefined} step={field.type === "number" ? "any" : undefined} maxLength={1000} value={value} onChange={e => change(e.target.value)}/>} {field.hint && <small>{field.hint}</small>}</label>;
      })}</div></section>{index === 0 && <>{children}{createLinks.fields}</>}</Fragment>)}
      {!fieldGroups.length && <>{children}{createLinks.fields}</>}
      <div className="save-bar"><ErrorBox error={error}/><div className="actions">{savedRecord ? <button className="button primary" type="button" onClick={() => onSave(savedRecord)}>Mở hồ sơ đã lưu</button> : <><button className="button" type="button" disabled={busy} onClick={cancel}>Hủy</button><button className="button primary" disabled={busy}>{busy ? "Đang lưu…" : "Lưu hồ sơ"}</button></>}</div></div>
    </form></>;
}
