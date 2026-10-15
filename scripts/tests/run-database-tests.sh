#!/usr/bin/env bash
# Uses a disposable local PostgreSQL cluster, never DATABASE_URL or Supabase.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "$script_dir/../.." && pwd)"
for program in initdb pg_ctl psql node; do
  command -v "$program" >/dev/null || { printf '%s is required on PATH.\n' "$program" >&2; exit 1; }
done
test_dir="$(mktemp -d /tmp/ai-cat-sql.XXXXXX)"
cleanup() {
  if [[ -f "$test_dir/data/postmaster.pid" ]]; then
    pg_ctl -D "$test_dir/data" stop -m fast >/dev/null 2>&1 || true
  fi
  rm -rf -- "$test_dir"
}
trap cleanup EXIT
initdb -D "$test_dir/data" --auth=trust --no-locale --encoding=UTF8 >"$test_dir/init.log"
# Empty listen_addresses disables TCP. The private socket directory isolates this run.
pg_ctl -D "$test_dir/data" -l "$test_dir/server.log" -o "-h '' -k $test_dir -p 55439" start >/dev/null
cd -- "$project_dir"
# Use the actual UI configuration to exercise every contextual action against SQL.
dossier_sections="$(node --experimental-strip-types --input-type=module -e 'import { dossierSections } from "./src/lib/dossier.ts"; process.stdout.write(JSON.stringify(dossierSections));')"
catalog_modules="$(node --experimental-strip-types --input-type=module -e 'import { modules } from "./src/lib/catalog.ts"; process.stdout.write(JSON.stringify(modules));')"
psql -X -h "$test_dir" -p 55439 -d postgres -v ON_ERROR_STOP=1 -v "dossier_sections=$dossier_sections" -v "catalog_modules=$catalog_modules" \
  -f "$script_dir/bootstrap.sql" \
  -f "$project_dir/supabase/migrations/202610080001_ai_catalog.sql" \
  -f "$project_dir/supabase/migrations/202610080002_entity_dossiers.sql" \
  -f "$project_dir/supabase/migrations/202610080003_unit_survey_lookup.sql" \
  -f "$project_dir/supabase/migrations/202610080004_partner_expert_dossiers.sql" \
  -f "$project_dir/supabase/migrations/202610080005_record_restore.sql" \
  -f "$project_dir/supabase/migrations/202610130001_contextual_related_creation.sql" \
  -f "$script_dir/cooperation-migration-setup.sql" \
  -f "$project_dir/supabase/migrations/202610130002_flatten_partner_cooperation.sql" \
  -f "$script_dir/cooperation-migration-checks.sql" \
  -f "$script_dir/catalog-checks.sql" \
  -f "$script_dir/document-checks.sql" \
  -f "$script_dir/archive-checks.sql" \
  -f "$script_dir/dossier-checks.sql" \
  -f "$script_dir/unit-survey-checks.sql" \
  -f "$script_dir/expert-checks.sql" \
  -f "$script_dir/record-files-checks.sql" \
  -f "$script_dir/restore-checks.sql" \
  -f "$script_dir/consortium-checks.sql" \
  -f "$script_dir/cooperation-consortium-setup.sql" \
  -f "$project_dir/supabase/migrations/202610130003_reconcile_cooperation_consortium.sql" \
  -f "$script_dir/cooperation-consortium-checks.sql" \
  -f "$project_dir/supabase/migrations/202610130004_document_actions.sql" \
  -f "$project_dir/supabase/migrations/202610130005_document_trash_guard.sql" \
  -f "$script_dir/document-actions-checks.sql" \
  -f "$script_dir/cooperation-deduplication-setup.sql" \
  -f "$project_dir/supabase/migrations/202610130006_deduplicate_partner_cooperation.sql" \
  -f "$script_dir/cooperation-deduplication-checks.sql" \
  -f "$script_dir/partner-identity-setup.sql" \
  -f "$project_dir/supabase/migrations/202610130007_reconcile_partner_identities.sql" \
  -f "$script_dir/partner-identity-checks.sql" \
  -f "$project_dir/supabase/migrations/202610140001_ai_roadmap_model.sql" \
  -f "$script_dir/roadmap-model-checks.sql" \
  -f "$script_dir/standard-catalog-setup.sql" \
  -f "$project_dir/supabase/migrations/202610140002_standard_problem_catalog.sql" \
  -f "$script_dir/standard-catalog-checks.sql" \
  -f "$project_dir/supabase/migrations/202610140003_split_unit_problems_by_partner.sql" \
  -f "$script_dir/activity-provider-setup.sql" \
  -f "$project_dir/supabase/migrations/202610140004_unit_as_activity_provider.sql" \
  -f "$script_dir/activity-provider-checks.sql" \
  -f "$script_dir/activity-lead-setup.sql" \
  -f "$project_dir/supabase/migrations/202610140005_activity_lead_and_type_catalogs.sql" \
  -f "$script_dir/activity-lead-checks.sql" \
  -f "$project_dir/supabase/migrations/202610140006_partner_and_activity_type_lists.sql" \
  -f "$project_dir/supabase/migrations/202610140008_overview_consortium_lead.sql" \
  -f "$script_dir/purge-legacy-setup.sql" \
  -f "$project_dir/supabase/migrations/202610140009_purge_legacy_and_archived_records.sql" \
  -f "$script_dir/purge-legacy-checks.sql" \
  -f "$script_dir/dictionary-review-setup.sql" \
  -f "$project_dir/supabase/migrations/202610140010_apply_data_dictionary_review.sql" \
  -f "$script_dir/dictionary-review-checks.sql" \
  -f "$script_dir/work-item-setup.sql" \
  -f "$project_dir/supabase/migrations/202610150001_work_item_catalog.sql" \
  -f "$script_dir/work-item-checks.sql" \
  -f "$project_dir/supabase/migrations/202610150002_work_item_start_date.sql" \
  -f "$script_dir/work-item-start-date-checks.sql" \
  -f "$project_dir/supabase/migrations/202610150003_activity_done_status.sql" \
  -f "$script_dir/training-move-setup.sql" \
  -f "$project_dir/supabase/migrations/202610150004_training_into_activities.sql" \
  -f "$script_dir/training-move-checks.sql" \
  -f "$project_dir/supabase/migrations/202610150007_overview_management_fields.sql" \
  -f "$project_dir/supabase/migrations/202610150008_list_search_short_names.sql" \
  -f "$project_dir/supabase/migrations/202610150009_contact_directory.sql" \
  -f "$script_dir/contact-directory-checks.sql" \
  -f "$project_dir/supabase/migrations/202610150010_delete_contacts_with_organisation.sql" \
  -f "$script_dir/contact-cleanup-checks.sql" \
  -f "$project_dir/supabase/migrations/202610150011_document_uploader_name.sql" \
  -f "$script_dir/document-uploader-checks.sql" \
  -f "$script_dir/overview-management-checks.sql" \
  -f "$script_dir/activity-meeting-setup.sql" \
  -f "$project_dir/supabase/migrations/202610150012_activity_meetings_to_milestones.sql" \
  -f "$script_dir/activity-meeting-checks.sql" \
  -f "$script_dir/ui-contract-checks.sql"
