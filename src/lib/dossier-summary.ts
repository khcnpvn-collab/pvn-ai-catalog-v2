import { moduleMap, type CatalogRecord, type Field, type Relation } from './catalog';
import type { Dossier, DossierSection, RelatedRecord } from './dossier';
import { cleanGeneratedRecordText, isInternalCodeField, isGeneratedRecordCode, parseNarrative, recordExcerpt } from './record-presentation';

function clean(record: CatalogRecord, value: string | number | null | undefined) {
  return cleanGeneratedRecordText(value == null ? '' : String(value), isGeneratedRecordCode(record.code));
}

export function summaryFacts(record: CatalogRecord, limit = 6): { field: Field; value: string | number }[] {
  const fields = moduleMap[record.kind]?.fields || [];
  const visibleFields = record.kind === 'partner'
    ? ['partner_type', 'country', 'website'].flatMap(key => fields.find(field => field.key === key) || [])
    : fields.filter(field => !field.hidden);
  return visibleFields.filter(field => !isInternalCodeField(field.key)).flatMap(field => {
    const value = clean(record, record.data[field.key]);
    return field.type !== 'textarea' && value.trim() && value.length <= 160 && !value.includes('\n')
      ? [{ field, value: field.type === 'number' ? record.data[field.key] as number | string : value }] : [];
  }).slice(0, Math.max(0, limit));
}

export function summaryNarrative(record: CatalogRecord): string {
  // Unit summaries written by the survey import only restate that a questionnaire was received.
  if (record.kind === 'unit' && /phiếu khảo sát/i.test(record.summary || '')) return '';
  if (record.kind === 'use_case' && clean(record, record.data.objective).trim()) return recordExcerpt(clean(record, record.data.objective), 480);
  if (record.kind === 'collaboration') {
    const scope = clean(record, record.data.scope);
    if (scope.trim()) return recordExcerpt(scope, 480);
  }
  const blocks = parseNarrative(clean(record, record.summary));
  const preferred = blocks.find(block => ['Mô tả', 'Mô tả nhu cầu', 'Phạm vi'].includes(block.label || ''));
  const summary = preferred?.text || blocks.filter(block => !block.label).map(block => block.text).join(' ') || blocks.map(block => `${block.label}: ${block.text}`).join(' ');
  const fallback = (moduleMap[record.kind]?.fields || []).filter(field => field.type === 'textarea').map(field => clean(record, record.data[field.key])).find(value => value.trim() && !/(?:^|\s)\d+:\s*\d+:/.test(value));
  return recordExcerpt(summary || fallback || '', 480);
}

export function summarySections(sections: DossierSection[], related: RelatedRecord[], limit = 3) {
  return sections.map(section => {
    const entries = summarySectionEntries(section, related);
    return { section, count: entries.length, preview: entries.slice(0, Math.max(0, limit)) };
  });
}

export function directRelationContext(ownerId: string, entry: RelatedRecord, links: Relation[]): Record<string, string> {
  const sourceId = entry.direction === 'outgoing' ? ownerId : entry.record.id;
  const targetId = entry.direction === 'outgoing' ? entry.record.id : ownerId;
  return links.find(link => link.source_id === sourceId && link.target_id === targetId && link.relation === entry.relation)?.context || {};
}

export function summarySectionEntries(section: DossierSection, related: RelatedRecord[]): RelatedRecord[] {
  const unique = new Map<string, RelatedRecord>();
  for (const entry of sectionEntries(section, related)) {
    if (!unique.has(entry.record.id) || (unique.get(entry.record.id)?.via && !entry.via)) unique.set(entry.record.id, entry);
  }
  return [...unique.values()];
}

export function sectionEntries(section: DossierSection, related: RelatedRecord[]): RelatedRecord[] {
  const byKind = related.filter(entry => section.kinds.includes(entry.record.kind));
  if (section.selector === 'partner-contact') return byKind.filter(entry => !entry.via && entry.relation === 'contact' && entry.direction === 'outgoing');
  // Activities signed by a consortium the partner belongs to arrive through that consortium.
  if (section.selector === 'partner-collaboration') return byKind.filter(entry => entry.relation === 'partner' && (entry.via ? entry.via.kind === 'partner' : entry.direction === 'incoming'));
  if (section.selector === 'partner-engagement') return byKind.filter(entry =>
    (!entry.via && entry.relation === 'partner' && entry.direction === 'incoming') || entry.via?.kind === 'collaboration');
  if (section.selector === 'partner-consortium') return byKind.filter(entry => !entry.via && entry.relation === 'partner');
  if (section.selector === 'consortium-members') return byKind.filter(entry => !entry.via && entry.relation === 'partner' && entry.direction === 'outgoing');
  // Units and partners reached through an activity already show in the activity table, so role lists keep direct links only.
  // A unit carrying out an activity is its executing party, not one of its PVN subjects.
  if (section.selector === 'unit-roles') return byKind.filter(entry => !entry.via && entry.relation === 'unit');
  if (['activity-list', 'milestones', 'standard-partners', 'unit-standards'].includes(section.selector || '')) return byKind.filter(entry => !entry.via);
  if (section.selector === 'activity-partner') return byKind.filter(entry => !entry.via && entry.relation === 'partner' && entry.direction === 'outgoing');
  if (section.selector === 'direct-outgoing') return byKind.filter(entry => !entry.via && entry.direction === 'outgoing');
  if (section.selector === 'unit-partners') return byKind.filter(entry => entry.via?.kind === 'collaboration');
  return byKind;
}

export function partnerTimelineEntries(entries: RelatedRecord[]): RelatedRecord[] {
  const key = (entry: RelatedRecord) => String(entry.record.data.start_date || entry.record.data.end_date || '');
  return [...new Map(entries.map(entry => [entry.record.id, entry])).values()].sort((a, b) =>
    key(b).localeCompare(key(a)) || b.record.updated_at.localeCompare(a.record.updated_at) || b.record.id.localeCompare(a.record.id));
}

export function summaryRecordDescription(record: CatalogRecord): string {
  const keys: Record<string, string[]> = {
    unit: ['sector'], contact: ['position', 'email', 'phone'], expert: ['current_position', 'academic_title', 'country'],
    reference: ['reference_type', 'date_note', 'edition'], engagement: ['start_date', 'location', 'conclusions'],
  };
  const value = (keys[record.kind] || []).map(key => clean(record, record.data[key])).filter(Boolean).join(' · ');
  return recordExcerpt(value || summaryNarrative(record), 180);
}

// The dossier lists each related record once, yet one record can be linked twice (a unit that is both a PVN
// subject and the executing party). Every direct link gets its own entry so each section finds its link.
export function withDirectLinks(dossier: Dossier): Dossier {
  const id = dossier.data.id;
  const seen = new Set(dossier.related.filter(entry => !entry.via).map(entry => `${entry.record.id}|${entry.relation}|${entry.direction}`));
  const extra: RelatedRecord[] = [];
  for (const link of dossier.links) {
    const outgoing = link.source_id === id;
    const other = outgoing ? link.target : link.target_id === id ? link.source : undefined;
    if (!other) continue;
    const direction = outgoing ? 'outgoing' : 'incoming';
    const key = `${other.id}|${link.relation}|${direction}`;
    if (seen.has(key)) continue;
    seen.add(key);
    extra.push({ record: other, via: null, relation: link.relation, direction });
  }
  return extra.length ? { ...dossier, related: [...dossier.related, ...extra] } : dossier;
}
