"use client";
import { useMemo, useState, type KeyboardEvent } from 'react';
import { moduleMap } from '@/lib/catalog';
import { matchesSearch, searchKey, type Overview } from '@/lib/overview';
import { Icon } from './ui';
import { useOverview } from './use-overview';

type Suggestion = { id: string; title: string; kind: string; detail?: string | null };

// Every record the overview already holds, labelled with its catalogue, so suggestions appear while typing.
function suggestionPool(overview: Overview): Suggestion[] {
  return [
    ...overview.standards.map(item => ({ id: item.id, title: item.title, kind: 'use_case', detail: item.code })),
    ...overview.work_items.map(item => ({ id: item.id, title: item.title, kind: 'work_item', detail: item.item_group })),
    ...overview.activities.map(item => ({ id: item.id, title: item.title, kind: 'collaboration', detail: item.status })),
    ...overview.partners.map(item => ({ id: item.id, title: item.title, kind: 'partner', detail: item.short_name })),
    ...overview.units.map(item => ({ id: item.id, title: item.title, kind: 'unit', detail: item.abbreviation })),
    ...overview.experts.map(item => ({ id: item.id, title: item.title, kind: 'expert', detail: item.organization })),
  ];
}

// Titles starting with the query come first, then any title or detail containing it.
function rank(pool: Suggestion[], query: string) {
  const key = searchKey(query).trim();
  return pool.filter(item => matchesSearch(query, item.title, item.detail))
    .sort((a, b) => Number(!searchKey(a.title).startsWith(key)) - Number(!searchKey(b.title).startsWith(key)) || a.title.localeCompare(b.title, 'vi'))
    .slice(0, 8);
}

export default function GlobalSearch({ initial, onOpen, onSearch }: { initial: string; onOpen: (id: string) => void; onSearch: (query: string) => void }) {
  const overview = useOverview();
  const [query, setQuery] = useState(initial);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const pool = useMemo(() => overview.data ? suggestionPool(overview.data) : [], [overview.data]);
  const matches = query.trim() ? rank(pool, query) : [];
  const showList = open && query.trim().length > 0;
  function choose(item: Suggestion) { setOpen(false); setQuery(''); onOpen(item.id); }
  function searchAll() { setOpen(false); onSearch(query.trim()); }
  function keyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === 'Escape') { setOpen(false); return; }
    if (!showList || !matches.length) return;
    if (event.key === 'ArrowDown') { event.preventDefault(); setActive(index => (index + 1) % matches.length); }
    if (event.key === 'ArrowUp') { event.preventDefault(); setActive(index => (index - 1 + matches.length) % matches.length); }
    if (event.key === 'Enter' && matches[active]) { event.preventDefault(); choose(matches[active]); }
  }
  return <form className="global-search" role="search" onSubmit={event => { event.preventDefault(); searchAll(); }}>
    <Icon name="search"/>
    <input name="q" role="combobox" aria-label="Tìm kiếm toàn bộ hồ sơ" aria-expanded={showList} aria-controls="global-search-list" aria-autocomplete="list"
      aria-activedescendant={showList && matches[active] ? `global-search-${matches[active].id}` : undefined} placeholder="Tìm hồ sơ…" autoComplete="off"
      value={query} onChange={event => { setQuery(event.target.value); setActive(0); setOpen(true); }} onFocus={() => setOpen(true)} onBlur={() => setOpen(false)} onKeyDown={keyDown}/>
    <button type="submit" className="icon-button" aria-label="Xem tất cả kết quả"><Icon name="arrow" size={16}/></button>
    {showList && <ul className="global-search-list" id="global-search-list" role="listbox" aria-label="Gợi ý hồ sơ">
      {matches.map((item, index) => <li key={item.id} id={`global-search-${item.id}`} role="option" aria-selected={index === active}
        onMouseDown={event => { event.preventDefault(); choose(item); }} onMouseEnter={() => setActive(index)}>
        <strong>{item.title}</strong><span>{[moduleMap[item.kind]?.label, item.detail].filter(Boolean).join(' · ')}</span>
      </li>)}
      {!matches.length && <li className="global-search-empty" role="presentation">{overview.data ? 'Không có gợi ý phù hợp' : 'Đang tải gợi ý…'}</li>}
      <li className="global-search-all" role="presentation" onMouseDown={event => { event.preventDefault(); searchAll(); }}>Xem tất cả kết quả cho “{query.trim()}”<Icon name="arrow" size={14}/></li>
    </ul>}
  </form>;
}
