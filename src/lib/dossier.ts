import type { CatalogDocument, CatalogRecord, Relation } from './catalog';

export type RelatedRecord = { record: CatalogRecord; via: CatalogRecord | null; relation: string; direction: 'incoming' | 'outgoing' };
export type Dossier = { data: CatalogRecord; links: Relation[]; documents: CatalogDocument[]; history: Record<string, unknown>[]; related: RelatedRecord[]; attachments: { record: CatalogRecord; document: CatalogDocument }[] };
export type DossierContext = { parentId: string; parentTitle: string; parentKind?: string; relation: string; direction: 'to-parent' | 'from-parent'; context?: Record<string, string> };
export type DossierCrumb = { id: string; title: string; tab: string };
// context is stored on the new relation, e.g. the unit role of an activity created from a unit page.
export type SectionAction = { kind: string; relation: string; direction: DossierContext['direction']; label?: string; context?: Record<string, string> };
export type SectionSelector = 'contact-grid' | 'partner-contact' | 'partner-collaboration' | 'partner-engagement' | 'partner-consortium'
  | 'consortium-members' | 'activity-list' | 'activity-partner' | 'unit-roles' | 'standard-partners' | 'unit-standards' | 'unit-partners' | 'milestones' | 'direct-outgoing';
export type DossierSection = { id: string; label: string; description: string; kinds: string[]; actions: SectionAction[]; selector?: SectionSelector };
const to = (kind: string, relation: string): SectionAction => ({ kind, relation, direction: 'to-parent' });
const from = (kind: string, relation: string): SectionAction => ({ kind, relation, direction: 'from-parent' });
const section = (id: string, label: string, description: string, kinds: string[], actions: SectionAction[], selector?: DossierSection['selector']): DossierSection => ({ id, label, description, kinds, actions, selector });
const contacts = section('contacts', 'Đầu mối', 'Danh bạ và vai trò các đầu mối được kết nối với hồ sơ.', ['contact'], [from('contact', 'contact')], 'contact-grid');
const activityDescription = 'Bài toán đơn vị, POC, đề tài KHCN và nội dung hợp tác';
export const dossierSections: Record<string, DossierSection[]> = {
  unit: [
    section('activities', 'Triển khai & hợp tác', `${activityDescription} mà đơn vị làm đầu mối hoặc phối hợp.`, ['collaboration'], [{ ...to('collaboration', 'unit'), label: 'Thêm hoạt động', context: { subject_role: 'lead' } }], 'activity-list'),
    section('standards', 'Hạng mục', 'Bài toán chuẩn đơn vị là đầu mối ưu tiên hoặc có tiềm năng áp dụng, và các hạng mục áp dụng cho đơn vị.', ['use_case', 'work_item'], [{ ...to('use_case', 'unit'), label: 'Bài toán chuẩn', context: { subject_role: 'supporting' } }, { ...to('work_item', 'unit'), label: 'Hạng mục khác' }], 'unit-standards'),
    section('partners', 'Đối tác', 'Đối tác đã làm việc cùng đơn vị qua các hoạt động.', ['partner'], [], 'unit-partners'),
    section('engagements', 'Mốc & ghi chú', 'Các mốc làm việc và ghi chú với đơn vị.', ['engagement'], [{ ...to('engagement', 'unit'), label: 'Thêm mốc' }], 'milestones'),
    contacts,
  ],
  partner: [
    section('contacts', 'Đầu mối liên hệ', 'Thông tin người phụ trách để liên hệ nhanh, không mở thêm một hồ sơ trung gian.', ['contact'], [from('contact', 'contact')], 'partner-contact'),
    section('collaborations', 'Triển khai & hợp tác', 'Mọi hoạt động có đối tác tham gia, kể cả hoạt động ký qua liên danh.', ['collaboration'], [to('collaboration', 'partner')], 'partner-collaboration'),
    section('engagements', 'Mốc làm việc', 'Nhật ký làm việc chung hoặc gắn đồng thời với nhiều hoạt động. Mốc của liên danh ghi ở đối tác đầu mối.', ['engagement'], [to('engagement', 'partner')], 'partner-engagement'),
    section('standards', 'Bài toán chuẩn có thể đáp ứng', 'Gắn bài toán chuẩn mà đối tác có năng lực đáp ứng; đối tác sẽ hiện là đối tác tiềm năng của bài toán đó.', ['use_case'], [{ ...from('use_case', 'use_case'), label: 'Bài toán chuẩn' }], 'direct-outgoing'),
    section('consortium', 'Liên danh', 'Một liên danh gồm nhiều đối tác; một đối tác có thể tham gia nhiều liên danh.', ['partner'], [{ ...from('partner', 'partner'), label: 'Thêm thành viên' }, { ...to('partner', 'partner'), label: 'Tham gia liên danh' }], 'partner-consortium'),
  ],
  use_case: [
    section('activities', 'Triển khai & hợp tác', `${activityDescription} gắn với bài toán chuẩn này.`, ['collaboration'], [{ ...to('collaboration', 'use_case'), label: 'Thêm hoạt động' }], 'activity-list'),
    section('units', 'Đơn vị', 'Đầu mối ưu tiên triển khai, đơn vị tiềm năng áp dụng và đơn vị đang có hoạt động.', ['unit'], [{ ...from('unit', 'unit'), label: 'Đơn vị tiềm năng', context: { subject_role: 'supporting' } }], 'unit-roles'),
    section('partners', 'Đối tác tiềm năng', 'Đối tác có thể đáp ứng bài toán; đối tác đã làm nằm trong bảng hoạt động.', ['partner'], [{ ...to('partner', 'use_case'), label: 'Đối tác tiềm năng' }], 'standard-partners'),
  ],
  collaboration: [
    section('organizations', 'Chủ thể PVN', 'Một đơn vị hoặc Ban đầu mối và các đơn vị phối hợp.', ['unit'], [{ ...from('unit', 'unit'), label: 'Đơn vị', context: { subject_role: 'supporting' } }], 'unit-roles'),
    section('partner', 'Bên thực hiện', 'Một đối tác, một liên danh hoặc một đơn vị PVN thực hiện cho đơn vị đầu mối.', ['partner', 'unit'], [{ ...from('partner', 'partner'), label: 'Đối tác / liên danh' }, { ...from('unit', 'partner'), label: 'Đơn vị PVN' }], 'activity-partner'),
    section('contents', 'Hạng mục', 'Mỗi hoạt động gắn tối đa một hạng mục thuộc nhóm của hoạt động: bài toán chuẩn hoặc hạng mục nhóm khác.', ['use_case', 'work_item'], [from('use_case', 'use_case'), from('work_item', 'use_case')]),
    section('engagements', 'Mốc làm việc', 'Các mốc, kết quả và file được gắn với hoạt động này.', ['engagement'], [to('engagement', 'collaboration')], 'milestones'),
  ],
  engagement: [section('contacts', 'Thành phần & đầu mối', 'Các cá nhân tham gia và thông tin liên hệ.', ['contact'], [from('contact', 'participant')]),
    section('collaborations', 'Hoạt động', 'Các hoạt động đã gắn với mốc làm việc này.', ['collaboration'], []),
    section('organizations', 'Đơn vị & đối tác', 'Các bên tham gia đợt làm việc.', ['unit', 'partner'], [from('unit', 'unit'), from('partner', 'partner')]),
    section('standards', 'Bài toán chuẩn', 'Bài toán chuẩn được trao đổi trong mốc làm việc.', ['use_case'], [from('use_case', 'use_case')])],
};
// Supporting dossiers retain their business context when opened from a subject.
const organizations = section('organizations','Đơn vị & đối tác','Các đơn vị, đối tác gắn với hồ sơ.', ['unit','partner'],[from('unit','unit'),from('partner','partner')]);
dossierSections.work_item = [
  section('activities', 'Triển khai & hợp tác', 'Các hoạt động hợp tác gắn với hạng mục này.', ['collaboration'], [{ ...to('collaboration', 'use_case'), label: 'Thêm hoạt động' }], 'activity-list'),
  section('units', 'Đơn vị áp dụng', 'Các đơn vị cụ thể được ưu tiên áp dụng hạng mục.', ['unit'], [{ ...from('unit', 'unit'), label: 'Đơn vị áp dụng' }], 'direct-outgoing'),
];
dossierSections.contact = [organizations, section('engagements','Đợt làm việc','Các đợt làm việc có sự tham gia của đầu mối.', ['engagement'],[to('engagement','participant')])];
const experts = section('experts', 'Chuyên gia', 'Các chuyên gia tham gia hoặc được kết nối với hồ sơ.', ['expert'], [from('expert', 'expert')]);
const references = section('references', 'Tài liệu tham khảo', 'Thông tin và liên kết tham khảo. Tệp đã tải lên nằm riêng tại phần Tài liệu.', ['reference'], [to('reference', 'related')]);
dossierSections.expert = [
  section('organizations', 'Nơi công tác', 'Đơn vị hoặc đối tác chuyên gia đang làm việc.', ['unit', 'partner'], [{ ...from('unit', 'unit'), label: 'Đơn vị' }, { ...from('partner', 'partner'), label: 'Đối tác' }]),
  section('activities', 'Triển khai & hợp tác', 'Hoạt động có chuyên gia tham gia: giảng dạy, hội thảo, tư vấn…', ['collaboration'], [{ ...to('collaboration', 'expert'), label: 'Thêm hoạt động' }], 'activity-list'),
];
dossierSections.reference = [section('subjects', 'Hồ sơ liên quan', 'Hồ sơ sử dụng hoặc liên quan đến tài liệu tham khảo này.', ['expert', 'unit', 'partner', 'collaboration', 'use_case', 'engagement'], [from('expert', 'expert'), ...['unit', 'partner', 'use_case', 'engagement'].map(kind => from(kind, 'related'))])];
dossierSections.engagement.push(experts, references);

export function readTrail(value: string | null): DossierCrumb[] {
  try { const parsed: unknown = JSON.parse(value || '[]'); return Array.isArray(parsed) ? parsed.filter((v): v is DossierCrumb => Boolean(v && typeof v === 'object' && typeof v.id === 'string' && typeof v.title === 'string' && typeof v.tab === 'string')).slice(-12) : []; } catch { return []; }
}
export function dossierPath(id: string, tab = 'overview', trail: DossierCrumb[] = []) {
  const params = new URLSearchParams({ tab });
  if (trail.length) params.set('trail', JSON.stringify(trail));
  return `record/${id}?${params}`;
}

// A consortium (partner of type "Liên danh") is a light group: its members and the activities signed through it.
export const consortiumSections: DossierSection[] = [
  section('members', 'Thành viên', 'Các đối tác trong liên danh; một đối tác làm đầu mối.', ['partner'], [from('partner', 'partner')], 'consortium-members'),
  section('collaborations', 'Triển khai & hợp tác', 'Các hoạt động ký qua liên danh.', ['collaboration'], [to('collaboration', 'partner')], 'partner-collaboration'),
];
