\set ON_ERROR_STOP on
select public.catalog_test_assert((select archived_at is not null from ai_management.records where kind='partner' and title='NBTH'),'a partner record duplicating a unit is archived');
select public.catalog_test_assert(exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id join ai_management.records u on u.id=l.target_id
  where a.title='NBTH · NBDH' and l.relation='partner' and u.kind='unit' and u.title='Đơn vị thực hiện nội bộ'),'the activity now names the unit as its executing party');
select public.catalog_test_assert(exists(select 1 from ai_management.audit a join ai_management.records r on r.id=a.record_id where r.title='NBTH' and a.action='fold_partner_into_unit'),'folding the partner is audited');
begin;
select set_config('test.provider',(select id::text from ai_management.records where kind='unit' and title='Đơn vị thực hiện nội bộ'),true);
select set_config('test.folded',(select id::text from ai_management.records where title='NBTH · NBDH'),true);
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare provider uuid; standard uuid; partner uuid; activity uuid; overview jsonb; folded uuid;
begin
 provider := current_setting('test.provider')::uuid;
 folded := current_setting('test.folded')::uuid;
 overview := public.ai_catalog_overview();
 perform public.catalog_test_assert(exists(select 1 from jsonb_array_elements(overview->'activities') a where a->>'id'=folded::text and a->>'provider_unit_id'=provider::text and a->>'partner_id' is null),'a unit carrying out an activity is reported apart from partners');
 activity := (public.ai_catalog_save('{"kind":"collaboration","title":"Hoạt động do đơn vị thực hiện","status":"Đề xuất","visibility":"team","data":{}}')->>'id')::uuid;
 standard := (public.ai_catalog_save('{"kind":"use_case","title":"Bài toán chuẩn đối chiếu","status":"Chính thức","visibility":"team","data":{}}')->>'id')::uuid;
 partner := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác đối chiếu","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',activity,'target_id',provider,'relation','partner'));
 perform public.catalog_test_error(format('select public.ai_catalog_link(%L::jsonb)',jsonb_build_object('source_id',activity,'target_id',partner,'relation','partner')::text),'VALIDATION','an activity keeps one executing party, partner or unit');
 perform public.catalog_test_error(format('select public.ai_catalog_link(%L::jsonb)',jsonb_build_object('source_id',standard,'target_id',provider,'relation','partner')::text),'VALIDATION','only an activity takes a unit as its executing party');
 perform public.catalog_test_assert(not exists(select 1 from jsonb_array_elements(public.ai_catalog_overview()->'partners') p where p->>'id'=provider::text),'units stay out of the partner catalogue');
end $$;
reset role;
rollback;
