# 14/10/2026 — Tổ chức lại danh mục theo lộ trình AI

**Bối cảnh.** Người dùng (Ban KHCN) thấy app cũ quản lý mọi thứ như hồ sơ ngang hàng: liên danh là một hồ sơ riêng, bài toán tách 4 loại (bài toán, nhu cầu, triển khai, POC). Sau 3 vòng phỏng vấn, mô hình chốt: 7 chương trình AI → 61 bài toán chuẩn → hồ sơ hoạt động (một mẫu cho bài toán đơn vị, POC, đề tài, hợp tác); đối tác có trạng thái chung; liên danh nhẹ; chuyên gia và đào tạo rút gọn; mọi tab mở bằng số liệu và biểu đồ.

**Quyết định kỹ thuật.**
- Không đổi tên kind trong database: `use_case` = bài toán chuẩn, `collaboration` = hồ sơ hoạt động. Giữ được trigger, gateway, quan hệ và file; chỉ thêm cột và cập nhật registry.
- `demand` đổi kind tại chỗ (xóa dòng chi tiết, cập nhật `records.kind`, thêm dòng chi tiết mới) để giữ ID, file, nguồn, audit.
- Trường không còn dùng giữ trong registry và đánh dấu `hidden` ở UI: `ai_catalog_save` ghi NULL cho trường registry không gửi lên, nên bỏ khỏi registry sẽ an toàn nhưng gửi thừa sẽ bị từ chối; editor lọc `data` theo registry.
- Một gateway `ai_catalog_overview()` thay cho nhiều request: mọi dashboard và dải số liệu dùng chung một lần tải có cache 30 giây, bị xóa khi lưu.
- Kiểm tra hợp đồng registry/UI chuyển về cuối bộ SQL vì nó luôn phải so với registry sau migration mới nhất.

**Sự cố gặp phải.**
- PostgreSQL cục bộ không khởi động trên macOS: "postmaster became multithreaded" → cần `LC_ALL=en_US.UTF-8`.
- Ràng buộc danh sách cố định của `learning_event.event_type` mang tên `..._check1` (ràng buộc thứ hai trên cột); bản đầu của migration gỡ nhầm ràng buộc độ dài. Phát hiện khi soát tên ràng buộc trên production, đổi sang tìm theo nội dung định nghĩa.
- Bộ chuẩn hóa khảo sát kiểm tra trạng thái theo registry hiện hành; cập nhật sang trạng thái mới để nhập lại vẫn hợp lệ.

**Kiểm chứng trước khi áp.** Đối chiếu chỉ đọc trên production: 70/70 nhu cầu khớp đúng một dòng danh mục; mọi viết tắt đơn vị tồn tại và duy nhất; 35 hồ sơ hợp tác theo bài toán, 12 hồ sơ có đúng một đối tác.
