"use client";
import { useState } from 'react';
import { APPLY_SCOPES, ITEM_STATUSES, SCOPE_LEVELS } from '@/lib/catalog';
import { activityCounts, byId, itemActivities, matchesSearch, type Overview } from '@/lib/overview';
import { DashboardSection, dashboardStyles as styles } from './dashboard-primitives';
import { Badge, date, Icon } from './ui';

// One tab of the item catalogue for a work item group: who leads it, where it applies and its activities.
export default function WorkItemList({ group, overview, onOpen }: { group: string; overview: Overview; onOpen: (id: string) => void }) {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('');
  const [level, setLevel] = useState('');
  const [scope, setScope] = useState('');
  const units = byId(overview.units);
  const items = overview.work_items.filter(item => item.item_group === group);
  const filtered = items.filter(item => (!status || item.status === status) && (!level || item.scope_level === level) && (!scope || item.apply_scope === scope)
    && matchesSearch(query, item.title, item.owner, item.coordinator));
  const applies = (item: Overview['work_items'][number]) => item.apply_scope === 'Đơn vị cụ thể'
    ? item.unit_ids.map(id => units.get(id)?.abbreviation || units.get(id)?.title).filter(Boolean).join(', ') || 'Đơn vị cụ thể (chưa chọn)'
    : item.apply_scope || '—';
  return <DashboardSection title={`Hạng mục — ${group}`} eyebrow="Chi tiết">
    <div className={styles.filters}>
      <label className="search-field"><Icon name="search"/><input aria-label="Tìm hạng mục" value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm tên, đầu mối, phối hợp…"/></label>
      <select aria-label="Phân loại" value={level} onChange={event => setLevel(event.target.value)}><option value="">Tập đoàn và đơn vị</option>{SCOPE_LEVELS.map(item => <option key={item}>{item}</option>)}</select>
      <select aria-label="Ưu tiên áp dụng" value={scope} onChange={event => setScope(event.target.value)}><option value="">Mọi phạm vi áp dụng</option>{APPLY_SCOPES.map(item => <option key={item}>{item}</option>)}</select>
      <select aria-label="Trạng thái" value={status} onChange={event => setStatus(event.target.value)}><option value="">Tất cả trạng thái</option>{ITEM_STATUSES.map(item => <option key={item}>{item}</option>)}</select>
    </div>
    <p className={styles.count}>{filtered.length} / {items.length} hạng mục</p>
    {items.length ? <div className="table-scroll" tabIndex={0} role="region" aria-label={`Hạng mục ${group}`}><table><thead><tr><th>Hạng mục</th><th>Phân loại</th><th>Ưu tiên áp dụng</th><th>Đầu mối / phối hợp</th><th>Bắt đầu</th><th>Trạng thái</th><th className={styles.numeric}>Hoạt động</th></tr></thead>
      <tbody>{filtered.map(item => {
        const counts = activityCounts(itemActivities(overview, item.id));
        return <tr key={item.id}>
          <td><button className="record-name" onClick={() => onOpen(item.id)}>{item.title}</button></td>
          <td>{item.scope_level || '—'}</td>
          <td>{applies(item)}</td>
          <td>{item.owner || '—'}{item.coordinator && <div className="record-meta">Phối hợp: {item.coordinator}</div>}</td>
          <td>{item.start_date ? date(item.start_date) : '—'}</td>
          <td><Badge>{item.status}</Badge></td>
          <td className={styles.numeric}>{counts.total}{counts.detail && <div className="record-meta">{counts.detail}</div>}</td>
        </tr>;
      })}</tbody></table></div> : <p className="related-group-empty">Chưa có hạng mục trong nhóm này. Bấm “Thêm hạng mục” để nhập.</p>}
  </DashboardSection>;
}
