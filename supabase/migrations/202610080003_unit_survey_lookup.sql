-- Read immutable full questionnaires through the existing explicit unit mapping.
create function public.ai_catalog_unit_survey(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare unit_record jsonb; result jsonb;
begin
 -- Full survey source access remains admin-only, as in ai_catalog_sources.
 perform ai_management.require_role(false,true);
 unit_record := ai_management.record_json(p_id);
 if unit_record is null then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if unit_record->>'kind'<>'unit' then raise exception 'VALIDATION: expected unit dossier' using errcode='22023'; end if;
 with mapped as (
  select s.* from ai_management.sources s
  where s.source_type in ('unit_catalog','survey') and (
   s.linked_record_id=p_id or exists(
    select 1 from ai_management.source_links l where l.source_id=s.id and l.record_id=p_id
   )
  )
 ), catalog_codes as (
  select distinct unit_code from mapped where source_type='unit_catalog' and nullif(unit_code,'') is not null
 ), unit_codes as (
  select unit_code from catalog_codes
  union
  select unit_code from mapped where source_type='survey' and nullif(unit_code,'') is not null
   and not exists(select 1 from catalog_codes)
 ), snapshots as (
  select s.* from ai_management.sources s
  where s.source_type='survey' and (
   s.unit_code in (select unit_code from unit_codes)
   or (s.unit_code is null and s.id in (select id from mapped where source_type='survey'))
  )
 )
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',s.id,'title',s.title,'unit_code',s.unit_code,'created_at',s.created_at,
  'payload',jsonb_build_object('answers',s.payload->'answers','status',s.payload->'status',
   'updated_at',s.payload->'updated_at','schema_version',s.payload->'schema_version')
 ) order by coalesce(nullif(s.payload->>'updated_at',''),s.created_at::text) desc,s.created_at desc,s.id),'[]'::jsonb)
 into result from snapshots s;
 return result;
end $$;
revoke all on function public.ai_catalog_unit_survey(uuid) from public,anon;
grant execute on function public.ai_catalog_unit_survey(uuid) to authenticated;
