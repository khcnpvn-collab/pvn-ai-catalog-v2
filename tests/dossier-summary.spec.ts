import { test, expect } from '@playwright/test';
import type { CatalogRecord } from '../src/lib/catalog';
import { dossierPath, dossierSections, readTrail, type Dossier, type RelatedRecord } from '../src/lib/dossier';
import { resolveDossierTab, visibleRecordStatus } from '../src/lib/record-presentation';
import { partnerTimelineEntries, sectionEntries, summaryFacts, summaryNarrative, summaryRecordDescription, summarySectionEntries, summarySections, withDirectLinks } from '../src/lib/dossier-summary';
import { editorPresentation, visibleEditorDataKeys } from '../src/lib/editor-presentation';

// Synthetic inputs exercise presentation only; no API fixtures or production writes.
function record(id: string, kind = 'partner', data: CatalogRecord['data'] = {}): CatalogRecord {
  return { id, kind, title: `Example ${id}`, code: null, summary: null, status: 'Chưa xác minh', version: 1, data, created_at: '', updated_at: '', created_by: 'owner' };
}
function related(item: CatalogRecord, via: CatalogRecord | null = null, relation = 'related', direction: RelatedRecord['direction'] = 'incoming'): RelatedRecord {
  return { record: item, via, relation, direction };
}
function dossier(overrides: Partial<Dossier> = {}): Dossier {
  return { data: record('subject', 'expert'), links: [], history: [], related: [], documents: [], attachments: [], ...overrides };
}

test('summary groups count unique records and bound previews without mutating the projection', () => {
  const entries = [related(record('a', 'contact'), null, 'contact', 'outgoing'), related(record('a', 'contact'), record('via', 'engagement'), 'contact'), related(record('b', 'contact'), null, 'contact', 'outgoing'), related(record('c', 'contact'), null, 'contact', 'outgoing'), related(record('d', 'contact'), null, 'contact', 'outgoing'), related(record('coop', 'collaboration'), null, 'partner')];
  const before = structuredClone(entries);
  const groups = summarySections(dossierSections.partner, entries, 2);
  const contacts = groups.find(group => group.section.id === 'contacts')!;
  expect(contacts.count).toBe(4);
  expect(contacts.preview.map(entry => entry.record.id)).toEqual(['a', 'b']);
  expect(groups.find(group => group.section.id === 'collaborations')?.count).toBe(1);
  expect(entries).toEqual(before);
});

test('summary only projects the supplied readable records', () => {
  const permitted = record('private-contact', 'contact');
  const groups = summarySections(dossierSections.unit, [related(permitted)]);
  const allIds = groups.flatMap(group => group.preview.map(entry => entry.record.id));
  expect(allIds).toEqual(['private-contact']);
  expect(groups.find(group => group.section.id === 'contacts')?.count).toBe(1);
  expect(summarySections(dossierSections.unit, []).every(group => group.count === 0 && group.preview.length === 0)).toBe(true);
});

test('section preview limit zero retains real counts without exposing records', () => {
  const groups = summarySections(dossierSections.partner, [related(record('a', 'contact'), null, 'contact', 'outgoing')], 0);
  expect(groups.find(group => group.section.id === 'contacts')?.count).toBe(1);
  expect(groups.flatMap(group => group.preview)).toEqual([]);
});

test('partner sections filter direct relation direction', () => {
  const collaboration = record('coop', 'collaboration');
  const direct = related(collaboration, null, 'partner', 'incoming');
  const wrongDirection = related(record('wrong', 'collaboration'), null, 'partner', 'outgoing');
  const indirectPartner = related(record('other', 'partner'), collaboration, 'partner');
  const consortium = related(record('member', 'partner'), null, 'partner', 'outgoing');
  const model = [direct, wrongDirection, indirectPartner, consortium];
  const cooperation = sectionEntries(dossierSections.partner.find(section => section.id === 'collaborations')!, model);
  expect(cooperation.map(entry => entry.record.id)).toEqual(['coop']);
  const members = sectionEntries(dossierSections.partner.find(section => section.id === 'consortium')!, model);
  expect(members.map(entry => entry.record.id)).toEqual(['member']);
});

test('partner timeline uses business dates, falls back safely and deduplicates newest first', () => {
  const dated = { ...record('dated', 'engagement', { start_date: '2026-10-09' }), updated_at: '2026-10-09T02:00:00Z' };
  const legacy = { ...record('legacy', 'engagement', { end_date: '2026-09-01' }), updated_at: '2026-10-10T02:00:00Z' };
  const undated = { ...record('undated', 'engagement', { period_label: 'Quý IV/2026' }), updated_at: '2026-10-11T02:00:00Z' };
  expect(partnerTimelineEntries([related(legacy), related(undated), related(dated), related(dated)]).map(entry => entry.record.id)).toEqual(['dated', 'legacy', 'undated']);
});

test('partner overview keeps the complete readable group before choosing newest timeline entries', () => {
  const section = dossierSections.partner.find(item => item.id === 'engagements')!;
  const model = [
    related({ ...record('a', 'engagement', { start_date: '2026-01-01' }), title: 'A' }, null, 'partner'),
    related({ ...record('b', 'engagement', { start_date: '2026-02-01' }), title: 'B' }, null, 'partner'),
    related({ ...record('c', 'engagement', { start_date: '2026-03-01' }), title: 'C' }, null, 'partner'),
    related({ ...record('z-newest', 'engagement', { start_date: '2026-12-01' }), title: 'Z' }, null, 'partner'),
  ];
  const full = summarySectionEntries(section, model);
  expect(full).toHaveLength(4);
  expect(partnerTimelineEntries(full).slice(0, 3).map(entry => entry.record.id)).toEqual(['z-newest', 'c', 'b']);
  expect(summarySections([section], model, 3)[0].preview.map(entry => entry.record.id)).toEqual(['a', 'b', 'c']);
});

test('partner editor presets are contextual and preserve full forms outside the partner dossier', () => {
  expect(editorPresentation('partner').dataKeys).toEqual(['partner_type', 'strategic_level', 'country', 'website', 'specialties']);
  expect(visibleEditorDataKeys('contact', 'partner', ['position', 'email', 'expertise', 'role'])).toEqual(['role', 'position', 'email']);
  expect(editorPresentation('contact', 'unit').dataKeys).toBeNull();
  expect(editorPresentation('collaboration').dataKeys).toEqual(['item_group', 'item_category', 'declared_title', 'scope', 'lead', 'start_date', 'end_date', 'agreement', 'results', 'conclusion', 'next_notes']);
  expect(editorPresentation('partner').showStatus).toBe(true);
});

test('partner summary only exposes the basic identity fields in the requested order', () => {
  const item = record('partner', 'partner', { aliases: 'Tên cũ', origin: 'Nguồn khảo sát', website: 'https://example.test', country: 'Việt Nam', partner_type: 'Doanh nghiệp' });
  expect(summaryFacts(item, 10).map(({field}) => field.key)).toEqual(['partner_type', 'country', 'website']);
});

test('direct links replace an indirect duplicate without inflating counts or retaining a false via label', () => {
  const contact = record('contact', 'contact');
  const groups = summarySections(dossierSections.unit, [related(contact, record('meeting', 'engagement')), related(contact)]);
  const group = groups.find(group => group.section.id === 'contacts')!;
  expect(group.count).toBe(1);
  expect(group.preview[0].via).toBeNull();
});

test('metadata references never count as stored files or invent download versions', () => {
  const model = dossier({ related: [related(record('reference', 'reference', { external_url: 'https://example.test/cv.pdf' }))] });
  const sections = summarySections(dossierSections.engagement, model.related);
  expect(sections.find(group => group.section.id === 'references')?.count).toBe(1);
});

test('summary facts include only populated short facts and preserve numeric zero', () => {
  const item = record('use_case', 'use_case', { start_year: 0, objective: 'Narrative objective', category: 'a'.repeat(161), program: 'line one\nline two', leadership_level: null });
  const facts = summaryFacts(item, 10);
  expect(facts.find(fact => fact.field.key === 'start_year')?.value).toBe(0);
  expect(facts.some(fact => ['objective', 'category', 'program', 'leadership_level'].includes(fact.field.key))).toBe(false);
  expect(summaryFacts(item, 1)).toHaveLength(1);
  expect(summaryFacts(record('empty'))).toEqual([]);
});

test('summary narrative is readable and bounded without inventing content for empty dossiers', () => {
  const item = { ...record('summary'), summary: 'Thông tin có nguồn và nội dung rõ ràng. '.repeat(40) };
  const value = summaryNarrative(item);
  expect(value.length).toBeLessThanOrEqual(480);
  expect(value).toContain('Thông tin có nguồn');
  expect(value.endsWith('…')).toBe(true);
  expect(summaryNarrative(record('empty'))).toBe('');
});

test('collaboration summary presents its managed scope before imported provenance prose', () => {
  const collaboration = record('collaboration', 'collaboration', { scope: 'AI Chatbot' });
  collaboration.summary = 'Tình trạng nguyên gốc: Nghiên cứu đối tác\nTên đối tác nguyên gốc: FPT Digital';
  expect(summaryNarrative(collaboration)).toBe('AI Chatbot');
});

test('summary favors substantive labeled narrative and does not preview raw indexed survey matrices', () => {
  const item = { ...record('need', 'demand'), summary: 'Đơn vị: Example\nTrạng thái đơn vị khai báo: Đang nghiên cứu\nMô tả nhu cầu: Theo dõi thiết bị quay' };
  expect(summaryNarrative(item)).toBe('Theo dõi thiết bị quay');
  expect(summaryNarrative(record('unit', 'unit', { capabilities: '0: 0: Nội dung ô ma trận' }))).toBe('');
});

test('record previews expose useful domain context with bounded descriptions', () => {
  expect(summaryRecordDescription(record('expert', 'expert', { current_position: 'Advisor', academic_title: 'Professor', country: 'Việt Nam' }))).toBe('Advisor · Professor · Việt Nam');
  const description = summaryRecordDescription(record('contact', 'contact', { position: 'Nội dung chức danh '.repeat(30), email: 'example@example.test' }));
  expect(description.length).toBeLessThanOrEqual(180);
  expect(description.endsWith('…')).toBe(true);
});

test('reference attachment status derives from readable files rather than stale metadata', () => {
  const item = { ...record('reference', 'reference'), status: 'Chưa đính kèm' };
  expect(visibleRecordStatus(item)).toBeNull();
  expect(visibleRecordStatus(item, 1)).toBe('Có tệp đính kèm');
  expect(visibleRecordStatus(item, 0)).toBe('Chưa đính kèm');
  expect(visibleRecordStatus({ ...item, data: { external_url: 'https://example.test/cv' } }, 0)).toBe('Có liên kết tham khảo');
  expect(visibleRecordStatus({ ...item, status: 'Có tệp đính kèm', data: { external_url: 'javascript:alert(1)' } }, 0)).toBe('Chưa đính kèm');
  expect(visibleRecordStatus(record('partner'), 1)).toBeNull();
});

test('CV overview preserves old detail deep links and breadcrumb return sections', () => {
  const allowed = ['information', ...dossierSections.expert.map(section => section.id)];
  for (const section of ['overview', 'information', 'documents', 'organizations', 'activities']) expect(resolveDossierTab(section, allowed)).toBe(section);
  for (const removed of ['competencies', 'affiliations', 'training']) expect(resolveDossierTab(removed, allowed)).toBe('overview');
  expect(resolveDossierTab('references', allowed)).toBe('documents');
  for (const removed of ['links', 'history', 'survey']) expect(resolveDossierTab(removed, allowed)).toBe('overview');
  const trail = [{ id: 'expert-id', title: 'Hồ sơ chuyên gia', tab: 'affiliations' }];
  const path = dossierPath('organization-id', 'information', trail);
  const query = new URLSearchParams(path.split('?')[1]);
  expect(query.get('tab')).toBe('information');
  expect(readTrail(query.get('trail'))).toEqual(trail);
  expect(resolveDossierTab('survey', ['information', ...dossierSections.unit.map(section => section.id)], true)).toBe('survey');
});


test('internal codes stay out of every editor and summary facts', () => {
  for (const kind of ['unit', 'partner', 'expert', 'expertise', 'collaboration', 'contact', 'reference', 'use_case']) {
    expect(editorPresentation(kind).showCode).toBe(false);
    expect(visibleEditorDataKeys(kind, undefined, ['domain_code', 'internal_unit_code', 'country'])).not.toContain('domain_code');
    expect(visibleEditorDataKeys(kind, undefined, ['domain_code', 'internal_unit_code', 'country'])).not.toContain('internal_unit_code');
  }
  expect(summaryFacts(record('expertise', 'expertise', {domain_code: 'CM001'}))).toEqual([]);
});

test('a unit that is both PVN subject and executing party shows in both activity sections', () => {
  const activity = record('activity', 'collaboration');
  const unit = record('unit', 'unit');
  const link = (relation: string, context: Record<string, string> = {}) => ({ id: relation, source_id: activity.id, target_id: unit.id, relation, note: null, context, source: activity, target: unit });
  const model = withDirectLinks(dossier({ data: activity, links: [link('unit', { subject_role: 'lead' }), link('partner')], related: [related(unit, null, 'partner', 'outgoing')] }));
  const ids = (id: string) => sectionEntries(dossierSections.collaboration.find(section => section.id === id)!, model.related).map(entry => entry.record.id);
  expect(ids('organizations')).toEqual(['unit']);
  expect(ids('partner')).toEqual(['unit']);
  expect(withDirectLinks(model).related).toHaveLength(2);
});
