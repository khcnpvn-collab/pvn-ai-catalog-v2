"use client";
import { useState } from 'react';
import { PARTNER_STATUSES } from '@/lib/catalog';
import { byId, countBy, distinct, isActiveActivity, isConsortium, matchesSearch, partnerActivities, type Overview } from '@/lib/overview';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, KpiGrid, Panel, StageBar } from './dashboard-primitives';
import { Badge, Icon } from './ui';

// Tab "Đối tác": overall relationship status, who we work with most, and what each partner has done.
export default function PartnerDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('');
  const standards = byId(overview.standards), workItems = byId(overview.work_items), units = byId(overview.units);
  // Consortia are groups of partners: counted apart, never listed as partners.
  const partners = overview.partners.filter(partner => !isConsortium(partner));
  const consortia = overview.partners.filter(isConsortium);
  const rows = partners.map(partner => {
    const activities = partnerActivities(overview, partner.id);
    // PVN units and items met through this partner's activities.
    const unitIds = distinct(activities.flatMap(activity => activity.unit_ids));
    const itemIds = distinct(activities.map(activity => activity.standard_id || activity.work_item_id));
    return { partner, activities, active: activities.filter(activity => isActiveActivity(activity.status)).length, unitIds, itemIds };
  });
  const top = [...rows].filter(row => row.activities.length).sort((a, b) => b.activities.length - a.activities.length || a.partner.title.localeCompare(b.partner.title, 'vi')).slice(0, 10)
    .map(row => ({ label: row.partner.title, value: row.activities.length, parts: [{ name: 'Đang chạy', value: row.active, color: '#1c426f' }, { name: 'Khác', value: row.activities.length - row.active, color: '#a3b8d4' }] }));
  const filtered = rows.filter(row => (!status || row.partner.status === status) && matchesSearch(query, row.partner.title, row.partner.short_name, row.partner.partner_type, row.partner.country));
  const counts = countBy(partners, partner => partner.status, PARTNER_STATUSES);
  const count = (label: string) => counts.find(item => item.label === label)?.value || 0;
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số đối tác" items={[
      { label: 'Đối tác', value: partners.length, caption: `${rows.filter(row => row.activities.length).length} đối tác có hoạt động`, icon: 'people', onClick: () => setStatus(''), pressed: !status },
      { label: 'Đang hợp tác', value: count('Đang hợp tác'), caption: `${partners.filter(partner => partner.strategic_level && partner.strategic_level !== 'Không').length} có MOU / hợp tác chiến lược — bấm để lọc`, icon: 'check', onClick: () => setStatus(status === 'Đang hợp tác' ? '' : 'Đang hợp tác'), pressed: status === 'Đang hợp tác' },
      { label: 'Tiềm năng', value: count('Tiềm năng'), caption: 'Bấm để lọc', icon: 'spark', onClick: () => setStatus(status === 'Tiềm năng' ? '' : 'Tiềm năng'), pressed: status === 'Tiềm năng' },
      { label: 'Liên danh', value: consortia.length, caption: `${new Set(consortia.flatMap(group => group.member_ids)).size} đối tác tham gia liên danh`, icon: 'link' },
    ]}/>
    <ChartGrid>
      <Panel title="Đối tác theo trạng thái hợp tác" eyebrow="Quan hệ" note="Trạng thái chung do Ban KHCN đánh giá; bấm để lọc.">
        <StageBar data={counts} unit="đối tác" selected={status} onSelect={label => setStatus(current => current === label ? '' : label)}/>
      </Panel>
      <Panel title="Đối tác có nhiều hoạt động nhất" eyebrow="Mức độ hợp tác" note="Tính cả hoạt động ký qua liên danh.">
        <BarChart data={top} unit="hoạt động" legend={[{ name: 'Đang POC / triển khai / vận hành', color: '#1c426f' }, { name: 'Khác', color: '#a3b8d4' }]}/>
      </Panel>
    </ChartGrid>
    <DashboardSection title="Danh sách đối tác" eyebrow="Chi tiết">
      <div className={styles.filters}>
        <label className="search-field"><Icon name="search"/><input aria-label="Tìm đối tác" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm tên, loại, quốc gia…"/></label>
        <select aria-label="Trạng thái hợp tác" value={status} onChange={event => setStatus(event.target.value)}><option value="">Tất cả trạng thái</option>{PARTNER_STATUSES.map(item => <option key={item}>{item}</option>)}</select>
      </div>
      <p className={styles.count}>{filtered.length} / {partners.length} đối tác</p>
      <div className="table-scroll" tabIndex={0} role="region" aria-label="Danh sách đối tác"><table><thead><tr><th>Đối tác</th><th>Trạng thái</th><th className={styles.numeric}>Tổng hoạt động</th><th>Đơn vị hợp tác</th><th>Hạng mục hợp tác</th></tr></thead>
        <tbody>{filtered.map(({ partner, activities, unitIds, itemIds }) => <tr key={partner.id}>
          <td><button className="record-name" onClick={() => onOpen(partner.id)}>{partner.title}</button><div className="record-meta">{[partner.partner_type, partner.country, consortia.some(group => group.member_ids.includes(partner.id)) ? `Liên danh: ${consortia.filter(group => group.member_ids.includes(partner.id)).map(group => group.title).join(', ')}` : null].filter(Boolean).join(' · ')}</div></td>
          <td><Badge>{partner.status}</Badge></td>
          <td className={styles.numeric}>{activities.length}</td>
          <td>{unitIds.length ? unitIds.map((id, index) => <span key={id}>{index > 0 && ', '}<button className="text-button" onClick={() => onOpen(id)}>{units.get(id)?.abbreviation || units.get(id)?.title}</button></span>) : '—'}</td>
          <td>{itemIds.length ? <ul className="cell-lines">{itemIds.map(id => <li key={id}><button className="text-button" onClick={() => onOpen(id)}>{standards.get(id) ? [standards.get(id)!.code, standards.get(id)!.title].filter(Boolean).join(' · ') : workItems.get(id)?.title}</button></li>)}</ul> : '—'}</td>
        </tr>)}</tbody></table></div>
    </DashboardSection>
  </div>;
}
