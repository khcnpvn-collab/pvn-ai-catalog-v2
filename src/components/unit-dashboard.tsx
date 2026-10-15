"use client";
import { UNIT_TYPES } from '@/lib/catalog';
import { type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { distinct, isActiveActivity, latestMilestone, milestoneDate, unitActivities, type Overview } from '@/lib/overview';
import { dayText } from './activity-cells';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, KpiGrid, OTHER_COLOR, Panel, PRIORITY_COLOR } from './dashboard-primitives';

// Tab "Đơn vị": who leads activities, who owns priority standard problems, and each unit's partners.
export default function UnitDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [table, setTable] = useTableState('units');
  const onlyActive = table.quick.includes('active');
  const rows = overview.units.map(unit => {
    const activities = unitActivities(overview, unit.id);
    const leadStandards = overview.standards.filter(standard => standard.lead_unit_id === unit.id);
    return { id: unit.id, unit, activities, leading: activities.filter(activity => activity.lead_unit_id === unit.id), leadStandards,
      poc: activities.filter(activity => ['POC', 'Pilot'].includes(activity.status)).length,
      running: activities.filter(activity => ['Triển khai chính thức', 'Vận hành'].includes(activity.status)).length,
      partners: distinct(activities.map(activity => activity.partner_id)).length,
      potential: overview.standards.filter(standard => standard.potential_unit_ids.includes(unit.id)),
      workItems: overview.work_items.filter(item => item.unit_ids.includes(unit.id)),
      milestone: latestMilestone(overview.milestones.filter(item => item.unit_ids.includes(unit.id))) };
  });
  type Row = typeof rows[number];
  const name = (row: Row) => row.unit.abbreviation || row.unit.title;
  const byActivities = [...rows].filter(row => row.activities.length).sort((a, b) => b.activities.length - a.activities.length).slice(0, 12)
    .map(row => { const active = row.activities.filter(activity => isActiveActivity(activity.status)).length; return { label: name(row), value: row.activities.length, parts: [{ name: 'Đang chạy', value: active, color: '#1c426f' }, { name: 'Khác', value: row.activities.length - active, color: '#a3b8d4' }] }; });
  const byLead = [...rows].filter(row => row.leadStandards.length).sort((a, b) => b.leadStandards.length - a.leadStandards.length)
    .map(row => { const priority = row.leadStandards.filter(standard => standard.is_priority === 'Có').length; return { label: name(row), value: row.leadStandards.length, parts: [{ name: 'Ưu tiên', value: priority, color: PRIORITY_COLOR }, { name: 'Khác', value: row.leadStandards.length - priority, color: OTHER_COLOR }] }; });
  const milestoneDay = (row: Row) => row.milestone ? milestoneDate(row.milestone) : '';
  const columns: CatalogColumn<Row>[] = [
    { key: 'title', label: 'Đơn vị', wide: true, text: row => [row.unit.title, row.unit.abbreviation].filter(Boolean).join(' · '), sort: row => row.unit.title,
      render: row => <><button className="record-name" onClick={() => onOpen(row.id)}>{row.unit.title}</button>{row.unit.abbreviation && <div className="record-meta">{row.unit.abbreviation}</div>}</> },
    { key: 'type', label: 'Phân loại đơn vị', text: row => row.unit.unit_type || '' },
    { key: 'sector', label: 'Lĩnh vực', text: row => row.unit.sector || '' },
    { key: 'activities', label: 'Hoạt động (đầu mối / tổng)', numeric: true, text: row => `${row.leading.length} / ${row.activities.length}`, sort: row => row.activities.length },
    { key: 'poc', label: 'POC / pilot', numeric: true, text: row => String(row.poc), sort: row => row.poc },
    { key: 'running', label: 'Triển khai / vận hành', numeric: true, text: row => String(row.running), sort: row => row.running },
    { key: 'partners', label: 'Đối tác', numeric: true, text: row => String(row.partners), sort: row => row.partners },
    { key: 'standards', label: 'Bài chuẩn đầu mối / tiềm năng', numeric: true, text: row => `${row.leadStandards.length} / ${row.potential.length}`, sort: row => row.leadStandards.length * 1000 + row.potential.length },
    { key: 'work_items', label: 'Hạng mục khác áp dụng', numeric: true, text: row => String(row.workItems.length), sort: row => row.workItems.length },
    { key: 'milestone', label: 'Mốc gần nhất', text: row => row.milestone ? dayText(milestoneDay(row)) || row.milestone.title : '', sort: milestoneDay,
      render: row => row.milestone ? <button className="text-button" onClick={() => onOpen(row.milestone!.id)}>{dayText(milestoneDay(row)) || row.milestone.title}</button> : '—' },
  ];
  const filters: TableFilter<Row>[] = [
    { key: 'type', label: 'Phân loại đơn vị', all: 'Mọi phân loại đơn vị', values: row => row.unit.unit_type, order: UNIT_TYPES },
    { key: 'sector', label: 'Lĩnh vực', all: 'Mọi lĩnh vực', values: row => row.unit.sector },
  ];
  const quick: QuickFilter<Row>[] = [
    { key: 'active', label: 'Có hoạt động', test: row => row.activities.length > 0 },
    { key: 'no_activity', label: 'Chưa có hoạt động', test: row => !row.activities.length },
    { key: 'priority_idle', label: 'Đầu mối bài toán ưu tiên nhưng chưa có hoạt động', test: row => !row.activities.length && row.leadStandards.some(standard => standard.is_priority === 'Có') },
  ];
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số đơn vị" items={[
      { label: 'Đơn vị', value: rows.length, caption: 'Gồm Tập đoàn và các Ban', icon: 'building', onClick: () => setTable({ ...table, quick: table.quick.filter(key => key !== 'active') }), pressed: !onlyActive },
      { label: 'Đơn vị có hoạt động', value: rows.filter(row => row.activities.length).length, caption: 'Bấm để lọc', icon: 'file', onClick: () => setTable({ ...table, quick: onlyActive ? table.quick.filter(key => key !== 'active') : [...table.quick, 'active'] }), pressed: onlyActive },
      { label: 'Đang POC / pilot', value: overview.activities.filter(activity => ['POC', 'Pilot'].includes(activity.status) && activity.lead_unit_id).length, caption: 'Hoạt động có đơn vị đầu mối', icon: 'spark' },
      { label: 'Đầu mối bài toán ưu tiên', value: distinct(overview.standards.filter(standard => standard.is_priority === 'Có').map(standard => standard.lead_unit_id)).length, caption: 'Đơn vị được giao dẫn dắt', icon: 'shield' },
    ]}/>
    <ChartGrid>
      <Panel title="Hoạt động theo đơn vị" eyebrow="Mức độ triển khai" note="12 đơn vị có nhiều hoạt động nhất, tính cả vai trò phối hợp.">
        <BarChart data={byActivities} unit="hoạt động" legend={[{ name: 'Đang POC / triển khai / vận hành', color: '#1c426f' }, { name: 'Khác', color: '#a3b8d4' }]}/>
      </Panel>
      <Panel title="Đầu mối ưu tiên theo bài toán chuẩn" eyebrow="Định hướng">
        <BarChart data={byLead} unit="bài toán" legend={[{ name: 'Ưu tiên', color: PRIORITY_COLOR }, { name: 'Khác', color: OTHER_COLOR }]}/>
      </Panel>
    </ChartGrid>
    <DashboardSection title="Danh sách đơn vị" eyebrow="Chi tiết">
      <CatalogTable label="Danh sách đơn vị" unit="đơn vị" rows={rows} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
        exportName="don-vi" searchPlaceholder="Tìm tên, viết tắt, lĩnh vực…"/>
    </DashboardSection>
  </div>;
}
