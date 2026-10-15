\set ON_ERROR_STOP on
-- Runs after every migration: the UI module contract must match the final registry.
begin;
create temporary table ui_contract_modules(config jsonb);
insert into ui_contract_modules values (:'catalog_modules'::jsonb);
do $$ declare m jsonb; actual jsonb; begin
 for m in select * from jsonb_array_elements((select config from ui_contract_modules)) loop
  select jsonb_build_object('statuses',to_jsonb(statuses),'fields',fields) into actual from ai_management.module_registry where kind=m->>'kind';
  perform public.catalog_test_assert(actual=jsonb_build_object('statuses',m->'statuses','fields',(select jsonb_agg(jsonb_build_object('key',f->>'key','type',coalesce(f->>'type','text'),'options',f->'options')) from jsonb_array_elements(m->'fields') f)), 'database registry matches UI contract: '||(m->>'kind'));
 end loop;
end $$;
rollback;
