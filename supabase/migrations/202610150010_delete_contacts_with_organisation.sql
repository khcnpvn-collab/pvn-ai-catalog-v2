-- A contact is a row of its unit or partner. Deleting the unit or partner deletes the contacts that belong
-- to it alone, so none is left behind without an organisation. The three contacts of the deleted group
-- "Nhóm ADT–AIQ" (Đặng Minh, Nguyễn Thế Duy, Phan Bảo Ngọc) were left behind that way and go now.
-- Every deleted record is snapshotted in the audit log first.
begin;
-- Unit contacts point to their unit; partners point to their contacts.
create or replace function ai_management.contact_belongs_to(p_contact uuid,p_org uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from ai_management.relations l where (l.source_id=p_org and l.target_id=p_contact and l.relation='contact')
  or (l.source_id=p_contact and l.target_id=p_org and l.relation in ('unit','partner')))
$$;
revoke all on function ai_management.contact_belongs_to(uuid,uuid) from public,anon,authenticated;

create or replace function public.ai_catalog_delete(p_id uuid,p_version integer) returns boolean
language plpgsql security definer set search_path='' as $function$
declare previous ai_management.records; folders uuid[]; contacts uuid[]; extra uuid[];
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
 -- Contacts of this unit or partner that belong to no other unit or partner.
 select coalesce(array_agg(c.id),'{}') into contacts from ai_management.records c
 where c.kind='contact' and previous.kind in ('unit','partner') and ai_management.contact_belongs_to(c.id,p_id)
  and not exists(select 1 from ai_management.records o where o.id<>p_id and o.kind in ('unit','partner') and ai_management.contact_belongs_to(c.id,o.id));
 extra:=folders||contacts;
 insert into ai_management.audit(record_id,actor_id,action,before_value)
 select r.id,auth.uid(),case when r.id=any(contacts) then 'delete_with_organisation' else 'delete' end,jsonb_build_object('record',ai_management.record_json(r.id),
   'relations',(select coalesce(jsonb_agg(to_jsonb(l)),'[]'::jsonb) from ai_management.relations l where r.id in (l.source_id,l.target_id)),
   'document_ids',(select coalesce(jsonb_agg(d.document_id),'[]'::jsonb) from ai_management.document_links d where d.record_id=r.id),
   'source_ids',(select coalesce(jsonb_agg(l.source_id),'[]'::jsonb) from ai_management.source_links l where l.record_id=r.id))
 from ai_management.records r where r.id=p_id or r.id=any(extra);
 delete from ai_management.relations where source_id=p_id or target_id=p_id or source_id=any(extra) or target_id=any(contacts);
 delete from ai_management.document_links where record_id=p_id or record_id=any(extra);
 delete from ai_management.source_links where record_id=p_id or record_id=any(contacts);
 update ai_management.sources set linked_record_id=null where linked_record_id=p_id or linked_record_id=any(contacts);
 delete from ai_management.records where id=p_id or id=any(extra);
 return true;
end $function$;
revoke all on function public.ai_catalog_delete(uuid,integer) from public,anon;
grant execute on function public.ai_catalog_delete(uuid,integer) to authenticated;

-- The three contacts of the deleted group, by id; each must still be a contact with no link at all.
create temporary table left_contact on commit drop as
select r.id from ai_management.records r where r.kind='contact'
 and r.id in ('f9f3c610-8d36-45e1-8ed9-2f7f1ab9192f','07bd13cf-bded-46d8-a151-581f390cb3c5','119f3221-99a1-4983-9f86-64bf2087074c')
 and not exists(select 1 from ai_management.relations l where r.id in (l.source_id,l.target_id));
insert into ai_management.audit(record_id,actor_id,action,before_value)
select c.id,(select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1),'delete_with_organisation',jsonb_build_object('record',ai_management.record_json(c.id),'organisation','Nhóm ADT–AIQ',
  'source_ids',(select coalesce(jsonb_agg(l.source_id),'[]'::jsonb) from ai_management.source_links l where l.record_id=c.id))
from left_contact c;
delete from ai_management.document_links where record_id in (select id from left_contact);
delete from ai_management.source_links where record_id in (select id from left_contact);
update ai_management.sources set linked_record_id=null where linked_record_id in (select id from left_contact);
delete from ai_management.records where id in (select id from left_contact);
commit;
