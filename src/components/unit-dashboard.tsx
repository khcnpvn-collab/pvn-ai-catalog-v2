"use client";
import { useState } from 'react';
import { distinct, isActiveActivity, latestMilestone, matchesSearch, milestoneDate, unitActivities, type Overview } from '@/lib/overview';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, KpiGrid, OTHER_COLOR, Panel, PRIORITY_COLOR } from './dashboard-primitives';
import { date, Icon } from './ui';

// Tab "Đơn vị": who leads activities, who owns priority standard problems, and each unit's partners.
export default function UnitDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState('');
  const [onlyActive, setOnlyActive] = useState(false);
  const rows = overview.units.map(unit => {
    const activities = unitActivities(overview, unit.id);
    const leading = activities.filter(activity => activity.lead_unit_id === unit.id);
    const leadStandards = overview.standards.filter(standard => standard.lead_unit_id === unit.id);
    const potential = overview.standards.filter(standard => standard.potential_unit_ids.includes(unit.id));
    return { unit, activities, leading, poc: activities.filter(activity => ['POC', 'Pilot'].includes(activity.status)).length,
      running: activities.filter(activity => ['Triển khai chính thức', 'Vận hành'].includes(activity.status)).length,
      partners: distinct(activities.map(activity => activity.partner_id)).length, leadStandards, potential,
      milestone: latestMilestone(overview.milestones.filter(item => item.unit_ids.includes(unit.id))) };
  });
  const name = (row: typeof rows[number]) => row.unit.abbreviation || row.unit.title;
  const byActivities = [...rows].filter(row => row.activities.length).sort((a, b) => b.activities.length - a.activities.length).slice(0, 12)
    .map(row => { const active = row.activities.filter(activity => isActiveActivity(activity.status)).length; return { label: name(row), value: row.activities.length, parts: [{ name: 'Đang chạy', value: active, color: '#1c426f' }, { name: 'Khác', value: row.activities.length - active, color: '#a3b8d4' }] }; });
  const byLead = [...rows].filter(row => row.leadStandards.length).sort((a, b) => b.leadStandards.length - a.leadStandards.length)
    .map(row => { const priority = row.leadStandards.filter(standard => standard.is_priority === 'Có').length; return { label: name(row), value: row.leadStandards.length, parts: [{ name: 'Ưu tiên', value: priority, color: PRIORITY_COLOR }, { name: 'Khác', value: row.leadStandards.length - priority, color: OTHER_COLOR }] }; });
  const filtered = rows.filter(row => (!onlyActive || row.activities.length > 0) && matchesSearch(query, row.unit.title, row.unit.abbreviation, row.unit.sector));
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số đơn vị" items={[
      { label: 'Đơn vị', value: rows.length, caption: 'Gồm Tập đoàn và các Ban', icon: 'building', onClick: () => setOnlyActive(false), pressed: !onlyActive },
      { label: 'Đơn vị có hoạt động', value: rows.filter(row => row.activities.length).length, caption: 'Bấm để lọc', icon: 'file', onClick: () => setOnlyActive(!onlyActive), pressed: onlyActive },
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
      <div className={styles.filters}><label className="search-field"><Icon name="search"/><input aria-label="Tìm đơn vị" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm tên, viết tắt, lĩnh vực…"/></label></div>
      <p className={styles.count}>{filtered.length} / {rows.length} đơn vị</p>
      <div className="table-scroll" tabIndex={0} role="region" aria-label="Danh sách đơn vị"><table><thead><tr><th>Đơn vị</th><th className={styles.numeric}>Hoạt động (đầu mối / tổng)</th><th className={styles.numeric}>POC / pilot</th><th className={styles.numeric}>Triển khai / vận hành</th><th className={styles.numeric}>Đối tác</th><th className={styles.numeric}>Bài chuẩn đầu mối / tiềm năng</th><th>Mốc gần nhất</th></tr></thead>
        <tbody>{filtered.map(row => <tr key={row.unit.id}>
          <td><button className="record-name" onClick={() => onOpen(row.unit.id)}>{row.unit.title}</button><div className="record-meta">{[row.unit.abbreviation, row.unit.sector].filter(Boolean).join(' · ')}</div></td>
          <td className={styles.numeric}>{row.leading.length} / {row.activities.length}</td><td className={styles.numeric}>{row.poc}</td><td className={styles.numeric}>{row.running}</td><td className={styles.numeric}>{row.partners}</td>
          <td className={styles.numeric}>{row.leadStandards.length} / {row.potential.length}</td>
          <td>{row.milestone ? <button className="text-button" onClick={() => onOpen(row.milestone!.id)}>{milestoneDate(row.milestone) ? date(milestoneDate(row.milestone)) : row.milestone.title}</button> : '—'}</td>
        </tr>)}</tbody></table></div>
    </DashboardSection>
  </div>;
}
