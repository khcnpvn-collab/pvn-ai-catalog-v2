# Áp dụng thiết kế navy đã duyệt

Ngày: 13/10/2026.

## Bối cảnh và quyết định

Thiết kế navy đã được duyệt trên Sites được đưa vào ứng dụng danh mục AI hiện hữu. Bộ màu `#081b36`, `#102d55`, `#17477c`, font Be Vietnam Pro phục vụ nội bộ với bốn trọng lượng và giấy phép đi kèm, cùng các khối trắng bo góc tạo nhận diện thống nhất. Dashboard dùng lại ảnh năng lượng đã tạo cho mẫu duyệt và ghi rõ đây là hình ảnh ý tưởng tạo bằng AI.

Danh mục chính có kiểu thẻ và bảng, dùng cùng kết quả tìm kiếm, lọc và phân trang. Hồ sơ tổng hợp có bìa navy, dải thông tin cập nhật, mục lục và các vùng nội dung tách biệt. Tên, số liệu, ngày, trạng thái và quan hệ lấy từ hồ sơ ứng dụng; ảnh đại diện bằng ký tự lấy từ tên, không thay bằng người hoặc tổ chức giả.

Điều hướng chính được làm phẳng; nhóm Tra cứu & quản trị mở rộng giữ các công cụ hiện có, bao gồm Thùng rác và nguồn dành cho admin. Thanh trên giữ nền sáng cả trên di động, footer bổ sung tên Petrovietnam và AI WORKSPACE. Các quyết định trước về Lexend, góc bo đồng loạt 4px, cấm ảnh nền và thanh trên di động nền tối được thay bằng [hướng dẫn thiết kế hiện hành](../design-guidelines.md).

## Phạm vi bảo toàn và kiểm chứng

Thay đổi thuộc lớp trình bày: giữ xác thực, quyền đọc/ghi, tìm kiếm, tạo/sửa, xóa/khôi phục, quan hệ, file/thư mục và phạm vi khảo sát; không cần migration cơ sở dữ liệu. Các quy tắc ẩn trạng thái xác minh, phạm vi chia sẻ trên màn hình nghiệp vụ và nguồn khảo sát chỉ dành cho admin tiếp tục áp dụng.

Nhật ký này ghi nhận quyết định thiết kế và phần triển khai đã đối chiếu mã nguồn, không xác nhận triển khai production hay kết quả kiểm thử chưa chạy. Tình trạng kiểm chứng tổng thể được theo dõi trong [kế hoạch áp dụng thiết kế](../../plans/20261013-navy-design-adoption/plan.md).
