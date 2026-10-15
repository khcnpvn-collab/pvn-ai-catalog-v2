-- Remove only legacy member links already represented by the owning consortium.
-- Partner profiles, source rows, files and the authoritative consortium roles stay intact.
begin;

create temporary table redundant_cooperation_members on commit drop as
with owners as (
 select content.id content_id,
  (array_agg(edge.target_id) filter (where edge.note is distinct from 'Thành viên liên danh – cần xác minh vai trò'))[1] owner_id
 from ai_management.records content
 join ai_management.relations edge on edge.source_id=content.id and edge.relation='partner'
 where content.kind='collaboration'
 group by content.id
 having count(*)>1 and count(*) filter (where edge.note is distinct from 'Thành viên liên danh – cần xác minh vai trò')=1
), verified as (
 select owner.* from owners owner
 where not exists (
  select 1 from ai_management.relations member
  where member.source_id=owner.content_id and member.relation='partner'
   and member.note='Thành viên liên danh – cần xác minh vai trò'
   and not exists(select 1 from ai_management.relations represented
    where represented.source_id=owner.owner_id and represented.target_id=member.target_id and represented.relation='partner')
 )
)
select edge.*,owner.owner_id from verified owner
join ai_management.relations edge on edge.source_id=owner.content_id and edge.relation='partner'
 and edge.note='Thành viên liên danh – cần xác minh vai trò';

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select member.source_id,member.created_by,'normalize_cooperation_consortium',
 to_jsonb(member)-'owner_id',
 jsonb_build_object('partner_id',member.owner_id,'member_id',member.target_id,'represented_by','partner_consortium')
from redundant_cooperation_members member;

delete from ai_management.relations edge using redundant_cooperation_members member where edge.id=member.id;

create or replace function public.ai_catalog_partner_review() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role(false,true);
 with partner_rows as (
  select r.id,r.title,r.code,r.summary,r.updated_at,d.legal_name,d.short_name,d.partner_type,d.country,d.website,
   regexp_replace(lower(btrim(coalesce(nullif(d.legal_name,''),r.title))),'[[:space:][:punct:]]+','','g') normalized_name
  from ai_management.records r join ai_management.partner_details d on d.record_id=r.id
  where r.archived_at is null
 ), duplicates as (
  select normalized_name,jsonb_agg(jsonb_build_object('id',id,'title',title) order by title,id) records
  from partner_rows where normalized_name<>'' group by normalized_name having count(*)>1
 ), incomplete as (
  select jsonb_agg(jsonb_build_object('id',id,'title',title,'missing',
   array_remove(array[
    case when nullif(btrim(coalesce(legal_name,'')),'') is null then 'legal_name' end,
    case when nullif(btrim(coalesce(partner_type,'')),'') is null then 'partner_type' end,
    case when nullif(btrim(coalesce(country,'')),'') is null then 'country' end
   ],null)) order by title,id) records
  from partner_rows
  where nullif(btrim(coalesce(legal_name,'')),'') is null
     or nullif(btrim(coalesce(partner_type,'')),'') is null
     or nullif(btrim(coalesce(country,'')),'') is null
 ), content_partner_counts as (
  select r.id,r.title,count(p.id) partner_count
  from ai_management.records r
  left join ai_management.relations l on l.source_id=r.id and l.relation='partner'
  left join ai_management.records p on p.id=l.target_id and p.kind='partner'
  where r.kind='collaboration' and r.archived_at is null
  group by r.id,r.title
 ), orphan_contents as (
  select jsonb_agg(jsonb_build_object('id',id,'title',title,'partner_count',partner_count) order by title,id) records
  from content_partner_counts where partner_count<>1
 ), content_use_case_counts as (
  select r.id,r.title,count(u.id) use_case_count
  from ai_management.records r
  left join ai_management.relations l on l.source_id=r.id and l.relation='use_case'
  left join ai_management.records u on u.id=l.target_id and u.kind='use_case'
  where r.kind='collaboration' and r.archived_at is null
  group by r.id,r.title
 ), multiple_use_cases as (
  select jsonb_agg(jsonb_build_object('id',id,'title',title,'use_case_count',use_case_count) order by title,id) records
  from content_use_case_counts where use_case_count>1
 ), multiple_lead_units as (
  select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'lead_count',x.lead_count) order by r.title,r.id) records
  from ai_management.records r join (
   select source_id,count(*) lead_count from ai_management.relations
   where relation='unit' and context->>'subject_role'='lead' group by source_id having count(*)>1
  ) x on x.source_id=r.id
  where r.kind='collaboration' and r.archived_at is null
 ), orphan_milestones as (
  select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title) order by r.title,r.id) records
  from ai_management.records r
  where r.kind='engagement' and r.archived_at is null and exists(
   select 1 from ai_management.relations edge join ai_management.records content on content.id=edge.target_id
   where edge.source_id=r.id and edge.relation='collaboration' and content.kind='collaboration'
  ) and not exists(
   select 1 from ai_management.relations l join ai_management.records p on p.id=l.target_id
   where l.source_id=r.id and l.relation='partner' and p.kind='partner'
  )
 )
 select jsonb_build_object(
  'generated_at',now(),
  'partner_count',(select count(*) from partner_rows),
  'cooperation_content_count',(select count(*) from ai_management.records where kind='collaboration' and archived_at is null),
  'duplicate_name_groups',coalesce((select jsonb_agg(records) from duplicates),'[]'::jsonb),
  'incomplete_partners',coalesce((select records from incomplete),'[]'::jsonb),
  'cooperation_contents_without_one_partner',coalesce((select records from orphan_contents),'[]'::jsonb),
  'cooperation_contents_with_multiple_use_cases',coalesce((select records from multiple_use_cases),'[]'::jsonb),
  'cooperation_contents_with_multiple_lead_units',coalesce((select records from multiple_lead_units),'[]'::jsonb),
  'milestones_without_partner',coalesce((select records from orphan_milestones),'[]'::jsonb),
  'remaining_legacy_items',(select count(*) from ai_management.records where kind='collaboration_item')
 ) into result;
 return result;
end $$;

revoke all on function public.ai_catalog_partner_review() from public,anon,authenticated;
grant execute on function public.ai_catalog_partner_review() to authenticated;

commit;
