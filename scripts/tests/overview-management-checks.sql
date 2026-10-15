\set ON_ERROR_STOP on
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert(public.ai_catalog_overview()->'activities'->0 ?& array['next_notes','last_meeting_date'],'activities carry their next step and last meeting');
select public.catalog_test_assert(public.ai_catalog_overview()->'partners'->0 ?& array['contact_name','contact_count'],'partners carry their main contact');
select public.catalog_test_assert(public.ai_catalog_overview()->'experts'->0 ? 'expertise_summary','experts carry their expertise');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
select public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_list('unit','nbth')->'data') x where x->>'title'='Đơn vị thực hiện nội bộ'),'a unit is found by its abbreviation');
select public.catalog_test_assert(exists(select 1 from jsonb_array_elements(public.ai_catalog_list('unit','thực hiện nội')->'data') x where x->>'title'='Đơn vị thực hiện nội bộ'),'a unit is still found by its full name');
reset role;
