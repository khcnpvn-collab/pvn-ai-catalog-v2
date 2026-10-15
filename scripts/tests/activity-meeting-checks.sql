\set ON_ERROR_STOP on
-- The typed meeting date became a held milestone of the activity; the next step moved into the results.
select public.catalog_test_assert((select count(*) from ai_management.relations l join ai_management.records e on e.id=l.source_id and e.kind='engagement'
  join ai_management.engagement_details d on d.record_id=e.id
  where l.target_id='71000000-0000-4000-8000-000000000001' and l.relation='collaboration' and d.start_date='2026-08-24' and d.end_date='2026-08-24'
   and e.status='Đã diễn ra' and e.title='Làm việc với Đối tác có buổi họp')=1,'a meeting date becomes one held milestone named after the partner');
select public.catalog_test_assert((select results from ai_management.collaboration_details where record_id='71000000-0000-4000-8000-000000000001')=E'Đã demo\n\nBước tiếp theo: Chọn PoC','the next step is appended to the results');
select public.catalog_test_assert(exists(select 1 from ai_management.audit where record_id='71000000-0000-4000-8000-000000000001' and action='drop_activity_meeting_fields' and before_value->>'last_meeting_date'='2026-08-24'),'the dropped values are snapshotted');
select public.catalog_test_assert(not exists(select 1 from information_schema.columns where table_schema='ai_management' and table_name='collaboration_details' and column_name in ('conclusion','next_notes','last_meeting_date')),'the three columns are gone');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert(not (public.ai_catalog_overview()->'activities'->0 ?| array['next_notes','last_meeting_date']),'the overview no longer lists the dropped fields');
select public.catalog_test_error($$select public.ai_catalog_save('{"kind":"collaboration","title":"x","status":"Đề xuất","data":{"item_group":"Dữ liệu, CSDL","next_notes":"y"}}')$$,'VALIDATION','an activity no longer accepts a next step');
select public.catalog_test_assert((public.ai_catalog_save('{"kind":"collaboration","title":"x","status":"Đề xuất","data":{"item_group":"Dữ liệu, CSDL","results":"y"}}')->>'id') is not null,'an activity still saves its results');
reset role;
