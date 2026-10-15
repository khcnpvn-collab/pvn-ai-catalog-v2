"use client";
import { useState } from 'react';
import { ITEM_GROUPS, ITEM_STATUSES, STANDARD_GROUP } from '@/lib/catalog';
import { countBy, isActiveActivity, itemActivities, type Overview } from '@/lib/overview';
import { BarChart, ChartGrid, dashboardStyles as styles, GroupTabs, KpiGrid, OTHER_COLOR, Panel, StageBar } from './dashboard-primitives';
import StandardTab from './standard-dashboard';
import WorkItemList from './work-item-list';
import { Icon } from './ui';

// The tab survives opening an item and coming back.
let lastGroup = STANDARD_GROUP;

// "Danh mục hạng mục": figures across the six groups on top, then one catalogue tab per group.
export default function ItemCatalogDashboard({ overview, onOpen, canWrite, onCreate }: { overview: Overview; onOpen: (id: string) => void; canWrite?: boolean; onCreate?: (kind: string, preset?: Record<string, string>) => void }) {
  const [group, setGroupState] = useState(lastGroup);
  const setGroup = (next: string) => { lastGroup = next; setGroupState(next); };
  const items = [...overview.standards.map(item => ({ id: item.id, status: item.status, group: STANDARD_GROUP })), ...overview.work_items.map(item => ({ id: item.id, status: item.status, group: item.item_group }))];
  const withActivity = new Set(overview.activities.flatMap(activity => [activity.standard_id, activity.work_item_id]).filter(Boolean));
  const linked = overview.activities.filter(activity => activity.standard_id || activity.work_item_id);
  const counts = Object.fromEntries(ITEM_GROUPS.map(name => [name, items.filter(item => item.group === name).length]));
  const byGroup = ITEM_GROUPS.map(name => {
    const inGroup = items.filter(item => item.group === name);
    const active = inGroup.filter(item => withActivity.has(item.id)).length;
    return { label: name, value: inGroup.length, parts: [{ name: 'Có hoạt động', value: active, color: '#1c426f' }, { name: 'Chưa có hoạt động', value: inGroup.length - active, color: OTHER_COLOR }] };
  });
  const standard = group === STANDARD_GROUP;
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số hạng mục" items={[
      { label: 'Hạng mục', value: items.length, caption: `${overview.standards.length} bài toán chuẩn · ${overview.work_items.length} hạng mục khác`, icon: 'spark' },
      { label: 'Đang thực hiện', value: items.filter(item => item.status === 'Đang thực hiện').length, caption: `${items.filter(item => item.status === 'Hoàn thành').length} đã hoàn thành`, icon: 'check' },
      { label: 'Có hoạt động', value: items.filter(item => withActivity.has(item.id)).length, caption: `${items.length - items.filter(item => withActivity.has(item.id)).length} hạng mục chưa có hoạt động`, icon: 'file' },
      { label: 'Hoạt động gắn hạng mục', value: linked.length, caption: `${linked.filter(activity => isActiveActivity(activity.status)).length} đang POC / triển khai · ${overview.activities.length - linked.length} chưa gắn`, icon: 'link' },
    ]}/>
    <ChartGrid>
      <Panel title="Hạng mục theo nhóm" eyebrow="Độ phủ" note="Bấm vào một nhóm để mở tab của nhóm đó.">
        <BarChart data={byGroup} unit="hạng mục" selected={group} onSelect={setGroup} legend={[{ name: 'Có hoạt động', color: '#1c426f' }, { name: 'Chưa có hoạt động', color: OTHER_COLOR }]}/>
      </Panel>
      <Panel title="Hạng mục theo trạng thái" eyebrow="Vòng đời">
        <StageBar data={countBy(items, item => item.status, ITEM_STATUSES)} unit="hạng mục"/>
      </Panel>
    </ChartGrid>
    <section aria-label="Danh mục theo nhóm">
      <GroupTabs label="Nhóm hạng mục" groups={ITEM_GROUPS} active={group} counts={counts} onChange={setGroup}/>
      <div className={styles.tabHeading}><p>{standard ? `${overview.standards.length} bài toán chuẩn theo 7 chương trình AI.` : `${counts[group]} hạng mục · ${items.filter(item => item.group === group).reduce((sum, item) => sum + itemActivities(overview, item.id).length, 0)} hoạt động đã gắn.`}</p>
        {canWrite && onCreate && <button className="button primary" onClick={() => standard ? onCreate('use_case') : onCreate('work_item', { item_group: group })}><Icon name="plus"/>{standard ? 'Thêm bài toán chuẩn' : 'Thêm hạng mục'}</button>}</div>
      {standard ? <StandardTab overview={overview} onOpen={onOpen}/> : <WorkItemList key={group} group={group} overview={overview} onOpen={onOpen}/>}
    </section>
  </div>;
}
