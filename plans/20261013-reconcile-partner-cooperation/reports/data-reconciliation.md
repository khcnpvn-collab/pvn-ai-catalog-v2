# Kết quả đối soát đối tác và hợp tác

Ngày 13/10/2026. Đối chiếu trên Supabase hiện tại và workbook v6 do người dùng cung cấp.

| Nhóm | Kết luận | Xử lý |
|---|---|---|
| ADT / ADT Global / AIQ | `ADT` là hồ sơ nhóm `LD002`; ADT Global (`DT0002`) là thành viên đầu mối, AIQ (`DT0003`) là thành viên. Không phải ba tên cho một pháp nhân. | Đổi nhãn nhóm thành **Nhóm ADT–AIQ**; giữ các hồ sơ và cạnh thành viên. |
| 53 cặp hợp tác khảo sát gốc/item | Cùng mã nguồn, đối tác, chủ thể PVN, phạm vi và kết quả; bản item không có tài sản hay chỉnh sửa riêng. | Lưu trữ 53 item, giữ 53 gốc, nguồn, quan hệ và audit; 160 → 107 nội dung hoạt động. |
| Hai hợp tác AWS cùng phạm vi | Một hợp tác với PVPGB, một với PVPOWER. | Giữ riêng theo chủ thể PVN. |
| `AWS` / `Amazon Web Services (AWS)` | Bản nguồn đơn lẻ ghi tên “Amazon”, lĩnh vực “AWS”; người dùng xác nhận đây là cùng đối tác quản trị. | Chuyển nguồn và hai quan hệ hợp tác vào Amazon Web Services; lưu trữ hồ sơ AWS dư. |
| `GE` / `GE Vernova`, FPT và các công ty con, Viettel và các công ty con, VNPT và VNPT AI | Tên cùng thương hiệu không đủ để suy ra cùng chủ thể hợp tác. | Giữ riêng. |
| `Microsoft, Google` và `VNPT AI, CMC OpenAI` | Người dùng xác nhận đây là lỗi chuẩn hóa tên nhiều bên, không phải liên danh. | Tách thành bốn nội dung hợp tác riêng gắn Microsoft, Google Cloud, VNPT AI, CMC OpenAI; cùng giữ bài toán, chủ thể PVN và nguồn; lưu trữ hai hồ sơ ghép. |

Kiểm tra sau triển khai: 75 đối tác, 107 hợp tác hoạt động, 53 item lưu trữ có audit, 418 bản nguồn, 648 ánh xạ nguồn, 674 quan hệ, 42 tài liệu/42 liên kết file. Không còn cặp mã gốc/item đồng thời hoạt động; mọi hợp tác hoạt động có đúng một đối tác. Bộ SQL biệt lập chạy đạt sau khi thêm migration 006 và kiểm tra dossier.

Sau migration 007 trên Supabase lúc 11:38 UTC ngày 13/10/2026: **71 đối tác và 110 nội dung hợp tác đang hoạt động**, ba hồ sơ danh tính lỗi lưu trữ, bốn nội dung riêng từ hai nhãn ghép, 418 nguồn, 652 ánh xạ nguồn, 42 tài liệu/42 liên kết file. Không còn quan hệ nào trỏ tới ba hồ sơ đã gộp/tách; không còn tên ghép hoặc AWS dư trong danh mục hoạt động. Mọi nội dung hợp tác hoạt động có đúng một đối tác. Truy vấn trùng theo cùng đối tác, cùng chủ thể PVN và cùng phạm vi chuẩn hóa trả 0 cặp. Tên gần giống nhưng là nhóm/công ty thành viên như FPT, Viettel, VNPT hoặc GE/Vernova vẫn giữ riêng, không suy diễn cùng pháp nhân. `Google` trong nguồn được ánh xạ vào hồ sơ Google Cloud đã có, không khẳng định đây là tên pháp nhân được đơn vị khai báo. Số lượng đầu/cuối của pha 2 có thể khác mốc pha 1 vì người dùng tiếp tục chỉnh sửa app giữa hai lần kiểm tra.
