-- Load the standard problem catalogue supplied by Ban KHCN on 14/10/2026 and
-- move unit problems onto it. Records are matched by unit names, declared
-- problem titles and import codes, never by generated IDs. Replaced records
-- go to the trash with an audit entry; nothing is deleted.
begin;
select pg_advisory_xact_lock(73424910902411);

create temporary table roadmap_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;
do $$ begin
 if not exists(select 1 from roadmap_actor) then raise exception 'An admin membership must own the imported standard problems'; end if;
end $$;

-- Matching key: Unicode NFC, collapsed spaces, no trailing punctuation, lower case.
create function pg_temp.roadmap_key(value text) returns text language sql immutable as $$
 select lower(regexp_replace(regexp_replace(btrim(normalize(coalesce(value,''),NFC)),'\s+',' ','g'),'[[:space:].;]+$',''))
$$;

create temporary table roadmap_program(n int primary key,name text not null) on commit drop;
insert into roadmap_program values
 (1,'AI cho tìm kiếm, thăm dò và khai thác'),
 (2,'AI cho vận hành, hiệu suất, độ tin cậy và toàn vẹn tài sản'),
 (3,'AI cho hoạch định, thương mại và tối ưu chuỗi năng lượng'),
 (4,'AI cho dự án đầu tư, EPCI và quản lý dự án'),
 (5,'AI cho an toàn, môi trường, rủi ro và kiểm soát tuân thủ'),
 (6,'AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp'),
 (7,'AI cho nghiên cứu, đổi mới sáng tạo và sản phẩm, công nghệ');
create temporary table roadmap_standard(stt int primary key,program int not null,category text,title text not null,is_priority text not null,
 start_year int,lead_key text,potential_keys text,leadership_level text,description text) on commit drop;
create temporary table roadmap_unit_problem(stt int not null,unit_title text not null,declared_title text not null) on commit drop;
insert into roadmap_standard(stt,program,category,title,is_priority,start_year,lead_key,potential_keys,leadership_level,description) values
(1,1,'Tra cứu và tổng hợp dữ liệu, tài liệu, tri thức chuyên ngành thăm dò - khai thác','AI tìm kiếm và tra cứu tri thức nội bộ chuyên ngành thăm dò - khai thác','Có',2026,'PETROVIETNAM','PVEP;VSP;BIENDONGPOC;PQPOC;VPI','Tập đoàn triển khai','Ứng dụng AI hỗ trợ tìm kiếm, tra cứu, hỏi – đáp và tổng hợp dữ liệu, tài liệu và tri thức nội bộ/chuyên ngành E&P từ các cơ sở dữ liệu và tài liệu chuyên môn; cung cấp kết quả kèm nguồn tham chiếu phục vụ nghiên cứu và tác nghiệp chuyên môn.'),
(2,1,'Cơ sở dữ liệu và tra cứu/tìm kiếm','Tự động tổng hợp báo cáo và quản trị dữ liệu','Không',null,null,null,null,'Ứng dụng AI hỗ trợ thu thập, tổng hợp và chuẩn hóa dữ liệu từ các nguồn E&P; tự động tổng hợp báo cáo định kỳ, báo cáo quản trị và hỗ trợ tra cứu, theo dõi dữ liệu phục vụ công tác điều hành.'),
(3,1,'Hiệu chỉnh, xử lý và minh giải tài liệu giếng khoan','Hiệu chỉnh và chuẩn hóa dữ liệu giếng khoan','Có',2027,'VPI','PVEP;VSP;BIENDONGPOC;PQPOC','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI/ML hỗ trợ kiểm tra chất lượng, phát hiện dữ liệu thiếu/bất thường và hiệu chỉnh, chuẩn hóa dữ liệu giếng khoan, bao gồm hỗ trợ dự báo missing log, phục vụ các bước xử lý và minh giải tiếp theo.'),
(4,1,'Hiệu chỉnh, xử lý, minh giải, tổng hợp và phân tích tài liệu giếng khoan','Xử lý và minh giải tài liệu giếng khoan','Không',null,null,null,null,'Ứng dụng AI/ML hỗ trợ xử lý, phân tích và minh giải dữ liệu giếng khoan/well-log, nhận diện các đặc trưng địa chất – địa vật lý và hỗ trợ chuyên gia đánh giá tầng chứa.'),
(5,1,'Hiệu chỉnh, xử lý và minh giải tài liệu giếng khoan','Phân tích, đánh giá và tổng hợp kết quả giếng khoan','Có',2027,'PVEP','PVEP;VSP;BIENDONGPOC;PQPOC;VPI','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI hỗ trợ tổng hợp kết quả giếng khoan từ các nguồn dữ liệu liên quan, phân tích và so sánh các chỉ tiêu chính, hỗ trợ đánh giá kết quả giếng và phục vụ cập nhật nhận định địa chất, khai thác.'),
(6,1,'Minh giải và tổng hợp tài liệu địa chấn','Ứng dụng AI hỗ trợ minh giải cấu trúc địa chất','Không',null,null,null,null,'Ứng dụng AI/ML hỗ trợ nhận diện và minh giải các cấu trúc địa chất trên tài liệu địa chấn, hỗ trợ xây dựng bản đồ địa chấn và rút ngắn thời gian xử lý, minh giải.'),
(7,1,'Minh giải và tổng hợp tài liệu địa chấn','AI hỗ trợ minh giải thuộc tính địa chấn đặc biệt','Không',null,null,null,null,'Ứng dụng AI/ML, bao gồm CNN, hỗ trợ phân tích và minh giải các thuộc tính địa chấn, nghịch đảo địa chấn và dự báo phân bố, thuộc tính đá chứa phục vụ đánh giá tầng chứa.'),
(8,1,'Minh giải cấu trúc và thuộc tính địa chấn, đánh giá tiềm năng và hỗ trợ lựa chọn vị trí khoan','AI phân tích tổng hợp tài liệu địa chất, địa chấn để đánh giá tiềm năng dầu khí','Có',2027,'VSP','PVEP;BIENDONGPOC;PQPOC;VPI','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI hỗ trợ tổng hợp và phân tích dữ liệu địa chất, địa chấn, giếng khoan và các thuộc tính liên quan để đánh giá tiềm năng dầu khí, hỗ trợ nhận diện và xếp hạng các khu vực triển vọng.'),
(9,1,'Minh giải và tổng hợp tài liệu địa chấn','Ứng dụng AI hỗ trợ lựa chọn các vị trí khoan thăm dò khai thác theo phương án địa chất','Không',null,null,null,null,'Ứng dụng AI hỗ trợ tổng hợp các kết quả địa chất, địa chấn và mô hình hiện có để so sánh, đánh giá và hỗ trợ lựa chọn các vị trí khoan thăm dò, khai thác theo phương án địa chất.'),
(10,1,'Quản trị tài chính, hợp đồng và PSC dầu khí','Trợ lý AI tự động hóa quản lý doanh thu, chi phí, phân chia sản phẩm dầu/khí','Không',null,null,null,null,'AI kết nối dữ liệu ERP và các báo cáo sản lượng khai thác, báo cáo thu hồi chi phí, báo cáo chi phí, quy định của PSC, quy định về thuế để phân chia sản phẩm dầu khí, xác định thu hồi chi phí và nghĩa vụ thuế. • Có cảnh báo đến hạn mức THCP'),
(11,1,'Quản trị tài chính, hợp đồng và PSC dầu khí','Trợ lý AI quản trị, hỏi đáp, kiểm toán và rủi ro hợp đồng dầu khí','Không',null,null,null,null,'Ứng dụng AI (LLM kết hợp RAG) để: • tra cứu điều khoản PSC • đối chiếu quy định pháp luật • rà soát hồ sơ chi phí • phát hiện khoản chi chưa phù hợp hợp đồng • phát hiện sai lệch giữa hồ sơ thanh toán và chứng từ • tổng hợp bằng chứng kiểm toán • hỗ trợ lập giấy tờ làm việc • hỗ trợ soạn báo cáo kiểm toán Trợ lý hỏi đáp hợp đồng dầu khí Kiểm toán chi phí thu hồi hợp đồng dầu khí'),
(12,1,'Thẩm định phát triển mỏ dầu khí','Trợ lý AI phân tích kinh tế mỏ cận biên và gia hạn PSC','Không',null,null,null,null,'Trợ lý kinh tế mỏ cận biên và gia hạn PSC'),
(13,1,'Tự động hóa xây dựng mô hình tĩnh động và tối ưu phương án khai thác','Ứng dụng AI đưa ra các phương án khai thác phù hợp dựa trên mô hình hiện hữu','Không',null,null,null,null,'Ứng dụng AI/ML khai thác các mô hình tĩnh, động và dữ liệu khai thác hiện hữu để phân tích, so sánh và đề xuất các phương án khai thác phù hợp; hỗ trợ đánh giá phương án nâng cao sản lượng và hệ số thu hồi dầu khí.'),
(14,2,'Giám sát, dự báo và tối ưu vận hành nhà máy','Quản lý năng lượng, phát thải và carbon/ESG','Không',null,null,null,null,'Ứng dụng AI phân tích dữ liệu vận hành từ DCS, SCADA, Historian và các hệ thống liên quan để đánh giá hiệu quả sử dụng năng lượng, nhận diện các điểm tiêu hao bất thường và hỗ trợ đề xuất chế độ vận hành tối ưu nhằm giảm tiêu hao năng lượng và phát thải của nhà máy.'),
(15,2,'Giám sát, dự báo và tối ưu vận hành nhà máy','AI hỗ trợ tối ưu chế độ vận hành lò hơi thông qua điều chỉnh Oxy dư','Không',null,null,null,null,'Ứng dụng AI phân tích các thông số vận hành, hiệu suất lò hơi trong quá khứ và dữ liệu thời gian thực để tính toán, đề xuất mức thiết lập Oxy dư phù hợp, qua đó hỗ trợ tối ưu hiệu suất vận hành lò hơi của nhà máy nhiệt điện than.'),
(16,2,'Giám sát, phát hiện bất thường và tối ưu vận hành nhà máy, hệ thống','AI giám sát, tối ưu vận hành, năng lượng và phát thải nhà máy','Có',2027,'PVCFC','PVGAS;BSR;NSRP;PVFCCO;PVPOWER;PVPGB;VNPOLY','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI khai thác dữ liệu từ Data Platform, DCS, SCADA, Historian, CMMS và các thiết bị hiện trường để giám sát trạng thái vận hành, dự báo diễn biến các thông số công nghệ như mức bồn, áp suất, lưu lượng; phát hiện bất thường của quá trình và hỗ trợ điều hành sản xuất. Đồng thời hỗ trợ đánh giá hiệu suất thiết bị, tối ưu tiêu hao năng lượng, phát thải và đưa ra cảnh báo hoặc khuyến nghị vận hành. Nội dung khai báo cũng bao gồm hỗ trợ dự báo nhu cầu bảo dưỡng, sửa chữa và nghiên cứu ứng dụng AI trong rà soát, thẩm định P&ID.'),
(17,2,'Quản lý tài sản, giám sát tình trạng thiết bị và bảo trì dự báo','AI phân tích dữ liệu PIG/MFL để nhận diện khuyết tật đường ống','Có',2027,'PVU','PVGAS','Tập đoàn dẫn dắt, đơn vị triển khai','Nghiên cứu ứng dụng thuật toán AI kết hợp dữ liệu rò rỉ đường sức từ MFL thu thập từ thiết bị khảo sát đường ống PIG để xử lý tín hiệu, nhận diện, phân loại và xác định kích thước các khuyết tật trên đường ống thép; qua đó nâng cao độ chính xác và mức độ tự động hóa trong công tác khảo sát, kiểm tra và đánh giá tình trạng đường ống.'),
(18,2,'Giám sát, kiểm tra và đánh giá toàn vẹn đường ống','AI và cảm biến giám sát rò rỉ, xâm nhập và ăn mòn đường ống','Không',null,null,null,null,'Ứng dụng AI kết hợp dữ liệu thu thập từ các hệ thống cảm biến để giám sát tình trạng đường ống, nhận diện và cảnh báo các dấu hiệu rò rỉ, xâm nhập, ăn mòn hoặc các trạng thái bất thường, phục vụ công tác giám sát an toàn và quản lý toàn vẹn hệ thống đường ống.'),
(19,2,'Lập kế hoạch và điều phối bảo dưỡng lớn','Điều phối lịch bảo dưỡng lớn','Không',null,null,null,null,'Xây dựng công cụ hỗ trợ điều phối lịch bảo dưỡng lớn giữa các nhà máy, công trình và đơn vị liên quan trên cơ sở kế hoạch sản xuất, tình trạng thiết bị, chu kỳ bảo dưỡng, nguồn lực nhân sự, vật tư, nhà thầu và thời gian dừng máy. Ứng dụng AI và thuật toán tối ưu để phát hiện xung đột lịch, đánh giá tác động của từng phương án đến sản lượng, chuỗi cung ứng và nghĩa vụ giao hàng, đồng thời đề xuất thời điểm và trình tự bảo dưỡng phù hợp. Giải pháp cho phép mô phỏng thay đổi tiến độ, sự cố phát sinh hoặc thiếu nguồn lực; hỗ trợ theo dõi các mốc công việc, đường găng và cảnh báo nguy cơ chậm tiến độ.'),
(20,2,'Mô phỏng và tối ưu vận hành bằng Digital Twin','Digital Twin nhà máy điện và tối ưu vận hành chuỗi khí – điện','Không',null,null,null,null,'Xây dựng nền tảng dữ liệu công nghiệp và mô hình Digital Twin nhằm hỗ trợ giám sát, mô phỏng và tối ưu vận hành nhà máy điện; từng bước mở rộng sang Digital Twin và tối ưu vận hành liên đơn vị trong chuỗi khí – điện.'),
(21,2,'Mô phỏng và tối ưu vận hành bằng Digital Twin','Digital Twin và AI/ML tối ưu vận hành nhà máy lọc hóa dầu','Không',null,null,null,null,'Nghiên cứu ứng dụng AI/ML kết hợp các hệ thống APC/RTO và Digital Twin nhằm hỗ trợ giám sát, mô phỏng và tối ưu các quá trình công nghệ trong nhà máy lọc hóa dầu. Digital Twin được xây dựng trên cơ sở tích hợp dữ liệu vận hành và các mô hình công nghệ để phản ánh trạng thái nhà máy, hỗ trợ phân tích các kịch bản và nâng cao hiệu quả tối ưu vận hành.'),
(22,2,'Mô phỏng và tối ưu vận hành bằng Digital Twin','Digital Twin và tối ưu vận hành hệ thống đường ống khí','Không',null,null,null,null,'Xây dựng Digital Twin cho hệ thống đường ống khí trên cơ sở tích hợp dữ liệu vận hành thực tế để hỗ trợ giám sát trạng thái hệ thống, mô phỏng các chế độ và kịch bản vận hành, đồng thời hỗ trợ phân tích và tối ưu vận hành hệ thống đường ống khí.'),
(23,2,'Quản lý tài sản, giám sát tình trạng thiết bị và bảo trì dự báo','AI hỗ trợ chẩn đoán và dự báo hỏng hóc thiết bị quay nhà máy điện','Có',2026,'PVPOWER','PVPGB;BSR;NSRP;PVCFC;PVFCCO','Tập đoàn dẫn dắt, đơn vị triển khai','Thu thập dữ liệu vận hành thời gian thực như dòng điện, độ rung, nhiệt độ, từ thông của các thiết bị quay chính trong nhà máy điện như ID Fan, FD Fan, bơm… để AI phân tích tình trạng, phát hiện bất thường và dự báo nguy cơ hoặc thời gian đến hỏng hóc, qua đó hỗ trợ xây dựng kế hoạch bảo trì, sửa chữa phù hợp.'),
(24,2,'Quản lý tài sản, giám sát tình trạng và bảo trì dự báo','AI quản lý tài sản, phát hiện bất thường và bảo trì tiên đoán thiết bị công nghiệp','Không',null,null,null,null,'Ứng dụng AI hỗ trợ quản lý tài sản, thiết bị theo vòng đời; phân loại, gắn mã, theo dõi biến động, kiểm kê, khấu hao và nhu cầu sử dụng/trang bị. Đồng thời phân tích dữ liệu cảm biến, dữ liệu vận hành và lịch sử hỏng hóc, bảo trì, bảo dưỡng để phát hiện sớm bất thường, phân tích nguyên nhân, dự báo nguy cơ hư hỏng và hỗ trợ tối ưu kế hoạch bảo trì. Phạm vi áp dụng gồm các thiết bị quan trọng tại nhà máy lọc hóa dầu, Gas Compressor, máy nén, máy bơm và các thiết bị công nghiệp khí.'),
(25,2,'Tra cứu, hỏi đáp và khai thác tri thức vận hành nhà máy','Trợ lý AI hỏi đáp kiến thức vận hành nhà máy','Không',null,null,null,null,'Xây dựng trợ lý AI/Chatbot hỗ trợ tra cứu và hỏi đáp các thông tin, tài liệu và kiến thức liên quan đến vận hành nhà máy, giúp người dùng tiếp cận nhanh các nội dung chuyên môn phục vụ công tác vận hành.'),
(26,3,'Dự báo, cân đối và điều độ khí/LNG','AI dự báo và cân đối cung – cầu khí/LNG','Không',null,null,null,null,'Ứng dụng AI để tổng hợp và phân tích dữ liệu cung, nhu cầu tiêu thụ và các yếu tố liên quan nhằm dự báo, cân đối cung – cầu khí/LNG theo từng giai đoạn; hỗ trợ đánh giá tình trạng thiếu/thừa nguồn và cung cấp thông tin phục vụ công tác lập kế hoạch, điều hành và quyết định thương mại.'),
(27,3,'Dự báo, cân đối và điều độ khí/LNG','AI tối ưu điều độ LNG, nhập khẩu và tồn kho','Không',null,null,null,null,'Ứng dụng AI hỗ trợ dự báo nhu cầu, cân đối nguồn cung và tối ưu kế hoạch nhập khẩu, điều độ tiếp nhận LNG và quản lý mức tồn kho, phục vụ nâng cao hiệu quả vận hành và điều hành chuỗi cung ứng LNG.'),
(28,3,'Dự báo, cân đối và điều độ khí/LNG','Cân đối/điều độ khí - LNG','Không',null,null,null,null,'Ứng dụng AI và mô hình tối ưu để tổng hợp nhu cầu khí, khả năng cung cấp từ các nguồn trong nước, kế hoạch nhập LNG, năng lực kho cảng, tồn chứa, tái hóa khí và giới hạn vận chuyển của hệ thống đường ống. Giải pháp hỗ trợ lập và cập nhật phương án cân đối nguồn – nhu cầu theo ngày, tháng và kỳ kế hoạch; tối ưu lịch tiếp nhận tàu, phân bổ khí/LNG cho từng khách hàng và xử lý các ràng buộc vận hành, hợp đồng, chất lượng khí và mức tồn kho an toàn. Hệ thống mô phỏng các tình huống thiếu nguồn, chậm tàu, biến động nhu cầu hoặc sự cố hạ tầng, từ đó đề xuất phương án điều độ khả thi và cảnh báo sớm nguy cơ mất cân đối.'),
(29,3,'Giám sát hiệu quả sản xuất – kinh doanh, công suất và tồn kho','AI giám sát biên lợi nhuận, công suất và tồn kho lọc hóa dầu','Không',null,null,null,null,'Ứng dụng AI hỗ trợ tổng hợp, theo dõi và phân tích các chỉ tiêu biên lợi nhuận/crack margin, công suất sản xuất và mức tồn kho trong hoạt động lọc hóa dầu, phục vụ công tác giám sát hiệu quả sản xuất – kinh doanh và hỗ trợ điều hành.'),
(30,3,'Mô phỏng, cân đối và tối ưu nguyên liệu – sản xuất – tồn kho','Mô phỏng kịch bản cân đối nguyên liệu - sản xuất - tồn kho','Không',null,null,null,null,'Xây dựng mô hình mô phỏng và tối ưu tích hợp chuỗi nguyên liệu – sản xuất – tồn kho trên cơ sở nhu cầu thị trường, hợp đồng mua bán, năng lực thiết bị, định mức tiêu hao, kế hoạch nhập nguyên liệu, cơ cấu sản phẩm và giới hạn kho chứa. Giải pháp cho phép thiết lập, so sánh các kịch bản về giá, nhu cầu, nguồn cung, công suất, dừng máy và chính sách tồn kho; lượng hóa tác động đến sản lượng, chi phí, biên lợi nhuận, mức tồn kho và khả năng đáp ứng đơn hàng. Kết quả hỗ trợ lựa chọn phương án vận hành và kế hoạch mua – sản xuất – bán tối ưu, đồng thời cảnh báo nguy cơ thiếu nguyên liệu, quá tải kho hoặc mất cân đối sản phẩm.'),
(31,3,'Tra cứu, khai thác tri thức và văn bản nội bộ','AI nhận dạng, tra cứu và đối chiếu vật tư kỹ thuật','Có',2027,'PVPOWER','NSRP;PVPGB;BSR;PVGAS;PVCFC;PVFCCO;PTSC;PVMR;PVDRILLING','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI tích hợp với hệ thống quản lý danh điểm vật tư để hỗ trợ tìm kiếm, chuẩn hóa dữ liệu vật tư và xác định vật tư tương đương dựa trên hình ảnh hoặc thông số kỹ thuật. Giải pháp có thể kết hợp cơ sở dữ liệu vật tư và hình ảnh, cơ sở dữ liệu vector, AI Engine và Chatbot để hỗ trợ tra cứu nhanh và cung cấp thông tin chi tiết về vật tư.'),
(32,3,'Phân tích kinh doanh, khách hàng và phát triển sản phẩm, dịch vụ','AI cho kinh doanh và khách hàng','Không',null,null,null,null,'Hỗ trợ dự báo giá và nhu cầu, phân tích thị trường và kinh doanh, tư vấn hoặc tương tác với khách hàng, người dùng và hỗ trợ phát triển sản phẩm, dịch vụ.'),
(33,3,'Phân tích, dự báo thị trường, giá, nhu cầu và hỗ trợ quyết định thương mại','AI phân tích, dự báo thị trường, giá và hỗ trợ quyết định thương mại','Không',null,null,null,null,'Ứng dụng AI/LLM để tự động tổng hợp tin tức, diễn biến thị trường và giá cả, xây dựng bản tin định kỳ và CSDL để dự báo giá, nhu cầu và phân tích các yếu tố ảnh hưởng đến giá bán. Hệ thống hỗ trợ đề xuất khoảng giá hoặc các kịch bản giá theo sản phẩm, thị trường, khu vực, nhóm khách hàng, kênh phân phối và thời điểm; cung cấp phân tích, cảnh báo và khuyến nghị phục vụ người có thẩm quyền xem xét, quyết định. Kết quả AI không tự động ban hành hoặc thay đổi giá bán và không thay thế trách nhiệm thẩm định, phê duyệt của các cấp có thẩm quyền.'),
(34,3,'Phân tích, dự báo thị trường, giá, nhu cầu và hỗ trợ quyết định thương mại','AI tự động hóa báo cáo thị trường và tồn kho hàng ngày','Không',null,null,null,null,'Tự động tổng hợp, chuẩn hóa và trình bày báo cáo thị trường dầu thô, xăng dầu, khí, phân bón và tồn kho các đơn vị thành file báo cáo Lãnh đạo Tập đoàn.'),
(35,3,'Phân tích, dự báo thị trường, giá, nhu cầu và hỗ trợ quyết định thương mại','AI xây dựng và duy trì CSDL thông tin thị trường tổng hợp.','Không',null,null,null,null,'Hỗ trợ thu thập, phân loại và cập nhật dữ liệu thị trường năng lượng từ nhiều nguồn phục vụ tra cứu và phân tích chung của Ban.'),
(36,3,'Phân tích, dự báo thị trường, giá, nhu cầu và hỗ trợ quyết định thương mại','AI dự báo giá và phân tích thị trường phục vụ giao dịch thương mại.','Không',null,null,null,null,'Phân tích dữ liệu giá, cung – cầu và các yếu tố vĩ mô để hỗ trợ ra quyết định giao dịch dầu thô, xăng dầu, khí, điện, than.'),
(37,3,'Phân tích, dự báo thị trường, giá, nhu cầu và hỗ trợ quyết định thương mại','Dự báo thị trường dùng chung','Không',null,null,null,null,'Xây dựng nền tảng dự báo thị trường dùng chung, tích hợp dữ liệu lịch sử tiêu thụ, giá cả, cung – cầu, tồn kho, hoạt động sản xuất – kinh doanh và các yếu tố kinh tế, mùa vụ có liên quan. Ứng dụng AI/ML để nhận diện xu hướng, dự báo nhu cầu và giá theo từng sản phẩm, khu vực và kỳ kế hoạch; đồng thời cho phép các đơn vị sử dụng chung một bộ giả định, kịch bản và phiên bản dự báo. Kết quả hỗ trợ lập kế hoạch sản xuất, kinh doanh, mua hàng, logistics và ngân sách; cung cấp cảnh báo sớm khi thị trường biến động hoặc kết quả thực tế lệch đáng kể so với dự báo.'),
(38,3,'Quản trị hợp đồng và nghiệp vụ thương mại','Trợ lý AI quản lý, rà soát và hỗ trợ soạn thảo hợp đồng thương mại','Không',null,null,null,null,'Xây dựng trợ lý AI hỗ trợ quản lý và khai thác thông tin hợp đồng thương mại; tra cứu, rà soát điều khoản, nghĩa vụ và các nội dung cần lưu ý; đồng thời hỗ trợ soạn thảo, hiệu chỉnh và chuẩn hóa hợp đồng trên cơ sở mẫu biểu, quy định và hồ sơ liên quan.'),
(39,3,'Quản trị hợp đồng và nghiệp vụ thương mại','AI hỗ trợ đàm phán và quản lý vòng đời hợp đồng thương mại quốc tế.','Không',null,null,null,null,'Rà soát điều khoản, đối chiếu tiền lệ đàm phán và cảnh báo rủi ro đối với các hợp đồng JMA, LA, GSPA, GTA, PPA.'),
(40,3,'Tư vấn khách hàng và hỗ trợ dịch vụ nông nghiệp','Chatbot AI hỗ trợ khách hàng và tư vấn nông nghiệp','Không',null,null,null,null,'Xây dựng Chatbot AI hỗ trợ tiếp nhận và trả lời các câu hỏi của khách hàng, cung cấp thông tin về sản phẩm, dịch vụ và các nội dung tư vấn liên quan đến nông nghiệp trên cơ sở nguồn dữ liệu, tài liệu và tri thức được tích hợp.'),
(41,4,'Phân tích danh mục đầu tư và phân bổ vốn','Phân tích danh mục đầu tư và phân bổ vốn','Không',null,null,null,null,'Ứng dụng AI và mô hình phân tích tài chính để tổng hợp, chuẩn hóa và đánh giá danh mục dự án đầu tư theo các tiêu chí chiến lược, hiệu quả tài chính, mức độ rủi ro, nhu cầu vốn, tiến độ, khả năng triển khai và sự phụ thuộc giữa các dự án. Giải pháp hỗ trợ xếp hạng ưu tiên, mô phỏng các kịch bản hạn mức vốn và tối ưu phân bổ vốn theo năm hoặc giai đoạn, có xét đến các ràng buộc ngân sách, nguồn vốn và mục tiêu danh mục. Hệ thống cung cấp phân tích độ nhạy, cảnh báo dự án có nguy cơ vượt vốn hoặc chậm tiến độ và đề xuất phương án điều chỉnh, giãn hoặc tái phân bổ vốn để nâng cao hiệu quả sử dụng vốn.'),
(42,4,'Rà soát, thẩm định và kiểm soát hồ sơ dự án đầu tư','AI hậu kiểm và rà soát quy trình cấp vốn','Không',null,null,null,null,'Ứng dụng AI hỗ trợ rà soát, đối chiếu hạng mục, giá trị và phạm vi công việc với kế hoạch sản xuất kinh doanh, dự toán, hợp đồng, biên bản nghiệm thu, hóa đơn, đề nghị thanh toán/tạm ứng và các hồ sơ liên quan; tổng hợp, so sánh giá trị vốn cấp với giá trị kế hoạch để hỗ trợ hậu kiểm và trình phương án cấp vốn.'),
(43,4,'Rà soát, thẩm định và kiểm soát hồ sơ dự án đầu tư về quy hoạch, pháp lý và kỹ thuật','Trợ lý AI tra cứu, rà soát quy hoạch, pháp lý và tài liệu kỹ thuật dự án năng lượng','Có',2027,'PVCHEM','PTSC;PVE;PETROCONS;PVPOWER;PVGAS;BSR;PVCFC;PVFCCO','Tập đoàn dẫn dắt, đơn vị triển khai','Xây dựng trợ lý AI hỗ trợ tra cứu, tổng hợp, rà soát và phân tích các quy hoạch điện và quy hoạch liên quan; văn bản pháp luật trong lĩnh vực điện, năng lượng tái tạo và đầu tư xây dựng; đồng thời hỗ trợ khai thác, rà soát và phân tích các tài liệu kỹ thuật của dự án điện.'),
(44,4,'Rà soát, thẩm định và kiểm soát hồ sơ dự án đầu tư','Trợ lý AI hỗ trợ thẩm định dự án lọc – hóa – khí','Không',null,null,null,null,'Xây dựng trợ lý AI hỗ trợ khai thác, tra cứu, tổng hợp và phân tích thông tin phục vụ công tác thẩm định các dự án lọc – hóa – khí; hỗ trợ chuyên viên rà soát hồ sơ, tìm kiếm thông tin liên quan và chuẩn bị các nội dung phục vụ thẩm định dự án.'),
(45,5,'Dự báo và quản lý rủi ro môi trường','Dự báo và quản lý rủi ro môi trường','Không',null,null,null,null,'Ứng dụng AI phân tích dữ liệu môi trường và các dữ liệu liên quan để dự báo, nhận diện và cảnh báo sớm các nguy cơ, sự cố môi trường, trong đó có nguy cơ tràn dầu; hỗ trợ công tác giám sát và chủ động triển khai các biện pháp phòng ngừa, ứng phó.'),
(46,5,'Giám sát an toàn, phát hiện nguy cơ và hỗ trợ ứng cứu sự cố','Camera AI giám sát an toàn, tuân thủ và ứng cứu sự cố','Có',2026,'BSR','PVCFC;PVGAS;PVPOWER;PVPGB;NSRP;PVFCCO;PVEP;VSP;PTSC','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI kết nối với hệ thống camera hiện hữu để giám sát các khu vực, hoạt động và tình huống liên quan đến an ninh, an toàn trong nhà máy; tự động nhận diện và cảnh báo các hành vi, điều kiện hoặc tình huống có nguy cơ mất an toàn, hỗ trợ công tác giám sát và kiểm soát an ninh, an toàn lao động.'),
(47,5,'Pháp lý, thẩm quyền và kiểm soát tuân thủ','Trợ lý AI tra cứu, rà soát pháp lý và tuân thủ','Không',null,null,null,null,'Xây dựng trợ lý AI hỗ trợ tra cứu văn bản pháp luật, quy chế và quy định nội bộ có trích dẫn đến điều, khoản và số hiệu văn bản; đồng thời rà soát hồ sơ, văn bản và điều khoản để phát hiện xung đột, thiếu căn cứ pháp lý, nghĩa vụ chưa rõ và các rủi ro tuân thủ. Khi không xác định được căn cứ phù hợp, hệ thống không đưa ra kết luận và kết quả chỉ phục vụ tham khảo nội bộ.'),
(48,5,'Pháp lý, thẩm quyền và kiểm soát tuân thủ','AI rà soát hồ sơ trình HĐTV và kiểm tra thẩm quyền phê duyệt','Không',null,null,null,null,'Ứng dụng AI để tóm tắt nội dung hồ sơ trình; đối chiếu giá trị và tính chất nghiệp vụ với Ma trận phân cấp thẩm quyền; kiểm tra tính đầy đủ của hồ sơ theo checklist; đối chiếu với nghị quyết, chỉ đạo trước đó và hỗ trợ phát hiện dấu hiệu vượt thẩm quyền, thiếu căn cứ pháp lý, sai lệch số liệu hoặc phát sinh so với chủ trương đã được phê duyệt.'),
(49,5,'Quản lý phát thải, carbon và ESG','Quản lý năng lượng, phát thải và carbon/ESG','Không',null,null,null,null,'Ứng dụng AI hỗ trợ tự động tổng hợp dữ liệu và lập báo cáo ESG, kiểm kê phát thải carbon; tính toán và phân tích dấu vết carbon của sản phẩm; đồng thời hỗ trợ theo dõi, phân tích và quản lý danh mục tín chỉ carbon và các chỉ tiêu ESG liên quan.'),
(51,6,'Phân tích chỉ tiêu, báo cáo quản trị và hỗ trợ lập kế hoạch sản xuất kinh doanh','AI phân tích KPI, báo cáo và lập kế hoạch SXKD','Có',2027,'PETROVIETNAM','ALL','Tập đoàn triển khai','Ứng dụng AI để phân tích dữ liệu và các chỉ số KPI; tự động tổng hợp, tóm tắt và thuyết minh báo cáo quản trị; nhận diện các nội dung chậm tiến độ, rủi ro và vấn đề cần lãnh đạo xem xét. Đồng thời hỗ trợ lập, phân tích và theo dõi kế hoạch sản xuất kinh doanh, cung cấp thông tin phục vụ công tác điều hành và ra quyết định.'),
(52,6,'Phân tích tài chính, chi phí, ngân sách và tài sản','AI cho tài chính, chi phí và tài sản','Không',null,null,null,null,'Hỗ trợ tổng hợp, phân tích, tính toán và dự báo doanh thu, chi phí, ngân sách và nghĩa vụ tài chính; đồng thời theo dõi tài sản và nhu cầu sử dụng, tổng hợp sản lượng, tồn kho và doanh thu giao dịch thương mại'),
(53,6,'Phân tích tài chính, chi phí, ngân sách và tài sản','AI phân tích tài chính, chi phí và ngân sách','Không',null,null,null,null,'Ứng dụng AI để tổng hợp và phân tích dữ liệu tài chính, chi phí và ngân sách; tự động nhận diện, phân loại chi phí, phát hiện khoản mục bất thường, phân tích nguyên nhân biến động và đề xuất cơ hội tối ưu chi phí. Hệ thống hỗ trợ dự báo chi phí và nhu cầu ngân sách, cảnh báo nguy cơ vượt ngân sách, đồng thời hỗ trợ phân tích sơ bộ tình hình tài chính doanh nghiệp.'),
(54,6,'Quản lý hợp đồng, đấu thầu và kiểm toán','AI cho hợp đồng, đấu thầu và kiểm toán','Không',null,null,null,null,'Hỗ trợ quản lý vòng đời hợp đồng và đấu thầu; tra cứu, tổng hợp, đối chiếu điều khoản, nghĩa vụ, hồ sơ, chứng từ, chi phí và các mốc thực hiện; hỗ trợ nhận diện, cảnh báo các nội dung cần rà soát, sai lệch hoặc rủi ro trong quá trình thực hiện hợp đồng và chuẩn bị tài liệu phục vụ công tác kiểm tra, kiểm toán'),
(55,6,'Tra cứu, khai thác tri thức và văn bản nội bộ','Trợ lý AI tra cứu và khai thác tri thức doanh nghiệp','Có',2027,'PETROVIETNAM','ALL','Tập đoàn triển khai','Ứng dụng AI để tìm kiếm, hỏi – đáp, tóm tắt và khai thác quy chế, quy trình, hướng dẫn, tài liệu nghiệp vụ và tri thức nội bộ bằng ngôn ngữ tự nhiên; cung cấp câu trả lời có trích dẫn nguồn và tuân thủ phạm vi phân quyền truy cập.'),
(56,6,'Tra cứu nghiệp vụ Đảng – Đoàn và hỗ trợ soạn thảo văn bản','Trợ lý AI nghiệp vụ Đảng – Đoàn và hỗ trợ soạn thảo văn bản','Không',null,null,null,null,'Ứng dụng AI hỗ trợ tra cứu, hỏi – đáp các quy định và hướng dẫn về nghiệp vụ Đảng, đoàn thể có trích dẫn nguồn; đồng thời hỗ trợ phác thảo báo cáo, nghị quyết, chương trình hành động và các văn bản nghiệp vụ từ nội dung, kết luận cuộc họp.'),
(57,6,'Tra cứu và hỗ trợ nghiệp vụ nhân sự','Trợ lý AI tra cứu và hỗ trợ nghiệp vụ nhân sự','Không',null,null,null,null,'Xây dựng trợ lý AI hỗ trợ người lao động và cán bộ nghiệp vụ tra cứu, hỏi – đáp các chính sách, quy định và quy trình nhân sự như ngày phép, tiêu chuẩn chức danh, đào tạo, biệt phái và các chế độ liên quan; cung cấp câu trả lời kèm nguồn tham chiếu từ văn bản nội bộ.'),
(58,6,'Tự động hóa tác nghiệp, văn bản và điều hành công việc','Trợ lý AI tích hợp ERP hỗ trợ tra cứu và tác nghiệp nghiệp vụ','Không',null,null,null,null,'Tích hợp AI vào hệ thống ERP để hỗ trợ người dùng tra cứu, hỏi – đáp dữ liệu, tìm kiếm thông tin và tự động hoặc hỗ trợ thực hiện một số tác vụ nghiệp vụ thường xuyên trên hệ thống.'),
(59,6,'Tự động hóa tác nghiệp, xử lý văn bản và điều hành công việc','AI xử lý văn bản và trợ lý tổng hợp, thư ký','Có',2026,'PETROVIETNAM','ALL','Tập đoàn triển khai','Ứng dụng AI để tóm tắt văn bản, báo cáo và hồ sơ; trích xuất thông tin trọng yếu, yêu cầu xử lý và thời hạn; hỗ trợ phân loại, gắn thẻ, luân chuyển và rà soát thể thức văn bản. Đồng thời sử dụng Speech-to-Text và AI để hỗ trợ lập, tóm tắt biên bản họp và tổng hợp tài liệu, báo cáo, tờ trình, lịch sử trao đổi phục vụ công tác tổng hợp, thư ký.'),
(60,6,'Tự động hóa tác nghiệp, văn bản và điều hành công việc','AI theo dõi chỉ đạo, nhiệm vụ và cảnh báo tiến độ','Không',null,null,null,null,'Ứng dụng AI để theo dõi nhiệm vụ và chỉ đạo điều hành; tự động tổng hợp tình hình thực hiện, nhiệm vụ chậm và các nội dung trọng yếu phục vụ giao ban; hỗ trợ nhắc việc, cảnh báo quá hạn và phát hiện các dấu hiệu bất thường trong việc cập nhật và thực hiện nhiệm vụ.'),
(61,7,'Hỗ trợ nghiên cứu, phát triển công nghệ, vật liệu và sản phẩm mới chuyên ngành','AI hỗ trợ R&D công nghệ, vật liệu, xúc tác và sản phẩm mới','Có',2027,'VPI','BSR;PVCFC;PVFCCO;PVCHEM','Tập đoàn dẫn dắt, đơn vị triển khai','Ứng dụng AI hỗ trợ hoạt động nghiên cứu và phát triển trong các lĩnh vực hydrogen, nhiên liệu hàng không bền vững SAF, tái chế vật liệu, xúc tác, vật liệu mới và công thức sản phẩm mới; hỗ trợ thu thập, tổng hợp và phân tích dữ liệu, tài liệu nghiên cứu để phục vụ đánh giá và lựa chọn các hướng nghiên cứu tiềm năng.'),
(62,7,'Phân tích dữ liệu cây trồng và tối ưu bón phân','Machine Learning hỗ trợ bón phân chính xác cho cây trồng','Không',null,null,null,null,'Nghiên cứu ứng dụng mô hình Machine Learning để phân tích dữ liệu liên quan đến cây trồng và điều kiện canh tác, từ đó hỗ trợ xác định lượng và chế độ bón phân phù hợp, hướng tới sử dụng phân bón chính xác và hiệu quả hơn.');
insert into roadmap_unit_problem(stt,unit_title,declared_title) values
(1,'Viện Dầu khí Việt Nam','Chatbot hỏi đáp lĩnh dữ liệu chuyên môn (Well-log, E&P, Tạp chí Dầu khí,...)'),
(3,'Viện Dầu khí Việt Nam','Dự báo missing log'),
(5,'Chi nhánh Tập đoàn – Công ty Điều hành Dầu khí Phú Quốc','Drilling AI'),
(8,'Liên doanh Việt – Nga Vietsovpetro','ứng dụng AI/ML trong địa chất'),
(16,'Công ty Cổ phần Phân bón Dầu khí Cà Mau','AI cho dự án nhà máy thông minh: hỗ trợ vận hành; bảo trì tuyên đoán; đánh giá công nghệ, thiết bị; tối ưu năng lượng;'),
(23,'Tổng công ty Điện lực Dầu khí Việt Nam – CTCP','Ứng dụng mô hình dự báo của AWS để dự báo bất thường hư hỏng quạt khói IDF Nhà máy Điện Vũng Áng 1'),
(31,'Chi nhánh Phát điện Dầu khí','AI hỗ trợ nhận dạng, tìm kiếm vật tư, thông số kỹ thuật vật tư, xác định vật tư tương đương'),
(32,'Công ty Cổ phần PVI','Ứng dụng OCR trong xử lý hồ sơ bồi thường'),
(43,'Tổng công ty Hóa chất và Dịch vụ Dầu khí','Quản lý dự án'),
(46,'Công ty Cổ phần Lọc hóa dầu Bình Sơn','Triển khai giải pháp AI kết nối với các Camera hiện hữu để giám sát, kiểm soát phục vụ công tác An ninh, An toàn của Nhà máy.'),
(51,'Chi nhánh Phát điện Dầu khí','AI hỗ trợ phân tích dữ liệu, báo cáo quản trị'),
(55,'Ngân hàng Thương mại Cổ phần Đại Chúng Việt Nam','Xây dựng Kho dữ liệu văn bản điện tử và AI Chatbot tra cứu, khai thác tri thức văn bản điện tử'),
(59,'Tổng công ty Phân bón và Hóa chất Dầu khí – CTCP','AI Agent hỗ trợ sáng tạo, chỉnh sửa nội dung và phân tích dữ liệu'),
(61,'Viện Dầu khí Việt Nam','AI Agent tự động nghiên cứu'),
(5,'Tổng công ty Thăm dò Khai thác Dầu khí','Ứng dụng AI giám sát, phân tích và tư vấn tối ưu hóa thi công giếng khoan theo thời gian thực'),
(6,'Tổng công ty Thăm dò Khai thác Dầu khí','Ứng dụng Machine Learning trên Petrel hỗ trợ minh giải cấu trúc và xây dựng bản đồ địa chấn tại Lô B và Lô 01/10&02/10'),
(7,'Tổng công ty Thăm dò Khai thác Dầu khí','Ứng dụng AI/CNN trong nghịch đảo địa chấn, dự báo phân bố và thuộc tính đá chứa, đánh giá tiềm năng dầu khí phục vụ tối ưu giếng khoan và định hướng thăm dò tại các dự án của PVEP.'),
(10,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý AI tự động hóa quản lý doanh thu, chi phí, phân chia sản phẩm dầu/khí'),
(11,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý kiểm toán hợp đồng dầu khí'),
(13,'Tổng công ty Thăm dò Khai thác Dầu khí','AI hỗ trợ đánh giá và đề xuất giải pháp nâng cao hệ số thu hồi dầu'),
(15,'Chi nhánh Phát điện Dầu khí','AI hỗ trợ tính toán, đề xuất chế độ vận hành lò hơi của nhà máy nhiệt điện than thông qua điều chỉnh Oxy dư.'),
(16,'Tổng công ty Khí Việt Nam – CTCP','AI cho điều hành sản xuất sẽ đọc dữ liệu từ Data Platform chung phục vụ Dự đoán BDSC, ứng dụng trong dự đoán bình bồn, áp lực, thẩm định P&ID (AWS)'),
(17,'Trường Đại học Dầu khí Việt Nam','Nghiên cứu ứng dụng thuật toán trí tuệ nhân tạo AI cho thiết bị khảo sát đường ống thép (PIG) để nhận diện các khuyết tật.'),
(20,'Tổng công ty Điện lực Dầu khí Việt Nam – CTCP','Xây dựng mô hình thử nghiệm Digital Twin cho Nhà máy điện Cà Mau 1&2'),
(23,'Chi nhánh Phát điện Dầu khí','AI hỗ trợ chuẩn đoán tình trạng, dự báo hỏng hóc cho tiết bị quay chính (động cơ, máy phát) trong nhà máy điện'),
(24,'Công ty Cổ phần Lọc hóa dầu Bình Sơn','Ứng dụng AI bảo trì tiên đoán (predictive maintenance) cho các thiết bị quan trọng.'),
(24,'Tổng công ty Thăm dò Khai thác Dầu khí','Phát hiện bất thường của thiết bị và quá trình từ dữ liệu vận hành + Dự báo hư hỏng, bảo trì tiên đoán cho thiết bị Gas-lift Compressor'),
(24,'Viện Dầu khí Việt Nam','Predictive Maintenance'),
(25,'Công ty TNHH Lọc hóa dầu Nghi Sơn','Xây dựng Enterprise AI Knowledge Management'),
(31,'Công ty TNHH Lọc hóa dầu Nghi Sơn','Tìm kiếm tra cứu thông tin vật tư bằng AI (Bao gồm cả hình ảnh)'),
(32,'Ngân hàng Thương mại Cổ phần Đại Chúng Việt Nam','Ngân hàng hội thoại (Conversation Banking)'),
(32,'Trường Đại học Dầu khí Việt Nam','Trợ lý AI tư vấn tuyển sinh và hỗ trợ thí sinh lựa chọn chương trình đào tạo.'),
(33,'Tổng công ty Phân bón và Hóa chất Dầu khí – CTCP','Xây dựng công cụ Giải pháp chiến lược kinh doanh, bao gồm mô hình hỗ trợ quyết định giá bán'),
(34,'Viện Dầu khí Việt Nam','Bản tin thị trường tự động'),
(36,'Viện Dầu khí Việt Nam','Dự báo giá sản phẩm (brent oil, lng,...)'),
(38,'Tổng công ty Hóa chất và Dịch vụ Dầu khí','Quản lý hợp đồng'),
(42,'Cơ quan Tập đoàn','AI rà soát quy trình cấp vốn'),
(46,'Công ty Cổ phần PVI','Ứng dụng AI trong giám sát hạ tầng - an ninh mạng'),
(47,'Cơ quan Tập đoàn','AI rà soát pháp lý, quy chế, quy định, hợp đồng'),
(47,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý hỏi–đáp quy chế, quy định nội bộ và pháp luật có trích dẫn nguồn, phục vụ công tác cho ý kiến và kiểm tra, giám sát'),
(48,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý rà soát tờ trình, hồ sơ trình HĐTV và đối chiếu thẩm quyền theo Ma trận phân cấp thẩm quyền'),
(51,'Công ty TNHH Lọc hóa dầu Nghi Sơn','Phân tích các thông tin tài chính, vận hành của công ty dùng AI'),
(51,'Cơ quan Tập đoàn','AI tổng hợp báo cáo quản trị điều hành'),
(51,'Tổng công ty Hóa chất và Dịch vụ Dầu khí','Quản trị điều hành'),
(52,'Tổng công ty Thăm dò Khai thác Dầu khí','Hỗ trợ công tác quản trị hành chính, cơ sở vật chất và chi phí'),
(52,'Tổng công ty Thăm dò Khai thác Dầu khí','Hỗ trợ quản lý tài sản và bảo trì thông minh'),
(53,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý AI phân tích sơ bộ tình hình tài chính của PVEP'),
(54,'Tổng công ty Cổ phần Khoan và Dịch vụ Khoan Dầu khí','Hệ thống quản lý đấu thầu và hợp đồng'),
(55,'Trường Đại học Dầu khí Việt Nam','Trợ lý AI tra cứu, hỏi đáp quy chế, quy trình và tài liệu nội bộ của Trường'),
(55,'Tổng công ty Cổ phần Vận tải Dầu khí','PVTrans AI Assistant – Trợ lý AI tra cứu, hỏi đáp và khai thác tri thức nội bộ'),
(55,'Tổng công ty Dầu Việt Nam – CTCP','Trợ lý hỏi–đáp văn bản, quy định nội bộ có trích dẫn nguồn
Tóm tắt nội dung và hỗ trợ soạn thảo'),
(55,'Tổng công ty Khí Việt Nam – CTCP','AI cho Quản trị doanh nghiệp sẽ dùng đọc dữ liệu từ M-File, O365 (Copilot)'),
(55,'Tổng công ty Thăm dò Khai thác Dầu khí','Quản lý và khai thác tri thức doanh nghiệp'),
(56,'Tổng công ty Thăm dò Khai thác Dầu khí','Trợ lý AI hỏi–đáp và hỗ trợ soạn thảo văn bản nghiệp vụ Đảng - Đoàn PVEP'),
(57,'Công ty TNHH Lọc hóa dầu Nghi Sơn','Xin nghỉ và duyệt nghỉ phép dùng AI'),
(57,'Tổng công ty Thăm dò Khai thác Dầu khí','HR Copilot PVEP'),
(58,'Tổng công ty Khí Việt Nam – CTCP','Áp dụng AI cho việc nhập liệu tự động vào SAP và các hệ thống khác'),
(58,'Tổng công ty Thăm dò Khai thác Dầu khí','AI nhúng trong hệ thống ERP'),
(59,'Công ty Cổ phần PVI','Ứng dụng OCR trong công tác thanh quyết toán'),
(59,'Công ty Cổ phần Phân bón Dầu khí Cà Mau','AI cho tự đống hóa quy trình; tư vấn quy trình, trợ lý nghiệp vụ. AI hỗ trợ kiểm soát, vận hành, tuân thủ'),
(59,'Trường Đại học Dầu khí Việt Nam','Hệ thống AI hỗ trợ quản lý minh chứng, đối sánh tiêu chí và lập báo cáo tự đánh giá phục vụ kiểm định chất lượng giáo dục trong nước và quốc tế'),
(59,'Tổng công ty Cổ phần Dịch vụ Kỹ thuật Dầu khí Việt Nam','1. Tóm tắt, tổng hợp tài liệu hoặc báo cáo nhanh hơn giảm 1,976 giờ / tuần / ~300 user
2. Tìm/tra cứu nhanh tài liệu, thông tin và quy định nội bộ giảm 1,733 giờ / tuần / ~300 user
3. Phân tích dữ liệu / tổng hợp báo cáo phục vụ ra quyết định giảm 1,798 giờ / tuần / ~300 user
4. Hỗ trợ soạn thảo và chuẩn hóa văn bản / biểu mẫu giảm 1,820 giờ / tuần / ~300 user
5. Tự động hóa các tác vụ lặp lại / nhiều bước giảm 913 giờ / tuần / ~150 user
6. So sánh, rà soát và kiểm tra hồ sơ / phiên bản tài liệu'),
(59,'Tổng công ty Thăm dò Khai thác Dầu khí','AI nhúng trong hệ thống 1Office'),
(59,'Tổng công ty Thăm dò Khai thác Dầu khí','Tự động hóa xử lý văn bản và quản lý tài liệu; Trợ lý ảo hỗ trợ công tác tổng hợp và thư ký'),
(59,'Tổng công ty Tư vấn Thiết kế Dầu khí – CTCP','Sữ dụng AI lập trình và bảo trì hệ thống văn phòng số'),
(60,'Tổng công ty Cổ phần Dịch vụ Kỹ thuật Dầu khí Việt Nam','7. Theo dõi công việc, nhắc việc và deadline giảm 1,203 giờ / tuần / ~200 user.
8. Hỗ trợ họp, biên bản và kết luận công việc giảm 643 giờ / tuần / ~100 user'),
(60,'Tổng công ty Thăm dò Khai thác Dầu khí','Tự động tổng hợp báo cáo giám sát định kỳ và cảnh báo sớm nhiệm vụ, kiến nghị quá hạn từ hệ thống 10 phân hệ dashboard KSNB'),
(61,'Trường Đại học Dầu khí Việt Nam','Nghiên cứu xây dựng nền tảng phần mềm tích hợp dữ liệu năng lượng ngoài khơi có hỗ trợ AI đáng tin cậy nhằm tăng cường năng lực sẵn sàng cho phát triển năng lượng tái tạo trong tương lai tại Việt Nam'),
(61,'Trường Đại học Dầu khí Việt Nam','Nhận thức của sinh viên học tiếng Anh như một ngoại ngữ về tính hữu ích của phản hồi do AI tạo ra về bài nói tiếng Anh so với phản hồi từ giáo viên.'),
(61,'Trường Đại học Dầu khí Việt Nam','Trợ lý AI hỗ trợ nghiên cứu khoa học, tìm kiếm và tổng hợp tài liệu');

-- Units are identified by their abbreviation, compared without spaces or punctuation.
create temporary table roadmap_unit on commit drop as
select r.id,r.title,upper(regexp_replace(coalesce(d.abbreviation,''),'[^[:alnum:]]','','g')) unit_key
from ai_management.records r join ai_management.unit_details d on d.record_id=r.id
where r.kind='unit' and r.archived_at is null;
create temporary table roadmap_standard_key on commit drop as
select s.stt,k.unit_key,false is_lead from roadmap_standard s
cross join lateral unnest(string_to_array(s.potential_keys,';')) k(unit_key) where s.potential_keys<>'ALL'
union all
select s.stt,s.lead_key,true from roadmap_standard s where s.lead_key is not null;
do $$
declare problem text;
begin
 select string_agg(distinct x.unit_key,', ') into problem from roadmap_standard_key x
 where not exists(select 1 from roadmap_unit u where u.unit_key=x.unit_key);
 if problem is not null then raise exception 'Standard catalogue names unknown units: %',problem; end if;
 select string_agg(distinct u.unit_key,', ') into problem from roadmap_unit u
 where u.unit_key in (select unit_key from roadmap_standard_key) and (select count(*) from roadmap_unit o where o.unit_key=u.unit_key)>1;
 if problem is not null then raise exception 'Several active units share the abbreviation: %',problem; end if;
end $$;
-- "Toàn bộ các đơn vị trong Tập đoàn" means every unit except the Group head office.
create temporary table roadmap_standard_unit on commit drop as
select x.stt,u.id unit_id,x.is_lead from roadmap_standard_key x join roadmap_unit u using(unit_key)
union all
select s.stt,u.id,false from roadmap_standard s join roadmap_unit u on u.unit_key<>'PETROVIETNAM' where s.potential_keys='ALL';

-- 1. Standard problems keep the use_case kind; codes BTC-01 … BTC-62 follow the source numbering.
insert into ai_management.records(kind,title,code,status,source_note,visibility,created_by)
select 'use_case',s.title,'BTC-'||lpad(s.stt::text,2,'0'),'Chính thức',
 'Danh mục bài toán chuẩn do Ban KHCN cung cấp ngày 14/10/2026.','team',(select user_id from roadmap_actor)
from roadmap_standard s
where not exists(select 1 from ai_management.records r where r.code='BTC-'||lpad(s.stt::text,2,'0'));
create temporary table roadmap_standard_id on commit drop as
select s.stt,r.id from roadmap_standard s join ai_management.records r on r.code='BTC-'||lpad(s.stt::text,2,'0') and r.kind='use_case';
insert into ai_management.use_case_details(record_id,program,category,objective,leadership_level,is_priority,start_year)
select i.id,p.name,s.category,s.description,s.leadership_level,s.is_priority,s.start_year
from roadmap_standard s join roadmap_standard_id i using(stt) join roadmap_program p on p.n=s.program
on conflict(record_id) do nothing;
insert into ai_management.relations(source_id,target_id,relation,context,created_by)
select i.id,x.unit_id,'unit',jsonb_build_object('subject_role',case when bool_or(x.is_lead) then 'lead' else 'supporting' end),(select user_id from roadmap_actor)
from roadmap_standard_unit x join roadmap_standard_id i using(stt)
group by i.id,x.unit_id
on conflict(source_id,target_id,relation) do nothing;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select i.id,(select user_id from roadmap_actor),'import_standard_catalog',
 jsonb_build_object('code','BTC-'||lpad(s.stt::text,2,'0'),'title',s.title,'is_priority',s.is_priority,'lead_key',s.lead_key,'potential_keys',s.potential_keys)
from roadmap_standard s join roadmap_standard_id i using(stt);

-- 2. Each unit demand becomes an activity of type "Bài toán đơn vị", keeping its ID, files and sources.
create temporary table roadmap_demand on commit drop as
select d.id demand_id,d.created_by,u.id unit_id,dd.original_title,dd.scope,dd.business_owner,dd.expectations,
 substring(d.summary from 'Trạng thái đơn vị khai báo: ([^\n]*)') declared_status,
 to_jsonb(d)||jsonb_build_object('data',to_jsonb(dd)-'record_id'-'kind') before_value,
 coalesce((select array_agg(l.target_id) from ai_management.relations l where l.source_id=d.id and l.relation='use_case'),'{}') old_use_cases,
 (select array_agg(distinct p.stt) from roadmap_unit_problem p
  where pg_temp.roadmap_key(p.unit_title)=pg_temp.roadmap_key(u.title) and pg_temp.roadmap_key(p.declared_title)=pg_temp.roadmap_key(dd.original_title)) matches
from ai_management.records d
join ai_management.demand_details dd on dd.record_id=d.id
left join ai_management.relations lu on lu.source_id=d.id and lu.relation='unit'
left join ai_management.records u on u.id=lu.target_id
where d.kind='demand' and d.archived_at is null;
do $$ begin
 if exists(select 1 from roadmap_demand where cardinality(matches)>1) then raise exception 'A unit demand matches several catalogue rows'; end if;
 if exists(select demand_id from roadmap_demand group by demand_id having count(*)>1) then raise exception 'A unit demand is linked to several units'; end if;
end $$;
-- Partner cooperation recorded per unit problem, resolved before the old links go.
create temporary table roadmap_partner_problem on commit drop as
select c.id collaboration_id,c.summary,d.demand_id,
 (select l.target_id from ai_management.relations l where l.source_id=c.id and l.relation='partner' limit 1) partner_id,
 count(*) over (partition by d.demand_id) per_demand,
 count(*) over (partition by c.id) per_collaboration
from ai_management.records c
join ai_management.relations lu on lu.source_id=c.id and lu.relation='unit'
join ai_management.relations luc on luc.source_id=c.id and luc.relation='use_case'
join roadmap_demand d on d.unit_id=lu.target_id and luc.target_id=any(d.old_use_cases)
where c.kind='collaboration' and c.archived_at is null;

delete from ai_management.demand_details where record_id in (select demand_id from roadmap_demand);
update ai_management.records r set kind='collaboration',version=r.version+1,status=case
  when d.declared_status ~* 'áp dụng|vận hành' then 'Vận hành'
  when d.declared_status ~* 'poc|thử nghiệm' then 'POC'
  when d.declared_status ~* 'triển khai' then 'Triển khai chính thức'
  else 'Đề xuất' end
from roadmap_demand d where r.id=d.demand_id;
insert into ai_management.collaboration_details(record_id,cooperation_types,declared_title,scope,lead,source_status)
select d.demand_id,'Bài toán đơn vị',left(d.original_title,1000),left(coalesce(d.scope,d.expectations),10000),d.business_owner,
 case when d.declared_status is null then null else left('Đơn vị khai báo: '||d.declared_status,1000) end
from roadmap_demand d;
update ai_management.relations l set context=l.context||jsonb_build_object('subject_role','lead')
from roadmap_demand d where l.source_id=d.demand_id and l.relation='unit';
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select l.source_id,d.created_by,'replace_use_case_link',to_jsonb(l),null
from ai_management.relations l join roadmap_demand d on d.demand_id=l.source_id where l.relation='use_case';
delete from ai_management.relations l using roadmap_demand d where l.source_id=d.demand_id and l.relation='use_case';
insert into ai_management.relations(source_id,target_id,relation,created_by)
select d.demand_id,i.id,'use_case',(select user_id from roadmap_actor)
from roadmap_demand d join roadmap_standard_id i on i.stt=d.matches[1] where cardinality(d.matches)=1;
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select d.demand_id,d.created_by,'convert_demand_to_activity',d.before_value,
 jsonb_build_object('kind','collaboration','standard_code',case when cardinality(d.matches)=1 then 'BTC-'||lpad(d.matches[1]::text,2,'0') end)
from roadmap_demand d;

-- 3. A unit problem with exactly one partner absorbs that partner's cooperation record.
create temporary table roadmap_merge on commit drop as
select p.collaboration_id,p.demand_id,p.partner_id,p.summary,partner.title partner_title
from roadmap_partner_problem p left join ai_management.records partner on partner.id=p.partner_id
where p.per_demand=1 and p.per_collaboration=1 and p.partner_id is not null
 and not exists(select 1 from ai_management.relations l where l.source_id=p.demand_id and l.relation='partner');
insert into ai_management.relations(source_id,target_id,relation,note,context,created_by)
select m.demand_id,l.target_id,'partner',l.note,l.context,l.created_by
from roadmap_merge m join ai_management.relations l on l.source_id=m.collaboration_id and l.relation='partner';
update ai_management.relations l set target_id=m.demand_id from roadmap_merge m
where l.target_id=m.collaboration_id and not exists(select 1 from ai_management.relations x where x.source_id=l.source_id and x.target_id=m.demand_id and x.relation=l.relation);
update ai_management.relations l set source_id=m.demand_id from roadmap_merge m
where l.source_id=m.collaboration_id and l.relation not in ('partner','unit','use_case')
 and not exists(select 1 from ai_management.relations x where x.source_id=m.demand_id and x.target_id=l.target_id and x.relation=l.relation);
insert into ai_management.document_links(record_id,document_id,version_id,created_by,created_at)
select m.demand_id,l.document_id,l.version_id,l.created_by,l.created_at from roadmap_merge m join ai_management.document_links l on l.record_id=m.collaboration_id
on conflict(record_id,document_id) do nothing;
insert into ai_management.source_links(source_id,record_id,created_by,created_at)
select l.source_id,m.demand_id,l.created_by,l.created_at from roadmap_merge m join ai_management.source_links l on l.record_id=m.collaboration_id
on conflict(source_id,record_id) do nothing;
update ai_management.records r set version=r.version+1,
 summary=left(concat_ws(E'\n\n',nullif(r.summary,''),'Đối tác theo khảo sát: '||m.partner_title||coalesce(' — '||substring(m.summary from 'Tình trạng theo bài toán: ([^\n]*)'),'')),10000)
from roadmap_merge m where r.id=m.demand_id;
update ai_management.records r set archived_at=now(),version=r.version+1 from roadmap_merge m where r.id=m.collaboration_id;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select m.collaboration_id,r.created_by,'merge_into_activity',jsonb_build_object('target_id',m.demand_id,'partner_id',m.partner_id)
from roadmap_merge m join ai_management.records r on r.id=m.collaboration_id;

-- 4. Other per-problem partner records stay separate and point at the same standard problem.
create temporary table roadmap_repoint on commit drop as
select distinct p.collaboration_id,i.id standard_id
from roadmap_partner_problem p join roadmap_demand d on d.demand_id=p.demand_id join roadmap_standard_id i on i.stt=d.matches[1]
where cardinality(d.matches)=1 and p.collaboration_id not in (select collaboration_id from roadmap_merge)
 and p.per_collaboration=1;
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select l.source_id,(select user_id from roadmap_actor),'replace_use_case_link',to_jsonb(l),jsonb_build_object('target_id',x.standard_id)
from roadmap_repoint x join ai_management.relations l on l.source_id=x.collaboration_id and l.relation='use_case';
delete from ai_management.relations l using roadmap_repoint x where l.source_id=x.collaboration_id and l.relation='use_case';
insert into ai_management.relations(source_id,target_id,relation,created_by)
select x.collaboration_id,x.standard_id,'use_case',(select user_id from roadmap_actor) from roadmap_repoint x;

-- 5. Survey-derived standard problems are replaced by the official catalogue.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select l.source_id,(select user_id from roadmap_actor),'replace_use_case_link',to_jsonb(l),null
from ai_management.relations l join ai_management.records s on s.id=l.source_id join ai_management.records t on t.id=l.target_id
where l.relation='use_case' and s.kind='collaboration' and t.kind='use_case' and t.code like 'KS-USE\_CASE-%';
delete from ai_management.relations l using ai_management.records s,ai_management.records t
where s.id=l.source_id and t.id=l.target_id and l.relation='use_case' and s.kind='collaboration' and t.kind='use_case' and t.code like 'KS-USE\_CASE-%';
insert into ai_management.audit(record_id,actor_id,action,after_value)
select r.id,(select user_id from roadmap_actor),'replaced_by_standard_catalog',jsonb_build_object('title',r.title)
from ai_management.records r where r.kind='use_case' and r.archived_at is null and r.code like 'KS-USE\_CASE-%';
update ai_management.records r set archived_at=now(),version=r.version+1
where r.kind='use_case' and r.archived_at is null and r.code like 'KS-USE\_CASE-%';

-- 6. Partner records without a type tag are partner cooperation.
update ai_management.collaboration_details d set cooperation_types='Hợp tác đối tác'
from ai_management.records r where r.id=d.record_id and r.archived_at is null and d.cooperation_types is null;

-- 7. Priority table status column (decision 12): PVCFC has run a camera AI POC.
insert into ai_management.records(kind,title,code,status,source_note,visibility,created_by)
select 'collaboration','POC Camera AI giám sát an toàn – PVCFC','BTC-46-PVCFC-POC','POC',
 'Theo cột Hiện trạng của danh sách 14 bài toán ưu tiên (14/10/2026): đơn vị đã POC.','team',(select user_id from roadmap_actor)
where not exists(select 1 from ai_management.records where code='BTC-46-PVCFC-POC');
insert into ai_management.collaboration_details(record_id,cooperation_types)
select r.id,'POC' from ai_management.records r where r.code='BTC-46-PVCFC-POC' on conflict(record_id) do nothing;
insert into ai_management.relations(source_id,target_id,relation,context,created_by)
select r.id,u.id,'unit',jsonb_build_object('subject_role','lead'),(select user_id from roadmap_actor)
from ai_management.records r join roadmap_unit u on u.unit_key='PVCFC' where r.code='BTC-46-PVCFC-POC'
on conflict(source_id,target_id,relation) do nothing;
insert into ai_management.relations(source_id,target_id,relation,created_by)
select r.id,i.id,'use_case',(select user_id from roadmap_actor)
from ai_management.records r join roadmap_standard_id i on i.stt=46 where r.code='BTC-46-PVCFC-POC'
 and not exists(select 1 from ai_management.relations l where l.source_id=r.id and l.relation='use_case');
insert into ai_management.audit(record_id,actor_id,action,after_value)
select r.id,(select user_id from roadmap_actor),'create',jsonb_build_object('code',r.code,'title',r.title)
from ai_management.records r where r.code='BTC-46-PVCFC-POC' and not exists(select 1 from ai_management.audit a where a.record_id=r.id);

-- 8. Expert competencies and affiliations become text on the expert profile.
create temporary table roadmap_expert_text on commit drop as
select e.id expert_id,
 (select a.organization_name from ai_management.records ar join ai_management.affiliation_details a on a.record_id=ar.id
   join ai_management.relations l on l.source_id=ar.id and l.relation='expert' and l.target_id=e.id
   where ar.archived_at is null and a.organization_name is not null order by (a.is_primary='Có') desc,ar.created_at limit 1) organization,
 (select string_agg(concat_ws(' · ',nullif(a.organization_name,''),nullif(a.position,''),nullif(a.department,''),nullif(a.period_label,''),nullif(a.notes,'')),E'\n' order by ar.created_at)
   from ai_management.records ar join ai_management.affiliation_details a on a.record_id=ar.id
   join ai_management.relations l on l.source_id=ar.id and l.relation='expert' and l.target_id=e.id where ar.archived_at is null) work_history,
 (select string_agg(concat_ws(' · ',xr.title,nullif(x.proficiency,''),case when x.years_experience is not null then x.years_experience||' năm kinh nghiệm' end,nullif(x.experience,'')),E'\n' order by xr.created_at)
   from ai_management.records xr join ai_management.expertise_details x on x.record_id=xr.id
   join ai_management.relations l on l.source_id=xr.id and l.relation='expert' and l.target_id=e.id where xr.archived_at is null) expertise_summary
from ai_management.records e where e.kind='expert' and e.archived_at is null;
update ai_management.expert_details d set
 organization=coalesce(d.organization,left(t.organization,1000)),
 work_history=coalesce(d.work_history,left(t.work_history,10000)),
 expertise_summary=coalesce(d.expertise_summary,left(t.expertise_summary,10000))
from roadmap_expert_text t where d.record_id=t.expert_id;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select r.id,r.created_by,'fold_into_expert_profile',jsonb_build_object('expert_id',l.target_id)
from ai_management.records r join ai_management.relations l on l.source_id=r.id and l.relation='expert'
where r.kind in ('affiliation','expertise') and r.archived_at is null;
update ai_management.records r set archived_at=now(),version=r.version+1 where r.kind in ('affiliation','expertise') and r.archived_at is null;

-- 9. Re-derive partner statuses that the structure migration derived, now that
-- unit problems carry their partners. Statuses set by people are left alone.
create temporary table roadmap_partner_rederive on commit drop as
select p.id,p.status old_status,case
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null
   and a.status in ('POC','Triển khai chính thức','Pilot','Vận hành')) then 'Đang hợp tác'
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null
   and a.status in ('Đề xuất','Đang trao đổi')) then 'Tiềm năng'
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null) then 'Tạm dừng'
  else 'Tiềm năng' end new_status
from ai_management.records p
where p.kind='partner' and (select a.action from ai_management.audit a where a.record_id=p.id order by a.id desc limit 1)='derive_partner_status';
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select p.id,p.created_by,'derive_partner_status',jsonb_build_object('status',m.old_status),jsonb_build_object('status',m.new_status)
from roadmap_partner_rederive m join ai_management.records p on p.id=m.id where m.new_status<>m.old_status;
update ai_management.records p set status=m.new_status,version=p.version+1 from roadmap_partner_rederive m where m.id=p.id and m.new_status<>m.old_status;
commit;
