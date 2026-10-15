"use client";
import { type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { countBy, type Overview, type OverviewExpert } from '@/lib/overview';
import { dayText, overviewMaps, partnerTerms, unitTerms } from './activity-cells';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { DashboardSection, dashboardStyles as styles, KpiGrid } from './dashboard-primitives';
import { Badge } from './ui';

// Tab "Chuyên gia": a profile register with where each expert works and the activities they took part in.
export function ExpertDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [table, setTable] = useTableState('experts');
  const maps = overviewMaps(overview);
  const place = (expert: OverviewExpert) => [...expert.unit_ids.map(id => maps.units.get(id)?.title), ...expert.partner_ids.map(id => maps.partners.get(id)?.title), expert.organization].filter(Boolean)[0] || '';
  const activities = (expert: OverviewExpert) => overview.activities.filter(activity => activity.expert_ids?.includes(expert.id)).length;
  const statuses = countBy(overview.experts, expert => expert.status);
  const columns: CatalogColumn<OverviewExpert>[] = [
    { key: 'title', label: 'Chuyên gia', text: expert => expert.title, render: expert => <button className="record-name" onClick={() => onOpen(expert.id)}>{expert.title}</button> },
    { key: 'place', label: 'Nơi công tác', text: place, search: expert => [...unitTerms(maps, expert.unit_ids), ...partnerTerms(maps, expert.partner_ids), expert.organization] },
    { key: 'position', label: 'Chức vụ', text: expert => expert.current_position || '' },
    { key: 'expertise', label: 'Lĩnh vực chuyên môn', text: expert => expert.expertise_summary || '',
      render: expert => expert.expertise_summary ? <div className={styles.clamp} title={expert.expertise_summary}>{expert.expertise_summary}</div> : '—' },
    { key: 'activities', label: 'Hoạt động', numeric: true, text: expert => String(activities(expert)), sort: activities },
    { key: 'status', label: 'Trạng thái', text: expert => expert.status, render: expert => <Badge>{expert.status}</Badge> },
    { key: 'updated', label: 'Cập nhật', text: expert => dayText(expert.updated_at), sort: expert => expert.updated_at },
  ];
  const filters: TableFilter<OverviewExpert>[] = [
    { key: 'status', label: 'Trạng thái', all: 'Tất cả trạng thái', values: expert => expert.status },
  ];
  const quick: QuickFilter<OverviewExpert>[] = [{ key: 'no_activity', label: 'Chưa tham gia hoạt động', test: expert => !activities(expert) }];
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số chuyên gia" items={[
      { label: 'Chuyên gia', value: overview.experts.length, icon: 'user' },
      ...statuses.slice(0, 3).map(item => ({ label: item.label, value: item.value, icon: 'people' })),
    ]}/>
    <DashboardSection title="Danh sách chuyên gia" eyebrow="Chi tiết">
      <CatalogTable label="Danh sách chuyên gia" unit="chuyên gia" rows={overview.experts} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
        exportName="chuyen-gia" searchPlaceholder="Tìm chuyên gia, nơi công tác, chuyên môn…"/>
    </DashboardSection>
  </div>;
}
