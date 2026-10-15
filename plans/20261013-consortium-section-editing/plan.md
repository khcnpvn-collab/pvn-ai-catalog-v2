---
title: Consortium and section editing
status: completed
priority: P1
effort: medium
branch: none
tags: [partner, consortium, dossier, ui]
created: 2026-10-13
---

# Consortium and section editing

Date: 2026-10-13  
Status: Complete  
Progress: 5/5 validation groups complete

## Outcome

Keep consortiums in the partner catalog, let users select or create full partner profiles as members, and identify one member as the consortium lead. Show every dossier section independently and support section-level editing from the overview.

## Phase

1. [Implement and verify](phase-01-implement-and-verify.md)

## Acceptance

- A consortium member or consortium is selected from `partner`; creating either opens the normal partner profile form and saves a full partner record.
- The relation records whether the selected party is the consortium lead and displays that role in both consortium directions.
- Every dossier section appears in its normal order even when empty; “Các mục khác” is removed.
- Every section has its own edit control. Simple sections edit in place; collaboration and engagement sections use an accessible modal form.
- Existing permissions, records, relations, files, navigation and API responses remain compatible.
- Focused tests, full validation, lint, typecheck, build and authenticated desktop/mobile checks pass.
