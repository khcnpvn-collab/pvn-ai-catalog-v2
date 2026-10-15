-- A work item's start is picked on a calendar: the month field becomes a date (no value was entered yet;
-- any month would become its first day).
begin;
alter table ai_management.work_item_details drop constraint if exists work_item_details_start_month_check;
alter table ai_management.work_item_details rename column start_month to start_date;
alter table ai_management.work_item_details alter column start_date type date using (start_date||'-01')::date;
update ai_management.module_registry set fields=(
 select jsonb_agg(case when f->>'key'='start_month' then '{"key":"start_date","type":"date","options":null}'::jsonb else f end order by n)
 from jsonb_array_elements(fields) with ordinality e(f,n)) where kind='work_item';
-- The overview names the field the same way.
do $$ begin
 execute replace(pg_get_functiondef('public.ai_catalog_overview()'::regprocedure),'''start_month'',d.start_month','''start_date'',d.start_date');
end $$;
commit;
