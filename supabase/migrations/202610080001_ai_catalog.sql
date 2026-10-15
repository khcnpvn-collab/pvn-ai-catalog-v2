-- Independent AI catalog. Additive only; no survey objects are changed.
-- Apply once with the database owner. All application writes go through checked gateways.
begin;
create schema ai_management;
revoke all on schema ai_management from public, anon, authenticated;
create table ai_management.memberships (
 user_id uuid primary key references auth.users(id), role text not null check(role in ('admin','editor','reader')),
 display_name text check(length(display_name)<=250), created_at timestamptz not null default now()
);
create table ai_management.module_registry (
 kind text primary key, statuses text[] not null, fields jsonb not null
);
create table ai_management.records (
 id uuid primary key default gen_random_uuid(), kind text not null references ai_management.module_registry(kind),
 title text not null check(length(btrim(title)) between 1 and 250), code text check(length(code)<=80),
 summary text check(length(summary)<=10000), status text not null,
 observed_on date, source_note text check(length(source_note)<=5000),
 visibility text not null default 'team' check(visibility in ('team','private')),
 version integer not null default 1 check(version>0), created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), archived_at timestamptz,
 unique(id,kind)
);
create index ai_catalog_records_kind_updated on ai_management.records(kind,updated_at desc);
create index ai_catalog_records_search on ai_management.records using gin(to_tsvector('simple',title||' '||coalesce(code,'')||' '||coalesce(summary,'')));
insert into ai_management.module_registry values ('unit',array['Đang hoạt động','Ngừng hoạt động','Chưa xác minh'],'[{"key": "abbreviation", "type": "text", "options": null}, {"key": "sector", "type": "text", "options": null}, {"key": "address", "type": "text", "options": null}, {"key": "website", "type": "url", "options": null}, {"key": "capabilities", "type": "textarea", "options": null}, {"key": "governance", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.unit_details (
 record_id uuid primary key,
 kind text not null default 'unit' check(kind='unit'),
 "abbreviation" text check(length("abbreviation")<=1000),
 "sector" text check(length("sector")<=1000),
 "address" text check(length("address")<=1000),
 "website" text check(length("website")<=1000) check("website" ~* '^https?://[^/\s]+'),
 "capabilities" text check(length("capabilities")<=10000),
 "governance" text check(length("governance")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('contact',array['Còn hiệu lực','Đã thay đổi','Chưa xác minh'],'[{"key": "position", "type": "text", "options": null}, {"key": "department", "type": "text", "options": null}, {"key": "email", "type": "email", "options": null}, {"key": "phone", "type": "text", "options": null}, {"key": "expertise", "type": "textarea", "options": null}, {"key": "biography", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.contact_details (
 record_id uuid primary key,
 kind text not null default 'contact' check(kind='contact'),
 "position" text check(length("position")<=1000),
 "department" text check(length("department")<=1000),
 "email" text check(length("email")<=1000) check("email" ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
 "phone" text check(length("phone")<=1000),
 "expertise" text check(length("expertise")<=10000),
 "biography" text check(length("biography")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('engagement',array['Đã diễn ra','Đang diễn ra','Dự kiến','Chưa xác minh'],'[{"key": "start_date", "type": "date", "options": null}, {"key": "end_date", "type": "date", "options": null}, {"key": "period_label", "type": "text", "options": null}, {"key": "location", "type": "text", "options": null}, {"key": "participants", "type": "textarea", "options": null}, {"key": "conclusions", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.engagement_details (
 record_id uuid primary key,
 kind text not null default 'engagement' check(kind='engagement'),
 "start_date" date,
 "end_date" date,
 "period_label" text check(length("period_label")<=1000),
 "location" text check(length("location")<=1000),
 "participants" text check(length("participants")<=10000),
 "conclusions" text check(length("conclusions")<=10000),
 check(end_date is null or start_date is null or end_date>=start_date),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('partner',array['Chưa xác minh','Đã xác minh','Cần bổ sung'],'[{"key": "legal_name", "type": "text", "options": null}, {"key": "aliases", "type": "text", "options": null}, {"key": "website", "type": "url", "options": null}, {"key": "specialties", "type": "textarea", "options": null}, {"key": "origin", "type": "text", "options": null}]'::jsonb);
create table ai_management.partner_details (
 record_id uuid primary key,
 kind text not null default 'partner' check(kind='partner'),
 "legal_name" text check(length("legal_name")<=1000),
 "aliases" text check(length("aliases")<=1000),
 "website" text check(length("website")<=1000) check("website" ~* '^https?://[^/\s]+'),
 "specialties" text check(length("specialties")<=10000),
 "origin" text check(length("origin")<=1000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('collaboration',array['Tiềm năng','Đang trao đổi','Đang xác định phạm vi','Đang thực hiện','Hoàn thành','Tạm dừng','Không tiếp tục','Chưa xác minh'],'[{"key": "scope", "type": "textarea", "options": null}, {"key": "lead", "type": "text", "options": null}, {"key": "results", "type": "textarea", "options": null}, {"key": "agreement", "type": "text", "options": null}]'::jsonb);
create table ai_management.collaboration_details (
 record_id uuid primary key,
 kind text not null default 'collaboration' check(kind='collaboration'),
 "scope" text check(length("scope")<=10000),
 "lead" text check(length("lead")<=1000),
 "results" text check(length("results")<=10000),
 "agreement" text check(length("agreement")<=1000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('collaboration_item',array['Đề xuất','Đang trao đổi','Đang thực hiện','Hoàn thành','Tạm dừng','Chưa xác minh'],'[{"key": "item_type", "type": "select", "options": ["CSDL", "Bài toán AI", "POC", "Giải pháp", "Đào tạo", "Tư vấn", "Khác"]}, {"key": "scope", "type": "textarea", "options": null}, {"key": "results", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.collaboration_item_details (
 record_id uuid primary key,
 kind text not null default 'collaboration_item' check(kind='collaboration_item'),
 "item_type" text check(length("item_type")<=1000) check("item_type" in ('CSDL','Bài toán AI','POC','Giải pháp','Đào tạo','Tư vấn','Khác')),
 "scope" text check(length("scope")<=10000),
 "results" text check(length("results")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('use_case',array['Chưa xác minh','Đã xác minh','Cần bổ sung'],'[{"key": "category", "type": "text", "options": null}, {"key": "sector", "type": "text", "options": null}, {"key": "objective", "type": "textarea", "options": null}, {"key": "scope", "type": "textarea", "options": null}, {"key": "expected_value", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.use_case_details (
 record_id uuid primary key,
 kind text not null default 'use_case' check(kind='use_case'),
 "category" text check(length("category")<=1000),
 "sector" text check(length("sector")<=1000),
 "objective" text check(length("objective")<=10000),
 "scope" text check(length("scope")<=10000),
 "expected_value" text check(length("expected_value")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('demand',array['Chưa xác minh','Đã xác minh','Cần bổ sung'],'[{"key": "original_title", "type": "text", "options": null}, {"key": "scope", "type": "textarea", "options": null}, {"key": "business_owner", "type": "text", "options": null}, {"key": "expectations", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.demand_details (
 record_id uuid primary key,
 kind text not null default 'demand' check(kind='demand'),
 "original_title" text check(length("original_title")<=1000),
 "scope" text check(length("scope")<=10000),
 "business_owner" text check(length("business_owner")<=1000),
 "expectations" text check(length("expectations")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('data_asset',array['Đang sử dụng','Đang chuẩn bị','Chưa sẵn sàng','Chưa xác minh'],'[{"key": "source_system", "type": "text", "options": null}, {"key": "format", "type": "text", "options": null}, {"key": "coverage", "type": "textarea", "options": null}, {"key": "owner", "type": "text", "options": null}, {"key": "quality", "type": "text", "options": null}, {"key": "access_conditions", "type": "textarea", "options": null}, {"key": "classification", "type": "text", "options": null}, {"key": "frequency", "type": "text", "options": null}]'::jsonb);
create table ai_management.data_asset_details (
 record_id uuid primary key,
 kind text not null default 'data_asset' check(kind='data_asset'),
 "source_system" text check(length("source_system")<=1000),
 "format" text check(length("format")<=1000),
 "coverage" text check(length("coverage")<=10000),
 "owner" text check(length("owner")<=1000),
 "quality" text check(length("quality")<=1000),
 "access_conditions" text check(length("access_conditions")<=10000),
 "classification" text check(length("classification")<=1000),
 "frequency" text check(length("frequency")<=1000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('implementation',array['Khảo sát','POC','Pilot','Đang triển khai','Vận hành','Tạm dừng','Kết thúc','Chưa xác minh'],'[{"key": "scope", "type": "textarea", "options": null}, {"key": "solution", "type": "text", "options": null}, {"key": "results", "type": "textarea", "options": null}, {"key": "obstacles", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.implementation_details (
 record_id uuid primary key,
 kind text not null default 'implementation' check(kind='implementation'),
 "scope" text check(length("scope")<=10000),
 "solution" text check(length("solution")<=1000),
 "results" text check(length("results")<=10000),
 "obstacles" text check(length("obstacles")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('poc',array['Chuẩn bị','Đang thử nghiệm','Đã kết thúc','Tạm dừng','Chưa xác minh'],'[{"key": "hypothesis", "type": "textarea", "options": null}, {"key": "approach", "type": "textarea", "options": null}, {"key": "criteria", "type": "textarea", "options": null}, {"key": "results", "type": "textarea", "options": null}, {"key": "conclusion", "type": "select", "options": ["Chưa đánh giá", "Đạt", "Đạt có điều kiện", "Không đạt", "Chưa đủ bằng chứng"]}]'::jsonb);
create table ai_management.poc_details (
 record_id uuid primary key,
 kind text not null default 'poc' check(kind='poc'),
 "hypothesis" text check(length("hypothesis")<=10000),
 "approach" text check(length("approach")<=10000),
 "criteria" text check(length("criteria")<=10000),
 "results" text check(length("results")<=10000),
 "conclusion" text check(length("conclusion")<=1000) check("conclusion" in ('Chưa đánh giá','Đạt','Đạt có điều kiện','Không đạt','Chưa đủ bằng chứng')),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('course',array['Đang sử dụng','Tham khảo','Ngừng sử dụng','Chưa xác minh'],'[{"key": "topic", "type": "text", "options": null}, {"key": "audience", "type": "text", "options": null}, {"key": "objectives", "type": "textarea", "options": null}, {"key": "syllabus", "type": "textarea", "options": null}, {"key": "edition", "type": "text", "options": null}, {"key": "duration_hours", "type": "number", "options": null}, {"key": "prerequisites", "type": "text", "options": null}]'::jsonb);
create table ai_management.course_details (
 record_id uuid primary key,
 kind text not null default 'course' check(kind='course'),
 "topic" text check(length("topic")<=1000),
 "audience" text check(length("audience")<=1000),
 "objectives" text check(length("objectives")<=10000),
 "syllabus" text check(length("syllabus")<=10000),
 "edition" text check(length("edition")<=1000),
 "duration_hours" numeric check("duration_hours" between 0 and 100000000),
 "prerequisites" text check(length("prerequisites")<=1000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('learning_event',array['Dự kiến','Đang diễn ra','Đã tổ chức','Hoãn','Hủy','Chưa xác minh'],'[{"key": "event_type", "type": "select", "options": ["Lớp đào tạo", "Hội thảo", "Tọa đàm", "Kết hợp"]}, {"key": "topic", "type": "text", "options": null}, {"key": "start_date", "type": "date", "options": null}, {"key": "end_date", "type": "date", "options": null}, {"key": "period_label", "type": "text", "options": null}, {"key": "format", "type": "select", "options": ["Trực tiếp", "Trực tuyến", "Kết hợp"]}, {"key": "location", "type": "text", "options": null}, {"key": "audience", "type": "text", "options": null}, {"key": "agenda", "type": "textarea", "options": null}, {"key": "course_edition", "type": "textarea", "options": null}, {"key": "reported_attendees", "type": "number", "options": null}, {"key": "attendance_source", "type": "textarea", "options": null}, {"key": "results", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.learning_event_details (
 record_id uuid primary key,
 kind text not null default 'learning_event' check(kind='learning_event'),
 "event_type" text check(length("event_type")<=1000) check("event_type" in ('Lớp đào tạo','Hội thảo','Tọa đàm','Kết hợp')),
 "topic" text check(length("topic")<=1000),
 "start_date" date,
 "end_date" date,
 "period_label" text check(length("period_label")<=1000),
 "format" text check(length("format")<=1000) check("format" in ('Trực tiếp','Trực tuyến','Kết hợp')),
 "location" text check(length("location")<=1000),
 "audience" text check(length("audience")<=1000),
 "agenda" text check(length("agenda")<=10000),
 "course_edition" text check(length("course_edition")<=10000),
 "reported_attendees" numeric check("reported_attendees" between 0 and 100000000),
 "attendance_source" text check(length("attendance_source")<=10000),
 "results" text check(length("results")<=10000),
 check(end_date is null or start_date is null or end_date>=start_date),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('learning_session',array['Dự kiến','Đã diễn ra','Chưa xác minh'],'[{"key": "topic", "type": "text", "options": null}, {"key": "session_date", "type": "date", "options": null}, {"key": "time_label", "type": "text", "options": null}, {"key": "content", "type": "textarea", "options": null}, {"key": "conclusions", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.learning_session_details (
 record_id uuid primary key,
 kind text not null default 'learning_session' check(kind='learning_session'),
 "topic" text check(length("topic")<=1000),
 "session_date" date,
 "time_label" text check(length("time_label")<=1000),
 "content" text check(length("content")<=10000),
 "conclusions" text check(length("conclusions")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
insert into ai_management.module_registry values ('resource',array['Chưa xác minh','Đã xác minh','Cần bổ sung'],'[{"key": "resource_type", "type": "select", "options": ["Slide", "Bài đọc", "Bài tập", "Video", "Biểu mẫu", "Liên kết", "Khác"]}, {"key": "topic", "type": "text", "options": null}, {"key": "author", "type": "text", "options": null}, {"key": "language", "type": "text", "options": null}, {"key": "external_url", "type": "url", "options": null}, {"key": "sharing_terms", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.resource_details (
 record_id uuid primary key,
 kind text not null default 'resource' check(kind='resource'),
 "resource_type" text check(length("resource_type")<=1000) check("resource_type" in ('Slide','Bài đọc','Bài tập','Video','Biểu mẫu','Liên kết','Khác')),
 "topic" text check(length("topic")<=1000),
 "author" text check(length("author")<=1000),
 "language" text check(length("language")<=1000),
 "external_url" text check(length("external_url")<=1000) check("external_url" ~* '^https?://[^/\s]+'),
 "sharing_terms" text check(length("sharing_terms")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
create table ai_management.relations (
 id uuid primary key default gen_random_uuid(), source_id uuid not null references ai_management.records(id),
 target_id uuid not null references ai_management.records(id), relation text not null check(relation in ('related','parent','unit','partner','contact','use_case','data','collaboration','course','event','speaker','participant','organizer','resource')),
 note text check(length(note)<=5000), context jsonb not null default '{}'::jsonb check(jsonb_typeof(context)='object'),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 check(source_id<>target_id), unique(source_id,target_id,relation)
);
create index ai_catalog_relations_target on ai_management.relations(target_id);
create unique index ai_catalog_one_parent on ai_management.relations(source_id) where relation='parent';
create table ai_management.documents (
 id uuid primary key default gen_random_uuid(), title text not null check(length(btrim(title)) between 1 and 250),
 visibility text not null check(visibility in ('team','private')), created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table ai_management.document_versions (
 id uuid primary key, document_id uuid not null references ai_management.documents(id),
 version integer not null check(version>0), filename text not null check(length(filename) between 1 and 250),
 mime_type text not null check(length(mime_type) between 1 and 200), size_bytes bigint not null check(size_bytes between 1 and 20971520),
 storage_path text not null unique, checksum text not null check(checksum ~ '^[0-9a-f]{64}$'),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 unique(document_id,version), unique(id,document_id)
);
create table ai_management.document_links (
 record_id uuid not null references ai_management.records(id), document_id uuid not null references ai_management.documents(id),
 version_id uuid, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 primary key(record_id,document_id), foreign key(version_id,document_id) references ai_management.document_versions(id,document_id)
);
create table ai_management.sources (
 id uuid primary key default gen_random_uuid(), source_key text not null unique check(length(source_key) between 1 and 500),
 source_type text not null check(length(source_type) between 1 and 100), title text not null check(length(title) between 1 and 250),
 unit_code text check(length(unit_code)<=100), payload jsonb not null check(jsonb_typeof(payload)='object' and octet_length(payload::text)<=2097152),
 status text not null default 'pending' check(status in ('pending','linked')), linked_record_id uuid references ai_management.records(id),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table ai_management.source_links (
 source_id uuid not null references ai_management.sources(id), record_id uuid not null references ai_management.records(id),
 created_by uuid not null references auth.users(id), created_at timestamptz not null default now(),
 primary key(source_id,record_id)
);
create index ai_catalog_source_links_record on ai_management.source_links(record_id);
create table ai_management.audit (
 id bigint generated always as identity primary key, record_id uuid references ai_management.records(id),
 actor_id uuid not null references auth.users(id), action text not null, before_value jsonb, after_value jsonb,
 created_at timestamptz not null default now()
);
create index ai_catalog_audit_record on ai_management.audit(record_id,created_at desc);

create function ai_management.current_role() returns text language sql stable security definer set search_path='' as $$
 select role from ai_management.memberships where user_id=auth.uid()
$$;
create function ai_management.require_role(p_write boolean default false,p_admin boolean default false) returns text language plpgsql stable security definer set search_path='' as $$
declare r text:=ai_management.current_role();
begin
 if r is null or (p_write and r='reader') or (p_admin and r<>'admin') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 return r;
end $$;
create function ai_management.can_read_record(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.records r where r.id=p_id and ai_management.current_role() is not null and (r.visibility='team' or r.created_by=auth.uid() or ai_management.current_role()='admin'))
$$;
create function ai_management.can_write_record(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select ai_management.current_role() in ('admin','editor') and ai_management.can_read_record(p_id)
$$;
create function ai_management.can_read_document(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.documents d where d.id=p_id and ai_management.current_role() is not null and (d.visibility='team' or d.created_by=auth.uid() or ai_management.current_role()='admin'))
$$;
create function ai_management.record_json(p_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r ai_management.records; d jsonb;
begin
 if not ai_management.can_read_record(p_id) then return null; end if;
 select * into r from ai_management.records where id=p_id;
 execute format('select to_jsonb(d)-''record_id''-''kind'' from ai_management.%I d where record_id=$1',r.kind||'_details') into d using p_id;
 return to_jsonb(r)||jsonb_build_object('data',coalesce(d,'{}'::jsonb));
end $$;
create function ai_management.document_json(p_id uuid,p_pin uuid default null) returns jsonb language sql stable security definer set search_path='' as $$
 select to_jsonb(d)||jsonb_build_object('versions',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'document_id',v.document_id,'version',v.version,'filename',v.filename,'mime_type',v.mime_type,'size_bytes',v.size_bytes,'created_at',v.created_at) order by version desc) from ai_management.document_versions v where v.document_id=d.id and (p_pin is null or v.id=p_pin)),'[]'::jsonb), 'linked_records',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'kind',r.kind)) from ai_management.document_links l join ai_management.records r on r.id=l.record_id where l.document_id=d.id and ai_management.can_read_record(r.id)),'[]'::jsonb))
 from ai_management.documents d where d.id=p_id and ai_management.can_read_document(d.id)
$$;
create function ai_management.reject_unknown(p_value jsonb,p_keys text[]) returns void language plpgsql immutable set search_path='' as $$
begin
 if p_value is null or jsonb_typeof(p_value)<>'object' or exists(select 1 from jsonb_object_keys(p_value) k where not(k=any(p_keys))) then raise exception 'VALIDATION: unknown fields or invalid object' using errcode='22023'; end if;
end $$;
create function ai_management.immutable_row() returns trigger language plpgsql set search_path='' as $$
begin raise exception 'FORBIDDEN: immutable history' using errcode='42501'; end $$;
create trigger ai_catalog_versions_immutable before update or delete on ai_management.document_versions for each row execute function ai_management.immutable_row();
create trigger ai_catalog_audit_immutable before update or delete on ai_management.audit for each row execute function ai_management.immutable_row();
create function ai_management.source_immutable() returns trigger language plpgsql set search_path='' as $$
begin
 if new.source_key is distinct from old.source_key or new.source_type is distinct from old.source_type or new.title is distinct from old.title or new.unit_code is distinct from old.unit_code or new.payload is distinct from old.payload or new.created_by is distinct from old.created_by or new.created_at is distinct from old.created_at or new.id is distinct from old.id then raise exception 'FORBIDDEN: immutable source snapshot' using errcode='42501'; end if;
 return new;
end $$;
create trigger ai_catalog_sources_immutable before update on ai_management.sources for each row execute function ai_management.source_immutable();
create trigger ai_catalog_sources_no_delete before delete on ai_management.sources for each row execute function ai_management.immutable_row();

create function public.ai_catalog_membership() returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('user_id',user_id,'role',role,'display_name',display_name) from ai_management.memberships where user_id=auth.uid()
$$;
create function public.ai_catalog_list(p_kind text default null,p_query text default '',p_status text default null,p_page integer default 1,p_archived boolean default false) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; total bigint;
begin
 perform ai_management.require_role();
 if p_page is null or p_page<1 or p_page>100000 or length(coalesce(p_query,''))>500 then raise exception 'VALIDATION: invalid filter' using errcode='22023'; end if;
 if p_kind is not null and not exists(select 1 from ai_management.module_registry where kind=p_kind) then raise exception 'VALIDATION: invalid kind' using errcode='22023'; end if;
 select count(*) into total from ai_management.records r where ai_management.can_read_record(r.id) and (p_kind is null or r.kind=p_kind) and (p_status is null or r.status=p_status) and (r.archived_at is not null)=p_archived and (coalesce(p_query,'')='' or strpos(lower(r.title||' '||coalesce(r.code,'')||' '||coalesce(r.summary,'')),lower(p_query))>0);
 select coalesce(jsonb_agg(ai_management.record_json(x.id) order by x.updated_at desc,x.id),'[]'::jsonb) into result from (select r.id,r.updated_at from ai_management.records r where ai_management.can_read_record(r.id) and (p_kind is null or r.kind=p_kind) and (p_status is null or r.status=p_status) and (r.archived_at is not null)=p_archived and (coalesce(p_query,'')='' or strpos(lower(r.title||' '||coalesce(r.code,'')||' '||coalesce(r.summary,'')),lower(p_query))>0) order by r.updated_at desc,r.id limit 30 offset (p_page-1)*30) x;
 return jsonb_build_object('data',result,'total',total,'page',p_page,'pageSize',30);
end $$;
create function public.ai_catalog_get(p_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb; links jsonb; documents jsonb; history jsonb;
begin
 perform ai_management.require_role(); result:=ai_management.record_json(p_id);
 if result is null then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 select coalesce(jsonb_agg((to_jsonb(l)-'created_by'-'created_at')||jsonb_build_object('source',ai_management.record_json(l.source_id),'target',ai_management.record_json(l.target_id)) order by l.created_at),'[]'::jsonb) into links from ai_management.relations l where (l.source_id=p_id or l.target_id=p_id) and ai_management.can_read_record(l.source_id) and ai_management.can_read_record(l.target_id);
 select coalesce(jsonb_agg(ai_management.document_json(l.document_id,l.version_id) order by l.created_at),'[]'::jsonb) into documents from ai_management.document_links l where l.record_id=p_id and ai_management.can_read_document(l.document_id);
 select coalesce(jsonb_agg(to_jsonb(a) order by a.id desc),'[]'::jsonb) into history from (select id,record_id,actor_id,action,created_at from ai_management.audit where record_id=p_id order by id desc limit 100) a;
 return jsonb_build_object('data',result,'links',links,'documents',documents,'history',history);
end $$;
create function public.ai_catalog_save(p_record jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare k text; rid uuid; previous ai_management.records; details jsonb; field jsonb; value jsonb; collist text; datalist text; updater text; result jsonb; columns_allowed text[]; common_key text;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_record,array['id','kind','title','code','summary','status','observed_on','source_note','visibility','version','data']);
 for common_key in select unnest(array['kind','title','code','summary','status','observed_on','source_note','visibility']) loop
  if p_record ? common_key and p_record->common_key<>'null'::jsonb and jsonb_typeof(p_record->common_key)<>'string' then raise exception 'VALIDATION: expected common text field' using errcode='22023'; end if;
 end loop;
 if p_record ? 'version' and (jsonb_typeof(p_record->'version')<>'number' or (p_record->>'version') !~ '^[1-9][0-9]*$') then raise exception 'VALIDATION: invalid version' using errcode='22023'; end if;
 k:=p_record->>'kind';
 if not exists(select 1 from ai_management.module_registry where kind=k and p_record->>'status'=any(statuses)) or p_record->>'visibility' not in ('team','private') or p_record->>'visibility' is null or jsonb_typeof(p_record->'title') is distinct from 'string' then raise exception 'VALIDATION: invalid record' using errcode='22023'; end if;
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
 end loop;
 if nullif(p_record->>'observed_on','') is not null and ((p_record->>'observed_on') !~ '^\d{4}-\d{2}-\d{2}$' or to_char((p_record->>'observed_on')::date,'YYYY-MM-DD')<>(p_record->>'observed_on')) then raise exception 'VALIDATION: invalid observed date' using errcode='22023'; end if;
 if p_record ? 'id' then
  rid:=(p_record->>'id')::uuid;
  select * into previous from ai_management.records where id=rid for update;
  if not found or not ai_management.can_read_record(rid) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
  if not ai_management.can_write_record(rid) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
  if previous.archived_at is not null then raise exception 'VALIDATION: archived record' using errcode='22023'; end if;
  if previous.version is distinct from (p_record->>'version')::integer then raise exception 'CONFLICT' using errcode='40001'; end if;
  if p_record->>'visibility'='private' and previous.created_by<>auth.uid() and ai_management.current_role()<>'admin' then raise exception 'FORBIDDEN: only creator or admin can make a record private' using errcode='42501'; end if;
  if previous.kind<>k then raise exception 'VALIDATION: kind cannot change' using errcode='22023'; end if;
  update ai_management.records set title=btrim(p_record->>'title'),code=nullif(p_record->>'code',''),summary=nullif(p_record->>'summary',''),status=p_record->>'status',observed_on=nullif(p_record->>'observed_on','')::date,source_note=nullif(p_record->>'source_note',''),visibility=p_record->>'visibility',version=version+1,updated_at=now() where id=rid;
 else
  insert into ai_management.records(kind,title,code,summary,status,observed_on,source_note,visibility,created_by) values(k,btrim(p_record->>'title'),nullif(p_record->>'code',''),nullif(p_record->>'summary',''),p_record->>'status',nullif(p_record->>'observed_on','')::date,nullif(p_record->>'source_note',''),p_record->>'visibility',auth.uid()) returning id into rid;
 end if;
 select string_agg(format('%I',f->>'key'),','),string_agg(format('x.%I',f->>'key'),','),string_agg(format('%I=excluded.%I',f->>'key',f->>'key'),',') into collist,datalist,updater from ai_management.module_registry m cross join lateral jsonb_array_elements(m.fields) f where m.kind=k;
 execute format('insert into ai_management.%I(record_id,%s) select $1,%s from jsonb_populate_record(null::ai_management.%I,$2) x on conflict(record_id) do update set %s',k||'_details',collist,datalist,k||'_details',updater) using rid,details;
 result:=ai_management.record_json(rid);
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value) values(rid,auth.uid(),case when previous.id is null then 'create' else 'update' end,case when previous.id is null then null else to_jsonb(previous) end,result);
 return result;
exception when check_violation or not_null_violation or invalid_text_representation or datetime_field_overflow or invalid_datetime_format or numeric_value_out_of_range then raise exception 'VALIDATION: invalid fields' using errcode='22023';
end $$;
create function public.ai_catalog_archive(p_id uuid,p_version integer) returns boolean language plpgsql security definer set search_path='' as $$
declare previous ai_management.records;
begin
 perform ai_management.require_role(true);
 select * into previous from ai_management.records where id=p_id for update;
 if not found or not ai_management.can_read_record(p_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if previous.version is distinct from p_version then raise exception 'CONFLICT' using errcode='40001'; end if;
 if previous.archived_at is not null then raise exception 'VALIDATION: already archived' using errcode='22023'; end if;
 update ai_management.records set archived_at=now(),updated_at=now(),version=version+1 where id=p_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value,after_value) values(p_id,auth.uid(),'archive',to_jsonb(previous),ai_management.record_json(p_id));
 return true;
end $$;
create function public.ai_catalog_stats() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare counts jsonb; recent jsonb;
begin
 perform ai_management.require_role();
 select jsonb_object_agg(m.kind,coalesce(x.c,0)) into counts from ai_management.module_registry m left join (select r.kind,count(*) c from ai_management.records r where r.archived_at is null and ai_management.can_read_record(r.id) group by r.kind) x using(kind);
 select coalesce(jsonb_agg(ai_management.record_json(x.id) order by x.updated_at desc),'[]'::jsonb) into recent from (select id,updated_at from ai_management.records where archived_at is null and ai_management.can_read_record(id) order by updated_at desc limit 10) x;
 return jsonb_build_object('counts',counts,'recent',recent);
end $$;
create function public.ai_catalog_link(p_link jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
 if s.archived_at is not null or t.archived_at is not null or s.id=t.id then raise exception 'VALIDATION: invalid relation endpoints' using errcode='22023'; end if;
 rel:=p_link->>'relation'; ctx:=coalesce(p_link->'context','{}'::jsonb);
 if jsonb_typeof(ctx)<>'object' or octet_length(ctx::text)>16000 then raise exception 'VALIDATION: invalid context' using errcode='22023'; end if;
 for item in select key,value from jsonb_each(ctx) loop
  if length(item.key)>80 or jsonb_typeof(item.value)<>'string' or length(item.value#>>'{}')>1000 then raise exception 'VALIDATION: invalid context value' using errcode='22023'; end if;
 end loop;
 if not (case rel
  when 'related' then true
  when 'parent' then (s.kind=t.kind and s.kind in ('use_case','unit')) or (s.kind='collaboration_item' and t.kind='collaboration') or (s.kind='learning_session' and t.kind in ('learning_event','engagement')) or (s.kind='learning_event' and t.kind='course')
  when 'unit' then t.kind='unit'
  when 'partner' then t.kind='partner'
  when 'contact' then t.kind='contact'
  when 'use_case' then t.kind='use_case'
  when 'data' then t.kind='data_asset'
  when 'collaboration' then t.kind='collaboration'
  when 'course' then t.kind='course' and s.kind in ('learning_event','learning_session','resource','collaboration_item','contact')
  when 'event' then t.kind in ('learning_event','engagement') and s.kind in ('learning_session','contact','resource','unit','partner')
  when 'speaker' then t.kind='contact' and s.kind in ('course','learning_event','learning_session','engagement')
  when 'participant' then t.kind='contact' and s.kind in ('learning_event','learning_session','engagement')
  when 'organizer' then t.kind in ('unit','partner') and s.kind in ('course','learning_event','learning_session','engagement')
  when 'resource' then t.kind='resource'
  else false end) then raise exception 'VALIDATION: incompatible relation kinds' using errcode='22023'; end if;
 if rel='parent' and exists(with recursive ancestors(id) as (select t.id union select r.target_id from ai_management.relations r join ancestors a on r.source_id=a.id where r.relation='parent') select 1 from ancestors where id=s.id) then raise exception 'VALIDATION: parent cycle' using errcode='22023'; end if;
 insert into ai_management.relations(source_id,target_id,relation,note,context,created_by) values(s.id,t.id,rel,nullif(p_link->>'note',''),ctx,auth.uid()) returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(s.id,auth.uid(),'link',to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when unique_violation then raise exception 'CONFLICT: relation already exists or parent already assigned' using errcode='40001';
 when check_violation or invalid_text_representation or not_null_violation then raise exception 'VALIDATION: invalid relation' using errcode='22023';
end $$;
create function public.ai_catalog_unlink(p_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare previous ai_management.relations; source_archived timestamptz;
begin
 perform ai_management.require_role(true);
 perform pg_advisory_xact_lock(73424910902411);
 select * into previous from ai_management.relations where id=p_id for update;
 if not found or not ai_management.can_read_record(previous.source_id) or not ai_management.can_read_record(previous.target_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(previous.source_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 select archived_at into source_archived from ai_management.records where id=previous.source_id for update;
 if source_archived is not null then raise exception 'VALIDATION: archived record' using errcode='22023'; end if;
 delete from ai_management.relations where id=p_id;
 insert into ai_management.audit(record_id,actor_id,action,before_value) values(previous.source_id,auth.uid(),'unlink',to_jsonb(previous));
 return true;
end $$;
create function public.ai_catalog_documents(p_query text default '') returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 if length(coalesce(p_query,''))>500 then raise exception 'VALIDATION: search too long' using errcode='22023'; end if;
 select coalesce(jsonb_agg(ai_management.document_json(x.id) order by x.created_at desc),'[]'::jsonb) into result from (select id,created_at from ai_management.documents where ai_management.can_read_document(id) and (coalesce(p_query,'')='' or strpos(lower(title),lower(p_query))>0) order by created_at desc limit 200) x;
 return result;
end $$;
create function public.ai_catalog_document_link(p_record_id uuid,p_document_id uuid,p_version_id uuid default null) returns boolean language plpgsql security definer set search_path='' as $$
begin
 perform ai_management.require_role(true);
 if not ai_management.can_read_record(p_record_id) or not ai_management.can_read_document(p_document_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if not ai_management.can_write_record(p_record_id) then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if exists(select 1 from ai_management.records where id=p_record_id and archived_at is not null) or (p_version_id is not null and not exists(select 1 from ai_management.document_versions where id=p_version_id and document_id=p_document_id)) then raise exception 'VALIDATION: invalid document attachment' using errcode='22023'; end if;
 insert into ai_management.document_links(record_id,document_id,version_id,created_by) values(p_record_id,p_document_id,p_version_id,auth.uid()) on conflict(record_id,document_id) do update set version_id=excluded.version_id,created_by=excluded.created_by,created_at=now();
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(p_record_id,auth.uid(),'document_link',jsonb_build_object('document_id',p_document_id,'version_id',p_version_id));
 return true;
end $$;
create function public.ai_catalog_document_save(p_document jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare did uuid; vid uuid; pathname text; doc ai_management.documents; next_version integer; object_meta jsonb;
begin
 perform ai_management.require_role(true);
 perform ai_management.reject_unknown(p_document,array['title','visibility','document_id','version_id','filename','mime_type','size_bytes','storage_path','checksum','record_id']);
 vid:=(p_document->>'version_id')::uuid; pathname:=p_document->>'storage_path';
 if vid is null or pathname is null or pathname !~ ('^'||auth.uid()::text||'/'||vid::text||'/file[.](pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|png|jpg|jpeg)$') or (p_document->>'filename') ~ '[[:cntrl:]/\\]' or (p_document->>'filename') in ('.','..') then raise exception 'VALIDATION: invalid storage path' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('ai-catalog:'||pathname,0));
 select metadata into object_meta from storage.objects where bucket_id='ai-catalog-documents' and name=pathname;
 if not found then raise exception 'VALIDATION: file must be uploaded first' using errcode='22023'; end if;
 if object_meta ? 'size' and (object_meta->>'size')::bigint is distinct from (p_document->>'size_bytes')::bigint then raise exception 'VALIDATION: size mismatch' using errcode='22023'; end if;
 if p_document ? 'document_id' and p_document->>'document_id' is not null then
  did:=(p_document->>'document_id')::uuid;
  select * into doc from ai_management.documents where id=did for update;
  if not found or not ai_management.can_read_document(did) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
  -- Existing document identity/visibility stays stable when adding a version.
  if (p_document->>'visibility') is distinct from doc.visibility then raise exception 'VALIDATION: document visibility cannot change through version upload' using errcode='22023'; end if;
 else
  insert into ai_management.documents(title,visibility,created_by) values(btrim(p_document->>'title'),p_document->>'visibility',auth.uid()) returning * into doc; did:=doc.id;
 end if;
 select coalesce(max(version),0)+1 into next_version from ai_management.document_versions where document_id=did;
 insert into ai_management.document_versions(id,document_id,version,filename,mime_type,size_bytes,storage_path,checksum,created_by) values(vid,did,next_version,p_document->>'filename',p_document->>'mime_type',(p_document->>'size_bytes')::bigint,pathname,p_document->>'checksum',auth.uid());
 if nullif(p_document->>'record_id','') is not null then perform public.ai_catalog_document_link((p_document->>'record_id')::uuid,did,vid); end if;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(null,auth.uid(),'document_version',jsonb_build_object('document_id',did,'version_id',vid,'version',next_version));
 return ai_management.document_json(did);
exception when unique_violation then raise exception 'CONFLICT: document version already registered' using errcode='40001';
 when check_violation or not_null_violation or invalid_text_representation or numeric_value_out_of_range then raise exception 'VALIDATION: invalid document metadata' using errcode='22023';
end $$;
create function public.ai_catalog_download(p_version_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role();
 select jsonb_build_object('storage_path',v.storage_path,'filename',v.filename) into result from ai_management.document_versions v where id=p_version_id and ai_management.can_read_document(v.document_id);
 if result is null then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 return result;
end $$;
create function public.ai_catalog_sources() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 perform ai_management.require_role(false,true);
 select coalesce(jsonb_agg((to_jsonb(s)-'created_by')||jsonb_build_object(
  'linked_record_id',case when ai_management.can_read_record(s.linked_record_id) then s.linked_record_id else null end,
  'linked_records',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'kind',r.kind) order by l.created_at,r.id) from ai_management.source_links l join ai_management.records r on r.id=l.record_id where l.source_id=s.id and ai_management.can_read_record(r.id)),'[]'::jsonb)
 ) order by s.created_at desc),'[]'::jsonb) into result from ai_management.sources s;
 return result;
end $$;
create function public.ai_catalog_source_save(p_source jsonb) returns boolean language plpgsql security definer set search_path='' as $$
declare rid uuid;
begin
 perform ai_management.require_role(true,true);
 perform ai_management.reject_unknown(p_source,array['source_key','source_type','title','unit_code','payload']);
 insert into ai_management.sources(source_key,source_type,title,unit_code,payload,created_by) values(p_source->>'source_key',p_source->>'source_type',p_source->>'title',p_source->>'unit_code',p_source->'payload',auth.uid()) on conflict(source_key) do nothing returning id into rid;
 if rid is not null then insert into ai_management.audit(actor_id,action,after_value) values(auth.uid(),'source_snapshot',jsonb_build_object('source_id',rid)); end if;
 return rid is not null;
exception when check_violation or not_null_violation then raise exception 'VALIDATION: invalid source snapshot' using errcode='22023';
end $$;
create function public.ai_catalog_source_link(p_source_id uuid,p_record_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare inserted boolean;
begin
 perform ai_management.require_role(true,true);
 if not ai_management.can_read_record(p_record_id) then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 -- Serialize first-link selection while preserving every approved split mapping.
 perform 1 from ai_management.sources where id=p_source_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 insert into ai_management.source_links(source_id,record_id,created_by) values(p_source_id,p_record_id,auth.uid()) on conflict(source_id,record_id) do nothing;
 inserted:=found;
 if inserted then
  update ai_management.sources set status='linked',linked_record_id=coalesce(linked_record_id,p_record_id) where id=p_source_id;
  insert into ai_management.audit(record_id,actor_id,action,after_value) values(p_record_id,auth.uid(),'source_link',jsonb_build_object('source_id',p_source_id));
 end if;
 return true;
end $$;
-- Default deny direct access. RLS remains enabled on every application table.
do $$
declare tab record;
begin
 for tab in select tablename from pg_tables where schemaname='ai_management' loop
  execute format('alter table ai_management.%I enable row level security',tab.tablename);
 end loop;
end $$;
create policy ai_catalog_membership_read on ai_management.memberships for select to authenticated using(user_id=auth.uid());
create policy ai_catalog_registry_read on ai_management.module_registry for select to authenticated using(ai_management.current_role() is not null);
create policy ai_catalog_records_read on ai_management.records for select to authenticated using(ai_management.can_read_record(id));
do $$
declare k text;
begin
 for k in select kind from ai_management.module_registry loop
  execute format('create policy ai_catalog_detail_read on ai_management.%I for select to authenticated using(ai_management.can_read_record(record_id))',k||'_details');
 end loop;
end $$;
create policy ai_catalog_relations_read on ai_management.relations for select to authenticated using(ai_management.can_read_record(source_id) and ai_management.can_read_record(target_id));
create policy ai_catalog_documents_read on ai_management.documents for select to authenticated using(ai_management.can_read_document(id));
create policy ai_catalog_versions_read on ai_management.document_versions for select to authenticated using(ai_management.can_read_document(document_id));
create policy ai_catalog_document_links_read on ai_management.document_links for select to authenticated using(ai_management.can_read_record(record_id) and ai_management.can_read_document(document_id));
create policy ai_catalog_sources_read on ai_management.sources for select to authenticated using(ai_management.current_role()='admin');
create policy ai_catalog_source_links_read on ai_management.source_links for select to authenticated using(ai_management.current_role()='admin' and ai_management.can_read_record(record_id));
create policy ai_catalog_audit_read on ai_management.audit for select to authenticated using(ai_management.current_role()='admin');

insert into storage.buckets(id,name,public,file_size_limit) values('ai-catalog-documents','ai-catalog-documents',false,20971520);
create function ai_management.storage_upload_allowed(p_name text) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce(ai_management.current_role() in ('admin','editor') and p_name ~ ('^'||auth.uid()::text||'/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[A-Za-z0-9._-]+$') and split_part(p_name,'/',3) not in ('.','..') and not exists(select 1 from ai_management.document_versions where storage_path=p_name),false)
$$;
create function ai_management.storage_read_allowed(p_name text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.document_versions v where v.storage_path=p_name and ai_management.can_read_document(v.document_id)) or ai_management.storage_upload_allowed(p_name)
$$;
-- Coordinate orphan cleanup and registration: once registered a stored object is immutable.
create function ai_management.storage_object_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if old.bucket_id='ai-catalog-documents' then
  perform pg_advisory_xact_lock(hashtextextended('ai-catalog:'||old.name,0));
  if exists(select 1 from ai_management.document_versions where storage_path=old.name) then raise exception 'FORBIDDEN: registered document object is immutable' using errcode='42501'; end if;
 end if;
 if tg_op='DELETE' then return old; end if;
 return new;
end $$;
create trigger ai_catalog_registered_object_immutable before update or delete on storage.objects for each row execute function ai_management.storage_object_guard();
create policy ai_catalog_storage_read on storage.objects for select to authenticated using(bucket_id='ai-catalog-documents' and ai_management.storage_read_allowed(name));
create policy ai_catalog_storage_insert on storage.objects for insert to authenticated with check(bucket_id='ai-catalog-documents' and ai_management.storage_upload_allowed(name));
create policy ai_catalog_storage_cleanup on storage.objects for delete to authenticated using(bucket_id='ai-catalog-documents' and ai_management.storage_upload_allowed(name));
-- Restrictive guards protect this bucket even if pre-existing permissive policies are broad.
-- All other bucket rows evaluate true, so existing applications retain their behavior.
create policy ai_catalog_storage_read_guard on storage.objects as restrictive for select to authenticated using(bucket_id<>'ai-catalog-documents' or ai_management.storage_read_allowed(name));
create policy ai_catalog_storage_insert_guard on storage.objects as restrictive for insert to authenticated with check(bucket_id<>'ai-catalog-documents' or ai_management.storage_upload_allowed(name));
create policy ai_catalog_storage_update_guard on storage.objects as restrictive for update to authenticated using(bucket_id<>'ai-catalog-documents') with check(bucket_id<>'ai-catalog-documents');
create policy ai_catalog_storage_delete_guard on storage.objects as restrictive for delete to authenticated using(bucket_id<>'ai-catalog-documents' or ai_management.storage_upload_allowed(name));
create policy ai_catalog_storage_anon_guard on storage.objects as restrictive for all to anon using(bucket_id<>'ai-catalog-documents') with check(bucket_id<>'ai-catalog-documents');

revoke all on all tables in schema ai_management from public,anon,authenticated;
revoke all on all sequences in schema ai_management from public,anon,authenticated;
revoke all on all functions in schema ai_management from public,anon,authenticated;
grant usage on schema ai_management to authenticated;
grant execute on function ai_management.storage_upload_allowed(text),ai_management.storage_read_allowed(text) to authenticated;
-- Explicitly enumerate gateways: never change privileges on any existing public function.
do $$
declare f regprocedure;
begin
 for f in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('ai_catalog_membership','ai_catalog_list','ai_catalog_get','ai_catalog_save','ai_catalog_archive','ai_catalog_stats','ai_catalog_link','ai_catalog_unlink','ai_catalog_documents','ai_catalog_document_save','ai_catalog_document_link','ai_catalog_download','ai_catalog_sources','ai_catalog_source_save','ai_catalog_source_link') loop
  execute format('revoke all on function %s from public,anon,authenticated',f);
  execute format('grant execute on function %s to authenticated',f);
 end loop;
end $$;
commit;
