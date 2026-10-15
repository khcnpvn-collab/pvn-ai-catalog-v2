\set ON_ERROR_STOP on
-- Run only in the disposable test cluster; all folder fixtures roll back.
begin;
reset role;
create function public.record_files_test_input(k text, label text, visibility text default 'team') returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('kind',k,'title',label,'status',statuses[1],'visibility',visibility,'data','{}'::jsonb)
 from ai_management.module_registry where kind=k
$$;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$
declare
 parent jsonb; folder jsonb; renamed jsonb; payload jsonb; detail jsonb; k text; relation_name text;
 private_parent uuid; team_parent uuid; folder_id uuid; doc_id uuid;
begin
 foreach k in array array['unit','partner','expert','use_case','engagement','affiliation','expertise'] loop
  parent:=public.ai_catalog_save(public.record_files_test_input(k,'Folder owner '||k));
  relation_name:=case when k='expert' then 'expert' else 'related' end;
  payload:=public.record_files_test_input('reference','Folder '||k)||'{"data":{"reference_type":"Thư mục"}}'::jsonb;
  folder:=public.ai_catalog_create_related((parent->>'id')::uuid,payload,relation_name,'to-parent');
  detail:=public.ai_catalog_dossier((parent->>'id')::uuid);
  perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(detail->'related') e where e->'record'->>'id'=folder->>'id' and e->'via'='null'::jsonb), 'direct folder visible on '||k||' dossier');
 end loop;
 team_parent:=(parent->>'id')::uuid;
 private_parent:=(public.ai_catalog_save(public.record_files_test_input('expert','Private folder owner','private'))->>'id')::uuid;
 payload:=public.record_files_test_input('reference','Private folder','private')||'{"code":"FOLDER-CODE","summary":"Original summary","source_note":"Original source","observed_on":"2026-10-01","data":{"reference_type":"CV","external_url":"https://example.test/cv.pdf","notes":"Original notes"}}'::jsonb;
 folder:=public.ai_catalog_create_related(private_parent,payload,'expert','to-parent');
 folder_id:=(folder->>'id')::uuid;
 perform public.catalog_test_assert(folder->>'visibility'='private','folder create keeps explicit private visibility');
 payload:=payload||jsonb_build_object('id',folder_id,'version',1,'title','Renamed shared folder');
 renamed:=public.ai_catalog_save(payload);
 perform public.catalog_test_assert(renamed->'data'=folder->'data' and renamed->>'source_note'=folder->>'source_note' and renamed->>'code'=folder->>'code' and renamed->>'summary'=folder->>'summary' and renamed->>'observed_on'=folder->>'observed_on' and renamed->>'visibility'='private','folder rename preserves metadata source URL and privacy');
 perform public.catalog_test_assert((renamed->>'version')::int=2,'folder rename advances optimistic version');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L::jsonb)',payload::text),'CONFLICT','stale folder rename rejected');
 select (value->>'id')::uuid into doc_id from public.catalog_test_state where name='doc';
 perform public.ai_catalog_document_link(private_parent,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_document_link(folder_id,doc_id,'20000000-0000-4000-8000-000000000002');
 detail:=public.ai_catalog_dossier(private_parent);
 perform public.catalog_test_assert(detail->'documents'->0->'versions'->0->>'id'='20000000-0000-4000-8000-000000000001','root file keeps original version pin');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(detail->'attachments') e where e->'record'->>'id'=folder_id::text and e->'document'->'versions'->0->>'id'='20000000-0000-4000-8000-000000000002'),'folder file keeps independent version pin');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L::uuid,%L::jsonb,''related'',''to-parent'')',team_parent,public.record_files_test_input('reference','Reader folder')::text),'FORBIDDEN','reader cannot create folder');
 perform public.catalog_test_error(format('select public.ai_catalog_get(%L::uuid)',folder_id),'NOT_FOUND','private folder hidden from other member');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
 private_parent:=(public.ai_catalog_save(public.record_files_test_input('unit','Other private owner','private'))->>'id')::uuid;
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L::uuid,%L::jsonb,''related'',''to-parent'')',private_parent,public.record_files_test_input('reference','Foreign folder')::text),'NOT_FOUND','editor cannot create folder under other private parent');
 perform public.ai_catalog_archive(team_parent,1);
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L::uuid,%L::jsonb,''related'',''to-parent'')',team_parent,public.record_files_test_input('reference','Archived owner folder')::text),'archived record','archived parent rejects folder creation');
end $$;
reset role;
rollback;
