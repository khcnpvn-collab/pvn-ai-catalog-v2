# Danh mục AI — Petrovietnam

Ứng dụng quản trị và tra cứu hiện trạng, độc lập với app khảo sát. Sau đợt nhập ngày 08/10/2026 có 530 hồ sơ và 31 tệp tài liệu (số lượng tiếp tục thay đổi khi người dùng bổ sung): 450 hồ sơ từ đợt nhập khảo sát, bổ sung 80 hồ sơ từ workbook đối tác–chuyên gia. Bốn hồ sơ tham khảo mới là metadata/URL, không phải tệp đã tải lên. Dùng chung Supabase project hiện hữu nhưng lưu hồ sơ chuẩn trong schema `ai_management`, tài liệu trong bucket riêng tư `ai-catalog-documents`, và danh sách quyền riêng. Không có dữ liệu minh họa trong ứng dụng.

## Phạm vi hiện có

Từ 14/10/2026 ứng dụng được tổ chức theo lộ trình AI của Tập đoàn (người dùng chính: Ban KHCN):

- **Bài toán chuẩn** (61 bài, mã `BTC-xx`) thuộc 7 chương trình AI; mỗi bài có nhóm bài toán (tag nhập dần), mô tả, mức dẫn dắt, thuộc danh mục ưu tiên (14 bài), năm dự kiến, một đơn vị/Ban đầu mối ưu tiên và các đơn vị tiềm năng. Bài chuẩn tạo nhanh khi nhập hồ sơ mang trạng thái *Chờ rà soát*.
- **Triển khai & hợp tác** (mỗi mục là một *hoạt động*) dùng chung một mẫu cho bài toán đơn vị, POC, đề tài KHCN, hạ tầng, đào tạo, MOU…; loại hoạt động là tag. Vòng đời: Đề xuất → Đang trao đổi → POC → Triển khai chính thức → Pilot → Vận hành, cùng Tạm dừng và Dừng. Mỗi hồ sơ có một chủ thể PVN đầu mối (đơn vị hoặc Ban), nhiều đơn vị phối hợp, tối đa một bên thực hiện (đối tác đơn lẻ, liên danh, hoặc một đơn vị PVN làm cho đơn vị khác — đơn vị không xuất hiện trong menu Đối tác), tối đa một bài toán chuẩn, mốc làm việc và file.
- **Đối tác** có trạng thái hợp tác chung (Chiến lược / Đang hợp tác / Tiềm năng / Tạm dừng) và tag "bài toán chuẩn có thể đáp ứng" để xác định đối tác tiềm năng. Hồ sơ ký qua liên danh hiện ở trang của từng thành viên với nhãn *Qua liên danh*. Liên danh chỉ gồm thành viên, đầu mối và file; mốc ghi ở đối tác đầu mối.
- **Đơn vị** (gồm Cơ quan Tập đoàn và các Ban khi được bổ sung): hoạt động triển khai & hợp tác, bài toán chuẩn liên quan, đối tác, mốc/ghi chú, đầu mối, file và một khu *Kết quả khảo sát* chỉ đọc cho admin. Nội dung tự điền từ phiếu (hiện trạng, quản trị), danh mục CSDL và hiện trạng triển khai cũ được ẩn, dữ liệu vẫn giữ.
- **Chuyên gia**: hồ sơ cá nhân, nơi công tác, lĩnh vực/năng lực và quá trình công tác dạng văn bản.
- **Đào tạo & hội thảo**: một mẫu chung; loại hoạt động (đào tạo, hội thảo, khóa học…) là tag; có thời gian, đối tượng, file, đối tác/đơn vị tổ chức và chuyên gia.
- Tìm kiếm ở thanh trên cùng, chỉnh sửa có kiểm tra phiên bản và kho File & tài liệu giữ nguyên. Từ 14/10/2026 giao diện bỏ các mục Tất cả hồ sơ, Thùng rác và Nguồn & chuẩn hóa; dữ liệu và API phía sau không đổi.

Mỗi tab chính (Bài toán chuẩn, Triển khai & hợp tác, Đối tác, Đơn vị, Chuyên gia, Đào tạo & hội thảo) mở bằng thẻ số liệu, biểu đồ và bảng tóm tắt, sau đó là danh sách chi tiết có lọc; bấm thẻ hoặc cột biểu đồ để lọc danh sách. Trang chi tiết bài toán chuẩn, đối tác và đơn vị có dải số liệu nhanh ở đầu. Trang hồ sơ là một mặt trắng duy nhất, các mục ngăn bằng đường kẻ, nút **Thêm mới / Chọn có sẵn** nằm cùng dòng tiêu đề mục; trạng thái có màu riêng dùng chung cho nhãn và biểu đồ. Tên chương trình AI luôn hiển thị đầy đủ như danh mục gốc. Số liệu lấy từ gateway `ai_catalog_overview()` theo đúng quyền đọc của người dùng.

Chuyển đổi dữ liệu ngày 14/10/2026 (migration `202610140001`, `202610140002`, đã áp dụng lên database thật — số liệu đối chiếu tại [docs/verification.md](docs/verification.md)): 70 nhu cầu đơn vị trở thành hồ sơ hoạt động loại *Bài toán đơn vị* (giữ ID, tên, file, nguồn) và được gắn bài toán chuẩn theo bảng đối soát do Ban KHCN duyệt; hồ sơ hợp tác theo từng bài toán có đúng một đối tác được gộp vào bài toán đơn vị; bài toán làm với nhiều đối tác được tách thành một hoạt động cho mỗi đối tác (migration `202610140003`); 69 bài toán sinh từ khảo sát chuyển vào Thùng rác; nội dung hợp tác cũ chuyển sang vòng đời mới (trạng thái cũ ghi trong lịch sử). Quyết định đối soát tại [plans/261014-0912-catalog-domain-redesign](plans/261014-0912-catalog-domain-redesign/plan.md).

## Chạy ứng dụng

Giao diện dùng logo Petrovietnam đầy đủ, điều hướng xanh đậm, thao tác chính xanh lá và bảng dữ liệu trên nền sáng. Logo và font tiếng Việt được phục vụ nội bộ, không tải từ dịch vụ bên ngoài. Xem [quy ước thiết kế](docs/design-guidelines.md) khi bổ sung màn hình.

Yêu cầu Node.js 22 trở lên; đã kiểm tra bằng Node.js 24.

```sh
npm ci
cp .env.example .env.local
npm run dev
```

Điền cấu hình Supabase vào `.env.local` bằng kênh quản trị nội bộ; không đưa file này vào Git hoặc gửi qua chat. Cấu hình máy triển khai hiện đã được tạo từ app khảo sát. App dùng cổng **3100**: <http://localhost:3100>.

```sh
npm run build
npm start
```

Lệnh trên chạy bản production trên máy hiện tại. Để công bố qua HTTPS, triển khai thư mục này thành một ứng dụng riêng; đặt ba biến môi trường như `.env.example`. Không dùng chung dự án hosting hoặc tên cookie của app khảo sát. Endpoint tải tệp hỗ trợ 20 MiB; hạ tầng hosting cần cho phép request body ít nhất 21 MiB, hoặc cần đổi sang luồng upload trực tiếp có kiểm soát nếu nhà cung cấp giới hạn nhỏ hơn.

## Database và quyền

Các migration đến `202610130005_document_trash_guard.sql` đã áp dụng qua Supabase MCP lên project hiện hữu. Ba migration đầu ngày 13/10 bổ sung tạo hồ sơ/liên danh nguyên tử, chuyển 53 hạng mục cũ về nội dung hợp tác một cấp và đối soát liên kết thành viên liên danh nhập trùng. Hai migration tiếp theo cho phép gỡ file khỏi hồ sơ, ẩn file khỏi kho và chặn tác động vào hồ sơ trong Thùng rác; dữ liệu tệp vật lý và lịch sử vẫn được giữ. Sau triển khai có 75 đối tác và 160 nội dung hợp tác; không còn dữ liệu tầng cũ hoặc nội dung có sai số lượng đối tác/use case/chủ thể PVN đầu mối. Tổng 534 hồ sơ, 42 tài liệu và 418 bản nguồn được bảo toàn; hash dữ liệu khảo sát không đổi. Với database mới, chạy migration đúng thứ tự, mỗi migration một lần; không chạy fixture trong `scripts/tests/` lên database thật. Xem [trạng thái xác minh](docs/verification.md) và [thiết kế database](docs/database.md).

Đăng nhập bằng email/mật khẩu Supabase hiện có; tên ngắn được nối `@pvn.vn`. Không tự sao chép quyền quản trị từ app khảo sát. Quản trị viên database cấp `admin`, `editor` hoặc `reader` trong `ai_management.memberships` cho tài khoản được lựa chọn rõ ràng. Không cần tạo lại mật khẩu. Tài khoản chưa được cấp quyền sẽ thấy thông báo sau đăng nhập.

App không dùng `SUPABASE_SERVICE_ROLE_KEY`: mọi thao tác dùng phiên người đăng nhập và các gateway có kiểm tra quyền.

## Cách nhập hồ sơ

1. Mở bài toán chuẩn, hoạt động, đối tác, đơn vị hoặc chuyên gia; dùng nút **Chỉnh sửa** ngay tại vùng thông tin hoặc dòng cần sửa. Đầu mối sửa trực tiếp trong bảng; nội dung hợp tác và mốc làm việc mở biểu mẫu riêng. Dùng **Thêm mới** hoặc **Chọn có sẵn** tại từng vùng để bổ sung hồ sơ liên quan. Khi tạo mới, hồ sơ và liên kết cùng được lưu; nếu liên kết không hợp lệ, hồ sơ mới không được tạo rời.
2. Chọn một hồ sơ con để xem trực tiếp thông tin đầy đủ. Dùng đường dẫn hồ sơ phía trên hoặc **Quay lại** để trở về chủ thể và tab trước đó; tab và ngữ cảnh nằm trong URL. Nhãn **Qua …** chỉ rõ hồ sơ trung gian của quan hệ gián tiếp. Gắn thêm quan hệ tại từng tab nghiệp vụ. Các tab **Quản lý liên kết**, **Lịch sử** và **Cơ cấu đơn vị** đã được bỏ; URL cũ của các tab này mở nội dung mặc định của hồ sơ.
3. Tại **File & tài liệu**, chọn **Tải file lên** để gắn tệp trực tiếp vào hồ sơ, hoặc **Tạo thư mục** rồi mở thư mục ngay trong vùng này để tải tệp vào đó. Chọn **Dùng file có sẵn** để dùng lại tài liệu. Mỗi tệp tối đa 20 MiB. Tệp của các hồ sơ liên quan được nhóm theo nơi đính kèm. Với PDF, ảnh và tệp văn bản, chọn **Xem trước**; các loại khác dùng **Tải về**.

   Có thể **Đổi tên** hoặc **Xóa thư mục** khi mở thư mục và có quyền ghi; xóa thư mục gỡ thư mục khỏi mọi hồ sơ đang dùng chung, không xóa file khỏi kho. **Gỡ file** chỉ bỏ liên kết ở hồ sơ/thư mục đang xem; **Xóa file** tại kho chung ẩn file khỏi mọi nơi sau xác nhận. Hồ sơ tham khảo cũ, URL và metadata được giữ nguyên trong vùng này; URL `references` cũ chuyển đến **File & tài liệu**. Hiện hỗ trợ một cấp thư mục; chưa có thao tác di chuyển hoặc nhập file hàng loạt.

Mỗi **hoạt động** có thể tạo từ trang bài toán chuẩn, đơn vị, đối tác hoặc từ tab Triển khai & hợp tác. Tại trang hoạt động, chọn một chủ thể PVN đầu mối và các đơn vị phối hợp (nút **Đặt làm đầu mối**), một đối tác hoặc liên danh, và tối đa một bài toán chuẩn; nếu chưa có bài toán chuẩn phù hợp, **Thêm mới** tạo bài toán chuẩn ở trạng thái *Chờ rà soát*. Trên trang bài toán chuẩn, gắn đơn vị tiềm năng, đặt đơn vị đầu mối ưu tiên và gắn đối tác tiềm năng; trên trang đối tác, gắn các bài toán chuẩn đối tác có thể đáp ứng.

## Xóa hồ sơ

Người có quyền ghi chọn **Xóa hồ sơ** ở đầu hồ sơ. Vùng xác nhận tại chỗ nêu rõ tên hồ sơ; **Xác nhận xóa** gỡ hồ sơ khỏi danh mục rồi quay về tab của loại hồ sơ đó. Hồ sơ liên quan, quan hệ, file và bản nguồn được giữ; trong database hồ sơ chỉ được đánh dấu lưu trữ (`archived_at`) nên quản trị viên vẫn có thể khôi phục bằng SQL nếu cần. Giao diện không còn trang Thùng rác.

## Tra cứu chi tiết và phiếu khảo sát

Với bốn loại chủ thể chính và hồ sơ hợp tác, **Hồ sơ tổng hợp → Xem đầy đủ thông tin** mở các nhóm thông tin nhận diện và nội dung dài. Hồ sơ phụ hiển thị đầy đủ các nhóm này ngay khi mở; nguồn và thời điểm ghi nhận nằm trong phần có thể mở rộng. Hồ sơ tài liệu mở thẳng vùng file, kèm phần **Thông tin tài liệu** để xem metadata. Các nhãn xác minh được ẩn khỏi danh sách, bộ lọc, biểu mẫu và hồ sơ; tình trạng hoạt động vẫn hiển thị khi có. Giá trị cũ và lịch sử trong database được giữ nguyên.

Quản trị viên mở **Đơn vị → hồ sơ đơn vị → Kết quả khảo sát** để xem bản nguồn đã liên kết. Bảng giữ nguyên câu hỏi và câu trả lời, có tìm kiếm không dấu, lọc theo mục và chọn bản phiếu theo thời điểm cập nhật. Ngày cập nhật phiếu và ngày tiếp nhận bản nguồn được ghi riêng. Ma trận, bảng lặp và bài toán chi tiết hiện nhãn dòng/cột; tệp chỉ hiện tên, tải các tệp đã có trong kho tại **File & tài liệu**.

Phiếu là dữ liệu chỉ đọc. Nội dung đào tạo và POC được giữ để tra cứu, không thay đổi phạm vi nhập hồ sơ đã chọn. Quyền xem toàn bộ bản nguồn vẫn chỉ dành cho admin. Mẫu chưa xác định hoặc khác phiên bản nhãn hiện tại giữ chỉ mục gốc ở các bảng đánh giá để tránh gán nhầm nội dung.

## Kiểm thử

```sh
npm run typecheck
npm run lint
npm run build
# Chạy server ở terminal riêng trước bộ browser/API tests:
npm test
# Cần Node.js 22+ và PostgreSQL initdb, pg_ctl, psql trên PATH:
bash scripts/tests/run-database-tests.sh
```

Playwright dùng Chrome đã cài và kiểm tra API chưa đăng nhập, giao diện desktop/mobile và validation. Bộ SQL dựng cluster biệt lập, áp dụng các migration hiện hành, kiểm tra các module, phân quyền, liên kết, phiên bản, tài liệu, nguồn và hồ sơ chủ thể. Runner dùng Node.js để đọc cấu hình thao tác thực tế từ `src/lib/dossier.ts` và kiểm tra chúng trên SQL. Không dùng bản ghi thử nghiệm trên Supabase thật. Kiểm tra upload/download qua Supabase HTTP và thao tác trình duyệt đã đăng nhập cần tài khoản được cấp quyền.

Xem [kiến trúc](docs/system-architecture.md), [hợp đồng API](docs/api-contract.md) và [báo cáo xác minh](docs/verification.md) để biết trạng thái chạy thực tế và giới hạn.
