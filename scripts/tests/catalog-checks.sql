\set ON_ERROR_STOP on
create function public.catalog_test_assert(ok boolean,label text) returns void language plpgsql as $$ begin if ok is distinct from true then raise exception 'FAILED: %',label; end if; raise notice 'PASS: %',label; end $$;
create function public.catalog_test_error(sql_text text,expected text,label text) returns void language plpgsql as $$ declare message text; begin begin execute sql_text; exception when others then get stacked diagnostics message=MESSAGE_TEXT; if strpos(message,expected)>0 then raise notice 'PASS: %',label; return; end if; raise exception 'FAILED: % (unexpected: %)',label,message; end; raise exception 'FAILED: % (no error)',label; end $$;
insert into auth.users values('10000000-0000-4000-8000-000000000001'),('10000000-0000-4000-8000-000000000002'),('10000000-0000-4000-8000-000000000003'),('10000000-0000-4000-8000-000000000004');
insert into ai_management.memberships(user_id,role) values('10000000-0000-4000-8000-000000000001','admin'),('10000000-0000-4000-8000-000000000002','editor'),('10000000-0000-4000-8000-000000000003','reader');
create table public.catalog_test_state(name text primary key,value jsonb);
grant all on public.catalog_test_state to authenticated;
set role anon;
select public.catalog_test_error('select public.ai_catalog_list()','permission denied','anon cannot execute gateway');
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000004',false);
select public.catalog_test_assert(public.ai_catalog_membership() is null,'nonmember has no membership');
select public.catalog_test_error('select public.ai_catalog_list()','FORBIDDEN','nonmember cannot read records');
select public.catalog_test_error('select * from ai_management.memberships','permission denied','no direct membership grants');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into public.catalog_test_state values('team',public.ai_catalog_save('{"kind":"unit","title":"Kiểm thử","status":"Đang hoạt động","visibility":"team","data":{"website":"https://example.org","capabilities":"Khả năng"}}'));
insert into public.catalog_test_state values('private',public.ai_catalog_save('{"kind":"unit","title":"Riêng tư","status":"Đang hoạt động","visibility":"private","data":{}}'));
select public.catalog_test_assert((public.ai_catalog_list()->>'total')::int=2,'editor sees own team and private');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"unit","title":"X","status":"Đang hoạt động","visibility":"team","data":{"unknown":"bad"}}'')','VALIDATION','unknown data keys rejected');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"course","title":"X","status":"Đang sử dụng","visibility":"team","data":{"duration_hours":-1}}'')','VALIDATION','negative number rejected');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"engagement","title":"X","status":"Đã diễn ra","visibility":"team","data":{"start_date":"2026-02-30"}}'')','VALIDATION','invalid date rejected');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"engagement","title":"X","status":"Đã diễn ra","visibility":"team","data":{"start_date":"2026-03-01","end_date":"2026-02-01"}}'')','VALIDATION','reversed dates rejected');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"poc","title":"X","status":"Chuẩn bị","visibility":"team","data":{"conclusion":"bad"}}'')','VALIDATION','unknown option rejected');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"contact","title":"X","status":"Còn hiệu lực","visibility":"team","data":{"email":"not-email"}}'')','VALIDATION','email constraint enforced');
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"resource","title":"X","status":"Chưa xác minh","visibility":"team","data":{"external_url":"javascript:alert(1)"}}'')','VALIDATION','unsafe URL rejected');

do $$ declare result jsonb; begin
 begin
  result:=public.ai_catalog_save('{"kind":"unit","title":"Uppercase URL fixture","status":"Đang hoạt động","visibility":"team","data":{"website":"HTTPS://example.org"}}');
  perform public.catalog_test_assert(result->'data'->>'website'='HTTPS://example.org','unit accepts uppercase HTTP scheme');
  result:=public.ai_catalog_save('{"kind":"partner","title":"Uppercase URL fixture","status":"Chưa xác minh","visibility":"team","data":{"website":"HTTP://example.org"}}');
  perform public.catalog_test_assert(result->'data'->>'website'='HTTP://example.org','partner accepts uppercase HTTP scheme');
  result:=public.ai_catalog_save('{"kind":"resource","title":"Uppercase URL fixture","status":"Chưa xác minh","visibility":"team","data":{"external_url":"HtTpS://example.org"}}');
  perform public.catalog_test_assert(result->'data'->>'external_url'='HtTpS://example.org','resource accepts mixed-case HTTP scheme');
  raise exception using errcode='Z0001',message='rollback successful URL fixtures';
 exception when sqlstate 'Z0001' then null;
 end;
end $$;

insert into public.catalog_test_state select 'updated',public.ai_catalog_save(jsonb_build_object('id',value->>'id','version',1,'kind','unit','title','Đã sửa','status','Đang hoạt động','visibility','team','data',jsonb_build_object('abbreviation','NEW'))) from public.catalog_test_state where name='team';
select public.catalog_test_assert((value->>'version')::int=2 and value->'data'->>'abbreviation'='NEW','typed update and version increment') from public.catalog_test_state where name='updated';
select public.catalog_test_error(format('select public.ai_catalog_archive(%L,1)',value->>'id'),'CONFLICT','stale archive conflicts') from public.catalog_test_state where name='updated';
select public.catalog_test_error(format('select public.ai_catalog_save(%L)',jsonb_build_object('id',value->>'id','version',1,'kind','unit','title','Stale','status','Đang hoạt động','visibility','team')),'CONFLICT','stale update conflicts') from public.catalog_test_state where name='updated';
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.catalog_test_assert((public.ai_catalog_list()->>'total')::int=1,'reader sees only team');
select public.catalog_test_error(format('select public.ai_catalog_get(%L)',value->>'id'),'NOT_FOUND','reader cannot get private record') from public.catalog_test_state where name='private';
select public.catalog_test_error('select public.ai_catalog_save(''{"kind":"unit","title":"X","status":"Đang hoạt động","visibility":"team"}'')','FORBIDDEN','reader cannot create');
select public.catalog_test_error('select public.ai_catalog_sources()','FORBIDDEN','reader cannot see source snapshots');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
select public.catalog_test_assert((public.ai_catalog_list()->>'total')::int=2,'admin sees private');
select public.catalog_test_assert(public.ai_catalog_source_save('{"source_key":"survey:1:sha256","source_type":"survey_use_case","title":"Original","payload":{"answer":"Original unchanged"}}'),'admin inserts snapshot');
select public.catalog_test_assert(not public.ai_catalog_source_save('{"source_key":"survey:1:sha256","source_type":"survey_use_case","title":"Replacement","payload":{"answer":"changed"}}'),'source idempotent');
select public.catalog_test_assert(public.ai_catalog_sources()->0->'payload'->>'answer'='Original unchanged','snapshot not overwritten');
select public.catalog_test_assert(public.ai_catalog_source_link((public.ai_catalog_sources()->0->>'id')::uuid,(value->>'id')::uuid),'source link') from public.catalog_test_state where name='team';
reset role;
-- Typed module roundtrips; schema registry supplies valid fixture values in this isolated DB only.
do $$ declare m record; f jsonb; data jsonb; input jsonb; output jsonb; begin
 perform set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
 for m in select * from ai_management.module_registry loop
  data:='{}'::jsonb;
  for f in select * from jsonb_array_elements(m.fields) loop
   data:=data||jsonb_build_object(f->>'key',case when f->>'type'='date' then to_jsonb('2026-01-01'::text) when f->>'type'='number' then to_jsonb(2.5) when f->>'type'='email' then to_jsonb('test@example.org'::text) when f->>'type'='url' then to_jsonb('https://example.org'::text) when f->'options'<>'null'::jsonb then f->'options'->0 else to_jsonb('Đủ dữ liệu'::text) end);
  end loop;
  input:=jsonb_build_object('kind',m.kind,'title','Roundtrip '||m.kind,'status',m.statuses[1],'visibility','team','data',data);
  output:=public.ai_catalog_save(input);
  perform public.catalog_test_assert(output->'data'=data,'typed roundtrip '||m.kind);
 end loop;
end $$;
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into public.catalog_test_state values('caseA',public.ai_catalog_save('{"kind":"use_case","title":"A","status":"Chưa xác minh","visibility":"team"}')),('caseB',public.ai_catalog_save('{"kind":"use_case","title":"B","status":"Chưa xác minh","visibility":"team"}'));
insert into public.catalog_test_state select 'relation',public.ai_catalog_link(jsonb_build_object('source_id',a.value->>'id','target_id',b.value->>'id','relation','parent','context',jsonb_build_object('role','historical'))) from public.catalog_test_state a,public.catalog_test_state b where a.name='caseA' and b.name='caseB';
select public.catalog_test_error(format('select public.ai_catalog_link(%L)',jsonb_build_object('source_id',b.value->>'id','target_id',a.value->>'id','relation','parent')),'VALIDATION: parent cycle','parent cycle rejected') from public.catalog_test_state a,public.catalog_test_state b where a.name='caseA' and b.name='caseB';
select public.catalog_test_error(format('select public.ai_catalog_link(%L)',jsonb_build_object('source_id',a.value->>'id','target_id',b.value->>'id','relation','speaker')),'VALIDATION: incompatible','relation kinds enforced') from public.catalog_test_state a,public.catalog_test_state b where a.name='caseA' and b.name='caseB';
select public.catalog_test_assert(public.ai_catalog_unlink((value->>'id')::uuid),'unlink works') from public.catalog_test_state where name='relation';
select public.catalog_test_assert(public.ai_catalog_archive((value->>'id')::uuid,1),'archive works') from public.catalog_test_state where name='caseA';
select public.catalog_test_assert((public.ai_catalog_list(null,'',null,1,true)->>'total')::int=1,'archive filter works');
select public.catalog_test_assert((public.ai_catalog_stats()->'counts'->>'use_case')::int=2,'statistics exclude archived');
