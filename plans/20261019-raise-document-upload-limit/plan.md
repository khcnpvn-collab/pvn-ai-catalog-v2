# Nâng dung lượng file đính kèm

Trạng thái: hoàn thành ở mức 50 MiB theo lựa chọn của người dùng (19/10/2026).

## Kết luận hạ tầng

Supabase project hiện có global Storage limit 50 MiB và thuộc gói chưa hỗ trợ tăng lên 100 MiB (MCP trả `PaymentRequiredException`). Bucket riêng của app trước thay đổi là 20 MiB; bucket khảo sát giữ 20 MiB. Sau khi kiểm tra giới hạn gói, người dùng chọn giữ 50 MiB/tệp và không nâng gói. Constraint metadata vẫn cho phép tới 100 MiB nhưng giới hạn hiệu lực của app, bucket và global là 50 MiB.

## Phạm vi

- Form và API của app quản trị cho phép tối đa 50 MiB/tệp hiện tại, không đổi quyền hay dữ liệu khảo sát.
- Migration nâng constraint metadata lên 100 MiB, bucket app lên 50 MiB; bổ sung các đuôi tệp đã mở trong app vào gateway đăng ký tài liệu.
- Giữ nguyên API, tải từng tệp và kiểm tra MIME; tệp nén tải về, không giải nén.

## Kiểm chứng

Xem [phase-01-implement-and-verify.md](phase-01-implement-and-verify.md).

Hai migration `202610190001_document_upload_capacity.sql` và `202610190002_restore_document_filename_validation.sql` đã áp dụng qua Supabase MCP. Database thật xác nhận bucket app 50 MiB, bucket khảo sát 20 MiB, constraint metadata 100 MiB, gateway nhận ZIP và giữ nguyên kiểm tra tên tệp. Bộ PostgreSQL biệt lập đạt 576 kiểm tra; 94 validation, 7 API khi chưa đăng nhập, typecheck, lint và build đạt. Global giữ 50 MiB theo lựa chọn của người dùng.
