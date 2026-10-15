"use client";
import RecordCombobox, { type ComboOption } from './record-combobox';
import { Icon } from './ui';

// Several records from a loaded catalogue: search and pick one at a time, each choice becomes a removable chip.
export default function MultiRecordPicker({ label, options, value, onChange, placeholder, hint }: {
  label: string; options: ComboOption[]; value: ComboOption[]; onChange: (value: ComboOption[]) => void; placeholder?: string; hint?: string;
}) {
  const chosen = new Set(value.map(item => item.id));
  return <div className="field full multi-record-field">
    <RecordCombobox label={label} options={options.filter(option => !chosen.has(option.id))} value={null} placeholder={placeholder} hint={hint}
      onChange={choice => { if (choice && 'id' in choice) onChange([...value, choice]); }}/>
    {value.length > 0 && <div className="tag-input multi-record-chips">{value.map(item => <span className="tag-chip" key={item.id}>{item.label}
      <button type="button" aria-label={`Bỏ ${item.label}`} onClick={() => onChange(value.filter(other => other.id !== item.id))}><Icon name="close" size={13}/></button></span>)}</div>}
  </div>;
}
