# Chỉnh sửa hồ sơ và file trực tiếp

Trạng thái: hoàn thành (13/10/2026).

## Phạm vi
- Loại bỏ lớp nút “Chỉnh sửa” trung gian trên CV; hiển thị thao tác tạo và sửa ở đúng bảng/dòng. Đầu mối sửa trong lưới.
- Mốc làm việc và nội dung hợp tác mở form một lần; dialog hiển thị trọn chiều cao và thanh lưu luôn tới được.
- File có thể gỡ khỏi hồ sơ/thư mục, thư mục có thể xóa; giao diện chỉ hiển thị file hiện dùng, không hiển thị quản lý phiên bản. Xem trước định dạng trình duyệt hỗ trợ.
- Dùng các thành phần chung để áp dụng trên hồ sơ đơn vị, đối tác, chuyên gia, use case và hồ sơ phụ.

## Kiểm chứng
- Test tập trung cho bảng đầu mối, luồng file và SQL quyền gỡ tài liệu.
- Typecheck, lint, build, database test; kiểm tra app trên desktop/mobile.
- Migration mới chỉ chạm schema `ai_management` và gateway riêng, dữ liệu khảo sát không đổi.

Kết quả: 140/140 kiểm tra Playwright, 510 kiểm tra PostgreSQL biệt lập, lint, typecheck và production build đạt. Hai migration tài liệu đã áp dụng qua Supabase MCP; dữ liệu tệp hiện hữu được bảo toàn.
