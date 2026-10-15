-- Collapse source-identical survey containers/items left side by side after flattening.
-- Keep the original cooperation record; retain the duplicate, its source mapping
-- and audit history in the trash so the decision can be reversed.
begin;

create temporary table duplicate_survey_cooperation on commit drop as
select original.id canonical_id, item.id duplicate_id, item.created_by actor_id,
 to_jsonb(item) as duplicate_record, to_jsonb(item_detail) as duplicate_detail
from ai_management.records original
join ai_management.records item
 on item.code=replace(original.code,'KS-COLLABORATION-','KS-COLLABORATION_ITEM-')
 and item.kind='collaboration' and item.archived_at is null and item.version=2
join ai_management.collaboration_details original_detail on original_detail.record_id=original.id
join ai_management.collaboration_details item_detail on item_detail.record_id=item.id
where original.kind='collaboration' and original.archived_at is null
 and original.code like 'KS-COLLABORATION-%'
 and original_detail.scope is not distinct from item_detail.scope
 and original_detail.results is not distinct from item_detail.results
 and item_detail.lead is null and item_detail.agreement is null
 and item_detail.next_notes is null and item_detail.last_meeting_date is null
 and item_detail.cooperation_types='Khác' and item_detail.source_status='Chưa xác minh'
 and exists(select 1 from ai_management.source_links where record_id=original.id)
 and (select array_agg(source_id order by source_id) from ai_management.source_links where record_id=original.id)
     is not distinct from
     (select array_agg(source_id order by source_id) from ai_management.source_links where record_id=item.id)
 and (select jsonb_agg(jsonb_build_object('target',target_id,'relation',relation,'note',note,'context',context)
                       order by target_id,relation)
      from ai_management.relations where source_id=original.id and relation in ('partner','unit'))
     is not distinct from
     (select jsonb_agg(jsonb_build_object('target',target_id,'relation',relation,'note',note,'context',context)
                       order by target_id,relation)
      from ai_management.relations where source_id=item.id and relation in ('partner','unit'))
 and not exists(select 1 from ai_management.document_links where record_id=item.id)
 and not exists(select 1 from ai_management.relations where target_id=item.id)
 and not exists(select 1 from ai_management.relations where source_id=item.id and relation not in ('partner','unit'));

do $$
declare matching_pairs integer; safe_pairs integer;
begin
 select count(*) into matching_pairs
 from ai_management.records original join ai_management.records item
  on item.code=replace(original.code,'KS-COLLABORATION-','KS-COLLABORATION_ITEM-')
 where original.kind='collaboration' and item.kind='collaboration'
  and original.archived_at is null and item.archived_at is null
  and original.code like 'KS-COLLABORATION-%';
 select count(*) into safe_pairs from duplicate_survey_cooperation;
 if matching_pairs<>safe_pairs then
  raise exception 'Unsafe survey cooperation pair: % matching, % source-identical and asset-free',matching_pairs,safe_pairs;
 end if;
 raise notice 'Source-identical cooperation pairs to archive: %',safe_pairs;
end $$;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select duplicate_id,actor_id,'deduplicate_survey_cooperation',
 jsonb_build_object('record',duplicate_record,'detail',duplicate_detail),
 jsonb_build_object('canonical_id',canonical_id,'reason','same source, partner, PVN subject and scope; no separate assets')
from duplicate_survey_cooperation;

update ai_management.records record
set archived_at=now(),updated_at=now(),version=version+1
from duplicate_survey_cooperation pair where record.id=pair.duplicate_id;

-- The existing ADT record is the ADT–AIQ group, not a second ADT company.
-- Rename only while the workbook identity and both member edges still match.
create temporary table adt_group_to_rename on commit drop as
select group_record.id,group_record.created_by actor_id,to_jsonb(group_record) before_value
from ai_management.records group_record
join ai_management.partner_details detail on detail.record_id=group_record.id
where group_record.title='ADT' and group_record.archived_at is null
 and detail.partner_type='Liên danh / nhóm đối tác'
 and exists(select 1 from ai_management.source_links link
  join ai_management.sources source on source.id=link.source_id
  where link.record_id=group_record.id and source.source_type='partner_workbook'
   and source.source_key like '%:06_dim_lien_danh:LD002')
 and (select count(*) from ai_management.relations
  where source_id=group_record.id and relation='partner')=2
 and exists(select 1 from ai_management.relations edge
  join ai_management.source_links member_source on member_source.record_id=edge.target_id
  join ai_management.sources source on source.id=member_source.source_id
  where edge.source_id=group_record.id and edge.relation='partner'
   and source.source_type='partner_workbook'
   and source.source_key like '%:03_dim_doi_tac:DT0002')
 and exists(select 1 from ai_management.relations edge
  join ai_management.source_links member_source on member_source.record_id=edge.target_id
  join ai_management.sources source on source.id=member_source.source_id
  where edge.source_id=group_record.id and edge.relation='partner'
   and source.source_type='partner_workbook'
   and source.source_key like '%:03_dim_doi_tac:DT0003');

update ai_management.records record
set title='Nhóm ADT–AIQ',updated_at=now(),version=version+1
from adt_group_to_rename target where record.id=target.id;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select target.id,target.actor_id,'clarify_partner_group',target.before_value,
 jsonb_build_object('title','Nhóm ADT–AIQ','reason','workbook LD002; ADT Global and AIQ remain separate members')
from adt_group_to_rename target;

commit;
