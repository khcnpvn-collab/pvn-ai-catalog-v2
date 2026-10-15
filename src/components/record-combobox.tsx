"use client";
import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react';
import { matchesSearch } from '@/lib/overview';
import { Icon } from './ui';

export type ComboOption = { id: string; label: string; detail?: string | null };
// Either an existing record or the title of one to create.
export type ComboChoice = ComboOption | { create: string };

// Type to filter a catalogue already loaded in the browser; pick a row, or create a new entry from the text.
export default function RecordCombobox({ label, options, value, onChange, placeholder, createLabel, hint }: {
  label: string; options: ComboOption[]; value: ComboChoice | null; onChange: (choice: ComboChoice | null) => void;
  placeholder?: string; createLabel?: string; hint?: string;
}) {
  const listId = useId();
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const text = query.trim();
  // Every match is listed; the list scrolls, so a long catalogue such as the 61 standard problems stays reachable.
  const matches = options.filter(option => matchesSearch(query, option.label, option.detail));
  const rows: ComboChoice[] = [...matches, ...(createLabel && text && !matches.some(option => option.label.toLocaleLowerCase('vi') === text.toLocaleLowerCase('vi')) ? [{ create: text }] : [])];
  const list = useRef<HTMLUListElement>(null);
  useEffect(() => { list.current?.querySelector('[aria-selected="true"]')?.scrollIntoView({ block: 'nearest' }); }, [active, open]);
  function choose(choice: ComboChoice) { onChange(choice); setQuery(''); setOpen(false); }
  function keyDown(event: KeyboardEvent<HTMLInputElement>) {
    // Escape closes the suggestions first; only a second Escape reaches the dialog around the form.
    if (event.key === 'Escape') { if (open && rows.length) { event.stopPropagation(); setOpen(false); } return; }
    if (!open || !rows.length) return;
    if (event.key === 'ArrowDown') { event.preventDefault(); setActive(index => (index + 1) % rows.length); }
    if (event.key === 'ArrowUp') { event.preventDefault(); setActive(index => (index - 1 + rows.length) % rows.length); }
    if (event.key === 'Enter') { event.preventDefault(); choose(rows[active]); }
  }
  if (value) return <div className="field"><span>{label}</span><div className="combo-chosen">
    <span>{'create' in value ? <><strong>{value.create}</strong><small>{createLabel} — tạo khi lưu</small></> : <><strong>{value.label}</strong>{value.detail && <small>{value.detail}</small>}</>}</span>
    <button type="button" className="text-button" onClick={() => onChange(null)}>Đổi</button>
  </div></div>;
  return <label className="field combo">{label}
    <span className="search-field"><Icon name="search"/><input role="combobox" aria-expanded={open && rows.length > 0} aria-controls={listId} aria-autocomplete="list" autoComplete="off"
      placeholder={placeholder} value={query} onChange={event => { setQuery(event.target.value); setActive(0); setOpen(true); }} onFocus={() => setOpen(true)} onBlur={() => setOpen(false)} onKeyDown={keyDown}/></span>
    {open && rows.length > 0 && <ul ref={list} className="combo-list" id={listId} role="listbox">{rows.map((row, index) => <li key={'create' in row ? 'create' : row.id} role="option" aria-selected={index === active}
      onMouseDown={event => { event.preventDefault(); choose(row); }} onMouseEnter={() => setActive(index)}>
      {'create' in row ? <strong className="combo-create"><Icon name="plus" size={14}/>{createLabel}: “{row.create}”</strong> : <><strong>{row.label}</strong>{row.detail && <span>{row.detail}</span>}</>}
    </li>)}</ul>}
    {hint && <small>{hint}</small>}
  </label>;
}
