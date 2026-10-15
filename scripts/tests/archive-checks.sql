\set ON_ERROR_STOP on
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into public.catalog_test_state values('archive_relation_source',public.ai_catalog_save('{"kind":"use_case","title":"Archive relation fixture","status":"Chưa xác minh","visibility":"team"}'));
insert into public.catalog_test_state select 'archive_relation',public.ai_catalog_link(jsonb_build_object('source_id',s.value->>'id','target_id',t.value->>'id','relation','related')) from public.catalog_test_state s,public.catalog_test_state t where s.name='archive_relation_source' and t.name='team';
select public.catalog_test_assert(public.ai_catalog_archive((value->>'id')::uuid,1),'archive relation source') from public.catalog_test_state where name='archive_relation_source';
select public.catalog_test_error(format('select public.ai_catalog_unlink(%L)',value->>'id'),'VALIDATION: archived record','cannot unlink from archived source record') from public.catalog_test_state where name='archive_relation';
select public.catalog_test_assert(jsonb_array_length(public.ai_catalog_get((value->>'id')::uuid)->'links')=1,'archived record retains relation after rejected unlink') from public.catalog_test_state where name='archive_relation_source';
reset role;
