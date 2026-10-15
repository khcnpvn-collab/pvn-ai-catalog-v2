begin;

-- Restore the existing soft-deleted record without changing its ownership or links.
create function public.ai_catalog_restore(p_id uuid, p_version integer) returns boolean
language plpgsql security definer set search_path='' as $$
declare previous ai_management.records;
begin
 perform ai_management.require_role(true);
 select * into previous from ai_management.records where id=p_id for update;
 if not found or not ai_management.can_read_record(p_id) then
  raise exception 'NOT_FOUND' using errcode='P0002';
 end if;
 if not ai_management.can_write_record(p_id) then
  raise exception 'FORBIDDEN' using errcode='42501';
 end if;
 if previous.version is distinct from p_version then
  raise exception 'CONFLICT' using errcode='40001';
 end if;
 if previous.archived_at is null then
  raise exception 'VALIDATION: record is not deleted' using errcode='22023';
 end if;
 update ai_management.records
 set archived_at=null, updated_at=now(), version=version+1
 where id=p_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
 values(p_id,auth.uid(),'restore',to_jsonb(previous),ai_management.record_json(p_id));
 return true;
end $$;

revoke all on function public.ai_catalog_restore(uuid,integer) from public,anon;
grant execute on function public.ai_catalog_restore(uuid,integer) to authenticated;

commit;
