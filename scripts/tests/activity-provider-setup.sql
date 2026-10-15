\set ON_ERROR_STOP on
-- A partner record that is really a PVN unit, as the survey created for "VPI · PQPOC".
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare provider uuid; client uuid; partner uuid; activity uuid;
begin
 provider := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị thực hiện nội bộ","status":"Đang hoạt động","visibility":"team","data":{"abbreviation":"NBTH"}}')->>'id')::uuid;
 client := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị đặt hàng nội bộ","status":"Đang hoạt động","visibility":"team","data":{"abbreviation":"NBDH"}}')->>'id')::uuid;
 partner := (public.ai_catalog_save('{"kind":"partner","title":"NBTH","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 activity := (public.ai_catalog_save('{"kind":"collaboration","title":"NBTH · NBDH","status":"Đang trao đổi","visibility":"team","data":{"cooperation_types":"Hợp tác đối tác"}}')->>'id')::uuid;
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',activity,'target_id',client,'relation','unit','context',jsonb_build_object('subject_role','lead')));
 perform public.ai_catalog_link(jsonb_build_object('source_id',activity,'target_id',partner,'relation','partner'));
end $$;
reset role;
