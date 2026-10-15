-- Every file shows who uploaded it: the member's display name, or the account name before the @.
begin;
create or replace function ai_management.document_json(p_id uuid, p_pin uuid default null) returns jsonb
language sql stable security definer set search_path='' as $function$
 select (to_jsonb(d)-'archived_at')||jsonb_build_object('versions',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'document_id',v.document_id,'version',v.version,'filename',v.filename,'mime_type',v.mime_type,'size_bytes',v.size_bytes,'created_at',v.created_at) order by version desc) from ai_management.document_versions v where v.document_id=d.id and (p_pin is null or v.id=p_pin)),'[]'::jsonb),
  'linked_records',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'kind',r.kind)) from ai_management.document_links l join ai_management.records r on r.id=l.record_id where l.document_id=d.id and ai_management.can_read_record(r.id)),'[]'::jsonb),
  'created_by_name',(select coalesce(nullif(trim(m.display_name),''),split_part(u.email,'@',1)) from auth.users u left join ai_management.memberships m on m.user_id=u.id where u.id=d.created_by))
 from ai_management.documents d where d.id=p_id and ai_management.can_read_document(d.id)
$function$;
commit;
