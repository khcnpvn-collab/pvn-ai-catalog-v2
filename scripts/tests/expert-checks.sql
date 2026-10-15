\set ON_ERROR_STOP on
begin;
reset role;
create temporary table expert_test_registry as select * from ai_management.module_registry;
grant select on expert_test_registry to authenticated;
create function public.expert_test_input(k text,label text,visibility text default 'team') returns jsonb
language sql security definer set search_path='' as $$
 select jsonb_build_object('kind',k,'title',label,'status',statuses[1],'visibility',visibility,'data','{}'::jsonb)
 from ai_management.module_registry where kind=k
$$;
create function public.expert_test_record(k text,label text,visibility text default 'team') returns uuid
language sql as $$ select (public.ai_catalog_save(public.expert_test_input(k,label,visibility))->>'id')::uuid $$;
create function public.expert_test_link(s uuid,t uuid,rel text) returns void language plpgsql as $$
begin perform public.ai_catalog_link(jsonb_build_object('source_id',s,'target_id',t,'relation',rel)); end $$;
create function public.expert_test_has(d jsonb,id uuid) returns boolean language sql as $$
 select exists(select 1 from jsonb_array_elements(d->'related') e where e->'record'->>'id'=id::text)
$$;
select public.catalog_test_assert((select count(*)=4 and bool_and(c.relrowsecurity) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='ai_management' and c.relname in ('expert_details','affiliation_details','expertise_details','reference_details')),'all four added detail tables enforce RLS');
-- The registry/UI contract is asserted after the latest migration in ui-contract-checks.sql.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare k text; kind_record record; field jsonb; input jsonb; child jsonb; detail jsonb; updated jsonb; parent_id uuid;
 expert_id uuid; expert_other uuid; private_expert uuid; unit_id uuid; partner_id uuid; other_unit uuid;
 affiliation_id uuid; hidden_affiliation uuid; archived_affiliation uuid; hidden_target uuid; archived_target uuid;
 engagement_id uuid; collaboration_id uuid; reference_id uuid; expertise_id uuid; excluded_reference uuid; excluded_expertise uuid;
 colleague_id uuid; colleague_affiliation uuid; unrelated_engagement uuid; doc_id uuid; engagement_reference uuid; collaboration_reference uuid; private_reference uuid; projection jsonb; prior_count integer;
begin
 -- The existing typed-roundtrip suite populates all new and extended fields. Here verify rejection contracts.
 for kind_record in select * from expert_test_registry where kind in ('expert','affiliation','expertise','reference','partner','contact','collaboration','engagement') loop
  input:=public.expert_test_input(kind_record.kind,'Expert validation fixture');
  perform public.catalog_test_error(format('select public.ai_catalog_save(%L)',input||jsonb_build_object('data',jsonb_build_object('unknown_field','x'))),'VALIDATION','new/extended kind rejects unknown fields: '||kind_record.kind);
  for field in select * from jsonb_array_elements(kind_record.fields) where value->>'type' in ('url','email','date','number','select') loop
   perform public.catalog_test_error(format('select public.ai_catalog_save(%L)',input||jsonb_build_object('data',jsonb_build_object(field->>'key',case field->>'type' when 'url' then 'javascript:alert(1)' when 'email' then 'invalid-email' when 'date' then '2026-02-30' when 'number' then '-1' else 'not-an-option' end))),'VALIDATION','typed rejection '||kind_record.kind||'.'||(field->>'key'));
  end loop;
 end loop;
 expert_id:=public.expert_test_record('expert','Expert subject');
 perform public.catalog_test_assert(public.ai_catalog_get(expert_id)->'data'->'data'->'contact_consent'='null'::jsonb,'new expert has no inferred contact consent');
 child:=public.ai_catalog_save(public.expert_test_input('reference','Partial date reference')||'{"data":{"date_note":"Quý I/2026"}}'::jsonb);
 perform public.catalog_test_assert(child->'data'->>'date_note'='Quý I/2026' and child->'data'->'document_date'='null'::jsonb,'reference preserves partial date without inventing exact day');
 expert_other:=public.expert_test_record('expert','Other expert');
 private_expert:=public.expert_test_record('expert','Private expert','private');
 unit_id:=public.expert_test_record('unit','Expert affiliated unit');
 partner_id:=public.expert_test_record('partner','Expert partner');
 other_unit:=public.expert_test_record('unit','Unrelated unit');
 child:=public.ai_catalog_create_related(partner_id,public.expert_test_input('expert','Context expert'),'expert','from-parent');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(partner_id),(child->>'id')::uuid),'partner contextual creation inserts readable expert relation');
 child:=public.ai_catalog_create_related(expert_id,public.expert_test_input('affiliation','Employment link'),'expert','to-parent');
 affiliation_id:=(child->>'id')::uuid;
 perform public.expert_test_link(affiliation_id,unit_id,'unit');
 child:=public.ai_catalog_create_related(expert_id,public.expert_test_input('expertise','Individual competency'),'expert','to-parent');
 expertise_id:=(child->>'id')::uuid;
 child:=public.ai_catalog_create_related(expert_id,public.expert_test_input('reference','Reference metadata'),'expert','to-parent');
 reference_id:=(child->>'id')::uuid;
 perform public.catalog_test_error(format('select public.ai_catalog_link(%L)',jsonb_build_object('source_id',expertise_id,'target_id',expert_other,'relation','expert')),'VALIDATION: record already assigned','competency cannot be owned by a second expert');
 perform public.catalog_test_error(format('select public.ai_catalog_link(%L)',jsonb_build_object('source_id',affiliation_id,'target_id',expert_other,'relation','expert')),'VALIDATION: record already assigned','affiliation cannot be owned by a second expert');
 perform public.expert_test_link(reference_id,expert_other,'expert');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(expert_other),reference_id),'reference may be shared by multiple experts');
 projection:=public.ai_catalog_dossier(expert_id);
 perform public.catalog_test_assert(public.expert_test_has(projection,affiliation_id) and public.expert_test_has(projection,expertise_id) and public.expert_test_has(projection,reference_id),'expert contextual supporting records appear directly');
 perform public.catalog_test_assert(public.expert_test_has(projection,unit_id),'expert dossier reaches organization through own affiliation');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(unit_id),expert_id),'organization reaches expert through affiliation');
 -- An organizational or expert endpoint must never become a bridge into another dossier.
 colleague_id:=public.expert_test_record('expert','Same organization colleague');
 colleague_affiliation:=public.expert_test_record('affiliation','Colleague affiliation');
 perform public.expert_test_link(colleague_affiliation,colleague_id,'expert');
 perform public.expert_test_link(colleague_affiliation,unit_id,'unit');
 perform public.expert_test_link(expert_id,unit_id,'unit');
 unrelated_engagement:=public.expert_test_record('engagement','Colleague meeting');
 perform public.expert_test_link(unrelated_engagement,colleague_id,'expert');
 perform public.expert_test_link(expert_id,expert_other,'related');
 perform public.expert_test_link(expert_other,other_unit,'unit');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(expert_id),colleague_id) and not public.expert_test_has(public.ai_catalog_dossier(expert_id),other_unit),'expert dossier never fans out through organization or another expert');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(unit_id),unrelated_engagement),'organization never fans out through affiliated expert to other engagements');
 -- Supporting competency and reference records are leaves, even when cross-linked.
 excluded_reference:=public.expert_test_record('partner','Reference-only unrelated partner');
 excluded_expertise:=public.expert_test_record('use_case','Competency-only unrelated case');
 perform public.expert_test_link(reference_id,excluded_reference,'related');
 perform public.expert_test_link(expertise_id,excluded_expertise,'use_case');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(expert_id),excluded_reference) and not public.expert_test_has(public.ai_catalog_dossier(expert_id),excluded_expertise),'expert dossier does not expand through reference or expertise leaves');
 -- Employment bridges only project expert <-> organization, not arbitrary root subjects.
 parent_id:=public.expert_test_record('use_case','Unrelated root subject');
 perform public.expert_test_link(affiliation_id,parent_id,'use_case');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(parent_id),expert_id) and not public.expert_test_has(public.ai_catalog_dossier(parent_id),unit_id),'affiliation cannot bridge from an unrelated subject');
 engagement_id:=public.expert_test_record('engagement','Expert working session');
 perform public.ai_catalog_link(jsonb_build_object('source_id',engagement_id,'target_id',expert_id,'relation','expert','context',jsonb_build_object('role','Cố vấn tại thời điểm trao đổi')));
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_get(engagement_id)->'links') l where l->>'target_id'=expert_id::text and l->'context'->>'role'='Cố vấn tại thời điểm trao đổi'),'expert relation preserves historical participation context');
 perform public.expert_test_link(engagement_id,private_expert,'expert');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(engagement_id),expert_id) and public.expert_test_has(public.ai_catalog_dossier(engagement_id),private_expert),'engagement keeps multiple expert participants');
 perform public.expert_test_link(engagement_id,other_unit,'unit');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(expert_id),other_unit),'expert reaches unit through directly associated engagement');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(other_unit),expert_id),'unit reaches participating expert through engagement');
 collaboration_id:=public.expert_test_record('collaboration','Expert cooperation');
 perform public.expert_test_link(collaboration_id,partner_id,'partner');
 perform public.expert_test_link(collaboration_id,expert_id,'expert');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(partner_id),expert_id),'partner reaches expert through cooperation');
 engagement_reference:=public.expert_test_record('reference','Meeting reference');
 collaboration_reference:=public.expert_test_record('reference','Cooperation reference');
 private_reference:=public.expert_test_record('reference','Private meeting reference','private');
 perform public.expert_test_link(engagement_reference,engagement_id,'related');
 perform public.expert_test_link(collaboration_reference,collaboration_id,'related');
 perform public.expert_test_link(private_reference,engagement_id,'related');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(expert_id),engagement_reference) and public.expert_test_has(public.ai_catalog_dossier(other_unit),engagement_reference),'engagement references roll up to its expert and unit');
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(partner_id),collaboration_reference),'cooperation references roll up to partner');
 -- Full relation whitelist: use real gateway checks rather than reproducing validation logic.
 foreach k in array array['partner','unit','use_case','collaboration','collaboration_item','engagement','affiliation','expertise','reference','learning_event','course','learning_session'] loop
  parent_id:=public.expert_test_record(k,'Expert relationship source '||k);
  perform public.expert_test_link(parent_id,expert_id,'expert');
  perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(parent_id),expert_id),'expert relation accepts source kind '||k);
 end loop;
 foreach k in array array['contact','demand','data_asset','implementation','poc','resource','expert'] loop
  parent_id:=public.expert_test_record(k,'Invalid expert relationship source '||k);
  perform public.catalog_test_error(format('select public.ai_catalog_link(%L)',jsonb_build_object('source_id',parent_id,'target_id',expert_id,'relation','expert')),'VALIDATION: incompatible','expert relation rejects source kind '||k);
 end loop;
 foreach k in array array['course','learning_event','learning_session','engagement'] loop
  parent_id:=public.expert_test_record(k,'Expert speaker source '||k);
  perform public.expert_test_link(parent_id,expert_id,'speaker');
  perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(parent_id),expert_id),'speaker relation supports expert from '||k);
  if k<>'course' then
   perform public.expert_test_link(parent_id,expert_id,'participant');
   perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(parent_id),expert_id),'participant relation supports expert from '||k);
  end if;
 end loop;
 -- Expert is an entity: its private/direct document library is not inherited by organizations.
 select (value->>'id')::uuid into doc_id from public.catalog_test_state where name='doc';
 perform public.ai_catalog_document_link(expert_id,doc_id,'20000000-0000-4000-8000-000000000001');
 perform public.ai_catalog_document_link(affiliation_id,doc_id,'20000000-0000-4000-8000-000000000002');
 projection:=public.ai_catalog_dossier(unit_id);
 perform public.catalog_test_assert(not exists(select 1 from jsonb_array_elements(projection->'attachments') a where a->'record'->>'id'=expert_id::text),'organization attachment aggregation excludes expert entity documents');
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(projection->'attachments') a where a->'record'->>'id'=affiliation_id::text and a->'document'->'versions'->0->>'version'='2'),'subordinate affiliation document retains its version pin');
 hidden_affiliation:=public.expert_test_record('affiliation','Hidden employment bridge','private');
 hidden_target:=public.expert_test_record('partner','Organization behind hidden employment');
 perform public.expert_test_link(hidden_affiliation,expert_id,'expert');
 perform public.expert_test_link(hidden_affiliation,hidden_target,'partner');
 archived_affiliation:=public.expert_test_record('affiliation','Archived employment bridge');
 archived_target:=public.expert_test_record('partner','Organization behind archived employment');
 perform public.expert_test_link(archived_affiliation,expert_id,'expert');
 perform public.expert_test_link(archived_affiliation,archived_target,'partner');
 perform public.ai_catalog_archive(archived_affiliation,1);
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(expert_id),archived_target),'archived affiliation does not project organization');
 updated:=public.ai_catalog_save(public.expert_test_input('expert','Updated expert')||jsonb_build_object('id',expert_id,'version',1));
 perform public.catalog_test_assert(updated->>'version'='2','expert updates preserve optimistic concurrency');
 perform public.catalog_test_error(format('select public.ai_catalog_save(%L)',public.expert_test_input('expert','Stale expert')||jsonb_build_object('id',expert_id,'version',1)),'CONFLICT','stale expert update rejected');
 prior_count:=(public.ai_catalog_list(null,'Rollback expert child')->>'total')::int;
 perform public.catalog_test_error(format('select public.ai_catalog_create_related(%L,%L,''expert'',''to-parent'')',expert_id,public.expert_test_input('expert','Rollback expert child')),'VALIDATION','invalid expert contextual link fails');
 perform public.catalog_test_assert((public.ai_catalog_list(null,'Rollback expert child')->>'total')::int=prior_count,'failed expert contextual create leaves no orphan');
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
 perform public.catalog_test_assert(public.expert_test_has(public.ai_catalog_dossier(expert_id),engagement_reference) and not public.expert_test_has(public.ai_catalog_dossier(expert_id),private_reference),'reader receives public rolled-up reference but never private reference');
 perform public.catalog_test_assert(public.ai_catalog_get(expert_id)->'data'->>'title'='Updated expert','reader can view team expert');
 perform public.catalog_test_error(format('select public.ai_catalog_get(%L)',private_expert),'NOT_FOUND','reader cannot view private expert');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(engagement_id),private_expert),'reader cannot see private expert endpoint in engagement');
 perform public.catalog_test_assert(not public.expert_test_has(public.ai_catalog_dossier(expert_id),hidden_target),'reader cannot cross private affiliation bridge');
 foreach k in array array['expert','affiliation','expertise','reference'] loop
  perform public.catalog_test_error(format('select public.ai_catalog_save(%L)',public.expert_test_input(k,'Denied reader '||k)),'FORBIDDEN','reader cannot create '||k);
  perform public.catalog_test_error('select * from ai_management.'||k||'_details','permission denied','no direct grants on '||k||' details');
 end loop;
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',true);
 perform public.catalog_test_error(format('select public.ai_catalog_dossier(%L)',expert_id),'FORBIDDEN','nonmember cannot open expert dossier');
end $$;
reset role;
rollback;
