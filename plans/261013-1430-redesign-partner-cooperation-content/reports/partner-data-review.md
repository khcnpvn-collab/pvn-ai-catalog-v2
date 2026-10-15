# Partner data review — 2026-10-13

## Deployment

All three October 13 migrations are applied to the connected Supabase project `icycubrzvfptfehxqvfp` through the official Codex MCP client. OAuth was restored before deployment. The raw pre-migration snapshot and live reports are stored in `.private/migration-backups/`, excluded from Git.

## Reconciliation

- 75 partner dossiers; 160 one-level cooperation contents.
- 53 legacy items converted with IDs, files, sources and audit retained; zero legacy items remain.
- Two consortium contents previously linked to their group and its members. All member relationships and lead roles already existed on the consortium dossier. Four redundant content-to-member edges were removed with complete before-values in audit; both contents retain their original group owner.
- Zero duplicate name groups, invalid partner counts, multiple canonical use cases, multiple lead PVN subjects or cooperation milestones missing their partner.
- The independent Mehdi Hatamian expert meeting remains unchanged and is outside the partner-milestone check.
- Optional source gaps remain: 73 legal names, 7 partner types and 42 countries. Existing dossier titles are valid; missing fields are not fabricated.

## Preservation checks

534 records, 42 documents, 42 versions, 42 file links and 418 sources before and after. Public survey data hashes, public column definitions, public/Storage policies and all 19 pre-existing gateway definitions match the baseline. All four new gateways are executable by `authenticated`, not `anon`, and enforce membership/ownership inside SQL.

The complete disposable PostgreSQL suite and 13 focused workbook contract tests pass. The importer now assigns grouped cooperation to the group dossier and retains membership in the consortium itself.
