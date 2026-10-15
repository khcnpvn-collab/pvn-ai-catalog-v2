\set ON_ERROR_STOP on
-- Fixtures shaped like the survey import: unit demands linked to generated
-- standard problems, and per-problem partner cooperation records.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare unit_key text; unit_id uuid; vpi uuid; pvcfc uuid; uc1 uuid; uc2 uuid; uc3 uuid; d1 uuid; d2 uuid; d3 uuid;
declare p1 uuid; p2 uuid; p3 uuid; c1 uuid; c2 uuid; c3 uuid; c4 uuid; expert uuid; aff uuid; skill uuid;
begin
 foreach unit_key in array array['BIENDONGPOC','BSR','NSRP','PETROCONS','PETROVIETNAM','PQPOC','PTSC','PVCHEM','PVDRILLING','PVE','PVEP','PVFCCO','PVGAS','PVMR','PVPGB','PVPOWER','PVU','VNPOLY','VSP'] loop
  unit_id := (public.ai_catalog_save(jsonb_build_object('kind','unit','title','Đơn vị '||unit_key,'status','Đang hoạt động','visibility','team','data',jsonb_build_object('abbreviation',unit_key)))->>'id')::uuid;
 end loop;
 vpi := (public.ai_catalog_save('{"kind":"unit","title":"Viện Dầu khí Việt Nam","status":"Đang hoạt động","visibility":"team","data":{"abbreviation":"VPI"}}')->>'id')::uuid;
 pvcfc := (public.ai_catalog_save('{"kind":"unit","title":"Công ty Cổ phần Phân bón Dầu khí Cà Mau","status":"Đang hoạt động","visibility":"team","data":{"abbreviation":"PVCFC"}}')->>'id')::uuid;
 uc1 := (public.ai_catalog_save('{"kind":"use_case","title":"Dự báo missing log","code":"KS-USE_CASE-000000000000000000000001","status":"Chờ rà soát","visibility":"team","data":{}}')->>'id')::uuid;
 uc2 := (public.ai_catalog_save('{"kind":"use_case","title":"AI cho dự án nhà máy thông minh","code":"KS-USE_CASE-000000000000000000000002","status":"Chờ rà soát","visibility":"team","data":{}}')->>'id')::uuid;
 uc3 := (public.ai_catalog_save('{"kind":"use_case","title":"Bài toán ngoài danh mục","code":"KS-USE_CASE-000000000000000000000003","status":"Chờ rà soát","visibility":"team","data":{}}')->>'id')::uuid;
 d1 := (public.ai_catalog_save(jsonb_build_object('kind','demand','title','Dự báo missing log · VPI','status','Chưa xác minh','visibility','team','summary','Đơn vị: VPI'||E'\n'||'Trạng thái đơn vị khai báo: POC (thử nghiệm)','data',jsonb_build_object('original_title','Dự báo  missing log','scope','Giếng khoan','business_owner','Phòng dữ liệu')))->>'id')::uuid;
 d2 := (public.ai_catalog_save(jsonb_build_object('kind','demand','title','Nhà máy thông minh · PVCFC','status','Chưa xác minh','visibility','team','summary','Trạng thái đơn vị khai báo: Ý tưởng','data',jsonb_build_object('original_title','AI cho dự án nhà máy thông minh: hỗ trợ vận hành; bảo trì tuyên đoán; đánh giá công nghệ, thiết bị; tối ưu năng lượng;','expectations','Mô tả nhu cầu: tối ưu')))->>'id')::uuid;
 d3 := (public.ai_catalog_save(jsonb_build_object('kind','demand','title','Bài toán ngoài danh mục · VPI','status','Chưa xác minh','visibility','team','summary','Trạng thái đơn vị khai báo: Đang áp dụng','data',jsonb_build_object('original_title','Bài toán ngoài danh mục')))->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',d1,'target_id',vpi,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',d1,'target_id',uc1,'relation','use_case'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',d2,'target_id',pvcfc,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',d2,'target_id',uc2,'relation','use_case'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',d3,'target_id',vpi,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',d3,'target_id',uc3,'relation','use_case'));
 p1 := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác một","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 p2 := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác hai","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 p3 := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác ba","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 c1 := (public.ai_catalog_save(jsonb_build_object('kind','collaboration','title','Đối tác một · VPI · Dự báo missing log','status','POC','visibility','team','summary','Tình trạng theo bài toán: PoC','data','{}'::jsonb))->>'id')::uuid;
 c2 := (public.ai_catalog_save('{"kind":"collaboration","title":"Đối tác hai · PVCFC","status":"Đề xuất","visibility":"team","data":{}}')->>'id')::uuid;
 c3 := (public.ai_catalog_save('{"kind":"collaboration","title":"Đối tác ba · PVCFC","status":"Đề xuất","visibility":"team","data":{}}')->>'id')::uuid;
 c4 := (public.ai_catalog_save('{"kind":"collaboration","title":"Đối tác một · VPI","status":"Đang trao đổi","visibility":"team","data":{"cooperation_types":"MOU"}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',c1,'target_id',p1,'relation','partner'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c1,'target_id',vpi,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c1,'target_id',uc1,'relation','use_case'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c2,'target_id',p2,'relation','partner'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c2,'target_id',pvcfc,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c2,'target_id',uc2,'relation','use_case'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c3,'target_id',p3,'relation','partner'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c3,'target_id',pvcfc,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c3,'target_id',uc2,'relation','use_case'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c4,'target_id',p1,'relation','partner'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',c4,'target_id',vpi,'relation','unit'));
 expert := (public.ai_catalog_save('{"kind":"expert","title":"Chuyên gia kiểm thử","status":"Đã trao đổi","visibility":"team","data":{}}')->>'id')::uuid;
 aff := (public.ai_catalog_save('{"kind":"affiliation","title":"Công tác","status":"Hiện tại","visibility":"team","data":{"organization_name":"Đại học Kiểm thử","position":"Giảng viên","is_primary":"Có"}}')->>'id')::uuid;
 skill := (public.ai_catalog_save('{"kind":"expertise","title":"Học máy","status":"Đã ghi nhận","visibility":"team","data":{"proficiency":"Chuyên sâu","years_experience":8}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',aff,'target_id',expert,'relation','expert'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',skill,'target_id',expert,'relation','expert'));
 insert into public.catalog_test_state values
  ('roadmap_vpi',to_jsonb(vpi)),('roadmap_pvcfc',to_jsonb(pvcfc)),('roadmap_d1',to_jsonb(d1)),('roadmap_d2',to_jsonb(d2)),('roadmap_d3',to_jsonb(d3)),
  ('roadmap_p1',to_jsonb(p1)),('roadmap_c1',to_jsonb(c1)),('roadmap_c2',to_jsonb(c2)),('roadmap_c3',to_jsonb(c3)),('roadmap_c4',to_jsonb(c4)),
  ('roadmap_expert',to_jsonb(expert)),('roadmap_aff',to_jsonb(aff)),('roadmap_skill',to_jsonb(skill));
end $$;
reset role;
