"use client";
import { useState } from 'react';
import { ACTIVITY_STATUSES, ITEM_CATEGORIES, ITEM_GROUPS, PROGRAMS, STANDARD_GROUP } from '@/lib/catalog';
import { byId, countBy, isActiveActivity, matchesSearch, type Overview } from '@/lib/overview';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, FilterNote, GroupTabs, KpiGrid, OTHER_COLOR, Panel, StageBar } from './dashboard-primitives';
import { ActivityTable } from './roadmap-sections';
import { Icon } from './ui';

// The tab survives opening an activity and coming back.
let lastGroup = STANDARD_GROUP;

// Tab "Triển khai & hợp tác": lifecycle and groups across all activities, then one list per item group.
export default function ActivityDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [group, setGroupState] = useState(lastGroup);
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [program, setProgram] = useState('');
  const [unassigned, setUnassigned] = useState(false);
  const setGroup = (next: string) => { lastGroup = next; setGroupState(next); setCategory(''); setProgram(''); };
  const standards = byId(overview.standards), workItems = byId(overview.work_items), partners = byId(overview.partners), units = byId(overview.units);
  const activities = overview.activities;
  const groupOf = (activity: Overview['activities'][number]) => activity.item_group || STANDARD_GROUP;
  const linked = (activity: Overview['activities'][number]) => Boolean(activity.standard_id || activity.work_item_id);
  const counts = Object.fromEntries(ITEM_GROUPS.map(name => [name, activities.filter(activity => groupOf(activity) === name).length]));
  const inGroup = activities.filter(activity => groupOf(activity) === group);
  const filtered = inGroup.filter(activity => (!status || activity.status === status) && (!category || activity.item_category === category)
    && (!program || standards.get(activity.standard_id || '')?.program === program) && (!unassigned || !linked(activity))
    && matchesSearch(query, activity.title, activity.item_category, partners.get(activity.partner_id || '')?.title, units.get(activity.lead_unit_id || '')?.title, units.get(activity.lead_unit_id || '')?.abbreviation,
      standards.get(activity.standard_id || '')?.title, workItems.get(activity.work_item_id || '')?.title));
  const inStage = (statuses: string[]) => activities.filter(activity => statuses.includes(activity.status)).length;
  const byGroup = ITEM_GROUPS.map(name => {
    const items = activities.filter(activity => groupOf(activity) === name);
    const running = items.filter(activity => isActiveActivity(activity.status)).length;
    return { label: name, value: items.length, parts: [{ name: 'Đang chạy', value: running, color: '#1c426f' }, { name: 'Khác', value: items.length - running, color: OTHER_COLOR }] };
  });
  const unlinkedCount = activities.filter(activity => !linked(activity)).length;
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số hoạt động" items={[
      { label: 'Hoạt động', value: activities.length, caption: `${ITEM_GROUPS.length} nhóm hạng mục`, icon: 'file', onClick: () => { setStatus(''); setUnassigned(false); }, pressed: !status && !unassigned },
      { label: 'Đang POC / pilot', value: inStage(['POC', 'Pilot']), caption: 'Thử nghiệm đang chạy', icon: 'spark' },
      { label: 'Triển khai / vận hành', value: inStage(['Triển khai chính thức', 'Vận hành']), caption: `${activities.filter(activity => isActiveActivity(activity.status)).length} hoạt động đang chạy`, icon: 'check' },
      { label: 'Chưa gắn hạng mục', value: unlinkedCount, caption: 'Bấm để lọc trong tab đang mở', icon: 'link', onClick: () => setUnassigned(!unassigned), pressed: unassigned },
    ]}/>
    <ChartGrid>
      <Panel title="Hoạt động theo giai đoạn" eyebrow="Vòng đời" note="Bấm vào một giai đoạn để lọc danh sách.">
        <StageBar data={countBy(activities, activity => activity.status, ACTIVITY_STATUSES)} unit="hoạt động" selected={status} onSelect={label => setStatus(current => current === label ? '' : label)}/>
      </Panel>
      <Panel title="Hoạt động theo nhóm hạng mục" eyebrow="Phân loại" note="Bấm vào một nhóm để mở tab của nhóm đó.">
        <BarChart data={byGroup} unit="hoạt động" selected={group} onSelect={setGroup} legend={[{ name: 'Đang chạy', color: '#1c426f' }, { name: 'Khác', color: OTHER_COLOR }]}/>
      </Panel>
    </ChartGrid>
    <section aria-label="Hoạt động theo nhóm">
      <GroupTabs label="Nhóm hạng mục" groups={ITEM_GROUPS} active={group} counts={counts} onChange={setGroup}/>
      <DashboardSection title={`Hoạt động — ${group}`} eyebrow="Chi tiết">
        <div className={styles.filters}>
          <label className="search-field"><Icon name="search"/><input aria-label="Tìm hoạt động" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm hoạt động, đối tác, đơn vị, hạng mục…"/></label>
          <select aria-label="Trạng thái" value={status} onChange={event => setStatus(event.target.value)}><option value="">Tất cả trạng thái</option>{ACTIVITY_STATUSES.map(item => <option key={item}>{item}</option>)}</select>
          <select aria-label="Phân loại chi tiết" value={category} onChange={event => setCategory(event.target.value)}><option value="">Mọi phân loại chi tiết</option>{(ITEM_CATEGORIES[group] || []).map(item => <option key={item}>{item}</option>)}</select>
          {group === STANDARD_GROUP && <select aria-label="Chương trình AI" value={program} onChange={event => setProgram(event.target.value)}><option value="">Tất cả chương trình</option>{PROGRAMS.map(name => <option key={name}>{name}</option>)}</select>}
          {unassigned && <FilterNote label="Chưa gắn hạng mục" onClear={() => setUnassigned(false)}/>}
        </div>
        <p className={styles.count}>{filtered.length} / {inGroup.length} hoạt động</p>
        {inGroup.length ? <ActivityTable activities={filtered} overview={overview} onOpen={onOpen} showGroup={false}/> : <p className="related-group-empty">Chưa có hoạt động trong nhóm này.</p>}
      </DashboardSection>
    </section>
  </div>;
}
