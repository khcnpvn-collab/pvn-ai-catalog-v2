-- Removes records that are no longer part of the catalog: everything already archived (the
-- trash is gone from the app) and every record of the legacy kinds (old survey data assets,
-- old implementation statuses, old expert affiliations/expertise and the kinds that never held
-- data). Before deletion each record is snapshotted, with its fields, links and source links,
-- into the immutable audit log; audit rows keep the old record IDs once the records are gone.
-- Source snapshots are never deleted; only their pointer to a removed record is cleared.
begin;

create temporary table purge_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;
create temporary table legacy_kind(kind text primary key) on commit drop;
insert into legacy_kind values ('affiliation'),('expertise'),('data_asset'),('implementation'),('demand'),
 ('poc'),('course'),('learning_session'),('resource'),('collaboration_item');
create temporary table purge_set on commit drop as
select r.id,r.kind from ai_management.records r
where r.archived_at is not null or r.kind in (select kind from legacy_kind);

do $$
declare p record; detail jsonb;
begin
 for p in select r.* from ai_management.records r join purge_set s on s.id=r.id loop
  execute format('select to_jsonb(d)-''record_id''-''kind'' from ai_management.%I d where record_id=$1',p.kind||'_details') into detail using p.id;
  insert into ai_management.audit(record_id,actor_id,action,before_value)
  values(p.id,(select user_id from purge_actor),'purge_record',jsonb_build_object(
   'record',to_jsonb(p),'data',coalesce(detail,'{}'::jsonb),
   'relations',(select coalesce(jsonb_agg(to_jsonb(l)),'[]'::jsonb) from ai_management.relations l where p.id in (l.source_id,l.target_id)),
   'document_ids',(select coalesce(jsonb_agg(d.document_id),'[]'::jsonb) from ai_management.document_links d where d.record_id=p.id),
   'source_ids',(select coalesce(jsonb_agg(distinct x.id),'[]'::jsonb) from (
     select l.source_id id from ai_management.source_links l where l.record_id=p.id
     union select s.id from ai_management.sources s where s.linked_record_id=p.id) x)));
 end loop;
end $$;

-- History outlives the records it describes.
alter table ai_management.audit drop constraint if exists audit_record_id_fkey;

delete from ai_management.relations where source_id in (select id from purge_set) or target_id in (select id from purge_set);
delete from ai_management.document_links where record_id in (select id from purge_set);
delete from ai_management.source_links where record_id in (select id from purge_set);
update ai_management.sources set linked_record_id=null where linked_record_id in (select id from purge_set);
delete from ai_management.records where id in (select id from purge_set);

do $$
declare k text;
begin
 if exists(select 1 from ai_management.records where kind in (select kind from legacy_kind)) then
  raise exception 'Legacy records remain after the purge';
 end if;
 for k in select kind from legacy_kind loop
  execute format('drop table if exists ai_management.%I',k||'_details');
 end loop;
end $$;
delete from ai_management.module_registry where kind in (select kind from legacy_kind);

-- Gateways whose screens were removed: source administration and the partner reconciliation review.
do $$
declare f regprocedure;
begin
 for f in select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname in ('ai_catalog_sources','ai_catalog_source_save','ai_catalog_source_link','ai_catalog_partner_review') loop
  execute format('drop function %s',f);
 end loop;
end $$;
commit;
