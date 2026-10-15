# Rà soát logic, giao diện, trải nghiệm, thẩm mỹ — Danh mục AI PVN

Ngày: 13/10/2026 · Phạm vi: toàn bộ `src/`, API, CSS; duyệt app thật tại localhost:3100 (tài khoản admin, chỉ xem, không lưu/xóa/tải lên) ở 1440×900 và 375×812.
Không chỉnh sửa mã. `npm run typecheck` và `npm run lint` sạch.

Ký hiệu: **[XM]** = đã xác minh trên app/API thật · **[Code]** = suy ra từ đọc mã.

## Điểm mạnh (giữ nguyên)

- API kiểm soát tốt: same-origin cho mọi mutation, kiểm quyền phía server, RPC + RLS, khóa phiên bản (409) khi sửa/xóa/khôi phục, không lộ service-role key.
- Có ý thức a11y: skip link, focus trap menu/dialog, `aria-*`, nút ≥ 44px, `prefers-reduced-motion`.
- Nhận diện navy nhất quán, logo/font phục vụ nội bộ; câu chữ tiếng Việt cẩn thận; trang đăng nhập gọn, đẹp.
- Luồng xóa → Thùng rác → khôi phục rõ ràng, có xác nhận tại chỗ.

## P1 — Nên sửa sớm (ảnh hưởng dùng thật / đúng dữ liệu)

1. **Tìm kiếm phân biệt dấu và chỉ tìm tên/mã/tóm tắt** [XM] — `supabase/migrations/202610080001_ai_catalog.sql:307` dùng `strpos(lower(title||code||summary))`. "vien han lam" → 0 kết quả (có dấu → 1); "Israel" → 0 dù CodeValue ghi quốc gia Israel. Không tìm được theo tên viết tắt, email, quốc gia, năng lực (nằm trong `data`). Với một danh mục tra cứu, đây là lỗi trải nghiệm lớn nhất. Đề xuất: `unaccent` + chỉ mục trigram trên title + các trường `data` chính.
2. **Không gỡ được liên kết sai ở hầu hết vùng hồ sơ** [Code] — `RecordRelations` (có "Bỏ liên kết") không còn được dùng (`src/components/record-relations.tsx:21`), `DossierSection` chỉ có Thêm/Chọn/Sửa. Liên danh không có xóa thành viên hay đổi đầu mối; đầu mối không có gỡ. Chỉ dialog Nội dung hợp tác có "Bỏ". Người dùng chọn nhầm sẽ không tự sửa được.
3. **Mobile bị cuộn ngang cả trang** [XM] — hồ sơ đối tác ở 375px có `scrollWidth = 860px`. Nguyên nhân gốc: `<span class="sr-only">` (absolute) trong `<th>` thoát khỏi `.table-scroll` vì container `position: static` (`globals.css:1388`). Cùng lỗi tiềm ẩn ở mọi bảng có cột "Xem hồ sơ"/"Thao tác". Sửa 1 dòng: `.table-scroll { position: relative }`.
4. **Desktop 1440px bảng đầu mối vẫn tràn ngang** [XM] — `min-width: 860px` (`globals.css:1156`) > vùng chứa 836px → thanh cuộn ngang dù chỉ 5 cột ngắn.
5. **"Hồ sơ tổng hợp" không tổng hợp** [XM] — Cơ quan Tập đoàn render đủ 64 mục "Hợp tác & đối tác" → vùng cao 7.900px, trang 12.100px (`record-summary.tsx:36-39` truyền toàn bộ entries). Cần giới hạn 5–10 mục + "Xem tất cả (64)" (tab chi tiết đã có sẵn).
6. **Request dây chuyền (N+1)** [XM] — mỗi thẻ nội dung hợp tác/mốc/use case tự gọi thêm `/dossier` (`partner-sections.tsx:57, 99, 140`). Hồ sơ ADT: 1 request 1,0s rồi 3 request ~0,8–1,0s → nội dung hiện "Đang đọc liên kết…" ~2s; đơn vị/use case nhiều nội dung sẽ chậm tuyến tính. Nên trả kèm chủ thể/use case/số mốc trong RPC dossier của hồ sơ cha.
7. **Dialog sửa Nội dung hợp tác khó hiểu** [XM] — mở ra là form thông tin; bấm **Hủy** không đóng mà chuyển sang bước Chủ thể/Use case/File (`partner-workspace-editor.tsx:101`). Bước liên kết bị "giấu" sau Lưu/Hủy. **Bỏ** gỡ liên kết ngay, không xác nhận (`:33`). Tạo nội dung mới từ mốc làm việc không xuất hiện trong danh sách tick vì `cooperationEntries` là dữ liệu cũ của trang cha (`:54-58, :126`).
8. **Mất dữ liệu đang nhập không cảnh báo** [Code] — Esc/bấm nền đóng dialog ngay (`editor-dialog.tsx:18, 30`); bấm menu bên/nút back của trình duyệt khi đang ở form (`catalog-app.tsx:35`); không có kiểm tra "có thay đổi chưa lưu".
9. **Liên danh hiển thị sai đầu mối** [Code] — khi đối tác chỉ là *thành viên* liên danh của đối tác khác (chỉ có quan hệ incoming), khối vẫn ghi "Đầu mối liên danh: Đối tác đang xem" (`partner-sections.tsx:136`).
10. **Tải nhiều file dùng chung một "Tên tài liệu"** [Code] — nhập tên rồi chọn 3 file → cả 3 cùng tên (`document-library.tsx:18`).

## P2 — Trải nghiệm & giao diện

**Danh mục**
- Quay lại từ hồ sơ mất trang, từ khóa, bộ lọc, kiểu xem (state không nằm trong URL — `record-list.tsx:38-44`).
- Tổng số hiện 3 lần (banner, dòng kết quả, chân trang — `record-list.tsx:55, 65, 67`); tiêu đề trang + banner lặp hai lớp khẩu hiệu trước khi tới dữ liệu.
- Mật độ thấp: 3 thẻ/hàng, cao ≥ 270px, 30 thẻ/trang → ~10 hàng cuộn. Bảng chỉ có Tên/Ngày ghi nhận/Cập nhật; thiếu Loại, Quốc gia, số nội dung hợp tác. Cột "Ngày ghi nhận" của đối tác đa phần "Chưa ghi nhận" vì form đối tác đã ẩn trường này.
- Không có lọc theo loại đối tác/quốc gia, không có sắp xếp (luôn theo ngày cập nhật).
- Avatar chữ cái ít giá trị: đơn vị toàn "CT", "TC" (Công ty/Tổng công ty) — nên dùng tên viết tắt (PVEP, BSR…).
- Mô tả thẻ đơn vị là câu mẫu của bộ nhập ("Đã nhận phiếu khảo sát. Hồ sơ hiện trạng được chuẩn hóa…") lặp ở mọi thẻ.
- Đổi trang/bộ lọc thay toàn bộ danh sách bằng skeleton (nháy), không cuộn lên đầu.
- Ô "Trong Thùng rác" ở mọi danh mục trùng chức năng với trang Thùng rác.

**Hồ sơ**
- Mục lục: mục đầu luôn tô "đang chọn" bằng CSS (`globals.css:3015`), không theo vị trí cuộn.
- Nút **Xóa hồ sơ** (viền đỏ) là thao tác nổi bật nhất ở bìa hồ sơ chính; trên mobile đứng ngay dưới tên. Nên đưa vào menu "…". Xóa xong bị đẩy sang Thùng rác thay vì về danh sách + thông báo "Hoàn tác".
- Thẻ nội dung hợp tác: badge trạng thái bị kéo dài 275px (cha là grid) [XM]; dòng "Cơ quan Tập đoàn  Nội dung công việc khác  0 mốc làm việc" mất ngăn cách thành câu liền (`globals.css:3029`).
- Tiêu đề "06File & tài liệu" dính số thứ tự (h2 `display:block`, các h2 khác `flex gap`) [XM].
- Nút bút chì cạnh thành viên liên danh mở form sửa *hồ sơ đối tác khác* thay thế cả vùng — dễ hiểu nhầm là sửa vai trò liên danh.
- Sửa mốc làm việc nhanh vẫn cho chọn trạng thái "Chưa xác minh" (`partner-sections.tsx:90`), trái quy ước ẩn nhãn xác minh.
- Dấu `*` bắt buộc rơi xuống dòng riêng dưới nhãn (`.field` là flex-column, `globals.css:519`) [XM].
- "Dùng file có sẵn" là `<select>` tới 200 file, không xem trước thông tin file.

**Khung & dashboard**
- Thuật ngữ không thống nhất: menu "Bài toán AI" vs nhãn module/topbar/KPI "Bài toán chuẩn" vs "Use case"; KPI "Hồ sơ hợp tác" vs "Nội dung hợp tác"; breadcrumb topbar "Lộ trình AI" trong khi sản phẩm là "Danh mục AI / AI WORKSPACE".
- Icon menu trùng: Đối tác = Chuyên gia (people), Tổng quan = Bài toán AI (grid), Danh mục dữ liệu = Nguồn & chuẩn hóa (database).
- Hero dashboard cao ~425px ở 1440×900 — gần nửa màn hình đầu cho ảnh minh họa; "Khám phá danh mục" và "Khám phá đối tác" cùng đích.
- Vai trò hiển thị 2 lần (badge topbar + sidebar). Ô tìm toàn cục chỉ rộng ~178px, không đồng bộ với trang tìm kiếm.
- Footer trôi giữa màn hình khi nội dung ngắn/đang tải.
- Câu chữ cũ: "xem các tệp… tại tab Tài liệu" (`unit-survey.tsx:51`) — tab đã đổi thành "File & tài liệu"; "Chưa có mốc trao đổi" vs tiêu đề "Mốc làm việc".
- Nguồn & chuẩn hóa: "Tạo hồ sơ chuẩn" rời trang, mất bản nguồn đang chọn, phải quay lại tìm; payload hiển thị JSON thô.

## P3 — Thẩm mỹ & nợ kỹ thuật

- **Chữ quá nhỏ** [XM]: 25+ quy tắc 8–11px — nav caption 9px, footer 9px, eyebrow banner 9px, ghi chú ảnh hero 8px, header bảng 10px in hoa, badge thẻ 10px; nút 12px, ô bảng 12px. Chữ có dấu in hoa ở 9–10px rất khó đọc. Hướng dẫn thiết kế ghi base 14px nhưng lớp CSS cuối hạ xuống 11–12px. Đề xuất sàn 12px cho meta, 13–14px cho nút/bảng.
- `globals.css` 3.542 dòng, nhiều lớp ghi đè (`.page-heading` 8 lần, `.topbar` 6, `.dossier-heading` 5); nhiều mã màu hex ngoài token (#637893, #6987ae, #9db2d1…). Khó bảo trì, dễ phát sinh lỗi như mục 3, 4.
- Mã JSX dạng "một dòng" rất dài (vd. `catalog-app.tsx:68` hàng nghìn ký tự) — đạt "dưới 200 dòng" về hình thức nhưng khó review/diff.
- Code chết: `RecordRelations`/`LinkForm`, `modalSectionIds`; `navigationGroups`, `partnerCooperationContent`, `summaryDocuments` chỉ còn test dùng.
- Đường fallback RPC cũ trong `route.ts:64-117, 149-166, 200-210` (unlink rồi link lại, không nguyên tử) — migration đã áp dụng nên có thể bỏ để giảm rủi ro/độ phức tạp.
- Dashboard tải 5 × 30 hồ sơ chỉ để hiện 3 mục mỗi khối; logic avatar lặp ở 2 nơi.
- Sửa nội dung hợp tác có phân loại cũ sẽ âm thầm đổi thành "Khác" và chép giá trị sang trường ẩn `source_status` khi lưu (`record-editor.tsx:14-24`).
- `catalog.ts` trộn 2 kiểu định dạng (gọn và JSON) cho định nghĩa module.

## Quan sát dữ liệu (không phải lỗi mã)

- ADT có 2 nội dung hợp tác gần trùng ("ADT/AIQ · PETROVIETNAM" và "Nội dung hợp tác ADT/AIQ · PETROVIETNAM", cùng phạm vi) — nên rà trùng.
- Chỉ 1 chuyên gia trong danh mục; KPI "1 hồ sơ" trên dashboard trông lạc lõng.

## Thứ tự đề xuất

1. Sửa nhanh CSS (≤ 1 giờ): `.table-scroll { position: relative }`, bỏ `min-width: 860px`, dấu `*`, "06File", badge kéo dài, ngăn cách dòng counts, mục lục active.
2. Tìm kiếm không dấu + tìm trong `data`.
3. Gỡ liên kết/đổi đầu mối/xóa thành viên liên danh ngay tại vùng hồ sơ (có xác nhận).
4. Giới hạn mục trong Hồ sơ tổng hợp + gộp N+1 vào RPC dossier.
5. Dialog nội dung hợp tác: một màn hình, nút Đóng/Hoàn tất rõ ràng; cảnh báo thay đổi chưa lưu.
6. Giữ trạng thái danh mục trong URL; thêm lọc loại/quốc gia + sắp xếp.
7. Thang chữ mới (sàn 12px), thống nhất thuật ngữ, gom token màu, dọn code chết.

## Câu hỏi chưa giải quyết

- Thuật ngữ chuẩn muốn dùng: "Bài toán AI", "Bài toán chuẩn" hay "Use case"? "Nội dung hợp tác" hay "Hồ sơ hợp tác"?
- Có chủ ý ẩn hoàn toàn chức năng gỡ liên kết (để tránh xóa nhầm) hay đó là thiếu sót khi bỏ tab "Quản lý liên kết"?
- Hero dashboard có bắt buộc giữ kích thước theo mẫu đã duyệt trên Sites không?
