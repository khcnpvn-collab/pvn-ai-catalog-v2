-- Live-shape fixture for the identity decisions in migration 007.
insert into ai_management.records(id,kind,title,code,status,visibility,version,created_by,archived_at) values
 ('03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','partner','AWS','KS-PARTNER-8d16493c4ac3d5ca62e76588','Chưa xác minh','team',2,'10000000-0000-4000-8000-000000000001',null),
 ('07e5e5c6-c882-4152-8205-8cbc3c53d0d2','partner','Amazon Web Services (AWS)','KS-PARTNER-0eb9ef1206a4f1bb5fc16c76','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('9e647e63-2317-42a3-927f-f13952e94f92','partner','Microsoft','KS-PARTNER-5c627aade84c3248c647f4d0','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('639764d4-fc58-4e4c-9325-fce8a673bb05','partner','Google Cloud','WB-061ea40f-DT0034','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('e641a71b-7bd9-47f1-a548-9ab794887b70','partner','VNPT AI','WB-061ea40f-DT0066','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('7cc77334-99e8-4b3e-b048-9ddf250c82c4','partner','CMC OpenAI','KS-PARTNER-3c05d201c5c1858ab9a61040','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('41d76243-2459-4535-ab51-b6224ab5e690','partner','Microsoft, Google','KS-PARTNER-c80e3ee590c96d1f3e2e8e71','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('d0b7af77-170a-4c98-ab8b-ecd3b4978a97','partner','VNPT AI, CMC OpenAI','KS-PARTNER-fa7a5d077a1275bfc735e70b','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('c31f3b31-2e8c-4de4-8c70-c9830d3a1543','collaboration','Amazon · VPI','KS-COLLABORATION-ce5951b169d9d87bb2ff5f48','Tiềm năng','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('15b46894-c1b6-4974-a9f8-04f14f670c79','collaboration','Nội dung hợp tác Amazon · VPI','KS-COLLABORATION_ITEM-ce5951b169d9d87bb2ff5f48','Chưa xác minh','team',3,'10000000-0000-4000-8000-000000000001',now()),
 ('45e52554-413c-427d-909a-5273bfc15eae','collaboration','Microsoft, Google · NSRP · Trợ lý tra cứu và hỏi đáp tri thức nội bộ','KS-COLLABORATION-13201da6076860986bf24c8b','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('45370a72-d396-48bf-a637-7c8933a587d7','collaboration','VNPT AI, CMC OpenAI · PETROVIETNAM · AI tổng hợp báo cáo quản trị điều hành','KS-COLLABORATION-fbd3cacf7a4d53a55dbb2ae2','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('92000000-0000-4000-8000-000000000001','use_case','Trợ lý tra cứu và hỏi đáp tri thức nội bộ','TEST-IDENTITY-USECASE-1','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null),
 ('92000000-0000-4000-8000-000000000002','use_case','AI tổng hợp báo cáo quản trị điều hành','TEST-IDENTITY-USECASE-2','Chưa xác minh','team',1,'10000000-0000-4000-8000-000000000001',null);
insert into ai_management.partner_details(record_id,aliases,legal_name) values
 ('03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','Amazon','AWS'),
 ('07e5e5c6-c882-4152-8205-8cbc3c53d0d2','AWS',null),
 ('9e647e63-2317-42a3-927f-f13952e94f92',null,null),
 ('639764d4-fc58-4e4c-9325-fce8a673bb05',null,null),
 ('e641a71b-7bd9-47f1-a548-9ab794887b70',null,null),
 ('7cc77334-99e8-4b3e-b048-9ddf250c82c4',null,null),
 ('41d76243-2459-4535-ab51-b6224ab5e690','Microsoft, Google',null),
 ('d0b7af77-170a-4c98-ab8b-ecd3b4978a97','VNPT AI, CMC OpenAI',null);
insert into ai_management.collaboration_details(record_id,scope) values
 ('c31f3b31-2e8c-4de4-8c70-c9830d3a1543','AWS'),
 ('15b46894-c1b6-4974-a9f8-04f14f670c79','AWS'),
 ('45e52554-413c-427d-909a-5273bfc15eae','Trợ lý tra cứu và hỏi đáp tri thức nội bộ'),
 ('45370a72-d396-48bf-a637-7c8933a587d7','AI tổng hợp báo cáo quản trị điều hành');
insert into ai_management.use_case_details(record_id) values
 ('92000000-0000-4000-8000-000000000001'),('92000000-0000-4000-8000-000000000002');
insert into ai_management.sources(id,source_key,source_type,title,payload,status,linked_record_id,created_by) values
 ('45bef5ff-5058-405a-b280-f9e61f111ede','identity-aws-source','survey_partner','Amazon','{"original":{"ten":"Amazon"}}','linked','03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','10000000-0000-4000-8000-000000000001'),
 ('ddba9a15-2947-4d9f-ad46-2c51523caf76','identity-microsoft-google','survey_use_case','Enterprise AI Knowledge Management','{"details":{"doitac":[{"ten":"Microsoft, Google"}]}}','linked','92000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001'),
 ('4d92b283-352b-4eea-839c-e842daac04cb','identity-vnpt-cmc','survey_use_case','AI tổng hợp báo cáo','{"details":{"doitac":[{"ten":"VNPT AI, CMC OpenAI"}]}}','linked','92000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001');
insert into ai_management.source_links(source_id,record_id,created_by) values
 ('45bef5ff-5058-405a-b280-f9e61f111ede','03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','10000000-0000-4000-8000-000000000001'),
 ('45bef5ff-5058-405a-b280-f9e61f111ede','c31f3b31-2e8c-4de4-8c70-c9830d3a1543','10000000-0000-4000-8000-000000000001'),
 ('ddba9a15-2947-4d9f-ad46-2c51523caf76','41d76243-2459-4535-ab51-b6224ab5e690','10000000-0000-4000-8000-000000000001'),
 ('ddba9a15-2947-4d9f-ad46-2c51523caf76','45e52554-413c-427d-909a-5273bfc15eae','10000000-0000-4000-8000-000000000001'),
 ('4d92b283-352b-4eea-839c-e842daac04cb','d0b7af77-170a-4c98-ab8b-ecd3b4978a97','10000000-0000-4000-8000-000000000001'),
 ('4d92b283-352b-4eea-839c-e842daac04cb','45370a72-d396-48bf-a637-7c8933a587d7','10000000-0000-4000-8000-000000000001');
insert into ai_management.relations(source_id,target_id,relation,created_by) values
 ('c31f3b31-2e8c-4de4-8c70-c9830d3a1543','03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','partner','10000000-0000-4000-8000-000000000001'),
 ('15b46894-c1b6-4974-a9f8-04f14f670c79','03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','partner','10000000-0000-4000-8000-000000000001'),
 ('45e52554-413c-427d-909a-5273bfc15eae','41d76243-2459-4535-ab51-b6224ab5e690','partner','10000000-0000-4000-8000-000000000001'),
 ('45e52554-413c-427d-909a-5273bfc15eae','91000000-0000-4000-8000-000000000004','unit','10000000-0000-4000-8000-000000000001'),
 ('45e52554-413c-427d-909a-5273bfc15eae','92000000-0000-4000-8000-000000000001','use_case','10000000-0000-4000-8000-000000000001'),
 ('45370a72-d396-48bf-a637-7c8933a587d7','d0b7af77-170a-4c98-ab8b-ecd3b4978a97','partner','10000000-0000-4000-8000-000000000001'),
 ('45370a72-d396-48bf-a637-7c8933a587d7','91000000-0000-4000-8000-000000000004','unit','10000000-0000-4000-8000-000000000001'),
 ('45370a72-d396-48bf-a637-7c8933a587d7','92000000-0000-4000-8000-000000000002','use_case','10000000-0000-4000-8000-000000000001');
