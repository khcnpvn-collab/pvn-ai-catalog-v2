# Implementation contract

All endpoints require explicit ai_management membership except login/session. Errors `{error: string}`, status 400/401/403/404/409/500. JSON success `{data: ...}`. Mutations same-origin only. Module types and field schema in src/lib/catalog.ts.

## Browser API
- GET /api/session → `{data:{user:{id,email},membership:Membership|null,configured:boolean}}`; 401 when signed out.
- POST /api/auth/login `{account,password}`; POST /api/auth/logout. Username resolves @pvn.vn, independent cookie, no implicit survey membership.
- GET /api/records?kind=&q=&status=&page=1&archived=false → `{data:CatalogRecord[],total:number,page:number,pageSize:30}`; absent kind searches all.
- POST /api/records RecordInput → `{data:CatalogRecord}`. On creation, omitted/null/blank `code` receives a server-generated `AI-<UUID>` code; an existing supplied import code is retained. The same rule applies to POST /api/records/:id/related. The UI does not expose code entry. PATCH does not generate or replace codes automatically; the editor preserves stored codes. Both creation endpoints reject deprecated module kinds such as `collaboration_item`; existing records of those kinds remain readable and patchable during migration compatibility.
- GET /api/records/:id → `{data:CatalogRecord,links:Relation[],documents:CatalogDocument[],history: object[]}`.
- GET /api/records/:id/survey → `{data:UnitSurveySnapshot[]}`, admin only. Requires a readable `unit`; returns `[]` when no explicitly mapped survey is found, 400 for another record kind, 404 for a missing record. Snapshots are ordered by source `payload.updated_at` descending (fallback `created_at`), then snapshot `created_at` descending and ID. No fuzzy title matching, new imports or source writes.
- GET /api/records/:id/dossier → `Dossier` (shape below), HTTP 200. Preserves the detail fields and adds scoped related records and attachments.
- POST /api/records/:id/related `{record:RecordInput,relation:string,direction:'to-parent'|'from-parent',context?:Record<string,string>}` → `{data:CatalogRecord}`, HTTP 201. `record` must not contain `id`; only these four top-level keys are accepted. Requires write access to the active parent. Creates the record and its relation atomically when the contextual gateway is installed; the compatibility path uses the existing create/link/archive gateways and removes or archives a partially created partner if assigning its consortium context fails. `to-parent` means new record → parent; `from-parent` means parent → new record. Existing records are associated with POST /api/links.
- PATCH /api/records/:id RecordInput (id/version required) → `{data:CatalogRecord}`.
- DELETE /api/records/:id `{version}` → soft-delete to trash through the existing archive gateway, `{data:true}`. This retains `archived_at` semantics and the existing boolean response.
- POST /api/records/:id/restore `{version}` → `{data:true}`, HTTP 200. Requires an integer version from 1 through 2147483647; additional payload keys are rejected. Requires caller write/read permission and an archived record. Missing/unreadable record → 404, forbidden role → 403, stale version → 409, already-active record → 400. Clears `archived_at`, increments the record version and records audit action `restore` without changing links, documents, sources or ownership.
- GET /api/stats → `{data:{counts:Record<string,number>,recent:CatalogRecord[]}}`.
- GET /api/overview → `{data:Overview}` (see `src/lib/overview.ts`): compact, permission-filtered rows for standard problems, activities, partners, units, milestones, experts and training events. Powers every tab dashboard and the dossier highlight strip; one cached request per screen.
- POST /api/links `{source_id,target_id,relation,note?,context?}` → `{data:Relation}`. Context strings include attendance, role, organization_at_time, position_at_time and edition. A direct partner-to-partner consortium relation uses `context.consortium_role = 'lead' | 'member'`; promoting a lead demotes the prior lead of that consortium. DELETE /api/links/:id → `{data:true}`.
- GET /api/documents?q= → `{data:CatalogDocument[]}`.
- POST /api/documents multipart form: file, title, visibility=team|private, record_id?, document_id? (legacy immutable version support). → `{data:CatalogDocument}`. The current UI creates new files and does not expose version management.
- POST /api/documents/link `{record_id,document_id,version_id?}` → `{data:true}`; optional version pins a historical attachment. The current UI reuses the latest file automatically.
- DELETE /api/documents/:id/link `{record_id}` → `{data:true}`; removes only the link to that writable record or folder, with audit.
- DELETE /api/documents/:id → `{data:true}`; hides the document from the shared library and all dossiers after role/ownership checks. Registered versions and Storage objects remain for audit; this is not physical deletion.
- GET /api/documents/:versionId/download → protected redirect to short-lived signed download. `?preview=1` omits the download disposition for browser preview; the UI offers preview for PDF, images, TXT and CSV.

`UnitSurveySnapshot` is `{id:string,title:string,unit_code:string|null,created_at:string,payload:{answers:object|null,status:string|null,updated_at:string|null,schema_version:unknown}}`. The payload contains only these four properties; source identity metadata is not exposed here. The admin-only questionnaire renderer presents attachment names only, suppressing file paths/URLs from rendered values. File access remains through the existing document workflow.

Existing endpoint contracts remain unchanged. Dossier types and section actions are defined in `src/lib/dossier.ts`:

```ts
type RelatedRecord = {
  record: CatalogRecord;
  via: CatalogRecord | null;
  relation: string;
  direction: 'incoming' | 'outgoing';
};
type Dossier = {
  data: CatalogRecord;
  links: Relation[];
  documents: CatalogDocument[];
  history: Record<string, unknown>[];
  related: RelatedRecord[];
  attachments: { record: CatalogRecord; document: CatalogDocument }[];
};
```

`related` includes active, readable direct neighbors and selected second-edge neighbors through permitted operational records. It never expands through another unit, partner, expert or canonical use case. A record appears once, preferring a direct path; `via` is null for direct paths and identifies the readable intermediate otherwise. `direction` describes the final relation relative to the root or intermediate, not a new inferred edge. `attachments` retains each supporting record/document attachment and its version pin, checks document access independently, and excludes attachments belonging to neighboring unit/partner/expert/use-case/course entities. Root attachments remain in `documents`.

The UI fixes record kind, relation and direction for each contextual action. Hash URLs use `record/:id?tab=:section` plus an optional JSON `trail` of `{id,title,tab}` crumbs. Legacy `references` tabs resolve to `documents`. Removed `links`/`history` tabs and the unit `hierarchy` tab fall back to `overview`; `survey` is available only for admin unit dossiers. Verification statuses are hidden in presentation while existing stored status/API values remain compatible. These navigation hints never authorize access; APIs independently check membership and record permissions.

For the one-level partner cooperation model, canonical directions are `collaboration → partner`, `collaboration → unit`, `collaboration → use_case`, `engagement → partner` and `engagement → collaboration`. A collaboration may have many unit links and at most one link to a canonical use case. `unit` relation context may contain `subject_role: 'lead' | 'supporting'`. A milestone may link to zero, one or many cooperation contents; zero means it is a partner-level general milestone. Files remain attached to the record on which they were uploaded, and aggregation does not create new document links.

## Unified file presentation (existing endpoints)

`File & tài liệu` combines root attachments, readable reference containers/URLs and supporting-record attachments. Main `unit`/`partner`/`expert`/`use_case` dossiers retain the CV; supporting records render full details directly. Opening a file container reads its dossier inline. Existing reference IDs, URLs, metadata, document links and version pins are retained without a migration.

Folder creation uses POST `/api/records/:id/related` with a new `reference` record, `data.reference_type: 'Thư mục'`, parent visibility and direction `to-parent`; relation is `expert` for an expert parent and `related` otherwise. The UI permits one level and does not create folders under a reference. Rename uses the existing versioned PATCH, preserving other fields; renaming a shared container affects every dossier using that same record.

Root uploads use the root record ID; uploads/reuse inside a container use its record ID with the existing document endpoints. The new-file form defaults to the target record's visibility, which remains an explicit submitted choice. This default does not grant access or change document permissions. Reader/private/archived restrictions, independent document entitlement and per-record version pins continue to apply. No new endpoint or SQL contract is introduced; moving files, permanent file deletion and bulk file import are not provided by this UI. Soft-deleting a reference container uses the record lifecycle below and retains its files.

## Record trash and restore

The `#trash` UI uses the existing GET `/api/records?archived=true` contract, including `kind`, `q` and `page`; only readable archived records are returned. Previously archived records appear in the same trash view. Detail URLs opened there carry the known navigation hint `return=trash`, preserved through section changes and breadcrumbs; it is not an authorization flag. Record detail remains readable subject to the same permissions. Ordinary edit, association and attachment controls require an active record; restore is authorized separately for an archived record whose caller otherwise has write permission.

Deletion keeps audit action `archive` for compatibility. Restore adds action `restore`; both retain all related records, relation rows, source mappings, document links and pinned versions. Reader cannot perform either mutation. Private-owner/admin restrictions remain. There is no permanent record purge or registered-file deletion endpoint.

## Database RPC contract (public gateway, new names only)
All authenticated functions execute with caller privileges and RLS (or tightly checked security-definer if necessary). No authenticated user gets membership write directly. New ai_management schema contains common records and explicit typed detail tables from registry, relations, documents, document_versions/document_links, sources and audit.
- `ai_catalog_membership()` → membership object or null.
- `ai_catalog_list(p_kind text default null,p_query text default '',p_status text default null,p_page integer default 1,p_archived boolean default false)` → `{data,total,page,pageSize}`.
- `ai_catalog_get(p_id uuid)` → `{data,links,documents,history}`.
- `ai_catalog_unit_survey(p_id uuid)` → UnitSurveySnapshot[]; read-only, admin-only gateway from migration `202610080003_unit_survey_lookup.sql`. Resolves explicit source mappings as documented in [database.md](database.md).
- `ai_catalog_dossier(p_id uuid)` → `Dossier`; additive migration `202610080002_entity_dossiers.sql`.
- `ai_catalog_create_related(p_parent_id uuid,p_record jsonb,p_relation text,p_direction text)` → CatalogRecord; locks the active parent, checks write access, and composes save + link in one transaction. The direction values match the browser contract above.
- `ai_catalog_create_related_context(p_parent_id uuid,p_record jsonb,p_relation text,p_direction text,p_context jsonb)` → CatalogRecord; additive contextual variant used for consortium creation. It records `consortium_role` in the same transaction and demotes a prior lead before assigning a new one.
- `ai_catalog_save(p_record jsonb)` → CatalogRecord. Insert without id; update requires id/version; increment version atomically; data keys correspond typed detail columns.
- `ai_catalog_archive(p_id uuid,p_version integer)` → boolean; existing soft deletion used by the trash UI.
- `ai_catalog_restore(p_id uuid,p_version integer)` → boolean; migration 005 gateway. Locks the record row, checks membership/read/write permission and current version, rejects an already-active record, clears `archived_at`, increments `version` and appends a `restore` audit event. No table or policy changes.
- `ai_catalog_stats()` → `{counts,recent}`.
- `ai_catalog_overview()` → `{standards,activities,partners,units,milestones,experts,events}`; only active records the caller can read, relations only when both ends are readable.
- `ai_catalog_link(p_link jsonb)` → Relation; validate target/source kinds and no parent cycles.
- `ai_catalog_consortium_link(p_link jsonb)` → Relation; partner-to-partner gateway that accepts only `lead` or `member` and serializes lead replacement for one consortium source.
- `ai_catalog_collaboration_unit_link(p_link)` → atomically add/update a unit role (`subject_role` lead/supporting) and reassign the single lead, for an activity (`collaboration`) or a standard problem (`use_case`, lead = priority lead unit, supporting = potential unit).
- `ai_catalog_partner_review()` → reconciliation report for administrators. These gateways are installed by migration `202610130002_flatten_partner_cooperation.sql` and are not granted to `anon`.
- `ai_catalog_unlink(p_id uuid)` → boolean.
- `ai_catalog_documents(p_query text default '')` → CatalogDocument[].
- `ai_catalog_document_save(p_document jsonb)` → CatalogDocument. Input title,visibility,document_id? plus version_id UUID chosen by server, filename,mime_type,size_bytes,storage_path,checksum; record_id? optional. The file is first uploaded to path <user_id>/<version_id>/file.<extension>; member can write only own prefix; document registration validates prefix/metadata; new versions on authorized document only. On RPC failure, server removes uploaded unregistered object. Versions immutable. UI never receives storage_path.

File upload accepts PDF, Word (DOC/DOCX), Excel (XLS/XLSX), PowerPoint (PPT/PPTX), TXT/CSV/MD/RTF, PNG/JPG/JPEG/GIF/WEBP and ZIP/7Z/RAR. The browser and API use the same extension/MIME rules; an empty or generic binary browser MIME is accepted for an allowed extension, while a conflicting specific MIME is rejected. The current Supabase Free project allows 50 MiB per file; the metadata constraint is prepared for 100 MiB, but the application and bucket must remain at 50 MiB until the project is upgraded and its global limit is raised. Archives and other formats without browser preview are download-only; no archive contents are unpacked or indexed.
- `ai_catalog_document_link(p_record_id uuid,p_document_id uuid,p_version_id uuid default null)` → boolean; both readable, write permission record.
- `ai_catalog_download(p_version_id uuid)` → `{storage_path,filename}` only when allowed; normal storage signed request ALSO enforces RLS via document-version entitlement.

Bucket: `ai-catalog-documents`, private. Role admin/editor/reader. All members read team records; private records/files creator or admin only. Editor writes own or team records; reader no writes. Linking never grants document read. Typed fields have common max lengths and date/nonnegative validation. Return errors with stable codes/messages (CONFLICT, FORBIDDEN, NOT_FOUND, VALIDATION) for handlers to translate. Restrict public/anon execute/grants explicitly; do not touch existing functions/policies/tables.

Migrations 002 and 003 add three gateways to the original 15 (18 total after application), without replacing existing gateways or changing source/import contracts. Migration 005 adds only `ai_catalog_restore`, bringing the total to 19 after application; migration 004 keeps the count at 18. Migration `202610130001_contextual_related_creation.sql` adds the two consortium gateways, bringing the total to 21 when applied. Migration `202610130002_flatten_partner_cooperation.sql` adds the atomic PVN-subject gateway and read-only reconciliation gateway, bringing the total to 23 when applied. Migration `202610130003_reconcile_cooperation_consortium.sql` refines the existing report without adding another gateway. The API detects absence of the three new mutation gateways and uses existing gateways for compatibility; the reconciliation endpoint requires its migration. Deployment status is tracked in [verification.md](verification.md).

Since 14/10/2026 an activity (`collaboration`) may be created from any dossier context; the API no longer requires a partner parent. `POST /api/links` with `context.subject_role` routes to `ai_catalog_collaboration_unit_link` for both activities and standard problems.
