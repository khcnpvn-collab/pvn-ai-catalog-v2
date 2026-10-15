"use client";
import { useRef, useState } from 'react';
import { Icon } from './ui';

export type AddOption = { label: string; onSelect: () => void };

// The one add button of a section: a single choice acts at once, several open a short menu to pick from.
export default function AddMenu({ options, label = 'Thêm', disabled }: { options: AddOption[]; label?: string; disabled?: boolean }) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  if (!options.length) return null;
  if (options.length === 1) return <button type="button" className="button small" disabled={disabled} onClick={options[0].onSelect}><Icon name="plus" size={16}/>{options[0].label}</button>;
  return <div className="add-menu" ref={root} onBlur={event => { if (!root.current?.contains(event.relatedTarget as Node | null)) setOpen(false); }}
    onKeyDown={event => { if (event.key === 'Escape' && open) { event.stopPropagation(); setOpen(false); } }}>
    <button type="button" className="button small" aria-haspopup="menu" aria-expanded={open} disabled={disabled} onClick={() => setOpen(!open)}><Icon name="plus" size={16}/>{label}</button>
    {open && <div className="add-menu-list" role="menu">{options.map(option => <button key={option.label} type="button" role="menuitem" onClick={() => { setOpen(false); option.onSelect(); }}>{option.label}</button>)}</div>}
  </div>;
}
