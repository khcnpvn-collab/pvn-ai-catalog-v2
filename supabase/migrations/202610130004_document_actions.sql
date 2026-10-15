begin;

alter table ai_management.documents add column if not exists archived_at timestamptz;

create or replace function ai_management.can_read_document(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.documents d where d.id=p_id and d.archived_at is null and ai_management.current_role() is not null and (d.visibility='team' or d.created_by=auth.uid() or ai_management.current_role()='admin'))
$$;

create or replace function ai_management.document_json(p_id uuid,p_pin uuid default null) returns jsonb language sql stable security definer set search_path='' as $$
 select (to_jsonb(d)-'archived_at')||jsonb_build_object('versions',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'document_id',v.document_id,'version',v.version,'filename',v.filename,'mime_type',v.mime_type,'size_bytes',v.size_bytes,'created_at',v.created_at) order by version desc) from ai_management.document_versions v where v.document_id=d.id and (p_pin is null or v.id=p_pin)),'[]'::jsonb), 'linked_records',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'kind',r.kind)) from ai_management.document_links l join ai_management.records r on r.id=l.record_id where l.document_id=d.id and ai_management.can_read_record(r.id)),'[]'::jsonb))
 from ai_management.documents d where d.id=p_id and ai_management.can_read_document(d.id)
$$;

create function public.ai_catalog_document_unlink(p_record_id uuid,p_document_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform ai_management.require_role(true);
 if not ai_management.can_write_record(p_record_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if not exists(select 1 from ai_management.document_links where record_id=p_record_id and document_id=p_document_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 delete from ai_management.document_links where record_id=p_record_id and document_id=p_document_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value) values(p_record_id,auth.uid(),'document_unlink',jsonb_build_object('document_id',p_document_id));
 return true;
end $$;

create function public.ai_catalog_document_archive(p_document_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare previous ai_management.documents;
begin
 perform ai_management.require_role(true);
 select * into previous from ai_management.documents where id=p_document_id for update;
 if not found or previous.archived_at is not null then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if ai_management.current_role()<>'admin' and (previous.created_by<>auth.uid() or exists(select 1 from ai_management.document_links l where l.document_id=p_document_id and not ai_management.can_write_record(l.record_id))) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 update ai_management.documents set archived_at=now() where id=p_document_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value) values(null,auth.uid(),'document_archive',jsonb_build_object('document_id',p_document_id,'title',previous.title));
 return true;
end $$;

revoke all on function public.ai_catalog_document_unlink(uuid,uuid),public.ai_catalog_document_archive(uuid) from public,anon,authenticated;
grant execute on function public.ai_catalog_document_unlink(uuid,uuid),public.ai_catalog_document_archive(uuid) to authenticated;

commit;
