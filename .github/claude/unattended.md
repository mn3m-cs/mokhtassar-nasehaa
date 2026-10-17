# Building a ticket from the Claude workflow

You are running in GitHub Actions, with nobody to answer you. The owner reviews what you leave
behind when they return.

Follow `AGENTS.md`. Its "Claiming a ticket" section decides whether you may start at all. Use
`by:claude-cloud` as your name unless the ticket already carries a `by:hermes-claude-*` label,
which means Hermes claimed it for you.

## Proving the change

There is no `fvm` here. The workflow installed the Flutter version `alazkar/.fvmrc` pins, so run
the same checks with plain `flutter` and `dart`, from `alazkar/`:

```bash
flutter pub get
flutter analyze
flutter test
dart format <the files you changed>
```

Paste the output into the pull request. There is no emulator, so a case in "Cases to show" that
needs a «صورة محاكٍ» (and a case with no mark counts as one) cannot be finished here: comment that
on the ticket, swap `ready-for-dev` for `needs-decision`, and stop, rather than open a pull request
without it.

A case marked «صورة اختبار» does not stop you. Draw it with the tests, as `AGENTS.md` ("Proving it")
describes, using `test/support/screen_picture.dart`, commit the pictures in the branch, and mark
them «صورة اختبار» in the pull request. Stop only for the cases that need the emulator.

## Saving as you go

A run can end in the middle of a ticket when the account's limit runs out, and only what you
pushed survives it.

- Push your branch after each completed step, with a commit that still passes the checks above.
- Keep one comment on the ticket that starts with «التقدّم»: what is done and what is left. Update
  it each time you push.
- When you start and find a `claude/issue-<n>-*` branch and a «التقدّم» comment from an earlier
  run, continue from them: check that branch out, read the comment, and do not start over.

## Finishing

- On an issue, open a pull request with `gh pr create --base main`. Its body opens with
  `Closes #<n>` and states what you ran, with the output.
- On a pull request, push to its branch and answer the review there. Never open a second one.
- Swap the labels as `AGENTS.md` says: remove `ready-for-dev` and `in-progress`, add `in-review`,
  keep the `by:` label.
- Never credit Claude or AI anywhere: no "Generated with Claude Code" line, no `Co-Authored-By` trailer, and no mention of an assistant in commit messages, pull request bodies or comments. The owner removes them by hand otherwise.
- Never merge, never push to `main`, never rewrite pushed history.
