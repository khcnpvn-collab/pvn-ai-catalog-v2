-- A PVN unit can carry out an activity for another unit, in the place of an external partner.
-- The activity keeps a single executing party: one partner, one consortium or one unit, linked
-- with the existing "partner" relation. Units never appear in the partner catalogue or counts:
-- the overview reports them as provider_unit_id. Partner records that duplicate a unit are folded
-- into that unit and archived with an audit entry.
begin;

create or replace function public.ai_catalog_link(p_link jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare s ai_management.records; t ai_management.records; rel text; ctx jsonb; item record; result ai_management.relations;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_link,array['source_id','target_id','relation','note','context']);
 -- Serialize parent mutations so two concurrent inserts cannot create a cycle.
 perform pg_advisory_xact_lock(73424910902411);
 select * into s from ai_management.records where id=(p_link->>'source_id')::uuid;
 select * into t from ai_management.records where id=(p_link->>'target_id')::uuid;
 if s.id is null or t.id is null or not ai_management.can_read_record(s.id) or not ai_management.can_read_record(t.id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(s.id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if s.archived_at is not null or t.archived_at is not null or s.id=t.id then raise exception 'VALIDATION: invalid relation endpoints' using errcode='22023'; end if;
 rel:=p_link->>'relation'; ctx:=coalesce(p_link->'context','{}'::jsonb);
 if jsonb_typeof(ctx)<>'object' or octet_length(ctx::text)>16000 then raise exception 'VALIDATION: invalid context' using errcode='22023'; end if;
 for item in select key,value from jsonb_each(ctx) loop
  if length(item.key)>80 or jsonb_typeof(item.value)<>'string' or length(item.value#>>'{}')>1000 then raise exception 'VALIDATION: invalid context value' using errcode='22023'; end if;
 end loop;
 if not (case rel
  when 'related' then true
  when 'parent' then (s.kind=t.kind and s.kind in ('use_case','unit')) or (s.kind='collaboration_item' and t.kind='collaboration') or (s.kind='learning_session' and t.kind in ('learning_event','engagement')) or (s.kind='learning_event' and t.kind='course')
  when 'unit' then t.kind='unit'
  when 'partner' then t.kind='partner' or (t.kind='unit' and s.kind='collaboration')
  when 'contact' then t.kind='contact'
  when 'expert' then t.kind='expert' and s.kind in ('partner','unit','use_case','collaboration','collaboration_item','engagement','affiliation','expertise','reference','learning_event','course','learning_session')
  when 'use_case' then t.kind='use_case'
  when 'data' then t.kind='data_asset'
  when 'collaboration' then t.kind='collaboration'
  when 'course' then t.kind='course' and s.kind in ('learning_event','learning_session','resource','collaboration_item','contact')
  when 'event' then t.kind in ('learning_event','engagement') and s.kind in ('learning_session','contact','resource','unit','partner')
  when 'speaker' then t.kind in ('contact','expert') and s.kind in ('course','learning_event','learning_session','engagement')
  when 'participant' then t.kind in ('contact','expert') and s.kind in ('learning_event','learning_session','engagement')
  when 'organizer' then t.kind in ('unit','partner') and s.kind in ('course','learning_event','learning_session','engagement')
  when 'resource' then t.kind='resource'
  else false end) then raise exception 'VALIDATION: incompatible relation kinds' using errcode='22023'; end if;
 -- Competencies and employment records describe one person; events and references may involve many.
 if rel='expert' and s.kind in ('expertise','affiliation') and exists(
  select 1 from ai_management.relations r where r.source_id=s.id and r.relation='expert' and r.target_id<>t.id
 ) then raise exception 'VALIDATION: record already assigned to another expert' using errcode='22023'; end if;
 if rel='parent' and exists(with recursive ancestors(id) as (select t.id union select r.target_id from ai_management.relations r join ancestors a on r.source_id=a.id where r.relation='parent') select 1 from ancestors where id=s.id) then raise exception 'VALIDATION: parent cycle' using errcode='22023'; end if;
 insert into ai_management.relations(source_id,target_id,relation,note,context,created_by) values(s.id,t.id,rel,nullif(p_link->>'note',''),ctx,auth.uid()) returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(s.id,auth.uid(),'link',to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when unique_violation then raise exception 'CONFLICT: relation already exists or parent already assigned' using errcode='40001';
 when check_violation or invalid_text_representation or not_null_violation then raise exception 'VALIDATION: invalid relation' using errcode='22023';
end $$;

create or replace function public.ai_catalog_overview() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with v as (
  select r.id,r.kind,r.title,r.code,r.status,r.updated_at from ai_management.records r
  where r.archived_at is null and r.kind in ('use_case','collaboration','partner','unit','expert','learning_event','engagement')
   and ai_management.can_read_record(r.id)
 ), l as (
  select x.source_id,x.target_id,x.relation,x.context,t.kind target_kind,s.kind source_kind from ai_management.relations x
  join v s on s.id=x.source_id join v t on t.id=x.target_id
 )
 select jsonb_build_object(
  'standards',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'code',v.code,'status',v.status,'updated_at',v.updated_at,
    'program',d.program,'category',d.category,'is_priority',d.is_priority,'leadership_level',d.leadership_level,'start_year',d.start_year,
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'potential_unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit' and coalesce(l.context->>'subject_role','')<>'lead'),
    'potential_partner_ids',(select coalesce(jsonb_agg(l.source_id),'[]'::jsonb) from l where l.target_id=v.id and l.relation='use_case' and l.source_kind='partner')
   ) order by v.code,v.title),'[]'::jsonb) from v join ai_management.use_case_details d on d.record_id=v.id),
  'activities',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'type',d.cooperation_types,'start_date',d.start_date,'end_date',d.end_date,
    'partner_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'provider_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='unit' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' limit 1),
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by v.updated_at desc,v.id),'[]'::jsonb) from v join ai_management.collaboration_details d on d.record_id=v.id),
  'partners',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'short_name',d.short_name,'partner_type',d.partner_type,'country',d.country,
    'member_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.partner_details d on d.record_id=v.id),
  'units',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'updated_at',v.updated_at,
    'abbreviation',d.abbreviation,'sector',d.sector,
    'parent_id',(select l.target_id from l where l.source_id=v.id and l.relation='parent' limit 1)
   ) order by v.title),'[]'::jsonb) from v join ai_management.unit_details d on d.record_id=v.id),
  'milestones',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'start_date',d.start_date,'end_date',d.end_date,'period_label',d.period_label,
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner'),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'activity_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='collaboration')
   ) order by d.start_date desc nulls last,v.updated_at desc),'[]'::jsonb) from v join ai_management.engagement_details d on d.record_id=v.id),
  'experts',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'organization',d.organization,'current_position',d.current_position,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.expert_details d on d.record_id=v.id),
  'events',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'event_type',d.event_type,'start_date',d.start_date,'end_date',d.end_date,'audience',d.audience,
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='organizer' and l.target_kind='partner'),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='organizer' and l.target_kind='unit'),
    'expert_ids',(select coalesce(jsonb_agg(distinct l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation in ('speaker','participant') and l.target_kind='expert')
   ) order by d.start_date desc nulls last,v.updated_at desc),'[]'::jsonb) from v join ai_management.learning_event_details d on d.record_id=v.id)
 ) into result;
 return result;
end $$;

create temporary table unit_partner on commit drop as
select p.id partner_id, (array_agg(u.id))[1] unit_id
from ai_management.records p
join ai_management.records u on u.kind='unit' and u.archived_at is null
join ai_management.unit_details ud on ud.record_id=u.id
where p.kind='partner' and p.archived_at is null
 and (lower(btrim(p.title))=lower(btrim(u.title)) or lower(btrim(p.title))=lower(btrim(coalesce(ud.abbreviation,''))))
group by p.id having count(*)=1;
create temporary table unit_partner_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select l.source_id,(select user_id from unit_partner_actor),'replace_partner_with_unit',to_jsonb(l),jsonb_build_object('target_id',m.unit_id)
from ai_management.relations l join unit_partner m on m.partner_id=l.target_id join ai_management.records s on s.id=l.source_id
where l.relation='partner' and s.kind='collaboration';
update ai_management.relations l set target_id=m.unit_id
from unit_partner m, ai_management.records s
where l.target_id=m.partner_id and l.relation='partner' and s.id=l.source_id and s.kind='collaboration'
 and not exists(select 1 from ai_management.relations x where x.source_id=l.source_id and x.target_id=m.unit_id and x.relation='partner');

insert into ai_management.audit(record_id,actor_id,action,after_value)
select m.partner_id,(select user_id from unit_partner_actor),'fold_partner_into_unit',jsonb_build_object('unit_id',m.unit_id)
from unit_partner m;
update ai_management.records r set archived_at=now(),version=r.version+1 from unit_partner m where r.id=m.partner_id;

revoke all on function public.ai_catalog_link(jsonb),public.ai_catalog_overview() from public,anon;
grant execute on function public.ai_catalog_link(jsonb),public.ai_catalog_overview() to authenticated;
commit;
