# Dashboard và hồ sơ đối tác

Trang tổng quan trước đây chưa cho người điều hành thấy nhanh quy mô và hồ sơ vừa thay đổi. Bản mới dùng đúng số lượng hồ sơ mà người đăng nhập được đọc, gồm bốn KPI, một biểu đồ cơ cấu và bốn danh sách mới nhất độc lập. Thiết kế không suy diễn xu hướng hoặc hiệu quả từ dữ liệu chỉ có số lượng hiện tại.

Hồ sơ đối tác được thu về một trục nghiệp vụ: đối tác → hợp tác → nội dung hợp tác và nhật ký. Đầu mối là thông tin xem nhanh; liên danh dùng quan hệ đối tác trực tiếp; file của mốc làm việc giữ chủ sở hữu là engagement và vẫn xuất hiện trong vùng File & tài liệu chung. Các record và quan hệ cũ không bị xóa.

Một lỗi thứ tự được phát hiện khi rà soát: bản xem nhanh cắt ba engagement trước khi sắp ngày, phụ thuộc vào thứ tự projection. Cách sửa là lấy toàn bộ nhóm đã lọc quyền, khử trùng, sắp xếp theo ngày nghiệp vụ rồi mới giới hạn. Quy tắc này cũng giúp đầu mối chính và hai chiều liên danh không bị che bởi thứ tự trả về.

Đợt thay đổi không cần migration hoặc ghi dữ liệu thật. Kết quả cuối: 127 kiểm tra Playwright, ESLint, TypeScript và production build đều đạt; ứng dụng chạy tại cổng 3100.
