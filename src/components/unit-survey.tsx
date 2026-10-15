"use client";

import { useMemo, useState } from 'react';
import { buildSurveySections, filterSurveySections, surveyDisplaySchemaVersion, type SurveyAnswerNode, type SurveySnapshot } from '@/lib/survey-display';
import { Empty, ErrorBox, Icon, Loading, useResource } from './ui';
import styles from './unit-survey.module.css';

function sourceDate(value: string | null | undefined): string {
  if (!value) return 'Không ghi thời điểm';
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? value : parsed.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh', dateStyle: 'short', timeStyle: 'short' });
}

export function SurveyAnswer({ answer }: { answer: SurveyAnswerNode }) {
  switch (answer.type) {
    case 'text': return <span className={styles.text}>{answer.text}</span>;
    case 'empty': return <span className={styles.empty}>{answer.text}</span>;
    case 'list': {
      const List = answer.ordered ? 'ol' : 'ul';
      return <List className={styles.list}>{answer.items.map((item, index) => <li key={index}><SurveyAnswer answer={item}/></li>)}</List>;
    }
    case 'fields': return <dl className={styles.fields}>{answer.fields.map((field, index) => <div key={index}><dt>{field.label}</dt><dd><SurveyAnswer answer={field.value}/></dd></div>)}</dl>;
    case 'cards': return <div className={styles.cards}>{answer.cards.map((card, index) => <section className={styles.card} key={index}><h4>{card.title}</h4><SurveyAnswer answer={card.value}/></section>)}</div>;
    case 'table': return <div className={styles.tableScroll} role="region" tabIndex={0} aria-label="Bảng chi tiết câu trả lời, cuộn ngang để xem đủ cột"><table className={styles.answerTable}><thead><tr>{answer.columns.map((column, index) => <th scope="col" key={index}>{column}</th>)}</tr></thead><tbody>{answer.rows.map((row, index) => <tr key={index}>{row.map((cell, cellIndex) => <td key={cellIndex}><SurveyAnswer answer={cell}/></td>)}</tr>)}</tbody></table></div>;
  }
}

export default function UnitSurvey({ recordId }: { recordId: string }) {
  const resource = useResource<{ data: SurveySnapshot[] }>(`/api/records/${recordId}/survey`);
  const [selectedId, setSelectedId] = useState('');
  const [query, setQuery] = useState('');
  const [sectionId, setSectionId] = useState('');
  const snapshots = resource.data?.data;
  const snapshot = snapshots?.find(item => item.id === selectedId) || snapshots?.[0];
  const sections = useMemo(() => snapshot ? buildSurveySections(snapshot.payload.answers || {}, snapshot.payload.schema_version ?? null) : [], [snapshot]);
  const filtered = useMemo(() => filterSurveySections(sections, query, sectionId), [sections, query, sectionId]);
  const questionCount = filtered.reduce((count, section) => count + section.questions.length, 0);
  const versionMismatch = snapshot && String(snapshot.payload.schema_version) !== String(surveyDisplaySchemaVersion);
  const status = snapshot?.payload.status;
  const statusLabel = status ? ({ notstarted: 'Chưa bắt đầu', draft: 'Bản nháp', submitted: 'Đã gửi' } as Record<string, string>)[status] || status : null;

  return <div className={styles.survey}>
    <header className={styles.heading}><h2>Chi tiết phiếu khảo sát</h2><p>Tra cứu nguyên văn nội dung đơn vị đã khai báo trong bản nguồn được liên kết với hồ sơ này.</p></header>
    {resource.loading ? <Loading label="Đang tải phiếu khảo sát…"/> : resource.error ? <ErrorBox error={resource.error} retry={resource.refresh}/> : !snapshot ? <Empty title="Chưa có bản khảo sát được liên kết" text="Chưa có bản nguồn khảo sát được đối soát và gắn với hồ sơ đơn vị này."/> : <>
      <div className={styles.source}>
        {snapshots && snapshots.length > 1 && <label className="field">Chọn bản khảo sát<select value={snapshot.id} onChange={event => { setSelectedId(event.target.value); setSectionId(''); }}>
          {snapshots.map((item, index) => <option value={item.id} key={item.id}>{index === 0 ? 'Phiếu cập nhật mới nhất · ' : ''}{sourceDate(item.created_at)} · Phiếu cập nhật {sourceDate(item.payload.updated_at)}</option>)}
        </select></label>}
        <p className={styles.sourceTitle}>Phiếu khảo sát tại thời điểm cập nhật: <strong>{sourceDate(snapshot.payload.updated_at)}</strong></p>
        <p className={styles.sourceMeta}>Bản nguồn tiếp nhận: {sourceDate(snapshot.created_at)}{statusLabel && <> · {statusLabel}</>}{snapshot.unit_code && <> · Đơn vị {snapshot.unit_code}</>}</p>
        <p className={styles.sourceNote}>Nội dung chỉ đọc tại thời điểm đơn vị khai báo. Tệp đính kèm chỉ hiện tên; xem các tệp đã có trong kho tại vùng File & tài liệu.</p>
        {versionMismatch && <p className={styles.sourceNote}>Bản nguồn dùng mẫu khảo sát khác hoặc chưa ghi phiên bản. Các bảng đánh giá giữ chỉ mục nguyên gốc để tránh gán nhầm nhãn dòng và cột.</p>}
      </div>
      <div className={styles.toolbar}>
        <label className={styles.search}><Icon name="search"/><input aria-label="Tìm trong phiếu khảo sát" type="search" placeholder="Tìm câu hỏi hoặc nội dung trả lời…" value={query} onChange={event => setQuery(event.target.value)}/></label>
        <label className={styles.sectionFilter}><span>Lọc theo mục</span><select aria-label="Lọc mục khảo sát" value={sectionId} onChange={event => setSectionId(event.target.value)}><option value="">Tất cả mục</option>{sections.map(section => <option value={section.id} key={section.id}>{section.title}</option>)}</select></label>
      </div>
      <p className={styles.count} role="status">{questionCount} câu hỏi / nội dung{query || sectionId ? ' phù hợp' : ''}</p>
      {filtered.length ? <div className={styles.sections}>{filtered.map(section => <section className={styles.section} key={section.id}>
        <header className={styles.sectionHeading}><p>{section.partTitle}</p><h3>{section.title}</h3></header>
        <table className={styles.questionTable}><thead><tr><th scope="col">Câu hỏi</th><th scope="col">Nội dung đơn vị khai báo</th></tr></thead><tbody>{section.questions.map(question => <tr key={question.id}>
          <th scope="row">{question.label}</th><td><SurveyAnswer answer={question.answer}/></td>
        </tr>)}</tbody></table>
      </section>)}</div> : <Empty title="Không có nội dung phù hợp" text="Thử từ khóa khác hoặc chọn tất cả mục khảo sát."/>}
    </>}
  </div>;
}
