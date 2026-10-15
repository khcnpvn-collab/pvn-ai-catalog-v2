begin;

-- Create a related record and its contextual relation atomically. The original
-- four-argument gateway remains available for older clients.
create function public.ai_catalog_create_related_context(
  p_parent_id uuid,
  p_record jsonb,
  p_relation text,
  p_direction text,
  p_context jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare parent ai_management.records; child jsonb; child_id uuid;
declare consortium_id uuid;
begin
 perform ai_management.require_role(true);
 perform pg_advisory_xact_lock(73424910902411);
 select * into parent from ai_management.records where id=p_parent_id for update;
 if parent.id is null or not ai_management.can_read_record(p_parent_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_parent_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if parent.archived_at is not null then raise exception 'VALIDATION: archived record' using errcode='22023'; end if;
 if p_record is null or jsonb_typeof(p_record)<>'object' or p_record ? 'id'
  or p_direction is null or p_direction not in ('to-parent','from-parent')
  or p_context is null or jsonb_typeof(p_context)<>'object' then
  raise exception 'VALIDATION: invalid contextual creation' using errcode='22023';
 end if;
 if p_record->>'kind'='collaboration' and not (parent.kind='partner' and p_relation='partner' and p_direction='to-parent') then
  raise exception 'VALIDATION: cooperation content requires partner context' using errcode='22023';
 end if;
 child := public.ai_catalog_save(p_record);
 child_id := (child->>'id')::uuid;
 consortium_id := case when p_direction='to-parent' then child_id else p_parent_id end;
 if p_context ? 'consortium_role' then
  if p_relation<>'partner' or p_context->>'consortium_role' not in ('lead','member')
   or (select kind from ai_management.records where id=consortium_id)<>'partner'
   or (select kind from ai_management.records where id=case when p_direction='to-parent' then p_parent_id else child_id end)<>'partner' then
   raise exception 'VALIDATION: invalid consortium relation' using errcode='22023';
  end if;
  if p_context->>'consortium_role'='lead' then
   update ai_management.relations set context=(context - 'Vai trò' - 'role') || jsonb_build_object('consortium_role','member')
   where source_id=consortium_id and relation='partner'
    and coalesce(context->>'consortium_role',context->>'role',context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh');
  end if;
 end if;
 perform public.ai_catalog_link(jsonb_build_object(
  'source_id',consortium_id,
  'target_id',case when p_direction='to-parent' then p_parent_id else child_id end,
  'relation',p_relation,
  'context',p_context));
 return child;
end $$;

create function public.ai_catalog_consortium_link(p_link jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare source_record ai_management.records; target_record ai_management.records; role text;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_link,array['source_id','target_id','relation','note','context']);
 perform pg_advisory_xact_lock(73424910902411);
 select * into source_record from ai_management.records where id=(p_link->>'source_id')::uuid for update;
 select * into target_record from ai_management.records where id=(p_link->>'target_id')::uuid;
 role := p_link->'context'->>'consortium_role';
 if source_record.id is null or target_record.id is null or not ai_management.can_read_record(source_record.id) or not ai_management.can_read_record(target_record.id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(source_record.id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if source_record.kind<>'partner' or target_record.kind<>'partner' or p_link->>'relation'<>'partner' or role not in ('lead','member') then raise exception 'VALIDATION: invalid consortium relation' using errcode='22023'; end if;
 if role='lead' then
  update ai_management.relations set context=(context - 'Vai trò' - 'role') || jsonb_build_object('consortium_role','member')
  where source_id=source_record.id and relation='partner'
   and coalesce(context->>'consortium_role',context->>'role',context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh');
 end if;
 return public.ai_catalog_link(p_link);
end $$;

revoke all on function public.ai_catalog_create_related_context(uuid,jsonb,text,text,jsonb) from public,anon;
revoke all on function public.ai_catalog_consortium_link(jsonb) from public,anon;
grant execute on function public.ai_catalog_create_related_context(uuid,jsonb,text,text,jsonb),public.ai_catalog_consortium_link(jsonb) to authenticated;

commit;
