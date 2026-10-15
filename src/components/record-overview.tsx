"use client";
import type { CatalogRecord, Field } from '@/lib/catalog';
import { groupFields, moduleMap } from '@/lib/catalog';
import { cleanGeneratedRecordText, isInternalCodeField, isGeneratedRecordCode, parseDataDetails, parseNarrative } from '@/lib/record-presentation';
import { date } from './ui';

function Paragraphs({ text }: { text: string }) {
  return <>{text.split(/\n\s*\n/).filter(part => part.trim()).map((part, index) => <p className="preserve-lines" key={index}>{part}</p>)}</>;
}

function NarrativeValue({ text }: { text: string }) {
  const details = parseDataDetails(text);
  if (!details.some(block => block.label)) return <Paragraphs text={text}/>;
  return <div className="narrative-data-details">{details.map((block, index) => block.label
    ? <div key={index}><h4>{block.label}</h4><Paragraphs text={block.text}/></div>
    : <Paragraphs key={index} text={block.text}/>)}</div>;
}

export function NarrativeContent({ text }: { text: string }) {
  const blocks = parseNarrative(text);
  return <div className="narrative-content">{blocks.map((block, index) => <div className={block.label ? 'narrative-block has-label' : 'narrative-block'} key={index}>
    {block.label && <h3>{block.label}</h3>}<div className="narrative-value"><NarrativeValue text={block.text}/></div>
  </div>)}</div>;
}

function FactValue({ field, value }: { field: Field; value: string | number }) {
  const text = String(value);
  if (field.type === 'url' && /^https?:\/\//i.test(text)) return <a href={text} target="_blank" rel="noreferrer">{text}</a>;
  if (field.type === 'email' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text)) return <a href={`mailto:${text}`}>{text}</a>;
  if (!text.trim()) return null;
  return <>{field.type === 'date' ? date(text) : text}</>;
}

function NarrativeFieldValue({ kind, value, onSurvey }: { kind: string; value: string | number; onSurvey?: () => void }) {
  if (kind === 'unit' && /(?:^|\s)\d+:\s*\d+:/.test(String(value))) return <><p className="muted">Nội dung có các bảng trả lời trong phiếu khảo sát.</p>{onSurvey && <button className="text-button" onClick={onSurvey}>Xem bảng kết quả khảo sát</button>}<details className="source-narrative-details"><summary>Xem nội dung đã ghi nhận</summary><NarrativeContent text={String(value)}/></details></>;
  return <NarrativeContent text={String(value)}/>;
}

export default function RecordOverview({ record, onSurvey }: { record: CatalogRecord; onSurvey?: () => void }) {
  const mod = moduleMap[record.kind];
  const partnerKeys = new Set(['partner_type', 'strategic_level', 'country', 'website', 'specialties']);
  const generated = isGeneratedRecordCode(record.code);
  const summary = cleanGeneratedRecordText(record.summary, generated);
  const visibleFields = mod.fields.filter(field => !field.hidden && !isInternalCodeField(field.key) && (record.kind !== 'partner' || partnerKeys.has(field.key)));
  // Every field keeps its place; one not recorded yet simply shows an empty value.
  const fields = visibleFields.map(field => ({ field, value: record.data[field.key] ?? '' }));
  const filled = (value: string | number) => String(value).trim() !== '';
  const present = fields.filter(item => filled(item.value));
  const isNarrative = ({field, value}: {field: Field; value: string | number}) => filled(value) && (field.type === 'textarea' || String(value).length > 220 || String(value).includes('\n'));
  const facts = fields.filter(item => !isNarrative(item));
  const narratives = fields.filter(isNarrative);
  const hasGroups = visibleFields.some(field => field.group);
  const grouped = hasGroups ? groupFields(visibleFields, 'Thông tin khác').map(group => ({ label: group.label, values: fields.filter(item => group.fields.some(field => field.key === item.field.key)) })) : [];
  const summaryBlocks = parseNarrative(summary);
  const shortSummary = summary && summary.length <= 320 && !summaryBlocks.some(block => block.label);
  return <div className="record-overview">
    {shortSummary && <section className="dossier-intro"><h2>Tóm tắt</h2><Paragraphs text={summary}/></section>}
    {!hasGroups && facts.length > 0 && <section className="record-facts-section"><h2>Thông tin chính</h2><dl className="record-facts">{facts.map(({field, value}) => <div key={field.key}><dt>{field.label}</dt><dd><FactValue field={field} value={value}/></dd></div>)}</dl></section>}
    {summary && !shortSummary && <section className="record-narrative-section"><h2>Nội dung tổng hợp</h2><NarrativeContent text={summary}/></section>}
    {grouped.map(group => <section className="record-field-group" key={group.label}><h2>{group.label}</h2>
      {group.values.some(item => !isNarrative(item)) && <dl className="record-facts">{group.values.filter(item => !isNarrative(item)).map(({field, value}) => <div key={field.key}><dt>{field.label}</dt><dd><FactValue field={field} value={value}/></dd></div>)}</dl>}
      {group.values.filter(isNarrative).map(({field, value}) => <div className="record-group-narrative" key={field.key}><h3>{field.label}</h3><NarrativeFieldValue kind={record.kind} value={value} onSurvey={onSurvey}/></div>)}
    </section>)}
    {!hasGroups && narratives.map(({field, value}) => <section className="record-narrative-section" key={field.key}><h2>{field.label}</h2><NarrativeFieldValue kind={record.kind} value={value} onSurvey={onSurvey}/></section>)}
    {!summary && !present.length && <p className="muted">Chưa bổ sung nội dung chi tiết cho hồ sơ này.</p>}
    <p className="record-updated">Cập nhật lần cuối {date(record.updated_at)} · tạo ngày {date(record.created_at)}</p>
  </div>;
}
