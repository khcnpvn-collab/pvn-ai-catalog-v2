\set ON_ERROR_STOP on
create function pg_temp.moved() returns uuid language sql as $$ select id from ai_management.records where kind='collaboration' and title='Hội thảo chuyển đổi' $$;
select public.catalog_test_assert(pg_temp.moved() is not null,'the workshop becomes an activity');
select public.catalog_test_assert((select r.status||' | '||d.item_group||' | '||d.item_category from ai_management.records r join ai_management.collaboration_details d on d.record_id=r.id where r.id=pg_temp.moved())='Hoàn thành | Nhân lực, đào tạo | Hội thảo, chia sẻ kinh nghiệm','a held workshop is a finished people and training activity');
select public.catalog_test_assert((select d.scope from ai_management.collaboration_details d where d.record_id=pg_temp.moved()) like '%Địa điểm: 18 Láng Hạ%Số người tham dự: 150%','the workshop details move into the scope');
select public.catalog_test_assert((select d.start_date from ai_management.collaboration_details d where d.record_id=pg_temp.moved())=date '2026-03-26','the workshop dates move');
select public.catalog_test_assert(exists(select 1 from ai_management.relations l join ai_management.records w on w.id=l.target_id where l.source_id=pg_temp.moved() and l.relation='use_case' and w.title='Hội thảo chia sẻ kinh nghiệm'),'the activity is linked to the matching work item');
select public.catalog_test_assert(exists(select 1 from ai_management.relations l join ai_management.records e on e.id=l.target_id where l.source_id=pg_temp.moved() and l.relation='expert' and e.title='Diễn giả hội thảo'),'speakers follow as experts');
select public.catalog_test_assert(exists(select 1 from ai_management.relations l join ai_management.records u on u.id=l.target_id where l.source_id=pg_temp.moved() and l.relation='unit' and u.title='Đơn vị tổ chức hội thảo'),'organising units follow as PVN subjects');
select public.catalog_test_assert(not exists(select 1 from ai_management.module_registry where kind='learning_event') and not exists(select 1 from information_schema.tables where table_schema='ai_management' and table_name='learning_event_details'),'the training kind is gone');
select public.catalog_test_assert(exists(select 1 from ai_management.audit where action='convert_event_to_activity' and before_value->'record'->>'title'='Hội thảo chuyển đổi'),'the workshop is snapshotted');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert(not (public.ai_catalog_overview() ? 'events') and jsonb_array_length(public.ai_catalog_overview()->'activities')>0,'the overview drops events and still loads');
reset role;
