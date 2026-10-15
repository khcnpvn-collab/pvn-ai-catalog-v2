const verificationStatuses = new Set(['chưa xác minh', 'đã xác minh', 'cần xác minh', 'cần bổ sung', 'chờ đối soát', 'đã đối soát']);

export function visibleOperationalStatus(status: string | null | undefined): string | null {
  const value = status?.trim();
  return value && !verificationStatuses.has(value.normalize('NFC').toLocaleLowerCase('vi')) ? value : null;
}

// In a list of related records the usual state of a kind says nothing; only exceptions are tagged.
const routineStatus: Record<string, string> = { unit: 'Đang hoạt động' };
export function rowRecordStatus(record: { kind: string; status: string; data: Record<string, string | number | null> }): string | null {
  const status = visibleRecordStatus(record);
  return status && routineStatus[record.kind] === status ? null : status;
}

// A reference's stored metadata status does not establish whether a file exists.
export function visibleRecordStatus(record: { kind: string; status: string; data: Record<string, string | number | null> }, directDocumentCount?: number): string | null {
  if (record.kind !== 'reference') return visibleOperationalStatus(record.status);
  if (directDocumentCount == null) return null;
  if (directDocumentCount > 0) return 'Có tệp đính kèm';
  return /^https?:\/\//i.test(String(record.data.external_url ?? '')) ? 'Có liên kết tham khảo' : 'Chưa đính kèm';
}

export function isGeneratedRecordCode(code: string | null | undefined): boolean {
  return /^KS-[A-Z_]+-[a-f0-9]{24}$/i.test(code || '');
}

// These are importer-authored sentences, never a blanket filter on survey answers.
export function cleanGeneratedRecordText(text: string | null | undefined, generated = false): string {
  if (!text) return '';
  if (!generated) return text;
  return text
    .replace('Tên và nhóm bài toán được chuẩn hóa bước đầu; các đơn vị giữ hồ sơ nhu cầu riêng để đối soát.', 'Thông tin áp dụng tại từng đơn vị được lưu trong các hồ sơ nhu cầu.')
    .replace('Thông tin do đơn vị khai báo, chưa xác minh độc lập.', 'Thông tin do đơn vị khai báo.')
    .replace('Các bản khai báo gốc đều được liên kết tại Nguồn & chuẩn hóa; chưa xác minh độc lập.', 'Các bản khai báo gốc được liên kết tại Nguồn & chuẩn hóa.')
    .replace(/^Tình trạng ánh xạ từ phiếu khảo sát, chưa xác minh độc lập\.\s*$/gm, '')
    .replace(/^Trạng thái là thông tin đơn vị khai báo tại thời điểm nguồn; không suy diễn tiến độ hoặc hiệu quả thực tế\.\s*$/gm, '')
    .replace(/^(CSDL do [^\n]+ khai báo); chưa xác minh độc lập tình trạng sử dụng\.$/gm, '$1.')
    .replace(/^Khảo sát đơn vị; chưa xác minh pháp nhân$/, 'Khảo sát đơn vị')
    .replace(/\n{3,}/g, '\n\n').trim();
}

const narrativeLabels = new Set([
  'Đơn vị', 'Trạng thái đơn vị khai báo', 'Thời gian theo khai báo', 'Dữ liệu đầu vào', 'Mô tả',
  'Phương thức đánh giá hiệu quả', 'Hạ tầng/môi trường', 'Yêu cầu vị trí dữ liệu', 'Yêu cầu hạ tầng đặc thù',
  'Nhóm dữ liệu và mức sẵn sàng theo nguồn', 'Giải pháp tương tự trên thị trường (không khẳng định đã chọn)',
  'Phương thức triển khai dự kiến', 'Mô tả nhu cầu', 'Kết quả SXKD liên quan theo khai báo',
  'Tình trạng theo bài toán', 'Phạm vi', 'Khó khăn', 'Sự cố/rủi ro', 'Tình trạng nguyên gốc', 'Tên đối tác nguyên gốc',
  'Khả năng chia sẻ', 'Cách truy xuất', 'Vị trí lưu trữ', 'Môi trường', 'Tiêu chuẩn/quy định do đơn vị khai báo',
  'Văn bản nền tảng', 'Chia sẻ và kiến nghị về quản trị', 'Tài sản có thể chia sẻ', 'Nhu cầu tái sử dụng',
  'Quy mô nhân sự AI/dữ liệu', 'Năng lực AI/dữ liệu', 'Vướng mắc hạ tầng', 'Vướng mắc nhân sự',
  'Chiến lược/Kế hoạch KHCN - ĐMST - CĐS', 'Chiến lược/Kế hoạch/Lộ trình AI', 'Quy chế/quy trình ứng dụng AI',
]);

export type NarrativeBlock = { label: string | null; text: string };

export function parseNarrative(text: string): NarrativeBlock[] {
  return parseLabeledText(text, Object.fromEntries([...narrativeLabels].map(label => [label, label])));
}

export function parseDataDetails(text: string): NarrativeBlock[] {
  return parseLabeledText(text, {
    nhomdulieu: 'Nhóm dữ liệu', hethongnguon: 'Hệ thống nguồn', quanlydacbiet: 'Yêu cầu quản lý đặc biệt',
    sansangdulieu: 'Mức độ sẵn sàng', truongdulieuchinh: 'Các trường dữ liệu chính',
  });
}

function parseLabeledText(text: string, labels: Record<string, string>): NarrativeBlock[] {
  if (!text.trim()) return [];
  const blocks: NarrativeBlock[] = [];
  for (const line of text.split(/\r?\n/)) {
    const separator = line.indexOf(':');
    const label = separator >= 0 ? line.slice(0, separator).trim() : '';
    if (Object.hasOwn(labels, label)) {
      blocks.push({ label: labels[label], text: line.slice(separator + 1).trimStart() });
    } else if (blocks.length) {
      blocks[blocks.length - 1].text += `\n${line}`;
    } else {
      blocks.push({ label: null, text: line });
    }
  }
  return blocks;
}

export function recordExcerpt(text: string, maxLength = 200): string {
  const value = text.replace(/\s+/g, ' ').trim();
  if (value.length <= maxLength) return value;
  const candidate = value.slice(0, Math.max(0, maxLength - 1));
  const boundary = candidate.lastIndexOf(' ');
  return `${candidate.slice(0, boundary > maxLength * .6 ? boundary : undefined).trimEnd()}…`;
}

export function resolveDossierTab(requested: string, sectionIds: readonly string[], allowSurvey = false): string {
  if (requested === 'references') return 'documents';
  return ['overview', 'documents', ...(allowSurvey ? ['survey'] : []), ...sectionIds].includes(requested)
    && !['links', 'history'].includes(requested) ? requested : 'overview';
}

type PresentedRecord = { data: Record<string, string | number | null> };

// Short names longer than four characters do not fit the avatar tile; callers fall back to initials.
export function recordShortName(record: PresentedRecord): string | null {
  for (const candidate of [record.data.abbreviation, record.data.short_name]) {
    const value = String(candidate ?? '').trim();
    if (value && Array.from(value).length <= 4) return value;
  }
  return null;
}

// Classification shown on catalog cards and table rows, e.g. "Doanh nghiệp/nhà cung cấp · Việt Nam".
export function recordTypeLabel(record: PresentedRecord): string {
  const { partner_type, category, expert_type, event_type, item_category, item_group, sector, country } = record.data;
  const type = partner_type || category || expert_type || event_type || item_category || item_group || sector;
  return [type, country].filter(value => value != null && String(value).trim()).map(String).join(' · ');
}

// Imported mapping keys remain stored for reconciliation, not routine data entry.
export function isInternalCodeField(key: string): boolean {
  return key === 'internal_unit_code' || key === 'domain_code';
}
