-- The head office's survey declared VNPT twice with several areas in one line ("VNPT": data, reporting,
-- summarising, under an MoU; "VNPT - Qualcomm": edge, HSE, security, production). Like Huawei, each area
-- becomes its own activity linked to its item; areas already covered by an activity only gain the
-- source link. The reporting activity lost its partner when "VNPT AI" was retired: it takes VNPT, and
-- CMC OpenAI, named in the same survey line, gets its own activity. Matched by titles and codes;
-- nothing is deleted and every change is audited.
begin;

create temporary table vnpt_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;
create temporary table vnpt_ref on commit drop as select
 (select id from ai_management.records where kind='partner' and title='VNPT') vnpt,
 (select id from ai_management.records where kind='partner' and title='CMC OpenAI') cmc,
 (select id from ai_management.records where kind='partner' and title='Liên danh VNPT – Qualcomm') consortium,
 (select r.id from ai_management.records r join ai_management.unit_details u on u.record_id=r.id where u.abbreviation='PETROVIETNAM') head_office,
 (select id from ai_management.records where kind='collaboration' and title='AI tổng hợp báo cáo quản trị điều hành · PETROVIETNAM · VNPT AI') report,
 (select id from ai_management.records where kind='collaboration' and title='Edge AI trong liên danh VNPT-Qualcomm') edge,
 (select id from ai_management.sources where source_type='survey_partner' and unit_code='PETROVIETNAM' and payload->'original'->>'ten'='VNPT') src_vnpt,
 (select id from ai_management.sources where source_type='survey_partner' and unit_code='PETROVIETNAM' and payload->'original'->>'ten'='VNPT - Qualcomm') src_consortium;
do $$ begin
 if exists(select 1 from vnpt_ref where vnpt is null or cmc is null or consortium is null or head_office is null or report is null or edge is null or src_vnpt is null or src_consortium is null)
 then raise exception 'A VNPT record or survey source to split is missing'; end if;
end $$;

-- New activities: (partner, survey source, title, scope, status, group, category, item code).
create temporary table vnpt_new(n integer, partner text, source text, title text, scope text, status text, item_group text, item_category text, item_code text) on commit drop;
insert into vnpt_new values
 (1,'vnpt','vnpt','Xây dựng CSDL, big data · VNPT','Xây dựng CSDL, big data cấp Tập đoàn.','Đang trao đổi','Dữ liệu, CSDL','Xây dựng CSDL / kho dữ liệu','DL-01'),
 (2,'vnpt','vnpt','AI tóm tắt văn bản · VNPT','Tóm tắt văn bản, hỗ trợ xử lý văn bản.','Đang trao đổi','Bài toán','Giải pháp dùng chung Tập đoàn','BTC-59'),
 (3,'vnpt','vnpt','MoU / thỏa thuận hợp tác Petrovietnam – VNPT','MoU/Thỏa thuận hợp tác giữa Petrovietnam và VNPT theo khai báo khảo sát (chưa xác minh độc lập).','Hoàn thành','Ký kết hợp tác','Biên bản ghi nhớ (MOU)','KK-01'),
 (4,'consortium','consortium','AI giám sát an toàn HSE và an ninh trên Edge · Liên danh VNPT – Qualcomm','HSE, giám sát an ninh trên nền tảng Edge Computing.','Đề xuất','Bài toán','Giải pháp dùng chung Tập đoàn','BTC-46'),
 (5,'consortium','consortium','AI tối ưu khai thác dầu trên Edge · Liên danh VNPT – Qualcomm','Tối ưu khai thác dầu trên nền tảng Edge Computing.','Đề xuất','Bài toán','Giải pháp dùng chung Tập đoàn','BTC-13'),
 (6,'cmc','report','AI tổng hợp báo cáo quản trị điều hành · PETROVIETNAM · CMC OpenAI',null,'Đề xuất','Bài toán','Ứng dụng AI tại đơn vị','BTC-51');
alter table vnpt_new add column record_id uuid default gen_random_uuid(), add column partner_id uuid, add column item_id uuid;
update vnpt_new n set partner_id=case n.partner when 'vnpt' then r.vnpt when 'cmc' then r.cmc else r.consortium end from vnpt_ref r;
update vnpt_new n set item_id=x.id from ai_management.records x where x.code=n.item_code and x.kind in ('use_case','work_item');
do $$ begin
 if exists(select 1 from vnpt_new where item_id is null) then raise exception 'An item for the VNPT split is missing'; end if;
end $$;

insert into ai_management.records(id,kind,title,summary,status,created_by)
select n.record_id,'collaboration',n.title,
 case when n.source='report' then (select summary from ai_management.records where id=r.report)
  else concat_ws(E'\n','Tách từ khai báo đối tác '||case n.source when 'vnpt' then 'VNPT (tình trạng: MoU/Thỏa thuận hợp tác)' else 'VNPT - Qualcomm (tình trạng: Nghiên cứu đối tác)' end||' trong phiếu khảo sát của Cơ quan Tập đoàn.') end,
 n.status,(select user_id from vnpt_actor)
from vnpt_new n, vnpt_ref r;
insert into ai_management.collaboration_details(record_id,item_group,item_category,scope,declared_title,lead,source_status)
select n.record_id,n.item_group,n.item_category,coalesce(n.scope,d.scope),case when n.source='report' then d.declared_title end,case when n.source='report' then d.lead end,case when n.source='report' then d.source_status end
from vnpt_new n, vnpt_ref r left join ai_management.collaboration_details d on d.record_id=r.report;
insert into ai_management.relations(source_id,target_id,relation,context,note,created_by)
select record_id,partner_id,'partner','{}'::jsonb,case when source='report' then 'Theo khảo sát: VNPT AI, CMC OpenAI' end,(select user_id from vnpt_actor) from vnpt_new
union all select n.record_id,r.head_office,'unit',jsonb_build_object('subject_role','lead'),null,(select user_id from vnpt_actor) from vnpt_new n, vnpt_ref r
union all select record_id,item_id,'use_case','{}'::jsonb,null,(select user_id from vnpt_actor) from vnpt_new;
insert into ai_management.source_links(source_id,record_id,created_by)
select case n.source when 'vnpt' then r.src_vnpt when 'consortium' then r.src_consortium end,n.record_id,(select user_id from vnpt_actor)
from vnpt_new n, vnpt_ref r where n.source<>'report'
union all select l.source_id,n.record_id,(select user_id from vnpt_actor)
from vnpt_new n, vnpt_ref r join ai_management.source_links l on l.record_id=r.report where n.source='report';

-- Areas already covered: reporting is the existing activity (it takes VNPT back), edge computing is the
-- consortium's existing edge activity. Both gain the survey line as a source.
insert into ai_management.relations(source_id,target_id,relation,note,created_by)
select r.report,r.vnpt,'partner','Theo khảo sát: VNPT AI, CMC OpenAI',(select user_id from vnpt_actor) from vnpt_ref r
where not exists(select 1 from ai_management.relations l where l.source_id=r.report and l.relation='partner');
insert into ai_management.source_links(source_id,record_id,created_by)
select r.src_vnpt,r.report,(select user_id from vnpt_actor) from vnpt_ref r
union all select r.src_consortium,r.edge,(select user_id from vnpt_actor) from vnpt_ref r
on conflict do nothing;

insert into ai_management.audit(record_id,actor_id,action,after_value)
select record_id,(select user_id from vnpt_actor),'create_from_survey_area',jsonb_build_object('title',title,'item',item_code,'source',source) from vnpt_new
union all select r.report,(select user_id from vnpt_actor),'restore_partner_from_survey',jsonb_build_object('partner','VNPT','survey','VNPT AI, CMC OpenAI') from vnpt_ref r
union all select r.edge,(select user_id from vnpt_actor),'add_survey_source',jsonb_build_object('survey','VNPT - Qualcomm: Edge Computing') from vnpt_ref r;
commit;
