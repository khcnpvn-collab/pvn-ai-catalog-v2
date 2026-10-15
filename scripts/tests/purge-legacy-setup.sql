\set ON_ERROR_STOP on
-- A legacy data asset and an archived activity, both linked to a kept unit and a source snapshot.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare unit uuid; asset uuid; archived uuid; kept uuid;
begin
 unit := (public.ai_catalog_save('{"kind":"unit","title":"Đơn vị giữ lại khi dọn","status":"Đang hoạt động","visibility":"team","data":{"abbreviation":"DGL"}}')->>'id')::uuid;
 asset := (public.ai_catalog_save('{"kind":"data_asset","title":"CSDL cũ cần dọn","status":"Chưa xác minh","visibility":"team","data":{"owner":"Ban dữ liệu"}}')->>'id')::uuid;
 archived := (public.ai_catalog_save('{"kind":"collaboration","title":"Hoạt động đã gỡ cần dọn","status":"Đề xuất","visibility":"team","data":{}}')->>'id')::uuid;
 kept := (public.ai_catalog_save('{"kind":"collaboration","title":"Hoạt động giữ lại khi dọn","status":"Đề xuất","visibility":"team","data":{}}')->>'id')::uuid;
 perform public.ai_catalog_link(jsonb_build_object('source_id',asset,'target_id',unit,'relation','unit'));
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',archived,'target_id',unit,'relation','unit','context',jsonb_build_object('subject_role','lead')));
 perform public.ai_catalog_collaboration_unit_link(jsonb_build_object('source_id',kept,'target_id',unit,'relation','unit','context',jsonb_build_object('subject_role','lead')));
end $$;
reset role;
update ai_management.records set archived_at=now() where title='Hoạt động đã gỡ cần dọn';
insert into ai_management.sources(source_key,source_type,title,payload,status,linked_record_id,created_by)
select 'purge-legacy-fixture','survey_data_asset','Bản nguồn CSDL cũ','{"ten":"CSDL cũ cần dọn"}','linked',id,'10000000-0000-4000-8000-000000000001' from ai_management.records where title='CSDL cũ cần dọn';
insert into ai_management.source_links(source_id,record_id,created_by)
select s.id,s.linked_record_id,s.created_by from ai_management.sources s where s.source_key='purge-legacy-fixture';
create table public.purge_fixture as select id,title from ai_management.records where title in ('CSDL cũ cần dọn','Hoạt động đã gỡ cần dọn');
