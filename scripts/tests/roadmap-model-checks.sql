\set ON_ERROR_STOP on
select public.catalog_test_assert((select statuses from ai_management.module_registry where kind='collaboration')=array['Đề xuất','Đang trao đổi','POC','Triển khai chính thức','Pilot','Vận hành','Tạm dừng','Dừng'],'activities share one lifecycle');
select public.catalog_test_assert((select statuses from ai_management.module_registry where kind='partner')=array['Chiến lược','Đang hợp tác','Tiềm năng','Tạm dừng'],'partner status records the overall relationship');
select public.catalog_test_assert(not exists(select 1 from ai_management.records where kind='collaboration' and not status=any(array['Đề xuất','Đang trao đổi','POC','Triển khai chính thức','Pilot','Vận hành','Tạm dừng','Dừng'])),'existing activities mapped onto the lifecycle');
select public.catalog_test_assert(not exists(select 1 from ai_management.records where kind='partner' and not status=any(array['Chiến lược','Đang hợp tác','Tiềm năng','Tạm dừng'])),'existing partners received an overall status');
select public.catalog_test_assert(not exists(select 1 from ai_management.relations l join ai_management.records r on r.id=l.source_id where r.kind='collaboration' and l.relation='unit' and coalesce(l.context->>'subject_role','')='' and (select count(*) from ai_management.relations o where o.source_id=l.source_id and o.relation='unit')=1),'a single PVN subject becomes the lead subject');
begin;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare standard_id uuid; second_standard uuid; unit_a uuid; unit_b uuid; activity jsonb; consortium uuid; member uuid; signed jsonb; overview jsonb; leads int; dossier jsonb;
begin
 standard_id := (public.ai_catalog_save(jsonb_build_object('kind','use_case','title','Bài toán chuẩn kiểm thử','status','Chính thức','visibility','team','data',jsonb_build_object(
  'program','AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp','category','Nhóm nhập tự do','is_priority','Có','leadership_level','Đơn vị chủ động','start_year',2027)))->>'id')::uuid;
 second_standard := (public.ai_catalog_save(jsonb_build_object('kind','use_case','title','Bài toán chuẩn chờ rà soát','status','Chờ rà soát','visibility','team','data','{}'::jsonb))->>'id')::uuid;
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',jsonb_build_object('kind','use_case','title','X','status','Chính thức','visibility','team','data',jsonb_build_object('program','Chương trình khác'))::text),'VALIDATION','unknown programme rejected');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',jsonb_build_object('kind','use_case','title','X','status','Chính thức','visibility','team','data',jsonb_build_object('start_year',1999))::text),'VALIDATION','start year bounded');
 unit_a := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị kiểm thử A","status":"Đang hoạt động","visibility":"team","data":{}}')->>'id')::uuid;
 unit_b := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị kiểm thử B","status":"Đang hoạt động","visibility":"team","data":{}}')->>'id')::uuid;
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',standard_id,'target_id',unit_a,'relation','unit','context',jsonb_build_object('subject_role','lead')));
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',standard_id,'target_id',unit_b,'relation','unit','context',jsonb_build_object('subject_role','lead')));
 select count(*) into leads from jsonb_array_elements(public.ai_catalog_get(standard_id)->'links') link where link->>'relation'='unit' and link->'context'->>'subject_role'='lead';
 perform public.catalog_test_assert(leads=1,'a standard problem keeps one priority lead unit');
 perform public.catalog_test_assert((select link->'context'->>'subject_role' from jsonb_array_elements(public.ai_catalog_get(standard_id)->'links') link where link->>'target_id'=unit_a::text)='supporting','the previous lead becomes a potential unit');
 activity := public.ai_catalog_create_related_context(standard_id,jsonb_build_object('kind','collaboration','title','Hồ sơ hoạt động kiểm thử','status','POC','visibility','team','data',
  jsonb_build_object('cooperation_types','Đề tài KHCN','start_date','2026-01-01','end_date','2026-06-30','conclusion','Đạt')),'use_case','to-parent','{}'::jsonb);
 perform public.catalog_test_assert(activity->'data'->>'cooperation_types'='Đề tài KHCN','activity type is a free tag');
 perform public.catalog_test_error(format('select public.ai_catalog_link(%L::jsonb)',jsonb_build_object('source_id',activity->>'id','target_id',second_standard,'relation','use_case')::text),'VALIDATION','an activity belongs to one standard problem');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',jsonb_build_object('kind','collaboration','title','X','status','Chưa xác minh','visibility','team','data','{}'::jsonb)::text),'VALIDATION','old activity statuses rejected');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',jsonb_build_object('kind','collaboration','title','X','status','POC','visibility','team','data',jsonb_build_object('start_date','2026-05-01','end_date','2026-01-01'))::text),'VALIDATION','activity period cannot run backwards');
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',activity->>'id','target_id',unit_a,'relation','unit','context',jsonb_build_object('subject_role','lead')));
 consortium := (public.ai_catalog_save('{"kind":"partner","title":"Liên danh kiểm thử","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 member := (public.ai_catalog_save('{"kind":"partner","title":"Thành viên liên danh","status":"Đang hợp tác","visibility":"team","data":{}}')->>'id')::uuid;
 perform public.ai_catalog_consortium_link(jsonb_build_object('source_id',consortium,'target_id',member,'relation','partner','context',jsonb_build_object('consortium_role','lead')));
 signed := public.ai_catalog_create_related_context(consortium,jsonb_build_object('kind','collaboration','title','Hồ sơ qua liên danh','status','Đang trao đổi','visibility','team','data','{}'::jsonb),'partner','to-parent','{}'::jsonb);
 dossier := public.ai_catalog_dossier(member);
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(dossier->'related') entry where entry->'record'->>'id'=signed->>'id' and entry->'via'->>'id'=consortium::text),'a member partner sees activities signed by its consortium');
 perform public.catalog_test_assert(not exists(select 1 from jsonb_array_elements(public.ai_catalog_dossier(consortium)->'related') entry where entry->'via'->>'id'=member::text),'a consortium does not expand through its members');
 perform public.catalog_test_assert((public.ai_catalog_save(jsonb_build_object('kind','learning_event','title','Hội thảo kiểm thử','status','Dự kiến','visibility','team','data',jsonb_build_object('event_type','Khóa học')))->'data'->>'event_type')='Khóa học','training type is a free tag');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',jsonb_build_object('kind','learning_event','title','X','status','Dự kiến','visibility','team','data',jsonb_build_object('event_type',repeat('x',1001)))::text),'VALIDATION','training type keeps its length limit');
 overview := public.ai_catalog_overview();
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(overview->'standards') s where s->>'id'=standard_id::text and s->>'lead_unit_id'=unit_b::text and s->'potential_unit_ids' ? unit_a::text),'overview lists lead and potential units');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(overview->'activities') a where a->>'id'=activity->>'id' and a->>'standard_id'=standard_id::text and a->>'lead_unit_id'=unit_a::text),'overview links activities to their standard and lead unit');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(overview->'partners') p where p->>'id'=consortium::text and p->'member_ids' ? member::text),'overview lists consortium members');
end $$;
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
select public.catalog_test_error('select public.ai_catalog_overview()','FORBIDDEN','nonmember cannot read the overview');
reset role;
rollback;
