\set ON_ERROR_STOP on
create function pg_temp.state_id(name text) returns uuid language sql stable as $$ select (value#>>'{}')::uuid from public.catalog_test_state where catalog_test_state.name=$1 $$;
create function pg_temp.standard_id(code text) returns uuid language sql stable as $$ select id from ai_management.records where records.code=$1 and kind='use_case' and archived_at is null $$;
select public.catalog_test_assert((select count(*) from ai_management.records where kind='use_case' and code ~ '^BTC-\d\d$' and archived_at is null)=61,'61 official standard problems are loaded');
select public.catalog_test_assert((select count(*) from ai_management.records r join ai_management.use_case_details d on d.record_id=r.id where r.code ~ '^BTC-\d\d$' and d.is_priority='Có')=14,'exactly 14 standard problems are priority');
select public.catalog_test_assert(pg_temp.standard_id('BTC-50') is null,'#50 is merged into #54');
select public.catalog_test_assert((select d.objective from ai_management.use_case_details d where d.record_id=pg_temp.standard_id('BTC-54')) like 'Hỗ trợ quản lý vòng đời hợp đồng và đấu thầu%','#54 carries the description of #50');
select public.catalog_test_assert((select d.objective from ai_management.use_case_details d where d.record_id=pg_temp.standard_id('BTC-34')) like '%Lãnh đạo Tập đoàn.','#34 description is completed');
select public.catalog_test_assert((select title from ai_management.records where id=pg_temp.standard_id('BTC-46'))='Camera AI giám sát an toàn, tuân thủ và ứng cứu sự cố','#46 uses the priority table name');
select public.catalog_test_assert((select d.start_year from ai_management.use_case_details d where d.record_id=pg_temp.standard_id('BTC-02')) is null and (select d.is_priority from ai_management.use_case_details d where d.record_id=pg_temp.standard_id('BTC-02'))='Không','non-priority #2 keeps no priority fields');
select public.catalog_test_assert((select d.category from ai_management.use_case_details d where d.record_id=pg_temp.standard_id('BTC-31'))='Tra cứu, khai thác tri thức và văn bản nội bộ','priority problems take the priority table group');
select public.catalog_test_assert((select u.title from ai_management.relations l join ai_management.records u on u.id=l.target_id where l.source_id=pg_temp.standard_id('BTC-61') and l.relation='unit' and l.context->>'subject_role'='lead')='Viện Dầu khí Việt Nam','#61 has VPI as its single lead');
select public.catalog_test_assert((select count(*) from ai_management.relations l where l.source_id=pg_temp.standard_id('BTC-51') and l.relation='unit' and l.context->>'subject_role'='supporting')
 =(select count(*) from ai_management.records r join ai_management.unit_details d on d.record_id=r.id where r.kind='unit' and r.archived_at is null and coalesce(d.abbreviation,'')<>'PETROVIETNAM'),'whole-group potential expands to every unit');
select public.catalog_test_assert((select count(*) from ai_management.relations l where l.source_id=pg_temp.standard_id('BTC-05') and l.relation='unit')=5,'a lead unit also listed as potential is linked once');
-- Unit demands become activities on the matching standard problem.
select public.catalog_test_assert((select kind||'|'||status from ai_management.records where id=pg_temp.state_id('roadmap_d1'))='collaboration|POC','declared POC becomes an activity at POC');
select public.catalog_test_assert((select cooperation_types||'|'||declared_title||'|'||lead from ai_management.collaboration_details where record_id=pg_temp.state_id('roadmap_d1'))='Bài toán đơn vị|Dự báo  missing log|Phòng dữ liệu','activity keeps the declared title and business owner');
select public.catalog_test_assert(exists(select 1 from ai_management.relations where source_id=pg_temp.state_id('roadmap_d1') and relation='use_case' and target_id=pg_temp.standard_id('BTC-03')),'declared title matched despite spacing differences');
select public.catalog_test_assert((select context->>'subject_role' from ai_management.relations where source_id=pg_temp.state_id('roadmap_d1') and relation='unit')='lead','the unit becomes the lead PVN subject');
select public.catalog_test_assert(not exists(select 1 from ai_management.demand_details where record_id=pg_temp.state_id('roadmap_d1')),'demand detail row is replaced');
select public.catalog_test_assert((select status from ai_management.records where id=pg_temp.state_id('roadmap_d2'))='Đề xuất' and exists(select 1 from ai_management.relations where source_id=pg_temp.state_id('roadmap_d2') and relation='use_case' and target_id=pg_temp.standard_id('BTC-16')),'an idea becomes a proposal on #16');
select public.catalog_test_assert((select status from ai_management.records where id=pg_temp.state_id('roadmap_d3'))='Vận hành' and not exists(select 1 from ai_management.relations where source_id=pg_temp.state_id('roadmap_d3') and relation='use_case'),'an unmatched demand stays as an activity without a standard problem');
-- Partner cooperation per unit problem.
select public.catalog_test_assert(exists(select 1 from ai_management.relations where source_id=pg_temp.state_id('roadmap_d1') and relation='partner' and target_id=pg_temp.state_id('roadmap_p1')),'a single partner record is merged into the unit problem');
select public.catalog_test_assert((select archived_at is not null from ai_management.records where id=pg_temp.state_id('roadmap_c1')),'the merged partner record moves to the trash');
select public.catalog_test_assert(exists(select 1 from ai_management.audit where record_id=pg_temp.state_id('roadmap_c1') and action='merge_into_activity'),'the merge is audited');
select public.catalog_test_assert((select summary from ai_management.records where id=pg_temp.state_id('roadmap_d1')) like '%Đối tác theo khảo sát: Đối tác một — PoC','the partner status from the survey is kept on the activity');
select public.catalog_test_assert((select count(*) from ai_management.records r join ai_management.relations l on l.source_id=r.id and l.relation='use_case' and l.target_id=pg_temp.standard_id('BTC-16')
 where r.id in (pg_temp.state_id('roadmap_c2'),pg_temp.state_id('roadmap_c3')) and r.archived_at is null)=2,'several partners on one problem stay separate on the same standard problem');
select public.catalog_test_assert((select cooperation_types from ai_management.collaboration_details where record_id=pg_temp.state_id('roadmap_c2'))='Hợp tác đối tác','untyped partner records are tagged as partner cooperation');
select public.catalog_test_assert((select cooperation_types from ai_management.collaboration_details where record_id=pg_temp.state_id('roadmap_c4'))='MOU','existing tags are kept');
select public.catalog_test_assert(not exists(select 1 from ai_management.records where code like 'KS-USE\_CASE-%' and archived_at is null),'survey-derived standard problems move to the trash');
select public.catalog_test_assert(not exists(select 1 from ai_management.relations l join ai_management.records s on s.id=l.source_id join ai_management.records t on t.id=l.target_id where s.kind='collaboration' and l.relation='use_case' and t.code like 'KS-USE\_CASE-%'),'no activity points at a replaced standard problem');
select public.catalog_test_assert(exists(select 1 from ai_management.records r join ai_management.relations l on l.source_id=r.id and l.relation='use_case' and l.target_id=pg_temp.standard_id('BTC-46')
 join ai_management.relations u on u.source_id=r.id and u.relation='unit' and u.target_id=pg_temp.state_id('roadmap_pvcfc') and u.context->>'subject_role'='lead'
 where r.code='BTC-46-PVCFC-POC' and r.status='POC'),'PVCFC camera AI POC is recorded on #46');
-- Experts.
select public.catalog_test_assert((select organization||'|'||expertise_summary from ai_management.expert_details where record_id=pg_temp.state_id('roadmap_expert'))='Đại học Kiểm thử|Học máy · Chuyên sâu · 8 năm kinh nghiệm','expert profile absorbs organisation and expertise');
select public.catalog_test_assert((select bool_and(archived_at is not null) from ai_management.records where id in (pg_temp.state_id('roadmap_aff'),pg_temp.state_id('roadmap_skill'))),'expertise and affiliation records move to the trash');
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
select public.catalog_test_assert((select count(*) from jsonb_array_elements(public.ai_catalog_overview()->'standards') s where s->>'code' ~ '^BTC-\d\d$')=61,'readers see the official catalogue in the overview');
reset role;
