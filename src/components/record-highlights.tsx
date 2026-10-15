"use client";
import type { ReactNode } from 'react';
import type { CatalogRecord } from '@/lib/catalog';
import { byId, distinct, isActiveActivity, itemActivities, itemPartnerIds, latestMilestone, milestoneDate, partnerActivities, unitActivities, type Overview } from '@/lib/overview';
import { dashboardStyles as styles } from './dashboard-primitives';
import { date } from './ui';
import { useOverview } from './use-overview';

type Item = { label: string; value: ReactNode; detail?: string };

function items(record: CatalogRecord, overview: Overview): Item[] {
  const standards = byId(overview.standards);
  const running = (list: { status: string }[]) => list.filter(item => isActiveActivity(item.status)).length;
  const lastMilestone = (match: (item: Overview['milestones'][number]) => boolean) => {
    const milestone = latestMilestone(overview.milestones.filter(match));
    return milestone ? (milestoneDate(milestone) ? date(milestoneDate(milestone)) : milestone.period_label || milestone.title) : 'Chưa có';
  };
  if (record.kind === 'use_case') {
    const activities = itemActivities(overview, record.id);
    const standard = standards.get(record.id);
    return [
      { label: 'Hoạt động', value: activities.length, detail: `${running(activities)} đang POC / triển khai` },
      { label: 'Đơn vị', value: distinct(activities.map(activity => activity.lead_unit_id)).length, detail: `${standard?.potential_unit_ids.length || 0} đơn vị tiềm năng` },
      { label: 'Đối tác', value: itemPartnerIds(overview, record.id).length, detail: `${standard?.potential_partner_ids.length || 0} đối tác tiềm năng` },
    ];
  }
  if (record.kind === 'work_item') {
    const activities = itemActivities(overview, record.id);
    const item = overview.work_items.find(entry => entry.id === record.id);
    return [
      { label: 'Hoạt động', value: activities.length, detail: `${running(activities)} đang POC / triển khai` },
      { label: 'Đối tác', value: itemPartnerIds(overview, record.id).length },
      { label: 'Đơn vị áp dụng', value: item?.apply_scope === 'Đơn vị cụ thể' ? item.unit_ids.length : item?.apply_scope || 'Chưa xác định' },
      { label: 'Bắt đầu', value: item?.start_date ? date(item.start_date) : 'Chưa xác định' },
    ];
  }
  if (record.kind === 'partner') {
    const activities = partnerActivities(overview, record.id);
    return [
      { label: 'Hoạt động', value: activities.length, detail: `${running(activities)} đang POC / triển khai` },
      { label: 'Hạng mục đã làm', value: distinct(activities.map(activity => activity.standard_id || activity.work_item_id)).length },
      { label: 'Đơn vị cùng làm', value: distinct(activities.flatMap(activity => activity.unit_ids)).length },
      { label: 'Mốc gần nhất', value: lastMilestone(item => item.partner_ids.includes(record.id)) },
    ];
  }
  if (record.kind === 'unit') {
    const activities = unitActivities(overview, record.id);
    return [
      { label: 'Hoạt động', value: activities.length, detail: `${activities.filter(activity => activity.lead_unit_id === record.id).length} làm đầu mối` },
      { label: 'Đang POC / pilot', value: activities.filter(activity => ['POC', 'Pilot'].includes(activity.status)).length },
      { label: 'Đối tác', value: distinct(activities.map(activity => activity.partner_id)).length },
      { label: 'Bài toán chuẩn', value: overview.standards.filter(standard => standard.lead_unit_id === record.id).length, detail: `đầu mối · ${overview.standards.filter(standard => standard.potential_unit_ids.includes(record.id)).length} tiềm năng` },
      { label: 'Hạng mục áp dụng', value: overview.work_items.filter(item => item.unit_ids.includes(record.id)).length },
      { label: 'Mốc gần nhất', value: lastMilestone(item => item.unit_ids.includes(record.id)) },
    ];
  }
  return [];
}

// Quick figures at the top of an item, partner or unit dossier; an activity's own sections already say it all.
export default function RecordHighlights({ record }: { record: CatalogRecord }) {
  const overview = useOverview();
  if (!['use_case', 'work_item', 'partner', 'unit'].includes(record.kind) || !overview.data) return null;
  return <dl className={styles.highlights} aria-label="Số liệu nhanh">{items(record, overview.data).map(item => <div className={styles.highlight} key={item.label}><dt>{item.label}</dt><dd>{item.value}{item.detail && <small>{item.detail}</small>}</dd></div>)}</dl>;
}
