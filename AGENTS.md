# Working on this repository

These instructions are for every coding agent: Claude, Codex, OpenCode, Jules, and cloud sessions. The owner plans and reviews, and agents build while the owner is away. Nobody can answer you while you work, so these rules exist to make sure you never have to guess.

## Which ticket you may work on

Tickets are GitHub issues on `mn3m-cs/mokhtassar-nasehaa`. Labels show where each one stands:

| Label | Meaning |
|---|---|
| none | Opened but not yet discussed with the owner. Do not work on it. |
| `ready-for-dev` | The owner has approved the text and its decisions. You may work on it. |
| `needs-decision` | Work stopped on a question for the owner. Do not work on it. |
| `in-review` | A PR is open and waits for the owner. Do not work on it. |

A ticket is workable only when all of these are true:

- It has `ready-for-dev`.
- Every ticket it is blocked by is closed as completed, which means merged and not just in an open PR. Read both the `## Depends on` section and `gh api repos/mn3m-cs/mokhtassar-nasehaa/issues/<n>/dependencies/blocked_by`. Building on unmerged work forces a redo when that work changes in review.
- Every blocker was itself ready. If a ready ticket depends on one that is not ready, it waits. Never pull an unready ticket in to unblock it.
- It touches no file that an open PR touches. For content, any other open PR that changes `Al-Azkar.db` counts, because two DB changes always collide on IDs and dbVersion.

If no ticket qualifies, say so and stop. Work on one ticket at a time.

## Building it

The ticket body is the specification. Its `## Decisions` section holds the owner's rulings, and `## Options considered` explains what was rejected and why. Do not reopen a rejected option.

**When something is not covered, stop and ask in the ticket.** If you reach a choice the Decisions do not settle, and a wrong guess would change what gets built (what the reader sees, what content changes, what is in scope), do not guess:

1. Stop working on that ticket.
2. Comment on the ticket with the question, the options you see, and what each would mean.
3. Remove `ready-for-dev` and add `needs-decision`.
4. Move on to another workable ticket, or stop if there is none.

A small call that any sensible builder would make the same way, such as a variable name, a helper's place, or a test's shape, is yours. List these calls in the PR description, marked as your calls, so the owner can check them.

## Proving it

- Run the app's checks: `fvm flutter analyze` and `fvm flutter test`, from `alazkar/`. Format only with `fvm dart format <files>`. The bare `dart` on the PATH is a different SDK, and it restyles unrelated files.
- Never run two Flutter commands in one checkout at the same time.
- For a visible change, the ticket has a `## Cases to show in the PR` list. Capture a before and an after picture for every case, at the real size, commit them in the PR branch, and name each case beside its picture in the PR description. The owner reviews case by case, so a missing picture means an unreviewable PR.

## Finishing

Open a PR from a branch cut from the current `main` that says `Closes #<n>`. Swap the ticket's label from `ready-for-dev` to `in-review`. **Never merge**: merging is the owner's step after review. Never rewrite pushed history; to update a branch, merge `main` into it.

## Content rules

The app must match the book «مختصر النصيحة في الأذكار والأدعية الصحيحة» exactly. Every word a reader sees as content comes from the book verbatim. Nothing is paraphrased, summarised or added in an agent's own words. When the app and the book differ, the book wins. Content not in the book is deleted, not labelled. Detailed content procedure is in `CONTENT_AUDIT_AGENT_PLAN.md`.
