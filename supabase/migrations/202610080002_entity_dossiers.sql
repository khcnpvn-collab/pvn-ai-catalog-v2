-- Entity dossiers project existing relationships without changing source records.
create function public.ai_catalog_dossier(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare detail jsonb; related jsonb; attachments jsonb;
begin
 detail := public.ai_catalog_get(p_id);
 with direct as (
  select r.id, null::uuid via_id, l.relation,
   case when l.source_id=p_id then 'outgoing' else 'incoming' end direction, 1 depth
  from ai_management.relations l
  join ai_management.records r on r.id=case when l.source_id=p_id then l.target_id else l.source_id end
  where (l.source_id=p_id or l.target_id=p_id)
   and r.archived_at is null and ai_management.can_read_record(r.id)
 ), paths as (
  select * from direct
  union all
  select r.id, d.id, l.relation,
   case when l.source_id=d.id then 'outgoing' else 'incoming' end, 2
  from direct d
  join ai_management.records bridge on bridge.id=d.id
  join ai_management.relations l on l.source_id=d.id or l.target_id=d.id
  join ai_management.records r on r.id=case when l.source_id=d.id then l.target_id else l.source_id end
  where r.id<>p_id and r.archived_at is null and ai_management.can_read_record(r.id)
   -- Operational records provide context. Never expand through another entity.
   and (l.relation<>'related' or (bridge.kind='engagement' and r.kind='demand'))
   and case bridge.kind
    when 'demand' then r.kind='use_case' or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'implementation' then r.kind in ('use_case','partner','data_asset','poc') or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'poc' then r.kind in ('use_case','partner','data_asset','implementation') or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'collaboration' then r.kind in ('partner','use_case','collaboration_item','engagement','contact','data_asset') or (detail->'data'->>'kind' in ('partner','use_case') and r.kind='unit')
    when 'collaboration_item' then r.kind in ('collaboration','use_case','data_asset','partner')
    when 'engagement' then r.kind in ('contact','learning_session','resource','demand','use_case','data_asset')
    when 'learning_event' then detail->'data'->>'kind'='course' and r.kind in ('contact','learning_session','resource')
    when 'learning_session' then r.kind in ('contact','resource')
    else false end
 ), chosen as (
  select distinct on (id) * from paths order by id,depth,via_id,relation,direction
 )
 select coalesce(jsonb_agg(jsonb_build_object('record',ai_management.record_json(c.id),
  'via',case when c.via_id is null then null else ai_management.record_json(c.via_id) end,
  'relation',c.relation,'direction',c.direction) order by r.kind,r.title,r.id),'[]'::jsonb)
 into related from chosen c join ai_management.records r on r.id=c.id;
 -- Keep each record attachment distinct: the same document can be pinned to
 -- different versions in different engagements. Linking never grants read access.
 select coalesce(jsonb_agg(jsonb_build_object('record',entry->'record',
  'document',ai_management.document_json(l.document_id,l.version_id))
  order by entry->'record'->>'title',l.created_at,l.document_id),'[]'::jsonb)
 into attachments
 from jsonb_array_elements(related) entry
 join ai_management.document_links l on l.record_id=(entry->'record'->>'id')::uuid
 where entry->'record'->>'kind' not in ('unit','partner','use_case','course')
  and ai_management.can_read_document(l.document_id);
 return detail || jsonb_build_object('related',related,'attachments',attachments);
end $$;

create function public.ai_catalog_create_related(p_parent_id uuid,p_record jsonb,p_relation text,p_direction text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare parent ai_management.records; child jsonb; child_id uuid;
begin
 perform ai_management.require_role(true);
 -- Use the same lock order as relation mutations and lock the parent against archive.
 perform pg_advisory_xact_lock(73424910902411);
 select * into parent from ai_management.records where id=p_parent_id for update;
 if parent.id is null or not ai_management.can_read_record(p_parent_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_parent_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if parent.archived_at is not null then raise exception 'VALIDATION: archived record' using errcode='22023'; end if;
 if p_record is null or jsonb_typeof(p_record)<>'object' or p_record ? 'id'
  or p_direction is null or p_direction not in ('to-parent','from-parent') then
  raise exception 'VALIDATION: invalid contextual creation' using errcode='22023';
 end if;
 child := public.ai_catalog_save(p_record);
 child_id := (child->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object(
  'source_id',case when p_direction='to-parent' then child_id else p_parent_id end,
  'target_id',case when p_direction='to-parent' then p_parent_id else child_id end,
  'relation',p_relation));
 return child;
end $$;

revoke all on function public.ai_catalog_dossier(uuid) from public,anon;
revoke all on function public.ai_catalog_create_related(uuid,jsonb,text,text) from public,anon;
grant execute on function public.ai_catalog_dossier(uuid) to authenticated;
grant execute on function public.ai_catalog_create_related(uuid,jsonb,text,text) to authenticated;
