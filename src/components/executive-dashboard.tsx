"use client";

import type { CSSProperties } from "react";
import { moduleMap, type CatalogRecord } from "@/lib/catalog";
import { date, Empty, ErrorBox, Heading, Icon, Loading, useResource } from "./ui";
import styles from "./executive-dashboard.module.css";

type DashboardKind = "partner" | "collaboration" | "expert" | "use_case";
type ChartKind = "unit" | DashboardKind;
type StatsResult = { data: { counts: Record<string, number> } };
type RecordResult = { data: CatalogRecord[]; total: number; page: number; pageSize: number };
type DashboardProps = {
  canWrite: boolean;
  onCreate: (kind: string) => void;
  onOpenModule: (kind: string) => void;
  onOpenRecord: (id: string) => void;
};
type LatestBlockProps = Pick<DashboardProps, "onOpenModule" | "onOpenRecord"> & { kind: DashboardKind };

const kpis: ReadonlyArray<{ kind: DashboardKind; label: string; icon: string; caption: string }> = [
  { kind: "partner", label: "Đối tác", icon: "building", caption: "Kết nối & năng lực" },
  { kind: "collaboration", label: "Triển khai & hợp tác", icon: "link", caption: "Bài toán đơn vị, POC, hợp tác" },
  { kind: "expert", label: "Chuyên gia", icon: "user", caption: "Tri thức chuyên sâu" },
  { kind: "use_case", label: "Bài toán chuẩn", icon: "spark", caption: "7 chương trình AI" },
];
const chartSeries: ReadonlyArray<{ kind: ChartKind; label: string }> = [
  { kind: "unit", label: "Đơn vị" },
  { kind: "partner", label: "Đối tác" },
  { kind: "expert", label: "Chuyên gia" },
  { kind: "use_case", label: "Bài toán chuẩn" },
  { kind: "collaboration", label: "Hoạt động" },
];

function LatestBlock({ kind, onOpenModule, onOpenRecord }: LatestBlockProps) {
  const moduleEntry = moduleMap[kind];
  const resource = useResource<RecordResult>(`/api/records?kind=${kind}&page=1`);
  const records = resource.data?.data.slice(0, 3) ?? [];
  const partner = kind === "partner";

  return (
    <section className={`${styles.latestBlock} ${partner ? styles.partnerBlock : styles.editorialBlock}`} aria-labelledby={`latest-${kind}`}>
      <header className={styles.blockHeading}>
        <div>
          <p className={styles.eyebrow}>{partner ? "Kết nối gần đây" : "Mới cập nhật"}</p>
          <h2 id={`latest-${kind}`}>{moduleEntry.label}</h2>
        </div>
        {partner && <button className="text-button" type="button" onClick={() => onOpenModule(kind)}>Xem danh mục<Icon name="arrow" size={16}/></button>}
      </header>
      <div className={styles.latestContent}>
        {resource.loading ? <Loading label={`Đang tải ${moduleEntry.label.toLocaleLowerCase("vi-VN")}…`}/> : resource.error ? (
          <ErrorBox error={resource.error} retry={resource.refresh}/>
        ) : records.length > 0 ? (
          <ul className={styles.recordList}>
            {records.map(record => (
              <li key={record.id}>
                <button className={styles.recordLink} type="button" onClick={() => onOpenRecord(record.id)}>
                  {partner && <span className={styles.recordAvatar} aria-hidden="true">{record.title.trim().split(/\s+/).slice(0, 2).map(word => word[0]).join("").toLocaleUpperCase("vi-VN")}</span>}
                  <span className={styles.recordText}>
                    <strong>{record.title}</strong>
                    <span className={styles.recordDate}>Cập nhật <time dateTime={record.updated_at}>{date(record.updated_at)}</time></span>
                  </span>
                  <Icon name="arrow" size={16}/>
                </button>
              </li>
            ))}
          </ul>
        ) : <Empty title={`Chưa có ${moduleEntry.singular}`} text="Dữ liệu sẽ xuất hiện tại đây khi hồ sơ được bổ sung."/>}
      </div>
      {!partner && <button className={`text-button ${styles.blockLink}`} type="button" onClick={() => onOpenModule(kind)}>Xem tất cả<span className="sr-only"> {moduleEntry.label.toLocaleLowerCase("vi-VN")}</span><Icon name="arrow" size={16}/></button>}
    </section>
  );
}

export default function ExecutiveDashboard({ canWrite, onCreate, onOpenModule, onOpenRecord }: DashboardProps) {
  const stats = useResource<StatsResult>("/api/stats");
  const counts = stats.data?.data.counts;
  const chartMax = counts ? Math.max(1, ...chartSeries.map(item => counts[item.kind] ?? 0)) : 1;

  return (
    <div className={styles.dashboard}>
      <Heading title="Tổng quan" description="Một góc nhìn kết nối toàn bộ không gian AI."/>
      <section className={styles.hero} aria-labelledby="dashboard-hero-title">
        <span className={styles.heroIndex}>ENERGY × INTELLIGENCE</span>
        <div className={styles.heroCopy}>
          <p className={styles.eyebrow}>Kết nối tri thức · Mở rộng giá trị</p>
          <h2 id="dashboard-hero-title">Năng lượng mới.<br/>Từ những kết nối mới.</h2>
          <p>Không gian chung của đối tác, chuyên gia và các ứng dụng AI trong hệ sinh thái Petrovietnam.</p>
          <div className="actions">
            <button className={`button ${styles.heroPrimary}`} type="button" onClick={() => onOpenModule("partner")}>Khám phá đối tác<Icon name="arrow" size={16}/></button>
            <button className={`button ${styles.heroSecondary}`} type="button" onClick={() => onOpenModule("use_case")}>Bài toán chuẩn</button>
          </div>
        </div>
        <span className={styles.heroCredit}>HÌNH ẢNH Ý TƯỞNG ĐƯỢC TẠO BẰNG AI</span>
      </section>

      <section className={styles.metrics} aria-labelledby="dashboard-metrics-title">
        <h2 id="dashboard-metrics-title" className="sr-only">Chỉ số danh mục trọng tâm</h2>
        {stats.loading ? <Loading label="Đang tải số liệu điều hành…"/> : stats.error ? <ErrorBox error={stats.error} retry={stats.refresh}/> : counts ? (
          <div className={styles.kpiGrid}>
            {kpis.map(item => (
              <button className={styles.kpiCard} key={item.kind} type="button" onClick={() => onOpenModule(item.kind)} aria-label={`${item.label}: ${(counts[item.kind] ?? 0).toLocaleString("vi-VN")}. Mở danh mục.`}>
                <span className={styles.kpiLabel}>{item.label}<span className={styles.metricIcon}><Icon name={item.icon}/></span></span>
                <span className={styles.metricValue}><strong>{(counts[item.kind] ?? 0).toLocaleString("vi-VN")}</strong><span>hồ sơ</span></span>
                <span className={styles.kpiAction}>{item.caption}<Icon name="arrow" size={16}/></span>
              </button>
            ))}
          </div>
        ) : null}
      </section>

      <div className={styles.dashboardGrid}>
        <LatestBlock kind="partner" onOpenModule={onOpenModule} onOpenRecord={onOpenRecord}/>
        <figure className={styles.chart} aria-labelledby="catalog-composition-title">
          <figcaption className={styles.chartHeading}><div><p className={styles.eyebrow}>Bức tranh chung</p><h2 id="catalog-composition-title">Cơ cấu danh mục trọng tâm</h2></div><Icon name="database"/></figcaption>
          {stats.loading ? <Loading label="Đang tải cơ cấu danh mục…"/> : stats.error ? <ErrorBox error={stats.error} retry={stats.refresh}/> : counts ? (
            <ul className={styles.barList}>
              {chartSeries.map(item => {
                const value = counts[item.kind] ?? 0;
                const barStyle = { "--bar-size": `${(value / chartMax) * 100}%` } as CSSProperties;
                return <li key={item.kind} aria-label={`${item.label}: ${value.toLocaleString("vi-VN")} hồ sơ`}><span className={styles.barLabel}>{item.label}</span><span className={styles.barTrack} aria-hidden="true"><span className={styles.barFill} style={barStyle}/></span><strong>{value.toLocaleString("vi-VN")}</strong></li>;
              })}
            </ul>
          ) : null}
          <p className={styles.chartNote}>Số hồ sơ hiện hành có thể xem theo từng danh mục.</p>
        </figure>
      </div>

      <section className={styles.latest} aria-labelledby="latest-records-title">
        <header className={styles.latestHeading}><div><p className={styles.eyebrow}>Tri thức đang được kết nối</p><h2 id="latest-records-title">Khám phá gần đây</h2></div>{canWrite && <button className="text-button" type="button" onClick={() => onCreate("partner")}><Icon name="plus" size={16}/>Thêm đối tác</button>}</header>
        <div className={styles.latestGrid}>{kpis.filter(item => item.kind !== "partner").map(item => <LatestBlock key={item.kind} kind={item.kind} onOpenModule={onOpenModule} onOpenRecord={onOpenRecord}/>)}</div>
      </section>
      <div className={styles.sourceNote}><Icon name="shield" size={16}/><p>Số liệu tổng hợp từ hồ sơ hiện hành theo quyền truy cập. Bản nguồn khảo sát chỉ xuất hiện trong danh mục sau khi được đối soát và bổ sung.</p></div>
    </div>
  );
}
