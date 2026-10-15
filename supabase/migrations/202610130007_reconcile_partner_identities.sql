-- Reconcile identities confirmed by the data owner. Match stable import codes
-- and immutable survey snapshots; never rely on database-generated record IDs.
-- Each cooperation content remains specific to one partner.
begin;
select pg_advisory_xact_lock(73424910902411);

create temporary table reviewed_aws on commit drop as
select old.id old_partner_id,canonical.id canonical_partner_id,
 content.id content_id,item.id archived_content_id,source.id source_id
from ai_management.records old
join ai_management.records canonical on canonical.code='KS-PARTNER-0eb9ef1206a4f1bb5fc16c76'
join ai_management.records content on content.code='KS-COLLABORATION-ce5951b169d9d87bb2ff5f48'
join ai_management.records item on item.code='KS-COLLABORATION_ITEM-ce5951b169d9d87bb2ff5f48'
join ai_management.source_links link on link.record_id=old.id
join ai_management.sources source on source.id=link.source_id
 and source.source_type='survey_partner' and source.payload#>>'{original,ten}'='Amazon'
where old.code='KS-PARTNER-8d16493c4ac3d5ca62e76588';

create temporary table reviewed_partner_splits on commit drop as
select old.id old_partner_id,content.id content_id,source.id source_id,
 first_partner.id first_partner_id,second_partner.id second_partner_id,
 spec.old_label,spec.first_label,spec.second_label,spec.first_code,spec.second_code,
 gen_random_uuid() second_content_id,null::jsonb old_content,null::jsonb old_partner
from (values
 ('KS-PARTNER-c80e3ee590c96d1f3e2e8e71','KS-COLLABORATION-13201da6076860986bf24c8b',
  'KS-PARTNER-5c627aade84c3248c647f4d0','WB-061ea40f-DT0034',
  'Microsoft, Google','Microsoft','Google Cloud',
  'KS-COLLABORATION-d2a023a7fe060a1b0a3cd181','KS-COLLABORATION-e5cddaf72ccdeeeb80a80c73'),
 ('KS-PARTNER-fa7a5d077a1275bfc735e70b','KS-COLLABORATION-fbd3cacf7a4d53a55dbb2ae2',
  'WB-061ea40f-DT0066','KS-PARTNER-3c05d201c5c1858ab9a61040',
  'VNPT AI, CMC OpenAI','VNPT AI','CMC OpenAI',
  'KS-COLLABORATION-4d459ad716699313beae71c5','KS-COLLABORATION-19665432e5dbfe79f89efb47')
) spec(old_partner_code,content_code,first_partner_code,second_partner_code,
       old_label,first_label,second_label,first_code,second_code)
join ai_management.records old on old.code=spec.old_partner_code
join ai_management.records content on content.code=spec.content_code
join ai_management.records first_partner on first_partner.code=spec.first_partner_code
join ai_management.records second_partner on second_partner.code=spec.second_partner_code
join ai_management.source_links link on link.record_id=old.id
join ai_management.sources source on source.id=link.source_id
 and source.source_type='survey_use_case'
 and source.payload#>>'{details,doitac,0,ten}'=spec.old_label;

do $$
declare aws record; job record;
begin
 if (select count(*) from reviewed_aws)<>1 or (select count(*) from reviewed_partner_splits)<>2 then
  raise exception 'Reviewed partner identity keys no longer resolve uniquely';
 end if;
 select * into aws from reviewed_aws;
 if not exists(select 1 from ai_management.records where id=aws.old_partner_id
  and kind='partner' and title='AWS' and version=2 and archived_at is null)
 or not exists(select 1 from ai_management.records where id=aws.canonical_partner_id
  and kind='partner' and title='Amazon Web Services (AWS)' and archived_at is null)
 or not exists(select 1 from ai_management.partner_details where record_id=aws.old_partner_id
  and legal_name='AWS' and aliases='Amazon')
 or not exists(select 1 from ai_management.partner_details where record_id=aws.canonical_partner_id and aliases='AWS')
 or not exists(select 1 from ai_management.records where id=aws.content_id and kind='collaboration'
  and title='Amazon · VPI' and version=1 and archived_at is null)
 or not exists(select 1 from ai_management.records where id=aws.archived_content_id
  and kind='collaboration' and archived_at is not null)
 or (select count(*) from ai_management.relations where target_id=aws.old_partner_id and relation='partner')<>2
 or (select count(*) from ai_management.relations where target_id=aws.old_partner_id
  and source_id in (aws.content_id,aws.archived_content_id) and relation='partner')<>2
 or exists(select 1 from ai_management.relations where source_id=aws.old_partner_id)
 or exists(select 1 from ai_management.document_links where record_id=aws.old_partner_id)
 or (select count(*) from ai_management.source_links where record_id=aws.old_partner_id)<>1
 or not exists(select 1 from ai_management.sources where id=aws.source_id and linked_record_id=aws.old_partner_id)
 or exists(select 1 from ai_management.records where code='KS-COLLABORATION-2836804cc475699714f2a792') then
  raise exception 'AWS identity changed since review';
 end if;
 for job in select * from reviewed_partner_splits loop
  if not exists(select 1 from ai_management.records where id=job.old_partner_id
   and kind='partner' and title=job.old_label and version=1 and archived_at is null)
  or not exists(select 1 from ai_management.records where id=job.content_id
   and kind='collaboration' and title like job.old_label||' · %' and version=1 and archived_at is null)
  or not exists(select 1 from ai_management.records where id=job.first_partner_id
   and kind='partner' and title=job.first_label and archived_at is null)
  or not exists(select 1 from ai_management.records where id=job.second_partner_id
   and kind='partner' and title=job.second_label and archived_at is null)
  or (select count(*) from ai_management.relations where source_id=job.content_id)<>3
  or (select count(*) from ai_management.relations where source_id=job.content_id
   and relation='partner' and target_id=job.old_partner_id)<>1
  or (select count(*) from ai_management.relations where source_id=job.content_id and relation='unit')<>1
  or (select count(*) from ai_management.relations where source_id=job.content_id and relation='use_case')<>1
  or (select count(*) from ai_management.relations where target_id=job.old_partner_id)<>1
  or exists(select 1 from ai_management.relations where target_id=job.content_id or source_id=job.old_partner_id)
  or exists(select 1 from ai_management.document_links where record_id in (job.old_partner_id,job.content_id))
  or (select count(*) from ai_management.source_links where record_id=job.old_partner_id)<>1
  or (select count(*) from ai_management.source_links where record_id=job.content_id)<>1
  or not exists(select 1 from ai_management.source_links where source_id=job.source_id and record_id=job.content_id)
  or exists(select 1 from ai_management.records where code in (job.first_code,job.second_code)) then
   raise exception 'Compound partner identity changed since review: %',job.old_label;
  end if;
 end loop;
end $$;

-- AWS: move source and both cooperation edges, including the archived history.
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select old.id,old.created_by,'merge_partner_identity',
 jsonb_build_object('record',to_jsonb(old),'detail',to_jsonb(detail),'source_id',aws.source_id),
 jsonb_build_object('canonical_id',aws.canonical_partner_id,'decision','AWS and Amazon Web Services are one partner')
from reviewed_aws aws join ai_management.records old on old.id=aws.old_partner_id
join ai_management.partner_details detail on detail.record_id=old.id;
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select canonical.id,canonical.created_by,'merge_partner_alias',to_jsonb(detail),
 jsonb_build_object('aliases','AWS; Amazon')
from reviewed_aws aws join ai_management.records canonical on canonical.id=aws.canonical_partner_id
join ai_management.partner_details detail on detail.record_id=canonical.id;

insert into ai_management.source_links(source_id,record_id,created_by)
select link.source_id,aws.canonical_partner_id,link.created_by
from reviewed_aws aws join ai_management.source_links link on link.record_id=aws.old_partner_id;
update ai_management.sources source set linked_record_id=aws.canonical_partner_id
from reviewed_aws aws where source.id=aws.source_id;
update ai_management.relations edge set target_id=aws.canonical_partner_id
from reviewed_aws aws where edge.target_id=aws.old_partner_id and edge.relation='partner';
update ai_management.partner_details detail set aliases='AWS; Amazon'
from reviewed_aws aws where detail.record_id=aws.canonical_partner_id;
update ai_management.records canonical set version=canonical.version+1,updated_at=now()
from reviewed_aws aws where canonical.id=aws.canonical_partner_id;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select content.id,content.created_by,'normalize_cooperation_partner',to_jsonb(content),
 jsonb_build_object('title','Amazon Web Services (AWS) · VPI','code','KS-COLLABORATION-2836804cc475699714f2a792')
from reviewed_aws aws join ai_management.records content on content.id=aws.content_id;
update ai_management.records content set title='Amazon Web Services (AWS) · VPI',
 code='KS-COLLABORATION-2836804cc475699714f2a792',version=content.version+1,updated_at=now()
from reviewed_aws aws where content.id=aws.content_id;
delete from ai_management.source_links link using reviewed_aws aws where link.record_id=aws.old_partner_id;
update ai_management.records old set archived_at=now(),updated_at=now(),version=old.version+1
from reviewed_aws aws where old.id=aws.old_partner_id;

-- Two composite survey labels each represent two existing partner profiles.
update reviewed_partner_splits job set old_content=to_jsonb(content),old_partner=to_jsonb(partner)
from ai_management.records content,ai_management.records partner
where content.id=job.content_id and partner.id=job.old_partner_id;
update ai_management.relations edge set target_id=job.first_partner_id
from reviewed_partner_splits job
where edge.source_id=job.content_id and edge.target_id=job.old_partner_id and edge.relation='partner';
update ai_management.records content set
 title=replace(content.title,job.old_label,job.first_label),code=job.first_code,
 summary=concat_ws(E'\n',nullif(content.summary,''),
  'Nguồn khảo sát ghi chung '||job.old_label||'; tình trạng của từng đối tác chưa được xác minh riêng.'),
 updated_at=now(),version=content.version+1
from reviewed_partner_splits job where content.id=job.content_id;
insert into ai_management.records(id,kind,title,code,summary,status,observed_on,source_note,visibility,version,created_by)
select job.second_content_id,content.kind,replace(job.old_content->>'title',job.old_label,job.second_label),
 job.second_code,content.summary,content.status,content.observed_on,content.source_note,content.visibility,1,content.created_by
from reviewed_partner_splits job join ai_management.records content on content.id=job.content_id;
insert into ai_management.collaboration_details(
 record_id,scope,lead,results,agreement,cooperation_types,source_status,last_meeting_date,next_notes)
select job.second_content_id,detail.scope,detail.lead,detail.results,detail.agreement,
 detail.cooperation_types,detail.source_status,detail.last_meeting_date,detail.next_notes
from reviewed_partner_splits job join ai_management.collaboration_details detail on detail.record_id=job.content_id;
insert into ai_management.relations(source_id,target_id,relation,note,context,created_by)
select job.second_content_id,
 case when edge.relation='partner' then job.second_partner_id else edge.target_id end,
 edge.relation,edge.note,edge.context,edge.created_by
from reviewed_partner_splits job join ai_management.relations edge on edge.source_id=job.content_id;
insert into ai_management.source_links(source_id,record_id,created_by)
select job.source_id,job.second_content_id,content.created_by
from reviewed_partner_splits job join ai_management.records content on content.id=job.content_id;
insert into ai_management.source_links(source_id,record_id,created_by)
select job.source_id,member.partner_id,partner.created_by
from reviewed_partner_splits job
cross join lateral (values(job.first_partner_id),(job.second_partner_id)) member(partner_id)
join ai_management.records partner on partner.id=member.partner_id
on conflict(source_id,record_id) do nothing;

insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select job.content_id,content.created_by,'split_compound_cooperation',job.old_content,
 jsonb_build_object('partner_id',job.first_partner_id,'other_cooperation_id',job.second_content_id,'source_id',job.source_id)
from reviewed_partner_splits job join ai_management.records content on content.id=job.content_id;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select job.second_content_id,content.created_by,'split_compound_cooperation',
 jsonb_build_object('origin_cooperation_id',job.content_id,'partner_id',job.second_partner_id,'source_id',job.source_id)
from reviewed_partner_splits job join ai_management.records content on content.id=job.content_id;
insert into ai_management.audit(record_id,actor_id,action,before_value,after_value)
select job.old_partner_id,partner.created_by,'retire_compound_partner',job.old_partner,
 jsonb_build_object('member_ids',jsonb_build_array(job.first_partner_id,job.second_partner_id),'source_id',job.source_id)
from reviewed_partner_splits job join ai_management.records partner on partner.id=job.old_partner_id;
delete from ai_management.source_links link using reviewed_partner_splits job where link.record_id=job.old_partner_id;
update ai_management.records partner set archived_at=now(),updated_at=now(),version=partner.version+1
from reviewed_partner_splits job where partner.id=job.old_partner_id;

do $$
begin
 if exists(select 1 from ai_management.records r join reviewed_aws aws on r.id=aws.old_partner_id where r.archived_at is null)
 or exists(select 1 from ai_management.records r join reviewed_partner_splits job on r.id=job.old_partner_id where r.archived_at is null)
 or (select count(*) from ai_management.records where kind='collaboration' and archived_at is null and code in
  ('KS-COLLABORATION-d2a023a7fe060a1b0a3cd181','KS-COLLABORATION-e5cddaf72ccdeeeb80a80c73',
   'KS-COLLABORATION-4d459ad716699313beae71c5','KS-COLLABORATION-19665432e5dbfe79f89efb47'))<>4
 or exists(select 1 from ai_management.relations edge join reviewed_aws aws on edge.target_id=aws.old_partner_id)
 or exists(select 1 from ai_management.relations edge join reviewed_partner_splits job on edge.target_id=job.old_partner_id)
 or exists(select 1 from reviewed_partner_splits job
  cross join lateral (values(job.content_id),(job.second_content_id)) content(id)
  where (select count(*) from ai_management.relations edge
   where edge.source_id=content.id and edge.relation='partner')<>1) then
  raise exception 'Partner identity reconciliation postcheck failed';
 end if;
end $$;
commit;
