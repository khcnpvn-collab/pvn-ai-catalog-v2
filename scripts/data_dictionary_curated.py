"""Hand-written part of the data dictionary: field rows of the main groups (with app placement),
consortium, files, survey results and accounts, plus relations, roles, system tables, dashboard
rules and Claude's answers to the reviewer's notes. Fill counts come from the stats JSON when a
row maps to one stored field (GROUP_KIND below); the value written here is only the fallback.
"""

# Field row: (group, form section, label, key, type, allowed values, required, on form, on page, filled, example, meaning, Claude's note)
F = []
def add(group, section, label, key, typ, values, required, form, page, filled, example, meaning, note=""):
    F.append((group, section, label, key, typ, values, required, form, page, filled, example, meaning, note))

# Groups whose single-key rows take their fill count from stats["fields"]["<kind>.<key>"].
GROUP_KIND = {"Đối tác": "partner", "Liên danh": "partner#consortium", "Đơn vị": "unit", "Bài toán chuẩn": "use_case", "Triển khai & hợp tác": "collaboration"}

P = "Đối tác"
add(P, "Thông tin nhận diện", "Tên đối tác", "title", "Văn bản (≤250)", "", "Có", "Có", "Tiêu đề trang", "", "ADT Global/ADT Hi-tech", "Tên thường dùng của đối tác.")
add(P, "Thông tin nhận diện", "Trạng thái hợp tác", "status", "Danh mục", "Đang hợp tác; Tiềm năng; Tạm dừng", "Có", "Có", "Nhãn trên tiêu đề, bộ lọc dashboard", "", "", "Trạng thái quan hệ chung với đối tác (không phải của từng hoạt động). Lần đầu được suy ra từ hoạt động, sau đó sửa tay.")
add(P, "Thông tin nhận diện", "Giới thiệu ngắn", "summary", "Văn bản dài", "", "Không", "Có", "Thông tin chính", "", "Đối tác của NGS giới thiệu", "Mô tả ngắn về đối tác.", "Hầu như trống.")
add(P, "Thông tin đối tác", "Loại đối tác", "partner_type", "Danh mục", "Công ty công nghệ; Đơn vị đào tạo và NCKH; Cơ quan nhà nước; Tư vấn; Truyền thông/sự kiện; Liên danh", "Không", "Có", "Thông tin chính, bộ lọc dashboard", "", "", "Phân loại đối tác. 'Liên danh' chỉ dùng cho hồ sơ liên danh.")
add(P, "Thông tin đối tác", "Quốc gia", "country", "Danh mục", "20 quốc gia (Việt Nam, Hoa Kỳ, Trung Quốc, Nhật Bản, Hàn Quốc, Singapore, … , Khác)", "Không", "Có", "Thông tin chính", "", "", "Quốc gia của đối tác.")
add(P, "Hồ sơ giới thiệu", "Website", "website", "Liên kết http/https", "", "Không", "Có", "Thông tin chính", "", "https://adtglobal.vn/", "Trang web chính thức.")
add(P, "Hồ sơ giới thiệu", "Năng lực và giải pháp", "specialties", "Tag (nhiều giá trị)", "Tag đã dùng; gõ tag mới để thêm", "Không", "Có", "Xem đầy đủ thông tin", "", "Nền tảng AI", "Năng lực, sản phẩm/giải pháp chính.")
add(P, "Thông tin đối tác", "Tên ngắn", "short_name", "Văn bản", "", "Không", "Không", "Ký hiệu đại diện, gợi ý tìm kiếm", "", "ADT; AI Hay", "Tên viết tắt dùng làm ký hiệu và trong ô tìm kiếm.", "Đang dùng nhưng KHÔNG sửa được trên form — đề xuất đưa vào form.")
add(P, "Hệ thống", "Mã hồ sơ", "code", "Tự sinh", "", "Tự động", "Không", "Không", "", "KS-PARTNER-…", "Mã kỹ thuật để đối chiếu nguồn, không hiển thị.")
add(P, "Thông tin đối tác", "Hợp tác chiến lược", "strategic_level", "Danh mục", "Không; Biên bản ghi nhớ cấp đơn vị; Biên bản ghi nhớ cấp tập đoàn; Hợp tác chiến lược cấp đơn vị; Hợp tác chiến lược cấp tập đoàn", "Không", "Có", "Thông tin chính; thẻ số liệu dashboard", "", "", "Mức cam kết chính thức với đối tác (MOU / thỏa thuận chiến lược, cấp đơn vị hay Tập đoàn).", "Thêm 15/10/2026 thay trạng thái 'Chiến lược'; chưa đối tác nào được chọn.")

C = "Liên danh"
add(C, "Thông tin nhận diện", "Tên liên danh", "title", "Văn bản (≤250)", "", "Có", "Có", "Tiêu đề trang; nhóm trong mục Liên danh của từng thành viên", "", "Liên danh ADT – AIQ", "Tên nhóm các đối tác cùng tham gia. Quy ước: 'Liên danh <A> – <B>'.")
add(C, "Thông tin nhận diện", "Trạng thái", "status", "Danh mục", "Như đối tác", "Có", "Có", "Nhãn trên tiêu đề", "", "Tiềm năng (cả 4)", "Trạng thái chung của liên danh.", "Cả 4 đang 'Tiềm năng'; không ảnh hưởng trạng thái của thành viên.")
add(C, "Thông tin nhận diện", "Loại đối tác", "partner_type", "Cố định", "Liên danh", "Tự động", "Không", "Không", "", "Liên danh", "Đánh dấu hồ sơ là liên danh: không hiện trong menu/biểu đồ Đối tác, không tính là một đối tác.")
add(C, "Thành viên", "Thành viên", "quan hệ partner → partner", "Liên kết", "Đối tác (không phải liên danh)", "Không", "Trang liên danh › Thành viên; trang đối tác › Liên danh", "Danh sách thành viên", "8 liên kết / 4 liên danh", "VNPT; Qualcomm", "Một liên danh nhiều đối tác; một đối tác có thể ở nhiều liên danh. Xem sheet 'Liên danh'.")
add(C, "Thành viên", "Đầu mối liên danh", "consortium_role", "Nhãn trên liên kết", "lead; member", "1 đầu mối", "Nút 'Đặt làm đầu mối'", "Tag 'Đầu mối liên danh'", "4/4 liên danh có đầu mối", "VNPT (đầu mối)", "Đối tác đứng đầu liên danh.", "2 liên kết còn dùng nhãn cũ 'Vai trò' (Đứng đầu liên danh / Thành viên); app đọc như nhau.")
add(C, "Hoạt động", "Hoạt động ký qua liên danh", "quan hệ collaboration → liên danh", "Liên kết", "Tối đa 1 bên thực hiện / hoạt động", "Không", "Form hoạt động › Bên thực hiện › Qua liên danh", "Mục Triển khai & hợp tác của liên danh và của từng thành viên", "2 hoạt động", "", "Hoạt động có bên thực hiện là liên danh; dashboard tính cho từng thành viên.")
add(C, "Hoạt động", "Đối tác đầu mối của hoạt động", "lead_member_id", "Nhãn trên liên kết", "Một thành viên của liên danh", "Không", "Form hoạt động (tích đầu mối)", "Tag đầu mối trên dòng hoạt động", "0/2", "", "Thành viên làm đầu mối riêng cho hoạt động đó (có thể khác đầu mối liên danh).", "Chưa hoạt động nào được chọn.")
add(C, "Không dùng", "Quốc gia / Website / Giới thiệu / Năng lực / Tên ngắn", "country; website; summary; specialties; short_name", "Như đối tác", "", "Không", "Không", "Không", "0/4", "", "Liên danh là nhóm nhẹ nên không dùng các trường hồ sơ đối tác.")

U = "Đơn vị"
add(U, "Thông tin nhận diện", "Tên đơn vị", "title", "Văn bản (≤250)", "", "Có", "Có", "Tiêu đề trang", "", "Viện Dầu khí Việt Nam", "Tên đầy đủ đơn vị/Ban.", "Danh mục chưa có các Ban của Cơ quan Tập đoàn.")
add(U, "Thông tin nhận diện", "Tình trạng hoạt động", "status", "Danh mục", "Đang hoạt động; Ngừng hoạt động", "Có", "Có", "Không (ẩn khi 'Đang hoạt động')", "", "Đang hoạt động (cả 28)", "Đơn vị còn hoạt động hay không.")
add(U, "Thông tin nhận diện", "Tóm tắt", "summary", "Văn bản dài", "", "Không", "Có", "Không (câu tự sinh bị ẩn)", "", "Đã nhận phiếu khảo sát…", "Mô tả ngắn đơn vị.", "Toàn bộ là câu tự sinh từ khảo sát.")
add(U, "Nội dung đơn vị", "Tên viết tắt", "abbreviation", "Văn bản", "", "Không", "Có", "Thông tin chính, bảng, ký hiệu", "", "VPI; BSR; PVEP", "Khóa nhận diện đơn vị ở mọi nơi.", "Nên coi là bắt buộc và duy nhất.")
add(U, "Nội dung đơn vị", "Lĩnh vực hoạt động", "sector", "Văn bản", "", "Không", "Có", "Thông tin chính", "", "", "Lĩnh vực chính.", "Gõ tự do (8 giá trị) — có thể chuyển thành danh mục.")
add(U, "Nội dung đơn vị", "Địa chỉ", "address", "Văn bản", "", "Không", "Có", "Thông tin chính", "", "", "Địa chỉ trụ sở.", "Trống.")
add(U, "Nội dung đơn vị", "Website", "website", "Liên kết", "", "Không", "Có", "Thông tin chính", "", "", "Trang web đơn vị.", "Trống.")
add(U, "Thông tin nhận diện", "Phân loại đơn vị", "unit_type", "Danh mục", "Đơn vị thành viên; Ban/Văn phòng/Tổ chức thuộc Tập đoàn", "Có", "Có", "Thông tin chính", "28/28", "Đơn vị thành viên 27 · Ban/VP thuộc Tập đoàn 1 (Cơ quan Tập đoàn)", "Phân biệt Ban/VP của Tập đoàn với đơn vị thành viên.", "Thêm 15/10/2026; mặc định Đơn vị thành viên. Các Ban chưa có trong danh mục.")

S = "Bài toán chuẩn"
add(S, "Thông tin nhận diện", "Tên bài toán chuẩn", "title", "Văn bản (≤250)", "", "Có", "Có", "Tiêu đề trang", "", "Camera AI giám sát an toàn, tuân thủ và ứng cứu sự cố", "Tên bài toán chuẩn.", "BTC-14 và BTC-49 trùng tên 'Quản lý năng lượng, phát thải và carbon/ESG'.")
add(S, "Thông tin nhận diện", "Mã", "code", "Tự sinh", "BTC-01 … BTC-62 (không có BTC-50)", "Tự động", "Không", "Tiêu đề, bảng", "", "BTC-46", "Mã theo danh mục Ban KHCN; bài tạo mới từ hoạt động không có mã BTC.")
add(S, "Thông tin nhận diện", "Tình trạng danh mục", "status", "Danh mục", "Chính thức; Chờ rà soát", "Có", "Có", "Nhãn", "", "Chính thức (cả 61)", "Bài tạo nhanh từ hoạt động mang 'Chờ rà soát'.")
add(S, "Thông tin nhận diện", "Tóm tắt", "summary", "Văn bản dài", "", "Không", "Có", "Thông tin chính", "", "", "Không dùng (mô tả nằm ở 'Mô tả bài toán').", "Trùng ý với Mô tả bài toán — đề xuất ẩn khỏi form.")
add(S, "Phân loại", "Chương trình AI", "program", "Danh mục", "7 chương trình AI (xem sheet Danh mục giá trị)", "Không", "Có", "Thông tin chính, bảng, biểu đồ", "", "AI cho tìm kiếm, thăm dò và khai thác", "Chương trình AI chứa bài toán.")
add(S, "Phân loại", "Nhóm bài toán", "category", "Văn bản, có gợi ý", "41 nhóm đang dùng", "Không", "Có", "Thông tin chính", "", "Minh giải và tổng hợp tài liệu địa chấn", "Nhóm con trong chương trình (tag tự do).")
add(S, "Phân loại", "Mô tả bài toán", "objective", "Văn bản dài", "", "Không", "Có", "Thông tin chính", "", "Ứng dụng AI kết nối với hệ thống camera hiện hữu…", "Mô tả nội dung bài toán.")
add(S, "Định hướng triển khai", "Thuộc danh mục ưu tiên", "is_priority", "Danh mục", "Có; Không", "Không", "Có", "Thông tin chính, bộ lọc, biểu đồ", "", "Có 14 · Không 47", "Bài thuộc 14 bài ưu tiên.")
add(S, "Định hướng triển khai", "Mức dẫn dắt của Tập đoàn", "leadership_level", "Danh mục", "Tập đoàn triển khai; Tập đoàn dẫn dắt, đơn vị triển khai; Đơn vị chủ động", "Không", "Có", "Thông tin chính", "", "", "Vai trò của Tập đoàn.", "Chỉ 14 bài ưu tiên có giá trị.")
add(S, "Định hướng triển khai", "Năm dự kiến bắt đầu", "start_year", "Số (2000–2100)", "", "Không", "Có", "Thông tin chính, bảng", "", "2026; 2027", "Năm dự kiến triển khai.", "Chỉ 14 bài ưu tiên có giá trị.")
add(S, "Đơn vị", "Đơn vị đầu mối ưu tiên", "quan hệ use_case → unit (lead)", "Liên kết", "Tối đa 1", "Không", "Trang bài toán › Đơn vị › Đặt làm đầu mối", "Mục Đơn vị, bảng bài toán", "14/61", "PETROVIETNAM; VPI; BSR", "Đơn vị/Ban được giao dẫn dắt.")
add(S, "Đơn vị", "Đơn vị tiềm năng áp dụng", "quan hệ use_case → unit (supporting)", "Liên kết", "Nhiều", "Không", "Trang bài toán › Đơn vị", "Mục Đơn vị", "141 liên kết", "", "Đơn vị có thể áp dụng.")
add(S, "Đối tác", "Đối tác tiềm năng", "quan hệ partner → use_case", "Liên kết", "Nhiều", "Không", "Trang bài toán › Đối tác tiềm năng; trang đối tác › Bài toán chuẩn có thể đáp ứng", "Mục Đối tác tiềm năng", "0", "", "Đối tác có năng lực đáp ứng bài toán (chưa làm).", "Chưa có liên kết nào.")
add(S, "Tự tính", "Hoạt động / đang chạy / đối tác đã làm", "(tính từ hoạt động)", "Số liệu", "", "", "Không", "Dải số liệu đầu trang, bảng dashboard", "85 hoạt động gắn BTC", "BTC-59: 10 hoạt động, 6 đang chạy, 5 đối tác", "Đếm các hoạt động gắn bài toán; 'đang chạy' = POC, Triển khai chính thức, Pilot, Vận hành.")
add(S, "Ẩn", "Lĩnh vực / Phạm vi áp dụng / Giá trị kỳ vọng", "sector; scope; expected_value", "Văn bản", "", "Không", "Không", "Không", "0/61", "", "Trường của mô hình cũ.", "Trống hoàn toàn — đề xuất bỏ.")

A = "Triển khai & hợp tác"
add(A, "Thông tin nhận diện", "Tên hoạt động", "title", "Văn bản (≤250)", "", "Có", "Có", "Tiêu đề trang, bảng", "", "Phát hiện bất thường và bảo trì dự báo thiết bị · PVPGB · GE", "Tên hoạt động.", "Tên từ khảo sát có dạng 'Đối tác · Đơn vị · bài toán'.")
add(A, "Thông tin nhận diện", "Trạng thái", "status", "Danh mục", "Đề xuất; Đang trao đổi; POC; Triển khai chính thức; Pilot; Vận hành; Tạm dừng; Dừng", "Có", "Có", "Nhãn, bảng, biểu đồ", "", "", "Giai đoạn của hoạt động.", "Chưa có hoạt động nào ở Pilot.")
add(A, "Phân loại và phạm vi", "Loại hoạt động", "cooperation_types", "Danh mục", "Bài toán đơn vị; POC; Đề tài KHCN; Hợp tác đối tác; Hạ tầng; Đào tạo; MOU / hợp tác chiến lược; Tư vấn", "Không", "Có", "Thông tin chính, bảng", "", "", "Phân loại hoạt động (một giá trị).")
add(A, "Phân loại và phạm vi", "Tên do đơn vị khai báo", "declared_title", "Văn bản", "", "Không", "Chỉ khi đã có giá trị", "Thông tin chính", "", "AI cho dự án nhà máy thông minh…", "Tên gốc trong phiếu khảo sát (để đối chiếu).")
add(A, "Phân loại và phạm vi", "Mô tả / phạm vi", "scope", "Văn bản dài", "", "Không", "Có", "Thông tin chính", "", "Áp dụng cho các Nhà máy Đạm Cà Mau…", "Nội dung, phạm vi hoạt động.")
add(A, "Thời gian và tổ chức", "Đầu mối / bên chủ trì", "lead", "Văn bản", "", "Không", "Có", "Thông tin chính", "", "Văn phòng; Ban CĐS và các Ban/đơn vị…", "Bộ phận/người phụ trách ghi tay.", "Trùng ý với 'Chủ thể PVN – Đầu mối'. Đề xuất đổi thành 'Người/bộ phận phụ trách' hoặc bỏ.")
add(A, "Thời gian và tổ chức", "Thời gian bắt đầu / kết thúc", "start_date; end_date", "Ngày", "Kết thúc ≥ bắt đầu", "Không", "Có", "Thông tin chính, bảng", "2/157", "2026-10-01 → 2026-12-31", "Thời gian thực hiện.", "Gần như trống.")
add(A, "Thời gian và tổ chức", "Hợp đồng / thỏa thuận liên quan", "agreement", "Văn bản", "", "Không", "Có", "Xem đầy đủ thông tin", "", "", "Số/tên hợp đồng, MOU.", "Trống — giữ hay bỏ?")
add(A, "Kết quả và bước tiếp theo", "Kết quả", "results", "Văn bản dài", "", "Không", "Có", "Xem đầy đủ thông tin", "", "ADT đã gửi đề xuất…", "Kết quả đạt được.", "Trùng ý với 'Kết luận' — đề xuất gộp.")
add(A, "Kết quả và bước tiếp theo", "Kết luận", "conclusion", "Văn bản dài", "", "Không", "Có", "Xem đầy đủ thông tin", "", "", "Kết luận khi kết thúc.", "Trống, trùng ý với 'Kết quả'.")
add(A, "Kết quả và bước tiếp theo", "Bước tiếp theo", "next_notes", "Văn bản dài", "", "Không", "Có", "Xem đầy đủ thông tin", "", "Chọn 1-2 use case và workshop", "Việc cần làm tiếp.")
add(A, "Liên kết", "Chủ thể PVN – Đầu mối / Phối hợp", "quan hệ collaboration → unit", "Liên kết", "Đúng 1 đầu mối; phối hợp nhiều", "Có (đầu mối)", "Form thêm hoạt động; trang hoạt động › Chủ thể PVN", "Mục Chủ thể PVN, bảng", "157 đầu mối · 1 phối hợp", "PVEP (đầu mối)", "Đơn vị/Ban PVN chủ trì hoặc phối hợp.")
add(A, "Liên kết", "Bên thực hiện", "quan hệ collaboration → partner / liên danh / unit", "Liên kết", "Tối đa 1", "Không", "Form thêm hoạt động; trang hoạt động › Bên thực hiện", "Mục Bên thực hiện, bảng", "103 đối tác · 2 liên danh · 1 đơn vị PVN", "GE", "Đối tác, liên danh hoặc một đơn vị PVN thực hiện.", "51 hoạt động chưa có bên thực hiện; 19 liên kết có ghi chú.")
add(A, "Liên kết", "Bài toán chuẩn", "quan hệ collaboration → use_case", "Liên kết", "Tối đa 1", "Không", "Form thêm hoạt động; trang hoạt động › Bài toán chuẩn (tìm hoặc thêm mới)", "Mục Bài toán chuẩn, bảng", "85/157", "BTC-46", "Bài toán chuẩn hoạt động thuộc về.", "72 hoạt động chưa gắn bài toán chuẩn.")
add(A, "Ẩn", "Tình trạng theo nguồn", "source_status", "Văn bản", "", "Không", "Không", "Xem đầy đủ thông tin", "", "Đơn vị khai báo: POC (thử nghiệm)", "Trạng thái gốc trong khảo sát/workbook (để đối chiếu).")
add(A, "Ẩn", "Ngày làm việc gần nhất", "last_meeting_date", "Ngày", "", "Không", "Không", "Xem đầy đủ thông tin", "", "2026-09-11", "Từ workbook đối tác.", "Không sửa được; nên thay bằng mốc làm việc.")
add(A, "Ẩn", "Nội dung tổng hợp (tóm tắt)", "summary", "Văn bản dài", "", "Không", "Không", "Xem đầy đủ thông tin", "", "Đơn vị: PVEP · Trạng thái đơn vị khai báo: Ý tưởng…", "Văn bản tự sinh khi nhập khảo sát.", "Không sửa được trên form.")
add(A, "Hệ thống", "Mã hồ sơ", "code", "Tự sinh", "", "Tự động", "Không", "Không", "157/157", "KS-COLLABORATION-…", "Đối chiếu nguồn.")

D = "File & tài liệu"
add(D, "Tài liệu", "Tên tài liệu", "documents.title", "Văn bản (≤250)", "", "Có", "Có (khi tải lên)", "Danh sách file", "42/42", "", "Tên hiển thị của file.")
add(D, "Tài liệu", "Tệp", "document_versions.filename", "Tên tệp", "", "Có", "Chọn tệp", "Danh sách file", "42/42", "", "Tên tệp gốc khi tải.")
add(D, "Tài liệu", "Định dạng", "document_versions.mime_type", "Danh mục", "PDF; Word (doc, docx); Excel (xls, xlsx); PowerPoint (ppt, pptx); TXT; CSV; ảnh PNG/JPG", "Có", "Kiểm tra khi tải", "Biểu tượng file", "42/42", "PDF (cả 42)", "Loại tệp cho phép.")
add(D, "Tài liệu", "Dung lượng", "document_versions.size_bytes", "Số (byte)", "Tối đa 20 MB / tệp", "Có", "Kiểm tra khi tải", "Danh sách file", "42/42", "Tổng 166,9 MB; lớn nhất 19,4 MB", "Kích thước tệp.")
add(D, "Tài liệu", "Phiên bản", "document_versions.version", "Số", "", "Tự động", "Không", "Chỉ hiện bản đang dùng", "42/42", "Mỗi file 1 phiên bản", "Tải lại cùng tài liệu tạo phiên bản mới; phiên bản cũ không bị xóa.")
add(D, "Tài liệu", "Người tải / thời điểm", "created_by; created_at", "Tài khoản; thời gian", "", "Tự động", "Không", "Danh sách file", "42/42", "", "Ai tải, lúc nào.")
add(D, "Tài liệu", "Ẩn khỏi kho", "documents.archived_at", "Thời gian", "", "Không", "Nút 'Xóa file'", "Không", "0/42", "", "Xóa file trên app chỉ ẩn tài liệu; tệp vật lý được giữ. (Xóa hồ sơ thì xóa hẳn, nhưng file vẫn ở kho.)")
add(D, "Gắn vào hồ sơ", "Hồ sơ chứa file", "document_links.record_id", "Liên kết", "Mọi loại hồ sơ", "Có", "Mục File & tài liệu của hồ sơ", "Mục File & tài liệu; file của hoạt động/mốc gom lên trang đơn vị/đối tác", "42 liên kết", "Đơn vị 31 · Đào tạo 6 · Hoạt động 3 · Đối tác 1 · Tài liệu tham khảo 1", "Một file có thể gắn nhiều hồ sơ (hiện chưa file nào gắn 2 nơi).")
add(D, "Gắn vào hồ sơ", "Phiên bản ghim", "document_links.version_id", "Liên kết", "", "Tự động", "Không", "Không", "42/42", "", "Hồ sơ giữ đúng phiên bản file lúc gắn.")
add(D, "Gắn vào hồ sơ", "Thư mục", "hồ sơ 'Tài liệu tham khảo' loại 'Thư mục'", "Hồ sơ phụ", "Một cấp thư mục trong mỗi hồ sơ", "Không", "Mục File & tài liệu › Tạo thư mục", "Thư mục trong mục File & tài liệu; hoạt động của đối tác hiện như thư mục", "0 thư mục", "", "Gom file theo nhóm trong một hồ sơ.")
add(D, "Lưu trữ", "Vị trí lưu / mã kiểm tra", "storage_path; checksum", "Hệ thống", "Kho riêng tư ai-catalog-documents", "Tự động", "Không", "Không", "42/42", "", "Tệp chỉ tải được qua đường dẫn ký 60 giây sau khi kiểm tra quyền.")

K = "Kết quả khảo sát"
add(K, "Phiếu", "Phiếu khảo sát của đơn vị", "sources (survey)", "Bản gốc bất biến", "", "Tự động", "Không", "Trang đơn vị › Kết quả khảo sát (admin)", "33 phiếu", "", "Bản chụp nguyên văn phiếu khảo sát; không sửa được.")
add(K, "Phiếu", "Mã đơn vị / trạng thái / ngày cập nhật phiếu", "unit_code; payload.status; payload.updated_at", "Văn bản; ngày", "", "Tự động", "Không", "Đầu mục Kết quả khảo sát", "33/33", "BSR · submitted", "Ghép phiếu với đơn vị.")
add(K, "Phiếu", "Câu trả lời", "payload.answers", "Theo câu hỏi", "10 phần A1–C6 (xem sheet 'Câu hỏi khảo sát')", "Tự động", "Không", "Kết quả khảo sát (theo phần)", "33/33", "", "Toàn bộ câu trả lời, hiển thị theo bộ câu hỏi đã chụp.")
add(K, "Bản nguồn khác", "Danh mục đơn vị gốc", "sources (unit_catalog)", "Bản gốc", "", "Tự động", "Không", "Không", "28", "", "Danh mục đơn vị dùng ghép phiếu với đơn vị.")
add(K, "Bản nguồn khác", "Bản nguồn chi tiết", "sources (survey_use_case, survey_partner, survey_contact, survey_data_asset, partner_workbook)", "Bản gốc", "", "Tự động", "Không", "Không", "82 · 57 · 44 · 42 · 132", "", "Từng dòng nguồn đã dùng tạo hồ sơ; giữ để truy vết, không hiện trên app.", "121 bản nguồn từng trỏ tới hồ sơ đã dọn, nay không còn hồ sơ gắn.")
add(K, "Bản nguồn khác", "Gắn bản nguồn ↔ hồ sơ", "source_links", "Liên kết", "", "Tự động", "Không", "Không", "427 liên kết", "", "Hồ sơ được tạo/chuẩn hóa từ bản nguồn nào.")

T = "Tài khoản & lịch sử"
add(T, "Tài khoản", "Tài khoản đăng nhập", "email (Supabase)", "Email", "Tên ngắn tự nối @pvn.vn", "Có", "Màn hình đăng nhập", "Không", "", "", "Dùng tài khoản Supabase sẵn có.")
add(T, "Tài khoản", "Quyền", "memberships.role", "Danh mục", "admin; editor; reader", "Có", "Không (cấp trong database)", "Không", "1 admin", "", "admin: toàn quyền, xem Kết quả khảo sát; editor: thêm/sửa; reader: chỉ xem.")
add(T, "Tài khoản", "Tên hiển thị", "memberships.display_name", "Văn bản", "", "Không", "Không", "Đầu trang", "", "", "Tên hiển thị của người dùng.")
add(T, "Lịch sử", "Lịch sử thay đổi", "audit", "Bản ghi bất biến", "", "Tự động", "Không", "Không (đã bỏ tab lịch sử)", "3.459 dòng", "", "Mọi tạo/sửa/liên kết/xóa đều ghi lại, kể cả bản chụp hồ sơ đã dọn (purge_record).")

RELATIONS = [
    ("Triển khai & hợp tác", "Chủ thể PVN – Đầu mối", "Đơn vị", "Đơn vị/Ban PVN chủ trì hoạt động.", "157", "Đúng 1 đầu mối / hoạt động", "Trang hoạt động › Chủ thể PVN; form thêm hoạt động"),
    ("Triển khai & hợp tác", "Chủ thể PVN – Phối hợp", "Đơn vị", "Đơn vị phối hợp.", "1", "Nhiều", "Trang hoạt động › Chủ thể PVN › Chọn có sẵn"),
    ("Triển khai & hợp tác", "Bên thực hiện", "Đối tác", "Đối tác thực hiện hoạt động.", "103 (19 có ghi chú)", "Tối đa 1 bên thực hiện (đối tác, liên danh hoặc đơn vị PVN)", "Trang hoạt động › Bên thực hiện; form thêm hoạt động từ trang đối tác"),
    ("Triển khai & hợp tác", "Bên thực hiện (qua liên danh)", "Liên danh", "Hoạt động ký qua liên danh; hiện trên trang từng thành viên.", "2", "Kèm 'đối tác đầu mối của hoạt động' (lead_member_id): 0 đã ghi", "Form thêm hoạt động › Qua liên danh"),
    ("Triển khai & hợp tác", "Bên thực hiện (đơn vị PVN)", "Đơn vị", "Đơn vị PVN thực hiện cho đơn vị khác.", "1 (VPI · PQPOC)", "Thay cho đối tác", "Trang hoạt động › Bên thực hiện › Đơn vị PVN"),
    ("Triển khai & hợp tác", "Bài toán chuẩn", "Bài toán chuẩn", "Bài toán chuẩn hoạt động thuộc về.", "85 / 157", "Tối đa 1", "Form thêm hoạt động; trang hoạt động › Bài toán chuẩn"),
    ("Bài toán chuẩn", "Đơn vị đầu mối ưu tiên", "Đơn vị", "Đơn vị/Ban được giao dẫn dắt.", "14", "Tối đa 1", "Trang bài toán › Đơn vị › Đặt làm đầu mối"),
    ("Bài toán chuẩn", "Đơn vị tiềm năng áp dụng", "Đơn vị", "Đơn vị có thể áp dụng.", "141", "Nhiều ('Toàn bộ các đơn vị' = gắn tất cả)", "Trang bài toán › Đơn vị"),
    ("Đối tác", "Bài toán chuẩn có thể đáp ứng", "Bài toán chuẩn", "Đối tác tiềm năng cho bài toán.", "0", "Nhiều", "Trang đối tác › Bài toán chuẩn có thể đáp ứng"),
    ("Liên danh", "Thành viên", "Đối tác", "Đối tác trong liên danh; một đối tác đầu mối.", "8 (4 liên danh, 2 có ghi chú)", "Một liên danh nhiều đối tác; một đối tác nhiều liên danh", "Trang đối tác › Liên danh; trang liên danh › Thành viên"),
    ("Đối tác", "Đầu mối liên hệ", "Người liên hệ", "Người phụ trách bên đối tác.", "23", "Nhiều; 1 đầu mối chính", "Trang đối tác › Đầu mối liên hệ"),
    ("Đơn vị", "Đầu mối", "Người liên hệ", "Người phụ trách bên đơn vị.", "38", "Nhiều", "Trang đơn vị › Đầu mối"),
    ("Mốc làm việc", "Gắn với đối tác / đơn vị / hoạt động / chuyên gia", "Đối tác; Đơn vị; Hoạt động; Chuyên gia", "Nhật ký làm việc, kết quả, bước tiếp theo.", "Đơn vị 1 · Chuyên gia 1", "Nhiều", "Trang đối tác/đơn vị/hoạt động › Mốc"),
    ("Tài liệu tham khảo", "Gắn với chuyên gia / hồ sơ khác", "Chuyên gia; Mốc; Đối tác", "CV, bio, biên bản; thư mục file.", "Chuyên gia 4 · Mốc 1 · Đối tác 1", "Nhiều", "Trang chuyên gia; mục File & tài liệu"),
    ("Mọi hồ sơ", "File & tài liệu", "Tài liệu", "File đính kèm.", "Đơn vị 31 · Đào tạo 6 · Hoạt động 3 · Đối tác 1 · Tài liệu tham khảo 1", "Nhiều", "Mục File & tài liệu trên mọi trang"),
]

COMMON = [
    ("id", "Định danh", "UUID tự sinh", "Khóa duy nhất của mọi hồ sơ; dùng trong đường dẫn trang."),
    ("kind", "Loại hồ sơ", "Danh mục", "unit, contact, engagement, partner, collaboration, use_case, learning_event, expert, reference."),
    ("title", "Tên", "Văn bản ≤250, bắt buộc", "Tên hiển thị của hồ sơ."),
    ("code", "Mã", "Văn bản, tự sinh", "Mã đối chiếu nguồn (KS-…, WB-…, AI-…, BTC-xx). Chỉ bài toán chuẩn hiển thị mã."),
    ("summary", "Tóm tắt", "Văn bản dài ≤10.000", "Mô tả ngắn; với dữ liệu khảo sát thường là câu tự sinh."),
    ("status", "Trạng thái", "Theo danh mục của từng loại", "Xem sheet Danh mục giá trị."),
    ("version", "Phiên bản", "Số nguyên", "Tăng mỗi lần sửa; chặn hai người ghi đè nhau."),
    ("created_by / created_at / updated_at", "Người tạo, thời điểm tạo / sửa", "Tài khoản; thời gian", "Ghi tự động. updated_at có thể hiện là 'Cập nhật lần cuối'."),
    ("archived_at", "Cột kỹ thuật (luôn trống)", "Thời gian", "Từ 15/10/2026 xóa là xóa hẳn (bản chụp ghi vào lịch sử, hành động delete). Cột còn vì 15 chức năng database đọc nó; ràng buộc giữ luôn trống."),
]

CONTEXT = [
    ("subject_role", "Hoạt động / bài toán chuẩn → Đơn vị", "lead; supporting", "Đầu mối (đúng 1) / phối hợp hoặc tiềm năng áp dụng. Hoạt động: 157 lead · 1 supporting; bài toán: 14 lead · 141 supporting."),
    ("consortium_role", "Liên danh → Đối tác thành viên", "lead; member", "Đầu mối liên danh / thành viên."),
    ("Vai trò (cũ)", "Liên danh → Đối tác thành viên", "Đứng đầu liên danh; Thành viên", "Nhãn cũ từ workbook, app đọc như consortium_role."),
    ("lead_member_id", "Hoạt động → Liên danh", "Mã đối tác thành viên", "Đối tác làm đầu mối của riêng hoạt động đó trong liên danh (0/2 đã ghi)."),
    ("note", "Mọi quan hệ", "Văn bản ≤5.000", "Ghi chú trên liên kết: 19 ở bên thực hiện, 2 ở thành viên liên danh."),
]

SYSTEM = [
    ("documents", "Tài liệu", "id, title, visibility, created_by, created_at, archived_at", "documents", "Kho File & tài liệu; ẩn file = archived_at."),
    ("document_versions", "Phiên bản file", "document_id, version, filename, mime_type, size_bytes, storage_path, checksum", "versions", "Mỗi lần tải là một phiên bản bất biến."),
    ("document_links", "Gắn file vào hồ sơ", "record_id, document_id, version_id", "links", "Một file dùng chung được cho nhiều hồ sơ."),
    ("sources", "Bản nguồn", "source_key, source_type, title, unit_code, payload, status, linked_record_id", "sources", "Bản gốc phiếu khảo sát, danh mục đơn vị, workbook đối tác — không sửa/xóa được."),
    ("source_links", "Bản nguồn ↔ hồ sơ", "source_id, record_id", "source_links", "Hồ sơ được tạo/chuẩn hóa từ bản nguồn nào."),
    ("audit", "Lịch sử thay đổi", "record_id, actor_id, action, before_value, after_value, created_at", "audit", "Bất biến; giữ cả bản chụp hồ sơ đã dọn."),
    ("memberships", "Tài khoản & quyền", "user_id, role, display_name", "memberships", "Ai được vào app và quyền gì."),
    ("module_registry", "Cấu hình trường", "kind, statuses, fields", "registry", "Database kiểm tra dữ liệu lưu vào khớp danh mục trường/trạng thái."),
]

OVERVIEW = [
    ("Bài toán chuẩn", "lead_unit_id / potential_unit_ids", "Đơn vị đầu mối ưu tiên và đơn vị tiềm năng."),
    ("Bài toán chuẩn", "potential_partner_ids", "Đối tác đã gắn 'bài toán chuẩn có thể đáp ứng'."),
    ("Hoạt động", "partner_id / provider_unit_id", "Đối tác hoặc liên danh thực hiện / đơn vị PVN thực hiện."),
    ("Hoạt động", "party_lead_id", "Đối tác đầu mối của hoạt động trong liên danh."),
    ("Hoạt động", "standard_id / lead_unit_id / unit_ids", "Bài toán chuẩn, đơn vị đầu mối, mọi đơn vị tham gia."),
    ("Đối tác / liên danh", "member_ids / lead_member_id", "Thành viên và đầu mối của liên danh."),
    ("Đơn vị", "parent_id", "Đơn vị cấp trên (quan hệ 'parent', chưa dùng)."),
    ("Mốc / chuyên gia / đào tạo", "partner_ids, unit_ids, activity_ids, expert_ids", "Đối tượng gắn với mốc, chuyên gia, hoạt động đào tạo."),
    ("Quy tắc đếm", "Đang POC / triển khai", "Hoạt động ở POC, Triển khai chính thức, Pilot hoặc Vận hành."),
    ("Quy tắc đếm", "Đối tác của một hoạt động", "Bên thực hiện; liên danh được tính cho từng thành viên, không tính là một đối tác."),
    ("Quy tắc đếm", "Số đối tác trên dashboard", "Không tính hồ sơ liên danh (69 đối tác, 4 liên danh)."),
    ("Quy tắc đếm", "Trạng thái đối tác (lần đầu)", "Có hoạt động POC trở lên → Đang hợp tác; chỉ Đề xuất / Đang trao đổi → Tiềm năng; chỉ Tạm dừng / Dừng → Tạm dừng. Sau đó sửa tay."),
]

# Claude's answer to each reviewer note, keyed by (group, key): (proposal, impact on data and app).
ANSWERS = {
    ("Đối tác", "status"): ("Bỏ 'Chiến lược'; còn Đang hợp tác, Tiềm năng, Tạm dừng. Mức chiến lược chuyển sang trường mới 'Hợp tác chiến lược'.", "0 đối tác đang ở 'Chiến lược' — không đổi dữ liệu."),
    ("Đối tác", "partner_type"): ("Danh mục mới: Công ty công nghệ; Đơn vị đào tạo và NCKH; Cơ quan nhà nước; Tư vấn; Truyền thông/sự kiện; Liên danh.", "Đổi 59 'Doanh nghiệp/nhà cung cấp' → Công ty công nghệ; 7 Trường đại học + 1 Viện → Đơn vị đào tạo và NCKH. Ba loại còn lại giữ (bạn chưa nhắc)."),
    ("Đối tác", "country"): ("Chuyển thành danh mục chọn: 10 quốc gia đang dùng (Việt Nam, Hoa Kỳ, Trung Quốc, Vương quốc Anh, …) + 'Khác'.", "34/69 đã có giá trị, giữ nguyên; 35 còn trống."),
    ("Đối tác", "specialties"): ("Chuyển thành nhiều tag chọn từ danh sách gợi ý (vd. Nền tảng AI, Tư vấn giải pháp, Hạ tầng/Cloud, Thị giác máy tính, Chatbot/NLP, Phân tích dữ liệu, Digital Twin, IoT), vẫn cho thêm tag mới.", "Mới 2/69 có giá trị. Cần bạn chốt danh sách tag ban đầu."),
    ("Đối tác", "aliases"): ("Bỏ.", "68 giá trị chỉ từng dùng để ghép tên khi nhập; tìm kiếm không dùng. Dữ liệu cũ lưu lại trong lịch sử."),
    ("Đối tác", "legal_name"): ("Bỏ.", "Mất 1 giá trị (CodeValue) — lưu lại trong lịch sử."),
    ("Đối tác", "origin"): ("Bỏ.", "67 giá trị kỹ thuật, không hiển thị."),
    ("Đối tác", "document_notes"): ("Bỏ, sau khi chuyển 14 ghi chú có nội dung vào 'Giới thiệu ngắn' của đối tác (nếu trống) để không mất thông tin.", "Cần bạn đồng ý cách chuyển; nếu không cần giữ thì bỏ thẳng."),
    ("Đối tác", "internal_unit_code"): ("Bỏ (đã kiểm tra: 0/69 có giá trị, không chỗ nào dùng).", "Không mất dữ liệu."),
    ("Đối tác", "profile_url"): ("Bỏ.", "0/69 có giá trị; file giới thiệu đính kèm ở mục File & tài liệu."),
    ("Đối tác", "observed_on; source_note"): ("Bỏ. 'Ngày cập nhật cuối' không cần trường mới: hệ thống đã tự ghi updated_at, có thể hiện mờ 'Cập nhật lần cuối' trên trang.", "Áp dụng chung với ý kiến ở sheet Trường chung."),
    ("Đối tác", "strategic_level"): ("Thêm trường danh mục 'Hợp tác chiến lược' với 5 giá trị như bạn ghi, mặc định 'Không'; có bộ lọc trên dashboard.", "Lưu ý chồng ý với loại hoạt động 'MOU / hợp tác chiến lược': trường này ở cấp đối tác, loại hoạt động ở cấp từng hoạt động."),
    ("Đơn vị", "unit_type"): ("Thêm trường bắt buộc 'Phân loại đơn vị': Đơn vị thành viên; Ban/Văn phòng/Tổ chức thuộc Tập đoàn.", "28 đơn vị hiện có đặt là 'Đơn vị thành viên', trừ 'PETROVIETNAM' — cần bạn chốt. Các Ban chưa có trong danh mục sẽ thêm sau."),
    ("Đơn vị", "status"): ("Bỏ 'Chưa xác minh'; còn Đang hoạt động (mặc định), Ngừng hoạt động.", "Đổi cả 28 đơn vị sang 'Đang hoạt động'."),
    ("Đơn vị", "capabilities"): ("Bỏ.", "Nội dung gốc vẫn xem được ở Kết quả khảo sát của đơn vị — không mất thông tin."),
    ("Đơn vị", "governance"): ("Bỏ.", "Như trên."),
    ("Đơn vị", "observed_on; source_note"): ("Bỏ.", "Áp dụng chung với sheet Trường chung."),
    ("Trường chung", "observed_on"): ("Bỏ khỏi mọi loại hồ sơ.", "Đang có giá trị ở đơn vị 28, đối tác 50, hoạt động 134, đầu mối 39 (đều là ngày khảo sát) — lưu lại trong lịch sử."),
    ("Trường chung", "source_note"): ("Bỏ khỏi mọi loại hồ sơ.", "Truy vết nguồn vẫn còn qua bản nguồn (source_links) và lịch sử."),
    ("Trường chung", "visibility"): ("Bỏ; mọi thành viên có quyền đều xem mọi hồ sơ, phân quyền theo vai trò admin/editor/reader.", "Cả 391 hồ sơ và 42 file đang là 'team' — không ai mất quyền xem. Kiểm tra quyền trong database đơn giản hơn."),
    ("Trường chung", "archived_at"): ("Xóa là xóa hẳn: nút Xóa hồ sơ xóa luôn hồ sơ và liên kết, kèm bản chụp vào lịch sử như lượt dọn vừa rồi; bỏ chức năng khôi phục.", "Không hoàn tác được trên app — giữ hộp xác nhận ghi rõ tên hồ sơ. File đã gắn vẫn còn trong kho."),
}

# Value lists: (list, [(value, records using it, proposal from the review)]). Status lists of other kinds are added from stats.
VALUES = [
    ("Trạng thái hoạt động", [("Đề xuất", 53, ""), ("Đang trao đổi", 32, ""), ("POC", 33, ""), ("Triển khai chính thức", 25, ""), ("Pilot", 0, ""), ("Vận hành", 12, ""), ("Tạm dừng", 1, ""), ("Dừng", 1, "")]),
    ("Loại hoạt động", [("Bài toán đơn vị", 82, ""), ("POC", 4, ""), ("Đề tài KHCN", 0, ""), ("Hợp tác đối tác", 65, ""), ("Hạ tầng", 0, ""), ("Đào tạo", 1, ""), ("MOU / hợp tác chiến lược", 1, ""), ("Tư vấn", 4, "")]),
    ("Trạng thái hợp tác (đối tác)", [("Đang hợp tác", 29, ""), ("Tiềm năng", 38, ""), ("Tạm dừng", 2, "")]),
    ("Loại đối tác", [("Công ty công nghệ", 59, "Đã áp dụng"), ("Đơn vị đào tạo và NCKH", 8, "Đã áp dụng (gộp Trường đại học + Viện)"),
                      ("Cơ quan nhà nước", 0, ""), ("Tư vấn", 1, ""), ("Truyền thông/sự kiện", 1, ""), ("Liên danh", 4, "")]),
    ("Hợp tác chiến lược (đối tác)", [("Không", 0, ""), ("Biên bản ghi nhớ cấp đơn vị", 0, ""), ("Biên bản ghi nhớ cấp tập đoàn", 0, ""), ("Hợp tác chiến lược cấp đơn vị", 0, ""), ("Hợp tác chiến lược cấp tập đoàn", 0, ""), ("(chưa chọn)", 69, "")]),
    ("Quốc gia (đối tác) — danh mục 20 nước", [("Việt Nam", 16, ""), ("Hoa Kỳ", 6, ""), ("Trung Quốc", 3, ""), ("Vương quốc Anh", 3, ""), ("6 quốc gia khác", 6, ""), ("(trống)", 35, "")]),
    ("Chương trình AI", [("AI cho tìm kiếm, thăm dò và khai thác", 13, ""), ("AI cho vận hành, hiệu suất, độ tin cậy và toàn vẹn tài sản", 12, ""), ("AI cho hoạch định, thương mại và tối ưu chuỗi năng lượng", 15, ""),
                         ("AI cho dự án đầu tư, EPCI và quản lý dự án", 4, ""), ("AI cho an toàn, môi trường, rủi ro và kiểm soát tuân thủ", 5, ""), ("AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp", 10, ""), ("AI cho nghiên cứu, đổi mới sáng tạo và sản phẩm, công nghệ", 2, "")]),
    ("Mức dẫn dắt của Tập đoàn", [("Tập đoàn triển khai", 4, ""), ("Tập đoàn dẫn dắt, đơn vị triển khai", 10, ""), ("Đơn vị chủ động", 0, "")]),
    ("Tình trạng danh mục (bài toán chuẩn)", [("Chính thức", 61, ""), ("Chờ rà soát", 0, "")]),
    ("Tình trạng hoạt động (đơn vị)", [("Đang hoạt động", 28, ""), ("Ngừng hoạt động", 0, "")]),
    ("Phân loại đơn vị", [("Đơn vị thành viên", 27, "Mặc định"), ("Ban/Văn phòng/Tổ chức thuộc Tập đoàn", 1, "Cơ quan Tập đoàn")]),
    ("Định dạng file cho phép", [("PDF", 42, ""), ("Word (doc, docx)", 0, ""), ("Excel (xls, xlsx)", 0, ""), ("PowerPoint (ppt, pptx)", 0, ""), ("TXT, CSV", 0, ""), ("Ảnh PNG/JPG", 0, "")]),
    ("Quyền tài khoản", [("admin", 1, ""), ("editor", 0, ""), ("reader", 0, "")]),
]


# Every answer above was applied by migration 202610140010 on 15/10/2026.
ANSWERS = {key: ("ĐÃ ÁP DỤNG 15/10/2026. " + proposal, impact) for key, (proposal, impact) in ANSWERS.items()}
