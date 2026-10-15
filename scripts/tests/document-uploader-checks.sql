\set ON_ERROR_STOP on
-- Files name who uploaded them: the display name, or the account name when there is none.
update auth.users set email='nguoi.tai@pvn.vn' where id='10000000-0000-4000-8000-000000000004';
insert into ai_management.documents(id,title,created_by) values('70000000-0000-4000-8000-000000000001','Tệp của người tải','10000000-0000-4000-8000-000000000004');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert((select x->>'created_by_name' from jsonb_array_elements(public.ai_catalog_documents('Tệp của người tải')) x where x->>'id'='70000000-0000-4000-8000-000000000001')
  ='nguoi.tai','a file uploaded by a user without a display name shows the account name');
reset role;
