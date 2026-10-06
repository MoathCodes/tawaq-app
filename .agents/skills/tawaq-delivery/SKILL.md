---
name: tawaq-delivery
description: Deliver a Tawaq task through reproduction, Linux verification, evidence, and PR follow-up. Use for issue-to-PR work, desktop bug reproduction, visual evidence, or babysitting an existing Tawaq PR.
---

# Tawaq delivery

Carry the requested task through its authorized finish. Use AGENTS.md for product contracts and required checks; this skill owns the handoffs between implementation, runtime proof, and review.

## Establish the task

Read the request and owning code. Record expected behavior, reproduction, acceptance criteria, affected consumers, and authorized actions. Inspect the checkout and preserve unrelated work. Use a separate worktree when concurrent edits would overlap.

Keep recovery state outside the worktree in an unused task directory under `${XDG_STATE_HOME:-$HOME/.local/state}/tawaq-delivery/`. Record the issue/thread identifiers, repo, worktree, branch, base/head commits, PR URL, checks, evidence paths, blocker, and next action. Update after pushes and interruptions. The issue and PR remain the shared work record.

Done: the acceptance criteria and target checkout are explicit, and another worker can identify the next action without reconstructing the conversation.

## Reproduce and implement

For a fresh worktree or missing dependency, read [setup.md](references/setup.md). For native Linux UI work, workspace placement, screenshots, or video, read [linux-desktop.md](references/linux-desktop.md) before launching or touching the desktop.

Reproduce a bug before editing and save its diagnostics. If reproduction is unavailable, record the missing condition and qualify later claims. Implement the complete fix and appropriate regression coverage. For subjective UI work, obtain a concrete visual direction or show a scoped preview before expanding the change.

Done: every affected consumer and acceptance criterion has a change or proof of compatibility; a reproduced bug has a regression failing before and passing after the fix where feasible.

## Verify and capture

Run AGENTS.md's required checks, including changed-package checks. Repeat the runtime flow with isolated app data. Wait on observable readiness rather than arbitrary test sleeps.

Capture matching before/after images for visual changes and short video for motion, timing, sound, or multi-step behavior. Record the tested commit, dirty state, locale, theme, viewport, and steps beside the evidence. Qualify synthetic previews by what they actually exercise.

Done: the requested behavior is verified, required checks have outcomes, and all media has been inspected or decoded before being described as proof.

## Submit and babysit

For authorized PR creation or updates, read [pull-requests.md](references/pull-requests.md). Link the issue and evidence, and register every worked-on PR with T3's `link_pull_request` when exposed. Use an independent reviewer when requested or warranted, giving them acceptance criteria, diff, and evidence. One worker owns branch edits.

Follow CI and review state after each push. Preserve recovery state on quota/runtime interruption. Continue within existing authorization rather than requesting the same permission again.

Done: report a verified latest commit ready for merge, confirmed merge/closure, or a concrete blocker. An explicit continuous babysitting request stays on watch until merged/closed, the user stops it, or a blocker needs their input. After an authorized merge, reconcile issues and successor links. Verify thread PR links before finishing.
