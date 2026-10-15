# Hợp nhất AWS và tách tên đối tác ghép

Trạng thái: hoàn tất ngày 13/10/2026; migration đã áp dụng và đối chiếu trên Supabase.

## Căn cứ

Người dùng xác nhận gộp `AWS` vào `Amazon Web Services (AWS)`; các nhãn `Microsoft, Google` và `VNPT AI, CMC OpenAI` là lỗi chuẩn hóa, gồm các đối tác riêng. Đối chiếu Supabase ngày 13/10/2026: AWS phụ có 1 nguồn, 2 quan hệ hợp tác (1 nội dung đã lưu trữ), 0 file; mỗi hồ sơ ghép có 1 nguồn use case, 1 nội dung hợp tác, 0 file và 0 quan hệ khác. Các hồ sơ thành viên Microsoft, Google Cloud, VNPT AI, CMC OpenAI đã có.

## Thay đổi

- `src/lib/survey-normalization.ts`: sửa quy tắc rõ ràng cho ba trường hợp nguồn; bảo toàn danh tính/code hồ sơ chuẩn khi tiếp nhận lại.
- `supabase/migrations/202610130007_reconcile_partner_identities.sql`: chuyển nguồn/quan hệ AWS; tạo nội dung hợp tác riêng cho từng thành viên từ hai dòng ghép; lưu trữ ba hồ sơ đối tác lỗi và ghi audit.
- `tests/survey-normalization.spec.ts`, `scripts/tests/partner-identity-*`, `scripts/tests/run-database-tests.sh`: xác minh code ổn định, một đối tác trên một hợp tác, nguồn và quan hệ đầy đủ.
- `docs/database.md`, `docs/verification.md`, `docs/partner-workbook-import.md`, báo cáo pha 2: cập nhật trạng thái triển khai và các giới hạn diễn giải nguồn.

## Kiểm chứng và an toàn

Chỉ triển khai nếu preflight khớp chính xác mã, nguồn, quan hệ, phiên bản và không có tệp riêng; migration nguyên tử và có audit. Dữ liệu khảo sát gốc giữ nguyên; các hồ sơ lỗi được lưu trữ để phục hồi nếu cần. Chạy unit test chuẩn hóa, SQL biệt lập, rồi kiểm tra số liệu trên Supabase.
