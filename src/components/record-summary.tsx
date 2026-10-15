"use client";
import { useEffect, useRef, useState } from 'react';
import { type Membership } from '@/lib/catalog';
import { type Dossier, type DossierSection as Section } from '@/lib/dossier';
import { summarySections } from '@/lib/dossier-summary';
import { Icon } from './ui';
import DossierSection from './dossier-section';
import RecordEditor from './record-editor';
import RecordFiles from './record-files';
import RecordHighlights from './record-highlights';
import RecordOverview from './record-overview';
import { invalidateOverview } from './use-overview';

export default function RecordSummary({ dossier, sections, writable, allowSurvey, onSection, onOpen, membership, onRefresh }: {
  dossier: Dossier; sections: Section[]; writable: boolean; allowSurvey: boolean;
  onSection: (section: string) => void; onOpen: (id: string) => void; membership: Membership; onRefresh: () => void;
}) {
  const [editingInformation, setEditingInformation] = useState(false);
  const [activeSection, setActiveSection] = useState('cv-information');
  const pinned = useRef(false);
  function scrollToSection(id: string) {
    setActiveSection(id);
    // Hold the clicked entry while the page scrolls to it, even if its top never reaches the observed band.
    pinned.current = true;
    window.setTimeout(() => { pinned.current = false; }, 800);
    const target = document.getElementById(id);
    target?.scrollIntoView({ block: 'start' });
    target?.focus({ preventScroll: true });
  }
  const record = dossier.data;
  const partner = record.kind === 'partner';
  const groups = summarySections(sections.filter(section => section.id !== 'references'), dossier.related);
  const sectionKey = groups.map(group => group.section.id).join();
  // Highlight the contents entry for the section crossing the upper part of the viewport.
  useEffect(() => {
    if (typeof IntersectionObserver === 'undefined') return;
    const observer = new IntersectionObserver(entries => {
      const entering = entries.filter(entry => entry.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (entering && !pinned.current) setActiveSection(entering.target.id);
    }, { rootMargin: '-15% 0px -70% 0px' });
    document.querySelectorAll('.cv-body > .cv-section').forEach(section => observer.observe(section));
    return () => observer.disconnect();
  }, [sectionKey, allowSurvey]);
  const contentsButton = (id: string, label: string, count?: number) => <button key={id} aria-current={activeSection === id ? 'true' : undefined} onClick={() => scrollToSection(id)}>{label}{count != null && <span>{count}</span>}</button>;
  return <div className="cv-dossier">
    <nav className="cv-contents" aria-label="Mục lục hồ sơ tổng hợp"><strong>Trong hồ sơ</strong>{contentsButton('cv-information', 'Thông tin chính')}{groups.map(({section, count}) => contentsButton(`cv-${section.id}`, section.label, count))}{contentsButton('cv-documents', 'File & tài liệu')}{allowSurvey && contentsButton('cv-survey', 'Kết quả khảo sát')}</nav>
    <div className="cv-body">
      <RecordHighlights record={record}/>
      <section tabIndex={-1} className="cv-section cv-introduction" id="cv-information" aria-labelledby="cv-information-title"><header className="cv-section-heading"><h2 id="cv-information-title">Thông tin chính</h2>{!editingInformation && <div className="cv-section-actions">{writable && <button className="button small" onClick={() => setEditingInformation(true)}><Icon name="edit" size={15}/>Chỉnh sửa</button>}</div>}</header>
        {/* The section heading already names the form; Hủy and Lưu close it. */}
        {editingInformation ? <RecordEditor kind={record.kind} record={record} embedded hideHeading onCancel={() => setEditingInformation(false)} onSave={() => { setEditingInformation(false); invalidateOverview(); onRefresh(); }}/>
          : <RecordOverview record={record} onSurvey={allowSurvey ? () => onSection('survey') : undefined}/>}
      </section>
      {groups.map(({section, count}) => <section tabIndex={-1} className="cv-section" id={`cv-${section.id}`} key={section.id} aria-label={section.label}>
        <DossierSection section={section} record={record} related={dossier.related} links={dossier.links} membership={membership} attachments={dossier.attachments} writable={writable} onOpen={onOpen} refresh={onRefresh} compactCount={count} previewLimit={partner ? undefined : 6} onShowAll={() => onSection(section.id)}/>
      </section>)}
      <section tabIndex={-1} className="cv-section" id="cv-documents"><RecordFiles dossier={dossier} membership={membership} onOpen={onOpen} onRefresh={onRefresh}/></section>
      {allowSurvey && <section tabIndex={-1} className="cv-section cv-survey" id="cv-survey"><div><h2>Kết quả khảo sát</h2><p className="muted">Tra cứu câu hỏi, câu trả lời và các bảng theo bản nguồn của đơn vị.</p></div><button className="button" onClick={() => onSection('survey')}>Xem phiếu khảo sát<Icon name="arrow" size={16}/></button></section>}
    </div>
  </div>;
}
