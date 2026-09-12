Tawaq code-health remediation — design interview

Status: draft. The interview is in progress; this is not an implementation authorization or an executable final plan.

Evidence: [audit and reproductions](../audits/code-health-2026-09-09/audit.md).

User constraints already established:

- Address all eight audit findings.
- Repair the owning design when it is unsound; avoid another workaround that leaves conflicting rules or owners.
- Prefer simpler systems and lower maintenance cost. Neither minimum diff size nor minimum class count is the objective.
- Execute the eventual plan with parallel Luna agents. Task boundaries, shared files, prerequisites, and final integration must be explicit.
- Reach shared understanding through the grill-with-docs interview before implementation.
- Preserve existing unrelated changes, religious source content, and compatible persisted data.

Working vocabulary for this plan (implementation terms, not additions to the product glossary):

- Owner: the component authorized to change a fact or enforce a behavior.
- Projection: a derived view whose dependency tracking must keep it consistent with its owner.
- Draft: temporary uncommitted user input, distinct from the saved value.
- Forwarding layer: a helper that passes arguments to another API without owning a meaningful rule, transformation, or lifecycle.
- Foundational repair: a change that removes the source of contradictory behavior and updates every affected consumer.

Decision tree, round 1:

1. Scope of additional structural investigation beyond the eight findings: whether the large recitation components enter this plan as an evidence-gathering gate, or remain a separate follow-up.
2. About link interaction: open the real destination, or retain an explicit copy-link interaction.

Independent evidence gathering:

- Prayer projections: required time precision, actual dependency paths, settings changes, affected consumers, and candidate ownership designs.
- Accessibility: component-native semantics, cases requiring custom semantics, removable forwarding layers, and shared-file boundaries.

Later decisions must be grounded in those results. No repair design, ADR, implementation task assignment, or acceptance criteria are final yet.

The final plan must include the agreed behavior, chosen owners and removed structures, negative scope, prerequisite work, exclusive file ownership per Luna task, tests and runtime verification, generation ownership, integration order, and a rule for escalating discoveries that invalidate a task's agreed design.
