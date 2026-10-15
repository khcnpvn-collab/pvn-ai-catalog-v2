import { test, expect } from '@playwright/test';
import { modules, validateRecord, type CatalogRecord, type Membership } from '../src/lib/catalog';
import { dossierPath, readTrail, type Dossier, type RelatedRecord } from '../src/lib/dossier';
import { resolveDossierTab } from '../src/lib/record-presentation';
import { canWriteRecord, dossierAttachmentOwners, dossierFolders, folderCreateInput, folderRenameInput, isPrimaryDossier } from '../src/lib/record-files';

function record(kind = 'reference', id = '00000000-0000-4000-8000-000000000001'): CatalogRecord {
  return { id, kind, title: 'Existing folder', code: 'BUSINESS-CODE', summary: 'Preserve summary', status: 'Chưa đính kèm', version: 4, data: { reference_type: 'Thư mục', notes: 'Preserve notes' }, created_at: '', updated_at: '', created_by: 'owner' };
}
function membership(role: Membership['role'], user_id = 'other'): Membership { return { role, user_id, display_name: null }; }
function dossier(related: RelatedRecord[]): Dossier { return { data: record('expert'), documents: [], attachments: [], related, links: [], history: [] }; }
function entry(item: CatalogRecord, via: CatalogRecord | null = null): RelatedRecord { return { record: item, via, relation: 'related', direction: 'incoming' }; }

test('main entities and collaboration retain a CV while supporting records open full details', () => {
  expect(modules.filter(module => isPrimaryDossier(module.kind)).map(module => module.kind).sort()).toEqual(['collaboration', 'expert', 'partner', 'unit', 'use_case', 'work_item']);
  for (const kind of ['reference', 'engagement', 'affiliation', 'expertise', 'contact', 'unknown']) expect(isPrimaryDossier(kind)).toBe(false);
});

test('write affordances respect role ownership privacy and archive state of the actual target record', () => {
  expect(canWriteRecord(membership('reader', 'owner'))).toBe(false);
  expect(canWriteRecord(membership('editor'))).toBe(true);
  expect(canWriteRecord(membership('admin'))).toBe(true);
});

test('folder references deduplicate IDs prefer direct paths and retain both URL and non-URL metadata', () => {
  const folder = record();
  const reference = { ...record('reference', '00000000-0000-4000-8000-000000000002'), data: { reference_type: 'CV', external_url: 'https://example.test/cv' } };
  const source = dossier([entry(folder, record('engagement')), entry(reference), entry(folder), entry(record('partner'))]);
  const before = structuredClone(source);
  const folders = dossierFolders(source);
  expect(folders.map(item => item.record.id)).toEqual([folder.id, reference.id]);
  expect(folders[0].via).toBeNull();
  expect(folders[1].record.data.external_url).toBe('https://example.test/cv');
  expect(source).toEqual(before);
});

test('partner file area exposes every direct cooperation content as a logical folder', () => {
  const content = { ...record('collaboration', '00000000-0000-4000-8000-000000000003'), title: 'Digital Worker', status: 'Đang thực hiện', data: { item_group: 'Bài toán' } };
  const source: Dossier = { ...dossier([entry(content), entry(content, record('engagement'))]), data: { ...record('partner'), status: 'Chưa xác minh', data: {} } };
  const folders = dossierFolders(source);
  expect(folders.map(item => item.record.id)).toEqual([content.id]);
  expect(folders[0].via).toBeNull();
});

test('cooperation folders do not repeat in the related attachment owner list', () => {
  const content = { ...record('collaboration', '00000000-0000-4000-8000-000000000003'), title: 'Digital Worker' };
  const milestone = { ...record('engagement', '00000000-0000-4000-8000-000000000004'), title: 'Phiên làm việc' };
  const document = { id: '00000000-0000-4000-8000-000000000005', title: 'Biên bản' as const, created_by: 'owner', created_at: '', versions: [] };
  const source: Dossier = {
    ...dossier([entry(content)]),
    data: { ...record('partner'), data: {} },
    attachments: [{ record: content, document }, { record: milestone, document }],
  };
  const folders = dossierFolders(source);
  expect(dossierAttachmentOwners(source, folders).map(item => item.id)).toEqual([milestone.id]);
});

test('folder creation trims its name without copying unrelated data', () => {
  const parent = record('expert');
  const input = folderCreateInput(parent, '  Biên bản họp  ');
  expect(input).toMatchObject({ kind: 'reference', title: 'Biên bản họp', status: 'Chưa đính kèm', data: { reference_type: 'Thư mục' } });
  expect(input).not.toHaveProperty('id');
  expect(input).not.toHaveProperty('version');
  expect(input.data).not.toHaveProperty('notes');
  expect(validateRecord(input)).toBeNull();
  expect(() => folderCreateInput(record('reference'), 'Nested')).toThrow('một cấp');
  expect(() => folderRenameInput(record('partner'), 'Wrong kind')).toThrow();
});

test('folder names enforce empty and maximum lengths at creation and rename boundaries', () => {
  for (const name of ['', '   ', 'x'.repeat(251)]) {
    expect(() => folderCreateInput(record('unit'), name)).toThrow();
    expect(() => folderRenameInput(record(), name)).toThrow();
  }
  expect(folderCreateInput(record('unit'), 'x'.repeat(250)).title).toHaveLength(250);
  expect(folderRenameInput(record(), ' x ').title).toBe('x');
});

test('rename preserves source metadata and optimistic version rather than replacing a reference with an empty folder', () => {
  const folder = { ...record(), data: { reference_type: 'CV', external_url: 'https://example.test/cv.pdf', document_date: '2026-09-01', notes: 'Original notes' } };
  const before = structuredClone(folder);
  const input = folderRenameInput(folder, 'Renamed');
  expect(input).toMatchObject({ id: folder.id, kind: folder.kind, version: 4, title: 'Renamed', code: folder.code, summary: folder.summary, status: folder.status, data: folder.data });
  expect(validateRecord(input)).toBeNull();
  expect(folder).toEqual(before);
});

test('legacy reference links resolve to unified documents without losing breadcrumb return state', () => {
  expect(resolveDossierTab('references', ['information', 'references'])).toBe('documents');
  expect(resolveDossierTab('references', ['information'])).toBe('documents');
  expect(resolveDossierTab('documents', [])).toBe('documents');
  expect(resolveDossierTab('information', ['information'])).toBe('information');
  const trail = [{ id: 'owner', title: 'Hồ sơ gốc', tab: 'references' }];
  const path = dossierPath('reference', 'documents', trail);
  const query = new URLSearchParams(path.split('?')[1]);
  expect(readTrail(query.get('trail'))).toEqual(trail);
  for (const removed of ['history', 'links']) expect(resolveDossierTab(removed, ['information'])).toBe('overview');
});
