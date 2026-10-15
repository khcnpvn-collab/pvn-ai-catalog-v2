-- Training and workshops are managed like every other activity: each event becomes an activity of the
-- group "Nhân lực, đào tạo", linked to the matching work item when one exists, keeping its files and
-- people. The training record kind then goes away; each event is snapshotted in the audit log first.
begin;

create temporary table event_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;
create temporary table event_move on commit drop as
select r.id old_id, gen_random_uuid() new_id, r.title, r.summary, r.created_by, d.*,
 case r.status when 'Đã tổ chức' then 'Hoàn thành' when 'Đang diễn ra' then 'Triển khai chính thức' when 'Hoãn' then 'Tạm dừng' when 'Hủy' then 'Dừng' else 'Đề xuất' end new_status,
 case when d.event_type in ('Hội thảo','Tọa đàm') then 'Hội thảo, chia sẻ kinh nghiệm' else 'Đào tạo, khóa học' end category,
 concat_ws(E'\n', 'Loại: '||d.event_type, 'Chủ đề: '||d.topic, 'Hình thức: '||d.format, 'Địa điểm: '||d.location, 'Đối tượng: '||d.audience,
  'Số người tham dự: '||d.reported_attendees, 'Thời gian: '||d.period_label, 'Chương trình: '||d.agenda) scope_text
from ai_management.records r join ai_management.learning_event_details d on d.record_id=r.id;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select m.old_id,(select user_id from event_actor),'convert_event_to_activity',
 jsonb_build_object('record',to_jsonb(r),'data',to_jsonb(d)-'record_id'-'kind',
  'relations',(select coalesce(jsonb_agg(to_jsonb(l)),'[]'::jsonb) from ai_management.relations l where m.old_id in (l.source_id,l.target_id))),
 jsonb_build_object('activity_id',m.new_id)
from event_move m join ai_management.records r on r.id=m.old_id join ai_management.learning_event_details d on d.record_id=m.old_id;

insert into ai_management.records(id,kind,title,summary,status,created_by)
select new_id,'collaboration',title,summary,new_status,created_by from event_move;
insert into ai_management.collaboration_details(record_id,item_group,item_category,scope,start_date,end_date,results)
select new_id,'Nhân lực, đào tạo',category,nullif(scope_text,''),start_date,end_date,results from event_move;

-- The matching work item, by its title in the people and training group.
insert into ai_management.relations(source_id,target_id,relation,created_by)
select m.new_id,w.record_id,'use_case',(select user_id from event_actor)
from event_move m join ai_management.work_item_details w on w.item_group='Nhân lực, đào tạo'
join ai_management.records wr on wr.id=w.record_id and wr.title=case when m.category='Hội thảo, chia sẻ kinh nghiệm' then 'Hội thảo chia sẻ kinh nghiệm' end;
-- People and organisers follow: speakers and participants as experts, organising units as supporting subjects.
insert into ai_management.relations(source_id,target_id,relation,context,created_by)
select distinct on (m.new_id,l.target_id) m.new_id,l.target_id,'expert','{}'::jsonb,(select user_id from event_actor)
from event_move m join ai_management.relations l on l.source_id=m.old_id and l.relation in ('speaker','participant')
join ai_management.records t on t.id=l.target_id and t.kind='expert';
insert into ai_management.relations(source_id,target_id,relation,context,created_by)
select m.new_id,l.target_id,'unit',jsonb_build_object('subject_role','supporting'),(select user_id from event_actor)
from event_move m join ai_management.relations l on l.source_id=m.old_id and l.relation='organizer'
join ai_management.records t on t.id=l.target_id and t.kind='unit';
update ai_management.document_links l set record_id=m.new_id from event_move m where l.record_id=m.old_id;
update ai_management.source_links l set record_id=m.new_id from event_move m where l.record_id=m.old_id;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select new_id,(select user_id from event_actor),'create_from_event',jsonb_build_object('event_id',old_id,'item_group','Nhân lực, đào tạo','item_category',category) from event_move;

delete from ai_management.relations where source_id in (select old_id from event_move) or target_id in (select old_id from event_move);
delete from ai_management.records where id in (select old_id from event_move);
drop table ai_management.learning_event_details;
delete from ai_management.module_registry where kind='learning_event';

-- The overview no longer lists events.
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
    'organization',d.organization,'current_position',d.current_position,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.expert_details d on d.record_id=v.id)
 ) into result;
 return result;
end $$;
revoke all on function public.ai_catalog_overview() from public,anon;
grant execute on function public.ai_catalog_overview() to authenticated;
commit;
