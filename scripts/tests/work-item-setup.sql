\set ON_ERROR_STOP on
-- Activities without a standard problem, shaped like the survey and workbook rows they came from.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$ begin
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Hoạt động đào tạo cũ","status":"Đề xuất","data":{"cooperation_types":"Đào tạo"}}');
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Ký MOU nghiên cứu","status":"Đề xuất","data":{"cooperation_types":"POC","scope":"MOU nghiên cứu và đào tạo"}}');
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Tư vấn AI governance","status":"Đề xuất","data":{"cooperation_types":"Tư vấn","scope":"Khung quản trị AI"}}');
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Hợp tác trung tâm dữ liệu","status":"Đề xuất","data":{"cooperation_types":"Hợp tác đối tác","scope":"Xây dựng CSDL chuyên ngành; big data"}}');
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Triển khai nền tảng AI","status":"Đề xuất","data":{"cooperation_types":"Hợp tác đối tác","scope":"Cloud và GPU"}}');
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Trợ lý AI cho đơn vị","status":"Đề xuất","data":{"cooperation_types":"Bài toán đơn vị","scope":"AI Chatbot"}}');
end $$;
reset role;
