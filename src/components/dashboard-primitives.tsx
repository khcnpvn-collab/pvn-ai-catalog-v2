"use client";
import type { ReactNode } from 'react';
import type { Count } from '@/lib/overview';
import { statusColor } from '@/lib/status-tone';
import { Icon } from './ui';
import styles from './module-dashboard.module.css';

// One navy hue for magnitude; lifecycle stages use the shared status colours.
export const BAR_COLOR = '#1c426f';
export const stageColor = statusColor;
export const PRIORITY_COLOR = statusColor('Ưu tiên');
export const OTHER_COLOR = '#c9d6e8';

export type Kpi = { label: string; value: number; caption?: string; icon?: string; onClick?: () => void; pressed?: boolean };
export function KpiGrid({ items, label }: { items: Kpi[]; label: string }) {
  return <section className={styles.kpiGrid} aria-label={label}>{items.map(item => {
    const body = <><span className={styles.kpiLabel}>{item.label}{item.icon && <span className={styles.kpiIcon}><Icon name={item.icon} size={17}/></span>}</span>
      <strong className={styles.kpiValue}>{item.value.toLocaleString('vi-VN')}</strong>{item.caption && <span className={styles.kpiCaption}>{item.caption}</span>}</>;
    return item.onClick ? <button key={item.label} type="button" className={styles.kpiCard} aria-pressed={item.pressed} onClick={item.onClick}>{body}</button> : <div key={item.label} className={styles.kpiCard}>{body}</div>;
  })}</section>;
}

export function Panel({ title, eyebrow, note, wide = false, action, children }: { title: string; eyebrow?: string; note?: string; wide?: boolean; action?: ReactNode; children: ReactNode }) {
  return <figure className={`${styles.panel}${wide ? ` ${styles.panelWide}` : ''}`}>
    <figcaption className={styles.panelHeading}><div>{eyebrow && <p className={styles.eyebrow}>{eyebrow}</p>}<h2>{title}</h2></div>{action}</figcaption>
    {children}{note && <p className={styles.note}>{note}</p>}
  </figure>;
}

export function ChartGrid({ children }: { children: ReactNode }) { return <div className={styles.chartGrid}>{children}</div>; }

export type BarDatum = Count & { parts?: { value: number; color: string; name: string }[] };
// Horizontal bars, value printed at the end; rows filter the list below when onSelect is given.
export function BarChart({ data, unit, onSelect, selected, legend }: { data: BarDatum[]; unit: string; onSelect?: (label: string) => void; selected?: string; legend?: { name: string; color: string }[] }) {
  const max = Math.max(1, ...data.map(item => item.value));
  if (!data.length) return <p className="muted">Chưa có dữ liệu.</p>;
  return <>
    <ul className={styles.bars}>{data.map(item => {
      const parts = item.parts || [{ value: item.value, color: BAR_COLOR, name: unit }];
      const detail = parts.length > 1 ? ` (${parts.map(part => `${part.name}: ${part.value}`).join(', ')})` : '';
      const content = <><span className={styles.barLabel}>{item.label}</span>
        <span className={styles.barTrack} aria-hidden="true">{parts.filter(part => part.value > 0).map(part => <span key={part.name} className={styles.barSegment} style={{ width: `${(part.value / max) * 100}%`, background: part.color }}/>)}</span>
        <span className={styles.barValue}>{item.value.toLocaleString('vi-VN')}</span></>;
      const label = `${item.label}: ${item.value} ${unit}${detail}`;
      return <li key={item.label}>{onSelect
        ? <button type="button" className={styles.barRow} title={label} aria-label={`${label}. Lọc danh sách`} aria-pressed={selected === item.label} onClick={() => onSelect(item.label)}>{content}</button>
        : <div className={styles.barRow} title={label} aria-label={label} role="group">{content}</div>}</li>;
    })}</ul>
    {legend && <ul className={styles.legend}>{legend.map(item => <li key={item.name}><span className={styles.swatch} style={{ background: item.color }}/>{item.name}</li>)}</ul>}
  </>;
}

// A single stacked bar for an ordered distribution, with a legend that doubles as the table of values.
export function StageBar({ data, unit, onSelect, selected }: { data: Count[]; unit: string; onSelect?: (label: string) => void; selected?: string }) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  if (!total) return <p className="muted">Chưa có dữ liệu.</p>;
  const percent = (value: number) => `${Math.round((value / total) * 100)}%`;
  return <>
    <div className={styles.stage} role="img" aria-label={data.map(item => `${item.label}: ${item.value} ${unit}`).join('; ')}>
      {data.filter(item => item.value > 0).map(item => <span key={item.label} title={`${item.label}: ${item.value} ${unit} (${percent(item.value)})`} style={{ width: `${(item.value / total) * 100}%`, background: stageColor(item.label) }}/>)}
    </div>
    <ul className={styles.legend}>{data.map(item => {
      const content = <><span className={styles.swatch} style={{ background: stageColor(item.label) }}/>{item.label}<span className={styles.legendValue}>{item.value} · {percent(item.value)}</span></>;
      return <li key={item.label}>{onSelect ? <button type="button" className={styles.legendButton} aria-pressed={selected === item.label} onClick={() => onSelect(item.label)}>{content}</button> : content}</li>;
    })}</ul>
  </>;
}

export function FilterNote({ label, onClear }: { label: string; onClear: () => void }) {
  return <span className={styles.filterNote}>Đang lọc: <strong>{label}</strong><button type="button" className="text-button" onClick={onClear}>Bỏ lọc</button></span>;
}

export function DashboardSection({ title, eyebrow, children }: { title: string; eyebrow?: string; children: ReactNode }) {
  return <section className={styles.panel} aria-label={title}><div className={styles.panelHeading}><div>{eyebrow && <p className={styles.eyebrow}>{eyebrow}</p>}<h2>{title}</h2></div></div>{children}</section>;
}

export { styles as dashboardStyles };

// Tabs above a catalogue list, one per item group, each with its record count.
export function GroupTabs({ groups, active, counts, onChange, label }: { groups: string[]; active: string; counts: Record<string, number>; onChange: (group: string) => void; label: string }) {
  return <div className={styles.groupTabs} role="tablist" aria-label={label}>{groups.map(group =>
    <button key={group} type="button" role="tab" aria-selected={group === active} className={styles.groupTab} onClick={() => onChange(group)}>
      {group}<span className={styles.groupTabCount}>{counts[group] || 0}</span></button>)}</div>;
}
