\set ON_ERROR_STOP on
-- Deleting a unit deletes its own contacts; a contact shared with a partner stays with the partner.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare unit uuid; partner uuid; own uuid; shared uuid; version integer;
begin
 unit := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị bị xoá","status":"Đang hoạt động","data":{"unit_type":"Đơn vị thành viên"}}')->>'id')::uuid;
 partner := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác còn lại","status":"Tiềm năng","data":{}}')->>'id')::uuid;
 own := (public.ai_catalog_save('{"kind":"contact","title":"Đầu mối riêng","status":"Còn hiệu lực","data":{}}')->>'id')::uuid;
 shared := (public.ai_catalog_save('{"kind":"contact","title":"Đầu mối dùng chung","status":"Còn hiệu lực","data":{}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',own,'target_id',unit,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',shared,'target_id',unit,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',partner,'target_id',shared,'relation','contact'));
 version := (public.ai_catalog_get(unit)->'data'->>'version')::integer;
 perform public.ai_catalog_delete(unit,version);
end $$;
reset role;
select public.catalog_test_assert(not exists(select 1 from ai_management.records where title='Đầu mối riêng'),'a unit''s own contact goes with it');
select public.catalog_test_assert(exists(select 1 from ai_management.audit a where a.action='delete_with_organisation' and a.before_value->'record'->>'title'='Đầu mối riêng'),'the contact is snapshotted');
select public.catalog_test_assert(exists(select 1 from ai_management.records where title='Đầu mối dùng chung'),'a contact shared with a partner stays');
