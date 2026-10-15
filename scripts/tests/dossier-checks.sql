\set ON_ERROR_STOP on
-- All fixtures and helpers are rolled back; this file runs only in the disposable cluster.
begin;
create temporary table dossier_test_sections(config jsonb);
insert into dossier_test_sections values (:'dossier_sections'::jsonb);
grant select on dossier_test_sections to authenticated;
create function public.dossier_test_input(k text, label text, visibility text default 'team') returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('kind',k,'title',label,'status',statuses[1],'visibility',visibility,'data','{}'::jsonb)
 from ai_management.module_registry where kind=k
$$;
create function public.dossier_test_record(k text,label text,visibility text default 'team') returns uuid
language sql as $$ select (public.ai_catalog_save(public.dossier_test_input(k,label,visibility))->>'id')::uuid $$;
create function public.dossier_test_link(s uuid,t uuid,rel text) returns void language plpgsql as $$
begin perform public.ai_catalog_link(jsonb_build_object('source_id',s,'target_id',t,'relation',rel)); end $$;
create function public.dossier_test_has(d jsonb,id uuid) returns boolean language sql as $$
 select exists(select 1 from jsonb_array_elements(d->'related') e where e->'record'->>'id'=id::text)
$$;
set role anon;
select public.catalog_test_error('select public.ai_catalog_dossier(gen_random_uuid())','permission denied','anonymous dossier gateway denied');
select public.catalog_test_error('select public.ai_catalog_create_related(gen_random_uuid(),''{}'',''unit'',''to-parent'')','permission denied','anonymous contextual creation denied');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare
 unit_id uuid; partner_id uuid; case_id uuid; demand_id uuid; engagement_id uuid; engagement_two uuid;
 hidden_bridge uuid; hidden_case uuid; hidden_contact uuid; archived_id uuid; archived_bridge uuid; archived_case uuid;
 other_unit uuid; other_contact uuid; partner_contact uuid; unrelated_demand uuid; generic_case uuid;
 collaboration_id uuid; item_id uuid; child jsonb; d jsonb; e jsonb; original jsonb; baseline int; rel_baseline int;
 doc_id uuid; private_doc uuid; entry jsonb; parent_id uuid; meeting_demand uuid; private_meeting uuid; private_meeting_demand uuid; old_meeting uuid; old_meeting_demand uuid; meeting_case uuid; meeting_data uuid;
begin
 unit_id:=public.dossier_test_record('unit','Dossier unit');
 partner_id:=public.dossier_test_record('partner','Dossier partner');
 case_id:=public.dossier_test_record('use_case','Canonical case');
 demand_id:=public.dossier_test_record('demand','Local demand');
 engagement_id:=public.dossier_test_record('engagement','Meeting one');
 engagement_two:=public.dossier_test_record('engagement','Meeting two');
 hidden_bridge:=public.dossier_test_record('demand','Hidden demand','private');
 hidden_case:=public.dossier_test_record('use_case','Case behind hidden bridge');
 hidden_contact:=public.dossier_test_record('contact','Private contact','private');
 archived_id:=public.dossier_test_record('contact','Archived contact');
 archived_bridge:=public.dossier_test_record('demand','Archived demand');
 archived_case:=public.dossier_test_record('use_case','Case behind archived bridge');
 other_unit:=public.dossier_test_record('unit','Other unit');
 other_contact:=public.dossier_test_record('contact','Other unit contact');
 partner_contact:=public.dossier_test_record('contact','Other partner contact');
 unrelated_demand:=public.dossier_test_record('demand','Other case demand');
 generic_case:=public.dossier_test_record('use_case','Generic link case');
 collaboration_id:=public.dossier_test_record('collaboration','Agreement');
 item_id:=public.dossier_test_record('collaboration_item','Agreement item');
 perform public.dossier_test_link(demand_id,unit_id,'unit');
 perform public.dossier_test_link(demand_id,case_id,'use_case');
 perform public.dossier_test_link(demand_id,generic_case,'related');
 perform public.dossier_test_link(engagement_id,unit_id,'unit');
 perform public.dossier_test_link(engagement_two,unit_id,'unit');
 meeting_demand:=(public.ai_catalog_create_related(engagement_id,public.dossier_test_input('demand','Demand from meeting'),'related','to-parent')->>'id')::uuid;
 meeting_case:=(public.ai_catalog_create_related(engagement_id,public.dossier_test_input('use_case','Case from meeting'),'use_case','from-parent')->>'id')::uuid;
 meeting_data:=(public.ai_catalog_create_related(engagement_id,public.dossier_test_input('data_asset','Data from meeting'),'data','from-parent')->>'id')::uuid;
 private_meeting:=public.dossier_test_record('engagement','Private meeting','private');
 old_meeting:=public.dossier_test_record('engagement','Archived meeting');
 perform public.dossier_test_link(private_meeting,unit_id,'unit');
 perform public.dossier_test_link(old_meeting,unit_id,'unit');
 private_meeting_demand:=(public.ai_catalog_create_related(private_meeting,public.dossier_test_input('demand','Hidden meeting demand'),'related','to-parent')->>'id')::uuid;
 old_meeting_demand:=(public.ai_catalog_create_related(old_meeting,public.dossier_test_input('demand','Archived meeting demand'),'related','to-parent')->>'id')::uuid;
 perform public.ai_catalog_archive(old_meeting,1);
 perform public.dossier_test_link(hidden_bridge,unit_id,'unit');
 perform public.dossier_test_link(hidden_bridge,hidden_case,'use_case');
 perform public.dossier_test_link(hidden_contact,unit_id,'unit');
 perform public.dossier_test_link(archived_id,unit_id,'unit');
 perform public.dossier_test_link(archived_bridge,unit_id,'unit');
 perform public.dossier_test_link(archived_bridge,archived_case,'use_case');
 perform public.dossier_test_link(other_unit,unit_id,'parent');
 perform public.dossier_test_link(other_contact,other_unit,'unit');
 perform public.dossier_test_link(unit_id,partner_id,'partner');
 perform public.dossier_test_link(partner_contact,partner_id,'partner');
 perform public.dossier_test_link(unit_id,case_id,'use_case');
 perform public.dossier_test_link(unrelated_demand,case_id,'use_case');
 perform public.dossier_test_link(collaboration_id,unit_id,'unit');
 perform public.dossier_test_link(collaboration_id,partner_id,'partner');
 perform public.dossier_test_link(item_id,collaboration_id,'parent');
 -- Existing shared document has two versions. Preserve a distinct pin per subordinate record.
 select (value->>'id')::uuid into doc_id from public.catalog_test_state where name='doc';
 select (value->>'id')::uuid into private_doc from public.catalog_test_state where name='private_doc';
 perform public.ai_catalog_document_link(engagement_id,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_document_link(engagement_two,doc_id,'20000000-0000-4000-8000-000000000002');
 perform public.ai_catalog_document_link(engagement_id,private_doc,'20000000-0000-4000-8000-000000000003');
 perform public.ai_catalog_document_link(hidden_bridge,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_document_link(archived_bridge,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_document_link(partner_id,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_archive(archived_id,1);
 perform public.ai_catalog_archive(archived_bridge,1);
 d:=public.ai_catalog_dossier(unit_id);
 perform public.catalog_test_assert(public.dossier_test_has(d,hidden_bridge) and public.dossier_test_has(d,hidden_case),'creator sees permitted private bridge and indirect case');
 original:=public.ai_catalog_get(unit_id);
 perform public.catalog_test_assert(d-'related'-'attachments'=original,'dossier preserves original detail data links documents and history');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
 d:=public.ai_catalog_dossier(unit_id);
 perform public.catalog_test_assert(public.dossier_test_has(d,meeting_demand),'unit dossier includes demand recorded in its engagement');
 perform public.catalog_test_assert(public.dossier_test_has(d,meeting_case) and public.dossier_test_has(d,meeting_data),'unit dossier includes meeting use case and data');
 perform public.catalog_test_assert(not public.dossier_test_has(d,private_meeting_demand) and not public.dossier_test_has(d,old_meeting_demand),'hidden and archived engagement bridges never expose their demands');
 perform public.catalog_test_assert(public.dossier_test_has(d,demand_id) and public.dossier_test_has(d,engagement_id),'reader sees direct team demand and engagement');
 select x into e from jsonb_array_elements(d->'related') x where x->'record'->>'id'=demand_id::text;
 perform public.catalog_test_assert(e->'via'='null'::jsonb and e->>'direction'='incoming' and e->>'relation'='unit','direct relation includes correct direction and no intermediary');
 select x into e from jsonb_array_elements(d->'related') x where x->'record'->>'id'=item_id::text;
 perform public.catalog_test_assert(e->'via'->>'id'=collaboration_id::text and e->>'relation'='parent' and e->>'direction'='incoming','indirect item identifies readable agreement provenance');
 select x into e from jsonb_array_elements(d->'related') x where x->'record'->>'id'=case_id::text;
 perform public.catalog_test_assert(e->'via'='null'::jsonb and (select count(*) from jsonb_array_elements(d->'related') x where x->'record'->>'id'=case_id::text)=1,'direct path wins and duplicate paths collapse');
 perform public.catalog_test_assert(not public.dossier_test_has(d,hidden_bridge) and not public.dossier_test_has(d,hidden_case) and not public.dossier_test_has(d,hidden_contact),'private endpoints and private bridge descendants are absent');
 perform public.catalog_test_assert(not public.dossier_test_has(d,archived_id) and not public.dossier_test_has(d,archived_bridge) and not public.dossier_test_has(d,archived_case),'archived endpoints and bridge descendants are absent');
 perform public.catalog_test_assert(not public.dossier_test_has(d,other_contact),'no traversal through another unit');
 perform public.catalog_test_assert(not public.dossier_test_has(d,partner_contact),'no traversal through partner entity');
 perform public.catalog_test_assert(not public.dossier_test_has(d,unrelated_demand),'no traversal through canonical use case');
 perform public.catalog_test_assert(not public.dossier_test_has(d,generic_case),'generic related edge does not broaden indirect scope');
 perform public.catalog_test_assert(jsonb_array_length(d->'attachments')=2,'attachments exclude hidden archived private-document and entity-only attachments');
 for entry in select * from jsonb_array_elements(d->'attachments') loop
  perform public.catalog_test_assert(entry->'document'->>'id'=doc_id::text and jsonb_array_length(entry->'document'->'versions')=1 and entry->'document'->'versions'->0->>'version'=case when entry->'record'->>'id'=engagement_id::text then '1' else '2' end,'each subordinate attachment preserves its own immutable version pin');
 end loop;
 perform public.catalog_test_assert(d::text not like '%storage_path%','dossier contains no protected storage paths');
 perform public.catalog_test_error(format('select public.ai_catalog_dossier(%L)',hidden_bridge),'NOT_FOUND','reader cannot open private dossier');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',unit_id,public.dossier_test_input('contact','Denied reader child')),'FORBIDDEN','reader cannot create contextual record');
 -- A canonical use case can reach the unit through a local demand without expanding that unit.
 d:=public.ai_catalog_dossier(hidden_case);
 perform public.catalog_test_assert(not public.dossier_test_has(d,unit_id),'reader cannot reach unit through hidden demand in use-case dossier');
 d:=public.ai_catalog_dossier(partner_id);
 perform public.catalog_test_assert(public.dossier_test_has(d,item_id) and public.dossier_test_has(d,unit_id),'partner dossier contains agreement items and agreement unit');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
 d:=public.ai_catalog_dossier(hidden_case);
 perform public.catalog_test_assert(public.dossier_test_has(d,unit_id),'creator reaches unit through readable demand');
 child:=public.ai_catalog_create_related(unit_id,public.dossier_test_input('contact','Created in unit'),'unit','to-parent');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_get((child->>'id')::uuid)->'links') l where l->>'source_id'=child->>'id' and l->>'target_id'=unit_id::text and l->>'relation'='unit'),'contextual child creation inserts typed child-to-parent relation');
 child:=public.ai_catalog_create_related(engagement_id,public.dossier_test_input('contact','Created participant'),'participant','from-parent');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_get(engagement_id)->'links') l where l->>'source_id'=engagement_id::text and l->>'target_id'=child->>'id' and l->>'relation'='participant'),'contextual creation supports parent-to-child participant direction');
 baseline:=(public.ai_catalog_list(null,'Rollback child')->>'total')::int;
 rel_baseline:=jsonb_array_length(public.ai_catalog_get(unit_id)->'links');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''speaker'',''to-parent'')',unit_id,public.dossier_test_input('contact','Rollback child')),'VALIDATION','incompatible contextual relation fails');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''not-a-relation'',''to-parent'')',unit_id,public.dossier_test_input('contact','Rollback child')),'VALIDATION','unknown contextual relation fails');
 perform public.catalog_test_assert((public.ai_catalog_list(null,'Rollback child')->>'total')::int=baseline and jsonb_array_length(public.ai_catalog_get(unit_id)->'links')=rel_baseline,'failed relation rolls back created record and leaves no orphan links');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''sideways'')',unit_id,public.dossier_test_input('contact','Rollback child')),'VALIDATION','malformed contextual direction rejected');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',unit_id,child),'VALIDATION','contextual creation rejects updating an existing record');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,''null'',''unit'',''to-parent'')',unit_id),'VALIDATION','null contextual record rejected');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',archived_bridge,public.dossier_test_input('contact','Rollback child')),'VALIDATION: archived record','archived contextual parent rejected');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',gen_random_uuid(),public.dossier_test_input('contact','Rollback child')),'NOT_FOUND','missing contextual parent rejected');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
 parent_id:=public.dossier_test_record('unit','Private admin unit','private');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',parent_id,public.dossier_test_input('contact','Rollback child')),'NOT_FOUND','editor cannot create child for another users private parent');
 perform public.catalog_test_assert((public.ai_catalog_list(null,'Rollback child')->>'total')::int=baseline,'all rejected contextual creates leave no orphan records');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',true);
 perform public.catalog_test_error(format('select public.ai_catalog_dossier(%L)',unit_id),'FORBIDDEN','nonmember cannot read dossier');
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''unit'',''to-parent'')',unit_id,public.dossier_test_input('contact','Denied nonmember child')),'FORBIDDEN','nonmember cannot create related record');
end $$;
-- Execute every action declared by the UI, without duplicating its relation rules.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare configuration record; section jsonb; action jsonb; parent_id uuid; child jsonb; detail jsonb; source_id text; target_id text;
begin
 for configuration in select * from jsonb_each((select config from dossier_test_sections)) loop
  for section in select * from jsonb_array_elements(configuration.value) loop
   for action in select * from jsonb_array_elements(section->'actions') loop
    -- A unit as an activity's executing party needs a later migration; activity-provider-checks covers it.
    continue when action->>'kind'='unit' and action->>'relation'='partner';
    -- Work items arrive with a later migration; work-item-checks covers their actions.
    continue when configuration.key='work_item' or action->>'kind'='work_item';
    parent_id:=public.dossier_test_record(configuration.key,'Action contract parent '||configuration.key);
    child:=public.ai_catalog_create_related(parent_id,public.dossier_test_input(action->>'kind','Action contract child'),action->>'relation',action->>'direction');
    source_id:=case when action->>'direction'='to-parent' then child->>'id' else parent_id::text end;
    target_id:=case when action->>'direction'='to-parent' then parent_id::text else child->>'id' end;
    detail:=public.ai_catalog_get((child->>'id')::uuid);
    perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(detail->'links') l where l->>'source_id'=source_id and l->>'target_id'=target_id and l->>'relation'=action->>'relation'),
      'UI contextual action succeeds: '||configuration.key||'/'||(section->>'id')||'/'||(action->>'kind')||'/'||(action->>'relation')||'/'||(action->>'direction'));
   end loop;
  end loop;
 end loop;
end $$;
reset role;
rollback;
