# Dorar test storage fixture

`dorar-test-storage.patch` changes only two tests in the pinned Dorar submodule.
Those tests otherwise open the default disk cache, making clean package checks
depend on host paths and saved data. The patch supplies in-memory Drift
connections and resets them after each suite. It changes no production source.

`fvm exec bash tool/checks.sh packages` applies the patch before package checks.
The reverse check makes repeated runs harmless. An incompatible or independently
edited fixture fails the forward check instead of overwriting it. CI uses the
same path after checking out the pinned submodule. Keep the patch synchronized
with any future submodule revision; remove it once upstream contains the fix.
