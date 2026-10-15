"use client";
import { moduleMap } from '@/lib/catalog';
import type { Overview } from '@/lib/overview';
import ActivityDashboard from './activity-dashboard';
import { ExpertDashboard } from './capability-dashboards';
import PartnerDashboard from './partner-dashboard';
import ItemCatalogDashboard from './item-catalog-dashboard';
import UnitDashboard from './unit-dashboard';
import { ErrorBox, Icon, Loading } from './ui';
import { useOverview } from './use-overview';

type View = (props: { overview: Overview; onOpen: (id: string) => void; canWrite?: boolean; onCreate?: (kind: string, preset?: Record<string, string>) => void }) => React.JSX.Element;
const views: Record<string, View> = { use_case: ItemCatalogDashboard, collaboration: ActivityDashboard, partner: PartnerDashboard, unit: UnitDashboard, expert: ExpertDashboard };
export const dashboardKinds = new Set(Object.keys(views));

// Each main tab opens with figures and charts, then its detailed, filterable list.
// The standard problem tab opens the whole item catalogue, whose add buttons follow the group tab.
const banners: Record<string, { title: string; description: string }> = {
  use_case: { title: 'Danh mục hạng mục', description: 'Bài toán chuẩn và các hạng mục về nền tảng, dữ liệu, quản trị AI, nhân lực và ký kết hợp tác; mỗi hạng mục gom các hoạt động triển khai.' },
};

export default function ModuleDashboard({ kind, canWrite, onOpen, onCreate }: { kind: string; canWrite: boolean; onOpen: (id: string) => void; onCreate: (kind: string, preset?: Record<string, string>) => void }) {
  const overview = useOverview();
  const mod = moduleMap[kind];
  const View = views[kind];
  const banner = banners[kind];
  return <div className="catalog-list">
    <section className="catalog-banner"><div className="catalog-banner-copy"><h1>{banner?.title || mod.label}</h1><p>{banner?.description || mod.description}</p></div>
      <div className="catalog-banner-side">{canWrite && !banner && <button className="button primary" onClick={() => onCreate(kind)}><Icon name="plus"/>Thêm {mod.singular}</button>}</div></section>
    {overview.data ? <View overview={overview.data} onOpen={onOpen} canWrite={canWrite} onCreate={onCreate}/> : overview.error ? <ErrorBox error={overview.error} retry={overview.refresh}/> : <Loading label="Đang tổng hợp số liệu…"/>}
  </div>;
}
