\set ON_ERROR_STOP on
-- A unit contact points to its unit; a partner points to its contact. Both appear with their organisation.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare unit uuid; partner uuid; unit_contact uuid; partner_contact uuid;
begin
 unit := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị danh bạ","status":"Đang hoạt động","data":{"abbreviation":"DVDB","unit_type":"Đơn vị thành viên"}}')->>'id')::uuid;
 partner := (public.ai_catalog_save('{"kind":"partner","title":"Đối tác danh bạ","status":"Tiềm năng","data":{"short_name":"DTDB"}}')->>'id')::uuid;
 unit_contact := (public.ai_catalog_save('{"kind":"contact","title":"Người của đơn vị","status":"Còn hiệu lực","data":{"email":"a@pvn.vn","phone":"0901234567"}}')->>'id')::uuid;
 partner_contact := (public.ai_catalog_save('{"kind":"contact","title":"Người của đối tác","status":"Còn hiệu lực","data":{"is_primary":"Có"}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',unit_contact,'target_id',unit,'relation','unit'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',partner,'target_id',partner_contact,'relation','contact'));
end $$;
select public.catalog_test_assert((select x->'orgs'->0->>'short' from jsonb_array_elements(public.ai_catalog_directory()->'contacts') x where x->>'title'='Người của đơn vị')='DVDB','a unit contact lists its unit');
select public.catalog_test_assert((select x->'orgs'->0->>'kind'||'|'||(x->>'is_primary') from jsonb_array_elements(public.ai_catalog_directory()->'contacts') x where x->>'title'='Người của đối tác')='partner|Có','a partner contact lists its partner');
select public.catalog_test_assert(jsonb_typeof(public.ai_catalog_directory()->'experts')='array','experts are listed');
set role anon;
select public.catalog_test_error('select public.ai_catalog_directory()','permission denied','anon cannot read the directory');
reset role;
