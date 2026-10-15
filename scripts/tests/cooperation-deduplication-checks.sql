do $$
begin
 if (select count(*) from ai_management.records where id in
  ('91000000-0000-4000-8000-000000000001','91000000-0000-4000-8000-000000000002') and archived_at is null)<>1 then
  raise exception 'FAILED: duplicate survey cooperation remains active';
 end if;
 if not exists(select 1 from ai_management.records where id='91000000-0000-4000-8000-000000000001' and archived_at is null and status='Đang thực hiện') then
  raise exception 'FAILED: more informative original cooperation was not retained';
 end if;
 if not exists(select 1 from ai_management.records where id='91000000-0000-4000-8000-000000000002' and archived_at is not null and version=3) then
  raise exception 'FAILED: duplicate was not recoverably archived';
 end if;
 if (select count(*) from ai_management.source_links where source_id='91000000-0000-4000-8000-000000000003')<>2 then
  raise exception 'FAILED: source provenance was lost';
 end if;
 if (select count(*) from ai_management.relations where source_id in
  ('91000000-0000-4000-8000-000000000001','91000000-0000-4000-8000-000000000002'))<>4 then
  raise exception 'FAILED: original relations were changed';
 end if;
 if not exists(select 1 from ai_management.audit where record_id='91000000-0000-4000-8000-000000000002'
  and action='deduplicate_survey_cooperation' and after_value->>'canonical_id'='91000000-0000-4000-8000-000000000001') then
  raise exception 'FAILED: canonical record was not recorded in audit';
 end if;
 raise notice 'PASS: source-identical cooperation is archived with provenance and relations intact';
end $$;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare dossier jsonb;
begin
 dossier:=public.ai_catalog_dossier('88000000-0000-4000-8000-000000000001');
 if (select count(*) from jsonb_array_elements(dossier->'related') entry
  where entry->'record'->>'id' in ('91000000-0000-4000-8000-000000000001','91000000-0000-4000-8000-000000000002'))<>1 then
  raise exception 'FAILED: partner dossier still shows both survey cooperation records';
 end if;
 raise notice 'PASS: partner dossier shows only the canonical cooperation';
end $$;
reset role;
reset request.jwt.claim.sub;
