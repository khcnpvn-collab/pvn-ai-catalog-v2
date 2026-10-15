begin;

create or replace function public.ai_catalog_document_unlink(p_record_id uuid,p_document_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform ai_management.require_role(true);
 if not exists(select 1 from ai_management.records where id=p_record_id and archived_at is null) or not ai_management.can_write_record(p_record_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if not exists(select 1 from ai_management.document_links where record_id=p_record_id and document_id=p_document_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 delete from ai_management.document_links where record_id=p_record_id and document_id=p_document_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value) values(p_record_id,auth.uid(),'document_unlink',jsonb_build_object('document_id',p_document_id));
 return true;
end $$;

create or replace function public.ai_catalog_document_archive(p_document_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare previous ai_management.documents;
begin
 perform ai_management.require_role(true);
 select * into previous from ai_management.documents where id=p_document_id for update;
 if not found or previous.archived_at is not null then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if exists(select 1 from ai_management.document_links l join ai_management.records r on r.id=l.record_id where l.document_id=p_document_id and r.archived_at is not null) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if ai_management.current_role()<>'admin' and (previous.created_by<>auth.uid() or exists(select 1 from ai_management.document_links l where l.document_id=p_document_id and not ai_management.can_write_record(l.record_id))) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 update ai_management.documents set archived_at=now() where id=p_document_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value) values(null,auth.uid(),'document_archive',jsonb_build_object('document_id',p_document_id,'title',previous.title));
 return true;
end $$;

commit;
