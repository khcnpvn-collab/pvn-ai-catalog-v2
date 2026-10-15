"use client";
import { useState } from 'react';
import { ACTIVITY_STATUSES, ITEM_GROUPS, STANDARD_GROUP } from '@/lib/catalog';
import { countBy, isActiveActivity, type Overview } from '@/lib/overview';
import { activityTable } from './activity-table-columns';
import CatalogTable, { useTableState } from './catalog-table';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, GroupTabs, KpiGrid, OTHER_COLOR, Panel, StageBar } from './dashboard-primitives';

// The tab survives opening an activity and coming back.
let lastGroup = STANDARD_GROUP;

// Tab "Triển khai & hợp tác": lifecycle and groups across all activities, then one list per item group.
export default function ActivityDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [group, setGroupState] = useState(lastGroup);
  const [table, setTable] = useTableState('activities');
  const status = table.filters.status || '';
  const unassigned = table.quick.includes('no_item');
  // A new group keeps the cross-group filters and drops the group's own ones.
  const setGroup = (next: string) => { lastGroup = next; setGroupState(next); setTable({ ...table, filters: { ...table.filters, category: '' } }); };
  const setStatus = (next: string) => setTable({ ...table, filters: { ...table.filters, status: next } });
  const activities = overview.activities;
  const groupOf = (activity: Overview['activities'][number]) => activity.item_group || STANDARD_GROUP;
  const linked = (activity: Overview['activities'][number]) => Boolean(activity.standard_id || activity.work_item_id);
  const counts = Object.fromEntries(ITEM_GROUPS.map(name => [name, activities.filter(activity => groupOf(activity) === name).length]));
  const inGroup = activities.filter(activity => groupOf(activity) === group);
  const inStage = (statuses: string[]) => activities.filter(activity => statuses.includes(activity.status)).length;
  const byGroup = ITEM_GROUPS.map(name => {
    const items = activities.filter(activity => groupOf(activity) === name);
    const running = items.filter(activity => isActiveActivity(activity.status)).length;
    return { label: name, value: items.length, parts: [{ name: 'Đang chạy', value: running, color: '#1c426f' }, { name: 'Khác', value: items.length - running, color: OTHER_COLOR }] };
  });
  const unlinkedCount = activities.filter(activity => !linked(activity)).length;
  const config = activityTable(overview, onOpen, group);
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số hoạt động" items={[
      { label: 'Hoạt động', value: activities.length, caption: `${ITEM_GROUPS.length} nhóm hạng mục`, icon: 'file', onClick: () => setTable({ ...table, filters: { ...table.filters, status: '' }, quick: table.quick.filter(key => key !== 'no_item') }), pressed: !status && !unassigned },
      { label: 'Đang POC / pilot', value: inStage(['POC', 'Pilot']), caption: 'Thử nghiệm đang chạy', icon: 'spark' },
      { label: 'Triển khai / vận hành', value: inStage(['Triển khai chính thức', 'Vận hành']), caption: `${activities.filter(activity => isActiveActivity(activity.status)).length} hoạt động đang chạy`, icon: 'check' },
      { label: 'Chưa gắn hạng mục', value: unlinkedCount, caption: 'Bấm để lọc trong tab đang mở', icon: 'link', onClick: () => setTable({ ...table, quick: unassigned ? table.quick.filter(key => key !== 'no_item') : [...table.quick, 'no_item'] }), pressed: unassigned },
    ]}/>
    <ChartGrid>
      <Panel title="Hoạt động theo giai đoạn" eyebrow="Vòng đời" note="Bấm vào một giai đoạn để lọc danh sách.">
        <StageBar data={countBy(activities, activity => activity.status, ACTIVITY_STATUSES)} unit="hoạt động" selected={status} onSelect={label => setStatus(status === label ? '' : label)}/>
      </Panel>
      <Panel title="Hoạt động theo nhóm hạng mục" eyebrow="Phân loại" note="Bấm vào một nhóm để mở tab của nhóm đó.">
        <BarChart data={byGroup} unit="hoạt động" selected={group} onSelect={setGroup} legend={[{ name: 'Đang chạy', color: '#1c426f' }, { name: 'Khác', color: OTHER_COLOR }]}/>
      </Panel>
    </ChartGrid>
    <section aria-label="Hoạt động theo nhóm">
      <GroupTabs label="Nhóm hạng mục" groups={ITEM_GROUPS} active={group} counts={counts} onChange={setGroup}/>
      <DashboardSection title={`Hoạt động — ${group}`} eyebrow="Chi tiết">
        <CatalogTable key={group} label={`Hoạt động ${group}`} unit="hoạt động" rows={inGroup} {...config} state={table} onState={setTable}
          exportName="trien-khai-hop-tac" searchPlaceholder="Tìm hoạt động, đối tác, đơn vị (tên hoặc viết tắt), hạng mục…"/>
      </DashboardSection>
    </section>
  </div>;
}
