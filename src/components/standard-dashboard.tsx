"use client";
import { useState } from 'react';
import { ITEM_STATUSES, PROGRAMS } from '@/lib/catalog';
import { activityCounts, byId, itemActivities, itemPartnerIds, matchesSearch, UNCLASSIFIED, type Overview } from '@/lib/overview';
import { BarChart, DashboardSection, dashboardStyles as styles, FilterNote, OTHER_COLOR, Panel, PRIORITY_COLOR } from './dashboard-primitives';
import { Badge, Icon } from './ui';

// Tab "Bài toán" of the item catalogue: programme coverage, then the filterable list of standard problems.
export default function StandardTab({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState('');
  const [program, setProgram] = useState('');
  const [priority, setPriority] = useState('');
  const [status, setStatus] = useState('');
  const [onlyWithout, setOnlyWithout] = useState(false);
  const units = byId(overview.units);
  const standards = overview.standards;
  const activitiesOf = (id: string) => itemActivities(overview, id);
  const byProgram = PROGRAMS.map(name => {
    const items = standards.filter(standard => standard.program === name);
    const priorityCount = items.filter(standard => standard.is_priority === 'Có').length;
    return { label: name, value: items.length, parts: [{ name: 'Ưu tiên', value: priorityCount, color: PRIORITY_COLOR }, { name: 'Chưa ưu tiên', value: items.length - priorityCount, color: OTHER_COLOR }] };
  });
  const filtered = standards.filter(standard => (!program || standard.program === program) && (!priority || standard.is_priority === priority) && (!status || standard.status === status)
    && (!onlyWithout || !activitiesOf(standard.id).length) && matchesSearch(query, standard.title, standard.code, standard.category));
  const without = standards.filter(standard => !activitiesOf(standard.id).length).length;
  return <>
    <Panel title="Bài toán chuẩn theo chương trình" eyebrow="Độ phủ" note="Bấm vào một chương trình để lọc danh sách.">
      <BarChart data={byProgram} unit="bài toán" selected={program || undefined} onSelect={label => setProgram(current => current === label ? '' : label)}
        legend={[{ name: 'Ưu tiên', color: PRIORITY_COLOR }, { name: 'Chưa ưu tiên', color: OTHER_COLOR }]}/>
    </Panel>
    <DashboardSection title="Danh mục bài toán chuẩn" eyebrow="Chi tiết">
      <div className={styles.filters}>
        <label className="search-field"><Icon name="search"/><input aria-label="Tìm bài toán chuẩn" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm tên, mã hoặc nhóm…"/></label>
        <select aria-label="Chương trình AI" value={program} onChange={event => setProgram(event.target.value)}><option value="">Tất cả chương trình</option>{PROGRAMS.map(name => <option key={name} value={name}>{name}</option>)}</select>
        <select aria-label="Ưu tiên" value={priority} onChange={event => setPriority(event.target.value)}><option value="">Ưu tiên và chưa ưu tiên</option><option value="Có">Thuộc danh mục ưu tiên</option><option value="Không">Chưa ưu tiên</option></select>
        <select aria-label="Trạng thái" value={status} onChange={event => setStatus(event.target.value)}><option value="">Tất cả trạng thái</option>{ITEM_STATUSES.map(item => <option key={item}>{item}</option>)}</select>
        {onlyWithout ? <FilterNote label="Chưa có hoạt động" onClear={() => setOnlyWithout(false)}/> : without > 0 && <button type="button" className="text-button" onClick={() => setOnlyWithout(true)}>{without} bài chưa có hoạt động</button>}
      </div>
      <p className={styles.count}>{filtered.length} / {standards.length} bài toán chuẩn</p>
      <div className="table-scroll" tabIndex={0} role="region" aria-label="Danh mục bài toán chuẩn"><table><thead><tr><th>Mã</th><th>Bài toán chuẩn</th><th>Chương trình</th><th>Đầu mối ưu tiên</th><th>Trạng thái</th><th className={styles.numeric}>Năm</th><th className={styles.numeric}>Hoạt động</th><th className={styles.numeric}>Đối tác</th></tr></thead>
        <tbody>{filtered.map(standard => {
          const counts = activityCounts(activitiesOf(standard.id));
          const lead = standard.lead_unit_id ? units.get(standard.lead_unit_id) : null;
          return <tr key={standard.id}><td>{standard.code || '—'}</td>
            <td><button className="record-name" onClick={() => onOpen(standard.id)}>{standard.title}</button>{standard.category && <div className="record-meta">{standard.category}</div>}{standard.is_priority === 'Có' && <Badge>Ưu tiên</Badge>}</td>
            <td>{standard.program || UNCLASSIFIED}</td>
            <td>{lead ? <button className="text-button" onClick={() => onOpen(lead.id)}>{lead.abbreviation || lead.title}</button> : '—'}</td>
            <td><Badge>{standard.status}</Badge></td>
            <td className={styles.numeric}>{standard.start_year || '—'}</td>
            <td className={styles.numeric}>{counts.total}{counts.detail && <div className="record-meta">{counts.detail}</div>}</td>
            <td className={styles.numeric}>{itemPartnerIds(overview, standard.id).length}</td></tr>;
        })}</tbody></table></div>
      <p className={styles.note}>Cột Hoạt động: tổng số hoạt động; “đang chạy” gồm POC, pilot, triển khai chính thức và vận hành.</p>
    </DashboardSection>
  </>;
}
