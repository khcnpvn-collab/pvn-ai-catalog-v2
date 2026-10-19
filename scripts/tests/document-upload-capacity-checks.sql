\set ON_ERROR_STOP on
select public.catalog_test_assert((select file_size_limit from storage.buckets where id='ai-catalog-documents')=52428800,'app bucket accepts 50 MiB on the current plan');
select public.catalog_test_assert((select pg_get_constraintdef(oid) like '%104857600%' from pg_constraint where conrelid='ai_management.document_versions'::regclass and conname='document_versions_size_bytes_check'),'document metadata is prepared for 100 MiB');

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into storage.objects(bucket_id,name,metadata) values('ai-catalog-documents','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000100/file.zip','{"size":52428800}');
select public.catalog_test_assert((public.ai_catalog_document_save(jsonb_build_object('title','Tệp ZIP','version_id','20000000-0000-4000-8000-000000000100','filename','Tài liệu.ZIP','mime_type','application/zip','size_bytes',52428800,'storage_path','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000100/file.zip','checksum',repeat('a',64)))->'versions'->0->>'size_bytes')::bigint=52428800,'ZIP at current bucket limit registers through the document gateway');
insert into storage.objects(bucket_id,name,metadata) values('ai-catalog-documents','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000101/file.zip','{"size":104857600}');
select public.catalog_test_assert((public.ai_catalog_document_save(jsonb_build_object('title','Tệp sẵn sàng 100 MiB','version_id','20000000-0000-4000-8000-000000000101','filename','Tài liệu.zip','mime_type','application/zip','size_bytes',104857600,'storage_path','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000101/file.zip','checksum',repeat('b',64)))->'versions'->0->>'size_bytes')::bigint=104857600,'database metadata accepts 100 MiB once the paid storage cap is raised');
insert into storage.objects(bucket_id,name,metadata) values('ai-catalog-documents','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000102/file.zip','{"size":104857601}');
select public.catalog_test_error('select public.ai_catalog_document_save(''{"title":"Quá giới hạn","version_id":"20000000-0000-4000-8000-000000000102","filename":"Tài liệu.zip","mime_type":"application/zip","size_bytes":104857601,"storage_path":"10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000102/file.zip","checksum":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}'')','VALIDATION: invalid document metadata','database rejects document metadata above 100 MiB');
select public.catalog_test_error('select public.ai_catalog_document_save(''{"title":"Không cho EXE","version_id":"20000000-0000-4000-8000-000000000103","filename":"Ứng dụng.exe","mime_type":"application/octet-stream","size_bytes":1,"storage_path":"10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000103/file.exe","checksum":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}'')','VALIDATION: invalid storage path','gateway still rejects executable extensions');
do $test$
begin
 begin
  perform public.ai_catalog_document_save(jsonb_build_object('title','Tên sai','version_id','20000000-0000-4000-8000-000000000104','filename','bad'||chr(92)||'file.zip','mime_type','application/zip','size_bytes',1,'storage_path','10000000-0000-4000-8000-000000000002/20000000-0000-4000-8000-000000000104/file.zip','checksum',repeat('c',64)));
  raise exception 'filename with backslash was accepted';
 exception when sqlstate '22023' then
  if sqlerrm <> 'VALIDATION: invalid storage path' then raise; end if;
  raise notice 'PASS: gateway still rejects backslashes in filenames';
 end;
end $test$;
reset role;
