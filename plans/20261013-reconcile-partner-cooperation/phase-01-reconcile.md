# Pha 1: Đối soát và chuẩn hóa an toàn

## Căn cứ

- [Cấu trúc database](../../docs/database.md)
- [Quy tắc nhập workbook](../../docs/partner-workbook-import.md)
- [Migration chuyển nội dung hợp tác một cấp](../../supabase/migrations/202610130002_flatten_partner_cooperation.sql)
- Workbook v6 do người dùng cung cấp, sheet `03_dim_doi_tac`, `06_dim_lien_danh`, `07_bridge_ld_thanh_vien`, `08_fact_hop_tac`, `09_bridge_ht_doi_tac`.

## Phát hiện trước khi sửa

- 75 hồ sơ đối tác đang hoạt động; ADT là hồ sơ **nhóm ADT–AIQ** từ khảo sát và workbook `LD002`, có liên kết hai thành viên ADT Global / ADT Hi-tech (đầu mối) và AIQ. Không được nhập ADT vào ADT Global.
- 160 nội dung hợp tác đang hoạt động. Có 53 cặp cùng bản nguồn khảo sát, cùng đối tác và cùng phạm vi. Mỗi cặp gồm một `KS-COLLABORATION-*` và bản `KS-COLLABORATION_ITEM-*` được chuyển thành cùng cấp. Bản item không có file, quan hệ ngoài đối tác/đơn vị, trường nội dung riêng hoặc chỉnh sửa sau chuyển đổi.
- Các hồ sơ AWS mang nguồn và nội dung khác nhau; chưa có bằng chứng đủ chắc để chọn một danh tính. Các tên FPT/Viettel/VNPT/GE là nhóm mẹ, công ty con hoặc nhãn nguồn cần giữ riêng đến khi có xác minh.

## Thực hiện

1. Thêm migration transaction có điều kiện đối chiếu nguồn, đối tác, chủ thể PVN, nội dung và tài sản; chỉ lưu trữ bản item trùng, ghi audit kèm ID hồ sơ giữ lại.
2. Đổi tiêu đề hồ sơ nhóm ADT thành `Nhóm ADT–AIQ` khi đúng ID, loại nhóm, hai thành viên và nguồn workbook `LD002`; không đổi pháp nhân thành viên.
3. Bổ sung fixture/kiểm tra SQL cho trường hợp trùng an toàn, nguồn và quan hệ được giữ, dossier loại bản lưu trữ.
4. Chạy kiểm tra SQL, áp dụng migration qua Supabase MCP, đối chiếu số liệu và một số hồ sơ đại diện.

## Rủi ro và phục hồi

Lưu trữ là thao tác có thể khôi phục; bản gốc và mọi ánh xạ nguồn/audit vẫn còn. Migration dừng nếu phát hiện một cặp mã nguồn giống nhau nhưng có tài sản, quan hệ hoặc nội dung riêng. Không xóa vật lý hồ sơ/tài liệu. Nếu cần quay lại, khôi phục bản item theo ID và version sau khi đối chiếu audit.
