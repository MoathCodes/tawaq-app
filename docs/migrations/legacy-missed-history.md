# Legacy missed prayer records (TAW-17)

The recorded product decision is that `missed` means no completion record. It
must never become `late`. Hive wire indices remain jamaah=0, onTime=1, late=2,
missed=3, none=4. All other statuses and exact row keys remain compatible.

The user explicitly approved enabling this planned cleanup on 2026-10-04.
`prayerDatabaseProvider` now runs the migration after Hive initialization, before
any history read, write, analytics or duplicate repair. `AppBootstrap` also waits
for `prayerHistoryReadyProvider` before mounting the app. Failure presents a
localized Retry action; retry uses the same database handle and retained backup.

The backup and journal live beside the history box under
`migrations/prayer-history/`. Startup has exclusive ownership through the shared
readiness barrier. The approved policy applies only to legacy missed rows:

1. `prepare()` flushes the box, writes a versioned exact-key JSON backup, and
   publishes a `prepared` journal only after the backup write succeeds.
2. `apply()` receives the prepared backup identity and verifies its SHA-256
   digest against both the backup and journal before deleting any row.
3. Refuse unrelated edits or missing non-missed rows. Remove only legacy missed
   keys. A partly completed deletion can resume from the same backup.
4. Flush the box, compare every remaining row against the backup, then publish
   the `complete` marker. A failed flush cannot mark completion.
5. Retain the backup and journal. Independent reopening and repeated application
   preserve the remaining records.

The runtime UI no longer creates missed rows. Startup removes legacy missed
rows after retaining the backup. Analytics also exclude them for compatibility
with imported data and standalone fixtures. Period status rates use the count of
recorded jamaah, on-time and late completions. The on-time completion rate uses
jamaah plus on-time records as its numerator. Missing days and legacy missed or
none rows do not enter that denominator. Daily progress and streaks still use
the five obligatory prayers per configured calendar day.

Fixture coverage includes every legacy wire value, digest refusal, exact
non-missed preservation, interruption/restart, idempotence, edits after
preparation, and a failed durable flush followed by retry. These fixtures use
temporary boxes, not the user's saved data. Startup coverage verifies hydration
ordering, blocked reads and writes, backup retention after an independent
restart, and retry after initialization failure. Bootstrap coverage verifies that
history consumers remain unmounted until readiness completes.

No manual migration of the user's saved history was performed during development.
The next normal launch of this implementation will apply the approved startup
policy to that installation, retaining its backup and journal.
