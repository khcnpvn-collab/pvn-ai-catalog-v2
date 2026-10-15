-- Partner type and activity type are picked from fixed lists; existing values were folded onto
-- them by 202610140005. The registry mirrors the form so the UI contract stays one source.
begin;
update ai_management.module_registry set fields=(
 select jsonb_agg(case when f->>'key'='partner_type' then jsonb_build_object('key','partner_type','type','select','options',
   jsonb_build_array('Doanh nghiệp/nhà cung cấp','Trường đại học','Viện/tổ chức nghiên cứu','Cơ quan nhà nước','Tư vấn','Truyền thông/sự kiện','Liên danh')) else f end order by n)
 from jsonb_array_elements(fields) with ordinality x(f,n)) where kind='partner';
update ai_management.module_registry set fields=(
 select jsonb_agg(case when f->>'key'='cooperation_types' then jsonb_build_object('key','cooperation_types','type','select','options',
   jsonb_build_array('Bài toán đơn vị','POC','Đề tài KHCN','Hợp tác đối tác','Hạ tầng','Đào tạo','MOU / hợp tác chiến lược','Tư vấn')) else f end order by n)
 from jsonb_array_elements(fields) with ordinality x(f,n)) where kind='collaboration';
commit;
