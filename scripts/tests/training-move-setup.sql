\set ON_ERROR_STOP on
-- A workshop with a speaker and an organising unit, and the work item it belongs to.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$ declare event jsonb; expert jsonb; unit jsonb;
begin
 perform public.ai_catalog_save('{"kind":"work_item","title":"Hội thảo chia sẻ kinh nghiệm","status":"Đang thực hiện","data":{"item_group":"Nhân lực, đào tạo"}}');
 event:=public.ai_catalog_save('{"kind":"learning_event","title":"Hội thảo chuyển đổi","status":"Đã tổ chức","data":{"event_type":"Hội thảo","topic":"Chia sẻ kinh nghiệm AI","location":"18 Láng Hạ","reported_attendees":150,"start_date":"2026-03-26","end_date":"2026-03-26"}}');
 expert:=public.ai_catalog_save('{"kind":"expert","title":"Diễn giả hội thảo","status":"Đã trao đổi","data":{}}');
 unit:=public.ai_catalog_save('{"kind":"unit","title":"Đơn vị tổ chức hội thảo","status":"Đang hoạt động","data":{"unit_type":"Đơn vị thành viên"}}');
 perform public.ai_catalog_link(jsonb_build_object('source_id',event->>'id','target_id',expert->>'id','relation','speaker'));
 perform public.ai_catalog_link(jsonb_build_object('source_id',event->>'id','target_id',unit->>'id','relation','organizer'));
end $$;
reset role;
