# Sửa giao diện, trải nghiệm, thẩm mỹ

Nguồn: [báo cáo rà soát](../reports/review-261013-1807-logic-ui-ux-aesthetic-audit.md). Lỗi logic (tìm kiếm, gỡ liên kết, N+1, liên danh, tên file, dữ liệu cũ) để đợt sau theo giải thích của người dùng.

## Quyết định người dùng (13/10/2026)

- Thuật ngữ: "Bài toán AI" mọi nơi; bỏ "use case" trên giao diện. "Nội dung hợp tác" thay "Hồ sơ hợp tác".
- Hero dashboard: giữ nguyên kích thước; chỉ bỏ nút trùng đích ở tiêu đề.
- Nút Xóa hồ sơ: giữ vị trí cạnh Chỉnh sửa, đổi sang nút phụ nhẹ.
- Danh mục: gộp tiêu đề + banner thành 1 khối; bỏ eyebrow "PETROVIETNAM / AI WORKSPACE" lặp lại.

## Hạng mục — trạng thái: Hoàn thành khi tick

1. [x] Lỗi CSS: `.table-scroll` relative; bảng đầu mối không tràn; dấu `*`; "06File"; badge kéo dài; dòng counts có ngăn cách. (Footer: giữ nguyên — đo lại thấy `min-height` của vùng nội dung đã đẩy footer gần đáy, không phải lỗi thật.)
2. [x] Thang chữ: chữ thường ≥ 12px, nhãn in hoa ≥ 11px; nút/bảng 13px.
3. [x] Thuật ngữ & câu chữ: Bài toán AI, Nội dung hợp tác, "Danh mục AI" ở topbar, câu chữ cũ.
4. [x] Danh mục: khối tiêu đề gộp; bỏ tổng số lặp; giữ trạng thái (trang, từ khóa, lọc, kiểu xem) khi quay lại; không nháy khi đổi trang; thẻ gọn hơn, avatar dùng tên viết tắt, mô tả đơn vị theo lĩnh vực; bảng có cột Phân loại.
5. [x] Hồ sơ: mục lục theo vị trí cuộn; Hồ sơ tổng hợp giới hạn mục + "Xem tất cả"; nút Xóa nhẹ; trạng thái mốc không hiện nhãn xác minh.
6. [x] Dialog nội dung hợp tác/mốc: mở bước tổng quan trước; xác nhận khi "Bỏ" liên kết.
7. [x] Cảnh báo thay đổi chưa lưu (đóng dialog, Hủy, chuyển trang, đóng tab).
8. [x] Khung: icon menu riêng biệt, aria-current; ô tìm toàn cục rộng hơn và đồng bộ; bỏ nút trùng ở dashboard; "Dùng file có sẵn" dạng danh sách.
9. [x] Kiểm tra: typecheck, lint, build ✅; Playwright validation+API 134/134 sau review, bộ đầy đủ trước đó 140/142 (2 bài đăng nhập desktop quá hạn 30s do máy tải nặng); duyệt app 1440/375 ✅; docs + README ✅; review mã ✅ — [báo cáo](../reports/code-reviewer-261014-0103-ui-ux-fixes-review.md).

## Ràng buộc

Không đổi API, schema, quyền. Không xóa code chết trong đợt này (thuộc nợ kỹ thuật, làm cùng đợt logic).
