-- A survey container and its former item have identical source and business scope.
insert into ai_management.records(id,kind,title,code,status,visibility,version,created_by) values
 ('91000000-0000-4000-8000-000000000001','collaboration','Survey cooperation','KS-COLLABORATION-auditexample','Đang thực hiện','team',1,'10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000002','collaboration','Former survey item','KS-COLLABORATION_ITEM-auditexample','Chưa xác minh','team',2,'10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000004','unit','Survey subject','TEST-UNIT-DEDUP','Đang hoạt động','team',1,'10000000-0000-4000-8000-000000000001');
insert into ai_management.unit_details(record_id) values('91000000-0000-4000-8000-000000000004');
insert into ai_management.collaboration_details(record_id,scope,cooperation_types,source_status) values
 ('91000000-0000-4000-8000-000000000001','Shared source scope',null,null),
 ('91000000-0000-4000-8000-000000000002','Shared source scope','Khác','Chưa xác minh');
insert into ai_management.sources(id,source_key,source_type,title,payload,status,linked_record_id,created_by) values
 ('91000000-0000-4000-8000-000000000003','deduplication-test-source','survey_partner','Survey cooperation','{}'::jsonb,'linked','91000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001');
insert into ai_management.source_links(source_id,record_id,created_by) values
 ('91000000-0000-4000-8000-000000000003','91000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000003','91000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001');
insert into ai_management.relations(source_id,target_id,relation,created_by) values
 ('91000000-0000-4000-8000-000000000001','88000000-0000-4000-8000-000000000001','partner','10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000002','88000000-0000-4000-8000-000000000001','partner','10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000001','91000000-0000-4000-8000-000000000004','unit','10000000-0000-4000-8000-000000000001'),
 ('91000000-0000-4000-8000-000000000002','91000000-0000-4000-8000-000000000004','unit','10000000-0000-4000-8000-000000000001');
