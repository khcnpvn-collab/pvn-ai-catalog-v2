-- Activities drop three fields. The last working day now comes from the activity's milestones, so each
-- meeting date typed on an activity becomes a held milestone of that activity (with the activity's source);
-- "Bước tiếp theo" moves to the end of "Kết quả"; "Kết luận" is empty everywhere. Every value that goes
-- or moves is snapshotted in the audit log first.
begin;

create temporary table review_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;

-- One held milestone per meeting date, named after the activity's partner.
create temporary table meeting_milestone on commit drop as
select gen_random_uuid() id, r.id activity_id, r.created_by, d.last_meeting_date meeting_day,
 'Làm việc với '||coalesce((select p.title from ai_management.relations l join ai_management.records p on p.id=l.target_id
   where l.source_id=r.id and l.relation='partner' limit 1),r.title) title
from ai_management.records r join ai_management.collaboration_details d on d.record_id=r.id
where d.last_meeting_date is not null;
insert into ai_management.records(id,kind,title,code,status,created_by)
select id,'engagement',title,'AI-'||gen_random_uuid(),'Đã diễn ra',created_by from meeting_milestone;
insert into ai_management.engagement_details(record_id,kind,start_date,end_date)
select id,'engagement',meeting_day,meeting_day from meeting_milestone;
insert into ai_management.relations(source_id,target_id,relation,created_by)
select id,activity_id,'collaboration',created_by from meeting_milestone;
insert into ai_management.source_links(source_id,record_id,created_by)
select s.source_id,m.id,m.created_by from meeting_milestone m join ai_management.source_links s on s.record_id=m.activity_id;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select m.id,(select user_id from review_actor),'create_milestone_from_meeting_date',jsonb_build_object('activity_id',m.activity_id,'start_date',m.meeting_day,'title',m.title)
from meeting_milestone m;

-- Snapshot every value of the three fields, then append the next steps to the results.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select d.record_id,(select user_id from review_actor),'drop_activity_meeting_fields',
 jsonb_strip_nulls(jsonb_build_object('results',d.results,'conclusion',d.conclusion,'next_notes',d.next_notes,'last_meeting_date',d.last_meeting_date)),
 jsonb_build_object('results',concat_ws(E'\n\n',nullif(btrim(d.results),''),'Bước tiếp theo: '||nullif(btrim(d.next_notes),''),'Kết luận: '||nullif(btrim(d.conclusion),'')))
from ai_management.collaboration_details d
where coalesce(btrim(d.conclusion),'')<>'' or coalesce(btrim(d.next_notes),'')<>'' or d.last_meeting_date is not null;
update ai_management.collaboration_details d set results=concat_ws(E'\n\n',nullif(btrim(d.results),''),'Bước tiếp theo: '||nullif(btrim(d.next_notes),''))
where coalesce(btrim(d.next_notes),'')<>'';
update ai_management.collaboration_details d set results=concat_ws(E'\n\n',nullif(btrim(d.results),''),'Kết luận: '||nullif(btrim(d.conclusion),''))
where coalesce(btrim(d.conclusion),'')<>'';

update ai_management.module_registry set fields=(select jsonb_agg(f order by n) from jsonb_array_elements(fields) with ordinality x(f,n)
 where f->>'key' not in ('conclusion','next_notes','last_meeting_date')) where kind='collaboration';
alter table ai_management.collaboration_details drop column conclusion, drop column next_notes, drop column last_meeting_date;

create or replace function public.ai_catalog_overview() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with v as (
  select r.id,r.kind,r.title,r.code,r.status,r.updated_at from ai_management.records r
  where r.kind in ('use_case','work_item','collaboration','partner','unit','expert','engagement')
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
  'work_items',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'code',v.code,'status',v.status,'updated_at',v.updated_at,
    'item_group',d.item_group,'scope_level',d.scope_level,'apply_scope',d.apply_scope,'owner',d.owner,'coordinator',d.coordinator,'start_date',d.start_date,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by d.item_group,v.title),'[]'::jsonb) from v join ai_management.work_item_details d on d.record_id=v.id),
  'activities',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'item_group',d.item_group,'item_category',d.item_category,'start_date',d.start_date,'end_date',d.end_date,
    'partner_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'provider_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='unit' limit 1),
    'party_lead_id',(select l.context->>'lead_member_id' from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' and l.target_kind='use_case' limit 1),
    'work_item_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' and l.target_kind='work_item' limit 1),
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'expert_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='expert')
   ) order by v.updated_at desc,v.id),'[]'::jsonb) from v join ai_management.collaboration_details d on d.record_id=v.id),
  'partners',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'short_name',d.short_name,'partner_type',d.partner_type,'country',d.country,'strategic_level',d.strategic_level,'specialties',d.specialties,
    'contact_name',(select c.title from ai_management.relations x join ai_management.records c on c.id=x.target_id and c.kind='contact' left join ai_management.contact_details cd on cd.record_id=c.id
      where x.source_id=v.id and x.relation='contact' and ai_management.can_read_record(c.id) order by coalesce(cd.is_primary,'')='Có' desc,c.title limit 1),
    'contact_count',(select count(*) from ai_management.relations x join ai_management.records c on c.id=x.target_id and c.kind='contact' where x.source_id=v.id and x.relation='contact' and ai_management.can_read_record(c.id)),
    'member_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner'),
    'lead_member_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' and coalesce(l.context->>'consortium_role',l.context->>'role',l.context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh') limit 1)
   ) order by v.title),'[]'::jsonb) from v join ai_management.partner_details d on d.record_id=v.id),
  'units',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'abbreviation',d.abbreviation,'sector',d.sector,'unit_type',d.unit_type,
    'parent_id',(select l.target_id from l where l.source_id=v.id and l.relation='parent' limit 1)
   ) order by v.title),'[]'::jsonb) from v join ai_management.unit_details d on d.record_id=v.id),
  'milestones',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'start_date',d.start_date,'end_date',d.end_date,'period_label',d.period_label,
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner'),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'activity_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='collaboration')
   ) order by d.start_date desc nulls last,v.updated_at desc),'[]'::jsonb) from v join ai_management.engagement_details d on d.record_id=v.id),
  'experts',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'organization',d.organization,'current_position',d.current_position,'expertise_summary',d.expertise_summary,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.expert_details d on d.record_id=v.id)
 ) into result;
 return result;
end $$;
revoke all on function public.ai_catalog_overview() from public,anon;
grant execute on function public.ai_catalog_overview() to authenticated;
commit;
