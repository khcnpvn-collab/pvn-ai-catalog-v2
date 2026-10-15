import { test, expect } from '@playwright/test';
import { cleanGeneratedRecordText, isGeneratedRecordCode, parseDataDetails, parseNarrative, recordExcerpt, resolveDossierTab, visibleOperationalStatus, visibleRecordStatus } from '../src/lib/record-presentation';
import { dossierSections } from '../src/lib/dossier';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

test('verification status presentation is hidden without hiding operational states', () => {
  for (const status of ['Chưa xác minh', 'Đã xác minh', 'Cần xác minh', 'Cần bổ sung', 'Chờ đối soát', 'Đã đối soát', '  CHƯA XÁC MINH  ', 'Chưa xác minh'.normalize('NFD'), '', null, undefined]) expect(visibleOperationalStatus(status)).toBeNull();
  for (const status of ['Đang hoạt động', 'Đang triển khai', 'Đã diễn ra', 'Hoãn', 'POC', 'Chưa xác định', 'Đang dự thảo']) expect(visibleOperationalStatus(status)).toBe(status);
});

test('reference lists cannot present stored attachment states without actual readable file counts', () => {
  for (const status of ['Chưa đính kèm', 'Liên kết tham khảo', 'Có tệp đính kèm', 'Đã xác minh']) {
    expect(visibleRecordStatus({ kind: 'reference', status, data: { external_url: 'https://example.test/cv.pdf' } })).toBeNull();
  }
  expect(visibleRecordStatus({ kind: 'reference', status: 'Chưa đính kèm', data: {} }, 2)).toBe('Có tệp đính kèm');
  expect(visibleRecordStatus({ kind: 'reference', status: 'Chưa đính kèm', data: { external_url: 'HTTPS://example.test/cv.pdf' } }, 0)).toBe('Có liên kết tham khảo');
  expect(visibleRecordStatus({ kind: 'reference', status: 'Có tệp đính kèm', data: {} }, 0)).toBe('Chưa đính kèm');
  expect(visibleRecordStatus({ kind: 'collaboration', status: 'Đang thực hiện', data: {} })).toBe('Đang thực hiện');
});

test('generated record codes are recognized narrowly without hiding human business codes', () => {
  expect(isGeneratedRecordCode('KS-USE_CASE-abcdef123456abcdef123456')).toBe(true);
  for (const code of ['PVN-2026', 'KS-UNIT', 'KS-UNIT-123', '', null, undefined]) expect(isGeneratedRecordCode(code)).toBe(false);
});

test('only generated importer prose is cleaned while original text remains intact', () => {
  const generated = 'Thông tin do đơn vị khai báo, chưa xác minh độc lập.';
  expect(cleanGeneratedRecordText(generated)).toBe(generated);
  expect(cleanGeneratedRecordText(generated, true)).toBe('Thông tin do đơn vị khai báo.');
  const original = 'Đơn vị chưa xác minh dữ liệu cảm biến.\nCần bổ sung thiết bị và nhân sự.\nTình trạng dự án: đang triển khai.';
  expect(cleanGeneratedRecordText(original, true)).toBe(original);
  expect(cleanGeneratedRecordText(null, true)).toBe('');
});

test('known narrative labels become sections and preserve multiline unknown prose', () => {
  const input = 'Nội dung mở đầu\nMô tả: Theo dõi thiết bị\nDòng hai: nguyên văn\nDữ liệu đầu vào: Cảm biến\nhttps://example.org:443/data';
  expect(parseNarrative(input)).toEqual([
    { label: null, text: 'Nội dung mở đầu' },
    { label: 'Mô tả', text: 'Theo dõi thiết bị\nDòng hai: nguyên văn' },
    { label: 'Dữ liệu đầu vào', text: 'Cảm biến\nhttps://example.org:443/data' },
  ]);
  expect(parseNarrative('   ')).toEqual([]);
  expect(parseNarrative('Nhãn chưa biết: Nội dung')).toEqual([{ label: null, text: 'Nhãn chưa biết: Nội dung' }]);
});

test('data narrative field names gain readable labels without dropping unfamiliar lines', () => {
  expect(parseDataDetails('nhomdulieu: Cảm biến\nhethongnguon: SCADA\nlegacy_key: giữ nguyên')).toEqual([
    { label: 'Nhóm dữ liệu', text: 'Cảm biến' },
    { label: 'Hệ thống nguồn', text: 'SCADA\nlegacy_key: giữ nguyên' },
  ]);
});

test('hidden old dossier tabs fall back to overview and permitted sections remain addressable', () => {
  const unitSections = dossierSections.unit.map(section => section.id);
  expect(unitSections).not.toContain('hierarchy');
  for (const oldTab of ['history', 'links', 'hierarchy', 'unknown', 'survey']) expect(resolveDossierTab(oldTab, unitSections)).toBe('overview');
  expect(resolveDossierTab('survey', unitSections, true)).toBe('survey');
  for (const tab of ['overview', 'documents', ...unitSections]) expect(resolveDossierTab(tab, unitSections)).toBe(tab === 'references' ? 'documents' : tab);
  expect(resolveDossierTab('history', ['history'], true)).toBe('overview');
  expect(resolveDossierTab('hierarchy', dossierSections.use_case.map(section => section.id))).toBe('overview');
  expect(resolveDossierTab('activities', dossierSections.use_case.map(section => section.id))).toBe('activities');
});

test('partner dossier exposes one-level cooperation content, adding members and joining consortia', () => {
  expect(dossierSections.partner.map(section => section.id)).toEqual(['contacts', 'collaborations', 'engagements', 'standards', 'consortium']);
  const collaboration = dossierSections.partner.find(section => section.id === 'collaborations')!;
  expect(collaboration.selector).toBe('partner-collaboration');
  expect(collaboration.actions).toEqual([{ kind: 'collaboration', relation: 'partner', direction: 'to-parent' }]);
  const consortium = dossierSections.partner.find(section => section.id === 'consortium')!;
  expect(consortium.actions.map(action => action.direction)).toEqual(['from-parent', 'to-parent']);
  expect(consortium.actions.every(action => action.kind === 'partner')).toBe(true);
  expect(collaboration.label).toBe('Triển khai & hợp tác');
  expect(dossierSections.partner.find(section => section.id === 'standards')!.actions).toEqual([{ kind: 'use_case', relation: 'use_case', direction: 'from-parent', label: 'Bài toán chuẩn' }]);
});

test('summary exposes full sections directly without an extra edit layer', () => {
  const source = readFileSync(join(process.cwd(), 'src/components/record-summary.tsx'), 'utf8');
  expect(source).not.toContain('Các mục khác');
  expect(source).toContain('groups.map');
  expect(source).toContain('<DossierSection section={section}');
  expect(source).not.toContain('editingSection');
  expect(dossierSections.unit.find(section => section.id === 'contacts')?.selector).toBe('contact-grid');
});

test('an activity links PVN subjects, one partner, one item and milestones', () => {
  expect(dossierSections.collaboration.map(section => section.id)).toEqual(['organizations', 'partner', 'contents', 'engagements']);
  expect(dossierSections.collaboration.find(section => section.id === 'organizations')!.actions).toEqual([
    { kind: 'unit', relation: 'unit', direction: 'from-parent', label: 'Đơn vị', context: { subject_role: 'supporting' } },
  ]);
  expect(dossierSections.collaboration.find(section => section.id === 'partner')!.selector).toBe('activity-partner');
  expect(dossierSections.collaboration.find(section => section.id === 'contents')!.actions).toEqual([
    { kind: 'use_case', relation: 'use_case', direction: 'from-parent' },
    { kind: 'work_item', relation: 'use_case', direction: 'from-parent' },
  ]);
  expect(dossierSections.collaboration.find(section => section.id === 'engagements')!.actions).toEqual([
    { kind: 'engagement', relation: 'collaboration', direction: 'to-parent' },
  ]);
  expect(dossierSections.engagement.find(section => section.id === 'collaborations')!.actions).toEqual([]);
  expect(dossierSections.use_case.map(section => section.id)).toEqual(['activities', 'units', 'partners']);
  expect(dossierSections.use_case.find(section => section.id === 'units')!.selector).toBe('unit-roles');
});

test('record excerpt stays readable and bounded while leaving short content intact', () => {
  expect(recordExcerpt('  Dòng một\nDòng hai  ')).toBe('Dòng một Dòng hai');
  const excerpt = recordExcerpt('Nội dung chi tiết '.repeat(30), 80);
  expect(excerpt.length).toBeLessThanOrEqual(80);
  expect(excerpt.endsWith('…')).toBe(true);
  expect(recordExcerpt('')).toBe('');
});
