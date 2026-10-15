-- Reorganise the catalogue around the AI roadmap. Standard problems keep the
-- use_case kind and gain programme/priority fields; every concrete activity
-- (unit problem, POC, research topic, partner cooperation) keeps the
-- collaboration kind with one lifecycle. Columns are only added; hidden fields
-- keep their stored values. Survey objects and stored files are not changed.
begin;
select pg_advisory_xact_lock(73424910902411);

-- Standard problems: programme, leadership level, priority flag and start year.
alter table ai_management.use_case_details
 add column "program" text check(length("program")<=1000) check("program" in (
  'AI cho tìm kiếm, thăm dò và khai thác',
  'AI cho vận hành, hiệu suất, độ tin cậy và toàn vẹn tài sản',
  'AI cho hoạch định, thương mại và tối ưu chuỗi năng lượng',
  'AI cho dự án đầu tư, EPCI và quản lý dự án',
  'AI cho an toàn, môi trường, rủi ro và kiểm soát tuân thủ',
  'AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp',
  'AI cho nghiên cứu, đổi mới sáng tạo và sản phẩm, công nghệ')),
 add column "leadership_level" text check(length("leadership_level")<=1000) check("leadership_level" in (
  'Tập đoàn triển khai','Tập đoàn dẫn dắt, đơn vị triển khai','Đơn vị chủ động')),
 add column "is_priority" text check(length("is_priority")<=1000) check("is_priority" in ('Có','Không')),
 add column "start_year" numeric check("start_year" between 2000 and 2100 and "start_year"=trunc("start_year"));
update ai_management.module_registry set statuses=array['Chính thức','Chờ rà soát'], fields='[
 {"key":"program","type":"select","options":["AI cho tìm kiếm, thăm dò và khai thác","AI cho vận hành, hiệu suất, độ tin cậy và toàn vẹn tài sản","AI cho hoạch định, thương mại và tối ưu chuỗi năng lượng","AI cho dự án đầu tư, EPCI và quản lý dự án","AI cho an toàn, môi trường, rủi ro và kiểm soát tuân thủ","AI cho quản trị, điều hành và hiệu quả hoạt động doanh nghiệp","AI cho nghiên cứu, đổi mới sáng tạo và sản phẩm, công nghệ"]},
 {"key":"category","type":"text","options":null},
 {"key":"objective","type":"textarea","options":null},
 {"key":"is_priority","type":"select","options":["Có","Không"]},
 {"key":"leadership_level","type":"select","options":["Tập đoàn triển khai","Tập đoàn dẫn dắt, đơn vị triển khai","Đơn vị chủ động"]},
 {"key":"start_year","type":"number","options":null},
 {"key":"sector","type":"text","options":null},
 {"key":"scope","type":"textarea","options":null},
 {"key":"expected_value","type":"textarea","options":null}
]'::jsonb where kind='use_case';

-- Activities: the type becomes a free tag; add declared title, period and conclusion.
alter table ai_management.collaboration_details drop constraint collaboration_details_cooperation_type_check;
alter table ai_management.collaboration_details
 add column "declared_title" text check(length("declared_title")<=1000),
 add column "start_date" date,
 add column "end_date" date,
 add column "conclusion" text check(length("conclusion")<=10000),
 add constraint collaboration_details_period_check check(end_date is null or start_date is null or end_date>=start_date);
update ai_management.module_registry set statuses=array['Đề xuất','Đang trao đổi','POC','Triển khai chính thức','Pilot','Vận hành','Tạm dừng','Dừng'], fields='[
 {"key":"cooperation_types","type":"text","options":null},
 {"key":"declared_title","type":"text","options":null},
 {"key":"scope","type":"textarea","options":null},
 {"key":"lead","type":"text","options":null},
 {"key":"start_date","type":"date","options":null},
 {"key":"end_date","type":"date","options":null},
 {"key":"agreement","type":"text","options":null},
 {"key":"results","type":"textarea","options":null},
 {"key":"conclusion","type":"textarea","options":null},
 {"key":"source_status","type":"text","options":null},
 {"key":"last_meeting_date","type":"date","options":null},
 {"key":"next_notes","type":"textarea","options":null}
]'::jsonb where kind='collaboration';

-- Map every activity, including those in the trash, onto the single lifecycle.
-- Survey-derived records keep their original wording in the summary; prefer it.
create temporary table roadmap_activity_status on commit drop as
select r.id, r.status old_status, case
  when r.summary ~* 'Tình trạng (nguyên gốc|theo bài toán): *PoC' then 'POC'
  when r.summary ~* 'Tình trạng theo bài toán: *Đã ký kết' or r.summary ~* 'Tình trạng nguyên gốc: *Triển khai dự án chính thức' then 'Triển khai chính thức'
  when r.summary ~* 'Tình trạng theo bài toán: *Kết thúc' then 'Dừng'
  when r.summary ~* 'Tình trạng theo bài toán: *Khảo sát' then 'Đề xuất'
  when r.summary ~* 'Tình trạng nguyên gốc: *MoU' then 'Đang trao đổi'
  when r.status='Tiềm năng' then 'Đề xuất'
  when r.status in ('Đang trao đổi','Đang xác định phạm vi') then 'Đang trao đổi'
  when r.status='Đang thực hiện' then 'Triển khai chính thức'
  when r.status='Hoàn thành' then 'Vận hành'
  when r.status='Tạm dừng' then 'Tạm dừng'
  when r.status='Không tiếp tục' then 'Dừng'
  when r.status=any(array['Đề xuất','Đang trao đổi','POC','Triển khai chính thức','Pilot','Vận hành','Tạm dừng','Dừng']) then r.status
  else 'Đề xuất' end new_status
from ai_management.records r where r.kind='collaboration';
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select r.id,r.created_by,'normalize_activity_status',jsonb_build_object('status',m.old_status),jsonb_build_object('status',m.new_status)
from roadmap_activity_status m join ai_management.records r on r.id=m.id where m.new_status<>m.old_status;
update ai_management.records r set status=m.new_status, version=r.version+1
from roadmap_activity_status m where m.id=r.id and m.new_status<>m.old_status;

-- A single PVN subject without a role is the activity's lead subject.
update ai_management.relations l set context=l.context||jsonb_build_object('subject_role','lead')
from ai_management.records r
where r.id=l.source_id and r.kind='collaboration' and l.relation='unit' and coalesce(l.context->>'subject_role','')=''
 and (select count(*) from ai_management.relations other where other.source_id=l.source_id and other.relation='unit')=1;

-- Partners: the status now records the overall working relationship.
update ai_management.module_registry set statuses=array['Chiến lược','Đang hợp tác','Tiềm năng','Tạm dừng'] where kind='partner';
create temporary table roadmap_partner_status on commit drop as
select p.id, p.status old_status, case
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null
   and a.status in ('POC','Triển khai chính thức','Pilot','Vận hành')) then 'Đang hợp tác'
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null
   and a.status in ('Đề xuất','Đang trao đổi')) then 'Tiềm năng'
  when exists(select 1 from ai_management.relations l join ai_management.records a on a.id=l.source_id
   where l.target_id=p.id and l.relation='partner' and a.kind='collaboration' and a.archived_at is null) then 'Tạm dừng'
  else 'Tiềm năng' end new_status
from ai_management.records p
where p.kind='partner' and p.status not in ('Chiến lược','Đang hợp tác','Tiềm năng','Tạm dừng');
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select p.id,p.created_by,'derive_partner_status',jsonb_build_object('status',m.old_status),jsonb_build_object('status',m.new_status)
from roadmap_partner_status m join ai_management.records p on p.id=m.id;
update ai_management.records p set status=m.new_status, version=p.version+1 from roadmap_partner_status m where m.id=p.id;

-- Experts keep one profile: organisation, expertise and work history as text.
alter table ai_management.expert_details
 add column "organization" text check(length("organization")<=1000),
 add column "expertise_summary" text check(length("expertise_summary")<=10000),
 add column "work_history" text check(length("work_history")<=10000);
update ai_management.module_registry set fields='[
 {"key":"organization","type":"text","options":null},
 {"key":"expertise_summary","type":"textarea","options":null},
 {"key":"work_history","type":"textarea","options":null}
]'::jsonb||fields where kind='expert';

-- Training, workshops and courses share one record; the type is a free tag.
-- The fixed-list check is the column's second check constraint; find it by definition, keep the length limit.
do $$
declare fixed_list text;
begin
 for fixed_list in select conname from pg_constraint
  where conrelid='ai_management.learning_event_details'::regclass and contype='c' and pg_get_constraintdef(oid) like '%Lớp đào tạo%' loop
  execute format('alter table ai_management.learning_event_details drop constraint %I',fixed_list);
 end loop;
end $$;
update ai_management.module_registry set fields=(
 select jsonb_agg(case when f->>'key'='event_type' then jsonb_build_object('key','event_type','type','text','options',null) else f end order by n)
 from jsonb_array_elements(fields) with ordinality x(f,n)) where kind='learning_event';

-- Standard problems also name one priority lead unit (subject_role lead) and
-- many potential units (subject_role supporting); keep one lead per record.
create or replace function ai_management.enforce_collaboration_relation_cardinality() returns trigger
language plpgsql set search_path='' as $$
declare source_kind text;
begin
 if new.relation not in ('partner','use_case','unit') then return new; end if;
 perform pg_advisory_xact_lock(73424910902411);
 select kind into source_kind from ai_management.records where id=new.source_id;
 if source_kind not in ('collaboration','use_case') then return new; end if;
 if source_kind='collaboration' and new.relation in ('partner','use_case') and exists(
  select 1 from ai_management.relations existing
  where existing.source_id=new.source_id and existing.relation=new.relation and existing.id<>new.id
 ) then
  raise exception 'VALIDATION: activity accepts only one %',new.relation using errcode='22023';
 end if;
 if new.relation='unit' and new.context->>'subject_role'='lead' and exists(
  select 1 from ai_management.relations existing
  where existing.source_id=new.source_id and existing.relation='unit'
   and existing.context->>'subject_role'='lead' and existing.id<>new.id
 ) then
  raise exception 'VALIDATION: record accepts only one lead unit' using errcode='22023';
 end if;
 return new;
end $$;

create or replace function public.ai_catalog_collaboration_unit_link(p_link jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare source_record ai_management.records; target_record ai_management.records;
declare role text; ctx jsonb; item record; current_link ai_management.relations; result ai_management.relations;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_link,array['source_id','target_id','relation','note','context']);
 perform pg_advisory_xact_lock(73424910902411);
 select * into source_record from ai_management.records where id=(p_link->>'source_id')::uuid for update;
 select * into target_record from ai_management.records where id=(p_link->>'target_id')::uuid;
 ctx:=coalesce(p_link->'context','{}'::jsonb);
 role:=ctx->>'subject_role';
 if source_record.id is null or target_record.id is null or not ai_management.can_read_record(source_record.id) or not ai_management.can_read_record(target_record.id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(source_record.id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if source_record.archived_at is not null or target_record.archived_at is not null
  or source_record.kind not in ('collaboration','use_case') or target_record.kind<>'unit'
  or p_link->>'relation'<>'unit' or role not in ('lead','supporting') then
  raise exception 'VALIDATION: invalid unit role relation' using errcode='22023';
 end if;
 if jsonb_typeof(ctx)<>'object' or octet_length(ctx::text)>16000 then raise exception 'VALIDATION: invalid context' using errcode='22023'; end if;
 for item in select key,value from jsonb_each(ctx) loop
  if length(item.key)>80 or jsonb_typeof(item.value)<>'string' or length(item.value#>>'{}')>1000 then raise exception 'VALIDATION: invalid context value' using errcode='22023'; end if;
 end loop;
 if role='lead' then
  update ai_management.relations set context=context || jsonb_build_object('subject_role','supporting')
  where source_id=source_record.id and relation='unit' and target_id<>target_record.id and context->>'subject_role'='lead';
 end if;
 select * into current_link from ai_management.relations
 where source_id=source_record.id and target_id=target_record.id and relation='unit' for update;
 if current_link.id is null then return public.ai_catalog_link(p_link); end if;
 update ai_management.relations set context=ctx,
  note=case when p_link ? 'note' then nullif(p_link->>'note','') else current_link.note end
 where id=current_link.id returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
 values(source_record.id,auth.uid(),'link_context',to_jsonb(current_link),to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when check_violation or invalid_text_representation or not_null_violation then
 raise exception 'VALIDATION: invalid unit role relation' using errcode='22023';
end $$;

-- Activities may now be created from a standard problem, unit or partner page.
create or replace function public.ai_catalog_create_related_context(
  p_parent_id uuid,
  p_record jsonb,
  p_relation text,
  p_direction text,
  p_context jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare parent ai_management.records; child jsonb; child_id uuid;
declare consortium_id uuid;
begin
 perform ai_management.require_role(true);
 perform pg_advisory_xact_lock(73424910902411);
 select * into parent from ai_management.records where id=p_parent_id for update;
 if parent.id is null or not ai_management.can_read_record(p_parent_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_parent_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if parent.archived_at is not null then raise exception 'VALIDATION: archived record' using errcode='22023'; end if;
 if p_record is null or jsonb_typeof(p_record)<>'object' or p_record ? 'id'
  or p_direction is null or p_direction not in ('to-parent','from-parent')
  or p_context is null or jsonb_typeof(p_context)<>'object' then
  raise exception 'VALIDATION: invalid contextual creation' using errcode='22023';
 end if;
 child := public.ai_catalog_save(p_record);
 child_id := (child->>'id')::uuid;
 consortium_id := case when p_direction='to-parent' then child_id else p_parent_id end;
 if p_context ? 'consortium_role' then
  if p_relation<>'partner' or p_context->>'consortium_role' not in ('lead','member')
   or (select kind from ai_management.records where id=consortium_id)<>'partner'
   or (select kind from ai_management.records where id=case when p_direction='to-parent' then p_parent_id else child_id end)<>'partner' then
   raise exception 'VALIDATION: invalid consortium relation' using errcode='22023';
  end if;
  if p_context->>'consortium_role'='lead' then
   update ai_management.relations set context=(context - 'Vai trò' - 'role') || jsonb_build_object('consortium_role','member')
   where source_id=consortium_id and relation='partner'
    and coalesce(context->>'consortium_role',context->>'role',context->>'Vai trò') in ('lead','Đầu mối liên danh','Đứng đầu liên danh');
  end if;
 end if;
 perform public.ai_catalog_link(jsonb_build_object(
  'source_id',consortium_id,
  'target_id',case when p_direction='to-parent' then p_parent_id else child_id end,
  'relation',p_relation,
  'context',p_context));
 return child;
end $$;

-- Same projection as before, plus one consortium hop: a member partner sees
-- the activities signed by a consortium it belongs to ("Qua liên danh …").
create or replace function public.ai_catalog_dossier(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare detail jsonb; related jsonb; attachments jsonb;
begin
 detail := public.ai_catalog_get(p_id);
 with direct as (
  select r.id, null::uuid via_id, l.relation,
   case when l.source_id=p_id then 'outgoing' else 'incoming' end direction, 1 depth
  from ai_management.relations l
  join ai_management.records r on r.id=case when l.source_id=p_id then l.target_id else l.source_id end
  where (l.source_id=p_id or l.target_id=p_id)
   and r.archived_at is null and ai_management.can_read_record(r.id)
 ), paths as (
  select * from direct
  union all
  select r.id, d.id, l.relation,
   case when l.source_id=d.id then 'outgoing' else 'incoming' end, 2
  from direct d
  join ai_management.records bridge on bridge.id=d.id
  join ai_management.relations l on l.source_id=d.id or l.target_id=d.id
  join ai_management.records r on r.id=case when l.source_id=d.id then l.target_id else l.source_id end
  where r.id<>p_id and r.archived_at is null and ai_management.can_read_record(r.id)
   -- Operational records provide context. Never expand through another entity.
   and (l.relation<>'related' or (bridge.kind='engagement' and r.kind in ('demand','reference'))
    or (bridge.kind='collaboration' and r.kind='reference'))
   and case bridge.kind
    when 'demand' then r.kind='use_case' or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'implementation' then r.kind in ('use_case','partner','data_asset','poc') or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'poc' then r.kind in ('use_case','partner','data_asset','implementation') or (detail->'data'->>'kind'='use_case' and r.kind='unit')
    when 'collaboration' then r.kind in ('partner','use_case','collaboration_item','engagement','contact','expert','data_asset','reference') or (detail->'data'->>'kind' in ('partner','use_case') and r.kind='unit')
    when 'collaboration_item' then r.kind in ('collaboration','use_case','data_asset','partner')
    when 'engagement' then r.kind in ('contact','expert','learning_session','resource','demand','use_case','data_asset','reference') or (detail->'data'->>'kind'='expert' and r.kind='unit')
    when 'learning_event' then detail->'data'->>'kind'='course' and r.kind in ('contact','expert','learning_session','resource')
    when 'learning_session' then r.kind in ('contact','expert','resource')
    when 'affiliation' then (detail->'data'->>'kind'='expert' and r.kind in ('unit','partner'))
      or (detail->'data'->>'kind' in ('unit','partner') and r.kind='expert')
    when 'partner' then detail->'data'->>'kind'='partner' and d.relation='partner' and d.direction='incoming'
      and l.relation='partner' and l.target_id=d.id and r.kind='collaboration'
    else false end
 ), chosen as (
  select distinct on (id) * from paths order by id,depth,via_id,relation,direction
 )
 select coalesce(jsonb_agg(jsonb_build_object('record',ai_management.record_json(c.id),
  'via',case when c.via_id is null then null else ai_management.record_json(c.via_id) end,
  'relation',c.relation,'direction',c.direction) order by r.kind,r.title,r.id),'[]'::jsonb)
 into related from chosen c join ai_management.records r on r.id=c.id;
 -- Keep each record attachment distinct: the same document can be pinned to
 -- different versions in different engagements. Linking never grants read access.
 select coalesce(jsonb_agg(jsonb_build_object('record',entry->'record',
  'document',ai_management.document_json(l.document_id,l.version_id))
  order by entry->'record'->>'title',l.created_at,l.document_id),'[]'::jsonb)
 into attachments
 from jsonb_array_elements(related) entry
 join ai_management.document_links l on l.record_id=(entry->'record'->>'id')::uuid
 where entry->'record'->>'kind' not in ('unit','partner','use_case','expert','course')
  and ai_management.can_read_document(l.document_id);
 return detail || jsonb_build_object('related',related,'attachments',attachments);
end $$;

-- Compact, permission-filtered projection for tab dashboards and summary tables.
create function public.ai_catalog_overview() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 with v as (
  select r.id,r.kind,r.title,r.code,r.status,r.updated_at from ai_management.records r
  where r.archived_at is null and r.kind in ('use_case','collaboration','partner','unit','expert','learning_event','engagement')
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
    'partner_id',(select l.target_id from l where l.source_id=v.id and l.relation='partner' limit 1),
    'standard_id',(select l.target_id from l where l.source_id=v.id and l.relation='use_case' limit 1),
    'lead_unit_id',(select l.target_id from l where l.source_id=v.id and l.relation='unit' and l.context->>'subject_role'='lead' limit 1),
    'unit_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='unit')
   ) order by v.updated_at desc,v.id),'[]'::jsonb) from v join ai_management.collaboration_details d on d.record_id=v.id),
  'partners',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'status',v.status,'updated_at',v.updated_at,
    'short_name',d.short_name,'partner_type',d.partner_type,'country',d.country,
    'member_ids',(select coalesce(jsonb_agg(l.target_id),'[]'::jsonb) from l where l.source_id=v.id and l.relation='partner' and l.target_kind='partner')
   ) order by v.title),'[]'::jsonb) from v join ai_management.partner_details d on d.record_id=v.id),
  'units',(select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'updated_at',v.updated_at,
    'abbreviation',d.abbreviation,'sector',d.sector,
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
revoke all on function public.ai_catalog_dossier(uuid),public.ai_catalog_create_related_context(uuid,jsonb,text,text,jsonb),public.ai_catalog_collaboration_unit_link(jsonb) from public,anon;
grant execute on function public.ai_catalog_overview(),public.ai_catalog_dossier(uuid),public.ai_catalog_create_related_context(uuid,jsonb,text,text,jsonb),public.ai_catalog_collaboration_unit_link(jsonb) to authenticated;
commit;
