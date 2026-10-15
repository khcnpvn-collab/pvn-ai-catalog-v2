import { ACTIVE_ACTIVITY_STATUSES } from './catalog';

// Compact projection returned by ai_catalog_overview(); one request powers every tab dashboard.
type Base = { id: string; title: string; updated_at: string };
export type OverviewStandard = Base & { code: string | null; status: string; program: string | null; category: string | null; is_priority: string | null; leadership_level: string | null; start_year: number | null; lead_unit_id: string | null; potential_unit_ids: string[]; potential_partner_ids: string[] };
export type OverviewWorkItem = Base & { code: string | null; status: string; item_group: string; scope_level: string | null; apply_scope: string | null; owner: string | null; coordinator: string | null; start_date: string | null; unit_ids: string[] };
export type OverviewActivity = Base & { status: string; item_group: string | null; item_category: string | null; start_date: string | null; end_date: string | null; partner_id: string | null; provider_unit_id: string | null; party_lead_id: string | null; standard_id: string | null; work_item_id: string | null; lead_unit_id: string | null; unit_ids: string[]; expert_ids?: string[] };
export type OverviewPartner = Base & { status: string; short_name: string | null; partner_type: string | null; country: string | null; strategic_level?: string | null; specialties?: string | null; contact_name?: string | null; contact_count?: number; member_ids: string[]; lead_member_id?: string | null };
export type OverviewUnit = Base & { abbreviation: string | null; sector: string | null; unit_type?: string | null; status?: string; parent_id: string | null };
export type OverviewMilestone = Base & { status: string; start_date: string | null; end_date: string | null; period_label: string | null; partner_ids: string[]; unit_ids: string[]; activity_ids: string[] };
export type OverviewExpert = Base & { status: string; organization: string | null; current_position: string | null; expertise_summary?: string | null; unit_ids: string[]; partner_ids: string[] };
export type Overview = { standards: OverviewStandard[]; work_items: OverviewWorkItem[]; activities: OverviewActivity[]; partners: OverviewPartner[]; units: OverviewUnit[]; milestones: OverviewMilestone[]; experts: OverviewExpert[] };

export const UNCLASSIFIED = 'Chưa phân loại';
export type Count = { label: string; value: number };

export function byId<T extends { id: string }>(items: T[]): Map<string, T> {
  return new Map(items.map(item => [item.id, item]));
}

// Counts keep the given order first, then remaining labels by size; empty labels are grouped as unclassified.
export function countBy<T>(items: T[], label: (item: T) => string | null | undefined, order: readonly string[] = []): Count[] {
  const counts = new Map<string, number>();
  for (const item of items) {
    const key = label(item)?.trim() || UNCLASSIFIED;
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  const ordered = order.filter(key => counts.has(key)).map(key => ({ label: key, value: counts.get(key)! }));
  const rest = [...counts].filter(([key]) => !order.includes(key)).map(([key, value]) => ({ label: key, value }))
    .sort((a, b) => Number(a.label === UNCLASSIFIED) - Number(b.label === UNCLASSIFIED) || b.value - a.value || a.label.localeCompare(b.label, 'vi'));
  return [...ordered, ...rest];
}

export function isActiveActivity(status: string): boolean {
  return ACTIVE_ACTIVITY_STATUSES.includes(status);
}

// An activity signed by a consortium also counts for each member partner.
// A consortium is a light group of partners (type "Liên danh"), not a partner in its own right.
export function isConsortium(partner: { partner_type: string | null } | undefined | null) {
  return partner?.partner_type === 'Liên danh';
}

export function activityPartnerIds(activity: OverviewActivity, partners: Map<string, OverviewPartner>): string[] {
  if (!activity.partner_id) return [];
  return [activity.partner_id, ...(partners.get(activity.partner_id)?.member_ids || [])];
}

export function partnerActivities(overview: Overview, partnerId: string): OverviewActivity[] {
  const partners = byId(overview.partners);
  return overview.activities.filter(activity => activityPartnerIds(activity, partners).includes(partnerId));
}

// Activities of one item: a standard problem or a work item.
export function itemActivities(overview: Overview, itemId: string): OverviewActivity[] {
  return overview.activities.filter(activity => activity.standard_id === itemId || activity.work_item_id === itemId);
}

// A unit's activities include those it carries out for another unit in the place of a partner.
export function unitActivities(overview: Overview, unitId: string): OverviewActivity[] {
  return overview.activities.filter(activity => activity.unit_ids.includes(unitId) || activity.provider_unit_id === unitId);
}

export function distinct(values: (string | null | undefined)[]): string[] {
  return [...new Set(values.filter((value): value is string => Boolean(value)))];
}

// Partners that have worked on an item, directly or through a consortium.
export function itemPartnerIds(overview: Overview, itemId: string): string[] {
  const partners = byId(overview.partners);
  return distinct(itemActivities(overview, itemId).flatMap(activity => activityPartnerIds(activity, partners))).filter(id => !isConsortium(partners.get(id)));
}

// The last day of the most recent milestone among those given; empty when there is none.
export function lastMilestoneDay(milestones: OverviewMilestone[]): string {
  return milestones.map(item => item.end_date || item.start_date || '').filter(Boolean).sort().at(-1) || '';
}

export function milestoneDate(milestone: OverviewMilestone): string {
  return milestone.start_date || milestone.end_date || '';
}

// Most recent dated milestone first; undated ones follow by update time.
export function latestMilestone(milestones: OverviewMilestone[]): OverviewMilestone | null {
  return [...milestones].sort((a, b) => milestoneDate(b).localeCompare(milestoneDate(a)) || b.updated_at.localeCompare(a.updated_at))[0] || null;
}

// Accent-insensitive search for Vietnamese titles.
export function searchKey(text: string | null | undefined): string {
  return (text || '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLocaleLowerCase('vi');
}

export function matchesSearch(query: string, ...values: (string | null | undefined)[]): boolean {
  const key = searchKey(query).trim();
  return !key || values.some(value => searchKey(value).includes(key));
}

// Survey titles read "Partner · UNIT · problem"; on that partner's or unit's own page those parts repeat the page.
export function activityTitle(title: string, omit: (string | null | undefined)[] = []) {
  const skip = new Set(omit.filter(Boolean).map(value => value!.trim().toLocaleLowerCase('vi')));
  const parts = title.split(' · ').filter(part => !skip.has(part.trim().toLocaleLowerCase('vi')));
  return parts.length ? parts.join(' · ') : title;
}


// "3 hoạt động" with the running and finished ones spelled out, for item tables.
export function activityCounts(activities: { status: string }[]): { total: number; detail: string } {
  const running = activities.filter(activity => isActiveActivity(activity.status)).length;
  const done = activities.filter(activity => activity.status === 'Hoàn thành').length;
  return { total: activities.length, detail: [running ? `${running} đang chạy` : '', done ? `${done} hoàn thành` : ''].filter(Boolean).join(' · ') };
}
