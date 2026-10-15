\set ON_ERROR_STOP on
select public.catalog_test_assert((select d.cooperation_types from ai_management.collaboration_details d join ai_management.records r on r.id=d.record_id where r.title='Hoạt động nhãn cũ')='POC','legacy activity types fold onto the fixed list');
select public.catalog_test_assert((select d.partner_type from ai_management.partner_details d join ai_management.records r on r.id=d.record_id where r.title='Liên danh chưa phân loại')='Liên danh','an untyped partner with members becomes a consortium');
select public.catalog_test_assert((select d.partner_type from ai_management.partner_details d join ai_management.records r on r.id=d.record_id where r.title='Thành viên chưa phân loại')='Trường đại học','legacy partner types fold onto the fixed list');
select public.catalog_test_assert(exists(select 1 from ai_management.audit a join ai_management.records r on r.id=a.record_id where r.title='Hoạt động nhãn cũ' and a.action='normalize_activity_type'),'type changes are audited');
begin;
select set_config('test.consortium',(select id::text from ai_management.records where title='Liên danh chưa phân loại'),true);
select set_config('test.member',(select id::text from ai_management.records where title='Thành viên chưa phân loại'),true);
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare activity jsonb; member text := current_setting('test.member');
begin
 activity := public.ai_catalog_create_related_context(current_setting('test.consortium')::uuid,
  '{"kind":"collaboration","title":"Hoạt động qua liên danh có đầu mối","status":"Đề xuất","visibility":"team","data":{}}'::jsonb,'partner','to-parent',jsonb_build_object('lead_member_id',member));
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_overview()->'activities') a
  where a->>'id'=activity->>'id' and a->>'partner_id'=current_setting('test.consortium') and a->>'party_lead_id'=member),'an activity through a consortium names its lead member');
end $$;
reset role;
rollback;
