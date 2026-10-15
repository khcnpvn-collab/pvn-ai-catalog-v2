\set ON_ERROR_STOP on
select public.catalog_test_assert((select d.start_date from ai_management.work_item_details d join ai_management.records r on r.id=d.record_id where r.title='GPU dùng chung')=date '2026-11-01','an entered month becomes the first day of that month');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$ declare item jsonb; overview jsonb;
begin
 item:=public.ai_catalog_save('{"kind":"work_item","title":"Bắt đầu theo ngày","status":"Đang thực hiện","data":{"item_group":"Quản trị AI","start_date":"2026-12-15"}}');
 perform public.catalog_test_assert(item->'data'->>'start_date'='2026-12-15','a work item starts on a calendar date');
 perform public.catalog_test_error($q$select public.ai_catalog_save('{"kind":"work_item","title":"Ngày sai","status":"Đang thực hiện","data":{"item_group":"Quản trị AI","start_date":"2026-02-30"}}')$q$,'VALIDATION','an impossible date is rejected');
 overview:=public.ai_catalog_overview();
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(overview->'work_items') w where w->>'id'=item->>'id' and w->>'start_date'='2026-12-15'),'the overview carries the start date');
end $$;
reset role;
