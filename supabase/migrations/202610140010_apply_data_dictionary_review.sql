-- Applies the data dictionary review of 14/10/2026.
-- Partners: "Chiến lược" status retired, new type list, country and strategic level picked from
-- lists, capabilities kept as reusable tags, six unused fields dropped (introduction notes are
-- moved into the short introduction first). Units: a unit type, "Chưa xác minh" retired, two
-- survey-generated fields dropped. Every record: source date, source note and sharing scope
-- dropped; deleting a record now removes it for good, with a full snapshot in the audit log.
-- Values that disappear are snapshotted into the audit log before anything changes.
begin;

create temporary table review_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;

insert into ai_management.audit(record_id,actor_id,action,before_value)
select r.id,(select user_id from review_actor),'drop_reviewed_fields',jsonb_strip_nulls(jsonb_build_object(
  'observed_on',r.observed_on,'source_note',r.source_note,'visibility',r.visibility,
  'aliases',p.aliases,'legal_name',p.legal_name,'origin',p.origin,'document_notes',p.document_notes,
  'internal_unit_code',p.internal_unit_code,'profile_url',p.profile_url,'capabilities',u.capabilities,'governance',u.governance))
from ai_management.records r
left join ai_management.partner_details p on p.record_id=r.id
left join ai_management.unit_details u on u.record_id=r.id;

-- Introduction notes from the partner workbook become the partner's short introduction.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select r.id,(select user_id from review_actor),'move_document_notes_to_summary',jsonb_build_object('summary',r.summary),
  jsonb_build_object('summary',concat_ws(E'\n\n',nullif(btrim(r.summary),''),btrim(p.document_notes)))
from ai_management.records r join ai_management.partner_details p on p.record_id=r.id
where nullif(btrim(p.document_notes),'') is not null;
update ai_management.records r set summary=concat_ws(E'\n\n',nullif(btrim(r.summary),''),btrim(p.document_notes)),version=r.version+1,updated_at=now()
from ai_management.partner_details p
where p.record_id=r.id and nullif(btrim(p.document_notes),'') is not null;

-- New partner type list.
create temporary table partner_type_change on commit drop as
select record_id,partner_type old,case partner_type
  when 'Doanh nghiệp/nhà cung cấp' then 'Công ty công nghệ'
  when 'Trường đại học' then 'Đơn vị đào tạo và NCKH'
  when 'Viện/tổ chức nghiên cứu' then 'Đơn vị đào tạo và NCKH' end new
from ai_management.partner_details where partner_type in ('Doanh nghiệp/nhà cung cấp','Trường đại học','Viện/tổ chức nghiên cứu');
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select record_id,(select user_id from review_actor),'normalize_partner_type',jsonb_build_object('partner_type',old),jsonb_build_object('partner_type',new) from partner_type_change;
update ai_management.partner_details d set partner_type=c.new from partner_type_change c where c.record_id=d.record_id;

-- A strategic partner is an engaged partner; the strategic level now has its own field.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select id,(select user_id from review_actor),'retire_strategic_status',jsonb_build_object('status',status),jsonb_build_object('status','Đang hợp tác')
from ai_management.records where kind='partner' and status='Chiến lược';
update ai_management.records set status='Đang hợp tác',version=version+1,updated_at=now() where kind='partner' and status='Chiến lược';

-- Units: every current unit is active; the Group's own head office is a Group body, the rest are member units.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select r.id,(select user_id from review_actor),'normalize_unit_status',jsonb_build_object('status',r.status),jsonb_build_object('status','Đang hoạt động')
from ai_management.records r where r.kind='unit' and r.status not in ('Đang hoạt động','Ngừng hoạt động');
update ai_management.records set status='Đang hoạt động',version=version+1,updated_at=now() where kind='unit' and status not in ('Đang hoạt động','Ngừng hoạt động');
alter table ai_management.unit_details add column unit_type text not null default 'Đơn vị thành viên'
  check (unit_type in ('Đơn vị thành viên','Ban/Văn phòng/Tổ chức thuộc Tập đoàn'));
update ai_management.unit_details set unit_type='Ban/Văn phòng/Tổ chức thuộc Tập đoàn' where abbreviation='PETROVIETNAM';

alter table ai_management.partner_details
  add column strategic_level text check (strategic_level in ('Không','Biên bản ghi nhớ cấp đơn vị','Biên bản ghi nhớ cấp tập đoàn','Hợp tác chiến lược cấp đơn vị','Hợp tác chiến lược cấp tập đoàn')),
  add constraint partner_details_partner_type_list check (partner_type in ('Công ty công nghệ','Đơn vị đào tạo và NCKH','Cơ quan nhà nước','Tư vấn','Truyền thông/sự kiện','Liên danh')),
  add constraint partner_details_country_list check (country in ('Việt Nam','Hoa Kỳ','Trung Quốc','Nhật Bản','Hàn Quốc','Singapore','Ấn Độ','Vương quốc Anh','Pháp','Đức','Hà Lan','Na Uy','Thụy Sĩ','Israel','Liên bang Nga','Các Tiểu vương quốc Ả Rập Thống nhất','Ả Rập Xê Út','Úc','Canada','Khác'));
alter table ai_management.partner_details drop column aliases, drop column legal_name, drop column origin, drop column document_notes, drop column internal_unit_code, drop column profile_url;
alter table ai_management.unit_details drop column capabilities, drop column governance;

-- The registry mirrors src/lib/catalog.ts (order, type and options).
update ai_management.module_registry set statuses=array['Đang hợp tác','Tiềm năng','Tạm dừng'], fields='[
 {"key":"short_name","type":"text","options":null},
 {"key":"partner_type","type":"select","options":["Công ty công nghệ","Đơn vị đào tạo và NCKH","Cơ quan nhà nước","Tư vấn","Truyền thông/sự kiện","Liên danh"]},
 {"key":"strategic_level","type":"select","options":["Không","Biên bản ghi nhớ cấp đơn vị","Biên bản ghi nhớ cấp tập đoàn","Hợp tác chiến lược cấp đơn vị","Hợp tác chiến lược cấp tập đoàn"]},
 {"key":"country","type":"select","options":["Việt Nam","Hoa Kỳ","Trung Quốc","Nhật Bản","Hàn Quốc","Singapore","Ấn Độ","Vương quốc Anh","Pháp","Đức","Hà Lan","Na Uy","Thụy Sĩ","Israel","Liên bang Nga","Các Tiểu vương quốc Ả Rập Thống nhất","Ả Rập Xê Út","Úc","Canada","Khác"]},
 {"key":"website","type":"url","options":null},
 {"key":"specialties","type":"tags","options":null}]'::jsonb where kind='partner';
update ai_management.module_registry set statuses=array['Đang hoạt động','Ngừng hoạt động'], fields='[
 {"key":"unit_type","type":"select","options":["Đơn vị thành viên","Ban/Văn phòng/Tổ chức thuộc Tập đoàn"]},
 {"key":"abbreviation","type":"text","options":null},
 {"key":"sector","type":"text","options":null},
 {"key":"address","type":"text","options":null},
 {"key":"website","type":"url","options":null}]'::jsonb where kind='unit';

-- Every member reads every record and file; roles alone decide who may write.
create or replace function ai_management.can_read_record(p_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.records r where r.id=p_id and ai_management.current_role() is not null)
$$;
create or replace function ai_management.can_read_document(p_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.documents d where d.id=p_id and d.archived_at is null and ai_management.current_role() is not null)
$$;
alter table ai_management.records drop column observed_on, drop column source_note, drop column visibility;
alter table ai_management.documents drop column visibility;

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

create or replace function public.ai_catalog_document_save(p_document jsonb) returns jsonb
language plpgsql security definer set search_path='' as $function$
declare did uuid; vid uuid; pathname text; doc ai_management.documents; next_version integer; object_meta jsonb;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_document,array['title','document_id','version_id','filename','mime_type','size_bytes','storage_path','checksum','record_id']);
 vid:=(p_document->>'version_id')::uuid; pathname:=p_document->>'storage_path';
 if vid is null or pathname is null or pathname !~ ('^'||auth.uid()::text||'/'||vid::text||'/file[.](pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|png|jpg|jpeg)$') or (p_document->>'filename') ~ '[[:cntrl:]/\\\\]' or (p_document->>'filename') in ('.','..') then raise exception 'VALIDATION: invalid storage path' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('ai-catalog:'||pathname,0));
 select metadata into object_meta from storage.objects where bucket_id='ai-catalog-documents' and name=pathname;
 if not found then raise exception 'VALIDATION: file must be uploaded first' using errcode='22023'; end if;
 if object_meta ? 'size' and (object_meta->>'size')::bigint is distinct from (p_document->>'size_bytes')::bigint then raise exception 'VALIDATION: size mismatch' using errcode='22023'; end if;
 if p_document ? 'document_id' and p_document->>'document_id' is not null then
  did:=(p_document->>'document_id')::uuid;
  select * into doc from ai_management.documents where id=did for update;
  if not found or not ai_management.can_read_document(did) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 else
  insert into ai_management.documents(title,created_by) values(btrim(p_document->>'title'),auth.uid()) returning * into doc; did:=doc.id;
 end if;
 select coalesce(max(version),0)+1 into next_version from ai_management.document_versions where document_id=did;
 insert into ai_management.document_versions(id,document_id,version,filename,mime_type,size_bytes,storage_path,checksum,created_by) values(vid,did,next_version,p_document->>'filename',p_document->>'mime_type',(p_document->>'size_bytes')::bigint,pathname,p_document->>'checksum',auth.uid());
 if nullif(p_document->>'record_id','') is not null then perform public.ai_catalog_document_link((p_document->>'record_id')::uuid,did,vid); end if;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(null,auth.uid(),'document_version',jsonb_build_object('document_id',did,'version_id',vid,'version',next_version));
 return ai_management.document_json(did);
exception when unique_violation then raise exception 'CONFLICT: document version already registered' using errcode='40001';
 when check_violation or not_null_violation or invalid_text_representation or numeric_value_out_of_range then raise exception 'VALIDATION: invalid document metadata' using errcode='22023';
end $function$;

-- Deleting a record removes it, its links and its own folders; files stay in the shared library.
-- The audit row keeps the full record so it can still be looked up later.
create or replace function public.ai_catalog_delete(p_id uuid,p_version integer) returns boolean
language plpgsql security definer set search_path='' as $function$
declare previous ai_management.records; folders uuid[];
begin
 perform ai_management.require_role(true);
 perform pg_advisory_xact_lock(73424910902411);
 select * into previous from ai_management.records where id=p_id for update;
 if not found or not ai_management.can_read_record(p_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if previous.version is distinct from p_version then raise exception 'CONFLICT' using errcode='40001'; end if;
 select coalesce(array_agg(f.id),'{}') into folders from ai_management.records f join ai_management.reference_details d on d.record_id=f.id
 where d.reference_type='Thư mục' and exists(select 1 from ai_management.relations l where l.source_id=f.id and l.target_id=p_id)
  and not exists(select 1 from ai_management.relations l where (l.source_id=f.id and l.target_id<>p_id) or l.target_id=f.id);
 insert into ai_management.audit(record_id,actor_id,action,before_value)
 select r.id,auth.uid(),'delete',jsonb_build_object('record',ai_management.record_json(r.id),
   'relations',(select coalesce(jsonb_agg(to_jsonb(l)),'[]'::jsonb) from ai_management.relations l where r.id in (l.source_id,l.target_id)),
   'document_ids',(select coalesce(jsonb_agg(d.document_id),'[]'::jsonb) from ai_management.document_links d where d.record_id=r.id),
   'source_ids',(select coalesce(jsonb_agg(l.source_id),'[]'::jsonb) from ai_management.source_links l where l.record_id=r.id))
 from ai_management.records r where r.id=p_id or r.id=any(folders);
 delete from ai_management.relations where source_id=p_id or target_id=p_id or source_id=any(folders);
 delete from ai_management.document_links where record_id=p_id or record_id=any(folders);
 delete from ai_management.source_links where record_id=p_id;
 update ai_management.sources set linked_record_id=null where linked_record_id=p_id;
 delete from ai_management.records where id=p_id or id=any(folders);
 return true;
end $function$;
revoke all on function public.ai_catalog_delete(uuid,integer) from public,anon;
grant execute on function public.ai_catalog_delete(uuid,integer) to authenticated;
drop function public.ai_catalog_archive(uuid,integer);
drop function public.ai_catalog_restore(uuid,integer);
-- Gateways still filter on archived_at; with deletion final the column stays empty for good.
alter table ai_management.records add constraint records_never_archived check (archived_at is null);

-- The overview carries the reviewed partner and unit classifications for dashboard filters and tag suggestions.
create or replace function public.ai_catalog_overview() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with v as (
  select r.id,r.kind,r.title,r.code,r.status,r.updated_at from ai_management.records r
  where r.kind in ('use_case','collaboration','partner','unit','expert','learning_event','engagement')
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
  'activities',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'type',d.cooperation_types,'start_date',d.start_date,'end_date',d.end_date,
    'partner_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'provider_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' and l.target_kind='unit' limit 1),
    'party_lead_id',(select l.context->>'lead_member_id' from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' limit 1),
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
