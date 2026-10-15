---
title: Implement and verify consortium editing
status: completed
phase: 1
---

# Phase 01 — Implement and verify

Status: Complete

## Touchpoints

- `src/lib/dossier.ts`, `src/lib/dossier-summary.ts`: section semantics and relation context projection.
- `src/components/record-summary.tsx`, `dossier-section.tsx`, `partner-sections.tsx`, `record-editor.tsx`: complete section layout, local editing and modal editing.
- `src/app/api/[...path]/route.ts`, `supabase/migrations/`: atomic contextual creation for consortium relations.
- `src/app/globals.css`: modal, section editing and empty-state presentation.
- `tests/dossier-summary.spec.ts`, `tests/dossier-presentation.spec.ts`: behavior contracts.

## Steps

- [x] Add tests for complete empty-section rendering semantics, partner-only consortium actions and lead context.
- [x] Add context-aware consortium linking and creation while retaining existing generic record/link APIs.
- [x] Render all summary sections and add section edit controls with inline/modal modes.
- [x] Add per-record edit controls inside managed sections and verify focus/close behavior.
- [x] Reconcile final tester/reviewer findings and finish the completion report.

## Risks and rollback

- Context must be written atomically with a newly created partner to avoid orphan records.
- Modal focus must return to the originating section edit button.
- Existing imported role keys remain readable while new links use `consortium_role`.
- Roll back the presentation changes and new contextual RPC together; existing links and records remain valid.
