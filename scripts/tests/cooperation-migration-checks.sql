do $$
begin
 if not (select kind='collaboration' and status='Tiềm năng' and version=2 from ai_management.records where id='90000000-0000-4000-8000-000000000013') then raise exception 'FAILED: legacy item becomes one-level cooperation content'; end if;
 raise notice 'PASS: legacy item becomes one-level cooperation content with mapped status';
 if not (select scope='Item scope' and results='Item result' and cooperation_types='PoC / thử nghiệm' from ai_management.collaboration_details where record_id='90000000-0000-4000-8000-000000000013') then raise exception 'FAILED: legacy detail conversion'; end if;
 raise notice 'PASS: legacy item detail becomes cooperation content detail';
 if exists(select 1 from ai_management.collaboration_item_details where record_id='90000000-0000-4000-8000-000000000013') or exists(select 1 from ai_management.relations where source_id='90000000-0000-4000-8000-000000000013' and relation='parent') then raise exception 'FAILED: retired nesting remains'; end if;
 raise notice 'PASS: retired nesting detail and parent edge are removed';
 if not exists(select 1 from ai_management.relations where source_id='90000000-0000-4000-8000-000000000013' and target_id='90000000-0000-4000-8000-000000000010' and relation='partner') or not exists(select 1 from ai_management.relations where source_id='90000000-0000-4000-8000-000000000013' and target_id='90000000-0000-4000-8000-000000000011' and relation='unit') then raise exception 'FAILED: inherited context'; end if;
 raise notice 'PASS: converted content inherits partner and PVN subject';
 if not exists(select 1 from ai_management.audit where record_id='90000000-0000-4000-8000-000000000013' and action='normalize_cooperation_content') then raise exception 'FAILED: normalization audit'; end if;
 raise notice 'PASS: normalization is auditable';
 if not exists(select 1 from ai_management.relations where source_id='90000000-0000-4000-8000-000000000014' and target_id='90000000-0000-4000-8000-000000000010' and relation='partner') then raise exception 'FAILED: milestone partner inheritance'; end if;
 raise notice 'PASS: milestone inherits an unambiguous partner from cooperation content';
end $$;

set role authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000001',false);
do $$
declare report jsonb;
begin
 report:=public.ai_catalog_partner_review();
 if report->>'remaining_legacy_items'<>'0'
    or jsonb_array_length(report->'cooperation_contents_without_one_partner')<>0
    or jsonb_array_length(report->'cooperation_contents_with_multiple_use_cases')<>0
    or jsonb_array_length(report->'cooperation_contents_with_multiple_lead_units')<>0
    or jsonb_array_length(report->'milestones_without_partner')<>0 then
  raise exception 'FAILED: partner reconciliation report';
 end if;
 raise notice 'PASS: partner reconciliation report covers migrated content and milestones';
end $$;
reset role;
reset request.jwt.claim.sub;

insert into ai_management.records(id,kind,title,status,visibility,created_by) values
 ('90000000-0000-4000-8000-000000000015','partner','Second migration partner','Chưa xác minh','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000016','unit','Second migration unit','Đang hoạt động','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000017','use_case','Migration use case one','Chưa xác minh','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000018','use_case','Migration use case two','Chưa xác minh','team','90000000-0000-4000-8000-000000000001');
insert into ai_management.partner_details(record_id) values('90000000-0000-4000-8000-000000000015');
insert into ai_management.unit_details(record_id) values('90000000-0000-4000-8000-000000000016');
insert into ai_management.use_case_details(record_id) values('90000000-0000-4000-8000-000000000017'),('90000000-0000-4000-8000-000000000018');
insert into ai_management.relations(source_id,target_id,relation,context,created_by) values
 ('90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000017','use_case','{}','90000000-0000-4000-8000-000000000001');
update ai_management.relations set context='{"subject_role":"lead"}'
where source_id='90000000-0000-4000-8000-000000000013' and target_id='90000000-0000-4000-8000-000000000011' and relation='unit';

do $$
begin
 begin
  insert into ai_management.relations(source_id,target_id,relation,created_by) values('90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000015','partner','90000000-0000-4000-8000-000000000001');
  raise exception 'FAILED: second partner accepted';
 exception when sqlstate '22023' then raise notice 'PASS: cooperation content rejects a second partner'; end;
 begin
  insert into ai_management.relations(source_id,target_id,relation,created_by) values('90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000018','use_case','90000000-0000-4000-8000-000000000001');
  raise exception 'FAILED: second use case accepted';
 exception when sqlstate '22023' then raise notice 'PASS: cooperation content rejects a second use case'; end;
 begin
  insert into ai_management.relations(source_id,target_id,relation,context,created_by) values('90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000016','unit','{"subject_role":"lead"}','90000000-0000-4000-8000-000000000001');
  raise exception 'FAILED: second lead PVN subject accepted';
 exception when sqlstate '22023' then raise notice 'PASS: cooperation content rejects a second lead PVN subject'; end;
end $$;

set role authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000001',false);
do $$
declare linked jsonb; detail jsonb;
begin
 linked:=public.ai_catalog_collaboration_unit_link(jsonb_build_object(
  'source_id','90000000-0000-4000-8000-000000000013',
  'target_id','90000000-0000-4000-8000-000000000016',
  'relation','unit','context',jsonb_build_object('subject_role','lead')));
 detail:=public.ai_catalog_get('90000000-0000-4000-8000-000000000013');
 if linked->'context'->>'subject_role'<>'lead'
    or not exists(select 1 from jsonb_array_elements(detail->'links') item
      where item->>'source_id'='90000000-0000-4000-8000-000000000013'
       and item->>'target_id'='90000000-0000-4000-8000-000000000011'
       and item->>'relation'='unit' and item->'context'->>'subject_role'='supporting') then
  raise exception 'FAILED: atomic PVN lead reassignment';
 end if;
 raise notice 'PASS: cooperation lead PVN subject is reassigned atomically';
 begin
  perform public.ai_catalog_create_related_context(
   '90000000-0000-4000-8000-000000000016',
   '{"kind":"collaboration","title":"Invalid standalone content","status":"Tiềm năng","visibility":"team","data":{}}'::jsonb,
   'unit','to-parent','{}'::jsonb);
  raise exception 'FAILED: partnerless contextual cooperation accepted';
 exception when sqlstate '22023' then raise notice 'PASS: cooperation content requires partner creation context'; end;
end $$;
reset role;
reset request.jwt.claim.sub;

-- Keep the remaining regression suite isolated from these migration fixtures.
alter table ai_management.audit disable trigger ai_catalog_audit_immutable;
delete from ai_management.audit where record_id in ('90000000-0000-4000-8000-000000000010','90000000-0000-4000-8000-000000000011','90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000014');
alter table ai_management.audit enable trigger ai_catalog_audit_immutable;
delete from ai_management.relations where source_id in ('90000000-0000-4000-8000-000000000010','90000000-0000-4000-8000-000000000011','90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000014','90000000-0000-4000-8000-000000000015','90000000-0000-4000-8000-000000000016','90000000-0000-4000-8000-000000000017','90000000-0000-4000-8000-000000000018') or target_id in ('90000000-0000-4000-8000-000000000010','90000000-0000-4000-8000-000000000011','90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000014','90000000-0000-4000-8000-000000000015','90000000-0000-4000-8000-000000000016','90000000-0000-4000-8000-000000000017','90000000-0000-4000-8000-000000000018');
delete from ai_management.collaboration_details where record_id in ('90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000013');
delete from ai_management.engagement_details where record_id='90000000-0000-4000-8000-000000000014';
delete from ai_management.partner_details where record_id='90000000-0000-4000-8000-000000000010';
delete from ai_management.partner_details where record_id='90000000-0000-4000-8000-000000000015';
delete from ai_management.unit_details where record_id in ('90000000-0000-4000-8000-000000000011','90000000-0000-4000-8000-000000000016');
delete from ai_management.use_case_details where record_id in ('90000000-0000-4000-8000-000000000017','90000000-0000-4000-8000-000000000018');
delete from ai_management.records where id in ('90000000-0000-4000-8000-000000000010','90000000-0000-4000-8000-000000000011','90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000014','90000000-0000-4000-8000-000000000015','90000000-0000-4000-8000-000000000016','90000000-0000-4000-8000-000000000017','90000000-0000-4000-8000-000000000018');
delete from ai_management.memberships where user_id='90000000-0000-4000-8000-000000000001';
delete from auth.users where id='90000000-0000-4000-8000-000000000001';
