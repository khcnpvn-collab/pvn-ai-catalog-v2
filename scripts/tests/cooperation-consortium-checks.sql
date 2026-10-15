do $$
begin
 if (select count(*) from ai_management.relations where source_id='88000000-0000-4000-8000-000000000003' and relation='partner')<>1 then raise exception 'FAILED: consortium cooperation still has redundant members'; end if;
 raise notice 'PASS: consortium cooperation retains only its existing owner';
 if not exists(select 1 from ai_management.relations where source_id='88000000-0000-4000-8000-000000000001' and target_id='88000000-0000-4000-8000-000000000002' and context->>'consortium_role'='lead' and note='Authoritative consortium role') then raise exception 'FAILED: authoritative consortium changed'; end if;
 raise notice 'PASS: consortium membership and lead role remain intact';
 if not exists(select 1 from ai_management.audit where record_id='88000000-0000-4000-8000-000000000003' and action='normalize_cooperation_consortium' and before_value->>'note'='Thành viên liên danh – cần xác minh vai trò') then raise exception 'FAILED: normalization has no provenance'; end if;
 raise notice 'PASS: redundant link retains its full before-value in audit';
 if (select count(*) from ai_management.relations where source_id='88000000-0000-4000-8000-000000000005' and relation='partner')<>2 then raise exception 'FAILED: unresolved membership was guessed'; end if;
 raise notice 'PASS: unrepresented members are preserved for review';
end $$;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare review jsonb;
begin
 review:=public.ai_catalog_partner_review();
 if exists(select 1 from jsonb_array_elements(review->'milestones_without_partner') item where item->>'id'='88000000-0000-4000-8000-000000000004') then raise exception 'FAILED: expert-only meeting incorrectly requires a partner'; end if;
 raise notice 'PASS: partner review excludes unrelated expert or unit meetings';
end $$;
reset role;
reset request.jwt.claim.sub;
