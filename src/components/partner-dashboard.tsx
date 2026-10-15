"use client";
import { COUNTRIES, PARTNER_STATUSES, PARTNER_TYPES, splitTags, STRATEGIC_LEVELS } from '@/lib/catalog';
import { daysSince, rankIn, type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { countBy, distinct, isActiveActivity, isConsortium, latestMilestone, milestoneDate, partnerActivities, type Overview } from '@/lib/overview';
import { dayText, overviewMaps, RecordLines, unitName, unitTerms } from './activity-cells';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { BarChart, ChartGrid, DashboardSection, dashboardStyles as styles, KpiGrid, Panel, StageBar } from './dashboard-primitives';
import { Badge } from './ui';

const QUIET_DAYS = 180;

// Tab "Đối tác": overall relationship status, who we work with most, and what each partner has done.
export default function PartnerDashboard({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [table, setTable] = useTableState('partners');
  const status = table.filters.status || '';
  const setStatus = (next: string) => setTable({ ...table, filters: { ...table.filters, status: next } });
  const maps = overviewMaps(overview);
  // Consortia are groups of partners: counted apart, never listed as partners.
  const partners = overview.partners.filter(partner => !isConsortium(partner));
  const consortia = overview.partners.filter(isConsortium);
  const rows = partners.map(partner => {
    const activities = partnerActivities(overview, partner.id);
    const milestone = latestMilestone(overview.milestones.filter(item => item.partner_ids.includes(partner.id)));
    return { id: partner.id, partner, activities, active: activities.filter(activity => isActiveActivity(activity.status)).length,
      // PVN units and items met through this partner's activities.
      unitIds: distinct(activities.flatMap(activity => activity.unit_ids)), itemIds: distinct(activities.map(activity => activity.standard_id || activity.work_item_id)),
      groups: consortia.filter(group => group.member_ids.includes(partner.id)).map(group => group.title),
      lastWork: [milestone ? milestoneDate(milestone) : '', ...activities.map(activity => activity.last_meeting_date || '')].filter(Boolean).sort().at(-1) || '' };
  });
  type Row = typeof rows[number];
  const itemLabel = (id: string) => { const standard = maps.standards.get(id); return standard ? [standard.code, standard.title].filter(Boolean).join(' · ') : maps.workItems.get(id)?.title || ''; };
  const tags = (row: Row) => splitTags(row.partner.specialties);
  const top = [...rows].filter(row => row.activities.length).sort((a, b) => b.activities.length - a.activities.length || a.partner.title.localeCompare(b.partner.title, 'vi')).slice(0, 10)
    .map(row => ({ label: row.partner.title, value: row.activities.length, parts: [{ name: 'Đang chạy', value: row.active, color: '#1c426f' }, { name: 'Khác', value: row.activities.length - row.active, color: '#a3b8d4' }] }));
  const counts = countBy(partners, partner => partner.status, PARTNER_STATUSES);
  const count = (label: string) => counts.find(item => item.label === label)?.value || 0;
  const columns: CatalogColumn<Row>[] = [
    { key: 'title', label: 'Đối tác', wide: true, text: row => row.partner.title, search: row => [row.partner.short_name, row.partner.partner_type, row.partner.country, ...row.groups],
      render: row => <><button className="record-name" onClick={() => onOpen(row.id)}>{row.partner.title}</button><div className="record-meta">{[row.partner.partner_type, row.partner.country, row.groups.length ? `Liên danh: ${row.groups.join(', ')}` : null].filter(Boolean).join(' · ')}</div></> },
    { key: 'status', label: 'Trạng thái', text: row => row.partner.status, sort: row => rankIn(PARTNER_STATUSES, row.partner.status), render: row => <Badge>{row.partner.status}</Badge> },
    { key: 'strategic', label: 'Hợp tác chiến lược', text: row => row.partner.strategic_level || '', sort: row => rankIn(STRATEGIC_LEVELS, row.partner.strategic_level) },
    { key: 'specialties', label: 'Năng lực', text: row => tags(row).join(', '), sort: row => tags(row).length || null,
      render: row => tags(row).length ? <div className={styles.clamp} title={tags(row).join(', ')}>{tags(row).join(', ')}</div> : '—' },
    { key: 'contact', label: 'Đầu mối liên hệ', text: row => row.partner.contact_name || '',
      render: row => row.partner.contact_name ? <>{row.partner.contact_name}{(row.partner.contact_count || 0) > 1 && <div className="record-meta">{row.partner.contact_count} đầu mối</div>}</> : '—' },
    { key: 'activities', label: 'Tổng hoạt động', numeric: true, text: row => String(row.activities.length), sort: row => row.activities.length,
      render: row => <>{row.activities.length}{row.active > 0 && <div className="record-meta">{row.active} đang chạy</div>}</> },
    { key: 'units', label: 'Đơn vị hợp tác', text: row => row.unitIds.map(id => unitName(maps, id)).join(', '), sort: row => row.unitIds.length || null, search: row => unitTerms(maps, row.unitIds),
      render: row => row.unitIds.length ? row.unitIds.map((id, index) => <span key={id}>{index > 0 && ', '}<button className="text-button" onClick={() => onOpen(id)}>{unitName(maps, id)}</button></span>) : '—' },
    { key: 'items', label: 'Hạng mục hợp tác', wide: true, text: row => row.itemIds.map(itemLabel).join('; '), sort: row => row.itemIds.length || null,
      render: row => <RecordLines items={row.itemIds.map(id => ({ id, label: itemLabel(id) }))} onOpen={onOpen}/> },
    { key: 'last_work', label: 'Làm việc gần nhất', text: row => dayText(row.lastWork), sort: row => row.lastWork },
    { key: 'updated', label: 'Cập nhật', text: row => dayText(row.partner.updated_at), sort: row => row.partner.updated_at },
  ];
  const filters: TableFilter<Row>[] = [
    { key: 'status', label: 'Trạng thái hợp tác', all: 'Tất cả trạng thái', values: row => row.partner.status, order: PARTNER_STATUSES },
    { key: 'type', label: 'Loại đối tác', all: 'Mọi loại đối tác', values: row => row.partner.partner_type, order: PARTNER_TYPES },
    { key: 'country', label: 'Quốc gia', all: 'Mọi quốc gia', values: row => row.partner.country, order: COUNTRIES },
    { key: 'strategic', label: 'Hợp tác chiến lược', all: 'Mọi mức hợp tác chiến lược', values: row => row.partner.strategic_level, order: STRATEGIC_LEVELS },
    { key: 'specialty', label: 'Năng lực', all: 'Mọi năng lực', values: tags },
  ];
  const quick: QuickFilter<Row>[] = [
    { key: 'no_activity', label: 'Chưa có hoạt động', test: row => !row.activities.length },
    { key: 'no_contact', label: 'Chưa có đầu mối liên hệ', test: row => !row.partner.contact_count },
    { key: 'quiet', label: 'Không làm việc trên 6 tháng', test: row => (daysSince(row.lastWork) ?? Infinity) > QUIET_DAYS },
  ];
  return <div className={styles.dashboard}>
    <KpiGrid label="Chỉ số đối tác" items={[
      { label: 'Đối tác', value: partners.length, caption: `${rows.filter(row => row.activities.length).length} đối tác có hoạt động`, icon: 'people', onClick: () => setStatus(''), pressed: !status },
      { label: 'Đang hợp tác', value: count('Đang hợp tác'), caption: `${partners.filter(partner => partner.strategic_level && partner.strategic_level !== 'Không').length} có MOU / hợp tác chiến lược — bấm để lọc`, icon: 'check', onClick: () => setStatus(status === 'Đang hợp tác' ? '' : 'Đang hợp tác'), pressed: status === 'Đang hợp tác' },
      { label: 'Tiềm năng', value: count('Tiềm năng'), caption: 'Bấm để lọc', icon: 'spark', onClick: () => setStatus(status === 'Tiềm năng' ? '' : 'Tiềm năng'), pressed: status === 'Tiềm năng' },
      { label: 'Liên danh', value: consortia.length, caption: `${new Set(consortia.flatMap(group => group.member_ids)).size} đối tác tham gia liên danh`, icon: 'link' },
    ]}/>
    <ChartGrid>
      <Panel title="Đối tác theo trạng thái hợp tác" eyebrow="Quan hệ" note="Trạng thái chung do Ban KHCN đánh giá; bấm để lọc.">
        <StageBar data={counts} unit="đối tác" selected={status} onSelect={label => setStatus(status === label ? '' : label)}/>
      </Panel>
      <Panel title="Đối tác có nhiều hoạt động nhất" eyebrow="Mức độ hợp tác" note="Tính cả hoạt động ký qua liên danh.">
        <BarChart data={top} unit="hoạt động" legend={[{ name: 'Đang POC / triển khai / vận hành', color: '#1c426f' }, { name: 'Khác', color: '#a3b8d4' }]}/>
      </Panel>
    </ChartGrid>
    <DashboardSection title="Danh sách đối tác" eyebrow="Chi tiết">
      <CatalogTable label="Danh sách đối tác" unit="đối tác" rows={rows} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
        exportName="doi-tac" searchPlaceholder="Tìm đối tác, năng lực, đầu mối, đơn vị (tên hoặc viết tắt), hạng mục…"/>
    </DashboardSection>
  </div>;
}
