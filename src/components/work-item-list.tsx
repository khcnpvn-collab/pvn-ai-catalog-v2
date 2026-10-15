"use client";
import { APPLY_SCOPES, ITEM_STATUSES, SCOPE_LEVELS } from '@/lib/catalog';
import { rankIn, type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { activityCounts, itemActivities, itemPartnerIds, type Overview, type OverviewWorkItem } from '@/lib/overview';
import { dayText, overviewMaps, partnerTerms, unitName, unitTerms } from './activity-cells';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { DashboardSection } from './dashboard-primitives';
import { Badge } from './ui';

const SPECIFIC_UNITS = 'Đơn vị cụ thể';

// One tab of the item catalogue for a work item group: who leads it, where it applies and its activities.
export default function WorkItemList({ group, overview, onOpen }: { group: string; overview: Overview; onOpen: (id: string) => void }) {
  const [table, setTable] = useTableState(`work-items-${group}`);
  const maps = overviewMaps(overview);
  const items = overview.work_items.filter(item => item.item_group === group);
  const activitiesOf = (item: OverviewWorkItem) => itemActivities(overview, item.id);
  const partnerIds = (item: OverviewWorkItem) => itemPartnerIds(overview, item.id);
  const partnersOf = (item: OverviewWorkItem) => partnerIds(item).map(id => maps.partners.get(id)?.short_name || maps.partners.get(id)?.title).filter(Boolean).join(', ');
  const applies = (item: OverviewWorkItem) => item.apply_scope === SPECIFIC_UNITS
    ? item.unit_ids.map(id => unitName(maps, id)).filter(Boolean).join(', ') || `${SPECIFIC_UNITS} (chưa chọn)`
    : item.apply_scope || '';
  const columns: CatalogColumn<OverviewWorkItem>[] = [
    { key: 'title', label: 'Hạng mục', wide: true, text: item => item.title, render: item => <button className="record-name" onClick={() => onOpen(item.id)}>{item.title}</button> },
    { key: 'level', label: 'Phân loại', text: item => item.scope_level || '' },
    { key: 'scope', label: 'Ưu tiên áp dụng', text: applies, sort: item => item.apply_scope, search: item => unitTerms(maps, item.unit_ids) },
    { key: 'owner', label: 'Đầu mối / phối hợp', text: item => [item.owner, item.coordinator ? `Phối hợp: ${item.coordinator}` : ''].filter(Boolean).join('; '), sort: item => item.owner,
      render: item => <>{item.owner || '—'}{item.coordinator && <div className="record-meta">Phối hợp: {item.coordinator}</div>}</> },
    { key: 'start', label: 'Bắt đầu', text: item => dayText(item.start_date), sort: item => item.start_date },
    { key: 'status', label: 'Trạng thái', text: item => item.status, sort: item => rankIn(ITEM_STATUSES, item.status), render: item => <Badge>{item.status}</Badge> },
    { key: 'activities', label: 'Hoạt động', numeric: true, text: item => String(activitiesOf(item).length), sort: item => activitiesOf(item).length,
      render: item => { const counts = activityCounts(activitiesOf(item)); return <>{counts.total}{counts.detail && <div className="record-meta">{counts.detail}</div>}</>; } },
    { key: 'partners', label: 'Đối tác', text: partnersOf, search: item => partnerTerms(maps, partnerIds(item)) },
    { key: 'updated', label: 'Cập nhật', text: item => dayText(item.updated_at), sort: item => item.updated_at },
  ];
  const filters: TableFilter<OverviewWorkItem>[] = [
    { key: 'level', label: 'Phân loại', all: 'Tập đoàn và đơn vị', values: item => item.scope_level, order: SCOPE_LEVELS },
    { key: 'scope', label: 'Ưu tiên áp dụng', all: 'Mọi phạm vi áp dụng', values: item => item.apply_scope, order: APPLY_SCOPES },
    { key: 'status', label: 'Trạng thái', all: 'Tất cả trạng thái', values: item => item.status, order: ITEM_STATUSES },
  ];
  const quick: QuickFilter<OverviewWorkItem>[] = [
    { key: 'no_activity', label: 'Chưa có hoạt động', test: item => !activitiesOf(item).length },
    { key: 'no_owner', label: 'Chưa có đầu mối', test: item => !item.owner },
    { key: 'no_units', label: 'Đơn vị cụ thể chưa chọn đơn vị', test: item => item.apply_scope === SPECIFIC_UNITS && !item.unit_ids.length },
  ];
  return <DashboardSection title={`Hạng mục — ${group}`} eyebrow="Chi tiết">
    {items.length ? <CatalogTable label={`Hạng mục ${group}`} unit="hạng mục" rows={items} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
      exportName="hang-muc" searchPlaceholder="Tìm hạng mục, đầu mối, đơn vị (tên hoặc viết tắt), đối tác…"/>
      : <p className="related-group-empty">Chưa có hạng mục trong nhóm này. Bấm “Thêm hạng mục” để nhập.</p>}
  </DashboardSection>;
}
