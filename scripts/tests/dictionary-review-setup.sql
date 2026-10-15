\set ON_ERROR_STOP on
-- Records shaped like production before the data dictionary review.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$ begin
 perform public.ai_catalog_save('{"kind":"partner","title":"Công ty rà soát","status":"Chiến lược","visibility":"team","observed_on":"2026-08-11","source_note":"Khảo sát","data":{"partner_type":"Doanh nghiệp/nhà cung cấp","country":"Việt Nam","aliases":"CTRS","document_notes":"Ghi chú giới thiệu cần giữ"}}');
 perform public.ai_catalog_save('{"kind":"partner","title":"Viện rà soát","status":"Tiềm năng","visibility":"team","summary":"Giới thiệu sẵn có","data":{"partner_type":"Viện/tổ chức nghiên cứu","document_notes":"Ghi chú bổ sung"}}');
 perform public.ai_catalog_save('{"kind":"unit","title":"Cơ quan Tập đoàn rà soát","status":"Chưa xác minh","visibility":"team","data":{"abbreviation":"PETROVIETNAM","capabilities":"Nội dung khảo sát"}}');
end $$;
reset role;
-- Earlier fixtures used free-text values outside the reviewed lists; production has none.
update ai_management.partner_details set partner_type='Công ty công nghệ' where partner_type not in ('Doanh nghiệp/nhà cung cấp','Trường đại học','Viện/tổ chức nghiên cứu','Cơ quan nhà nước','Tư vấn','Truyền thông/sự kiện','Liên danh');
update ai_management.partner_details set country='Khác' where country not in ('Việt Nam','Hoa Kỳ','Trung Quốc','Nhật Bản','Hàn Quốc','Singapore','Ấn Độ','Vương quốc Anh','Pháp','Đức','Hà Lan','Na Uy','Thụy Sĩ','Israel','Liên bang Nga','Các Tiểu vương quốc Ả Rập Thống nhất','Ả Rập Xê Út','Úc','Canada','Khác');
update ai_management.records set status='Đang hợp tác' where kind='partner' and status not in ('Chiến lược','Đang hợp tác','Tiềm năng','Tạm dừng');
