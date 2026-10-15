-- Add expert subjects and workbook detail fields without changing survey objects.
begin;
alter table ai_management.contact_details add column "additional_emails" text check(length("additional_emails")<=10000);
alter table ai_management.contact_details add column "role" text check(length("role")<=1000);
alter table ai_management.contact_details add column "is_primary" text check(length("is_primary")<=1000) check("is_primary" in ('Có','Không'));
alter table ai_management.contact_details add column "work_status" text check(length("work_status")<=1000);
update ai_management.module_registry set fields='[{"key": "position", "type": "text", "options": null}, {"key": "department", "type": "text", "options": null}, {"key": "email", "type": "email", "options": null}, {"key": "phone", "type": "text", "options": null}, {"key": "expertise", "type": "textarea", "options": null}, {"key": "biography", "type": "textarea", "options": null}, {"key": "additional_emails", "type": "textarea", "options": null}, {"key": "role", "type": "text", "options": null}, {"key": "is_primary", "type": "select", "options": ["Có", "Không"]}, {"key": "work_status", "type": "text", "options": null}]'::jsonb where kind='contact';

alter table ai_management.engagement_details add column "next_notes" text check(length("next_notes")<=10000);
alter table ai_management.engagement_details add column "responsible" text check(length("responsible")<=1000);
update ai_management.module_registry set fields='[{"key": "start_date", "type": "date", "options": null}, {"key": "end_date", "type": "date", "options": null}, {"key": "period_label", "type": "text", "options": null}, {"key": "location", "type": "text", "options": null}, {"key": "participants", "type": "textarea", "options": null}, {"key": "conclusions", "type": "textarea", "options": null}, {"key": "next_notes", "type": "textarea", "options": null}, {"key": "responsible", "type": "text", "options": null}]'::jsonb where kind='engagement';

alter table ai_management.partner_details add column "short_name" text check(length("short_name")<=1000);
alter table ai_management.partner_details add column "partner_type" text check(length("partner_type")<=1000);
alter table ai_management.partner_details add column "country" text check(length("country")<=1000);
alter table ai_management.partner_details add column "internal_unit_code" text check(length("internal_unit_code")<=1000);
alter table ai_management.partner_details add column "profile_url" text check(length("profile_url")<=1000) check("profile_url" ~* '^https?://[^/\s]+');
alter table ai_management.partner_details add column "document_notes" text check(length("document_notes")<=10000);
update ai_management.module_registry set fields='[{"key": "legal_name", "type": "text", "options": null}, {"key": "aliases", "type": "text", "options": null}, {"key": "website", "type": "url", "options": null}, {"key": "specialties", "type": "textarea", "options": null}, {"key": "origin", "type": "text", "options": null}, {"key": "short_name", "type": "text", "options": null}, {"key": "partner_type", "type": "text", "options": null}, {"key": "country", "type": "text", "options": null}, {"key": "internal_unit_code", "type": "text", "options": null}, {"key": "profile_url", "type": "url", "options": null}, {"key": "document_notes", "type": "textarea", "options": null}]'::jsonb where kind='partner';

alter table ai_management.collaboration_details add column "cooperation_types" text check(length("cooperation_types")<=10000);
alter table ai_management.collaboration_details add column "source_status" text check(length("source_status")<=1000);
alter table ai_management.collaboration_details add column "last_meeting_date" date;
alter table ai_management.collaboration_details add column "next_notes" text check(length("next_notes")<=10000);
update ai_management.module_registry set fields='[{"key": "scope", "type": "textarea", "options": null}, {"key": "lead", "type": "text", "options": null}, {"key": "results", "type": "textarea", "options": null}, {"key": "agreement", "type": "text", "options": null}, {"key": "cooperation_types", "type": "textarea", "options": null}, {"key": "source_status", "type": "text", "options": null}, {"key": "last_meeting_date", "type": "date", "options": null}, {"key": "next_notes", "type": "textarea", "options": null}]'::jsonb where kind='collaboration';

insert into ai_management.module_registry values ('expert',array['Đã trao đổi','Đang hợp tác','Chưa liên hệ','Tạm dừng'],'[{"key": "honorific", "type": "text", "options": null}, {"key": "academic_title", "type": "text", "options": null}, {"key": "degree", "type": "text", "options": null}, {"key": "expert_type", "type": "text", "options": null}, {"key": "current_position", "type": "text", "options": null}, {"key": "country", "type": "text", "options": null}, {"key": "city", "type": "text", "options": null}, {"key": "email", "type": "email", "options": null}, {"key": "additional_emails", "type": "textarea", "options": null}, {"key": "phone", "type": "text", "options": null}, {"key": "website", "type": "url", "options": null}, {"key": "languages", "type": "text", "options": null}, {"key": "roles", "type": "textarea", "options": null}, {"key": "participation", "type": "textarea", "options": null}, {"key": "availability", "type": "text", "options": null}, {"key": "commercial_terms", "type": "textarea", "options": null}, {"key": "priority", "type": "text", "options": null}, {"key": "contact_consent", "type": "textarea", "options": null}, {"key": "sharing_terms", "type": "textarea", "options": null}, {"key": "classification", "type": "text", "options": null}]'::jsonb);
create table ai_management.expert_details (
 record_id uuid primary key,
 kind text not null default 'expert' check(kind='expert'),
 "honorific" text check(length("honorific")<=1000),
 "academic_title" text check(length("academic_title")<=1000),
 "degree" text check(length("degree")<=1000),
 "expert_type" text check(length("expert_type")<=1000),
 "current_position" text check(length("current_position")<=1000),
 "country" text check(length("country")<=1000),
 "city" text check(length("city")<=1000),
 "email" text check(length("email")<=1000) check("email" ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'),
 "additional_emails" text check(length("additional_emails")<=10000),
 "phone" text check(length("phone")<=1000),
 "website" text check(length("website")<=1000) check("website" ~* '^https?://[^/\s]+'),
 "languages" text check(length("languages")<=1000),
 "roles" text check(length("roles")<=10000),
 "participation" text check(length("participation")<=10000),
 "availability" text check(length("availability")<=1000),
 "commercial_terms" text check(length("commercial_terms")<=10000),
 "priority" text check(length("priority")<=1000),
 "contact_consent" text check(length("contact_consent")<=10000),
 "sharing_terms" text check(length("sharing_terms")<=10000),
 "classification" text check(length("classification")<=1000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
alter table ai_management.expert_details enable row level security;
create policy ai_catalog_detail_read on ai_management.expert_details for select to authenticated using(ai_management.can_read_record(record_id));
revoke all on ai_management.expert_details from public,anon,authenticated;

insert into ai_management.module_registry values ('affiliation',array['Hiện tại','Trước đây','Chưa ghi nhận'],'[{"key": "organization_name", "type": "text", "options": null}, {"key": "position", "type": "text", "options": null}, {"key": "department", "type": "text", "options": null}, {"key": "relationship", "type": "text", "options": null}, {"key": "is_primary", "type": "select", "options": ["Có", "Không"]}, {"key": "period_label", "type": "text", "options": null}, {"key": "source_url", "type": "url", "options": null}, {"key": "notes", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.affiliation_details (
 record_id uuid primary key,
 kind text not null default 'affiliation' check(kind='affiliation'),
 "organization_name" text check(length("organization_name")<=1000),
 "position" text check(length("position")<=1000),
 "department" text check(length("department")<=1000),
 "relationship" text check(length("relationship")<=1000),
 "is_primary" text check(length("is_primary")<=1000) check("is_primary" in ('Có','Không')),
 "period_label" text check(length("period_label")<=1000),
 "source_url" text check(length("source_url")<=1000) check("source_url" ~* '^https?://[^/\s]+'),
 "notes" text check(length("notes")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
alter table ai_management.affiliation_details enable row level security;
create policy ai_catalog_detail_read on ai_management.affiliation_details for select to authenticated using(ai_management.can_read_record(record_id));
revoke all on ai_management.affiliation_details from public,anon,authenticated;

insert into ai_management.module_registry values ('expertise',array['Đã ghi nhận'],'[{"key": "domain_code", "type": "text", "options": null}, {"key": "domain_group", "type": "text", "options": null}, {"key": "keywords", "type": "text", "options": null}, {"key": "proficiency", "type": "text", "options": null}, {"key": "years_experience", "type": "number", "options": null}, {"key": "industry", "type": "textarea", "options": null}, {"key": "experience", "type": "textarea", "options": null}, {"key": "evidence_url", "type": "url", "options": null}, {"key": "notes", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.expertise_details (
 record_id uuid primary key,
 kind text not null default 'expertise' check(kind='expertise'),
 "domain_code" text check(length("domain_code")<=1000),
 "domain_group" text check(length("domain_group")<=1000),
 "keywords" text check(length("keywords")<=1000),
 "proficiency" text check(length("proficiency")<=1000),
 "years_experience" numeric check("years_experience" between 0 and 100000000),
 "industry" text check(length("industry")<=10000),
 "experience" text check(length("experience")<=10000),
 "evidence_url" text check(length("evidence_url")<=1000) check("evidence_url" ~* '^https?://[^/\s]+'),
 "notes" text check(length("notes")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
alter table ai_management.expertise_details enable row level security;
create policy ai_catalog_detail_read on ai_management.expertise_details for select to authenticated using(ai_management.can_read_record(record_id));
revoke all on ai_management.expertise_details from public,anon,authenticated;

insert into ai_management.module_registry values ('reference',array['Liên kết tham khảo','Chưa đính kèm'],'[{"key": "reference_type", "type": "text", "options": null}, {"key": "external_url", "type": "url", "options": null}, {"key": "document_date", "type": "date", "options": null}, {"key": "date_note", "type": "text", "options": null}, {"key": "edition", "type": "text", "options": null}, {"key": "classification", "type": "text", "options": null}, {"key": "notes", "type": "textarea", "options": null}]'::jsonb);
create table ai_management.reference_details (
 record_id uuid primary key,
 kind text not null default 'reference' check(kind='reference'),
 "reference_type" text check(length("reference_type")<=1000),
 "external_url" text check(length("external_url")<=1000) check("external_url" ~* '^https?://[^/\s]+'),
 "document_date" date,
 "date_note" text check(length("date_note")<=1000),
 "edition" text check(length("edition")<=1000),
 "classification" text check(length("classification")<=1000),
 "notes" text check(length("notes")<=10000),
 foreign key(record_id,kind) references ai_management.records(id,kind) on delete cascade
);
alter table ai_management.reference_details enable row level security;
create policy ai_catalog_detail_read on ai_management.reference_details for select to authenticated using(ai_management.can_read_record(record_id));
revoke all on ai_management.reference_details from public,anon,authenticated;

alter table ai_management.relations drop constraint relations_relation_check;
alter table ai_management.relations add constraint relations_relation_check check(relation in ('related','parent','unit','partner','contact','use_case','data','collaboration','course','event','speaker','participant','organizer','resource','expert'));

create or replace function public.ai_catalog_link(p_link jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
  when 'expert' then t.kind='expert' and s.kind in ('partner','unit','use_case','collaboration','collaboration_item','engagement','affiliation','expertise','reference','learning_event','course','learning_session')
  when 'use_case' then t.kind='use_case'
  when 'data' then t.kind='data_asset'
  when 'collaboration' then t.kind='collaboration'
  when 'course' then t.kind='course' and s.kind in ('learning_event','learning_session','resource','collaboration_item','contact')
  when 'event' then t.kind in ('learning_event','engagement') and s.kind in ('learning_session','contact','resource','unit','partner')
  when 'speaker' then t.kind in ('contact','expert') and s.kind in ('course','learning_event','learning_session','engagement')
  when 'participant' then t.kind in ('contact','expert') and s.kind in ('learning_event','learning_session','engagement')
  when 'organizer' then t.kind in ('unit','partner') and s.kind in ('course','learning_event','learning_session','engagement')
  when 'resource' then t.kind='resource'
  else false end) then raise exception 'VALIDATION: incompatible relation kinds' using errcode='22023'; end if;
 -- Competencies and employment records describe one person; events and references may involve many.
 if rel='expert' and s.kind in ('expertise','affiliation') and exists(
  select 1 from ai_management.relations r where r.source_id=s.id and r.relation='expert' and r.target_id<>t.id
 ) then raise exception 'VALIDATION: record already assigned to another expert' using errcode='22023'; end if;
 if rel='parent' and exists(with recursive ancestors(id) as (select t.id union select r.target_id from ai_management.relations r join ancestors a on r.source_id=a.id where r.relation='parent') select 1 from ancestors where id=s.id) then raise exception 'VALIDATION: parent cycle' using errcode='22023'; end if;
 insert into ai_management.relations(source_id,target_id,relation,note,context,created_by) values(s.id,t.id,rel,nullif(p_link->>'note',''),ctx,auth.uid()) returning * into result;
 insert into ai_management.audit(record_id,actor_id,action,after_value) values(s.id,auth.uid(),'link',to_jsonb(result));
 return to_jsonb(result)-'created_by'-'created_at';
exception when unique_violation then raise exception 'CONFLICT: relation already exists or parent already assigned' using errcode='40001';
 when check_violation or invalid_text_representation or not_null_violation then raise exception 'VALIDATION: invalid relation' using errcode='22023';
end $$;

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


-- Replacements retain existing grants; make gateway access explicit.
revoke all on function public.ai_catalog_link(jsonb),public.ai_catalog_dossier(uuid) from public,anon;
grant execute on function public.ai_catalog_link(jsonb),public.ai_catalog_dossier(uuid) to authenticated;
commit;
