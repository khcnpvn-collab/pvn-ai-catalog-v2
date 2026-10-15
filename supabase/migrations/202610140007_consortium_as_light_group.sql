-- A consortium is a light group: its own record of type "Liên danh" whose members are peer
-- partners, one of them lead. Companies that had been given members (so they acted as the
-- consortium) are split: a new consortium takes over the membership, the company joins it
-- as a peer, and the company's own activities stay with the company. Matched by titles,
-- never by generated IDs; every change is audited and nothing is removed.
begin;

create temporary table group_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;

-- shell: the company acting as a consortium; consortium: the new group; shell_role: the company's role in it.
create temporary table consortium_split(shell text, consortium text, shell_role text) on commit drop;
insert into consortium_split values
 ('CMC TS','Liên danh CMC OpenAI – CMC TS','member'),
 ('AI Hay/1AI Technology','Liên danh ADT – AI Hay','member'),
 ('ADT Global/ADT Hi-tech','Liên danh ADT – AIQ','lead');

create temporary table split_plan on commit drop as
select s.*, p.id shell_id from consortium_split s
join ai_management.records p on p.kind='partner' and p.archived_at is null and p.title=s.shell;
do $$ begin
 if (select count(*) from split_plan)<>(select count(*) from consortium_split)
  or exists(select shell from split_plan group by shell having count(*)>1) then
  raise exception 'Each company acting as a consortium must match exactly one active partner';
 end if;
end $$;

insert into ai_management.records(kind,title,status,visibility,source_note,created_by)
select 'partner',s.consortium,'Tiềm năng','team','Tách từ quan hệ thành viên đã gắn trên '||s.shell||' (14/10/2026).',(select user_id from group_actor)
from split_plan s where not exists(select 1 from ai_management.records r where r.kind='partner' and r.title=s.consortium and r.archived_at is null);
alter table split_plan add column consortium_id uuid;
update split_plan s set consortium_id=r.id from ai_management.records r where r.kind='partner' and r.archived_at is null and r.title=s.consortium;
insert into ai_management.partner_details(record_id,partner_type)
select consortium_id,'Liên danh' from split_plan on conflict(record_id) do update set partner_type='Liên danh';

-- The members move from the company to the new consortium, keeping their roles.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select l.source_id,(select user_id from group_actor),'move_consortium_member',to_jsonb(l),jsonb_build_object('source_id',s.consortium_id)
from ai_management.relations l join split_plan s on s.shell_id=l.source_id join ai_management.records t on t.id=l.target_id
where l.relation='partner' and t.kind='partner';
update ai_management.relations l set source_id=s.consortium_id
from split_plan s, ai_management.records t
where l.source_id=s.shell_id and l.relation='partner' and t.id=l.target_id and t.kind='partner';
insert into ai_management.relations(source_id,target_id,relation,context,created_by)
select s.consortium_id,s.shell_id,'partner',jsonb_build_object('consortium_role',s.shell_role),(select user_id from group_actor)
from split_plan s on conflict(source_id,target_id,relation) do nothing;
update ai_management.partner_details d set partner_type='Doanh nghiệp/nhà cung cấp'
from split_plan s where d.record_id=s.shell_id and d.partner_type='Liên danh';
insert into ai_management.audit(record_id,actor_id,action,after_value)
select s.consortium_id,(select user_id from group_actor),'split_consortium_from_company',jsonb_build_object('company_id',s.shell_id,'company_role',s.shell_role)
from split_plan s;

-- The one real consortium from the workbook carried a member's name.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select r.id,(select user_id from group_actor),'rename_consortium',jsonb_build_object('title',r.title),jsonb_build_object('title','Liên danh VNPT – Qualcomm')
from ai_management.records r join ai_management.partner_details d on d.record_id=r.id
where r.kind='partner' and r.archived_at is null and r.title='Qualcomm' and d.partner_type='Liên danh';
update ai_management.records r set title='Liên danh VNPT – Qualcomm',version=r.version+1
from ai_management.partner_details d
where d.record_id=r.id and r.kind='partner' and r.archived_at is null and r.title='Qualcomm' and d.partner_type='Liên danh';
commit;
