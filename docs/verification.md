# Xác minh triển khai

Cập nhật: 19/10/2026. Ứng dụng: `pvn-ai-catalog`. Supabase project: `icycubrzvfptfehxqvfp`.

## Giới hạn tệp app quản trị (19/10/2026)

Theo yêu cầu nâng lên 100 MB/tệp, Supabase MCP trả `PaymentRequiredException` khi tăng global Storage limit từ 50 MiB lên 100 MiB; dự án hiện cần nâng gói trả phí để đạt mức này. Migration `202610190001_document_upload_capacity.sql` đã áp dụng: bucket `ai-catalog-documents` từ 20 lên 50 MiB, bucket khảo sát giữ 20 MiB, constraint metadata chuẩn bị tới 100 MiB và gateway nhận các định dạng app cho phép gồm ZIP/7Z/RAR. Migration `202610190002_restore_document_filename_validation.sql` khôi phục biểu thức kiểm tra tên tệp của gateway trước đó; xác minh live nhận ZIP và vẫn chặn dấu gạch ngược. App hiện kiểm tra 50 MiB/tệp, đúng giới hạn lưu trữ thực tế.

Đối chiếu live qua MCP: global 52.428.800 byte, bucket app 52.428.800 byte, bucket khảo sát 20.971.520 byte, constraint metadata `size_bytes <= 104857600`, gateway có đuôi mới. Bộ PostgreSQL biệt lập đạt **576 PASS**; Playwright validation **94 passed**, API khi chưa đăng nhập **7 passed**; typecheck, lint và production build đạt. Người dùng chọn giữ 50 MiB/tệp; không đổi gói dịch vụ hoặc nâng trần global lên 100 MiB.

## Database thật

Đã áp dụng migration `ai_catalog` thành công qua Supabase MCP ngày 08/10/2026. Đã tạo schema `ai_management` gồm 25 bảng có RLS, 15 loại hồ sơ, 15 gateway `public.ai_catalog_*`, bucket riêng tư `ai-catalog-documents` giới hạn 20 MiB và 8 policy Storage dành riêng cho bucket mới.

Đối chiếu trước/sau:

| Chỉ tiêu | Trước | Sau |
|---|---:|---:|
| Đơn vị khảo sát | 33 | 33 |
| Phiếu khảo sát | 33 | 33 |
| Profiles khảo sát | 37 | 37 |
| Hash cấu trúc cột khảo sát | `8ad24b40822bdcf6804c82cb64f9f1d5` | Không đổi |
| Hash policy public hiện hữu | `d7e6c3a26043fe7287ed6cc760441e03` | Không đổi |
| Hash hàm public hiện hữu, trừ gateway mới | `5dfe59d617800d332f7cdaa33506f30e` | Không đổi |

Bốn policy `survey_attachments_*` giữ nguyên nội dung. REST đọc `units` bằng cấu hình quản trị sẵn có trả HTTP 200. Ba gateway mới membership/stats/sources đã có trong PostgREST; gọi bằng anon trả HTTP 401, SQL code `42501`, không có lỗi thiếu hàm.

Đã xác minh `anon` không có quyền gọi gateway danh sách; `authenticated` có quyền gọi gateway nhưng không đọc trực tiếp bảng records hoặc tự thêm membership. Gateway kiểm tra quyền thành viên riêng. Khi khởi tạo, chưa có hồ sơ chuẩn hoặc membership; không nhập dữ liệu giả, không tự cấp quyền cho admin khảo sát. Đã cấp quyền quản trị đầu tiên cho tài khoản hiện hữu do người dùng chỉ định; không thay đổi mật khẩu hoặc quyền của app khảo sát.

## Hồ sơ chủ thể

Đã áp dụng migration `202610080002_entity_dossiers.sql` qua Supabase MCP (`entity_dossiers`) ngày 08/10/2026, bổ sung hai gateway đọc hồ sơ tổng hợp và tạo hồ sơ kèm liên kết; có tổng cộng 17 gateway ở đợt này. Đối chiếu sau áp dụng: 450 hồ sơ chuẩn và 33 phiếu khảo sát, số lượng không đổi. Thay đổi không nhập thêm dữ liệu hoặc sửa nguồn khảo sát; POC và đào tạo/hội thảo của đơn vị vẫn nằm ngoài phạm vi nhập.

Phạm vi kiểm chứng bổ sung: điều hướng đơn vị/đối tác/bài toán, tab và breadcrumb trong URL; tạo theo ngữ cảnh với loại cố định; gắn hồ sơ có sẵn; projection tối đa hai quan hệ với nhãn **Qua …**; không mở rộng qua chủ thể khác; hồ sơ trung gian riêng tư/lưu trữ; tài liệu nhóm theo hồ sơ và giữ phiên bản ghim; quyền đọc/ghi và rollback đồng thời hồ sơ/liên kết. Bộ SQL hoàn tất 237 kiểm tra thành công: 110 kiểm tra nghiệp vụ trước đó, 40 kiểm tra hồ sơ chủ thể và 87 thao tác tạo theo cấu hình tab thực tế.

Runner SQL cần Node.js 22 trở lên và các công cụ PostgreSQL trên PATH. Nó đọc cấu hình thật từ `src/lib/dossier.ts` để thực thi các thao tác theo tab trên cluster biệt lập; không ghi fixture vào Supabase thật. Typecheck, ESLint và production build đã thành công. Toàn bộ 55 kiểm tra Playwright thành công: 42 validation, 5 API và 8 giao diện desktop/mobile. Bản production đã khởi động lại tại cổng 3100.

Đã kiểm tra giao diện bằng phiên được cấp quyền trên hồ sơ đơn vị BSR: 3 đầu mối, 5 nhu cầu/bài toán, 3 hồ sơ hợp tác/đối tác, 1 hồ sơ dữ liệu và 2 tài liệu. Biểu mẫu tạo đầu mối cố định đúng loại, hiển thị đơn vị sẽ được gắn; hủy biểu mẫu trở về tab đầu mối. Mở đầu mối, tải lại trang rồi quay lại vẫn giữ đúng tab Đầu mối của đơn vị. Đã mở đối tác Noventiq và bài toán chuẩn từ hồ sơ BSR, kiểm tra các phần tương ứng và nhãn liên kết qua hồ sơ trung gian. Chưa tạo hoặc chỉnh sửa bản ghi thử nghiệm qua giao diện trên database thật; các thao tác ghi được kiểm tra trong bộ SQL biệt lập nêu trên.

## Chi tiết hồ sơ và tra cứu phiếu khảo sát

Đã áp dụng migration `202610080003_unit_survey_lookup.sql` ngày 08/10/2026; hiện có 18 gateway. Tra cứu theo ánh xạ rõ ràng tìm được bản phiếu cho cả 28 hồ sơ đơn vị: 27 bản đã gửi dùng schema 16; Rusvietpetro dùng schema 7, chưa bắt đầu và câu trả lời rỗng. Sau áp dụng, 450 hồ sơ và 286 bản nguồn giữ nguyên; không nhập thêm dữ liệu.

Đã kiểm tra 14 tình huống formatter: nhãn ma trận/rating, bài toán lồng nhau, bảng dữ liệu/đối tác, trường ngoài schema, câu trả lời rỗng hoặc xác nhận không có dữ liệu, số 0/boolean, mục khác, thứ tự xếp hạng, tên tệp không lộ locator và fallback phiên bản cũ. Bộ SQL hoàn tất 257 kiểm tra: 110 nghiệp vụ nền, 40 hồ sơ chủ thể, 85 thao tác tạo theo tab hiện hành và 22 kiểm tra tra cứu nguồn. Typecheck, ESLint và production build cuối cùng đã thành công; bản production đã khởi động lại tại cổng 3100. Toàn bộ 76 kiểm tra Playwright đạt: 63 validation (gồm 14 formatter khảo sát), 5 API và 8 giao diện desktop/mobile.

Đã kiểm tra đọc trên trình duyệt bằng phiên thật: hồ sơ triển khai PVOIL hiển thị nội dung theo nhãn, không còn nhãn xác minh hoặc các tab bị bỏ; phiếu PVOIL có đúng 37 câu hỏi trong 10 mục. Bộ lọc C5 hiển thị nhãn dòng/cột đầy đủ; tìm không dấu “ngan sach” trả 3 câu hỏi phù hợp. Nhãn câu hỏi xuống dòng đúng và không tràn ngang trang; bảng rộng cuộn trong khung riêng. Không tạo hoặc sửa dữ liệu thật để kiểm thử đợt này.

Tab phiếu chỉ hiện cho admin ở hồ sơ đơn vị; endpoint và SQL cũng kiểm tra admin. Các tab quản lý liên kết/lịch sử/cơ cấu đơn vị bị bỏ khỏi giao diện nhưng dữ liệu cũ được giữ; URL tab cũ về Thông tin chung. Trạng thái xác minh không còn là nội dung hiển thị hoặc lựa chọn, trong khi tình trạng hoạt động và giá trị lưu trữ vẫn tương thích.

## Kiểm thử nền ứng dụng và SQL

- 85 kiểm tra SQL thành công trên PostgreSQL biệt lập: 15 module, ràng buộc kiểu/ngày/số/URL, vai trò, riêng tư, xung đột phiên bản, lưu trữ, cây quan hệ, tài liệu bất biến, ghim/tái sử dụng, orphan cleanup, bucket cũ, nguồn bất biến và ánh xạ nhiều–nhiều.
- 41 kiểm tra Playwright thành công: validation/extraction, API chưa đăng nhập, same-origin, giới hạn JSON kể cả stream không có Content-Length, giao diện Chrome desktop và mobile 375px.
- Typecheck, ESLint và production build thành công. Giao diện login desktop/mobile đã được kiểm tra thực tế.
- Đã review độc lập quyền truy cập, gateway, Storage, các luồng giao diện. Đã sửa multipart buffering không giới hạn, preflight tài liệu bị giới hạn 200 kết quả, xóa quan hệ từ hồ sơ lưu trữ, URL scheme chữ hoa và không thống nhất định dạng chuỗi số.

Các bộ kiểm tra không tạo dữ liệu thử trên Supabase thật. Đã kiểm tra đọc tổng quan/thư viện bằng phiên quản trị thật, sao chép tài liệu qua Storage HTTP và khởi phát download từ giao diện. Chưa kiểm tra toàn bộ luồng chỉnh sửa tương tác bằng từng vai trò. SQL đã kiểm tra các nghiệp vụ này trong môi trường biệt lập nhưng không thay thế kiểm thử HTTP thật.

## Giao diện nhận diện Petrovietnam

Ngày 08/10/2026 đã áp dụng logo đầy đủ, sidebar xanh đậm, nút chính xanh lá, góc bo 4px và bố cục hồ sơ/bảng khảo sát thống nhất. Logo và Lexend tiếng Việt được phục vụ nội bộ; xem [quy ước thiết kế](design-guidelines.md). Không thay database, API hoặc quyền truy cập.

Production build, lint, typecheck và toàn bộ 76 kiểm tra Playwright đạt. Đã xem ảnh login desktop 1440px/mobile 375px; kiểm tra bằng phiên thật danh sách đơn vị, hồ sơ PVOIL và bảng khảo sát trên desktop 1280px và mobile 375px. Không tràn ngang trang; bảng rộng cuộn riêng, ô nhập 16px, menu đóng bằng Escape và trả focus đúng. Bộ lọc C5 vẫn hoạt động. Server đã chạy lại tại cổng 3100; tab bản mới đã mở ở danh mục đơn vị.

## Đối tác, chuyên gia và workbook

Ngày 08/10/2026 đã áp dụng `202610080004_partner_expert_dossiers.sql` qua Supabase MCP với tên `partner_expert_dossiers`. Registry có 19 loại hồ sơ, tổng gateway vẫn là 18. Đối chiếu hash xác nhận danh sách trạng thái của cả 15 loại cũ giữ nguyên. Lần duyệt tự động đầu từ chối các phép gán lại trạng thái cũ dư thừa; đã bỏ bốn phép gán, chạy lại 431 kiểm tra SQL thành công và lần duyệt lại được chấp thuận trước khi áp dụng.

Kết quả kiểm thử cuối cùng:

- **431 kiểm tra SQL đạt**, gồm 129 thao tác tạo theo cấu hình tab thực tế và 16 kiểm tra mẫu SQL nhập workbook: quyền, chủ thể duy nhất của năng lực/quan hệ tổ chức, phạm vi projection, bảo toàn dữ liệu, chạy lại không trùng và rollback.
- **92 kiểm tra Playwright đạt**: 79 validation và 13 API/giao diện. Lượt đầu của 13 kiểm tra API/giao diện bị môi trường sandbox chặn tiến trình/kết nối (`EPERM`); chạy lại cùng 13 kiểm tra ngoài sandbox đạt. Không tính lượt bị chặn là thành công.
- Typecheck, ESLint và production build đạt. Bản production đã chạy lại ở cổng 3100.

Đã hoàn tất tám lô: 132 bản nguồn ánh xạ tới 131 hồ sơ khác nhau, gồm 80 mới và 51 đã có; hồ sơ tăng 450 → 530, quan hệ tăng 528 → 620. Không ghi đè trường chung hoặc chi tiết đã có nội dung. Bốn hồ sơ tham khảo mới gồm ba URL công khai và một metadata chưa có tệp; 31 tệp Storage không đổi và không tải nguồn bên ngoài. Danh mục đào tạo/POC vẫn có 0 hồ sơ. Dữ liệu giữ lại và cách đối soát tiếp được ghi tại partner-workbook-import.md.

Đã kiểm tra đọc bằng trình duyệt có phiên được cấp quyền: chuyên gia có chín năng lực, năm quan hệ tổ chức, một đợt làm việc, bốn tham khảo và liên hệ tới PVN qua đợt làm việc. Thông tin chung chia nhóm, không hiện nhãn xác minh hoặc đường dẫn tệp cục bộ. Ở viewport 375px, chiều rộng trang ghi nhận 360px, không tràn ngang; đã trả lại kích thước cửa sổ sau kiểm tra. Không tạo bản ghi thử qua giao diện trên database thật; CRUD và các quyền ghi được kiểm tra trong SQL biệt lập, chưa xác minh mọi luồng ghi tương tác trên hệ thống thật.

## Hồ sơ kiểu CV và thao tác đính kèm

Ngày 08/10/2026 đã thay trang mở mặc định bằng hồ sơ tổng hợp: nhận diện, thông tin chính, xem trước các vùng nghiệp vụ và tệp đính kèm. Mỗi vùng có nút xem đầy đủ; trang sâu dùng bộ chọn mục và nút trở lại hồ sơ tổng hợp. URL section cũ và breadcrumb vẫn giữ ngữ cảnh. Không có migration, thay đổi quyền hay dữ liệu thật trong đợt này.

- **111 kiểm tra Playwright đạt**: 98 validation và 13 API/giao diện desktop–mobile. Các kiểm tra mới bao gồm đếm/dedup hồ sơ, giữ phiên bản tài liệu theo chủ thể, reference khác tệp thực tế, đường dẫn cũ, giới hạn tệp 20 MiB, tệp rỗng và định dạng không hỗ trợ. API/UI chạy ngoài sandbox để sử dụng Chrome và server local.
- ESLint, typecheck và production build đạt; bản production đã chạy lại ở cổng 3100.
- Đã kiểm tra bằng phiên thật: CV đối tác FPT Digital, đơn vị PTSC và chuyên gia Mehdi Hatamian; mở reference và biểu mẫu đính kèm đúng hồ sơ, rồi quay lại phần tham khảo của đối tác. Mục lục focus `cv-references` mà hash vẫn là tuyến hồ sơ tổng hợp. Đã kiểm tra liên kết sang đơn vị, lối vào phiếu khảo sát và nội dung tệp có sẵn. Ở viewport 375px, trang đối tác và đơn vị ghi nhận clientWidth/scrollWidth cùng 360px, không tràn ngang; đã trả lại kích thước mặc định.
- Nút đính kèm được đưa ra CV và đầu hồ sơ reference. Biểu mẫu hiển thị tên/dung lượng tệp chọn và thao tác lưu rõ ràng. Trạng thái reference được suy từ tài liệu đọc được, không dùng nhãn metadata cũ để khẳng định tệp đã lưu.

Về phản ánh chưa lưu được tệp: xác định mục tham khảo cũ chỉ nhập metadata/URL, còn tải tệp nằm ở phần riêng. Kiểm tra chỉ đọc trên database với tài khoản quản trị hiện hữu xác nhận quyền ghi hồ sơ reference, helper Storage và điều kiện policy upload đều cho phép; bucket vẫn riêng tư. Connector log không có scope đọc log Storage. Chưa tái hiện lỗi upload HTTP hoặc gửi tệp mới trên hệ thống thật ở đợt này, nên không kết luận đã sửa một lỗi từ chối quyền cụ thể. Không mở rộng quyền để xử lý vấn đề giao diện.

## Hợp nhất file/thư mục và bỏ tầng hồ sơ lặp

Ngày 08/10/2026 đã thay cách trình bày theo yêu cầu tiếp theo: chỉ đơn vị, đối tác, chuyên gia và bài toán chuẩn giữ CV; hồ sơ phụ mở thẳng nội dung. Nhóm liên quan chỉ có một loại không lặp tiêu đề cùng loại. Mỗi hồ sơ có một vùng **File & tài liệu**, không còn vùng tham khảo riêng hoặc nút tải file lặp ở đầu hồ sơ.

Thư mục dùng bản ghi/quan hệ hiện hữu, tạo cùng phạm vi chia sẻ với hồ sơ cha; có mở tại chỗ, tải file, dùng file có sẵn và đổi tên. Bản ghi/URL/metadata cũ được giữ; URL `references` mở vùng tài liệu thống nhất. Không áp dụng migration hoặc ghi dữ liệu thử lên Supabase thật.

- **118 kiểm tra Playwright đạt**: 105 validation và 13 API/giao diện desktop–mobile. **448 kiểm tra SQL biệt lập đạt**, trong đó 17 kiểm tra mới về thư mục, quyền, đổi tên có phiên bản, bảo toàn metadata và phiên bản file theo từng liên kết.
- Lint, typecheck và production build cuối cùng đạt; bản cuối đã chạy lại ở cổng 3100.
- Đã kiểm tra trên phiên thật: trang Digital Worker không còn CV con, chỉ có file và thông tin có thể mở rộng; FPT Digital chỉ có một vùng file, thư mục mở ngay trong hồ sơ, giữ file PDF người dùng đã tải. Tên file, phiên bản và đường tải về vẫn hiện. Đã mở/hủy biểu mẫu tạo thư mục và đổi tên mà không gửi thay đổi. Đầu mối chỉ có một tiêu đề nhóm và mở thẳng thông tin liên hệ; breadcrumb vẫn giữ phần Đầu mối của FPT Digital.
- CV FPT Digital ở viewport 375px có đúng một `.record-files`, không còn nhóm tham khảo; chiều rộng client/scroll đều 360px, cả khi mở thư mục có tên file dài. Đã trả lại kích thước cửa sổ. Hồ sơ đơn vị PVPOWER vẫn có file trực tiếp ở gốc và mục khảo sát.
- Review phát hiện trường hợp tải nhiều file thành công một phần rồi hủy không đánh dấu cần cập nhật danh sách. Đã bổ sung callback sau mỗi file lưu thành công: đóng biểu mẫu cập nhật thư mục, quay lại cập nhật hồ sơ cha; việc chỉ đọc thư mục không tải lại toàn trang. Review lại, focused lint và typecheck đạt. Không chủ động gây upload HTTP lỗi trên dữ liệu thật; nhánh này được kiểm tra bằng đọc mã, các quyền và lưu tài liệu được kiểm chứng bằng SQL biệt lập.

Giới hạn có chủ đích: một cấp thư mục; chưa có di chuyển/xóa file hoặc tải lên nguyên cây thư mục. Việc thư mục có thể dùng chung được nêu rõ trước đổi tên. Không sửa quyền Storage, quyền khảo sát hoặc dữ liệu nguồn.

## Xóa hồ sơ, Thùng rác và khôi phục

Ngày 09/10/2026 đã áp dụng migration `202610080005_record_restore.sql` qua Supabase MCP (`record_restore`), bổ sung gateway khôi phục; tổng số gateway là 19. Đối chiếu trước/sau giữ nguyên 532 hồ sơ, 0 hồ sơ đã xóa và 35 tài liệu. Hash các gateway cũ, policy public/Storage và cấu trúc cột khảo sát đều không đổi. Quyền execute gateway mới chỉ cấp authenticated, không cấp anon; hàm vẫn kiểm tra membership, quyền đọc/ghi và phiên bản.

- **495 kiểm tra SQL biệt lập đạt**, gồm 47 kiểm tra mới về khôi phục cả 19 loại hồ sơ, vai trò, hồ sơ riêng tư, phiên bản xung đột, trạng thái không hợp lệ, audit và bảo toàn quan hệ, nguồn, file cùng phiên bản ghim.
- **119 kiểm tra Playwright đạt**: 105 validation, 6 API và 8 giao diện desktop/mobile. API/giao diện chạy ngoài sandbox để sử dụng Chrome và server local. Lint, typecheck và production build đạt; bản cuối chạy tại cổng 3100.
- Đã kiểm tra bằng phiên thật: nút Xóa hồ sơ cạnh Chỉnh sửa; xác nhận ghi đúng tên hồ sơ và giải thích việc giữ dữ liệu liên quan. Hủy và Escape đóng xác nhận, trả focus về nút Xóa hồ sơ. Ở viewport 375px, chiều rộng client/scroll đều 360px; đã trả lại kích thước mặc định. Thùng rác tải thành công, có bộ lọc và trạng thái rỗng đúng với database.
- Không thực hiện xóa/khôi phục hồ sơ thật để kiểm thử. Các thao tác ghi, quyền và bảo toàn dữ liệu được kiểm chứng trong SQL biệt lập; chưa kiểm tra tương tác xóa/khôi phục thực tế bằng từng vai trò trên database thật.

Xóa sử dụng `archived_at` hiện hữu; không xóa vĩnh viễn hồ sơ, file, hồ sơ liên quan hoặc nguồn khảo sát. Hồ sơ đã xóa có thể mở từ Thùng rác để khôi phục nếu có quyền. API DELETE và bộ lọc `archived=true` giữ tương thích; bổ sung `POST /api/records/:id/restore` nhận phiên bản hiện tại.

## Liên danh và chỉnh sửa theo cấu phần

Ngày 13/10/2026 đã hoàn thiện trang hồ sơ để luôn hiện đủ cấu phần theo thứ tự cấu hình, kể cả cấu phần chưa có dữ liệu; không còn nhóm “Các mục khác”. Thông tin chính và các nhóm đơn giản chỉnh sửa ngay trong trang; hợp tác và mốc làm việc dùng dialog riêng có Escape, khóa focus và trả focus. Kiểm tra trực tiếp bằng phiên thật trên hồ sơ CodeValue xác nhận đủ bốn vùng đối tác, nút chỉnh sửa riêng, bộ chọn liên danh chỉ tải danh mục đối tác, checkbox đầu mối và dialog hợp tác. Không gửi biểu mẫu hoặc ghi dữ liệu thử; console không có lỗi.

Liên danh tiếp tục dùng hồ sơ `partner`. Tạo mới mở form hồ sơ đối tác; chọn có sẵn dùng danh mục đối tác; vai trò được lưu bằng `consortium_role`. Migration `202610130001_contextual_related_creation.sql` bảo đảm trong một transaction chỉ còn một đầu mối sau khi chọn đầu mối mới. Bộ SQL biệt lập đạt toàn bộ kiểm tra hiện hành và sáu kiểm tra liên danh mới: một đầu mối, hạ đầu mối cũ, tạo hồ sơ đầy đủ, gắn đầu mối khi tạo và từ chối vai trò sai. Migration đã áp dụng qua Supabase MCP ngày 13/10/2026 sau khi khôi phục OAuth; API hiện dùng các RPC nguyên tử. Đường tương thích được giữ cho database chưa có migration.

- 32 kiểm tra tập trung về trình bày/projection hồ sơ đạt; toàn bộ 134 kiểm tra đạt sau khi 14 kiểm tra cần Chrome được chạy ngoài sandbox; lint, typecheck và production build đạt.
- Bộ PostgreSQL biệt lập đạt, gồm toàn bộ kiểm tra cũ và sáu kiểm tra liên danh mới.
- Đã kiểm tra giao diện có phiên đăng nhập mà không ghi dữ liệu: cấu phần trống, editor tại chỗ, danh mục đối tác và dialog hợp tác.

## Nội dung hợp tác một cấp và dữ liệu đối tác

Ngày 13/10/2026 đã triển khai giao diện và hợp đồng dữ liệu cho **Nội dung hợp tác** một cấp theo từng đối tác. Một nội dung nhận nhiều chủ thể PVN và một chủ thể đầu mối tùy chọn, không quá một use case chuẩn, loại hợp tác quản trị và trạng thái dạng tag. Mốc làm việc gắn được nhiều nội dung, tạo nhanh nội dung mới và đính kèm file; file giữ nguyên chủ thể lưu, còn hồ sơ đối tác tổng hợp theo thư mục logic của nội dung. Trang use case có chiều tra cứu ngược tới các nội dung riêng của từng đối tác. Đầu mối hiển thị dạng bảng; hồ sơ đối tác hiện đủ các vùng trên một trang và không dùng “Xem đầy đủ”.

Loại tầng cũ `collaboration_item` đã bị ẩn khỏi toàn bộ lựa chọn tạo/liên kết và bị chặn ở hai API tạo hồ sơ. Bộ chuẩn hóa khảo sát đã được kiểm thử để chỉ tạo `collaboration` kèm phân loại `Khác`, phạm vi và tình trạng theo nguồn. Migration cũng đã kiểm thử việc từ chối đối tác thứ hai, use case thứ hai và chủ thể PVN đầu mối thứ hai trên cùng nội dung hợp tác. Định nghĩa cũ chỉ còn để đọc/chuyển đổi dữ liệu cho tới khi migration trên Supabase hoàn tất.

Lượt rà soát cuối chỉ cho phép tạo mới `collaboration` từ chính hồ sơ đối tác; các trang đơn vị, use case, mốc và tài liệu chỉ tra cứu quan hệ đã có. Việc đặt lại chủ thể PVN đầu mối dùng gateway nguyên tử `ai_catalog_collaboration_unit_link()` thay cho chuỗi xóa–tạo liên kết. Vùng file không còn liệt kê trùng một nội dung hợp tác vừa là thư mục logic vừa là chủ thể file liên quan. Thanh phân trang dùng nền trong suốt, không viền và không còn tạo một khối trắng tách rời ở danh sách chính hoặc hộp chọn hồ sơ. Kiểm tra trực tiếp trang Đối tác xác nhận nền `transparent`, không viền và điều khiển nằm liền mạch trên nền trang.

Migration `202610130002_flatten_partner_cooperation.sql` đã được kiểm tra trong PostgreSQL biệt lập cùng toàn bộ migration và bộ kiểm tra database. Dữ liệu mẫu tầng cũ chuyển thành `collaboration`, giữ ID/tài liệu/nguồn/quan hệ, kế thừa đối tác/chủ thể PVN, bỏ cạnh lồng và có audit. Báo cáo đối soát admin và endpoint `/api/partner-review` đã được bổ sung. Ngày 13/10/2026 đã khôi phục đăng nhập OAuth và triển khai bằng client MCP chính thức của Codex. Lịch sử Supabase xác nhận `contextual_related_creation` (`20261013085159`) và `flatten_partner_cooperation` (`20261013085220`). 53 hồ sơ tầng cũ chuyển thành nội dung hợp tác, giữ nguyên ID và dữ liệu liên quan; hiện có 75 đối tác, 160 nội dung hợp tác và 0 hạng mục tầng cũ. Migration `reconcile_cooperation_consortium` (`20261013090229`) chỉ bỏ 4 cạnh thành viên bị nối trùng trong hai nội dung của ADT/AIQ và VNPT–Qualcomm khi quan hệ thành viên đã có đủ trong hồ sơ liên danh, đồng thời lưu audit.

Đối chiếu trước/sau giữ tổng 534 hồ sơ, 42 tài liệu/42 phiên bản/42 liên kết file và 418 bản nguồn. Hash dữ liệu ba bảng khảo sát `profiles`, `responses`, `units`, hash cột public, policy public/Storage và định nghĩa 19 gateway cũ không đổi. Bốn gateway mới không cấp execute cho `anon`; các helper vẫn kiểm tra membership, quyền và trạng thái hồ sơ. Báo cáo cuối không có nhóm trùng tên, nội dung thiếu/thừa đối tác, nhiều use case/đầu mối PVN hoặc mốc hợp tác thiếu đối tác. Các mục thiếu thông tin cơ bản chỉ là dữ liệu chưa có trong nguồn: 73 tên pháp nhân, 7 loại đối tác và 42 quốc gia; không tự suy đoán.

Supabase Advisor ghi nhận cảnh báo chung về các gateway `SECURITY DEFINER` có quyền execute cho signed-in users. Đây là cơ chế RPC chủ đích của app; SQL biệt lập và kiểm tra grant trên project thật xác nhận có kiểm tra membership/quyền, không cấp `anon`. Không thay kiến trúc gateway chỉ để loại cảnh báo này; tham chiếu [database linter](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

Kết quả kiểm tra cuối:

- ESLint, typecheck và production build đạt.
- 135 kiểm tra Playwright đạt. Lượt đầu trong sandbox bị chặn tiến trình Chrome; lượt chạy ngoài sandbox đạt. Hai ca mobile sau đó bị gián đoạn do hết chỗ khi tạo trace, đã chạy lại đúng hai ca với một worker và tắt trace, đều đạt.
- Bộ PostgreSQL biệt lập chạy qua toàn bộ migration và tất cả kiểm tra hiện hành, gồm chuyển đổi nội dung hợp tác, audit, constraint phân loại, quyền, projection, file, khôi phục và liên danh.
- Kiểm tra trực tiếp bằng phiên quản trị trên hồ sơ CodeValue xác nhận một trang có đủ sáu vùng, biểu mẫu nội dung hợp tác có đúng nhóm trạng thái/phân loại mới, không ghi dữ liệu thử và console không có lỗi.
- 72 kiểm tra tập trung về registry, cấu trúc hồ sơ, projection và file đạt sau lượt rà soát cuối; bộ PostgreSQL biệt lập xác nhận đổi đầu mối nguyên tử và từ chối tạo nội dung hợp tác ngoài ngữ cảnh đối tác.

## Đối soát dữ liệu đối tác và hợp tác ngày 13/10/2026

Đối chiếu trực tiếp 75 hồ sơ đối tác với workbook v6 và Supabase xác nhận hồ sơ `ADT` là nhóm ADT–AIQ theo `06_dim_lien_danh:LD002`, có ADT Global / ADT Hi-tech là thành viên đầu mối và AIQ là thành viên còn lại. Đã đổi tên hiển thị thành **Nhóm ADT–AIQ**, giữ nguyên hai hồ sơ thành viên và các quan hệ. Không ghép nhóm vào ADT Global.

Trước migration 006 có 160 nội dung hợp tác hoạt động và 53 cặp gốc/item cùng nguồn khảo sát. Mỗi cặp có cùng đối tác, chủ thể PVN, phạm vi, kết quả và ngữ cảnh quan hệ; bản item không có file, quan hệ riêng hoặc chỉnh sửa sau chuyển đổi. Bộ PostgreSQL biệt lập đạt với kiểm tra lưu trữ có thể khôi phục, giữ ánh xạ nguồn/quan hệ/audit và chỉ hiển thị một nội dung trong dossier. Truy vấn tiền triển khai trên Supabase trả 53/53 cặp an toàn và một nhóm ADT hợp lệ. Migration `deduplicate_partner_cooperation_20261013` áp dụng thành công qua MCP. Sau triển khai có 107 nội dung hợp tác hoạt động, 53 bản item trong Thùng rác, 53 audit hợp nhất và 0 cặp cùng mã nguồn còn hoạt động; vẫn có 75 đối tác, 418 bản nguồn, 42 tài liệu/42 liên kết file. Cả 107 nội dung hoạt động có đúng một đối tác và nhóm ADT vẫn có hai thành viên.

Lượt rà soát sau triển khai kiểm tra thêm các trường cấp record của cả 53 cặp: ngày ghi nhận, ghi chú nguồn và phạm vi quyền đều giống nhau; 53 tóm tắt khác nhau đều là cùng một câu mẫu “Giữ nguyên phạm vi đã khai báo; chưa tự tách các hạng mục chưa rõ ranh giới.”, không phải nội dung riêng. Không phát hiện dữ liệu nghiệp vụ riêng bị khuất. Hồ sơ nhóm ADT thực tế có đúng hai cạnh thành viên tới ADT Global và AIQ theo nguồn workbook.

Rà phạm vi giống hệt trong 107 nội dung còn lại chỉ thấy một cặp AWS cùng chủ đề nhưng có hai nguồn khảo sát và hai chủ thể PVN khác nhau (PVPGB và PVPOWER); chưa đủ căn cứ coi là một hợp tác. Một nội dung hợp tác vẫn có thể có nhiều chủ thể PVN theo hợp đồng dữ liệu. Các cặp hồ sơ đối tác có tên gần nhau như AWS/Amazon Web Services, GE/GE Vernova, các công ty con FPT/Viettel/VNPT và tên ghép Microsoft–Google, VNPT AI–CMC OpenAI chưa bị tự ghép pháp nhân; cần xác minh ý nghĩa nguồn trước khi đổi quan hệ.

## Đối soát danh tính đối tác theo xác nhận mới

Ngày 13/10/2026, người dùng xác nhận gộp AWS vào Amazon Web Services và xác nhận hai nhãn `Microsoft, Google`, `VNPT AI, CMC OpenAI` là lỗi chuẩn hóa nhiều thành viên. Migration `reconcile_partner_identities_20261013` (`20261013113834`) đã áp dụng qua Supabase MCP; bản nguồn khảo sát không bị sửa. Ba hồ sơ đối tác lỗi được lưu trữ, hai nội dung hợp tác tên ghép được tách thành bốn nội dung riêng theo Microsoft, Google Cloud, VNPT AI và CMC OpenAI; nguồn, bài toán và chủ thể PVN vẫn truy vết được. Hồ sơ Amazon Web Services nhận nguồn và cả hai quan hệ hợp tác của AWS cũ. `Google` được nối vào hồ sơ Google Cloud sẵn có; đây là ánh xạ quản trị của nguồn khảo sát, không khẳng định tên pháp nhân.

Kiểm tra SQL hậu triển khai: 71 đối tác và 110 nội dung hợp tác đang hoạt động, 3 hồ sơ danh tính lỗi trong Thùng rác, 4 nội dung tách riêng, 0 quan hệ còn trỏ về hồ sơ lỗi, 0 nội dung hợp tác hoạt động thiếu/thừa đối tác. Có 418 nguồn, 652 ánh xạ nguồn, 42 tài liệu và 42 liên kết file. Truy vấn cùng đối tác/chủ thể PVN/phạm vi trả 0 cặp hợp tác trùng. Bộ PostgreSQL biệt lập đạt 538 kiểm tra, 128 kiểm tra validation Playwright đạt; ESLint, typecheck và production build đạt. Bộ quy tắc nhập lại đã được sửa để không tái tạo hai hồ sơ tên ghép hoặc AWS dư; chữ “Google” đứng một mình vẫn được giữ nguyên, chỉ nhãn ghép đã đối soát nối vào Google Cloud.

## Vận hành và giới hạn hiện tại

- App chạy local tại `http://localhost:3100`; chưa công bố URL hosting từ xa.
- Mốc sau nhập ngày 08/10/2026 có 530 hồ sơ và 31 tệp tài liệu; người dùng có thể tiếp tục bổ sung sau mốc này. Kết quả các đợt nhập khảo sát và workbook đối tác–chuyên gia. Bốn hồ sơ tham khảo mới không phải tệp tải lên. POC và đào tạo/hội thảo của đơn vị vẫn nằm ngoài phạm vi nhập.
- Cấp/thu hồi membership hiện do quản trị database thực hiện. Không có giao diện quản trị tài khoản trong bản này.
- Danh sách hồ sơ 30 dòng/trang; thư viện tài liệu tối đa 200 kết quả mỗi lần tìm; nguồn admin chưa phân trang; tìm kiếm hồ sơ chưa bỏ dấu tiếng Việt, tìm trong phiếu khảo sát có hỗ trợ không dấu.
- Lịch sử thao tác vẫn lưu trong database; tab lịch sử đã bỏ và chưa có màn hình so sánh từng trường giữa các phiên bản. Đã có khôi phục hồ sơ trong Thùng rác; chưa có xóa vĩnh viễn hồ sơ hoặc xóa vật lý object tệp đã đăng ký. Tệp có thể được gỡ liên kết hoặc ẩn khỏi ứng dụng.
- Đã cập nhật Next.js lên 16.4.0 sau audit. `npm audit` không còn cảnh báo dependency production; còn 5 mục high trong cây lint development do advisory của `braces` về mẫu glob lồng quá sâu. Không chạy lint với pattern do người dùng không tin cậy cung cấp; không hạ eslint-config-next trái phiên bản chỉ để làm audit sạch. Khóa phiên bản thực tế trong package-lock.json.
- Sao lưu database và Storage theo chính sách của Supabase/project trước vận hành chính thức. Không drop schema để rollback sau khi đã nhập dữ liệu thật; dùng migration sửa tiếp.

## Dashboard điều hành và hồ sơ đối tác tinh gọn

Ngày 09/10/2026 đã triển khai dashboard điều hành và cấu trúc đối tác mới mà không đổi schema, gateway, policy hoặc dữ liệu thật. Dashboard đọc 75 đối tác, 107 hồ sơ hợp tác, 1 chuyên gia, 69 bài toán chuẩn và 28 đơn vị theo phiên quản trị tại thời điểm kiểm tra; bốn khối mới nhất tải độc lập và mở đúng danh mục/hồ sơ.

Hồ sơ ADT/AIQ được kiểm tra trực tiếp: tiêu đề không còn ngày ghi nhận; form chính chỉ còn tên, giới thiệu, loại, quốc gia, website, năng lực và phạm vi chia sẻ; đầu mối dùng form gọn; hai hồ sơ hợp tác hiển thị hạng mục lồng; hai thành viên liên danh chỉ xuất hiện ở quan hệ trực tiếp. Không gửi biểu mẫu hoặc tạo dữ liệu thử. Lượt rà soát phát hiện bản xem nhanh timeline từng giới hạn trước khi sắp ngày; đã sửa để chọn trên toàn bộ nhóm đọc được rồi mới lấy ba mốc mới nhất, áp dụng cùng nguyên tắc cho đầu mối và liên danh.

- **127 kiểm tra Playwright đạt**: 113 validation trong sandbox và 14 API/giao diện desktop–mobile chạy lại ngoài sandbox do Chrome/kết nối localhost bị chặn `EPERM` trong sandbox.
- ESLint, typecheck và production build đạt. Bản production cuối đã khởi động lại tại `http://localhost:3100`.

Ngày 09/10/2026 tiếp tục rút gọn hồ sơ đối tác và bỏ toàn bộ bộ chọn/nhãn phạm vi chia sẻ khỏi giao diện hồ sơ, danh sách và file. Dữ liệu `visibility`, mặc định tạo mới, kiểm tra quyền và kế thừa khi tải file không đổi. Trang FPT Digital đã được kiểm tra trực tiếp: thông tin chính chỉ còn trường cơ bản; sơ đồ quan hệ giải thích trục đối tác–hợp tác–nội dung; thẻ hợp tác hiển thị số nội dung và mốc; biểu mẫu tải file chỉ còn file và tên tài liệu. Không gửi biểu mẫu hoặc ghi dữ liệu thật. **114 kiểm tra validation**, lint, typecheck và production build đạt; bản cuối chạy tại cổng 3100.

Ngày 09/10/2026 đã bỏ sơ đồ “Cấu trúc quản lý” và chuyển `collaboration` thành hồ sơ tổng hợp kiểu CV. Hồ sơ hợp tác chỉ còn ba vùng quan hệ rõ ràng: các bên tham gia; hạng mục/use case/POC gắn kèm; mốc hợp tác. File trực tiếp, thư mục và file của record liên quan dùng một vùng File & tài liệu. Mốc làm việc có thể gắn hồ sơ hợp tác từ chính trang mốc với cùng chiều quan hệ chuẩn, nên được tổng hợp lên hồ sơ hợp tác và nhật ký đối tác. Biểu mẫu hợp tác và mốc bỏ ngày/nguồn kỹ thuật, dữ liệu cũ vẫn được bảo toàn khi chỉnh sửa. **130 kiểm tra Playwright đạt** gồm 116 validation, 6 API và 8 giao diện desktop/mobile; ESLint, typecheck và production build đạt. Không đổi schema, policy hoặc dữ liệu thật. Đã kiểm tra trực tiếp hồ sơ FPT Digital · PTSC: trang tổng hợp hiển thị hai bên tham gia, một hạng mục, vùng mốc và một vùng file; các màn hình chi tiết có thao tác tạo mới hoặc gắn hồ sơ có sẵn đúng từng loại.

## Chỉnh sửa trực tiếp và thao tác file

Ngày 13/10/2026 đã bỏ lớp chỉnh sửa trung gian ở các hồ sơ CV; thông tin chính mở form ngay tại vùng, đầu mối sửa trực tiếp trong bảng, mốc sửa nhanh trên dòng và mở phần nội dung liên quan/file bằng một thao tác riêng. Form nội dung hợp tác mở thẳng để sửa; dialog đặt trong viewport, phần nút lưu luôn truy cập được. Trang file chỉ trình bày file hiện dùng, cho xem trước PDF/ảnh/TXT/CSV, gỡ liên kết theo hồ sơ, ẩn file khỏi kho chung và xóa thư mục có xác nhận phạm vi ảnh hưởng. Không có giao diện quản lý phiên bản; phiên bản nguồn vẫn giữ trong database.

Migration `document_actions` (`20261013095615`) và bản khóa thao tác trên hồ sơ trong Thùng rác `document_trash_guard` (`20261013100806`) đã áp dụng qua Supabase MCP. Xác minh sau migration đầu: 42 tài liệu, 42 phiên bản và 42 liên kết còn nguyên; không có tài liệu bị ẩn. Gateway mới chỉ cấp thực thi cho `authenticated`, không cấp `anon`. Đối chiếu sau migration thứ hai xác nhận hai chốt Thùng rác đang hoạt động và vẫn còn 42 tài liệu/42 liên kết, 0 tài liệu bị ẩn. Bộ PostgreSQL biệt lập đạt **510 kiểm tra PASS**, gồm quyền reader/editor, ảnh hưởng khi file có nhiều liên kết, chặn tải file ẩn và chặn gỡ file ở hồ sơ Thùng rác. Bộ Playwright đầy đủ đạt **140/140** kiểm tra sau sửa giao diện, cùng lint, typecheck và production build. Đã kiểm tra trên hồ sơ thật ở cổng 3100: bảng đầu mối, nút thêm nội dung/mốc, form mốc trong dialog và file dùng chung; không ghi dữ liệu thử.

## Lộ trình AI và danh mục bài toán chuẩn

Ngày 14/10/2026 đã áp dụng lên database thật: `ai_roadmap_model` qua Supabase MCP; `202610140002_standard_problem_catalog.sql` do người quản trị chạy trong SQL Editor (MCP không hiển thị được bước xác nhận lệnh có `delete`), nên migration thứ hai không nằm trong lịch sử migration của Supabase. Đối chiếu sau khi chạy:

- 61 bài toán chuẩn BTC-xx đang dùng, đủ 7 chương trình (13/12/15/4/5/10/2), 14 bài ưu tiên đều có đơn vị đầu mối; không còn bài toán chuẩn nào khác; 69 bài toán sinh từ khảo sát nằm trong Thùng rác.
- 0 nhu cầu đơn vị còn hoạt động; 70 bản ghi chuyển thành hồ sơ *Bài toán đơn vị*, cả 70 đã gắn bài toán chuẩn; 12 hồ sơ hợp tác một đối tác được gộp vào và chuyển Thùng rác; đã tạo POC Camera AI của PVCFC.
- 169 hồ sơ hoạt động: Đề xuất 60, Đang trao đổi 32, POC 37, Triển khai chính thức 25, Vận hành 13, Tạm dừng 1, Dừng 1; 94 hồ sơ gắn bài toán chuẩn, 169 có đơn vị đầu mối.
- 71 đối tác: Đang hợp tác 30, Tiềm năng 40, Tạm dừng 1. Không còn hồ sơ nơi công tác/chuyên môn riêng; nội dung đã gộp vào hồ sơ chuyên gia.
- `ai_catalog_overview()` chạy với quyền admin trả đủ 61 bài toán/169 hoạt động/71 đối tác/28 đơn vị. Security advisor chỉ còn các cảnh báo đã biết: gateway `SECURITY DEFINER` cho `authenticated` (theo thiết kế, tự kiểm tra thành viên) và chưa bật kiểm tra mật khẩu lộ.
- Khi gộp, trạng thái hồ sơ giữ theo khai báo của đơn vị. Có 6/12 trường hợp lệch với trạng thái hợp tác cũ của đối tác; trạng thái cũ vẫn còn trong hồ sơ đã chuyển Thùng rác và trong nhật ký, cần Ban KHCN rà lại.

Cũng ngày 14/10/2026, migration `split_unit_problems_by_partner` (`202610140003`) áp dụng qua Supabase MCP sau khi chạy thử có hoàn tác. 10 bài toán đơn vị đang làm với 2–3 đối tác (23 bản ghi khảo sát "Đối tác · Đơn vị · bài toán") được tách thành một hoạt động cho mỗi đối tác: mỗi hoạt động giữ trạng thái riêng của đối tác, nhận tên, phạm vi, nguồn khảo sát và bài toán chuẩn của bài toán đơn vị; bản ghi bài toán đơn vị không có đối tác được gỡ khỏi danh mục kèm nhật ký. Sau migration: 159 hoạt động (83 loại *Bài toán đơn vị*), cả 23 có đúng một đơn vị đầu mối và cùng bài toán chuẩn với bản gốc. 53 bản ghi hợp tác chung "Đối tác · Đơn vị" chờ Ban KHCN quyết định qua file `plans/261014-0912-catalog-domain-redesign/doi-soat-hop-tac-chung.xlsx` (tạo bằng `scripts/build-partner-unit-review-workbook.py`).

Migration `unit_as_activity_provider` (`202610140004`) áp dụng qua Supabase MCP ngày 14/10/2026 sau khi bộ PostgreSQL biệt lập đạt **570 PASS** (thêm kiểm tra: chỉ hoạt động mới nhận đơn vị làm bên thực hiện, vẫn một bên thực hiện, đơn vị không vào danh mục đối tác). Đối chiếu sau migration: hồ sơ đối tác "VPI" đã gộp vào đơn vị Viện Dầu khí Việt Nam và lưu trữ; 2 hoạt động "VPI · PQPOC" nhận Viện Dầu khí làm bên thực hiện; gateway liên kết và overview đã có quy tắc mới. Playwright 149/149, typecheck, lint, build đạt; trang hoạt động hiển thị "Bên thực hiện · Đơn vị PVN".

Ngày 14/10/2026 (chiều) áp dụng thêm qua Supabase MCP: `activity_lead_and_type_catalogs` (`202610140005`, gom nhãn loại hoạt động/loại đối tác, overview có `party_lead_id`), `partner_and_activity_type_lists` (`202610140006`, hai trường thành danh mục cố định), `consortium_as_light_group` (`202610140007`, chạy thử có hoàn tác trước; còn 4 liên danh: VNPT – Qualcomm, CMC OpenAI – CMC TS, ADT – AI Hay, ADT – AIQ) và `overview_consortium_lead` (`202610140008`). Sau đó: menu Đối tác còn 69 đối tác (không gồm liên danh), KPI liên danh = 4. Bộ PostgreSQL biệt lập 576 PASS; Playwright 151/151; typecheck, lint, build đạt.

## Dọn dữ liệu cũ và tối ưu code (14/10/2026)

Migration `202610140009_purge_legacy_and_archived_records.sql` xóa hẳn 217 hồ sơ (đếm trên database thật trước khi chạy): 153 hồ sơ đã gỡ (69 bài toán cũ, 78 hoạt động, 6 đối tác), 50 hồ sơ loại cũ còn dữ liệu (37 CSDL, 13 hiện trạng triển khai) và 14 hồ sơ chuyên gia cũ đã gỡ (5 quan hệ tổ chức, 9 năng lực). Kèm theo: 264 quan hệ, 225 ánh xạ nguồn; 121 bản nguồn chỉ bị xóa con trỏ `linked_record_id`. Mỗi hồ sơ có bản chụp audit `purge_record`; 1.051 dòng lịch sử cũ được giữ.

- Bộ PostgreSQL biệt lập: **489 PASS** (bỏ kiểm tra của công cụ nhập và API nguồn đã gỡ; thêm 15 kiểm tra dọn dữ liệu: bản chụp đủ trường/quan hệ/nguồn, lịch sử cũ còn, bản nguồn còn, hồ sơ giữ lại còn liên kết, bảng/registry/gateway cũ đã drop, overview chạy, không lưu được loại cũ). Playwright **105 passed**; `tsc`, `eslint`, `next build` sạch.
- Supabase MCP từ chối câu lệnh DELETE, kể cả khi chạy thử có hoàn tác; người quản trị đã chạy migration trong SQL Editor ngày 14/10/2026. Đối chiếu sau khi chạy: 391 hồ sơ, 0 hồ sơ đã gỡ, 9 loại trong registry, 217 bản chụp `purge_record`, 418 bản nguồn giữ nguyên.
- Code: gỡ 10 loại hồ sơ cũ khỏi `catalog.ts`/`dossier.ts`/component; gỡ công cụ nhập khảo sát và workbook đối tác (`survey-normalization.ts`, `partner-workbook.ts`, `source-extraction.ts`, 6 script, 3 bộ test), API `/api/sources` và `/api/partner-review`, `importClient` (app không còn dùng `SUPABASE_SERVICE_ROLE_KEY`), cờ `deprecated`/`contextOnly` và các hàm không còn được gọi. Bản sao code và tài liệu cũ trong `.private/code-backups/`.


## Áp dụng rà soát từ điển dữ liệu (15/10/2026)

Migration `202610140010_apply_data_dictionary_review.sql` do người quản trị chạy trong SQL Editor. Đối chiếu sau khi chạy: 391 hồ sơ, 42 tài liệu, 418 bản nguồn giữ nguyên; 391 bản chụp `drop_reviewed_fields`; 14 ghi chú giới thiệu chuyển vào `summary`; loại đối tác Công ty công nghệ 59 · Đơn vị đào tạo và NCKH 8 · Liên danh 4 · Tư vấn 1 · Truyền thông/sự kiện 1; đối tác Tiềm năng 42 (gồm 4 liên danh) · Đang hợp tác 29 · Tạm dừng 2; 28 đơn vị Đang hoạt động, 27 Đơn vị thành viên + 1 Ban/VP thuộc Tập đoàn (Cơ quan Tập đoàn); không còn cột đã bỏ; chỉ còn gateway `ai_catalog_delete`.

- Bộ PostgreSQL biệt lập **516 PASS** (thêm 27 kiểm tra: chuyển loại/trạng thái, chuyển ghi chú, bản chụp giá trị bị bỏ, kiểm tra danh mục phía database, đơn vị bắt buộc có phân loại, xóa hẳn kèm bản chụp, reader không xóa được, overview có trường mới). Playwright **105 passed**; `tsc`, `eslint`, `next build` sạch.
- Kiểm tra trên app thật (chỉ xem): trang đối tác ADT hiện giới thiệu đã chuyển từ ghi chú; trang Cơ quan Tập đoàn hiện phân loại mới và dòng "Cập nhật lần cuối"; form đối tác có danh mục Hợp tác chiến lược, Quốc gia và ô tag Năng lực và giải pháp.
