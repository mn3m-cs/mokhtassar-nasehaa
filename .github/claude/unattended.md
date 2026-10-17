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

Paste the output into the pull request. There is no emulator, so a ticket whose "Cases to show"
needs pictures of the app cannot be finished here: comment that on the ticket, swap
`ready-for-dev` for `needs-decision`, and stop, rather than open a pull request without them.

## Finishing

- On an issue, open a pull request with `gh pr create --base main`. Its body opens with
  `Closes #<n>` and states what you ran, with the output.
- On a pull request, push to its branch and answer the review there. Never open a second one.
- Swap the labels as `AGENTS.md` says: remove `ready-for-dev` and `in-progress`, add `in-review`,
  keep the `by:` label.
- Never merge, never push to `main`, never rewrite pushed history.
