"use client";
import type { QuickFilter, TableFilter } from '@/lib/catalog-table';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { DashboardSection, dashboardStyles as styles, KpiGrid } from './dashboard-primitives';
import { Badge, ErrorBox, Loading, useResource } from './ui';

type Organisation = { id: string; kind: 'unit' | 'partner'; title: string; short: string | null };
type Person = { id: string; title: string; status: string; position: string | null; email: string | null; phone: string | null; orgs: Organisation[] };
type Contact = Person & { role: string | null; department: string | null; is_primary: string | null; work_status: string | null };
type Expert = Person & { organization: string | null; expertise_summary: string | null };
type Directory = { contacts: Contact[]; experts: Expert[] };
type Row = { id: string; name: string; group: string; primary: boolean; expert: boolean; orgs: Organisation[]; organization: string | null; job: string; email: string; phone: string; note: string };

const GROUPS = ['Đầu mối đơn vị', 'Đầu mối đối tác', 'Chuyên gia', 'Chưa gắn đơn vị / đối tác'];
const clean = (value: string | null | undefined) => (value || '').trim();

function rows(directory: Directory): Row[] {
  const contacts = directory.contacts.map(contact => ({
    id: contact.id, name: contact.title, expert: false, primary: contact.is_primary === 'Có', orgs: contact.orgs, organization: null,
    group: contact.orgs.some(org => org.kind === 'unit') ? GROUPS[0] : contact.orgs.length ? GROUPS[1] : GROUPS[3],
    job: [contact.role, contact.position, contact.department].map(clean).filter(Boolean).join(' · '), email: clean(contact.email), phone: clean(contact.phone),
    note: clean(contact.work_status) && contact.work_status !== 'Đang công tác' ? clean(contact.work_status) : '' }));
  const experts = directory.experts.map(expert => ({
    id: expert.id, name: expert.title, expert: true, primary: false, orgs: expert.orgs, organization: expert.organization, group: GROUPS[2],
    job: clean(expert.position), email: clean(expert.email), phone: clean(expert.phone), note: '' }));
  return [...contacts, ...experts];
}

// "Danh bạ": every person to reach in one searchable table — contacts of units and partners, and experts.
// Contacts are edited on their unit or partner page; the name of an expert opens the expert profile.
export default function DirectoryPage({ onOpen }: { onOpen: (id: string) => void }) {
  const resource = useResource<{ data: Directory }>('/api/directory');
  const [table, setTable] = useTableState('directory');
  const group = table.filters.group || '';
  const setGroup = (next: string) => setTable({ ...table, filters: { ...table.filters, group: group === next ? '' : next } });
  const list = resource.data ? rows(resource.data.data) : [];
  const orgText = (row: Row) => row.orgs.map(org => org.short || org.title).join(', ') || clean(row.organization);
  const columns: CatalogColumn<Row>[] = [
    { key: 'name', label: 'Họ tên', text: row => row.name,
      render: row => <>{row.expert ? <button className="record-name" onClick={() => onOpen(row.id)}>{row.name}</button> : <strong>{row.name}</strong>}{row.primary && <Badge>Đầu mối chính</Badge>}{row.note && <div className="record-meta">{row.note}</div>}</> },
    { key: 'group', label: 'Nhóm', text: row => row.group },
    { key: 'org', label: 'Đơn vị / đối tác', text: orgText, search: row => row.orgs.flatMap(org => [org.title, org.short]),
      render: row => row.orgs.length ? <ul className="cell-lines">{row.orgs.map(org => <li key={org.id}><button className="text-button" title={org.title} onClick={() => onOpen(org.id)}>{org.short || org.title}</button></li>)}</ul> : clean(row.organization) || '—' },
    { key: 'job', label: 'Chức danh / vai trò', text: row => row.job, render: row => row.job ? <div className={styles.clamp} title={row.job}>{row.job}</div> : '—' },
    { key: 'email', label: 'Email', text: row => row.email, render: row => row.email ? <a href={`mailto:${row.email}`}>{row.email}</a> : '—' },
    { key: 'phone', label: 'Điện thoại', text: row => row.phone, render: row => row.phone ? <a href={`tel:${row.phone.replace(/[^+\d]/g, '')}`}>{row.phone}</a> : '—' },
  ];
  const filters: TableFilter<Row>[] = [{ key: 'group', label: 'Nhóm', all: 'Tất cả nhóm', values: row => row.group, order: GROUPS }];
  const quick: QuickFilter<Row>[] = [
    { key: 'primary', label: 'Đầu mối chính', test: row => row.primary },
    { key: 'no_email', label: 'Chưa có email', test: row => !row.email },
    { key: 'no_phone', label: 'Chưa có điện thoại', test: row => !row.phone },
  ];
  const count = (name: string) => list.filter(row => row.group === name).length;
  return <div className="catalog-list">
    <section className="catalog-banner"><div className="catalog-banner-copy"><h1>Danh bạ</h1><p>Đầu mối của đơn vị, đối tác và chuyên gia trong một bảng để tìm nhanh. Thêm hoặc sửa đầu mối ngay trên trang đơn vị, đối tác hoặc chuyên gia.</p></div></section>
    {resource.error && !resource.data ? <ErrorBox error={resource.error} retry={resource.refresh}/> : !resource.data ? <Loading label="Đang tải danh bạ…"/> : <div className={styles.dashboard}>
      <KpiGrid label="Chỉ số danh bạ" items={[
        { label: 'Đầu mối đơn vị', value: count(GROUPS[0]), caption: 'Bấm để lọc', icon: 'building', onClick: () => setGroup(GROUPS[0]), pressed: group === GROUPS[0] },
        { label: 'Đầu mối đối tác', value: count(GROUPS[1]), caption: 'Bấm để lọc', icon: 'people', onClick: () => setGroup(GROUPS[1]), pressed: group === GROUPS[1] },
        { label: 'Chuyên gia', value: count(GROUPS[2]), caption: 'Bấm để lọc', icon: 'user', onClick: () => setGroup(GROUPS[2]), pressed: group === GROUPS[2] },
        { label: 'Chưa gắn đơn vị / đối tác', value: count(GROUPS[3]), caption: 'Đầu mối chưa thuộc đâu — bấm để lọc', icon: 'link', onClick: () => setGroup(GROUPS[3]), pressed: group === GROUPS[3] },
      ]}/>
      <DashboardSection title="Danh bạ đầu mối" eyebrow="Tra cứu">
        <CatalogTable label="Danh bạ đầu mối" unit="người" rows={list} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
          exportName="danh-ba" searchPlaceholder="Tìm tên, đơn vị / đối tác (tên hoặc viết tắt), chức danh, email, điện thoại…"/>
      </DashboardSection>
    </div>}
  </div>;
}
