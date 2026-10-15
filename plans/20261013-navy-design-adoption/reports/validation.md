# Navy design adoption — non-browser validation

Date: 2026-10-13  
Status: DONE_WITH_CONCERNS — all assigned automated checks passed; controller reports authenticated CUA checks passed within the scope below. Production build predates the final minor CSS/focus changes.

## Summary

The existing validation project passed all 116 tests across ten spec files. Lint, standalone TypeScript checking and the production build also passed. No application source or tests were changed by this validation task.

## Results

| Command | Result | Detail |
| --- | --- | --- |
| `npm test -- --project=validation` | PASS | 116 passed, zero failed/skipped; 2 workers; 1.7 seconds |
| `npm run lint` | PASS | Exit 0, no warnings or errors |
| `npm run typecheck` | PASS | Exit 0, no diagnostics |
| `npm run build` | PASS, before final minor changes | Next.js 16.4.0, webpack; compiled successfully; TypeScript passed; 3 static pages generated |
| `npx eslint src/components/catalog-app.tsx src/components/executive-dashboard.tsx` | PASS, final source | Exit 0, no warnings or errors |
| `npm run typecheck` (final rerun) | PASS, final source | Exit 0, no diagnostics |

`next.config.ts` has no `NEXT_BUILD_DIR`/`distDir` override. The controller confirmed that the development server was stopped and explicitly coordinated the normal build before restarting it. Build output was `/`, `/_not-found`, and `/api/[...path]`; no build warning occurred.

The test runner emitted only the environment warning that `NO_COLOR` is ignored while `FORCE_COLOR` is set. It did not affect execution.

## Final verification update

After the initial build, the controller aligned the dashboard's two-column breakpoint to 650px, included `summary` in the mobile keyboard focus selector and included the survey heading in the dossier section counter. Source inspection confirmed these changes. The narrow ESLint command and full standalone TypeScript check passed afterward. No further production build was run because the development server was active and the controller explicitly requested that it remain undisturbed.

The controller reports authenticated CUA checks passed for real FPT search, card/table switching, opening a record, edit/cancel, files and cooperation. A 375px viewport had no page overflow; keyboard navigation reached the mobile summary disclosure, and Escape returned focus to the menu opener. No database writes were performed. These browser results are attributed to the controller and were not independently repeated by this validation task.

## Contract and data checks

- Dashboard tests retain the four KPI kinds, five chart kinds, independent first-page requests, API order, bounded three-record previews, errors/retry, empty states and responsive stylesheet assertions.
- Existing tests cover schema validation, provenance and normalization, survey display, dossier grouping, real readable file counts, relation direction, privacy/write affordances, upload limits and workbook import invariants.
- Source inspection of `executive-dashboard.tsx` confirmed counts come from `/api/stats` and recent records from `/api/records`. Record titles, dates and initials derive from response records.
- `record-list.tsx` uses the same returned records for both cards and tables, preserves query/status/kind/archive pagination parameters, uses returned totals and page size, and passes the archive return state when opening a record.
- `record-detail.tsx` retains dossier requests, `canWriteRecord`, ownership/role restore checks, versioned lifecycle requests, pending-operation protection, stale-version recovery and admin-only survey access.
- `catalog-app.tsx` retains the session and membership gates, actual account identity/role, reader write restrictions, admin-only source route, dossier trail navigation and mobile Escape/Tab focus handling.
- Targeted production component/style search found no mock, demo or prototype markers; placeholder matches were normal input placeholders. No `test.skip`, `test.fixme` or focused `test.only` was found in the tests.

## Limitations and follow-up

- No browser was launched by this task. The API, desktop and mobile Playwright projects were deliberately not run; the controller conducted CUA visual and interaction verification as reported above.
- These checks do not prove persisted create/edit/delete/restore/upload interactions end to end or server authorization against live data. The authenticated edit check stopped at cancellation.
- No coverage instrumentation is configured in the executed command, so no line/branch coverage percentage is claimed.
- This directory is not a Git repository; a historical diff proving every pre-existing assertion and API file remained unchanged was unavailable. The existing suites were run unchanged, and current contracts were inspected as described above.
- The 116-test suite, full lint and production build passed before the final minor CSS/focus changes; final source additionally passed narrow lint and full typecheck. A final production rebuild is not claimed.
