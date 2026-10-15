# Kiến trúc ứng dụng Danh mục AI

Cập nhật: 13/10/2026. Tài liệu mô tả hợp đồng ứng dụng và migration trong mã nguồn; kết quả triển khai và kiểm thử thực tế được ghi riêng tại [verification.md](verification.md).

## Luồng ứng dụng

Ứng dụng Next.js cung cấp giao diện React và API cùng nguồn. `catalog-app.tsx` quản lý phiên đăng nhập, điều hướng danh mục và đường dẫn hồ sơ. `isPrimaryDossier` trong `src/lib/record-files.ts` giới hạn CV cho `unit`, `partner`, `expert`, `use_case` và `collaboration`: trang `overview` dùng `record-summary.tsx` và các hàm `dossier-summary.ts`, còn `information` mở toàn bộ trường chi tiết. Các loại hồ sơ phụ hiển thị trực tiếp thông tin đầy đủ, các vùng nghiệp vụ có dữ liệu và vùng file trên cùng một trang; liên kết tới từng phần cuộn/focus vào vùng tương ứng. Hồ sơ `reference` mở vùng file trước, metadata nằm trong phần có thể mở rộng. Mục lục chỉ cuộn/focus trong DOM, còn thao tác xem sâu tiếp tục dùng ID phần nội dung trong URL. Các loại hồ sơ, trường chi tiết và danh mục trạng thái được khai báo tại `src/lib/catalog.ts`; `src/lib/dossier.ts` quy định phần nội dung và chiều liên kết theo từng chủ thể.

Các thao tác API dùng phiên Supabase của người gọi để gọi gateway `public.ai_catalog_*`. Schema `ai_management` giữ dữ liệu quản trị riêng, không dùng quyền quản trị khảo sát làm quyền ứng dụng. [api-contract.md](api-contract.md) và [database.md](database.md) mô tả các endpoint, kiểm soát phiên bản, RLS và Storage.

Giao diện chính đi từ đơn vị, đối tác, chuyên gia và bài toán chuẩn; các hồ sơ nghiệp vụ được mở trong ngữ cảnh chủ thể. Đường dẫn lưu chuỗi hồ sơ và tab để quay lại đúng vị trí. Tạo mới trong một phần nội dung gọi gateway tạo hồ sơ và quan hệ trong cùng transaction; lỗi liên kết không để lại hồ sơ mồ côi.

Dashboard dùng gateway thống kê hiện hữu cho KPI/cơ cấu và gọi độc lập danh sách trang đầu của `partner`, `collaboration`, `expert`, `use_case` cho các khối mới nhất. Một khối lỗi hoặc rỗng không làm mất nội dung của các khối còn lại. Dashboard chỉ trình bày tổng số hồ sơ đọc được và thời điểm cập nhật; không suy diễn tiến độ, xu hướng hay chỉ số hiệu quả.

Hồ sơ đối tác dùng bốn selector riêng trên projection hiện hữu. Đầu mối lấy quan hệ `contact` trực tiếp và hiển thị như bảng danh bạ. **Nội dung hợp tác** là một cấp duy nhất: mỗi `collaboration` liên kết tới đúng một đối tác, một hoặc nhiều chủ thể PVN bằng quan hệ `unit`, và không quá một use case chuẩn bằng quan hệ `use_case`. Vai trò chủ thể đầu mối nằm trong `context.subject_role`; loại hợp tác nằm trong danh mục quản trị và tiến độ dùng trạng thái của record, không dùng phần trăm. Nhật ký gom mốc trực tiếp hoặc qua nhiều quan hệ `engagement → collaboration`; một mốc có thể thuộc nhiều nội dung hợp tác. Liên danh chỉ lấy quan hệ partner trực tiếp và lưu một đầu mối bằng `context.consortium_role`.

Trang tổng hợp luôn dựng đủ các section theo thứ tự cấu hình, kể cả khi số hồ sơ bằng 0; trạng thái trống ghi rõ “Chưa có hồ sơ” thay vì dồn vào một nhóm khác. Mỗi section đặt thao tác ngay cạnh nội dung; không cần mở một lớp xem nhanh rồi mới vào form. Thông tin chính và các nhóm đơn giản sửa ngay trong section, đầu mối sửa trên bảng. Mốc làm việc sửa nhanh trên dòng; nút **Nội dung hợp tác & file** mở dialog để quản lý quan hệ và tài liệu. Nội dung hợp tác mở dialog trực tiếp; dialog có khóa focus, đóng bằng Escape và trả focus về nút gọi. Liên danh dùng bộ chọn cố định loại `partner`, cho phép tạo hồ sơ đối tác mới bằng cùng `RecordEditor`, và lưu vai trò đầu mối trên quan hệ trực tiếp.

Nội dung hợp tác là một hồ sơ nghiệp vụ riêng nhưng không nằm thêm trong điều hướng chính. Ba vùng quan hệ chuẩn là `organizations` (các chủ thể PVN), `contents` (không quá một use case chuẩn) và `engagements` (mốc hợp tác). Nội dung công việc khác vẫn là chính record `collaboration`; người dùng chỉ tạo use case khi chủ động chọn “Tạo mới use case”. Quan hệ mốc luôn có chiều `engagement → collaboration`, dù tạo từ nội dung hay gắn từ mốc; vì vậy cùng một mốc có thể xuất hiện trong nhiều thư mục nội dung và một lần trong nhật ký tổng hợp sau khi khử trùng. File trực tiếp của `collaboration` tạo thư mục logic mang tên nội dung; file trực tiếp của mốc nằm trong mốc và được tổng hợp qua các nội dung đã gắn mà không sao chép tài liệu.

Loại `collaboration_item` cùng các loại cũ khác đã bị gỡ hẳn ngày 14/10/2026 (xem mục mô hình lộ trình AI).

## Mô hình lộ trình AI (từ 14/10/2026)

- **Bài toán chuẩn** (`use_case`) → nhóm theo 7 chương trình (trường `program`); đầu mối ưu tiên và đơn vị tiềm năng là quan hệ `use_case → unit` có `subject_role`.
- **Hồ sơ hoạt động** (`collaboration`) → `unit` (đầu mối/phối hợp), `partner` (≤1, có thể là liên danh), `use_case` (≤1), mốc `engagement → collaboration`, file.
- **Đối tác** (`partner`) → trạng thái chung trong `status`; `partner → use_case` là năng lực đáp ứng; liên danh là `partner → partner` với `consortium_role`.
- Trang danh mục chính là dashboard (`module-dashboard.tsx` + từng `*-dashboard.tsx`) dựng từ `GET /api/overview`; dữ liệu dùng chung qua `use-overview.ts` (cache 30 giây, xóa khi lưu). Trang chi tiết dùng các selector trong `src/lib/dossier.ts`; các phần mới hiển thị bằng `roadmap-sections.tsx`, dải số liệu bằng `record-highlights.tsx`. Hàm tính toán thuần nằm trong `src/lib/overview.ts`. Mọi bảng danh sách trên dashboard dùng chung khung `catalog-table.tsx` (logic thuần ở `src/lib/catalog-table.ts`): tìm kiếm không dấu, bộ lọc chọn chỉ cho trường đang hiện trong bảng (tên đơn vị/đối tác/chuyên gia tìm qua ô tìm kiếm, khớp cả tên đầy đủ lẫn viết tắt/tên ngắn), lọc nhanh "thiếu thông tin", sắp xếp theo cột, xuất CSV (UTF-8 có BOM) đúng các dòng đang lọc; mỗi dashboard tự khai báo cột/bộ lọc (vd. `activity-table-columns.tsx`). Trạng thái lọc giữ trong phiên khi mở hồ sơ rồi quay lại. Overview cấp thêm `next_notes`, `last_meeting_date` (hoạt động), `contact_name`, `contact_count` (đối tác), `expertise_summary` (chuyên gia) cho các cột quản trị. Tìm kiếm phía máy chủ (`ai_catalog_list`, dùng cho "Chọn có sẵn" và "Xem tất cả kết quả") cũng khớp viết tắt đơn vị và tên ngắn đối tác qua `ai_management.record_search_text`. Đầu mối (`contact`) không có trang riêng: mở một đầu mối sẽ chuyển tới mục Đầu mối của đơn vị/đối tác (hoặc trang Danh bạ nếu chưa thuộc đâu); thêm/sửa/xoá trong bảng `contact-table.tsx` trên trang đơn vị/đối tác. Trang Danh bạ (`directory-page.tsx`, `GET /api/directory` → `ai_catalog_directory`) gom đầu mối đơn vị, đối tác và chuyên gia. Xoá đơn vị/đối tác xoá luôn đầu mối chỉ thuộc riêng nó (`ai_catalog_delete`, audit `delete_with_organisation`).
- App còn 9 loại hồ sơ: `unit`, `contact`, `engagement`, `partner`, `collaboration`, `use_case`, `learning_event`, `expert`, `reference`. Mười loại cũ (`demand`, `implementation`, `poc`, `data_asset`, `course`, `learning_session`, `resource`, `affiliation`, `expertise`, `collaboration_item`) đã bị gỡ hẳn bằng migration `202610140009`: xóa hồ sơ, bảng chi tiết, cấu hình và code; mỗi hồ sơ bị xóa được chụp đầy đủ vào audit `purge_record`.

## Mô hình chuyên gia và quan hệ tổ chức

Migration `202610080004_partner_expert_dossiers.sql` bổ sung `expert` và `reference` (cùng `expertise`, `affiliation` — đã gộp vào `expert` ngày 14/10/2026 rồi gỡ hẳn):

| Loại | Ý nghĩa | Liên kết chính |
|---|---|---|
| `expert` | Một chuyên gia, thông tin liên hệ, hình thức tham gia và phạm vi chia sẻ | Đối tác/đơn vị/hợp tác/bài toán/đợt làm việc kết nối tới chuyên gia |
| `reference` | Metadata tài liệu hoặc URL tham khảo | `reference → expert` bằng `expert`; các chủ thể khác dùng `related` |

Quan hệ `speaker` và `participant` của khóa học/đợt tổ chức/buổi chuyên đề nhận cả đầu mối `contact` và chuyên gia `expert`, theo phạm vi loại nguồn được gateway cho phép. Hồ sơ chuyên gia có phần giảng dạy/hội thảo để tạo hoặc gắn những hồ sơ này theo đúng chiều. Chức năng này không làm phát sinh đợt nhập dữ liệu đào tạo hoặc POC của đơn vị.

## Hồ sơ tổng hợp và phân quyền

Projection hồ sơ lấy quan hệ trực tiếp và tối đa một bước qua hồ sơ nghiệp vụ được cho phép. Projection lấy chuyên gia tham gia hợp tác/đợt làm việc/đào tạo. Không đi xuyên qua chuyên gia khác, đơn vị, đối tác hoặc bài toán khác để gom toàn bộ hồ sơ của họ. Trung gian và đích đều phải đọc được và chưa lưu trữ.

Các bảng chi tiết mới dùng cùng khóa ngoại ghép `(record_id, kind)`, kiểm tra kiểu/độ dài, RLS và gateway như các loại hiện hữu. Reader không ghi; hồ sơ riêng tư vẫn chỉ người tạo hoặc admin đọc được. `Field.group` chỉ là metadata trình bày để biểu mẫu và tổng quan chia theo nhóm nghiệp vụ; nó không thêm cột nghiệp vụ hoặc thay đổi quyền truy cập.

Trạng thái xác minh tiếp tục được giữ để tương thích dữ liệu cũ nhưng không hiển thị như trạng thái vận hành. Hồ sơ mới dùng trạng thái bảo thủ khi có lựa chọn: chuyên gia chưa liên hệ, tài liệu tham khảo chưa đính kèm. Xem hồ sơ không sửa dữ liệu đã lưu.

## Xóa hồ sơ và khôi phục

**Xóa hồ sơ** đặt cạnh **Chỉnh sửa** trên hồ sơ đang hoạt động khi người dùng có quyền ghi. Xác nhận nêu tên hồ sơ và việc giữ lại hồ sơ liên quan, file và bản nguồn. Giao diện dùng DELETE hiện có để đặt `archived_at`, không xóa các dòng dữ liệu; thao tác audit cũ vẫn mang tên `archive`.

Thùng rác đã bỏ khỏi giao diện ngày 14/10/2026; xóa xong app quay lại trang đang xem trước đó. Toàn bộ hồ sơ đã gỡ tính đến 14/10/2026 được xóa hẳn bằng migration `202610140009` (có bản chụp trong audit). Hồ sơ gỡ sau mốc đó vẫn chỉ mang `archived_at`; mở trực tiếp bằng đường dẫn vẫn khôi phục được.

POST `/api/records/:id/restore` gọi gateway bổ sung từ migration `202610080005`. Khóa hàng và phiên bản ngăn ghi đè thay đổi đồng thời; gateway chỉ chấp nhận hồ sơ đã xóa, trả lại trạng thái hoạt động và ghi audit `restore`. Hồ sơ liên quan, các quan hệ, tệp/phiên bản ghim, nguồn và metadata không bị xóa hoặc khởi tạo lại. Giao diện không cung cấp xóa vĩnh viễn; xóa hẳn chỉ thực hiện bằng migration dọn dữ liệu có bản chụp audit.

## File, thư mục và tài liệu tham khảo

`reference` lưu loại tài liệu, URL HTTP(S), ngày tài liệu khi biết chính xác, ghi chú thời điểm, phiên bản và phạm vi sử dụng. Nó không chứng minh tệp đã được tải lên hoặc URL đã được đọc. Đường dẫn tệp cục bộ trong workbook không được đưa vào trường URL hay biến thành nút tải xuống; ghi chú nghiệp vụ có thể nêu tài liệu chưa được đính kèm mà không công bố đường dẫn máy.

`record-files.tsx` cung cấp một vùng **File & tài liệu** dùng chung cho CV và hồ sơ phụ. Vùng này trình bày tệp trực tiếp của hồ sơ, các `reference` đang đọc được và tệp từ hồ sơ nghiệp vụ liên quan. `references` không còn là mục riêng; URL cũ được ánh xạ sang `documents`. Mở thư mục hoặc nhóm tài liệu tải dữ liệu hồ sơ tương ứng và hiển thị ngay trong vùng file, không mở thêm CV. Các `reference` cũ vẫn là những bản ghi hiện hữu, giữ nguyên URL và metadata; đây là thay đổi cách trình bày, không phải chuyển đổi hoặc di chuyển dữ liệu.

Thư mục mới là một bản ghi `reference` có `data.reference_type = "Thư mục"`, tên do người dùng nhập và `visibility` kế thừa hồ sơ cha. Tạo thư mục dùng `POST /api/records/:id/related`: quan hệ `expert` nếu cha là chuyên gia, `related` với các loại khác, chiều `to-parent`. Hồ sơ và quan hệ cùng được tạo trong transaction. Giao diện chỉ hỗ trợ một cấp và không tạo thư mục trong `reference`. Đổi tên dùng PATCH có ID/phiên bản, giữ các trường metadata khác; vì bản ghi có thể được nhiều hồ sơ dùng chung, biểu mẫu nêu rõ tên mới áp dụng ở mọi nơi đang dùng.

Tệp thực tế vẫn dùng `documents`, các phiên bản bất biến `document_versions`, `document_links` và bucket riêng tư hiện hữu. Tải mới hoặc dùng file có sẵn gắn tài liệu vào ID hồ sơ hoặc thư mục đang mở. Mặc định chia sẻ khi tải mới theo `visibility` của đích. Mỗi liên kết vẫn giữ phiên bản ghim trong dữ liệu cũ, nhưng giao diện chỉ hiển thị file hiện dùng và không quản lý phiên bản. File trực tiếp ở gốc không cần thư mục. Giao diện cho gỡ liên kết ở từng hồ sơ/thư mục, ẩn file khỏi kho chung, xóa thư mục vào Thùng rác và xem trước PDF/ảnh/văn bản; chưa có di chuyển hoặc nhập nguyên cây thư mục.

Migration `202610130004_document_actions.sql` bổ sung `documents.archived_at` và hai gateway gỡ liên kết/ẩn tài liệu. File ẩn bị loại khỏi danh sách, hồ sơ và quyền tải/xem trước; các object Storage và lịch sử phiên bản vẫn được giữ để đối soát. Migration `202610130005_document_trash_guard.sql` chặn gỡ liên kết hoặc ẩn file còn gắn vào hồ sơ đã xóa. Xóa thư mục chỉ lưu trữ record `reference`, không ẩn những file bên trong kho chung.

Biểu mẫu tải lên hiển thị tên và dung lượng tệp đã chọn; kiểm tra định dạng, tệp rỗng và giới hạn 20 MiB từng tệp trước khi gửi. API tiếp tục kiểm tra MIME, dung lượng và quyền bằng phiên người gọi. Nhiều tệp được gửi tuần tự, lỗi giữa chừng giữ lại phần chưa hoàn tất để thử lại; không coi một đợt nhiều tệp là giao dịch atomic. Thao tác trong vùng file chỉ hiện khi người dùng có quyền ghi cả hồ sơ đang xem lẫn đích đang mở; hồ sơ lưu trữ không cho ghi. API tiếp tục kiểm tra quyền độc lập. Tệp đính kèm của hồ sơ nghiệp vụ vẫn giữ riêng từng phiên bản ghim; có liên kết hồ sơ không cấp thêm quyền đọc tệp. Projection không gom tệp của một chuyên gia liền kề chỉ vì người đó có mặt trong quan hệ.

## Nguồn workbook và nhập dữ liệu

Nhập workbook là quy trình quản trị riêng, không chạy khi người dùng mở trang. Quy trình dùng bản nguồn bất biến và ánh xạ nguồn tới hồ sơ để đối soát, chạy lại và kiểm tra thay đổi. Mã nguồn phải đi cùng danh tính workbook/sheet, không dùng mã dòng đơn lẻ làm khóa toàn cục.

Tên chuẩn khớp chính xác và ánh xạ đã có được ưu tiên. Không tự gộp theo tên gần giống, thương hiệu chung hoặc alias đang xung đột. Trường có nội dung không bị ghi đè bằng ô trống hay giá trị khác chưa được giải quyết; các dòng bị bỏ qua hoặc xung đột phải có báo cáo. Dòng nguồn nhiều email được tách email chính và nội dung bổ sung; mốc ngày chưa chính xác được giữ ở trường văn bản tương ứng.

Hợp tác bổ sung cấp Tập đoàn được tách với hồ sơ đã nhập từ khảo sát. Nhãn nguồn nội bộ không đủ để kết luận bản ghi mới, loại bỏ trùng lặp hoặc đổi phạm vi thành cấp Tập đoàn. Liên danh và từng thành viên được giữ riêng. Nội dung “trao đổi tiếp theo” là ghi chú, không tạo nhiệm vụ, lịch hẹn hoặc lộ trình tự động.

Bản nguồn khảo sát và các tệp đã lưu giữ nguyên; admin xem bản khảo sát của đơn vị tại mục **Kết quả khảo sát**. Công cụ nhập khảo sát và workbook đối tác đã chạy xong và được gỡ khỏi code ngày 14/10/2026 (bản sao trong `.private/code-backups/`); dữ liệu nay sửa trực tiếp trên app.
