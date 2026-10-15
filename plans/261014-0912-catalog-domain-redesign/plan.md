# Tái cấu trúc mô hình danh mục AI

Trạng thái: **đã thống nhất hướng, chưa sửa app** · Cập nhật 14/10/2026

## Vì sao
App đang coi ~19 loại là hồ sơ ngang hàng (liên danh = hồ sơ đối tác riêng; bài toán tách 4 loại). Người dùng chính là Ban KHCN, cần trả lời nhanh: đã làm gì với từng đối tác, trạng thái ra sao, mỗi loại bài toán đã làm với đối tác nào, đối tác nào tiềm năng.

## Nguyên tắc
1. Ít loại hồ sơ; đầu mối, mốc, file là dòng trong bảng.
2. Nhập một lần, hiện ở mọi nơi liên quan.
3. Phân loại bằng tag, nhập dần, gợi ý lại giá trị cũ; cùng cấu trúc.
4. Không suy diễn từ khảo sát; khảo sát là một khu chỉ đọc ở trang đơn vị.
5. Mỗi tab và trang chi tiết mở đầu bằng thẻ số liệu, biểu đồ, bảng tổng hợp; chi tiết ở dưới.

## Mô hình đã chốt
- **Chương trình AI** (7) → **Bài toán chuẩn** (trục chính) → **Hồ sơ hoạt động**.
- Bài toán chuẩn: tên, mô tả, chương trình, nhóm (tag tự do), mức dẫn dắt (Tập đoàn triển khai / Tập đoàn dẫn dắt, đơn vị triển khai / Đơn vị chủ động), đầu mối ưu tiên (đơn vị/Ban), đơn vị tiềm năng (hoặc cờ Toàn Tập đoàn), năm dự kiến, thuộc danh mục ưu tiên, use case card (chờ mẫu). Tạo nhanh khi nhập → nhãn *Chờ rà soát*.
- Hồ sơ hoạt động = bài toán cụ thể + nội dung hợp tác (gộp). Loại là tag (Bài toán đơn vị, POC, Đề tài KHCN, Hạ tầng, Đào tạo, MOU…). Trạng thái: Đề xuất → Đang trao đổi → POC → Triển khai chính thức → Pilot → Vận hành; Tạm dừng; Dừng. 1 đầu mối PVN (đơn vị/Ban) + n phối hợp; đối tác đơn lẻ hoặc liên danh; mô tả, thời gian, kết quả, kết luận, mốc, file.
- Đối tác: trạng thái chung (Chiến lược / Đang hợp tác / Tiềm năng / Tạm dừng), tag bài toán chuẩn có thể đáp ứng; hoạt động gom tự động, kể cả "qua liên danh X".
- Liên danh: tên, thành viên, đối tác đầu mối, file. Mốc ghi ở đối tác đầu mối.
- Đơn vị (gồm Tập đoàn và các Ban): hoạt động, đối tác, mốc/ghi chú, file, đầu mối, khu Kết quả khảo sát.
- Chuyên gia: hồ sơ cá nhân + nơi công tác. Đào tạo & hội thảo: một mẫu, loại là tag, thời gian, đối tượng, file, có thể gắn đối tác/chuyên gia.

## Giai đoạn
| # | Nội dung | Trạng thái |
|---|---|---|
| 0 | Đối soát danh mục bài toán chuẩn + bảng gắn bài toán đơn vị (file để duyệt, chưa sửa app) | File [doi-soat-bai-toan-chuan.xlsx](doi-soat-bai-toan-chuan.xlsx) người dùng đã quyết (14/10) |
| 1 | Bài toán: chương trình, bài toán chuẩn, hồ sơ hoạt động, chuyển dữ liệu, thống kê đầu tab | Xong (mã + migration, kiểm thử cục bộ) |
| 2 | Đối tác: trạng thái chung, tag tiềm năng, hoạt động tổng hợp, liên danh nhẹ, thống kê | Xong |
| 3 | Đơn vị: trang mới, Tập đoàn + Ban, khảo sát một khu, ẩn phần suy diễn, thống kê | Xong (Ban: bổ sung dần khi cần) |
| 4 | Chuyên gia, Đào tạo rút gọn; Tổng quan cập nhật chỉ số | Xong |

Mỗi giai đoạn: người dùng xem trên app trước khi sang giai đoạn sau. Không xóa dữ liệu; chuyển hoặc ẩn, có báo cáo trước–sau.

## Chuyển dữ liệu
- 69 "bài toán chuẩn" + 70 nhu cầu từ khảo sát → ~70 hồ sơ hoạt động loại Bài toán đơn vị, nhãn chờ rà soát; gắn bài toán chuẩn theo bảng đã duyệt.
- Nội dung hợp tác → hồ sơ hoạt động (giữ file, mốc); trùng bài toán đơn vị thì đề xuất gộp.
- Đợt làm việc → mốc. Liên danh giữ thành viên, file. Năng lực/quan hệ tổ chức chuyên gia → trường văn bản.
- Ẩn: CSDL, hiện trạng triển khai, mô tả tự điền từ phiếu.

## Nguồn danh mục bài toán chuẩn (nhận 14/10)
- Dữ liệu chép nguyên văn: [data/standard-problem-catalog-source.json](data/standard-problem-catalog-source.json) — 62 bài chuẩn (mã 1–62), bảng 14 bài ưu tiên, 70 bài toán đơn vị đã gắn mã chuẩn.
- Đã chốt: tên 7 chương trình theo danh sách vòng 1; tên #1 và #46 theo bảng 14; ưu tiên = đúng 14 bài trong bảng 14; 69 bài toán đơn vị giữ tên đang có trong app.
- Mặc định đang áp dụng (chờ duyệt trong file): 14 bài ưu tiên lấy mức dẫn dắt, đầu mối, đơn vị tiềm năng, năm theo bảng 14; nhóm bài toán theo bảng 62.
- Không dùng: Lĩnh vực đề xuất áp dụng, Ưu tiên PoC 2026. Cột Hiện trạng chỉ để đối chiếu.
- Số liệu: chương trình 1–7 có 13/12/15/4/5/11/2 bài chuẩn; 24 bài chuẩn chưa có bài toán đơn vị nào.

## Quyết định đối soát (14/10, từ file đã điền)
1. Ưu tiên đúng 14 bài; #2/#32 không ưu tiên, bỏ năm/đầu mối/đơn vị của chúng.
2–4. Đầu mối, đơn vị tiềm năng, năm, #17: theo bảng 14.
5. Nhóm bài toán: bảng 14 cho 14 bài ưu tiên, còn lại bảng 62.
6. #14/#49 "Ưu tiên bảng 14": cả hai không có trong bảng 14 → giữ tên theo bảng 62 (cần người dùng xác nhận).
7. Gộp #50 vào #54 (nhóm #54, mô tả #50) → 61 bài chuẩn. 8. Sửa mô tả #34.
9. "Toàn bộ các đơn vị" → gắn từng đơn vị (để thấy bài ưu tiên tiềm năng).
10. #61 một đầu mối: VPI. 11. Giữ mapping bài toán đơn vị. 12. Theo bảng 14: tạo hồ sơ PVCFC POC camera AI gắn #46.
13. Khớp 70 bài toán đơn vị theo đơn vị + tên khai báo, giữ tên trong app, báo dòng không khớp.

## Triển khai
- Supabase MCP thêm vào .mcp.json (14/10); chờ người dùng phê duyệt + xác thực qua /mcp.
- Hướng kỹ thuật: dùng lại kind use_case = Bài toán chuẩn, collaboration = Hồ sơ hoạt động (giữ ID, file, mốc); demand → đổi kind sang collaboration; use_case cũ (69) vào Thùng rác sau khi chuyển liên kết.
