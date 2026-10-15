-- The Group head office declared Huawei once in its survey with five distinct solution areas. Each area
-- becomes its own activity linked to the matching standard problem: the original activity keeps the
-- first area, four new ones copy its partner, PVN subject and source. Matched by title and code; nothing
-- is deleted and every change is audited.
begin;

create temporary table split_actor on commit drop as
select user_id from ai_management.memberships where role='admin' order by created_at,user_id limit 1;
create temporary table split_origin on commit drop as
select r.* from ai_management.records r
join ai_management.relations p on p.source_id=r.id and p.relation='partner'
join ai_management.records h on h.id=p.target_id and h.title='Huawei'
where r.kind='collaboration' and r.title='Huawei · PETROVIETNAM';
do $$ begin
 if (select count(*) from split_origin)<>1 then raise exception 'Expected exactly one Huawei survey activity of the head office'; end if;
end $$;

create temporary table split_area(n integer, title text, scope text, standard_code text) on commit drop;
insert into split_area values
 (1,'Nền tảng xử lý và minh giải địa chấn BGP trên hạ tầng HPC · Huawei','Nền tảng xử lý và minh giải địa chấn tích hợp của BGP trên hạ tầng tính toán hiệu năng cao.','BTC-07'),
 (2,'Thuật toán xử lý địa chấn và mô hình AI chuyên ngành địa chất, giếng khoan · Huawei','Thuật toán xử lý địa chấn như xây dựng mô hình vận tốc, dịch chuyển trước cộng; mô hình AI chuyên ngành phục vụ địa chất, địa vật lý, dữ liệu giếng khoan và khai thác.','BTC-08'),
 (3,'AI Computer Vision cho công tác HSE · Huawei','AI Computer Vision trên nền tảng xử lý tập trung và tại biên cho công tác HSE.','BTC-46'),
 (4,'Cảm biến sợi quang, video AI, GIS và Digital Twin giám sát đường ống · Huawei','Cảm biến sợi quang, video AI, GIS và Digital Twin cho giám sát đường ống.','BTC-18'),
 (5,'Nền tảng nhà máy thông minh, tối ưu quá trình và hỗ trợ vận hành · Huawei','Nền tảng nhà máy thông minh, tối ưu quá trình, quản lý cảnh báo và hỗ trợ vận hành.','BTC-16');
alter table split_area add column record_id uuid, add column standard_id uuid;
update split_area a set standard_id=r.id from ai_management.records r where r.kind='use_case' and r.code=a.standard_code;
do $$ begin
 if exists(select 1 from split_area where standard_id is null) then raise exception 'A standard problem for the Huawei split is missing'; end if;
end $$;
update split_area set record_id=(select id from split_origin) where n=1;
update split_area set record_id=gen_random_uuid() where n>1;

insert into ai_management.audit(record_id,actor_id,action,before_value)
select o.id,(select user_id from split_actor),'split_partner_survey_activity',
 jsonb_build_object('record',to_jsonb(o),'data',(select to_jsonb(d)-'record_id'-'kind' from ai_management.collaboration_details d where d.record_id=o.id),
  'areas',(select jsonb_agg(jsonb_build_object('title',title,'standard',standard_code) order by n) from split_area))
from split_origin o;

-- The original keeps the first area.
update ai_management.records r set title=a.title,version=r.version+1,updated_at=now()
from split_area a where a.n=1 and r.id=a.record_id;
update ai_management.collaboration_details d set scope=a.scope,item_group='Bài toán',item_category='Giải pháp dùng chung Tập đoàn'
from split_area a where a.n=1 and d.record_id=a.record_id;

-- Four new activities copy the original's status, summary, details, partner, PVN subjects and sources.
insert into ai_management.records(id,kind,title,summary,status,created_by)
select a.record_id,'collaboration',a.title,concat_ws(E'\n',o.summary,'Tách từ khai báo đối tác Huawei trong phiếu khảo sát của Cơ quan Tập đoàn ('||a.n||'/5).'),o.status,(select user_id from split_actor)
from split_area a, split_origin o where a.n>1;
insert into ai_management.collaboration_details(record_id,item_group,item_category,scope,lead,source_status)
select a.record_id,'Bài toán','Giải pháp dùng chung Tập đoàn',a.scope,d.lead,d.source_status
from split_area a, split_origin o join ai_management.collaboration_details d on d.record_id=o.id where a.n>1;
insert into ai_management.relations(source_id,target_id,relation,context,note,created_by)
select a.record_id,l.target_id,l.relation,l.context,l.note,(select user_id from split_actor)
from split_area a, split_origin o join ai_management.relations l on l.source_id=o.id and l.relation in ('partner','unit')
where a.n>1;
insert into ai_management.source_links(source_id,record_id,created_by)
select l.source_id,a.record_id,(select user_id from split_actor)
from split_area a, split_origin o join ai_management.source_links l on l.record_id=o.id where a.n>1
on conflict do nothing;

-- Each area joins its standard problem.
insert into ai_management.relations(source_id,target_id,relation,created_by)
select record_id,standard_id,'use_case',(select user_id from split_actor) from split_area
on conflict do nothing;
insert into ai_management.audit(record_id,actor_id,action,after_value)
select record_id,(select user_id from split_actor),case when n=1 then 'narrow_to_survey_area' else 'create_from_survey_area' end,
 jsonb_build_object('title',title,'standard',standard_code,'origin_id',(select id from split_origin))
from split_area;
commit;
