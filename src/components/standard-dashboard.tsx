"use client";
import { ITEM_STATUSES, LEADERSHIP_LEVELS, PROGRAMS } from '@/lib/catalog';
import { rankIn, type QuickFilter, type TableFilter } from '@/lib/catalog-table';
import { activityCounts, itemActivities, itemPartnerIds, UNCLASSIFIED, type Overview, type OverviewStandard } from '@/lib/overview';
import { dayText, overviewMaps, partnerTerms, RecordLines, unitName, unitTerms } from './activity-cells';
import CatalogTable, { useTableState, type CatalogColumn } from './catalog-table';
import { BarChart, DashboardSection, OTHER_COLOR, Panel, PRIORITY_COLOR } from './dashboard-primitives';
import { Badge } from './ui';

// Tab "Bài toán" of the item catalogue: programme coverage, then the filterable list of standard problems.
export default function StandardTab({ overview, onOpen }: { overview: Overview; onOpen: (id: string) => void }) {
  const [table, setTable] = useTableState('standards');
  const program = table.filters.program || '';
  const maps = overviewMaps(overview);
  const standards = overview.standards;
  const activitiesOf = (standard: OverviewStandard) => itemActivities(overview, standard.id);
  const partnersOf = (standard: OverviewStandard) => itemPartnerIds(overview, standard.id);
  const partnerNames = (ids: string[]) => ids.map(id => maps.partners.get(id)?.short_name || maps.partners.get(id)?.title).filter(Boolean).join(', ');
  const byProgram = PROGRAMS.map(name => {
    const items = standards.filter(standard => standard.program === name);
    const priorityCount = items.filter(standard => standard.is_priority === 'Có').length;
    return { label: name, value: items.length, parts: [{ name: 'Ưu tiên', value: priorityCount, color: PRIORITY_COLOR }, { name: 'Chưa ưu tiên', value: items.length - priorityCount, color: OTHER_COLOR }] };
  });
  const columns: CatalogColumn<OverviewStandard>[] = [
    { key: 'code', label: 'Mã', text: standard => standard.code || '' },
    { key: 'title', label: 'Bài toán chuẩn', wide: true, text: standard => standard.title,
      render: standard => <><button className="record-name" onClick={() => onOpen(standard.id)}>{standard.title}</button>{standard.category && <div className="record-meta">{standard.category}</div>}{standard.is_priority === 'Có' && <Badge>Ưu tiên</Badge>}</> },
    { key: 'program', label: 'Chương trình', text: standard => standard.program || '' },
    { key: 'leadership', label: 'Mức dẫn dắt', text: standard => standard.leadership_level || '', sort: standard => rankIn(LEADERSHIP_LEVELS, standard.leadership_level) },
    { key: 'lead', label: 'Đầu mối ưu tiên', text: standard => unitName(maps, standard.lead_unit_id), search: standard => unitTerms(maps, [standard.lead_unit_id]),
      render: standard => standard.lead_unit_id ? <button className="text-button" onClick={() => onOpen(standard.lead_unit_id!)}>{unitName(maps, standard.lead_unit_id)}</button> : '—' },
    { key: 'potential', label: 'Đơn vị tiềm năng', text: standard => standard.potential_unit_ids.map(id => unitName(maps, id)).join(', '), sort: standard => standard.potential_unit_ids.length || null, search: standard => unitTerms(maps, standard.potential_unit_ids),
      render: standard => <RecordLines items={standard.potential_unit_ids.map(id => ({ id, label: unitName(maps, id) }))} onOpen={onOpen}/> },
    { key: 'status', label: 'Trạng thái', text: standard => standard.status, sort: standard => rankIn(ITEM_STATUSES, standard.status), render: standard => <Badge>{standard.status}</Badge> },
    { key: 'year', label: 'Năm', numeric: true, text: standard => standard.start_year ? String(standard.start_year) : '', sort: standard => standard.start_year },
    { key: 'activities', label: 'Hoạt động', numeric: true, text: standard => String(activitiesOf(standard).length), sort: standard => activitiesOf(standard).length,
      render: standard => { const counts = activityCounts(activitiesOf(standard)); return <>{counts.total}{counts.detail && <div className="record-meta">{counts.detail}</div>}</>; } },
    { key: 'partners', label: 'Đối tác (đã làm / tiềm năng)', text: standard => [partnerNames(partnersOf(standard)), standard.potential_partner_ids.length ? `Tiềm năng: ${partnerNames(standard.potential_partner_ids)}` : ''].filter(Boolean).join('; '),
      sort: standard => partnersOf(standard).length + standard.potential_partner_ids.length || null, search: standard => partnerTerms(maps, [...partnersOf(standard), ...standard.potential_partner_ids]),
      render: standard => <>{partnerNames(partnersOf(standard)) || '—'}{standard.potential_partner_ids.length > 0 && <div className="record-meta">Tiềm năng: {partnerNames(standard.potential_partner_ids)}</div>}</> },
    { key: 'updated', label: 'Cập nhật', text: standard => dayText(standard.updated_at), sort: standard => standard.updated_at },
  ];
  const filters: TableFilter<OverviewStandard>[] = [
    { key: 'program', label: 'Chương trình AI', all: 'Tất cả chương trình', values: standard => standard.program || UNCLASSIFIED, order: PROGRAMS },
    { key: 'priority', label: 'Ưu tiên', all: 'Ưu tiên và chưa ưu tiên', values: standard => standard.is_priority === 'Có' ? 'Thuộc danh mục ưu tiên' : 'Chưa ưu tiên' },
    { key: 'leadership', label: 'Mức dẫn dắt', all: 'Mọi mức dẫn dắt', values: standard => standard.leadership_level, order: LEADERSHIP_LEVELS },
    { key: 'status', label: 'Trạng thái', all: 'Tất cả trạng thái', values: standard => standard.status, order: ITEM_STATUSES },
    { key: 'year', label: 'Năm dự kiến', all: 'Mọi năm', values: standard => standard.start_year ? String(standard.start_year) : null },
  ];
  const quick: QuickFilter<OverviewStandard>[] = [
    { key: 'no_activity', label: 'Chưa có hoạt động', test: standard => !activitiesOf(standard).length },
    { key: 'no_lead', label: 'Chưa có đầu mối', test: standard => !standard.lead_unit_id },
    { key: 'no_partner', label: 'Chưa có đối tác', test: standard => !partnersOf(standard).length && !standard.potential_partner_ids.length },
  ];
  return <>
    <Panel title="Bài toán chuẩn theo chương trình" eyebrow="Độ phủ" note="Bấm vào một chương trình để lọc danh sách.">
      <BarChart data={byProgram} unit="bài toán" selected={program || undefined} onSelect={label => setTable({ ...table, filters: { ...table.filters, program: program === label ? '' : label } })}
        legend={[{ name: 'Ưu tiên', color: PRIORITY_COLOR }, { name: 'Chưa ưu tiên', color: OTHER_COLOR }]}/>
    </Panel>
    <DashboardSection title="Danh mục bài toán chuẩn" eyebrow="Chi tiết">
      <CatalogTable label="Danh mục bài toán chuẩn" unit="bài toán chuẩn" rows={standards} columns={columns} filters={filters} quick={quick} state={table} onState={setTable}
        exportName="bai-toan-chuan" searchPlaceholder="Tìm bài toán, mã, đơn vị (tên hoặc viết tắt), đối tác…"/>
    </DashboardSection>
  </>;
}
