---
title: "Redesign partner cooperation content"
description: "Flatten partner cooperation into one-level cooperation contents with shared use-case catalog links, multi-party PVN ownership, milestones, and files."
status: completed
priority: P1
effort: "large"
tags: [partner, collaboration, use-case, migration, ui]
created: 2026-10-13
---

# Redesign partner cooperation content

## Overview

Replace the nested partner collaboration model with one-level **Nội dung hợp tác** records. Each record belongs to one partner, can involve multiple PVN subjects, optionally links to a canonical use case, and owns classifications, status, milestones, and a logical file folder. Partner-level milestones and files remain valid and aggregate beside cooperation-specific content.

## Goals

| # | Goal | Priority |
|---|------|----------|
| 1 | Simplify the partner dossier into one continuous page with no “Xem đầy đủ” navigation | P1 |
| 2 | Model cooperation contents, PVN subjects, milestones, use-case links, and folders explicitly | P1 |
| 3 | Simplify contacts and consortium workflows | P1 |
| 4 | Preserve and reconcile existing partner data through a transactional one-time migration | P1 |

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Implement and verify](./phase-01-start.md) | Completed |

## Success Criteria

- [x] Partner dossier sections display together without “Xem đầy đủ”.
- [x] Contacts use an editable table/grid.
- [x] Consortium addition selects or creates a partner and maintains one lead.
- [x] Cooperation contents are one level, support multiple PVN subjects, canonical use cases or other catalog content, classification and status tags.
- [x] Milestones link to zero or more cooperation contents and accept file attachments in one complete form.
- [x] Files aggregate into cooperation-content folders or partner-level general files.
- [x] Canonical use cases show their partner-specific cooperation contents.
- [x] Existing partner data is migrated and a reconciliation report identifies duplicates, incomplete records, and unresolved relations.
- [x] Focused tests, lint, typecheck, build, SQL validation, and authenticated browser checks pass.

<!-- slug: redesign-partner-cooperation-content -->
