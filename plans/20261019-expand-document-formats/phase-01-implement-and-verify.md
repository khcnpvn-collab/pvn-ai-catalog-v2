# Cập nhật luồng tải tài liệu

## Bối cảnh

Form chung dùng `src/lib/document-upload.ts`, `src/components/document-library.tsx`; API kiểm tra MIME riêng trong `src/app/api/[...path]/route.ts`. Storage bucket không giới hạn MIME theo migration nền. Các kiểm tra hiện có ở `tests/document-upload.spec.ts`.

## Bước thực hiện

1. Chuyển danh sách định dạng và MIME về helper dùng chung; API gọi helper này và vẫn lưu MIME chuẩn.
2. Cập nhật gợi ý định dạng trong form và trường `accept`.
3. Sửa kiểm tra định dạng cho nhóm mới và đường biên MIME/đuôi; giữ từ chối đuôi thực thi hoặc mạo danh MIME rõ ràng.
4. Cập nhật mô tả hợp đồng API, chạy test tập trung rồi lint/typecheck/build do thay đổi mã dùng chung.

## Rủi ro và hoàn tác

MIME do trình duyệt cung cấp có thể rỗng hoặc chung; dùng đuôi tệp để chọn MIME chuẩn lưu trữ, từ chối MIME cụ thể không khớp. Không thay đổi schema, bucket, quyền hay dữ liệu cũ. Hoàn tác các tệp mã và tài liệu trong phạm vi này nếu kiểm thử phát hiện hồi quy.
