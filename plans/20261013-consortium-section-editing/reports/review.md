# Final review

No release-blocking findings remain.

- Related-record edit controls use the target record permission through `canWriteRecord`; a selected existing consortium must be writable when it becomes the relation source.
- Canonical roles use `consortium_role`; legacy `role` and `Vai trò` values remain readable.
- The new SQL gateways serialize lead replacement and create the partner plus relation atomically.
- The live database compatibility path uses existing gateways, restores a relation when replacement fails, and removes/archives a newly created partner when role assignment fails. It cannot provide cross-RPC transaction isolation under concurrent lead changes; applying the tested migration removes that limitation.
- Modal focus is contained, Escape closes the dialog, and focus returns to the originating section button.
- Consortium preview and “Xem thêm” now share the same three-record boundary.

Independent reviewer/tester agents were requested but could not start because the workspace agent quota was exhausted. The controller completed this evidence-based review against the implementation, tests, SQL runner and authenticated browser state.
