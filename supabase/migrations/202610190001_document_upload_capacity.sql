-- The current Supabase project is capped at 50 MiB globally. Prepare document
-- metadata for 100 MiB, while the app bucket remains within the live plan cap.
begin;

do $$
begin
 update storage.buckets set file_size_limit=52428800
 where id='ai-catalog-documents' and file_size_limit=20971520;
 if not found then raise exception 'ai-catalog-documents bucket is missing or its limit changed'; end if;
end $$;

alter table ai_management.document_versions drop constraint document_versions_size_bytes_check;
alter table ai_management.document_versions add constraint document_versions_size_bytes_check
 check(size_bytes between 1 and 104857600);

-- Match the app's supported extensions. All existing role, path, metadata,
-- attachment and audit checks remain in the gateway.
create or replace function public.ai_catalog_document_save(p_document jsonb) returns jsonb
language plpgsql security definer set search_path='' as $function$
declare did uuid; vid uuid; pathname text; doc ai_management.documents; next_version integer; object_meta jsonb;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_document,array['title','document_id','version_id','filename','mime_type','size_bytes','storage_path','checksum','record_id']);
 vid:=(p_document->>'version_id')::uuid; pathname:=p_document->>'storage_path';
 if vid is null or pathname is null or pathname !~ ('^'||auth.uid()::text||'/'||vid::text||'/file[.](pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|md|rtf|png|jpg|jpeg|gif|webp|zip|7z|rar)$') or (p_document->>'filename') ~ '[[:cntrl:]/\\]' or (p_document->>'filename') in ('.','..') then raise exception 'VALIDATION: invalid storage path' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('ai-catalog:'||pathname,0));
 select metadata into object_meta from storage.objects where bucket_id='ai-catalog-documents' and name=pathname;
 if not found then raise exception 'VALIDATION: file must be uploaded first' using errcode='22023'; end if;
 if object_meta ? 'size' and (object_meta->>'size')::bigint is distinct from (p_document->>'size_bytes')::bigint then raise exception 'VALIDATION: size mismatch' using errcode='22023'; end if;
 if p_document ? 'document_id' and p_document->>'document_id' is not null then
  did:=(p_document->>'document_id')::uuid;
  select * into doc from ai_management.documents where id=did for update;
  if not found or not ai_management.can_read_document(did) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 else
  insert into ai_management.documents(title,created_by) values(btrim(p_document->>'title'),auth.uid()) returning * into doc; did:=doc.id;
 end if;
 select coalesce(max(version),0)+1 into next_version from ai_management.document_versions where document_id=did;
 insert into ai_management.document_versions(id,document_id,version,filename,mime_type,size_bytes,storage_path,checksum,created_by) values(vid,did,next_version,p_document->>'filename',p_document->>'mime_type',(p_document->>'size_bytes')::bigint,pathname,p_document->>'checksum',auth.uid());
 if nullif(p_document->>'record_id','') is not null then perform public.ai_catalog_document_link((p_document->>'record_id')::uuid,did,vid); end if;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(null,auth.uid(),'document_version',jsonb_build_object('document_id',did,'version_id',vid,'version',next_version));
 return ai_management.document_json(did);
exception when unique_violation then raise exception 'CONFLICT: document version already registered' using errcode='40001';
 when check_violation or not_null_violation or invalid_text_representation or numeric_value_out_of_range then raise exception 'VALIDATION: invalid document metadata' using errcode='22023';
end $function$;

commit;
