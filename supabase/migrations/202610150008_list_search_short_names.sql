-- Searching a catalogue list finds a unit by its abbreviation and a partner by its short name, as well as by
-- title, code and summary: "BSR" finds Bình Sơn when choosing an existing unit. Only the search text changes.
begin;
create or replace function ai_management.record_search_text(p_id uuid) returns text
language sql stable security definer set search_path='' as $$
 select lower(concat_ws(' ', r.title, r.code, r.summary,
  (select u.abbreviation from ai_management.unit_details u where u.record_id=r.id),
  (select p.short_name from ai_management.partner_details p where p.record_id=r.id)))
 from ai_management.records r where r.id=p_id
$$;
revoke all on function ai_management.record_search_text(uuid) from public,anon,authenticated;

create or replace function public.ai_catalog_list(p_kind text default null,p_query text default '',p_status text default null,p_page integer default 1,p_archived boolean default false) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb; total bigint;
begin
 perform ai_management.require_role();
 if p_page is null or p_page<1 or p_page>100000 or length(coalesce(p_query,''))>500 then raise exception 'VALIDATION: invalid filter' using errcode='22023'; end if;
 if p_kind is not null and not exists(select 1 from ai_management.module_registry where kind=p_kind) then raise exception 'VALIDATION: invalid kind' using errcode='22023'; end if;
 select count(*) into total from ai_management.records r where ai_management.can_read_record(r.id) and (p_kind is null or r.kind=p_kind) and (p_status is null or r.status=p_status) and (r.archived_at is not null)=p_archived and (coalesce(p_query,'')='' or strpos(ai_management.record_search_text(r.id),lower(p_query))>0);
 select coalesce(jsonb_agg(ai_management.record_json(x.id) order by x.updated_at desc,x.id),'[]'::jsonb) into result from (select r.id,r.updated_at from ai_management.records r where ai_management.can_read_record(r.id) and (p_kind is null or r.kind=p_kind) and (p_status is null or r.status=p_status) and (r.archived_at is not null)=p_archived and (coalesce(p_query,'')='' or strpos(ai_management.record_search_text(r.id),lower(p_query))>0) order by r.updated_at desc,r.id limit 30 offset (p_page-1)*30) x;
 return jsonb_build_object('data',result,'total',total,'page',p_page,'pageSize',30);
end $$;
revoke all on function public.ai_catalog_list(text,text,text,integer,boolean) from public,anon;
grant execute on function public.ai_catalog_list(text,text,text,integer,boolean) to authenticated;
commit;
