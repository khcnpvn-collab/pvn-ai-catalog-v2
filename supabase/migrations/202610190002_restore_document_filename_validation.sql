-- Restore the exact filename validation expression used by the prior gateway.
-- The capacity migration preserved the checks but changed escaping in this
-- regular expression. This correction changes no other gateway behavior.
begin;
do $migration$
declare
 function_ddl text := pg_get_functiondef('public.ai_catalog_document_save(jsonb)'::regprocedure);
 previous_expression text := '[[:cntrl:]/' || repeat(chr(92),2) || ']';
 expected_expression text := '[[:cntrl:]/' || repeat(chr(92),4) || ']';
begin
 if position(previous_expression in function_ddl)=0 then
  raise exception 'document filename validation changed unexpectedly';
 end if;
 execute replace(function_ddl,previous_expression,expected_expression);
end $migration$;
commit;
