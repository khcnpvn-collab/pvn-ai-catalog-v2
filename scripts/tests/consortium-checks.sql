\set ON_ERROR_STOP on
begin;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
declare consortium_id uuid; member_one uuid; member_two uuid; member_three uuid; linked jsonb; lead_count int;
begin
 consortium_id := (public.ai_catalog_save(jsonb_build_object('kind','partner','title','Consortium','status','Chưa xác minh','visibility','team','data','{}'::jsonb))->>'id')::uuid;
 member_one := (public.ai_catalog_save(jsonb_build_object('kind','partner','title','Member one','status','Chưa xác minh','visibility','team','data','{}'::jsonb))->>'id')::uuid;
 member_two := (public.ai_catalog_save(jsonb_build_object('kind','partner','title','Member two','status','Chưa xác minh','visibility','team','data','{}'::jsonb))->>'id')::uuid;
 perform public.ai_catalog_consortium_link(jsonb_build_object('source_id',consortium_id,'target_id',member_one,'relation','partner','context',jsonb_build_object('consortium_role','lead')));
 perform public.ai_catalog_consortium_link(jsonb_build_object('source_id',consortium_id,'target_id',member_two,'relation','partner','context',jsonb_build_object('consortium_role','lead')));
 select count(*) into lead_count from jsonb_array_elements(public.ai_catalog_get(consortium_id)->'links') link
 where link->>'source_id'=consortium_id::text and link->>'relation'='partner' and link->'context'->>'consortium_role'='lead';
 perform public.catalog_test_assert(lead_count=1,'a consortium has exactly one canonical lead after replacement');
 perform public.catalog_test_assert((select link->'context'->>'consortium_role' from jsonb_array_elements(public.ai_catalog_get(consortium_id)->'links') link where link->>'source_id'=consortium_id::text and link->>'target_id'=member_one::text)='member','the previous lead is demoted atomically');
 linked := public.ai_catalog_create_related_context(consortium_id,jsonb_build_object('kind','partner','title','Created full partner','status','Chưa xác minh','visibility','team','data',jsonb_build_object('country','Việt Nam')),'partner','from-parent',jsonb_build_object('consortium_role','lead'));
 member_three := (linked->>'id')::uuid;
 perform public.catalog_test_assert((linked->'data'->>'country')='Việt Nam','contextual creation retains the full partner profile');
 perform public.catalog_test_assert((select link->'context'->>'consortium_role' from jsonb_array_elements(public.ai_catalog_get(consortium_id)->'links') link where link->>'source_id'=consortium_id::text and link->>'target_id'=member_three::text)='lead','created partner can become consortium lead');
 select count(*) into lead_count from jsonb_array_elements(public.ai_catalog_get(consortium_id)->'links') link
 where link->>'source_id'=consortium_id::text and link->>'relation'='partner' and link->'context'->>'consortium_role'='lead';
 perform public.catalog_test_assert(lead_count=1,'atomic creation also preserves one lead');
 perform public.catalog_test_error(format('select public.ai_catalog_consortium_link(%L::jsonb)',jsonb_build_object('source_id',consortium_id,'target_id',member_one,'relation','partner','context',jsonb_build_object('consortium_role','invalid'))::text),'VALIDATION','invalid consortium role rejected');
end $$;
reset role;
rollback;
