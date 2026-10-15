---
phase: 1
title: "Implement and verify"
status: completed
priority: P1
effort: "large"
dependencies: []
---

# Phase 1: Implement and verify

## Overview

Deliver the agreed partner dossier model, migrate compatible data, and verify the resulting UI and data contracts end to end.

## Requirements

- Functional: one-level cooperation contents with many PVN subjects, zero or one canonical use-case link, optional promotion of other content to a use case, many milestones, status and classification.
- Functional: partner-level and cooperation-level milestones/files, automatic folder aggregation, contact grid, simplified consortium flow, and use-case reverse lookup.
- Non-functional: preserve membership, record lifecycle, document security, audit, survey isolation, and existing imported records.

## Implementation Steps

1. Update typed schema and gateway projections with an additive, transactional one-time migration and reconciliation queries.
2. Update API/domain presentation helpers for one-level cooperation content and reverse use-case lookup.
3. Rebuild the partner dossier sections and complete milestone/file forms.
4. Convert compatible current data and produce a partner-data review report.
5. Run focused and broad automated checks plus authenticated desktop/mobile verification.

## Todo

- [x] Data model and migration prepared and verified locally
- [x] API and domain helpers
- [x] Partner dossier UI
- [x] Migration/reconciliation report prepared
- [x] Tests and authenticated browser verification
- [x] Apply migrations through `202610130003` via the official Supabase MCP client and run the live reconciliation report

## Success Criteria

- No nested collaboration/content hierarchy remains in the partner workflow.
- Existing usable data is retained, unresolved rows are reported rather than silently discarded.
- All acceptance criteria in `plan.md` pass.

## Risk Assessment

The existing database may not yet have the prior consortium migration. The migrations run in filename order, once per project, consistent with the repository deployment contract. Legacy relations can be ambiguous; migration will preserve them and flag uncertain mappings for review instead of guessing.
