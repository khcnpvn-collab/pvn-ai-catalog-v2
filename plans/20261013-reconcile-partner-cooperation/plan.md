# Đối soát hồ sơ đối tác và nội dung hợp tác

Trạng thái: hoàn tất hai pha đối soát đã được xác nhận (13/10/2026).

## Phạm vi

1. Đối chiếu danh mục đối tác với workbook v6, nguồn khảo sát và quan hệ trên Supabase.
2. Chỉ hợp nhất các nội dung hợp tác có cùng bản nguồn, cùng đối tác, cùng phạm vi và không có trường, liên kết hoặc tệp riêng. Giữ hồ sơ gốc có trạng thái nghiệp vụ đầy đủ hơn; lưu trữ bản tạo từ `collaboration_item`, giữ nguồn và dấu vết audit.
3. Làm rõ hồ sơ nhóm ADT–AIQ để không bị hiểu là trùng với thành viên ADT Global. Giữ riêng các thành viên và quan hệ liên danh.
4. Báo cáo các cặp còn mơ hồ; chỉ gộp AWS và tách hai nhãn đối tác ghép sau khi người dùng xác nhận. Giữ riêng công ty con/nhóm khác nếu chưa có chứng cứ đồng nhất.

## Pha thực hiện

- [Phase 1: Đối soát và chuẩn hóa an toàn](phase-01-reconcile.md) — hoàn tất
- [Phase 2: Hợp nhất AWS và tách đối tác ghép tên](phase-02-identity-reconciliation.md) — hoàn tất
- [Báo cáo dữ liệu và các trường hợp còn mở](reports/data-reconciliation.md)

## Tiêu chí nghiệm thu

- Toàn bộ cặp hợp tác từ cùng một phiếu nguồn có bằng chứng trùng được gộp về một hồ sơ hoạt động; không mất nguồn, file, quan hệ hoặc audit.
- Hồ sơ nhóm ADT–AIQ được phân biệt rõ với ADT Global và AIQ; hai thành viên vẫn tra cứu được.
- AWS được gộp về hồ sơ Amazon Web Services; hai nhãn đối tác ghép được tách thành các hồ sơ thành viên và nội dung hợp tác riêng. Các nhóm/công ty con còn mơ hồ vẫn giữ riêng.
- Kiểm tra SQL biệt lập và số liệu trước/sau trên Supabase đạt.
