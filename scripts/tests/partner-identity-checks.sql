do $$
declare item record;
begin
 perform public.catalog_test_assert((select count(*) from ai_management.records where id in
  ('03069b13-0f8e-4fa0-8fef-7c4f0d1cc49f','41d76243-2459-4535-ab51-b6224ab5e690','d0b7af77-170a-4c98-ab8b-ecd3b4978a97')
  and archived_at is not null)=3,'three obsolete partner profiles archived');
 perform public.catalog_test_assert((select count(*) from ai_management.relations where target_id='07e5e5c6-c882-4152-8205-8cbc3c53d0d2' and relation='partner')=2,'both AWS cooperation histories link to canonical partner');
 perform public.catalog_test_assert((select linked_record_id from ai_management.sources where id='45bef5ff-5058-405a-b280-f9e61f111ede')='07e5e5c6-c882-4152-8205-8cbc3c53d0d2','Amazon source points at canonical AWS');
 perform public.catalog_test_assert((select count(*) from ai_management.source_links where source_id='45bef5ff-5058-405a-b280-f9e61f111ede' and record_id='07e5e5c6-c882-4152-8205-8cbc3c53d0d2')=1,'AWS source linked to canonical profile');
 perform public.catalog_test_assert((select title from ai_management.records where id='c31f3b31-2e8c-4de4-8c70-c9830d3a1543')='Amazon Web Services (AWS) · VPI','AWS cooperation title normalized');
 for item in select r.id,r.code from ai_management.records r where r.code in
  ('KS-COLLABORATION-d2a023a7fe060a1b0a3cd181','KS-COLLABORATION-e5cddaf72ccdeeeb80a80c73',
   'KS-COLLABORATION-4d459ad716699313beae71c5','KS-COLLABORATION-19665432e5dbfe79f89efb47') loop
  perform public.catalog_test_assert((select count(*) from ai_management.relations where source_id=item.id and relation='partner')=1,'split cooperation has exactly one partner');
  perform public.catalog_test_assert((select count(*) from ai_management.relations where source_id=item.id and relation='unit')=1,'split cooperation retains PVN subject');
  perform public.catalog_test_assert((select count(*) from ai_management.relations where source_id=item.id and relation='use_case')=1,'split cooperation retains use case');
  perform public.catalog_test_assert((select count(*) from ai_management.source_links where record_id=item.id)=1,'split cooperation retains survey source');
 end loop;
 perform public.catalog_test_assert((select count(*) from ai_management.records where code in
  ('KS-COLLABORATION-d2a023a7fe060a1b0a3cd181','KS-COLLABORATION-e5cddaf72ccdeeeb80a80c73',
   'KS-COLLABORATION-4d459ad716699313beae71c5','KS-COLLABORATION-19665432e5dbfe79f89efb47')
  and archived_at is null)=4,'four separate active cooperation contents');
 perform public.catalog_test_assert((select count(*) from ai_management.source_links where source_id='ddba9a15-2947-4d9f-ad46-2c51523caf76'
  and record_id in ('9e647e63-2317-42a3-927f-f13952e94f92','639764d4-fc58-4e4c-9325-fce8a673bb05'))=2,'Microsoft and Google both map to original survey source');
 perform public.catalog_test_assert((select count(*) from ai_management.source_links where source_id='4d92b283-352b-4eea-839c-e842daac04cb'
  and record_id in ('e641a71b-7bd9-47f1-a548-9ab794887b70','7cc77334-99e8-4b3e-b048-9ddf250c82c4'))=2,'VNPT AI and CMC both map to original survey source');
 perform public.catalog_test_assert((select count(*) from ai_management.audit where action in
  ('merge_partner_identity','merge_partner_alias','split_compound_cooperation','retire_compound_partner'))=8,'all identity decisions have audit');
 raise notice 'PASS: reviewed partner identities and cooperation contents reconciled';
end $$;
