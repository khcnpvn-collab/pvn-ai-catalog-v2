# Nhận diện và giao diện Danh mục AI

Cập nhật: 13/10/2026 (bổ sung thang chữ, banner danh mục gộp và các quy ước trải nghiệm).

## Định hướng

Ứng dụng tra cứu và quản trị hiện trạng của Petrovietnam áp dụng thiết kế navy đã được duyệt trên Sites: điều hướng xanh đậm, thanh trên sáng, nền xám xanh và các khối nội dung trắng bo góc. Dashboard dùng lại ảnh năng lượng tạo bằng AI của mẫu đã duyệt; ảnh là minh họa ý tưởng, có nhãn nhận diện và không đại diện cho dữ liệu vận hành. Số liệu, tên, thời điểm, quan hệ và tài khoản luôn lấy từ ứng dụng thật; không đưa dữ liệu mẫu hoặc thao tác giả của prototype vào ứng dụng.

Logo đầy đủ lấy từ bộ tài nguyên Petrovietnam có sẵn trong app khảo sát, sao chép độc lập vào `public/brand`. Bản trắng đặt trên nền xanh đậm; bản màu dùng ở màn hình trạng thái nền sáng. Biểu tượng tab trình duyệt dùng ngọn lửa xanh đã có. Không bóp méo tỷ lệ logo hoặc dùng bộ màu đỏ thay cho bộ logo hiện hành.

## Quy ước dùng chung

- `src/app/globals.css` dùng đúng bộ màu navy đã duyệt: `--navy-deep: #081b36`, `--navy: #102d55`, `--accent` và `--blue: #17477c`. Thao tác chính và liên kết dùng xanh navy; nền `#f3f5f8`, khối nội dung trắng, viền `#dce3ed`. Đỏ dành cho lỗi hoặc thao tác cần chú ý; xanh lá còn phục vụ trạng thái phù hợp, không là màu thao tác chính.
- Font Be Vietnam Pro được phục vụ nội bộ từ `public/fonts`, gồm bốn trọng lượng 400, 500, 600, 700; giữ giấy phép SIL Open Font License 1.1 tại `public/fonts/be-vietnam-pro-license.txt`. Thang chữ: nội dung 14px (`--body`), nút/ô bảng/mô tả thẻ 13px (`--ui`), chú thích và nhãn phụ 12px (`--small`), nhãn in hoa giãn chữ 11px (`--micro`), ô nhập 16px. Không dùng chữ dưới 11px, kể cả chân trang, nhãn ảnh và ghi chú biểu đồ. Số liệu dùng chữ số có độ rộng đồng đều.
- Khoảng cách nền tảng theo đơn vị 4px; token góc bo 8px và 14px, thẻ và bìa có thể dùng 12–18px theo mẫu duyệt. Phân cấp bằng nền, đường viền, khoảng cách và trọng lượng chữ; dùng bóng đổ nhẹ khi cần, không dùng hiệu ứng chuyển động khi tải trang.
- Đơn vị, Đối tác, Chuyên gia, Bài toán AI và Nội dung hợp tác mở mặc định thành một trang tổng hợp kiểu CV: bìa navy với tên và ký tự đại diện, các vùng nghiệp vụ trắng tách biệt và File & tài liệu. Hồ sơ đối tác là ngoại lệ đọc liên tục: hiện toàn bộ dữ liệu của từng vùng, giữ cả vùng trống và không có nút xem đầy đủ. Mục lục trên màn hình lớn cuộn trong trang, không đổi hash điều hướng và tô mục theo vùng đang đọc; các vùng có số thứ tự giúp đọc nhanh. Trừ hồ sơ đối tác, mỗi nhóm trong trang tổng hợp hiện tối đa 6 hồ sơ, kèm **Xem tất cả N …** mở vùng chi tiết.
- Dashboard mở bằng hero dùng ảnh `public/brand/energy-hero.png`, kèm hai lối vào Đối tác và Bài toán AI. Phía dưới là bốn thẻ chỉ số, biểu đồ thanh ngang có nhãn/số đọc được và bốn khối hồ sơ mới nhất độc lập. Các khối dùng số liệu/hồ sơ hiện có theo quyền đọc và xử lý trạng thái tải, lỗi, rỗng riêng. Không suy diễn tỷ lệ tăng trưởng, tiến độ hoặc hiệu quả từ số lượng hiện tại.
- Hồ sơ đối tác ưu tiên đọc nhanh như một CV: đầu mối dạng bảng; nội dung hợp tác là một cấp riêng theo từng đối tác; nhật ký là timeline kết quả và bước tiếp theo; liên danh tách chiều tham gia/thành viên và chỉ có một đầu mối. Biểu mẫu đối tác chính không hỏi mã, ngày ghi nhận hoặc nguồn; các giá trị cũ vẫn được bảo toàn khi sửa.
- Nội dung hợp tác chỉ có ba vùng quan hệ: **Chủ thể PVN**, **Bài toán AI liên quan** và **Mốc làm việc**. Chủ thể PVN cho phép chọn nhiều đơn vị/Tập đoàn và đánh dấu một đầu mối; bài toán AI là tùy chọn và chỉ có một. Nội dung công việc khác không sinh thêm tầng hồ sơ. File của nội dung và các mốc liên quan cùng xuất hiện trong **File & tài liệu**; không tạo thêm vùng tài liệu riêng.
- Không hiển thị bộ chọn hoặc nhãn **Phạm vi chia sẻ** trong hồ sơ, danh sách và biểu mẫu file. Quyền vẫn được áp dụng phía dữ liệu; hồ sơ mới dùng mặc định nội bộ và file kế thừa đích. Hồ sơ đối tác chỉ trình bày loại, quốc gia, website, giới thiệu và năng lực; các trường nguồn cũ không xuất hiện trong trang nghiệp vụ chính.
- Trang chi tiết từng vùng của chủ thể chính dùng nút về Hồ sơ tổng hợp và bộ chọn mục gọn. Hồ sơ phụ mở thẳng thông tin đầy đủ, các liên kết và file, không lặp bước tổng hợp → thông tin. Vùng chỉ có một loại hồ sơ không lặp lại tiêu đề nhóm cùng loại. Thông tin đầy đủ giữ các nhóm trường có nhãn, nội dung dài, nguồn; thao tác xóa/khôi phục nằm ở đầu hồ sơ. Ở chiều rộng tối đa 960px, CV thành một cột và ẩn mục lục bên cạnh; nút xem chi tiết vẫn nằm trong mỗi vùng.
- Danh mục Đơn vị, Đối tác, Chuyên gia, Bài toán AI, Hợp tác và Đào tạo & hội thảo mở bằng một khối navy duy nhất gồm tên danh mục, mô tả ngắn, tổng số hồ sơ và nút Thêm; không đặt thêm tiêu đề trang, khẩu hiệu hay dòng eyebrow lặp. Có bộ chuyển dạng thẻ/bảng, mặc định dạng thẻ; bảng có cột Phân loại (loại · quốc gia). Hai kiểu xem dùng cùng dữ liệu, bộ lọc, tìm kiếm và phân trang; số tổng chỉ hiện một lần và phản ánh kết quả API. Từ khóa, bộ lọc, trang và kiểu xem được nhớ trong phiên để quay lại từ hồ sơ không mất vị trí; khi đổi trang, kết quả cũ mờ đi thay vì biến mất. Ký tự đại diện dùng tên viết tắt tối đa 4 ký tự nếu có. Thẻ lấy tên, mô tả, loại và ngày cập nhật từ hồ sơ, chỉ hiện trạng thái nghiệp vụ được phép hiển thị. Tra cứu toàn bộ và danh mục phụ dùng bảng.
- Bảng danh mục có hàng tiêu đề riêng, tên hồ sơ màu liên kết và phản hồi khi di chuột. Bảng khảo sát dùng cùng token trong `unit-survey.module.css`; bảng rộng cuộn trong vùng riêng có thể lấy focus.

- Không đặt dải thông tin trắng dưới banner hồ sơ. Mã hồ sơ và mã ánh xạ nội bộ không hiển thị trong biểu mẫu, chi tiết, bảng hoặc hộp chọn liên kết. Mã cũ được giữ để đối chiếu; hồ sơ mới được máy chủ cấp mã khi tạo. Nội dung nghiệp vụ bắt đầu ngay sau khoảng cách dưới banner.

## Khung ứng dụng và điều hướng

Điều hướng chính chia hai nhóm: **Lộ trình AI** (Bài toán chuẩn, Triển khai & hợp tác, Đối tác, Đơn vị) và **Năng lực** (Chuyên gia, Đào tạo & hội thảo), cùng Tổng quan và File & tài liệu. Không còn nhóm Tra cứu & quản trị (Tất cả hồ sơ, Thùng rác, Nguồn & chuẩn hóa); tìm kiếm toàn cục nằm ở thanh trên cùng. Dùng từ *hoạt động* cho một mục Triển khai & hợp tác, không gọi là "hồ sơ hoạt động".

Thanh trên nền sáng giữ tìm kiếm toàn cục và ngữ cảnh trang; sidebar giữ tài khoản, vai trò thực và đăng xuất. Footer dùng tên Petrovietnam, tên Tập đoàn và nhãn AI WORKSPACE. Việc sắp xếp lại menu không loại bỏ luồng nghiệp vụ hoặc cấp thêm quyền.

## File & tài liệu

Mỗi hồ sơ có một vùng File & tài liệu; không lặp nút đính kèm ở đầu hồ sơ hoặc tách thêm vùng Tài liệu tham khảo. Tệp có thể nằm trực tiếp ở gốc. Thư mục, tài liệu tham khảo cũ và file từ hồ sơ liên quan mở ngay trong vùng này, với đường quay về Tất cả file & thư mục. URL tham khảo vẫn có nút mở liên kết; metadata cũ có thể mở rộng để đọc.

Tạo thư mục, tải file, dùng file có sẵn và đổi tên là thao tác tại chỗ, chỉ hiện khi có quyền ghi. Thư mục mới kế thừa phạm vi chia sẻ của hồ sơ; tải file mới mặc định theo hồ sơ/thư mục đích. Biểu mẫu đổi tên phải nhắc tên mới áp dụng ở mọi hồ sơ dùng chung thư mục. Chỉ hỗ trợ một cấp thư mục; không gợi ý tính năng di chuyển, xóa hoặc nhập nguyên cây thư mục. Nhãn/số file phản ánh tài liệu đọc được, không dùng trạng thái metadata để khẳng định đã có tệp.

## Xóa hồ sơ

Đặt **Xóa hồ sơ** cạnh **Chỉnh sửa**, chỉ trên hồ sơ có quyền ghi, dùng nút phụ nhẹ trên bìa navy. Vùng xác nhận tại chỗ nêu đúng tên hồ sơ và việc giữ nguyên hồ sơ liên quan/file; có **Hủy**, **Xác nhận xóa**, trạng thái đang xử lý và chặn gửi lặp. Xóa xong quay về tab của loại hồ sơ. Khi xung đột phiên bản, yêu cầu **Tải lại hồ sơ**.

## Trang hồ sơ, biểu mẫu và màu trạng thái

- Mỗi trang hồ sơ và mỗi biểu mẫu là **một mặt trắng duy nhất**; các mục ngăn bằng đường kẻ ngang, không lồng hộp trong hộp. Tiêu đề mục 16px, số lượng dạng nhãn xám nhỏ, nút **Thêm mới / Chọn có sẵn** cùng dòng tiêu đề. Nhóm con (Đầu mối, Đơn vị tiềm năng…) là nhãn chữ in hoa nhỏ, không có khung nền.
- Dải số liệu nhanh đầu trang (bài toán chuẩn, đối tác, đơn vị) là các cột ngăn bằng vạch dọc, không phải thẻ. Trang hoạt động không có dải này vì các mục ngay dưới đã nêu đủ đầu mối, đối tác, bài toán chuẩn.
- Màu trạng thái dùng chung cho nhãn và biểu đồ (`src/lib/status-tone.ts`): Đề xuất xám, Đang trao đổi xanh trời, POC vàng hổ phách, Triển khai chính thức xanh dương, Pilot hồng, Vận hành xanh lá, Tạm dừng xám đá, Dừng đỏ; đối tác Chiến lược navy, Đang hợp tác xanh lá, Tiềm năng xanh trời; bài toán Chính thức xanh lá, Chờ rà soát hổ phách. Nhãn luôn kèm chữ, không dùng màu đơn lẻ.
- Mỗi bản ghi liên quan là **một dòng**: tên + nhãn vai trò/trạng thái (vd. *CMC OpenAI · Đầu mối liên danh*, *Cơ quan Tập đoàn · Đầu mối*). Không lặp tên đầu mối ở khối riêng, không hiện trạng thái thường lệ (đơn vị *Đang hoạt động*, bài toán *Chính thức*, đầu mối *Đang công tác*). Nhóm con chỉ dùng khi có nhiều loại vai trò cần tách (đơn vị đầu mối / tiềm năng của bài toán chuẩn).
- Không nhắc lại cùng một thông tin ở hai chỗ: đơn vị và đối tác đã có trong bảng hoạt động thì không liệt kê lại dạng "qua hoạt động"; dải số liệu không lặp trường đã có trong Thông tin chính; thư mục của hoạt động chỉ hiện ở File & tài liệu khi có file; mô tả đơn vị tự sinh từ khảo sát không hiện.
- Mục trống trên trang tổng hợp chỉ còn dòng tiêu đề (số 0 + nút thêm). Bảng hoạt động trên trang tổng hợp hiện tối đa 6 dòng kèm **Xem tất cả**; cột bài toán chuẩn ghi mã + tên, tối đa 2 dòng. Mốc làm việc là dòng có cột ngày, tên, trạng thái và một ghi chú gộp kết quả/bước tiếp theo.
- Bảng hoạt động dùng cột cố định (trạng thái, bên thực hiện/đầu mối, bài toán chuẩn), tên hoạt động lấy phần còn lại, không cuộn ngang. Trên trang đối tác/đơn vị, tên hoạt động bỏ phần lặp tên đối tác/đơn vị đó (tên đầy đủ ở tooltip). Dưới 760px, bảng hoạt động và bảng đầu mối thành các dòng xếp dọc có nhãn cột.
- Form sửa tại chỗ chỉ có **Hủy / Lưu** ở cuối, không thêm nút đóng ở tiêu đề. Mục đầu mối luôn có nút **Thêm đầu mối** trên dòng tiêu đề, kể cả khi trống.
- Tên chương trình AI hiển thị đầy đủ, viết hoa đầu câu như danh mục gốc ("AI cho …"), không cắt tiền tố.

## Tương tác và màn hình nhỏ

Tìm kiếm không có nút **Tìm**: ô tìm ở thanh trên hiện tối đa 8 gợi ý ngay khi gõ (không phân biệt dấu, ưu tiên tên bắt đầu bằng từ khóa; ↑/↓, Enter mở hồ sơ, Esc đóng, dòng cuối mở trang kết quả đầy đủ); danh sách, hộp chọn hồ sơ liên kết và kho tài liệu tự tìm sau khi ngừng gõ 0,3 giây (`useDebounce`), giữ kết quả cũ trong lúc tải. Ô tìm và ô chọn trong cùng thanh lọc cao 44px, cùng viền `--border-strong`, bo `--radius`; ô chọn tự vẽ mũi tên (không dùng giao diện mặc định của macOS).

Nút và ô nhập có chiều cao tối thiểu 44px. Biểu mẫu đang có thay đổi chưa lưu phải hỏi trước khi đóng dialog (Esc, bấm nền, nút đóng), bấm Hủy, chuyển trang trong ứng dụng hoặc đóng tab. Focus dùng xanh dương trên nền sáng, xanh sáng trên nền tối; menu di động giữ focus và đóng bằng Escape. Chuyển trạng thái ngắn, có hỗ trợ `prefers-reduced-motion`.

Ở chiều rộng tối đa 960px, sidebar chuyển thành menu thu gọn, giữ logo trắng bên trong; thanh trên cùng tiếp tục dùng nền sáng với nút mở menu và tìm kiếm. Lưới danh mục chuyển từ ba cột xuống hai cột ở tối đa 1200px, rồi một cột ở tối đa 650px. Ở màn hình nhỏ, hồ sơ và biểu mẫu chuyển thành một cột; bảng khảo sát chuyển nhãn câu hỏi lên trên câu trả lời, footer xếp dọc. Không thu nhỏ chữ ô nhập trên di động dưới 16px để ép nội dung vừa màn hình.

## Phạm vi bảo toàn

Các quy ước này điều chỉnh lớp trình bày và tương tác bằng các hợp đồng lưu hồ sơ, quan hệ và tài liệu hiện hữu. Đợt áp dụng thiết kế navy không thêm migration và không đổi schema database, API, xác thực, quyền truy cập, tài khoản hoặc phạm vi nhập khảo sát. Luồng khôi phục dùng endpoint/gateway hiện hữu được mô tả trong hợp đồng API; DELETE và dấu lưu trữ giữ tương thích. Các quyết định bỏ trạng thái xác minh, tab lịch sử/quản lý liên kết/cơ cấu đơn vị và giữ tra cứu khảo sát chỉ dành cho admin tiếp tục được áp dụng.
## Hồ sơ đối tác một trang

Hồ sơ đối tác luôn trình bày đầy đủ Thông tin chính, Đầu mối liên hệ, Nội dung hợp tác, Mốc làm việc, Liên danh và File & tài liệu trên một trang. Vùng chưa có dữ liệu vẫn giữ vị trí và hiển thị “Chưa có hồ sơ”. Không dùng liên kết “Xem đầy đủ” trong hồ sơ đối tác.

Đầu mối dùng bảng có các cột tên, vai trò/chức vụ, đơn vị/phòng ban, liên hệ và trạng thái, sửa trực tiếp trên dòng. Mốc làm việc cũng sửa nhanh các trường cơ bản trên dòng; thao tác **Nội dung hợp tác & file** mở dialog riêng để quản lý nhiều liên kết và file. Khi sửa, dialog nội dung hợp tác/mốc mở phần tổng quan liên kết và file trước; **Sửa thông tin** mở form và **Hủy** quay lại tổng quan. Tạo mới bắt đầu bằng form. **Bỏ** liên kết luôn hỏi xác nhận tại dòng. Mỗi nội dung hợp tác hiển thị trạng thái dạng tag, phân loại, chủ thể PVN, bài toán AI tùy chọn, số mốc, kết quả và bước tiếp theo. File của nội dung hợp tác được trình bày như một thư mục logic trong vùng File & tài liệu, không lặp thêm vùng tham khảo.


## Nội dung hợp tác từ trang đối tác

- Form **Thêm hoạt động** có khối **Bên tham gia và bài toán** ngay sau tên: *Bên thực hiện* mặc định là chính đối tác; nếu đối tác thuộc liên danh, chọn **Qua liên danh** (chọn liên danh khi có nhiều) và tích *đối tác này là đầu mối của hoạt động trong liên danh* (lưu ở `lead_member_id` của quan hệ hoạt động → liên danh). *Đơn vị đầu mối PVN* và *Bài toán chuẩn* là ô tìm trong danh mục (không dấu, ↑/↓/Enter, Esc đóng gợi ý trước khi đóng dialog); bài toán chuẩn có dòng **Thêm bài toán chuẩn mới** tạo bản *Chờ rà soát*.
- Hoạt động đã có: mục **Bên thực hiện** cho đổi giữa đối tác và liên danh; mục **Bài toán chuẩn** khi trống là ô tìm/thêm mới (cả trong dialog và trên trang hoạt động).
- **Liên danh là nhóm nhẹ, không phải đối tác**: hồ sơ loại *Liên danh* chỉ có tên, các đối tác thành viên ngang hàng (một đầu mối), hoạt động ký qua liên danh và file. Không hiện và không đếm trong menu Đối tác (dashboard đếm riêng số liên danh). Một công ty không có "thành viên"; muốn gom đối tác thì tạo liên danh. Trang đối tác: mục **Liên danh** liệt kê các liên danh đối tác tham gia, mỗi nhóm có toàn bộ thành viên, nhãn đầu mối, ô **Thêm đối tác vào liên danh** (chọn là thêm ngay) và **Rời liên danh**; đầu mục có **Tham gia liên danh** và **Tạo liên danh mới**. Trang liên danh: **Thành viên** (thêm, gỡ, đặt làm đầu mối) và **Triển khai & hợp tác**.
- Loại đối tác và loại hoạt động chọn từ danh mục cố định (`PARTNER_TYPES`, `ACTIVITY_TYPES`); nhãn cũ từ khảo sát/workbook gom bằng `activityType()`.
