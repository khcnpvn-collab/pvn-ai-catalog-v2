-- Flatten legacy collaboration items into one-level partner cooperation contents.
-- Existing IDs, documents, sources, audit history and non-parent relations are retained.
begin;

create temporary table cooperation_items_to_migrate on commit drop as
select r.id,r.title,r.code,r.summary,r.status,r.observed_on,r.source_note,r.visibility,
 r.version,r.created_by,r.created_at,r.updated_at,r.archived_at,
 d.item_type,d.scope,d.results,
 jsonb_build_object('kind',r.kind,'status',r.status,'data',to_jsonb(d)-'record_id'-'kind') before_value
from ai_management.records r
join ai_management.collaboration_item_details d on d.record_id=r.id
where r.kind='collaboration_item';

-- Inherit partner and PVN-subject relations from the former parent container so
-- every converted content remains discoverable from the same partner dossier.
insert into ai_management.relations(source_id,target_id,relation,note,context,created_by,created_at)
select distinct i.id,inherited.target_id,inherited.relation,inherited.note,inherited.context,inherited.created_by,inherited.created_at
from cooperation_items_to_migrate i
join ai_management.relations parent_link on parent_link.source_id=i.id and parent_link.relation='parent'
join ai_management.records parent_record on parent_record.id=parent_link.target_id and parent_record.kind='collaboration'
join ai_management.relations inherited on inherited.source_id=parent_record.id and inherited.relation in ('partner','unit')
on conflict(source_id,target_id,relation) do nothing;

-- The parent edge represented the retired nesting level and must not survive
-- after both endpoints become cooperation contents.
delete from ai_management.relations relation
using cooperation_items_to_migrate item
where relation.source_id=item.id and relation.relation='parent';

delete from ai_management.collaboration_item_details detail
using cooperation_items_to_migrate item
where detail.record_id=item.id;

update ai_management.records record
set kind='collaboration',
 status=case record.status
  when 'Đề xuất' then 'Tiềm năng'
  else record.status
 end,
 version=record.version+1,
 updated_at=now()
from cooperation_items_to_migrate item
where record.id=item.id;

insert into ai_management.collaboration_details(
 record_id,scope,lead,results,agreement,cooperation_types,source_status,last_meeting_date,next_notes
)
select item.id,item.scope,null,item.results,null,
 case item.item_type
  when 'POC' then 'PoC / thử nghiệm'
  when 'Tư vấn' then 'Hợp đồng tư vấn'
  when 'Đào tạo' then 'Đào tạo / chuyển giao'
  else coalesce(item.item_type,'Khác')
 end,
 item.status,null,null
from cooperation_items_to_migrate item;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select item.id,item.created_by,'normalize_cooperation_content',item.before_value,
 jsonb_build_object(
  'kind','collaboration',
  'status',record.status,
  'data',to_jsonb(detail)-'record_id'-'kind'
 )
from cooperation_items_to_migrate item
join ai_management.records record on record.id=item.id
join ai_management.collaboration_details detail on detail.record_id=item.id;

-- A milestone linked only through cooperation content should still appear in
-- its partner's common timeline. Infer the partner only when all linked
-- cooperation contents resolve to one unambiguous partner.
with candidates as (
 select edge.source_id engagement_id,
  (array_agg(distinct partner_link.target_id))[1] partner_id,
  engagement.created_by actor_id
 from ai_management.relations edge
 join ai_management.records engagement on engagement.id=edge.source_id and engagement.kind='engagement'
 join ai_management.records content on content.id=edge.target_id and content.kind='collaboration'
 join ai_management.relations partner_link on partner_link.source_id=content.id and partner_link.relation='partner'
 join ai_management.records partner on partner.id=partner_link.target_id and partner.kind='partner'
 where edge.relation='collaboration'
 group by edge.source_id,engagement.created_by
 having count(distinct partner_link.target_id)=1
), inserted as (
 insert into ai_management.relations(source_id,target_id,relation,created_by)
 select candidate.engagement_id,candidate.partner_id,'partner',candidate.actor_id
 from candidates candidate
 where not exists (
  select 1 from ai_management.relations existing
  where existing.source_id=candidate.engagement_id and existing.relation='partner'
 )
 on conflict(source_id,target_id,relation) do nothing
 returning source_id,target_id,created_by
)
insert into ai_management.audit(record_id,actor_id,action,after_value)
select source_id,created_by,'normalize_milestone_partner',
 jsonb_build_object('relation','partner','target_id',target_id)
from inserted;

-- Normalize free-text classifications from earlier imports. The source wording
-- remains in source_status so no provenance is discarded.
update ai_management.collaboration_details detail
set source_status=case
  when nullif(btrim(coalesce(detail.source_status,'')),'') is null then 'Phân loại nguồn: '||detail.cooperation_types
  else detail.source_status||E'\nPhân loại nguồn: '||detail.cooperation_types
 end,
 cooperation_types=case
  when detail.cooperation_types ~* 'poc|proof.of.concept|thử nghiệm' then 'PoC / thử nghiệm'
  when detail.cooperation_types ~* 'mua sắm' then 'Hợp đồng mua sắm'
  when detail.cooperation_types ~* 'tư vấn' then 'Hợp đồng tư vấn'
  when detail.cooperation_types ~* 'nghiên cứu|phát triển|r&d' then 'Nghiên cứu – phát triển'
  when detail.cooperation_types ~* 'đào tạo|chuyển giao' then 'Đào tạo / chuyển giao'
  when detail.cooperation_types ~* 'chiến lược' then 'Hợp tác chiến lược'
  else 'Khác'
 end
where detail.cooperation_types is not null and detail.cooperation_types not in (
 'PoC / thử nghiệm','Hợp đồng mua sắm','Hợp đồng tư vấn','Nghiên cứu – phát triển','Đào tạo / chuyển giao','Hợp tác chiến lược','Khác'
);

alter table ai_management.collaboration_details add constraint collaboration_details_cooperation_type_check
check(cooperation_types is null or cooperation_types in (
 'PoC / thử nghiệm','Hợp đồng mua sắm','Hợp đồng tư vấn','Nghiên cứu – phát triển','Đào tạo / chuyển giao','Hợp tác chiến lược','Khác'
));

-- The shared link gateway supports many modules. Enforce the narrower partner
-- cooperation contract at the table boundary so direct or concurrent calls
-- cannot attach a second partner/use case or a second lead PVN subject.
create function ai_management.enforce_collaboration_relation_cardinality() returns trigger
language plpgsql set search_path='' as $$
declare source_kind text;
begin
 if new.relation not in ('partner','use_case','unit') then return new; end if;
 perform pg_advisory_xact_lock(73424910902411);
 select kind into source_kind from ai_management.records where id=new.source_id;
 if source_kind<>'collaboration' then return new; end if;
 if new.relation in ('partner','use_case') and exists(
  select 1 from ai_management.relations existing
  where existing.source_id=new.source_id and existing.relation=new.relation and existing.id<>new.id
 ) then
  raise exception 'VALIDATION: cooperation content accepts only one %',new.relation using errcode='22023';
 end if;
 if new.relation='unit' and new.context->>'subject_role'='lead' and exists(
  select 1 from ai_management.relations existing
  where existing.source_id=new.source_id and existing.relation='unit'
   and existing.context->>'subject_role'='lead' and existing.id<>new.id
 ) then
  raise exception 'VALIDATION: cooperation content accepts only one lead PVN subject' using errcode='22023';
 end if;
 return new;
end $$;

create trigger collaboration_relation_cardinality
before insert or update of source_id,target_id,relation,context on ai_management.relations
for each row execute function ai_management.enforce_collaboration_relation_cardinality();

-- Assign or change the lead PVN subject in one transaction. This gateway also
-- upserts an existing unit link so clients never need to delete it first.
create function public.ai_catalog_collaboration_unit_link(p_link jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare source_record ai_management.records; target_record ai_management.records;
declare role text; ctx jsonb; item record; current_link ai_management.relations; result ai_management.relations;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_link,array['source_id','target_id','relation','note','context']);
 perform pg_advisory_xact_lock(73424910902411);
 select * into source_record from ai_management.records where id=(p_link->>'source_id')::uuid for update;
 select * into target_record from ai_management.records where id=(p_link->>'target_id')::uuid;
 ctx:=coalesce(p_link->'context','{}'::jsonb);
 role:=ctx->>'subject_role';
 if source_record.id is null or target_record.id is null or not ai_management.can_read_record(source_record.id) or not ai_management.can_read_record(target_record.id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(source_record.id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if source_record.archived_at is not null or target_record.archived_at is not null
  or source_record.kind<>'collaboration' or target_record.kind<>'unit'
  or p_link->>'relation'<>'unit' or role not in ('lead','supporting') then
  raise exception 'VALIDATION: invalid cooperation subject relation' using errcode='22023';
 end if;
 if jsonb_typeof(ctx)<>'object' or octet_length(ctx::text)>16000 then raise exception 'VALIDATION: invalid context' using errcode='22023'; end if;
 for item in select key,value from jsonb_each(ctx) loop
  if length(item.key)>80 or jsonb_typeof(item.value)<>'string' or length(item.value#>>'{}')>1000 then raise exception 'VALIDATION: invalid context value' using errcode='22023'; end if;
 end loop;
 if role='lead' then
  update ai_management.relations set context=context || jsonb_build_object('subject_role','supporting')
  where source_id=source_record.id and relation='unit' and target_id<>target_record.id and context->>'subject_role'='lead';
 end if;
 select * into current_link from ai_management.relations
 where source_id=source_record.id and target_id=target_record.id and relation='unit' for update;
 if current_link.id is null then return public.ai_catalog_link(p_link); end if;
 update ai_management.relations set context=ctx,
  note=case when p_link ? 'note' then nullif(p_link->>'note','') else current_link.note end
 where id=current_link.id returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
 values(source_record.id,auth.uid(),'link_context',to_jsonb(current_link),to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when check_violation or invalid_text_representation or not_null_violation then
 raise exception 'VALIDATION: invalid cooperation subject relation' using errcode='22023';
end $$;

revoke all on function public.ai_catalog_collaboration_unit_link(jsonb) from public,anon;
grant execute on function public.ai_catalog_collaboration_unit_link(jsonb) to authenticated;

update ai_management.module_registry set fields='[
 {"key":"cooperation_types","type":"select","options":["PoC / thử nghiệm","Hợp đồng mua sắm","Hợp đồng tư vấn","Nghiên cứu – phát triển","Đào tạo / chuyển giao","Hợp tác chiến lược","Khác"]},
 {"key":"scope","type":"textarea","options":null},
 {"key":"lead","type":"text","options":null},
 {"key":"agreement","type":"text","options":null},
 {"key":"results","type":"textarea","options":null},
 {"key":"source_status","type":"text","options":null},
 {"key":"last_meeting_date","type":"date","options":null},
 {"key":"next_notes","type":"textarea","options":null}
]'::jsonb where kind='collaboration';

-- Admin-only reconciliation report. It reports uncertainty without changing or
-- merging partner identities automatically.
create function public.ai_catalog_partner_review() returns jsonb
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
  where r.kind='engagement' and r.archived_at is null and not exists(
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
