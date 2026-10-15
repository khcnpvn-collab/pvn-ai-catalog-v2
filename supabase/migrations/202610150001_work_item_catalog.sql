-- Work items: alongside the standard problems, the catalogue now holds work items in five groups
-- (platform/infrastructure, data, AI governance, people/training, agreements). Every activity
-- belongs to one of six item groups (standard problems are the first) and links at most one item
-- through the existing "use_case" relation, which now accepts a standard problem or a work item.
-- All items, standard problems included, follow one lifecycle: in progress / done / paused.
-- Activities that had no item are sorted into groups by their old type, then by keywords.
begin;

create temporary table item_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;

-- 1. The work item kind.
insert into ai_management.module_registry(kind,statuses,fields) values ('work_item',array['Đang thực hiện','Hoàn thành','Tạm dừng'],'[
 {"key":"item_group","type":"select","options":["Nền tảng, hạ tầng, công nghệ","Dữ liệu, CSDL","Quản trị AI","Nhân lực, đào tạo","Ký kết hợp tác"]},
 {"key":"scope_level","type":"select","options":["Tập đoàn","Đơn vị"]},
 {"key":"apply_scope","type":"select","options":["Toàn Tập đoàn","Cơ quan Tập đoàn","Đơn vị cụ thể"]},
 {"key":"owner","type":"text","options":null},
 {"key":"coordinator","type":"text","options":null},
 {"key":"start_month","type":"month","options":null},
 {"key":"notes","type":"textarea","options":null}]'::jsonb);
create table ai_management.work_item_details(
 record_id uuid primary key,
 kind text not null default 'work_item' check (kind='work_item'),
 item_group text not null check (item_group in ('Nền tảng, hạ tầng, công nghệ','Dữ liệu, CSDL','Quản trị AI','Nhân lực, đào tạo','Ký kết hợp tác')),
 scope_level text check (scope_level in ('Tập đoàn','Đơn vị')),
 apply_scope text check (apply_scope in ('Toàn Tập đoàn','Cơ quan Tập đoàn','Đơn vị cụ thể')),
 owner text check (length(owner)<=1000),
 coordinator text check (length(coordinator)<=1000),
 start_month text check (start_month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
 notes text check (length(notes)<=10000),
 foreign key (record_id,kind) references ai_management.records(id,kind) on delete cascade);
alter table ai_management.work_item_details enable row level security;
revoke all on ai_management.work_item_details from public,anon,authenticated;

-- Codes per group (HT-01, DL-01, …) are kept for reference; the app does not show them.
create function ai_management.assign_work_item_code() returns trigger
language plpgsql security definer set search_path='' as $$
declare prefix text; next_number integer;
begin
 prefix:=case new.item_group when 'Nền tảng, hạ tầng, công nghệ' then 'HT' when 'Dữ liệu, CSDL' then 'DL' when 'Quản trị AI' then 'QT' when 'Nhân lực, đào tạo' then 'NL' else 'KK' end;
 perform pg_advisory_xact_lock(hashtextextended('ai-catalog:work-item-code',0));
 select coalesce(max(substring(r.code from '-([0-9]+)$')::integer),0)+1 into next_number
 from ai_management.records r where r.kind='work_item' and r.code ~ ('^'||prefix||'-[0-9]+$');
 update ai_management.records set code=prefix||'-'||lpad(next_number::text,2,'0')
 where id=new.record_id and (code is null or code !~ '^(HT|DL|QT|NL|KK)-[0-9]+$');
 return new;
end $$;
create trigger work_item_code after insert on ai_management.work_item_details for each row execute function ai_management.assign_work_item_code();

-- 2. Standard problems follow the item lifecycle; every catalogued problem is in progress.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select id,(select user_id from item_actor),'adopt_item_lifecycle',jsonb_build_object('status',status),jsonb_build_object('status','Đang thực hiện')
from ai_management.records where kind='use_case' and status<>'Đang thực hiện';
update ai_management.records set status='Đang thực hiện',version=version+1,updated_at=now() where kind='use_case' and status<>'Đang thực hiện';
update ai_management.module_registry set statuses=array['Đang thực hiện','Hoàn thành','Tạm dừng'] where kind='use_case';

-- 3. Activities: item group and detailed classification replace the activity type.
alter table ai_management.collaboration_details add column item_group text, add column item_category text;
create temporary table activity_group on commit drop as
select d.record_id, d.cooperation_types old_type,
 exists(select 1 from ai_management.relations l where l.source_id=d.record_id and l.relation='use_case') has_standard,
 normalize(concat_ws(' ',r.title,d.scope,d.declared_title),NFC) body
from ai_management.collaboration_details d join ai_management.records r on r.id=d.record_id;
alter table activity_group add column grp text, add column reason text;
update activity_group set grp=case
  when has_standard then 'Bài toán'
  when old_type='Đào tạo' then 'Nhân lực, đào tạo'
  when old_type='MOU / hợp tác chiến lược' then 'Ký kết hợp tác'
  when old_type='Hạ tầng' then 'Nền tảng, hạ tầng, công nghệ'
  when body ~* '(\mmou\M|ghi nhớ|thỏa thuận|thoả thuận|ký kết)' then 'Ký kết hợp tác'
  when body ~* '([đĐ]ào tạo|khóa học|khoá học|hội thảo|\mworkshop|\msummit|nhân lực)' then 'Nhân lực, đào tạo'
  when body ~* '(governance|quản trị ai|chiến lược ai|ai strategy|kiến trúc doanh nghiệp|quy chế|operating model)' then 'Quản trị AI'
  when body ~* '(hạ tầng|data center|\mhpc\M|cloud|đám mây|\mgpu|máy chủ|bản quyền|\medge\M|iot platform|access management)' then 'Nền tảng, hạ tầng, công nghệ'
  when body ~* '(dữ liệu|\mcsdl\M|big data)' then 'Dữ liệu, CSDL'
  when body ~* '(nền tảng|platform|copilot|công cụ ai)' then 'Nền tảng, hạ tầng, công nghệ'
  else 'Bài toán' end,
 reason=case when has_standard then 'Đã gắn bài toán chuẩn'
  when old_type in ('Đào tạo','MOU / hợp tác chiến lược','Hạ tầng') then 'Theo loại hoạt động cũ: '||old_type
  else 'Theo từ khóa trong tên / mô tả' end;
update ai_management.collaboration_details d set item_group=g.grp,
 item_category=case
  when g.grp='Bài toán' and g.old_type='Bài toán đơn vị' then 'Ứng dụng AI tại đơn vị'
  when g.grp='Bài toán' and g.old_type='Đề tài KHCN' then 'Đề tài KHCN / nghiên cứu'
  when g.grp='Bài toán' and g.old_type='Tư vấn' then 'Tư vấn, đánh giá giải pháp'
  when g.grp='Ký kết hợp tác' and (g.old_type='MOU / hợp tác chiến lược' or g.body ~* '(\mmou\M|ghi nhớ)') then 'Biên bản ghi nhớ (MOU)'
  when g.grp='Nhân lực, đào tạo' and g.body ~* '(hội thảo|\mworkshop|\msummit)' then 'Hội thảo, chia sẻ kinh nghiệm'
  when g.grp='Nhân lực, đào tạo' then 'Đào tạo, khóa học' end
from activity_group g where g.record_id=d.record_id;
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select g.record_id,(select user_id from item_actor),'assign_item_group',jsonb_build_object('cooperation_types',g.old_type),
 jsonb_build_object('item_group',d.item_group,'item_category',d.item_category,'reason',g.reason)
from activity_group g join ai_management.collaboration_details d on d.record_id=g.record_id;
alter table ai_management.collaboration_details drop column cooperation_types;
alter table ai_management.collaboration_details alter column item_group set not null,
 add constraint collaboration_item_group_list check (item_group in ('Bài toán','Nền tảng, hạ tầng, công nghệ','Dữ liệu, CSDL','Quản trị AI','Nhân lực, đào tạo','Ký kết hợp tác')),
 add constraint collaboration_item_category_list check (item_category is null or item_group||' | '||item_category = any(array[
  'Bài toán | Ứng dụng AI tại đơn vị','Bài toán | Giải pháp dùng chung Tập đoàn','Bài toán | Đề tài KHCN / nghiên cứu','Bài toán | Tư vấn, đánh giá giải pháp',
  'Nền tảng, hạ tầng, công nghệ | Hạ tầng tính toán (GPU, máy chủ)','Nền tảng, hạ tầng, công nghệ | Điện toán đám mây','Nền tảng, hạ tầng, công nghệ | Nền tảng AI / MLOps','Nền tảng, hạ tầng, công nghệ | Mô hình & công cụ AI (LLM, trợ lý AI)','Nền tảng, hạ tầng, công nghệ | Bản quyền, giấy phép phần mềm',
  'Dữ liệu, CSDL | Xây dựng CSDL / kho dữ liệu','Dữ liệu, CSDL | Chuẩn hóa, làm sạch, gán nhãn','Dữ liệu, CSDL | Tích hợp, chia sẻ dữ liệu','Dữ liệu, CSDL | Quản trị chất lượng dữ liệu','Dữ liệu, CSDL | Khai thác dữ liệu bên ngoài',
  'Quản trị AI | Chiến lược, kế hoạch AI','Quản trị AI | Chính sách, quy chế, quy trình','Quản trị AI | Rủi ro, an toàn, đạo đức AI','Quản trị AI | Kiến trúc, tiêu chuẩn kỹ thuật','Quản trị AI | Đo lường hiệu quả',
  'Nhân lực, đào tạo | Đào tạo, khóa học','Nhân lực, đào tạo | Hội thảo, chia sẻ kinh nghiệm','Nhân lực, đào tạo | Chuyển giao công nghệ, know-how','Nhân lực, đào tạo | Chuyên gia, cố vấn','Nhân lực, đào tạo | Phát triển đội ngũ chuyên sâu',
  'Ký kết hợp tác | Biên bản ghi nhớ (MOU)','Ký kết hợp tác | Thỏa thuận hợp tác chiến lược','Ký kết hợp tác | Thỏa thuận khung','Ký kết hợp tác | Hợp đồng dịch vụ / mua sắm','Ký kết hợp tác | Thỏa thuận bảo mật (NDA)']));
-- The registry mirrors src/lib/catalog.ts: the group and its category open the activity form.
update ai_management.module_registry set fields=jsonb_build_array(
 jsonb_build_object('key','item_group','type','select','options',jsonb_build_array('Bài toán','Nền tảng, hạ tầng, công nghệ','Dữ liệu, CSDL','Quản trị AI','Nhân lực, đào tạo','Ký kết hợp tác')),
 jsonb_build_object('key','item_category','type','select','options',jsonb_build_array(
  'Ứng dụng AI tại đơn vị','Giải pháp dùng chung Tập đoàn','Đề tài KHCN / nghiên cứu','Tư vấn, đánh giá giải pháp',
  'Hạ tầng tính toán (GPU, máy chủ)','Điện toán đám mây','Nền tảng AI / MLOps','Mô hình & công cụ AI (LLM, trợ lý AI)','Bản quyền, giấy phép phần mềm',
  'Xây dựng CSDL / kho dữ liệu','Chuẩn hóa, làm sạch, gán nhãn','Tích hợp, chia sẻ dữ liệu','Quản trị chất lượng dữ liệu','Khai thác dữ liệu bên ngoài',
  'Chiến lược, kế hoạch AI','Chính sách, quy chế, quy trình','Rủi ro, an toàn, đạo đức AI','Kiến trúc, tiêu chuẩn kỹ thuật','Đo lường hiệu quả',
  'Đào tạo, khóa học','Hội thảo, chia sẻ kinh nghiệm','Chuyển giao công nghệ, know-how','Chuyên gia, cố vấn','Phát triển đội ngũ chuyên sâu',
  'Biên bản ghi nhớ (MOU)','Thỏa thuận hợp tác chiến lược','Thỏa thuận khung','Hợp đồng dịch vụ / mua sắm','Thỏa thuận bảo mật (NDA)')))
 || coalesce((select jsonb_agg(f order by n) from jsonb_array_elements(fields) with ordinality e(f,n) where f->>'key'<>'cooperation_types'),'[]'::jsonb)
where kind='collaboration';

-- 4. The item relation of an activity (or a partner's capability) accepts a standard problem or a work item.
create or replace function public.ai_catalog_link(p_link jsonb) returns jsonb
language plpgsql security definer set search_path='' as $function$
declare s ai_management.records; t ai_management.records; rel text; ctx jsonb; item record; result ai_management.relations;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_link,array['source_id','target_id','relation','note','context']);
 -- Serialize parent mutations so two concurrent inserts cannot create a cycle.
 perform pg_advisory_xact_lock(73424910902411);
 select * into s from ai_management.records where id=(p_link->>'source_id')::uuid;
 select * into t from ai_management.records where id=(p_link->>'target_id')::uuid;
 if s.id is null or t.id is null or not ai_management.can_read_record(s.id) or not ai_management.can_read_record(t.id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(s.id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if s.id=t.id then raise exception 'VALIDATION: invalid relation endpoints' using errcode='22023'; end if;
 rel:=p_link->>'relation'; ctx:=coalesce(p_link->'context','{}'::jsonb);
 if jsonb_typeof(ctx)<>'object' or octet_length(ctx::text)>16000 then raise exception 'VALIDATION: invalid context' using errcode='22023'; end if;
 for item in select key,value from jsonb_each(ctx) loop
  if length(item.key)>80 or jsonb_typeof(item.value)<>'string' or length(item.value#>>'{}')>1000 then raise exception 'VALIDATION: invalid context value' using errcode='22023'; end if;
 end loop;
 if not (case rel
  when 'related' then true
  when 'parent' then s.kind=t.kind and s.kind in ('use_case','unit')
  when 'unit' then t.kind='unit'
  when 'partner' then t.kind='partner' or (t.kind='unit' and s.kind='collaboration')
  when 'contact' then t.kind='contact'
  when 'expert' then t.kind='expert' and s.kind in ('partner','unit','use_case','work_item','collaboration','engagement','reference','learning_event')
  when 'use_case' then t.kind in ('use_case','work_item')
  when 'collaboration' then t.kind='collaboration'
  when 'event' then t.kind in ('learning_event','engagement') and s.kind in ('contact','unit','partner')
  when 'speaker' then t.kind in ('contact','expert') and s.kind in ('learning_event','engagement')
  when 'participant' then t.kind in ('contact','expert') and s.kind in ('learning_event','engagement')
  when 'organizer' then t.kind in ('unit','partner') and s.kind in ('learning_event','engagement')
  else false end) then raise exception 'VALIDATION: incompatible relation kinds' using errcode='22023'; end if;
 if rel='parent' and exists(with recursive ancestors(id) as (select t.id union select r.target_id from ai_management.relations r join ancestors a on r.source_id=a.id where r.relation='parent') select 1 from ancestors where id=s.id) then raise exception 'VALIDATION: parent cycle' using errcode='22023'; end if;
 insert into ai_management.relations(source_id,target_id,relation,note,context,created_by) values(s.id,t.id,rel,nullif(p_link->>'note',''),ctx,auth.uid()) returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(s.id,auth.uid(),'link',to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when unique_violation then raise exception 'CONFLICT: relation already exists or parent already assigned' using errcode='40001';
 when check_violation or invalid_text_representation or not_null_violation then raise exception 'VALIDATION: invalid relation' using errcode='22023';
end $function$;

-- 5. Month fields hold "YYYY-MM".
create or replace function public.ai_catalog_save(p_record jsonb) returns jsonb
language plpgsql security definer set search_path='' as $function$
declare k text; rid uuid; previous ai_management.records; details jsonb; field jsonb; value jsonb; collist text; datalist text; updater text; result jsonb; columns_allowed text[]; common_key text;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_record,array['id','kind','title','code','summary','status','version','data']);
 for common_key in select unnest(array['kind','title','code','summary','status']) loop
  if p_record ? common_key and p_record->common_key<>'null'::jsonb and jsonb_typeof(p_record->common_key)<>'string' then raise exception 'VALIDATION: expected common text field' using errcode='22023'; end if;
 end loop;
 if p_record ? 'version' and (jsonb_typeof(p_record->'version')<>'number' or (p_record->>'version') !~ '^[1-9][0-9]*$') then raise exception 'VALIDATION: invalid version' using errcode='22023'; end if;
 k:=p_record->>'kind';
 if not exists(select 1 from ai_management.module_registry where kind=k and p_record->>'status'=any(statuses)) or jsonb_typeof(p_record->'title') is distinct from 'string' then raise exception 'VALIDATION: invalid record' using errcode='22023'; end if;
 details:=coalesce(p_record->'data','{}'::jsonb);
 select array_agg(f->>'key') into columns_allowed from ai_management.module_registry m cross join lateral jsonb_array_elements(m.fields) f where m.kind=k;
 perform ai_management.reject_unknown(details,columns_allowed);
 for field in select f from ai_management.module_registry m cross join lateral jsonb_array_elements(m.fields) f where m.kind=k loop
  value:=details->(field->>'key');
  if value='""'::jsonb then details:=jsonb_set(details,array[field->>'key'],'null'::jsonb); value:='null'::jsonb; end if;
  if value is null or value='null'::jsonb then continue; end if;
  if field->>'type'='number' then
   if jsonb_typeof(value) not in ('number','string') or (value#>>'{}') !~ '^[0-9]+([.][0-9]+)?$' then raise exception 'VALIDATION: invalid number' using errcode='22023'; end if;
  elsif jsonb_typeof(value)<>'string' then raise exception 'VALIDATION: expected text' using errcode='22023'; end if;
  if field->>'type'='date' and ((value#>>'{}') !~ '^\d{4}-\d{2}-\d{2}$' or to_char((value#>>'{}')::date,'YYYY-MM-DD')<>(value#>>'{}')) then raise exception 'VALIDATION: invalid date' using errcode='22023'; end if;
  if field->>'type'='month' and (value#>>'{}') !~ '^\d{4}-(0[1-9]|1[0-2])$' then raise exception 'VALIDATION: invalid month' using errcode='22023'; end if;
  if field->>'type'='select' and not (field->'options') ? (value#>>'{}') then raise exception 'VALIDATION: value not in list' using errcode='22023'; end if;
 end loop;
 if p_record ? 'id' then
  rid:=(p_record->>'id')::uuid;
  select * into previous from ai_management.records where id=rid for update;
  if not found or not ai_management.can_read_record(rid) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
  if not ai_management.can_write_record(rid) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if previous.version is distinct from (p_record->>'version')::integer then raise exception 'CONFLICT' using errcode='40001'; end if;
  if previous.kind<>k then raise exception 'VALIDATION: kind cannot change' using errcode='22023'; end if;
  update ai_management.records set title=btrim(p_record->>'title'),code=nullif(p_record->>'code',''),summary=nullif(p_record->>'summary',''),status=p_record->>'status',version=version+1,updated_at=now() where id=rid;
 else
  insert into ai_management.records(kind,title,code,summary,status,created_by) values(k,btrim(p_record->>'title'),nullif(p_record->>'code',''),nullif(p_record->>'summary',''),p_record->>'status',auth.uid()) returning id into rid;
 end if;
 select string_agg(format('%I',f->>'key'),','),string_agg(format('x.%I',f->>'key'),','),string_agg(format('%I=excluded.%I',f->>'key',f->>'key'),',') into collist,datalist,updater from ai_management.module_registry m cross join lateral jsonb_array_elements(m.fields) f where m.kind=k;
 execute format('insert into ai_management.%I(record_id,%s) select $1,%s from jsonb_populate_record(null::ai_management.%I,$2) x on conflict(record_id) do update set %s',k||'_details',collist,datalist,k||'_details',updater) using rid,details;
 result:=ai_management.record_json(rid);
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value) values(rid,auth.uid(),case when previous.id is null then 'create' else 'update' end,case when previous.id is null then null else to_jsonb(previous) end,result);
 return result;
exception when check_violation or not_null_violation or invalid_text_representation or datetime_field_overflow or invalid_datetime_format or numeric_value_out_of_range then raise exception 'VALIDATION: invalid fields' using errcode='22023';
end $function$;

-- 6. The overview carries work items and each activity's group, category and item.
create or replace function public.ai_catalog_overview() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with v as (
  select r.id,r.kind,r.title,r.code,r.status,r.updated_at from ai_management.records r
  where r.kind in ('use_case','work_item','collaboration','partner','unit','expert','learning_event','engagement')
   and ai_management.can_read_record(r.id)
 ), l as (
  select x.source_id,x.target_id,x.relation,x.context,t.kind target_kind,s.kind source_kind from ai_management.relations x
  join v s on s.id=x.source_id join v t on t.id=x.target_id
 )
 select jsonb_build_object(
  'standards',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'code',v.code,'status',v.status,'updated_at',v.updated_at,
    'program',d.program,'category',d.category,'is_priority',d.is_priority,'leadership_level',d.leadership_level,'start_year',d.start_year,
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'potential_unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit' and coalesce(l.context->>'subject_role','')<>'lead'),
    'potential_partner_ids',(select coalesce(jsonb_agg(l.source_id),'[]'::jsonb) from l where l.target_id=v.id and l.relation='use_case' and l.source_kind='partner')
   ) order by v.code,v.title),'[]'::jsonb) from v join ai_management.use_case_details d on d.record_id=v.id),
  'work_items',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'code',v.code,'status',v.status,'updated_at',v.updated_at,
    'item_group',d.item_group,'scope_level',d.scope_level,'apply_scope',d.apply_scope,'owner',d.owner,'coordinator',d.coordinator,'start_month',d.start_month,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by d.item_group,v.title),'[]'::jsonb) from v join ai_management.work_item_details d on d.record_id=v.id),
  'activities',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'item_group',d.item_group,'item_category',d.item_category,'start_date',d.start_date,'end_date',d.end_date,
    'partner_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'provider_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='unit' limit 1),
    'party_lead_id',(select l.context->>'lead_member_id' from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' and l.target_kind='use_case' limit 1),
    'work_item_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' and l.target_kind='work_item' limit 1),
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by v.updated_at desc,v.id),'[]'::jsonb) from v join ai_management.collaboration_details d on d.record_id=v.id),
  'partners',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'short_name',d.short_name,'partner_type',d.partner_type,'country',d.country,'strategic_level',d.strategic_level,'specialties',d.specialties,
    'member_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner'),
    'lead_member_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' and coalesce(l.context->>'consortium_role',l.context->>'role',l.context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh') limit 1)
   ) order by v.title),'[]'::jsonb) from v join ai_management.partner_details d on d.record_id=v.id),
  'units',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'abbreviation',d.abbreviation,'sector',d.sector,'unit_type',d.unit_type,
    'parent_id',(select l.target_id from l where l.source_id=v.id and l.relation='parent' limit 1)
   ) order by v.title),'[]'::jsonb) from v join ai_management.unit_details d on d.record_id=v.id),
  'milestones',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'start_date',d.start_date,'end_date',d.end_date,'period_label',d.period_label,
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner'),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'activity_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='collaboration')
   ) order by d.start_date desc nulls last,v.updated_at desc),'[]'::jsonb) from v join ai_management.engagement_details d on d.record_id=v.id),
  'experts',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'organization',d.organization,'current_position',d.current_position,
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit'),
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.expert_details d on d.record_id=v.id),
  'events',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'event_type',d.event_type,'start_date',d.start_date,'end_date',d.end_date,'audience',d.audience,
    'partner_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='organizer' and l.target_kind='partner'),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='organizer' and l.target_kind='unit'),
    'expert_ids',(select coalesce(jsonb_agg(distinct l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation in ('speaker','participant') and l.target_kind='expert')
   ) order by d.start_date desc nulls last,v.updated_at desc),'[]'::jsonb) from v join ai_management.learning_event_details d on d.record_id=v.id)
 ) into result;
 return result;
end $$;
revoke all on function public.ai_catalog_overview() from public,anon;
grant execute on function public.ai_catalog_overview() to authenticated;
commit;
