-- Fixtures intentionally exist before the flattening migration.
insert into auth.users(id) values('90000000-0000-4000-8000-000000000001');
insert into ai_management.memberships(user_id,role) values('90000000-0000-4000-8000-000000000001','admin');
insert into ai_management.records(id,kind,title,status,visibility,created_by) values
 ('90000000-0000-4000-8000-000000000010','partner','Migration partner','Chưa xác minh','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000011','unit','Migration unit','Đang hoạt động','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000012','collaboration','Migration container','Đang thực hiện','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000013','collaboration_item','Migration item','Đề xuất','team','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000014','engagement','Migration milestone','Đã diễn ra','team','90000000-0000-4000-8000-000000000001');
insert into ai_management.partner_details(record_id) values('90000000-0000-4000-8000-000000000010');
insert into ai_management.unit_details(record_id) values('90000000-0000-4000-8000-000000000011');
insert into ai_management.collaboration_details(record_id,scope) values('90000000-0000-4000-8000-000000000012','Container scope');
insert into ai_management.collaboration_item_details(record_id,item_type,scope,results) values('90000000-0000-4000-8000-000000000013','POC','Item scope','Item result');
insert into ai_management.engagement_details(record_id,conclusions) values('90000000-0000-4000-8000-000000000014','Milestone result');
insert into ai_management.relations(source_id,target_id,relation,created_by) values
 ('90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000010','partner','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000012','90000000-0000-4000-8000-000000000011','unit','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000013','90000000-0000-4000-8000-000000000012','parent','90000000-0000-4000-8000-000000000001'),
 ('90000000-0000-4000-8000-000000000014','90000000-0000-4000-8000-000000000013','collaboration','90000000-0000-4000-8000-000000000001');
