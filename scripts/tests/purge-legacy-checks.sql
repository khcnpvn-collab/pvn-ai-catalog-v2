\set ON_ERROR_STOP on
select public.catalog_test_assert(not exists(select 1 from ai_management.records where archived_at is not null),'archived records are purged');
select public.catalog_test_assert(not exists(select 1 from ai_management.records r join public.purge_fixture f on f.id=r.id),'legacy and archived fixtures are gone');
select public.catalog_test_assert((select count(*) from ai_management.audit a join public.purge_fixture f on f.id=a.record_id where a.action='purge_record')=2,'each purged record has one snapshot');
select public.catalog_test_assert((select before_value->'data'->>'owner' from ai_management.audit a join public.purge_fixture f on f.id=a.record_id where a.action='purge_record' and f.title='CSDL cũ cần dọn')='Ban dữ liệu','the snapshot keeps the record fields');
select public.catalog_test_assert((select jsonb_array_length(before_value->'relations') from ai_management.audit a join public.purge_fixture f on f.id=a.record_id where a.action='purge_record' and f.title='Hoạt động đã gỡ cần dọn')=1,'the snapshot keeps the record links');
select public.catalog_test_assert((select jsonb_array_length(before_value->'source_ids') from ai_management.audit a join public.purge_fixture f on f.id=a.record_id where a.action='purge_record' and f.title='CSDL cũ cần dọn')=1,'the snapshot keeps the source references');
select public.catalog_test_assert(exists(select 1 from ai_management.audit a join public.purge_fixture f on f.id=a.record_id where a.action<>'purge_record'),'earlier history of purged records is kept');
select public.catalog_test_assert((select linked_record_id is null from ai_management.sources where source_key='purge-legacy-fixture'),'the source snapshot stays, without its pointer');
select public.catalog_test_assert(not exists(select 1 from ai_management.source_links l join public.purge_fixture f on f.id=l.record_id),'source links to purged records are removed');
select public.catalog_test_assert(exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id where a.title='Hoạt động giữ lại khi dọn'),'kept records keep their links');
select public.catalog_test_assert(not exists(select 1 from information_schema.tables where table_schema='ai_management' and table_name in
 ('affiliation_details','expertise_details','data_asset_details','implementation_details','demand_details','poc_details','course_details','learning_session_details','resource_details','collaboration_item_details')),'legacy detail tables are dropped');
select public.catalog_test_assert((select count(*) from ai_management.module_registry)=9,'only the nine kinds in use remain registered');
select public.catalog_test_assert(not exists(select 1 from pg_proc where proname in ('ai_catalog_sources','ai_catalog_source_save','ai_catalog_source_link','ai_catalog_partner_review')),'retired gateways are dropped');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert(jsonb_array_length(public.ai_catalog_overview()->'activities')>0,'the overview still loads');
select public.catalog_test_error($$select public.ai_catalog_save('{"kind":"data_asset","title":"Không tạo được","status":"Chưa xác minh","visibility":"team","data":{}}')$$,'','legacy kinds can no longer be saved');
reset role;
drop table public.purge_fixture;
