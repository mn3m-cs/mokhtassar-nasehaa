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

## Saving as you go

A run can end in the middle of a ticket when the account's limit runs out, and only what you
pushed survives it.

- Push your branch after each completed step, with a commit that still passes the checks above.
- Keep one comment on the ticket that starts with «التقدّم»: what is done and what is left. Update
  it each time you push.
- When you start and find a `claude/issue-<n>-*` branch and a «التقدّم» comment from an earlier
  run, continue from them: check that branch out, read the comment, and do not start over.

## Book audit tickets

A ticket titled «مطابقة الكتاب» compares the app with the pages of the book, the 10th revised
edition (#116). The workflow downloaded it from the author's site and drew each page as
`book-pages/pages/p-NNN.png`, where NNN is the book's page number.

- Read each page as an image with the Read tool. There is no text layer to trust, so never work
  from extracted text.
- The book is copyrighted and this repository is public. Never commit, attach or paste a page
  image or any part of one: not in the branch, the pull request, or a comment. Quoting the
  book's words in the comparison table is fine, because they are the app's content.
- If `book-pages/pages/` is missing, the download failed or the site changed the file. Comment
  that on the ticket, swap `ready-for-dev` for `needs-decision`, and stop.
- Change the database only through `sqlite3 alazkar/assets/db/Al-Azkar.db` and the scripts in
  `data_pipeline/`, following sections 3 to 6 of `CONTENT_AUDIT_AGENT_PLAN.md`, and run its
  checks (`jq empty`, `PRAGMA integrity_check`, `PRAGMA foreign_key_check`, `PRAGMA user_version`).
  Its "do not commit" line is for a local helper; here you commit and push as above.
- The evidence is the comparison table the ticket asks for, not pictures of the app, so the
  missing emulator does not stop these tickets unless their "Cases to show" asks for app pictures.

## Finishing

- On an issue, open a pull request with `gh pr create --base main`. Its body opens with
  `Closes #<n>` and states what you ran, with the output.
- On a pull request, push to its branch and answer the review there. Never open a second one.
- Swap the labels as `AGENTS.md` says: remove `ready-for-dev` and `in-progress`, add `in-review`,
  keep the `by:` label.
- Never credit Claude or AI anywhere: no "Generated with Claude Code" line, no `Co-Authored-By` trailer, and no mention of an assistant in commit messages, pull request bodies or comments. The owner removes them by hand otherwise.
- Never merge, never push to `main`, never rewrite pushed history.
