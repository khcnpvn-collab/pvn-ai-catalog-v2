# Phase 01 — Approved design in the real app

Status: Complete — shell, dashboard, lists and dossiers integrated and verified.  
Context: [plan](plan.md), `docs/design-guidelines.md`, local `AGENTS.md`, approved `../sites/pvn-energy-design/dist/`.

## Ownership and files

| Slice | Sole write ownership | Responsibility |
| --- | --- | --- |
| Integration/shell | `src/app/globals.css`, `src/components/catalog-app.tsx`, `public/fonts/be-vietnam-pro-{400,500,600,700}.ttf`, `public/brand/energy-hero.png`, `docs/design-guidelines.md` | Tokens, fonts/assets, shared components, shell, list/dossier CSS, responsive integration and docs |
| Dashboard | `src/components/executive-dashboard.tsx`, `src/components/executive-dashboard.module.css` | Hero, metric cards, chart and latest-record composition using current requests |
| Integration/shell (same controller) | `src/components/record-list.tsx`, `src/components/record-detail.tsx`, `src/components/record-summary.tsx`, `src/components/partner-sections.tsx` | Presentation markup, record cards/table toggle where useful, dossier identity, numbered sections and partner presentation |

Workers are not alone in the codebase: do not revert others. The integration owner receives needed class names from markup owners and alone updates global CSS. No edits to `src/lib`, `src/app/api`, migrations, seed data or package dependencies. Read relevant bundled Next.js docs before framework changes, as local `AGENTS.md` requires.

## Exact token and asset transfer

Copy the approved font binaries and energy image from prototype `assets/`; reference local public URLs. Keep production PVN logos.

| Prototype value | Application mapping |
| --- | --- |
| `--navy: #102d55` | `--navy`, hero base and profile cover |
| `--navy-deep: #081b36` | new `--navy-deep`, sidebar |
| `--accent: #17477c`; hover `#0b2f59` | new `--accent`, primary actions, links; retain green only for genuine success states |
| `--accent-soft: #dceaff` | `--blue-soft` / accent-soft surfaces |
| `--ink: #172c49`; `--muted: #5d6d83` | existing text tokens |
| `--paper: #f3f5f8`; `--white: #fff`; `--soft: #edf2f8` | `--bg`, `--surface`, `--subtle` |
| `--line: #dce3ed`; `--blue: #305f86`; `--copper: #935d37` | border, secondary blue and warm decorative accents |
| active navigation `#234f84` | `--nav-active` |
| `--radius: 16px`; sidebar `240px` | shared token and shell width; buttons 8px, panels 14px, metric 12px, profile 16px, hero 18px |
| Be Vietnam Pro 400/500/600/700 | local `@font-face`, body/form inheritance; remove Lexend declarations |
| body 14px / 1.65; heading 36px/600 | shared typography; profile heading 32px; section heading 19–21px |

Match topbar 84px, content padding 32px 38px 54px, content maximum width 1650px, sidebar padding 32px 20px 20px. Keep readable 16px inputs and minimum 44px interactive targets from the app. These access requirements remain when prototype controls are smaller.

## Class mapping

Prefer styling existing semantic classes; new wrappers should expose the prototype geometry without rewriting behavior.

| Reference selector | Existing target / change |
| --- | --- |
| `.sidebar`, `.brand`, `.nav-link`, `.account` | `.sidebar`, `.sidebar-brand .brand`, `.nav-item`, `.sidebar-account`; preserve all production navigation groups and real account/logout |
| `.workspace`, `.topbar`, `main`, `.app-footer` | same shell / `.main-content`; add production footer, keep global search form and role display |
| `.page-head`, `.button`, `.pill`, `.panel` | `.page-heading`, `.button`, `.badge`, `.panel` |
| `.hero`, `.hero-copy`, `.hero:before` | dashboard module `hero`, `heroCopy`; background asset, minimum 320px, overlay `linear-gradient(90deg,#071a38df 0%,#122e6355 52%,transparent 80%)` |
| `.metrics`, `.metric`, `.metric-top`, `.metric-value` | dashboard `kpiGrid`, `kpiCard`, `kpiLabel`; add icon/value wrappers without changing count source |
| `.dashboard-grid`, `.bar-row`, `.bar-track` | dashboard composition wrapper, `barList li`, `barTrack`; thin 9px bars, actual max-scaled counts |
| `.panel-pad`, `.list-row`, `.editorial-card` | dashboard `latestBlock`, `recordList`, `recordLink`; preserve four independently loaded groups and at most three live entries per group |
| `.catalog-banner`, `.toolbar`, `.search-box`, `.segment` | list banner; existing `.toolbar`, `.search-field`; optional real-data grid/table switch with `aria-pressed` |
| `.card-grid`, `.partner-card`, `.table-wrap` | add list card wrappers using returned `CatalogRecord[]`; existing `.table-scroll`, `RecordTable` remain available |
| `.profile-cover`, `.profile-title`, `.profile-meta` | `.dossier-heading`, `.dossier-identity`, `.dossier-identity-meta`; keep lifecycle actions and confirmation outside decorative layers |
| `.profile-layout`, `.profile-index`, `.profile-section`, `.section-head` | `.cv-dossier`, `.cv-contents`, `.cv-section`, `.cv-section-heading`; desktop columns 190px + remaining width, gap 27px |
| `.facts`, `.narrative`, `.section-number` | `.record-facts`, `.cv-narrative`, new section-number span based on visible section order |
| `.contact-grid`, `.contact`, `.coop-card`, `.timeline` | `.partner-contact-grid`, `.partner-contact-card`, `.partner-collaboration-card`, `.partner-timeline` |
| `.file-row`, `.file-icon` | style current file area classes after inspection; keep `RecordFiles` behavior and all file permissions |

Profile cover gradient: `linear-gradient(110deg,#102c52 0%,#173e6b 65%,#224e7e)`, padding 30px 32px. Profile sections use white, 13px radius, 27px padding, 24px gap. Reproduce decorative rings with noninteractive pseudo-elements. Derive initials from actual titles; never invent missing factual metadata.

## Implementation sequence

1. Confirm existing working-tree edits; copy only approved assets and set shared tokens/fonts.
2. Implement owned shell/dashboard/list-dossier slices with agreed class mapping. Keep real API URLs, callbacks, hashes and permission checks unchanged.
3. Integrate global styles once. Remove superseded conflicting declarations rather than accumulate alternate themes. Use prototype tablet/mobile layout as reference while preserving overflow and focus safeguards.
4. Preserve all four latest categories and five chart series, existing reader/editor/admin rules, archived states, stale-version recovery and source/survey restrictions. Preserve partner unassigned content, consortium directions, unified files and empty-section handling.
5. Update design guidelines date and actual design decisions; retain functional sections and protected contracts.

## Validation

- First run existing relevant Playwright specs: `dashboard-presentation`, `dossier-presentation`, `dossier-summary`, `record-files` and `signed-out-ui`; inspect their assertions before adapting any visual expectations. Do not weaken behavior checks or add test-only production data.
- Then run `npm run lint`, `npm run typecheck`, `npm run build` because shared global styles and shell changed. Broaden existing tests only for a new regression or changed shared contract.
- Compare desktop and mobile screenshots to the approved local prototype: shell/hero, one list, a real partner dossier and collaboration dossier. Inspect long Vietnamese titles, zero/empty/error states, table overflow, keyboard focus, reduced motion and mobile menu closing.
- Verify live search/page navigation and permission-dependent controls using authorized existing sessions; report unavailable authenticated coverage rather than claim it passed.
- Check that no prototype names, counts, demo badges, demo handlers, mock imports or schema changes entered production files.

## Risks and rollback

Shared CSS may affect forms, survey tables and file controls: retain semantic error/success colors, 16px inputs, safe overflow and existing selectors; inspect those surfaces. Longer production navigation must remain scrollable inside the 240px sidebar. Authenticated record availability can limit visual coverage and must be stated. Roll back only this presentation change and newly copied assets, preserving unrelated edits and all production data.

## Dashboard slice verification

- `npx playwright test tests/dashboard-presentation.spec.ts`: 3 passed.
- Dashboard ESLint and application TypeScript checks passed.
- Hero, four KPI cards, partner/chart pair and remaining three independent latest groups implemented in the two owned dashboard files.
- Integrated validation and authenticated UI verification completed; see [validation](reports/validation.md) and [browser verification](reports/browser-verification.md).
