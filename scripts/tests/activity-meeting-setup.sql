\set ON_ERROR_STOP on
-- An activity with a typed meeting date and next step, linked to a partner and a source.
insert into ai_management.records(id,kind,title,status,created_by) values
 ('71000000-0000-4000-8000-000000000001','collaboration','Hoạt động có ngày họp',(select statuses[1] from ai_management.module_registry where kind='collaboration'),'10000000-0000-4000-8000-000000000002'),
 ('71000000-0000-4000-8000-000000000002','partner','Đối tác có buổi họp',(select statuses[1] from ai_management.module_registry where kind='partner'),'10000000-0000-4000-8000-000000000002');
insert into ai_management.collaboration_details(record_id,item_group,results,next_notes,last_meeting_date) values('71000000-0000-4000-8000-000000000001',(select item_group from ai_management.collaboration_details limit 1),'Đã demo','Chọn PoC','2026-08-24');
insert into ai_management.partner_details(record_id) values('71000000-0000-4000-8000-000000000002');
insert into ai_management.relations(source_id,target_id,relation,created_by) values('71000000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000002','partner','10000000-0000-4000-8000-000000000002');
