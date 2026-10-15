# Authenticated browser verification

Date: 2026-10-13
Status: Complete

The controller inspected the real app at http://localhost:3100 using the existing authenticated session and CUA. No records, files, permissions or database values were modified.

- Desktop: dashboard loads real counts and recent records, with the approved energy image, navy shell and Be Vietnam Pro font.
- Partner directory: live search returns the matching FPT Digital record; switching cards/table preserves the result and query.
- Dossiers: unit, partner and collaboration pages render real content, readable long Vietnamese titles, related records and unified documents. Parent-to-collaboration navigation retains the dossier trail.
- Edit form opens and cancellation returns to the dossier. Opening the document folder shows the existing PDF and authorized file controls.
- Mobile at 375 × 812: no horizontal page overflow; cover actions and titles wrap. Keyboard focus reaches the navigation disclosure; Enter expands it; Escape closes navigation and returns focus to the opener.
- Final correction: include summary controls in the mobile focus trap. Verified through keyboard interaction after the correction.
- Desktop screenshot saved at /private/tmp/pvn-ai-catalog-navy-live.png. App left on the overview route with its development server running.

## Coverage limits

Persisted create/edit/delete/restore/upload actions were not executed against live data. Existing automated contracts passed; this report does not claim end-to-end write-operation coverage. The production build and 116 tests passed before the final minor CSS/focus changes; final narrow lint and full typecheck passed afterward, as detailed in the validation report.
