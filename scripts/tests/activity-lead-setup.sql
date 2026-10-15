\set ON_ERROR_STOP on
-- Legacy type labels and an untyped consortium, as the survey import left them.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare consortium uuid; member uuid;
begin
 perform public.ai_catalog_save('{"kind":"collaboration","title":"Hoạt động nhãn cũ","status":"POC","visibility":"team","data":{"cooperation_types":"PoC / thử nghiệm"}}');
 consortium := (public.ai_catalog_save('{"kind":"partner","title":"Liên danh chưa phân loại","status":"Tiềm năng","visibility":"team","data":{}}')->>'id')::uuid;
 member := (public.ai_catalog_save('{"kind":"partner","title":"Thành viên chưa phân loại","status":"Tiềm năng","visibility":"team","data":{"partner_type":"Viện/trường"}}')->>'id')::uuid;
 perform public.ai_catalog_consortium_link(jsonb_build_object('source_id',consortium,'target_id',member,'relation','partner','context',jsonb_build_object('consortium_role','member')));
end $$;
reset role;
