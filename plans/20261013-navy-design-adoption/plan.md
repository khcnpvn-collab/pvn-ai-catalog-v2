# Adopt the approved navy design

Date: 2026-10-13  
Status: Complete. Approved design applied to the real app; automated checks and authenticated desktop/mobile verification completed. See [validation](reports/validation.md), [browser verification](reports/browser-verification.md) and [review](reports/code-review.md).

Port the approved Sites prototype into the existing Next.js application, using production records and preserving all current operations and permissions.

## Phase

1. [Design adoption and verification](phase-01-design-adoption.md): shared tokens/assets and shell; dashboard; lists and dossiers; integration and visual checks.

## Dependencies

- Reference: `../sites/pvn-energy-design/dist/{styles.css,app.js,index.html,assets/}`.
- Existing presentation rules: `docs/design-guidelines.md`; approved navy design supersedes its Lexend, 4px corners, green primary actions and no-background-image direction.
- Existing API contracts, dossier helpers, membership gates and navigation remain authoritative.
- One integration owner edits `globals.css`; independent owners use the existing class contracts or their owned CSS modules.

## Acceptance

- Be Vietnam Pro, navy shell, energy hero, rounded white panels, dossier cover/index, cards and tables visually match the approved reference at desktop and mobile widths.
- All displayed counts, titles, dates, relations, files and account information come from current application data; prototype JavaScript, mock records, demo actions and prototype labels are absent.
- Search, pagination, creation/editing, trash/restore, relation navigation, file operations, mobile focus behavior and role restrictions retain their current contracts.
- No database, migration, API, authentication or permission changes.
- Relevant existing tests, lint, typecheck and build pass; desktop/mobile visuals inspected. Any authenticated verification limitation is reported accurately.
