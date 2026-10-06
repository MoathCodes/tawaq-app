# Worktree preflight

Run from the task checkout. Read `.fvmrc`, submodule state, `tool/codegen.sh`, and applicable CI configuration for current commands.

1. Verify branch, base revision, dirty files, and disk space. Keep one editing worker per branch.
2. Use the pinned FVM SDK, initialize recursive submodules, and resolve app/package dependencies. Classify missing nested path dependencies as setup failures.
3. Generate through the repository's codegen path when checkout or changed inputs require it. Account for resulting tracked changes.
4. Run a relevant baseline check. Record existing failures with the base commit and exact diagnostic; compare against branch results. Repair within scope or report explicitly.
5. Trace actual storage initialization before choosing isolated app data. Verify proposed XDG/environment overrides are honored. A scoped visual harness proves only the surfaces it exercises.

Done: dependencies resolve, the SDK matches, baseline failures are known, and test data paths are distinct from the user's live Tawaq data.
