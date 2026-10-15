\set ON_ERROR_STOP on
-- Isolated fixtures exercise explicit mappings; no live survey response is written.
begin;
reset role;
create temporary table unit_survey_test_state(name text primary key,id uuid);
grant select on unit_survey_test_state to authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
insert into unit_survey_test_state
select name,(public.ai_catalog_save(jsonb_build_object('kind',kind,'title',title,'code',code,'status','Chưa xác minh','visibility',visibility))->>'id')::uuid
from (values
 ('unit-a','unit','Same unit name','SURVEY-A','team'),
 ('unit-b','unit','Legacy mapped unit','SURVEY-B','team'),
 ('unit-c','unit','Survey-only mapped unit','SURVEY-C','team'),
 ('placeholder','unit','Same unit name','SURVEY-A','team'),
 ('private','unit','Private surveyed unit','SURVEY-PRIVATE','private'),
 ('other-kind','partner','Partner is not a unit','SURVEY-A','team'),
 ('null-code','unit','Null code mapped unit',null,'team')) f(name,kind,title,code,visibility);
-- Seed immutable snapshots with controlled timestamps to distinguish answer date from import date.
insert into ai_management.sources(source_key,source_type,title,unit_code,payload,created_by,created_at)
select key,type,'Same unit name',unit_code,payload::jsonb,'10000000-0000-4000-8000-000000000001',created_at::timestamptz
from (values
 ('lookup:catalog-a','unit_catalog','SURVEY-A','{"name":"Same unit name"}','2026-10-08T00:00:00Z'),
 ('lookup:a-old','survey','SURVEY-A','{"answers":{"marker":"a-old","zero":0,"flag":false},"status":"submitted","updated_at":"2026-08-01T00:00:00Z","schema_version":1,"user_id":"never-expose-top-level-id","email":"never-expose-top-level-email"}','2026-10-07T00:00:00Z'),
 ('lookup:a-new','survey','SURVEY-A','{"answers":{"marker":"a-new","nested":{"items":["unchanged"]}},"status":"submitted","updated_at":"2026-10-01T00:00:00Z","schema_version":2}','2026-10-06T00:00:00Z'),
 ('lookup:a-granular','survey_use_case','SURVEY-A','{"answers":{"marker":"granular-not-full"}}','2026-10-08T00:00:00Z'),
 ('lookup:b','survey','SURVEY-B','{"answers":{"marker":"b"},"status":"submitted"}','2026-10-03T00:00:00Z'),
 ('lookup:b-new','survey','SURVEY-B','{"answers":{"marker":"b-new"},"status":"draft","updated_at":"2026-10-04T00:00:00Z"}','2026-10-02T00:00:00Z'),
 ('lookup:c','survey','SURVEY-C','{"answers":{"marker":"c"},"status":"submitted"}','2026-10-02T00:00:00Z'),
 ('lookup:c-new','survey','SURVEY-C','{"answers":{"marker":"c-new"},"status":"draft"}','2026-10-05T00:00:00Z'),
 ('lookup:similar-code','survey','survey-a','{"answers":{"marker":"wrong-case-code"}}','2026-10-08T00:00:00Z'),
 ('lookup:unrelated','manual','SURVEY-A','{"answers":{"marker":"manual-not-survey"}}','2026-10-08T00:00:00Z'),
 ('lookup:private','survey','SURVEY-PRIVATE','{"answers":{"marker":"private"}}','2026-10-08T00:00:00Z'),
 ('lookup:null','survey',null,'{"answers":{"marker":"null-code-explicit"}}','2026-10-08T00:00:00Z'),
 ('lookup:null-unmapped','survey',null,'{"answers":{"marker":"null-code-unmapped"}}','2026-10-08T00:00:00Z')) f(key,type,unit_code,payload,created_at);
insert into ai_management.source_links(source_id,record_id,created_by)
select s.id,r.id,'10000000-0000-4000-8000-000000000001'
from (values ('lookup:catalog-a','unit-a'),('lookup:a-old','unit-a'),('lookup:c','unit-c'),('lookup:private','private'),('lookup:null','null-code'),
 -- Deliberately inconsistent secondary source: catalog mapping remains authoritative.
 ('lookup:b','unit-a')) mapping(source_key,record_name)
join ai_management.sources s on s.source_key=mapping.source_key
join unit_survey_test_state r on r.name=mapping.record_name;
update ai_management.sources set linked_record_id=(select id from unit_survey_test_state where name='unit-b') where source_key='lookup:b';
create temporary table unit_survey_test_before as select id,payload from ai_management.sources where source_key like 'lookup:%';
set role anon;
select public.catalog_test_error('select public.ai_catalog_unit_survey(gen_random_uuid())','permission denied','anonymous cannot execute unit survey lookup');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare result jsonb; unit_id uuid;
begin
 select id into unit_id from unit_survey_test_state where name='unit-a';
 result:=public.ai_catalog_unit_survey(unit_id);
 perform public.catalog_test_assert(jsonb_array_length(result)=2,'unit lookup includes only full survey snapshots of its authoritative mapped code');
 perform public.catalog_test_assert(result->0->'payload'->'answers'->>'marker'='a-new' and result->1->'payload'->'answers'->>'marker'='a-old','survey versions sorted by answer updated date rather than import date');
 perform public.catalog_test_assert(result->0->'payload'->'answers'='{"marker":"a-new","nested":{"items":["unchanged"]}}'::jsonb and result->1->'payload'->'answers'->'zero'='0'::jsonb and result->1->'payload'->'answers'->'flag'='false'::jsonb,'lookup preserves nested answers zero and false');
 perform public.catalog_test_assert(result->1->'payload'->>'status'='submitted' and result->1->'payload'->>'schema_version'='1','lookup includes original response status and schema version');
 perform public.catalog_test_assert(not(result->1->'payload' ? 'user_id') and not(result->1->'payload' ? 'email') and not(result->1 ? 'source_key') and not(result->1 ? 'created_by'),'lookup omits unrelated top-level source and response metadata');
 perform public.catalog_test_assert(result::text not like '%wrong-case-code%' and result::text not like '%granular-not-full%' and result::text not like '%manual-not-survey%' and result::text not like '%"b"%','catalog mapping rejects wrong-unit mappings case mismatches and non-full sources');
 select id into unit_id from unit_survey_test_state where name='unit-b';
 result:=public.ai_catalog_unit_survey(unit_id);
 perform public.catalog_test_assert(jsonb_array_length(result)=2 and result->0->'payload'->'answers'->>'marker'='b-new','legacy linked_record_id maps unit and expands exact-code full versions');
 perform public.catalog_test_assert(result->0->'payload'->>'status'='draft','immutable draft version remains available without publishing normalized facts');
 select id into unit_id from unit_survey_test_state where name='unit-c';
 result:=public.ai_catalog_unit_survey(unit_id);
 perform public.catalog_test_assert(jsonb_array_length(result)=2 and result->0->'payload'->'answers'->>'marker'='c-new','explicit full-source mapping works without catalog mapping and falls back to import-date order');
 select id into unit_id from unit_survey_test_state where name='placeholder';
 perform public.catalog_test_assert(public.ai_catalog_unit_survey(unit_id)='[]'::jsonb,'unmapped placeholder never guesses survey by matching record title or code');
 select id into unit_id from unit_survey_test_state where name='null-code';
 result:=public.ai_catalog_unit_survey(unit_id);
 perform public.catalog_test_assert(jsonb_array_length(result)=1 and result->0->'payload'->'answers'->>'marker'='null-code-explicit','null-code source requires explicit mapping and does not collect other null-code sources');
 select id into unit_id from unit_survey_test_state where name='private';
 perform public.catalog_test_assert(jsonb_array_length(public.ai_catalog_unit_survey(unit_id))=1,'admin can read permitted private unit survey');
 select id into unit_id from unit_survey_test_state where name='other-kind';
 perform public.catalog_test_error(format('select public.ai_catalog_unit_survey(%L)',unit_id),'VALIDATION: expected unit dossier','survey endpoint rejects non-unit dossier');
 perform public.catalog_test_error(format('select public.ai_catalog_unit_survey(%L)',gen_random_uuid()),'NOT_FOUND','survey endpoint rejects missing unit');
 perform public.catalog_test_error('select public.ai_catalog_unit_survey(null)','NOT_FOUND','survey endpoint rejects null unit');
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_error(format('select public.ai_catalog_unit_survey(%L)',id),'FORBIDDEN','editor denied raw survey lookup for '||name) from unit_survey_test_state where name in ('unit-a','private');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.catalog_test_error(format('select public.ai_catalog_unit_survey(%L)',id),'FORBIDDEN','reader denied raw survey lookup for '||name) from unit_survey_test_state where name in ('unit-a','private');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
select public.catalog_test_error(format('select public.ai_catalog_unit_survey(%L)',id),'FORBIDDEN','nonmember denied unit survey lookup') from unit_survey_test_state where name='unit-a';
reset role;
select public.catalog_test_assert(not exists(select 1 from unit_survey_test_before b join ai_management.sources s using(id) where s.payload is distinct from b.payload),'survey lookup leaves every immutable source answer unchanged');
rollback;
