// hidden fields keep stored values but are not shown or edited; suggestions turn a text field into a free tag.
// "tags" stores several labels as "a; b", suggesting the labels already used so they are reused.
export type Field = { key: string; label: string; type?: "text" | "textarea" | "date" | "number" | "email" | "url" | "select" | "tags"; options?: string[]; hint?: string; group?: string; hidden?: boolean; suggestions?: string[]; required?: boolean };
export type Module = { kind: string; label: string; singular: string; description: string; group: string; fields: Field[]; statuses: string[] };
export const PROGRAMS = [
  "AI cho tìm kiếm, thăm dò và khai thác",
  "AI cho vận hành, hiệu suất, độ tin cậy và toàn vẹn tài sản",
  "AI cho hoạch định, thương mại và tối ưu chuỗi năng lượng",
  "AI cho dự án đầu tư, EPCI và quản lý dự án",
  "AI cho an toàn, môi trường, rủi ro và kiểm soát tuân thủ",
  "AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp",
  "AI cho nghiên cứu, đổi mới sáng tạo và sản phẩm, công nghệ",
];
export const LEADERSHIP_LEVELS = ["Tập đoàn triển khai", "Tập đoàn dẫn dắt, đơn vị triển khai", "Đơn vị chủ động"];
// Ordered lifecycle ending in "Hoàn thành"; the last two are off-track states.
export const ACTIVITY_STATUSES = ["Đề xuất", "Đang trao đổi", "POC", "Triển khai chính thức", "Pilot", "Vận hành", "Hoàn thành", "Tạm dừng", "Dừng"];
export const ACTIVE_ACTIVITY_STATUSES = ["POC", "Triển khai chính thức", "Pilot", "Vận hành"];
export const PARTNER_STATUSES = ["Đang hợp tác", "Tiềm năng", "Tạm dừng"];
// Six item groups: standard problems first, then the work item groups. An activity belongs to one group.
export const STANDARD_GROUP = "Bài toán";
export const WORK_ITEM_GROUPS = ["Nền tảng, hạ tầng, công nghệ", "Dữ liệu, CSDL", "Quản trị AI", "Nhân lực, đào tạo", "Ký kết hợp tác"];
export const ITEM_GROUPS = [STANDARD_GROUP, ...WORK_ITEM_GROUPS];
// Detailed classification of an activity, listed per group.
export const ITEM_CATEGORIES: Record<string, string[]> = {
  "Bài toán": ["Ứng dụng AI tại đơn vị", "Giải pháp dùng chung Tập đoàn", "Đề tài KHCN / nghiên cứu", "Tư vấn, đánh giá giải pháp"],
  "Nền tảng, hạ tầng, công nghệ": ["Hạ tầng tính toán (GPU, máy chủ)", "Điện toán đám mây", "Nền tảng AI / MLOps", "Mô hình & công cụ AI (LLM, trợ lý AI)", "Bản quyền, giấy phép phần mềm"],
  "Dữ liệu, CSDL": ["Xây dựng CSDL / kho dữ liệu", "Chuẩn hóa, làm sạch, gán nhãn", "Tích hợp, chia sẻ dữ liệu", "Quản trị chất lượng dữ liệu", "Khai thác dữ liệu bên ngoài"],
  "Quản trị AI": ["Chiến lược, kế hoạch AI", "Chính sách, quy chế, quy trình", "Rủi ro, an toàn, đạo đức AI", "Kiến trúc, tiêu chuẩn kỹ thuật", "Đo lường hiệu quả"],
  "Nhân lực, đào tạo": ["Đào tạo, khóa học", "Hội thảo, chia sẻ kinh nghiệm", "Chuyển giao công nghệ, know-how", "Chuyên gia, cố vấn", "Phát triển đội ngũ chuyên sâu"],
  "Ký kết hợp tác": ["Biên bản ghi nhớ (MOU)", "Thỏa thuận hợp tác chiến lược", "Thỏa thuận khung", "Hợp đồng dịch vụ / mua sắm", "Thỏa thuận bảo mật (NDA)"],
};
// Every item, standard problems included, follows this lifecycle.
export const ITEM_STATUSES = ["Đang thực hiện", "Hoàn thành", "Tạm dừng"];
export const SCOPE_LEVELS = ["Tập đoàn", "Đơn vị"];
export const APPLY_SCOPES = ["Toàn Tập đoàn", "Cơ quan Tập đoàn", "Đơn vị cụ thể"];
export const PARTNER_TYPES = ["Công ty công nghệ", "Đơn vị đào tạo và NCKH", "Cơ quan nhà nước", "Tư vấn", "Truyền thông/sự kiện", "Liên danh"];
export const STRATEGIC_LEVELS = ["Không", "Biên bản ghi nhớ cấp đơn vị", "Biên bản ghi nhớ cấp tập đoàn", "Hợp tác chiến lược cấp đơn vị", "Hợp tác chiến lược cấp tập đoàn"];
export const COUNTRIES = ["Việt Nam", "Hoa Kỳ", "Trung Quốc", "Nhật Bản", "Hàn Quốc", "Singapore", "Ấn Độ", "Vương quốc Anh", "Pháp", "Đức", "Hà Lan", "Na Uy", "Thụy Sĩ", "Israel", "Liên bang Nga", "Các Tiểu vương quốc Ả Rập Thống nhất", "Ả Rập Xê Út", "Úc", "Canada", "Khác"];
export const UNIT_TYPES = ["Đơn vị thành viên", "Ban/Văn phòng/Tổ chức thuộc Tập đoàn"];
export const modules: Module[] = [
  { kind: "unit", label: "Đơn vị", singular: "đơn vị", group: "Hồ sơ", description: "Thông tin và hiện trạng các đơn vị trong Tập đoàn.", statuses: ["Đang hoạt động", "Ngừng hoạt động"], fields: [
    { key: "unit_type", label: "Phân loại đơn vị", type: "select", options: UNIT_TYPES, required: true }, { key: "abbreviation", label: "Tên viết tắt" }, { key: "sector", label: "Lĩnh vực hoạt động" }, { key: "address", label: "Địa chỉ" }, { key: "website", label: "Website", type: "url" }] },
  { kind: "contact", label: "Đầu mối liên hệ", singular: "đầu mối", group: "Hồ sơ", description: "Đầu mối của đơn vị và đối tác, nhập ngay trên trang đơn vị hoặc đối tác; xem tập trung ở trang Danh bạ.", statuses: ["Còn hiệu lực", "Đã thay đổi", "Chưa xác minh"], fields: [
    { key: "position", label: "Chức danh", group: "Vai trò và công tác" }, { key: "department", label: "Phòng / ban", group: "Vai trò và công tác" }, { key: "email", label: "Email công việc", type: "email", group: "Thông tin liên hệ" }, { key: "phone", label: "Điện thoại", group: "Thông tin liên hệ" }, { key: "expertise", label: "Chuyên môn", type: "textarea", group: "Chuyên môn và giới thiệu" }, { key: "biography", label: "Giới thiệu", type: "textarea", group: "Chuyên môn và giới thiệu" }, {"key": "additional_emails", "label": "Email bổ sung", "type": "textarea", "group": "Thông tin liên hệ"}, {"key": "role", "label": "Vai trò đầu mối", "group": "Vai trò và công tác"}, {"key": "is_primary", "label": "Đầu mối chính", "type": "select", "group": "Vai trò và công tác", "options": ["Có", "Không"]}, {"key": "work_status", "label": "Tình trạng công tác", "group": "Vai trò và công tác"}] },
  { kind: "engagement", label: "Đợt làm việc", singular: "đợt làm việc", group: "Hồ sơ", description: "Lịch sử trao đổi, thành phần và tài liệu làm việc với đơn vị.", statuses: ["Đã diễn ra", "Đang diễn ra", "Dự kiến", "Chưa xác minh"], fields: [
    { key: "start_date", label: "Ngày bắt đầu", type: "date", group: "Thời gian và thành phần" }, { key: "end_date", label: "Ngày kết thúc", type: "date", group: "Thời gian và thành phần" }, { key: "period_label", label: "Thời gian nếu chỉ biết tháng / quý", group: "Thời gian và thành phần" }, { key: "location", label: "Địa điểm / hình thức", group: "Thời gian và thành phần" }, { key: "participants", label: "Thành phần được ghi nhận", type: "textarea", group: "Thời gian và thành phần" }, { key: "conclusions", label: "Nội dung và kết luận", type: "textarea", group: "Nội dung và kết quả" }, {"key": "next_notes", "label": "Nội dung trao đổi tiếp theo", "type": "textarea", "group": "Nội dung và kết quả"}, {"key": "responsible", "label": "Đầu mối phụ trách", "group": "Thời gian và thành phần"}] },
  { kind: "partner", label: "Đối tác", singular: "đối tác", group: "Hợp tác", description: "Danh mục đối tác, trạng thái hợp tác chung và các hoạt động đã làm cùng đối tác.", statuses: PARTNER_STATUSES, fields: [
    { key: "short_name", label: "Tên ngắn", group: "Thông tin đối tác" }, { key: "partner_type", label: "Loại đối tác", type: "select", options: PARTNER_TYPES, group: "Thông tin đối tác" }, { key: "strategic_level", label: "Hợp tác chiến lược", type: "select", options: STRATEGIC_LEVELS, group: "Thông tin đối tác" }, { key: "country", label: "Quốc gia", type: "select", options: COUNTRIES, group: "Thông tin đối tác" }, { key: "website", label: "Website", type: "url", group: "Hồ sơ giới thiệu" }, { key: "specialties", label: "Năng lực và giải pháp", type: "tags", group: "Hồ sơ giới thiệu", hint: "Chọn tag đã có hoặc gõ tag mới rồi nhấn Enter." }] },
  { kind: "collaboration", label: "Triển khai & hợp tác", singular: "hoạt động", group: "Bài toán & hoạt động", description: "Bài toán đơn vị, POC, đề tài KHCN và các nội dung hợp tác với đối tác; mỗi hồ sơ gắn tối đa một bài toán chuẩn.", statuses: ACTIVITY_STATUSES, fields: [
    { key: "item_group", label: "Nhóm hạng mục", type: "select", options: ITEM_GROUPS, group: "Phân loại và phạm vi", required: true }, { key: "item_category", label: "Phân loại chi tiết", type: "select", options: Object.values(ITEM_CATEGORIES).flat(), group: "Phân loại và phạm vi" }, { key: "declared_title", label: "Tên do đơn vị khai báo", group: "Phân loại và phạm vi" }, { key: "scope", label: "Mô tả / phạm vi", type: "textarea", group: "Phân loại và phạm vi" }, { key: "lead", label: "Đầu mối / bên chủ trì", group: "Thời gian và tổ chức" }, { key: "start_date", label: "Thời gian bắt đầu", type: "date", group: "Thời gian và tổ chức" }, { key: "end_date", label: "Thời gian kết thúc", type: "date", group: "Thời gian và tổ chức" }, { key: "agreement", label: "Hợp đồng / thỏa thuận liên quan", group: "Thời gian và tổ chức" }, { key: "results", label: "Kết quả", type: "textarea", group: "Kết quả và bước tiếp theo" }, { key: "source_status", label: "Tình trạng theo nguồn", group: "Kết quả và bước tiếp theo" } ] },
  { kind: "use_case", label: "Bài toán chuẩn", singular: "bài toán chuẩn", group: "Bài toán & hoạt động", description: "Danh mục bài toán chuẩn theo 7 chương trình AI; mỗi bài toán gom các hoạt động của đơn vị và đối tác.", statuses: ITEM_STATUSES, fields: [
    { key: "program", label: "Chương trình AI", type: "select", options: PROGRAMS, group: "Phân loại" }, { key: "category", label: "Nhóm bài toán", suggestions: [], group: "Phân loại" }, { key: "objective", label: "Mô tả bài toán", type: "textarea", group: "Phân loại" }, { key: "is_priority", label: "Thuộc danh mục ưu tiên", type: "select", options: ["Có", "Không"], group: "Định hướng triển khai" }, { key: "leadership_level", label: "Mức dẫn dắt của Tập đoàn", type: "select", options: LEADERSHIP_LEVELS, group: "Định hướng triển khai" }, { key: "start_year", label: "Năm dự kiến bắt đầu", type: "number", group: "Định hướng triển khai" }, { key: "sector", label: "Lĩnh vực", hidden: true }, { key: "scope", label: "Phạm vi áp dụng", type: "textarea", hidden: true }, { key: "expected_value", label: "Giá trị kỳ vọng", type: "textarea", hidden: true }] },
  { kind: "work_item", label: "Hạng mục triển khai", singular: "hạng mục", group: "Bài toán & hoạt động", description: "Hạng mục về nền tảng, dữ liệu, quản trị AI, nhân lực và ký kết hợp tác; mỗi hạng mục gom các hoạt động triển khai.", statuses: ITEM_STATUSES, fields: [
    { key: "item_group", label: "Nhóm hạng mục", type: "select", options: WORK_ITEM_GROUPS, group: "Thông tin hạng mục", required: true }, { key: "scope_level", label: "Phân loại", type: "select", options: SCOPE_LEVELS, group: "Thông tin hạng mục" }, { key: "apply_scope", label: "Ưu tiên áp dụng", type: "select", options: APPLY_SCOPES, group: "Thông tin hạng mục", hint: "Khi chọn 'Đơn vị cụ thể', chọn các đơn vị ở phần Đơn vị áp dụng." }, { key: "owner", label: "Đầu mối phụ trách", group: "Tổ chức thực hiện" }, { key: "coordinator", label: "Phối hợp", group: "Tổ chức thực hiện" }, { key: "start_date", label: "Thời gian bắt đầu", type: "date", group: "Tổ chức thực hiện" }, { key: "notes", label: "Ghi chú", type: "textarea", group: "Tổ chức thực hiện" }] },
  {
    "kind": "expert",
    "label": "Chuyên gia",
    "singular": "chuyên gia",
    "description": "Năng lực, tổ chức công tác và các nội dung trao đổi với chuyên gia.",
    "group": "Chuyên gia và tài liệu",
    "statuses": [
      "Đã trao đổi",
      "Đang hợp tác",
      "Chưa liên hệ",
      "Tạm dừng"
    ],
    "fields": [
      { "key": "organization", "label": "Nơi công tác", "group": "Thông tin chung" },
      { "key": "expertise_summary", "label": "Lĩnh vực / năng lực chuyên môn", "type": "textarea", "group": "Thông tin chung" },
      { "key": "work_history", "label": "Quá trình công tác", "type": "textarea", "group": "Thông tin chung" },
      {
        "key": "honorific",
        "label": "Danh xưng",
        "group": "Thông tin chuyên gia"
      },
      {
        "key": "academic_title",
        "label": "Học hàm",
        "group": "Thông tin chuyên gia"
      },
      {
        "key": "degree",
        "label": "Học vị",
        "group": "Thông tin chuyên gia"
      },
      {
        "key": "expert_type",
        "label": "Loại chuyên gia",
        "group": "Thông tin chuyên gia"
      },
      {
        "key": "current_position",
        "label": "Chức vụ hiện tại",
        "group": "Thông tin chuyên gia"
      },
      {
        "key": "country",
        "label": "Quốc gia",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "city",
        "label": "Thành phố",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "email",
        "label": "Email chính",
        "type": "email",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "additional_emails",
        "label": "Email bổ sung",
        "type": "textarea",
        "group": "Liên hệ và địa bàn",
        "hint": "Ghi đầy đủ các địa chỉ bổ sung, mỗi địa chỉ một dòng."
      },
      {
        "key": "phone",
        "label": "Điện thoại",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "website",
        "label": "Website / hồ sơ công khai",
        "type": "url",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "languages",
        "label": "Ngôn ngữ làm việc",
        "group": "Liên hệ và địa bàn"
      },
      {
        "key": "roles",
        "label": "Vai trò có thể tham gia",
        "type": "textarea",
        "group": "Hình thức tham gia"
      },
      {
        "key": "participation",
        "label": "Nội dung và hình thức tham gia",
        "type": "textarea",
        "group": "Hình thức tham gia"
      },
      {
        "key": "availability",
        "label": "Khả năng bố trí thời gian",
        "group": "Hình thức tham gia"
      },
      {
        "key": "commercial_terms",
        "label": "Điều kiện hợp tác / thương mại",
        "type": "textarea",
        "group": "Hình thức tham gia"
      },
      {
        "key": "priority",
        "label": "Mức ưu tiên",
        "group": "Hình thức tham gia"
      },
      {
        "key": "contact_consent",
        "label": "Thông tin đồng ý liên hệ",
        "type": "textarea",
        "group": "Liên hệ và chia sẻ",
        "hint": "Giữ đúng thông tin đã ghi nhận; để trống nếu chưa có."
      },
      {
        "key": "sharing_terms",
        "label": "Phạm vi chia sẻ được ghi nhận",
        "type": "textarea",
        "group": "Liên hệ và chia sẻ"
      },
      {
        "key": "classification",
        "label": "Phân loại thông tin",
        "group": "Liên hệ và chia sẻ"
      }
    ]
  },
  {
    "kind": "reference",
    "label": "Thư mục tài liệu",
    "singular": "thư mục tài liệu",
    "description": "File, thư mục và các thông tin tài liệu đã lưu.",
    "group": "Chuyên gia và tài liệu",
    "statuses": [
      "Liên kết tham khảo",
      "Chưa đính kèm"
    ],
    "fields": [
      {
        "key": "reference_type",
        "label": "Loại tài liệu",
        "group": "Thông tin tài liệu"
      },
      {
        "key": "external_url",
        "label": "Liên kết công khai",
        "type": "url",
        "group": "Thông tin tài liệu",
        "hint": "Chỉ dùng URL HTTP hoặc HTTPS. File và liên kết cùng nằm trong vùng File & tài liệu."
      },
      {
        "key": "document_date",
        "label": "Ngày tài liệu",
        "type": "date",
        "group": "Mốc thời gian và phiên bản",
        "hint": "Chỉ ghi ngày khi nguồn nêu rõ ngày của tài liệu."
      },
      {
        "key": "date_note",
        "label": "Ghi chú về thời điểm",
        "group": "Mốc thời gian và phiên bản",
        "hint": "Ghi tháng, năm hoặc ngày đối chiếu tại đây nếu không có ngày tài liệu chính xác."
      },
      {
        "key": "edition",
        "label": "Phiên bản",
        "group": "Mốc thời gian và phiên bản"
      },
      {
        "key": "classification",
        "label": "Phân loại thông tin",
        "group": "Phạm vi sử dụng"
      },
      {
        "key": "notes",
        "label": "Ghi chú tài liệu",
        "type": "textarea",
        "group": "Phạm vi sử dụng"
      }
    ]
  }
];
export function groupFields(fields: Field[], fallback: string): { label: string; fields: Field[] }[] {
  const groups = new Map<string, Field[]>();
  for (const field of fields) {
    const label = field.group || fallback;
    groups.set(label, [...(groups.get(label) || []), field]);
  }
  return Array.from(groups, ([label, fields]) => ({ label, fields }));
}
export const moduleMap: Record<string, Module> = Object.assign(Object.create(null), Object.fromEntries(modules.map(m => [m.kind, m])));
export type CatalogRecord = { id: string; kind: string; title: string; code: string | null; summary: string | null; status: string; version: number; data: Record<string, string | number | null>; created_at: string; updated_at: string; created_by: string };
export type RecordInput = Pick<CatalogRecord, "kind" | "title" | "status"> & Partial<Pick<CatalogRecord, "id" | "code" | "summary" | "version" | "data">>;
// Tags are stored as one text value separated by semicolons.
export const splitTags = (value: unknown) => String(value ?? "").split(";").map(tag => tag.trim()).filter(Boolean);
export const joinTags = (tags: string[]) => [...new Set(tags.map(tag => tag.trim()).filter(Boolean))].join("; ");
export type Relation = { id: string; source_id: string; target_id: string; relation: string; note: string | null; context: Record<string, string>; source?: CatalogRecord; target?: CatalogRecord };
export type DocumentVersion = { id: string; document_id: string; version: number; filename: string; mime_type: string; size_bytes: number; created_at: string };
export type CatalogDocument = { id: string; title: string; created_by: string; created_by_name?: string | null; created_at: string; versions: DocumentVersion[]; linked_records?: { id: string; title: string; kind: string }[] };
export type Membership = { user_id: string; role: "admin" | "editor" | "reader"; display_name: string | null };
export const relations = [
  { value: "related", label: "Liên quan" }, { value: "parent", label: "Thuộc hồ sơ cha" }, { value: "unit", label: "Thuộc / liên quan đơn vị" }, { value: "partner", label: "Đối tác tham gia" }, { value: "contact", label: "Đầu mối" }, { value: "expert", label: "Chuyên gia tham gia" }, { value: "use_case", label: "Bài toán chuẩn" }, { value: "collaboration", label: "Thuộc hoạt động" }, { value: "event", label: "Thuộc đợt / sự kiện" }, { value: "speaker", label: "Giảng viên / diễn giả" }, { value: "participant", label: "Thành phần tham gia" }, { value: "organizer", label: "Đơn vị tổ chức" },
];
export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export function validateRecord(input: RecordInput): string | null {
  if (!input || typeof input !== "object" || Array.isArray(input)) return "Hồ sơ không hợp lệ.";
  if (typeof input.kind !== "string") return "Loại hồ sơ không hợp lệ.";
  const mod = moduleMap[input.kind];
  if (!mod) return "Loại hồ sơ không hợp lệ.";
  if (typeof input.title !== "string" || !input.title.trim() || input.title.length > 250) return "Tên hồ sơ cần từ 1 đến 250 ký tự.";
  if (!mod.statuses.includes(input.status)) return "Trạng thái không hợp lệ.";
  if (input.id != null && (typeof input.id !== "string" || !UUID.test(input.id) || !Number.isInteger(input.version) || Number(input.version) < 1)) return "Thiếu phiên bản hồ sơ hợp lệ.";
  for (const key of ["code", "summary"] as const) if (input[key] != null && typeof input[key] !== "string") return "Thông tin hồ sơ phải là văn bản hợp lệ.";
  const validDate = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(v)) && new Date(v).toISOString().slice(0, 10) === v;
  if ((input.code?.length ?? 0) > 80 || (input.summary?.length ?? 0) > 10000) return "Nội dung vượt giới hạn cho phép.";
  if (input.data != null && (typeof input.data !== "object" || Array.isArray(input.data))) return "Chi tiết hồ sơ không hợp lệ.";
  const missing = mod.fields.find(field => field.required && (input.data?.[field.key] == null || input.data[field.key] === ""));
  if (missing) return `Cần chọn ${missing.label.toLowerCase()}.`;
  for (const [key, value] of Object.entries(input.data ?? {})) {
    const field = mod.fields.find(f => f.key === key);
    if (!field) return `Trường ${key} không thuộc loại hồ sơ này.`;
    if (value == null || value === "") continue;
    if (field.type === "number") { if (!["number", "string"].includes(typeof value) || (typeof value === "string" && !/^[0-9]+([.][0-9]+)?$/.test(value)) || !Number.isFinite(Number(value)) || Number(value) < 0 || Number(value) > 100000000) return `${field.label} cần là số không âm hợp lệ.`; }
    else if (typeof value !== "string" || value.length > (field.type === "textarea" ? 10000 : 1000)) return `${field.label} không hợp lệ hoặc quá dài.`;
    if (field.type === "date" && !validDate(String(value))) return `${field.label} không hợp lệ.`;
    if (field.type === "email" && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value))) return "Email không hợp lệ.";
    if (field.type === "url") { try { if (!["http:", "https:"].includes(new URL(String(value)).protocol)) return "Liên kết phải dùng HTTP hoặc HTTPS."; } catch { return "Liên kết không hợp lệ."; } }
    if (field.options && !field.options.includes(String(value))) return `${field.label} không thuộc danh mục.`;
  }
  const group = input.data?.item_group, category = input.data?.item_category;
  if (input.kind === "collaboration" && group && category && !ITEM_CATEGORIES[String(group)]?.includes(String(category))) return "Phân loại chi tiết không thuộc nhóm hạng mục đã chọn.";
  const start = input.data?.start_date, end = input.data?.end_date;
  if (start && end && String(end) < String(start)) return "Ngày kết thúc không được trước ngày bắt đầu.";
  return null;
}
