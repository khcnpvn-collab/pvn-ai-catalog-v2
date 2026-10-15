import { test, expect } from '@playwright/test';
import { buildSurveySections, filterSurveySections, formatSurveyAnswer, surveyAnswerText, surveyDisplaySections, type SurveyDisplayQuestion } from '../src/lib/survey-display';

const question = (id: string): SurveyDisplayQuestion => {
  const result = surveyDisplaySections.flatMap(section => section.questions).find(entry => entry.id === id);
  if (!result) throw new Error(`Missing source schema question: ${id}`);
  return result;
};
const answerText = (id: string, value: unknown) => surveyAnswerText(formatSurveyAnswer(question(id), value));

test('matrix positional answers use the original row and column labels', () => {
  const node = formatSurveyAnswer(question('c3_infra'), { '0': { '0': 'Có', '1': 'Đã có/đang sử dụng', '2': 'Nội dung chi tiết' } });
  expect(node.type).toBe('table');
  if (node.type !== 'table') throw new Error('Expected structured matrix');
  expect(node.columns).toEqual(expect.arrayContaining(['Nhu cầu', 'Mức độ sẵn sàng tại đơn vị']));
  expect(surveyAnswerText(node.rows[0][0])).toBe(question('c3_infra').rows![0]);
  expect(surveyAnswerText(node.rows[0][1])).toBe('Có');
  expect(surveyAnswerText(node.rows[0][2])).toBe('Đã có/đang sử dụng');
  expect(surveyAnswerText(node.rows[1][1])).toBe('Chưa có câu trả lời');
});

test('matrix unfamiliar row and column answers stay visible without pretending to be known labels', () => {
  const text = answerText('c3_infra', { '0': { '9': 'Future column answer', note: 'Legacy cell note' }, '99': { '0': 'Future row answer' } });
  expect(text).toContain('Future column answer');
  expect(text).toContain('Legacy cell note');
  expect(text).toContain('Dòng bổ sung (99)');
  expect(text).toContain('Future row answer');
});

test('ratings map one-based numeric scores to labels and retain out-of-range values', () => {
  const labels = question('b3_rating').scaleLabels!;
  const text = answerText('b3_rating', { '0': 1, '1': '4', '2': 0, '3': 9 });
  expect(text).toContain(labels[0]);
  expect(text).toContain(labels[3]);
  expect(text).toContain(' · 0');
  expect(text).toContain(' · 9');
});

test('keycards preserve named use cases and nested data and partner tables', () => {
  const node = formatSurveyAnswer(question('c1_key'), {
    'Bảo trì thiết bị': {
      mota: 'Phát hiện bất thường\nTheo từng ca vận hành',
      dulieunhom: [{ nhomdulieu: 'Dữ liệu cảm biến', hethongnguon: 'Hệ thống SCADA', truongdulieuchinh: 'Nhiệt độ', sansangdulieu: 'Chưa đánh giá' }],
      doitac: [{ ten: 'Đối tác A', trangthai: 'PoC' }],
      field_in_future_schema: 'Thông tin bổ sung nguyên gốc',
    },
  });
  expect(node.type).toBe('cards');
  const text = surveyAnswerText(node);
  for (const value of ['Bảo trì thiết bị', 'Mô tả bài toán', 'Phát hiện bất thường\nTheo từng ca vận hành', 'Nhóm dữ liệu đầu vào sử dụng', 'Dữ liệu cảm biến', 'Hệ thống hoặc CSDL nguồn', 'Hệ thống SCADA', 'Tên đối tác', 'Đối tác A', 'PoC', 'Thông tin bổ sung nguyên gốc']) expect(text).toContain(value);
});

test('grid keeps duplicate answer rows, unknown fields and primitive legacy rows', () => {
  const node = formatSurveyAnswer(question('a1_contact'), [{ name: 'Nguyễn A', phone: '00123', custom: 'Nội dung cũ' }, { name: 'Nguyễn A', phone: '00123' }, 'Dòng khai báo cũ']);
  expect(node.type).toBe('table');
  if (node.type !== 'table') throw new Error('Expected structured grid');
  expect(node.rows).toHaveLength(3);
  expect(node.columns).toContain('Họ và tên');
  expect(node.columns).toContain('custom');
  expect(surveyAnswerText(node)).toContain('00123');
  expect(surveyAnswerText(node)).toContain('Dòng khai báo cũ');
});

test('zero false empty arrays and confirmed-empty markers remain distinguishable', () => {
  expect(answerText('b2_budget', 0)).toBe('0 Triệu đồng/năm');
  expect(answerText('b4_other', false)).toBe('Không');
  for (const value of [undefined, null, '', '   ', []]) expect(answerText('b4_other', value)).toBe('Chưa có câu trả lời');
  const confirmed = answerText('c1_usecases', [{ __confirmedEmpty: true }]);
  expect(confirmed).toContain('Xác nhận không có dữ liệu: Có');
  expect(confirmed).not.toContain('Chưa có câu trả lời');
});

test('confirmed-empty plus substantive grid content preserves both source statements', () => {
  const text = answerText('c1_usecases', [{ __confirmedEmpty: true }, { ten: 'Bài toán đã khai', trangthai: 'Đang triển khai' }]);
  expect(text).toContain('Xác nhận không có dữ liệu: Có');
  expect(text).toContain('Bài toán đã khai');
});

test('selection other-text and array answer ordering are preserved without default ranks', () => {
  const text = answerText('b2_diff', { sel: ['Chưa xác định được nguồn ngân sách', 'Khác'], other: 'Khó khăn theo đơn vị' });
  expect(text).toContain('Lựa chọn:');
  expect(text).toContain('Khác');
  expect(text).toContain('Nội dung khác: Khó khăn theo đơn vị');
  const ranking = formatSurveyAnswer(question('b2_costmajor'), ['Nhân sự & tư vấn', 'Công nghệ & hạ tầng']);
  expect(ranking).toMatchObject({ type: 'list', ordered: true });
  expect(surveyAnswerText(ranking)).toBe('Nhân sự & tư vấn\nCông nghệ & hạ tầng');
  expect(answerText('b2_costmajor', undefined)).toBe('Chưa có câu trả lời');
});

test('attachment metadata presents filenames while suppressing paths locators and URL tokens', () => {
  const text = answerText('a2_docs', { '0': { '0': 'Đã ban hành/Phê duyệt', _files: [
    { name: 'Quyết định.pdf', path: 'private-bucket/secret-object.pdf', size: 42, type: 'application/pdf', download_url: 'https://hidden.example/file?token=secret' },
    'private-folder/legacy-file.docx?token=hidden',
    { name: 'Biên bản #1.pdf', path: 'private-bucket/minutes.pdf' },
    { name: 'report?.pdf', path: 'private-bucket/report.pdf' },
  ] } });
  expect(text).toContain('Quyết định.pdf');
  expect(text).toContain('legacy-file.docx');
  expect(text).toContain('Biên bản #1.pdf');
  expect(text).toContain('report?.pdf');
  for (const hidden of ['private-bucket', 'secret-object', 'private-folder', 'token=', 'hidden.example']) expect(text).not.toContain(hidden);
});

test('unknown answer shapes preserve visible values and hide nested storage locators', () => {
  const answers = { future_question: { nested: { useful: 'Giữ nội dung này', count: 0, enabled: false, storage_path: 'hidden-path' }, url: 'https://hidden.example/token' }, _files: [{ name: 'Tệp mới.xlsx', path: 'bucket/key' }], storage_path: 'hidden-top-level' };
  const before = structuredClone(answers);
  const extra = buildSurveySections(answers).find(section => section.id === 'additional')!;
  const text = extra.questions.map(entry => surveyAnswerText(entry.answer)).join('\n');
  for (const value of ['Giữ nội dung này', 'count: 0', 'enabled: Không', 'Tệp mới.xlsx']) expect(text).toContain(value);
  for (const hidden of ['hidden-path', 'hidden.example', 'hidden-top-level', 'bucket/key']) expect(text).not.toContain(hidden);
  expect(answers).toEqual(before);
});

test('empty lookup renders every known question without inventing answered content', () => {
  const sections = buildSurveySections({});
  expect(sections.map(section => section.id)).toEqual(surveyDisplaySections.map(section => section.id));
  expect(sections.flatMap(section => section.questions)).toHaveLength(surveyDisplaySections.flatMap(section => section.questions).length);
  expect(sections.flatMap(section => section.questions).find(entry => entry.id === 'a1_name')!.answer).toEqual({ type: 'empty', text: 'Chưa có câu trả lời' });
});

test('survey search matches unaccented Vietnamese question labels and answers while respecting sections', () => {
  const sections = buildSurveySections({ a1_name: 'Đơn vị Điện lực', c1_share: 'Kinh nghiệm vận hành' });
  const matches = filterSurveySections(sections, 'don vi dien luc');
  expect(matches.flatMap(section => section.questions).map(entry => entry.id)).toContain('a1_name');
  expect(filterSurveySections(sections, 'don vi dien luc', 'C1')).toEqual([]);
  expect(filterSurveySections(sections, '', 'C1').map(section => section.id)).toEqual(['C1']);
  expect(filterSurveySections(sections, 'chuoi-khong-ton-tai')).toEqual([]);
});

test('unknown or missing source schema versions preserve positional values without guessing row labels', () => {
  const answers = { c3_infra: { '0': { '0': 'Giá trị từ phiên bản khác' } }, b3_rating: { '0': 2 } };
  for (const version of [null, 15, 99, 'legacy']) {
    const questions = buildSurveySections(answers, version).flatMap(section => section.questions);
    const matrix = surveyAnswerText(questions.find(entry => entry.id === 'c3_infra')!.answer);
    const rating = surveyAnswerText(questions.find(entry => entry.id === 'b3_rating')!.answer);
    expect(matrix).toContain('Giá trị từ phiên bản khác');
    expect(matrix).not.toContain(question('c3_infra').rows![0]);
    expect(rating).toContain('2');
    expect(rating).not.toContain(question('b3_rating').scaleLabels![1]);
  }
  const known = buildSurveySections(answers, 16).flatMap(section => section.questions);
  expect(surveyAnswerText(known.find(entry => entry.id === 'c3_infra')!.answer)).toContain(question('c3_infra').rows![0]);
});


test('survey version metadata is excluded while unrelated unfamiliar answer keys remain visible', () => {
  const answers = { __surveySchemaVersion: 16, __otherMetadata: 'Keep other metadata', unknown: 'Keep unknown answer' };
  const questions = buildSurveySections(answers).flatMap(section => section.questions);
  expect(questions.map(entry => entry.id)).not.toContain('__surveySchemaVersion');
  expect(questions.find(entry => entry.id === '__otherMetadata')?.answer).toEqual({ type: 'text', text: 'Keep other metadata' });
  expect(questions.find(entry => entry.id === 'unknown')?.answer).toEqual({ type: 'text', text: 'Keep unknown answer' });
  expect(answers.__surveySchemaVersion).toBe(16);
});
