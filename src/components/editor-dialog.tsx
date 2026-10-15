"use client";

import { useEffect, useRef, type KeyboardEvent as ReactKeyboardEvent, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { confirmDiscardChanges, hasUnsavedChanges, Icon } from './ui';

export default function EditorDialog({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  const trigger = useRef<HTMLElement | null>(null);
  const dialog = useRef<HTMLElement>(null);
  const close = useRef(onClose);
  // Escape, the backdrop and the close button all ask before discarding input typed into the dialog.
  useEffect(() => { close.current = () => { if (confirmDiscardChanges(hasUnsavedChanges(dialog.current))) onClose(); }; }, [onClose]);
  useEffect(() => {
    trigger.current = document.activeElement as HTMLElement;
    const oldOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    const firstField = dialog.current?.querySelector<HTMLElement>('input:not([disabled]), textarea:not([disabled]), select:not([disabled])');
    (firstField || dialog.current?.querySelector<HTMLElement>('button'))?.focus();
    const escape = (event: KeyboardEvent) => { if (event.key === 'Escape') { event.preventDefault(); close.current(); } };
    document.addEventListener('keydown', escape);
    return () => { document.body.style.overflow = oldOverflow; document.removeEventListener('keydown', escape); trigger.current?.focus(); };
  }, []);
  function trapFocus(event: ReactKeyboardEvent<HTMLElement>) {
    if (event.key !== 'Tab') return;
    const focusable = [...(dialog.current?.querySelectorAll<HTMLElement>('button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), a[href]') || [])];
    if (!focusable.length) return;
    const first = focusable[0], last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
  }
  return createPortal(<div className="record-modal-backdrop" onMouseDown={event => { if (event.target === event.currentTarget) close.current(); }}>
    <section ref={dialog} className="record-modal" role="dialog" aria-modal="true" aria-label={title} onKeyDown={trapFocus}>
      <header className="record-modal-heading"><h2>{title}</h2><button className="icon-button" type="button" onClick={() => close.current()} aria-label="Đóng biểu mẫu"><Icon name="close"/></button></header>
      <div className="record-modal-body">{children}</div>
    </section>
  </div>, document.body);
}
