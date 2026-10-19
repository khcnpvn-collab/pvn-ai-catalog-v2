# Mở rộng định dạng tệp đính kèm

Trạng thái: hoàn thành (19/10/2026).

## Phạm vi và tiêu chí

- Giữ luồng tải nhiều tệp, giới hạn 20 MiB/tệp, quyền truy cập và kho riêng hiện có.
- Cho chọn và tải TXT, PPT, PNG vốn đã hỗ trợ; bổ sung MD, RTF, GIF, WEBP, ZIP, 7Z và RAR ở mọi form tài liệu dùng chung.
- Một danh sách MIME/đuôi tệp dùng chung cho kiểm tra giao diện và API; chấp nhận MIME chuẩn, biến thể phổ biến và MIME nhị phân chung của tệp hợp lệ.
- File không có khả năng xem trực tiếp sẽ được tải về; không nới quyền đọc hoặc xử lý nội dung archive.

## Thực hiện

Xem [phase-01-implement-and-verify.md](phase-01-implement-and-verify.md).

## Kết quả kiểm chứng

7 kiểm tra tải tệp, 94 kiểm tra validation và 7 kiểm tra API khi chưa đăng nhập đều đạt; lint, typecheck và production build đạt. Supabase Storage API xác nhận bucket `ai-catalog-documents` giới hạn 20 MiB và không có allowlist MIME riêng. Bản mẫu Sites tại cổng 3180 chỉ ghi nhớ tên tệp; app thật dùng cổng 3100.
