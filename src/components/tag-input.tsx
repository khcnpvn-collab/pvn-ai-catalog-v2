"use client";
import { useId, useState, type KeyboardEvent } from "react";
import { joinTags, splitTags } from "@/lib/catalog";
import { Icon } from "./ui";

// Several labels in one field: pick a tag already used elsewhere or type a new one and press Enter.
// A new tag is saved with the record and is offered to every later form.
export default function TagInput({ label, value, suggestions, onChange, hint }: { label: string; value: string; suggestions: string[]; onChange: (value: string) => void; hint?: string }) {
  const listId = useId();
  const [draft, setDraft] = useState("");
  const tags = splitTags(value);
  const add = (tag: string) => { if (tag.trim()) onChange(joinTags([...tags, tag])); setDraft(""); };
  const remove = (tag: string) => onChange(joinTags(tags.filter(item => item !== tag)));
  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Enter" || event.key === ";" || event.key === ",") { event.preventDefault(); add(draft); }
    else if (event.key === "Backspace" && !draft && tags.length) remove(tags[tags.length - 1]);
  };
  const options = suggestions.filter(tag => !tags.includes(tag));
  return <div className="field full tag-field"><span>{label}</span>
    <div className="tag-input">
      {tags.map(tag => <span className="tag-chip" key={tag}>{tag}<button type="button" aria-label={`Bỏ tag ${tag}`} onClick={() => remove(tag)}><Icon name="close" size={13}/></button></span>)}
      <input list={listId} value={draft} aria-label={label} placeholder={tags.length ? "Thêm tag…" : "Chọn hoặc gõ tag mới…"}
        onChange={event => { const next = event.target.value; if (options.includes(next)) add(next); else setDraft(next); }}
        onKeyDown={onKeyDown} onBlur={() => add(draft)}/>
      <datalist id={listId}>{options.map(tag => <option key={tag} value={tag}/>)}</datalist>
    </div>
    {hint && <small>{hint}</small>}
  </div>;
}
