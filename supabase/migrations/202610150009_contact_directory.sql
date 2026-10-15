-- One directory of people to reach: contacts of units and partners, and experts, each with the units or
-- partners they belong to. Unit contacts point to their unit; partners point to their contacts. Read only.
begin;
create or replace function public.ai_catalog_directory() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with org as (
  select o.id,o.kind,o.title,coalesce(u.abbreviation,p.short_name) short from ai_management.records o
  left join ai_management.unit_details u on u.record_id=o.id left join ai_management.partner_details p on p.record_id=o.id
  where o.kind in ('unit','partner') and ai_management.can_read_record(o.id)
 ), member as (
  select x.target_id person_id,x.source_id org_id from ai_management.relations x where x.relation='contact'
  union select x.source_id,x.target_id from ai_management.relations x where x.relation in ('unit','partner')
 ), orgs as (
  select m.person_id,jsonb_agg(jsonb_build_object('id',org.id,'kind',org.kind,'title',org.title,'short',org.short) order by org.title) list
  from member m join org on org.id=m.org_id group by m.person_id
 )
 select jsonb_build_object(
  'contacts',(select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'status',r.status,'updated_at',r.updated_at,
    'role',d.role,'position',d.position,'department',d.department,'email',d.email,'phone',d.phone,'is_primary',d.is_primary,'work_status',d.work_status,
    'orgs',coalesce(orgs.list,'[]'::jsonb)) order by r.title),'[]'::jsonb)
   from ai_management.records r join ai_management.contact_details d on d.record_id=r.id left join orgs on orgs.person_id=r.id
   where ai_management.can_read_record(r.id)),
  'experts',(select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'status',r.status,'updated_at',r.updated_at,
    'position',d.current_position,'organization',d.organization,'email',d.email,'phone',d.phone,'expertise_summary',d.expertise_summary,
    'orgs',coalesce(orgs.list,'[]'::jsonb)) order by r.title),'[]'::jsonb)
   from ai_management.records r join ai_management.expert_details d on d.record_id=r.id left join orgs on orgs.person_id=r.id
   where ai_management.can_read_record(r.id))
 ) into result;
 return result;
end $$;
revoke all on function public.ai_catalog_directory() from public,anon;
grant execute on function public.ai_catalog_directory() to authenticated;
commit;
