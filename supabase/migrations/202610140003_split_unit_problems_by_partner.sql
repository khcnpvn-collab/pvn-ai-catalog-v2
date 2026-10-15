-- A unit problem worked on with several partners becomes one activity per partner.
-- The survey created one record per partner titled "Partner · UNIT · problem" next to the
-- unit's own record "problem · UNIT"; each partner record absorbs the unit's content and
-- keeps its own status, and the unit's own record is archived with an audit entry.
-- Records are matched by lead unit and problem title, never by generated IDs. Nothing is removed from the database.
begin;
select pg_advisory_xact_lock(73424910902412);

create temporary table split_activity on commit drop as
with act as (
  select r.id, r.title, d.cooperation_types,
    (select l.target_id from ai_management.relations l where l.source_id = r.id and l.relation = 'unit' and l.context->>'subject_role' = 'lead' limit 1) lead_id,
    (select l.target_id from ai_management.relations l where l.source_id = r.id and l.relation = 'partner' limit 1) partner_id
  from ai_management.records r join ai_management.collaboration_details d on d.record_id = r.id
  where r.kind = 'collaboration' and r.archived_at is null
), unit_problem as (
  select act.*, lower(btrim(regexp_replace(title, '\s*·[^·]*$', ''))) problem from act
  where cooperation_types = 'Bài toán đơn vị' and partner_id is null and lead_id is not null
), partner_activity as (
  select act.*, lower(btrim(regexp_replace(title, '^[^·]*·[^·]*·\s*', ''))) problem from act
  where cooperation_types is distinct from 'Bài toán đơn vị' and title ~ '^[^·]+·[^·]+·' and partner_id is not null
)
select u.id unit_problem_id, p.id activity_id, u.title unit_problem_title, partner.title partner_title
from unit_problem u
join partner_activity p on p.lead_id = u.lead_id and p.problem = u.problem
join ai_management.records partner on partner.id = p.partner_id;

do $$ begin
  if exists(select activity_id from split_activity group by 1 having count(*) > 1) then raise exception 'A partner activity matches several unit problems'; end if;
end $$;

create temporary table split_actor on commit drop as
select user_id from ai_management.memberships where role = 'admin' order by created_at, user_id limit 1;

insert into ai_management.audit(record_id, actor_id, action, before_value, after_value)
select s.activity_id, (select user_id from split_actor), 'absorb_unit_problem',
  to_jsonb(r) || jsonb_build_object('data', to_jsonb(d) - 'record_id' - 'kind'), jsonb_build_object('unit_problem_id', s.unit_problem_id)
from split_activity s join ai_management.records r on r.id = s.activity_id join ai_management.collaboration_details d on d.record_id = s.activity_id;

update ai_management.records p set version = p.version + 1,
  title = left(s.unit_problem_title || ' · ' || s.partner_title, 250),
  summary = left(concat_ws(E'\n\n', nullif(p.summary, ''), nullif(u.summary, '')), 10000)
from split_activity s join ai_management.records u on u.id = s.unit_problem_id
where p.id = s.activity_id;

update ai_management.collaboration_details p set cooperation_types = 'Bài toán đơn vị',
  declared_title = coalesce(p.declared_title, u.declared_title),
  scope = left(concat_ws(E'\n\n', nullif(u.scope, ''), case when p.scope is distinct from u.scope then nullif(p.scope, '') end), 10000),
  lead = coalesce(p.lead, u.lead),
  source_status = coalesce(p.source_status, u.source_status)
from split_activity s join ai_management.collaboration_details u on u.record_id = s.unit_problem_id
where p.record_id = s.activity_id;

-- The standard problem follows the unit's record.
update ai_management.relations l set target_id = us.target_id
from split_activity s join ai_management.relations us on us.source_id = s.unit_problem_id and us.relation = 'use_case'
where l.source_id = s.activity_id and l.relation = 'use_case' and l.target_id <> us.target_id;
insert into ai_management.relations(source_id, target_id, relation, created_by)
select s.activity_id, us.target_id, 'use_case', (select user_id from split_actor)
from split_activity s join ai_management.relations us on us.source_id = s.unit_problem_id and us.relation = 'use_case'
where not exists(select 1 from ai_management.relations l where l.source_id = s.activity_id and l.relation = 'use_case');

-- Coordinating units, incoming links, files and survey sources are shared by every partner activity.
-- The partner activity already has the same lead unit, so any other unit joins as coordinating.
insert into ai_management.relations(source_id, target_id, relation, note, context, created_by)
select s.activity_id, l.target_id, l.relation, l.note,
  case when l.relation = 'unit' then l.context || jsonb_build_object('subject_role', 'supporting') else l.context end, l.created_by
from split_activity s join ai_management.relations l on l.source_id = s.unit_problem_id and l.relation not in ('use_case', 'partner')
where not exists(select 1 from ai_management.relations x where x.source_id = s.activity_id and x.target_id = l.target_id and x.relation = l.relation);
insert into ai_management.relations(source_id, target_id, relation, note, context, created_by)
select l.source_id, s.activity_id, l.relation, l.note, l.context, l.created_by
from split_activity s join ai_management.relations l on l.target_id = s.unit_problem_id
on conflict (source_id, target_id, relation) do nothing;
insert into ai_management.document_links(record_id, document_id, version_id, created_by, created_at)
select s.activity_id, l.document_id, l.version_id, l.created_by, l.created_at
from split_activity s join ai_management.document_links l on l.record_id = s.unit_problem_id
on conflict (record_id, document_id) do nothing;
insert into ai_management.source_links(source_id, record_id, created_by, created_at)
select l.source_id, s.activity_id, l.created_by, l.created_at
from split_activity s join ai_management.source_links l on l.record_id = s.unit_problem_id
on conflict (source_id, record_id) do nothing;

insert into ai_management.audit(record_id, actor_id, action, after_value)
select s.unit_problem_id, (select user_id from split_actor), 'split_into_partner_activities', jsonb_build_object('activity_ids', jsonb_agg(s.activity_id))
from split_activity s group by s.unit_problem_id;
update ai_management.records r set archived_at = now(), version = r.version + 1
where r.id in (select unit_problem_id from split_activity);
commit;
