-- Reproduce the old importer shape only in the disposable database.
reset role;
reset request.jwt.claim.sub;
insert into ai_management.records(id,kind,title,status,visibility,created_by) values
 ('88000000-0000-4000-8000-000000000001','partner','Verified consortium','Chưa xác minh','team','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000002','partner','Known member','Chưa xác minh','team','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000003','collaboration','Consortium content','Đang trao đổi','team','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000004','engagement','Expert-only meeting','Đã diễn ra','team','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000005','collaboration','Unresolved content','Đang trao đổi','team','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000006','partner','Unrepresented member','Chưa xác minh','team','10000000-0000-4000-8000-000000000001');
insert into ai_management.partner_details(record_id) values('88000000-0000-4000-8000-000000000001'),('88000000-0000-4000-8000-000000000002'),('88000000-0000-4000-8000-000000000006');
insert into ai_management.collaboration_details(record_id) values('88000000-0000-4000-8000-000000000003'),('88000000-0000-4000-8000-000000000005');
insert into ai_management.engagement_details(record_id) values('88000000-0000-4000-8000-000000000004');
alter table ai_management.relations disable trigger collaboration_relation_cardinality;
insert into ai_management.relations(source_id,target_id,relation,note,context,created_by) values
 ('88000000-0000-4000-8000-000000000001','88000000-0000-4000-8000-000000000002','partner','Authoritative consortium role','{"consortium_role":"lead"}','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000003','88000000-0000-4000-8000-000000000001','partner',null,'{}','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000003','88000000-0000-4000-8000-000000000002','partner','Thành viên liên danh – cần xác minh vai trò','{}','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000005','88000000-0000-4000-8000-000000000001','partner',null,'{}','10000000-0000-4000-8000-000000000001'),
 ('88000000-0000-4000-8000-000000000005','88000000-0000-4000-8000-000000000006','partner','Thành viên liên danh – cần xác minh vai trò','{}','10000000-0000-4000-8000-000000000001');
alter table ai_management.relations enable trigger collaboration_relation_cardinality;
