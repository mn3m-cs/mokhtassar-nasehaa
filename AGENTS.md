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

## Claiming a ticket

Several builders work at the same time: the owner, a local agent, a Claude workflow run, and
Hermes's lanes. A ticket is claimed before anyone starts on it, so two of them never build the same
thing.

- Do not start a ticket that carries `in-progress`, whoever put it there.
- Do not start a ticket that carries `hermes` unless you are Hermes or the owner asked you to. The
  owner sends work to Hermes with that label, and Hermes takes only tickets that carry both
  `ready-for-dev` and `hermes`.
- Before you start, add `in-progress` and the label that names you: `by:owner`,
  `by:claude-local`, `by:claude-cloud`, `by:hermes-claude-dp`, `by:hermes-claude-mn3m`,
  `by:hermes-codex` or `by:hermes-jules`. Then read the labels again. If another `by:` label is
  there as well, the claim added first in the issue's event history owns the ticket
  (`gh api repos/<owner>/<repo>/issues/<n>/events`), and the later one withdraws by removing its
  own labels.
- When the pull request opens, remove `ready-for-dev` and `in-progress` and add `in-review`. Keep
  the `by:` label, so the owner knows who built it.
- Never remove someone else's claim. A claim that has gone quiet is the owner's to clear.

## Building it

The ticket body is the specification. Its `## Decisions` section holds the owner's rulings, and `## Options considered` explains what was rejected and why. Do not reopen a rejected option.

**When something is not covered, stop and ask in the ticket.** If you reach a choice the Decisions do not settle, and a wrong guess would change what gets built (what the reader sees, what content changes, what is in scope), do not guess:

1. Stop working on that ticket.
2. Comment on the ticket with the question, the options you see, and what each would mean.
3. Remove `ready-for-dev` and add `needs-decision`.
4. Move on to another workable ticket, or stop if there is none.

A small call that any sensible builder would make the same way, such as a variable name, a helper's place, or a test's shape, is yours. List these calls in the PR description, marked as your calls, so the owner can check them.

**Facts you cannot see.** What you cannot verify in a system outside this repository must not ship as a silent failure. Either stop and ask in the ticket (`needs-decision`), or make the code say "unknown" in output that a log or a developer reads, never in content a reader sees, which comes from the book alone. Never skip a check without a trace. A fake in a test, such as a stubbed platform channel or Android notification, is built from a real sample of the object, copied from its source or captured from a run, never from the shape you guessed: a fake of a guessed shape only confirms the guess. Write any guess that remains in the PR description, with the line of code that holds it, so the reviewer checks it against the real source before anything else. This came from mn3m-cs/hermes-skills#279: a ticket named a field from memory, the builder guessed where it lived, its test built a fake of the guessed shape, and the code skipped the check silently when the field was absent (mn3m-cs/hermes-skills#280).

## Proving it

- Run the app's checks: `fvm flutter analyze` and `fvm flutter test`, from `alazkar/`. Format only with `fvm dart format <files>`. The bare `dart` on the PATH is a different SDK, and it restyles unrelated files.
- Never run two Flutter commands in one checkout at the same time.
- For a visible change, the ticket has a `## Cases to show in the PR` list. Capture a before and an after picture for every case, at the real size, commit them in the PR branch, and name each case beside its picture in the PR description. The owner reviews case by case, so a missing picture means an unreviewable PR.
- The ticket says, beside each case, what kind of picture proves it: «صورة محاكٍ» or «صورة اختبار». A case with no mark is «صورة محاكٍ», taken on the emulator as above. A case marked «صورة اختبار» is proved by a picture the tests draw instead, and the owner chooses this only for small visible changes.
- Draw a test picture with `test/support/screen_picture.dart`: call `loadAppFonts()` once in `setUpAll`, then `drawScreenPicture(tester, screen: ..., path: ...)` with the same `MaterialApp` theme the app uses (`fontFamily: 'Cairo'`). It loads the app's real fonts and the icon font, so the picture shows Arabic letters and icons and not boxes. `test/settings_screen_picture_test.dart` is the worked example. Take the before picture from `main` and the after picture from the branch, commit both, and mark each one «صورة اختبار» in the PR description.

## Finishing

Open a PR from a branch cut from the current `main` that says `Closes #<n>`. A ticket that came back from review already has its PR: continue on that PR's branch, merging `main` into it first, and do not open a second PR. The ticket's body then carries a dated amendment, and the amendment's Decisions, cases and acceptance items are what you build to. Swap the ticket's label from `ready-for-dev` to `in-review`. **Never merge**: merging is the owner's step after review. Never rewrite pushed history; to update a branch, merge `main` into it.

## Content rules

The app must match the book «مختصر النصيحة في الأذكار والأدعية الصحيحة» exactly. Every word a reader sees as content comes from the book verbatim. Nothing is paraphrased, summarised or added in an agent's own words. When the app and the book differ, the book wins. Content not in the book is deleted, not labelled. Detailed content procedure is in `CONTENT_AUDIT_AGENT_PLAN.md`; its section «مطابقة صفحة صفحة» (§9) is the page-by-page method. `docs/book-map.md` records which book chapters were compared with their pages. Never call the app «مطابق للكتاب» except for rows whose status is «قورن».
