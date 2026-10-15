"use client";
import { ACTIVITY_STATUSES, ITEM_CATEGORIES } from '@/lib/catalog';
import { daysSince, rankIn, type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { latestMilestone, milestoneDate, type Overview, type OverviewActivity } from '@/lib/overview';
import { ActivityItemCell, ActivityPartyCell, activityItemText, activityPartyText, dayText, overviewMaps, partnerTerms, unitName, unitTerms } from './activity-cells';
import type { CatalogColumn } from './catalog-table';
import { dashboardStyles as styles } from './dashboard-primitives';
import { Badge } from './ui';

export const STALE_DAYS = 90;

// Columns, filters and quick filters of the activity list on "Triển khai & hợp tác", for one item group.
export function activityTable(overview: Overview, onOpen: (id: string) => void, group: string) {
  const maps = overviewMaps(overview);
  const supporting = (activity: OverviewActivity) => activity.unit_ids.filter(id => id !== activity.lead_unit_id).map(id => unitName(maps, id)).filter(Boolean);
  // The latest working day: the date written on the activity or its most recent milestone.
  const lastWork = (activity: OverviewActivity) => {
    const milestone = latestMilestone(overview.milestones.filter(item => item.activity_ids.includes(activity.id)));
    return [activity.last_meeting_date, milestone ? milestoneDate(milestone) : ''].filter(Boolean).sort().at(-1) || '';
  };
  const period = (activity: OverviewActivity) => [dayText(activity.start_date), dayText(activity.end_date)].filter(Boolean).join(' – ');
  const columns: CatalogColumn<OverviewActivity>[] = [
    { key: 'title', label: 'Hoạt động', wide: true, text: activity => activity.title,
      render: activity => <><button className="record-name" title={activity.title} onClick={() => onOpen(activity.id)}>{activity.title}</button>{activity.item_category && <div className="record-meta">{activity.item_category}</div>}</> },
    { key: 'status', label: 'Trạng thái', text: activity => activity.status, sort: activity => rankIn(ACTIVITY_STATUSES, activity.status), render: activity => <Badge>{activity.status}</Badge> },
    { key: 'party', label: 'Bên thực hiện', text: activity => activityPartyText(activity, maps), search: activity => [...partnerTerms(maps, [activity.partner_id]), ...unitTerms(maps, [activity.provider_unit_id])], render: activity => <ActivityPartyCell activity={activity} maps={maps} onOpen={onOpen}/> },
    { key: 'lead', label: 'Đầu mối PVN', text: activity => [unitName(maps, activity.lead_unit_id), supporting(activity).length ? `Phối hợp: ${supporting(activity).join(', ')}` : ''].filter(Boolean).join('; '),
      sort: activity => unitName(maps, activity.lead_unit_id), search: activity => unitTerms(maps, activity.unit_ids),
      render: activity => <>{activity.lead_unit_id ? <button className="text-button" onClick={() => onOpen(activity.lead_unit_id!)}>{unitName(maps, activity.lead_unit_id)}</button> : '—'}{supporting(activity).length > 0 && <div className="record-meta">Phối hợp: {supporting(activity).join(', ')}</div>}</> },
    { key: 'item', label: 'Hạng mục', wide: true, text: activity => activityItemText(activity, maps), render: activity => <ActivityItemCell activity={activity} maps={maps} onOpen={onOpen}/> },
    { key: 'period', label: 'Thời gian', text: period, sort: activity => activity.start_date || activity.end_date },
    { key: 'last_work', label: 'Làm việc gần nhất', text: activity => dayText(lastWork(activity)), sort: lastWork },
    { key: 'next', label: 'Bước tiếp theo', text: activity => activity.next_notes || '', render: activity => activity.next_notes ? <div className={styles.clamp} title={activity.next_notes}>{activity.next_notes}</div> : '—' },
    { key: 'updated', label: 'Cập nhật', text: activity => dayText(activity.updated_at), sort: activity => activity.updated_at },
  ];
  const filters: TableFilter<OverviewActivity>[] = [
    { key: 'status', label: 'Trạng thái', all: 'Tất cả trạng thái', values: activity => activity.status, order: ACTIVITY_STATUSES },
    { key: 'category', label: 'Phân loại chi tiết', all: 'Mọi phân loại chi tiết', values: activity => activity.item_category, order: ITEM_CATEGORIES[group] || [] },
    { key: 'year', label: 'Năm bắt đầu', all: 'Mọi năm bắt đầu', values: activity => activity.start_date?.slice(0, 4) },
  ];
  const quick: QuickFilter<OverviewActivity>[] = [
    { key: 'no_item', label: 'Chưa gắn hạng mục', test: activity => !activity.standard_id && !activity.work_item_id },
    { key: 'no_party', label: 'Chưa có bên thực hiện', test: activity => !activity.partner_id && !activity.provider_unit_id },
    { key: 'no_lead', label: 'Chưa có đầu mối PVN', test: activity => !activity.lead_unit_id },
    { key: 'no_date', label: 'Chưa có thời gian', test: activity => !activity.start_date && !activity.end_date },
    { key: 'stale', label: `Không cập nhật trên ${STALE_DAYS} ngày`, test: activity => (daysSince(activity.updated_at) ?? 0) > STALE_DAYS },
  ];
  return { columns, filters, quick };
}
