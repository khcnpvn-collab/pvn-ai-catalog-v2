"use client";
import { useState } from 'react';
import { byId, countBy, matchesSearch, type Overview } from '@/lib/overview';
import { DashboardSection, dashboardStyles as styles, KpiGrid } from './dashboard-primitives';
import { Badge, Icon } from './ui';

// Tab "Chuyên gia": a simple profile register with where each expert works.
export function ExpertDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState('');
  const units = byId(overview.units), partners = byId(overview.partners);
  const place = (expert: Overview['experts'][number]) => [...expert.unit_ids.map(id => units.get(id)?.title), ...expert.partner_ids.map(id => partners.get(id)?.title), expert.organization].filter(Boolean)[0] || '—';
  const experts = overview.experts.filter(expert => matchesSearch(query, expert.title, expert.organization, expert.current_position));
  const statuses = countBy(overview.experts, expert => expert.status);
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số chuyên gia" items={[
      { label: 'Chuyên gia', value: overview.experts.length, icon: 'user' },
      ...statuses.slice(0, 3).map(item => ({ label: item.label, value: item.value, icon: 'people' })),
    ]}/>
    <DashboardSection title="Danh sách chuyên gia" eyebrow="Chi tiết">
      <div className={styles.filters}><label className="search-field"><Icon name="search"/><input aria-label="Tìm chuyên gia" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm tên, nơi công tác…"/></label></div>
      <div className="table-scroll" tabIndex={0} role="region" aria-label="Danh sách chuyên gia"><table><thead><tr><th>Chuyên gia</th><th>Nơi công tác</th><th>Chức vụ</th><th>Trạng thái</th></tr></thead>
        <tbody>{experts.map(expert => <tr key={expert.id}><td><button className="record-name" onClick={() => onOpen(expert.id)}>{expert.title}</button></td><td>{place(expert)}</td><td>{expert.current_position || '—'}</td><td><Badge>{expert.status}</Badge></td></tr>)}</tbody></table></div>
    </DashboardSection>
  </div>;
}
