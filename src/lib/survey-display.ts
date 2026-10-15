import capturedSchema from '../data/survey-display-schema.json';

export type SurveyDisplayField = { k?: string; label: string; type: string; columns?: SurveyDisplayField[]; group?: string; noDataLabel?: string };
export type SurveyDisplayQuestion = {
  id: string; label: string; type: string; unit?: string; rows?: string[];
  cols?: SurveyDisplayField[]; fields?: SurveyDisplayField[]; scaleLabels?: string[];
  attach?: boolean; rowLabel?: string; noDataLabel?: string;
};
export type SurveyDisplaySection = { id: string; title: string; partTitle: string; questions: SurveyDisplayQuestion[] };
export type SurveyAnswerNode =
  | { type: 'text' | 'empty'; text: string }
  | { type: 'list'; items: SurveyAnswerNode[]; ordered?: boolean }
  | { type: 'fields'; fields: { label: string; value: SurveyAnswerNode }[] }
  | { type: 'table'; columns: string[]; rows: SurveyAnswerNode[][] }
  | { type: 'cards'; cards: { title: string; value: SurveyAnswerNode }[] };
export type SurveyAnswerSection = Omit<SurveyDisplaySection, 'questions'> & {
  questions: { id: string; label: string; answer: SurveyAnswerNode }[];
};
export type SurveySnapshot = {
  id: string; title: string; unit_code: string | null; created_at: string;
  payload: { answers?: Record<string, unknown>; status?: string; updated_at?: string | null; schema_version?: unknown; [key: string]: unknown };
};

export const surveyDisplaySchemaVersion = capturedSchema.schemaVersion;
export const surveyDisplaySections = capturedSchema.sections as SurveyDisplaySection[];
const EMPTY_KEY = '__confirmedEmpty';
const empty = (): SurveyAnswerNode => ({ type: 'empty', text: 'Chưa có câu trả lời' });
const text = (value: string): SurveyAnswerNode => value.trim() ? { type: 'text', text: value } : empty();
const object = (value: unknown): value is Record<string, unknown> => Boolean(value && typeof value === 'object' && !Array.isArray(value));
const own = (value: Record<string, unknown>, key: string) => Object.hasOwn(value, key);
// File locators are never presentation values, including unfamiliar/legacy objects.
const privateKey = (key: string) => /^(?:path|storage_?path|full_?path|bucket(?:_id)?|signed_?url|download_?url|public_?url|url|uri)$/i.test(key);
const visibleKeys = (value: Record<string, unknown>) => Object.keys(value).filter(key => !privateKey(key));
const fallbackLabel = (key: string) => key === EMPTY_KEY ? 'Xác nhận không có dữ liệu' : key === '_files' ? 'Tệp đính kèm' : key;

function fileName(value: unknown): string {
  const candidate = typeof value === 'string' ? value : object(value) ? [value.name, value.filename, value.fileName].find(item => typeof item === 'string') : undefined;
  if (typeof candidate !== 'string' || !candidate.trim()) return 'Tệp đính kèm chưa ghi tên';
  // Legacy strings sometimes contain a locator. Display its basename only.
  const isLocator = /[\\/]/.test(candidate) || /^[a-z]+:/i.test(candidate);
  const name = isLocator ? candidate.split(/[?#]/)[0].split(/[\\/]/).at(-1) || '' : candidate;
  return name || 'Tệp đính kèm chưa ghi tên';
}
function attachments(value: unknown): SurveyAnswerNode {
  if (value == null || (Array.isArray(value) && !value.length)) return empty();
  return { type: 'list', items: (Array.isArray(value) ? value : [value]).map(file => text(fileName(file))) };
}
function fileObject(value: Record<string, unknown>) {
  const hasLocator = Object.keys(value).some(privateKey);
  const hasName = ['name', 'filename', 'fileName'].some(key => own(value, key));
  const metadataOnly = Object.keys(value).every(key => privateKey(key) || ['name', 'filename', 'fileName', 'size', 'type', 'mime_type', 'uploadedAt', 'created_at'].includes(key));
  return (hasName && (hasLocator || own(value, 'uploadedAt') || (own(value, 'size') && own(value, 'type')))) ||
    (hasLocator && metadataOnly);
}
function extraFields(value: Record<string, unknown>, known: string[]) {
  return visibleKeys(value).filter(key => !known.includes(key)).map(key => ({
    label: fallbackLabel(key), value: key === '_files' ? attachments(value[key]) : generic(value[key]),
  }));
}

/** Read unfamiliar values without dropping fields or exposing file locators. */
function generic(value: unknown): SurveyAnswerNode {
  if (value == null) return empty();
  if (typeof value === 'string') return text(value);
  if (typeof value === 'boolean') return text(value ? 'Có' : 'Không');
  if (typeof value === 'number') return text(String(value));
  if (Array.isArray(value)) return value.length ? { type: 'list', items: value.map(generic) } : empty();
  if (!object(value)) return empty();
  if (fileObject(value)) return text(fileName(value));
  if (own(value, 'sel') || own(value, 'other')) {
    const fields = [];
    if (own(value, 'sel')) fields.push({ label: 'Lựa chọn', value: generic(value.sel) });
    if (own(value, 'other')) fields.push({ label: 'Nội dung khác', value: generic(value.other) });
    fields.push(...extraFields(value, ['sel', 'other']));
    return { type: 'fields', fields };
  }
  const fields = extraFields(value, []);
  return fields.length ? { type: 'fields', fields } : empty();
}
function fieldValue(field: SurveyDisplayField, value: unknown): SurveyAnswerNode {
  if (field.type === 'grouptable') return rowsTable(value, field.columns || []);
  if (field.type === 'partners') return rowsTable(value, [
    { k: 'ten', label: 'Tên đối tác', type: 'text' },
    { k: 'trangthai', label: 'Tình trạng hợp tác', type: 'text' },
  ]);
  return generic(value);
}
function labeledFields(value: unknown, fields: SurveyDisplayField[]): SurveyAnswerNode {
  if (!object(value)) return generic(value);
  return { type: 'fields', fields: [
    ...fields.map(field => ({ label: field.label, value: fieldValue(field, value[field.k || '']) })),
    ...extraFields(value, fields.map(field => field.k || '')),
  ] };
}
function rowsTable(value: unknown, fields: SurveyDisplayField[]): SurveyAnswerNode {
  if (!Array.isArray(value)) return generic(value);
  if (!value.length) return empty();
  const markerRows = value.filter(row => object(row) && own(row, EMPTY_KEY));
  const rows = value.filter(row => !object(row) || !own(row, EMPTY_KEY) || visibleKeys(row).some(key => key !== EMPTY_KEY));
  if (!rows.length) return generic(markerRows);
  const known = fields.map(field => field.k || '');
  const extras = [...new Set(rows.flatMap(row => object(row) ? visibleKeys(row).filter(key => !known.includes(key) && key !== EMPTY_KEY) : []))];
  const hasPrimitive = rows.some(row => !object(row));
  const table: SurveyAnswerNode = { type: 'table', columns: [
    'STT', ...fields.map(field => field.label), ...extras.map(fallbackLabel), ...(hasPrimitive ? ['Nội dung bổ sung'] : []),
  ], rows: rows.map((row, index) => [
    text(String(index + 1)),
    ...fields.map(field => object(row) ? fieldValue(field, row[field.k || '']) : empty()),
    ...extras.map(key => object(row) ? key === '_files' ? attachments(row[key]) : generic(row[key]) : empty()),
    ...(hasPrimitive ? [object(row) ? empty() : generic(row)] : []),
  ]) };
  return markerRows.length ? { type: 'list', items: [generic(markerRows.map(row => ({ [EMPTY_KEY]: (row as Record<string, unknown>)[EMPTY_KEY] }))), table] } : table;
}

export function formatSurveyAnswer(question: SurveyDisplayQuestion, value: unknown): SurveyAnswerNode {
  if (question.type === 'grid') return rowsTable(value, question.cols || []);
  if (question.type === 'keycards') {
    if (!object(value)) return generic(value);
    const cards = visibleKeys(value).filter(key => key !== EMPTY_KEY).map(title => ({ title, value: labeledFields(value[title], question.fields || []) }));
    const nodes: SurveyAnswerNode[] = [];
    if (own(value, EMPTY_KEY)) nodes.push(generic({ [EMPTY_KEY]: value[EMPTY_KEY] }));
    if (cards.length) nodes.push({ type: 'cards', cards });
    return nodes.length === 1 ? nodes[0] : nodes.length ? { type: 'list', items: nodes } : empty();
  }
  if (question.type === 'matrix' || question.type === 'rating') {
    if (value != null && !object(value) && !Array.isArray(value)) return generic(value);
    const values = (value ?? {}) as Record<string, unknown>;
    const labels = question.rows || [];
    const keys = [...labels.map((_, index) => String(index)), ...Object.keys(values).filter(key => !labels.some((_, index) => key === String(index)) && !privateKey(key))];
    const cols = question.cols || [];
    const matrixExtras = question.type === 'matrix' ? [...new Set(keys.flatMap(key => object(values[key]) ? visibleKeys(values[key]).filter(cell => cell !== '_files' && !cols.some((_, index) => cell === String(index))) : []))] : [];
    const hasFiles = question.attach || keys.some(key => object(values[key]) && own(values[key], '_files'));
    const hasUnstructured = keys.some(key => values[key] != null && !object(values[key]));
    const table: SurveyAnswerNode = { type: 'table', columns: question.type === 'rating'
      ? ['Nhận định', 'Mức đơn vị lựa chọn']
      : ['Nội dung', ...cols.map(col => col.label), ...matrixExtras.map(fallbackLabel), ...(hasFiles ? ['Tệp đính kèm'] : []), ...(hasUnstructured ? ['Nội dung bổ sung'] : [])],
    rows: keys.map(key => {
      const label = labels[Number(key)] ?? `Dòng bổ sung (${key})`;
      const row = values[key];
      if (question.type === 'rating') {
        const score = typeof row === 'number' ? row : typeof row === 'string' && /^\d+$/.test(row) ? Number(row) : NaN;
        const scale = Number.isInteger(score) && score > 0 ? question.scaleLabels?.[score - 1] : undefined;
        return [text(label), scale ? text(scale) : generic(row)];
      }
      return [text(label), ...cols.map((_, index) => object(row) ? generic(row[String(index)]) : empty()),
        ...matrixExtras.map(extra => object(row) ? generic(row[extra]) : empty()),
        ...(hasFiles ? [object(row) ? attachments(row._files) : empty()] : []),
        ...(hasUnstructured ? [object(row) || row == null ? empty() : generic(row)] : [])];
    }) };
    return keys.length ? table : empty();
  }
  if (question.type === 'ranking' && Array.isArray(value)) return value.length ? { type: 'list', items: value.map(generic), ordered: true } : empty();
  if (question.unit && (typeof value === 'number' || (typeof value === 'string' && value.trim()))) return text(`${value} ${question.unit}`);
  return generic(value);
}

export function surveyAnswerText(node: SurveyAnswerNode): string {
  switch (node.type) {
    case 'text': case 'empty': return node.text;
    case 'list': return node.items.map(surveyAnswerText).join('\n');
    case 'fields': return node.fields.map(field => `${field.label}: ${surveyAnswerText(field.value)}`).join('\n');
    case 'table': return [node.columns.join(' · '), ...node.rows.map(row => row.map(surveyAnswerText).join(' · '))].join('\n');
    case 'cards': return node.cards.map(card => `${card.title}\n${surveyAnswerText(card.value)}`).join('\n');
  }
}
export function buildSurveySections(answers: Record<string, unknown>, schemaVersion?: unknown): SurveyAnswerSection[] {
  const currentLabels = schemaVersion === undefined || String(schemaVersion) === String(surveyDisplaySchemaVersion);
  const sections = surveyDisplaySections.map(section => ({ ...section, questions: section.questions.map(question => ({
    id: question.id, label: question.label, answer: !currentLabels && ['matrix', 'rating'].includes(question.type)
      ? generic(answers[question.id])
      : formatSurveyAnswer(question, answers[question.id]),
  })) }));
  const known = new Set(surveyDisplaySections.flatMap(section => section.questions.map(question => question.id)));
  const extra = Object.keys(answers).filter(key => !known.has(key) && key !== '__surveySchemaVersion' && !privateKey(key));
  if (extra.length) sections.push({ id: 'additional', title: 'Thông tin bổ sung trong bản nguồn', partTitle: 'Nội dung ngoài các câu hỏi hiện hành', questions: extra.map(id => ({
    id, label: `Thông tin bổ sung (${id})`, answer: id === '_files' ? attachments(answers[id]) : generic(answers[id]),
  })) });
  return sections;
}
export function filterSurveySections(sections: SurveyAnswerSection[], query: string, sectionId = ''): SurveyAnswerSection[] {
  const normalize = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLocaleLowerCase('vi');
  const search = normalize(query.trim());
  return sections.filter(section => !sectionId || section.id === sectionId).map(section => ({ ...section, questions: section.questions.filter(question => !search || normalize(`${section.partTitle} ${section.title} ${question.label} ${surveyAnswerText(question.answer)}`).includes(search)) })).filter(section => section.questions.length);
}
