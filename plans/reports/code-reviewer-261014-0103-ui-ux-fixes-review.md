# Review mã — đợt sửa giao diện/trải nghiệm (plan 261013-1829)

Reviewer: agent code-reviewer (độc lập). Typecheck + lint sạch. Không phát hiện lỗi chặn; các mục dưới đã xử lý trừ khi ghi khác.

| # | Mức | Phát hiện | Xử lý |
|---|---|---|---|
| 1 | Cao | Đổi tab hồ sơ (Xem tất cả, Xem đầy đủ thông tin, chọn mục) bỏ qua cảnh báo chưa lưu | `changeTab` gọi `confirmDiscardChanges()` |
| 2 | Cao | "Hoàn tất"/"Sửa thông tin" trong dialog đóng form tạo nhanh đang nhập dở | Hỏi trước qua `leave()` theo vùng dialog |
| 3 | TB | Nút Back/Forward trình duyệt bỏ qua cảnh báo | **Chưa xử lý** — thuộc định tuyến, gộp đợt logic |
| 4 | TB | Sau khi lưu mà editor vẫn hiển thị, `data-dirty` mất đồng bộ | Reset `editedFields` khi lưu thành công |
| 5 | TB | "Đóng chỉnh sửa" bỏ dữ liệu không hỏi | Hỏi trước khi đóng |
| 6 | TB | Xác nhận "Bỏ" làm mất focus khỏi dialog; Esc đóng cả dialog | Focus "Giữ lại", trả focus về "Bỏ", Esc chỉ hủy xác nhận; nhóm có `aria-label` |
| 7 | TB | Viền focus mờ trên nền navy (~2.1:1) | `.catalog-banner/.dossier-heading :focus-visible` dùng `--focus-dark` |
| 8 | TB | Thẻ đơn vị lặp lĩnh vực ở mô tả và tag | Ẩn tag khi trùng mô tả |
| 9 | TB | Mục lục nhảy về mục trước khi bấm mục cuối trang | Giữ mục đã bấm 800ms |
| 10–19 | Thấp | deps scroll-spy theo id; giữ tiêu đề là thay đổi khi đổi loại; dedupe bài toán trước khi đếm; "hồ sơ hợp tác" còn sót; nhãn tải dialog; `recordShortName` thử từng trường; cột mũi tên ẩn cả tiêu đề; nhóm chọn file có tên; `returnValue` cho beforeunload; đổi tên biến bị che; dấu `·` không bị đọc | Đã xử lý tất cả |

Quyết định thêm: bộ lọc "Trong Thùng rác" không được nhớ khi quay lại danh mục (tránh danh sách trông như trống).

Xác minh lại trên app: dialog mở phần tổng quan; "Bỏ" → focus "Giữ lại" → trả focus về "Bỏ", liên kết giữ nguyên; cảnh báo chưa lưu chặn chuyển trang và Hủy (giả lập trả lời "không"/"có", không lưu dữ liệu).

## Câu hỏi còn mở

- Có cần chặn nút Back của trình duyệt khi đang nhập dở (mục 3)?
- Các form sửa nhanh (đầu mối trong bảng, mốc làm việc, tải file, thư mục) chưa gắn cảnh báo chưa lưu — có muốn mở rộng?
