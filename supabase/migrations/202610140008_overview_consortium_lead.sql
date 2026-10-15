-- The overview names each consortium's lead member, so partner pages can show it without loading
-- every consortium. Legacy role labels from the workbook count as lead too.
begin;

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
    'party_lead_id',(select l.context->>'lead_member_id' from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' limit 1),
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by v.updated_at desc,v.id),'[]'::jsonb) from v join ai_management.collaboration_details d on d.record_id=v.id),
  'partners',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'short_name',d.short_name,'partner_type',d.partner_type,'country',d.country,
    'member_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner'),
    'lead_member_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' and coalesce(l.context->>'consortium_role',l.context->>'role',l.context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh') limit 1)
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

revoke all on function public.ai_catalog_overview() from public,anon;
grant execute on function public.ai_catalog_overview() to authenticated;
commit;
