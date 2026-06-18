---
name: create-release
description: Cut a new release of the Implicits library — draft categorized release notes from changes since the last tag, create a draft GitHub release, and trigger the Release workflow that tests, tags, and publishes. Use when asked to release implicits, cut/create a release, or via /create-release <version>.
---

# Create a Release

Creates a release of Implicits. You draft the notes and the draft GitHub
release; the [`Release` workflow](../../../.github/workflows/release.yml) runs the
test gate, creates the tag, and publishes. Repo is `yandex/implicits`.

The version comes from the invocation argument (e.g. `/create-release 1.3.0`). If
none was given, ask for it.

## Preconditions — verify first, abort if any fail

Run and check:

- `git status` — working tree must be clean (no uncommitted changes).
- `git branch --show-current` and `git rev-parse @{u}` — branch must be up to
  date with its upstream remote, and `HEAD` must exist on the remote.

If any condition is not met, stop and tell the user what's wrong. **Do not** try
to commit, push, or otherwise "fix" the tree yourself.

## Process

1. **Validate the version** is SemVer `x.y.z` (no `v` prefix). Reject anything
   else.

2. **Study recent releases for style.** Run `gh release view <last-tag> --repo
   yandex/implicits` on the latest one or two (find them with `git tag
   --sort=-creatordate | head`). Match their conventions:
   - Plain `###` category headers, **no emoji**. Headers vary by what shipped —
     e.g. `New Features`, `Bug Fixes`, `Static Analysis`, `Improvements`,
     `Documentation`, `Tooling`.
   - Every entry ends with its PR ref `(#NN)`.
   - Headline features get a **bold name** + an em-dash description.
   - Add a `Thanks to @… for their contributions!` line when there were external
     contributors.

3. **Analyze changes since the previous release.** Find the previous tag, then
   review `git log <prev>..HEAD` and the merged PRs in that range to assemble the
   entries. Group them under the category headers above.

4. **Write the notes** to a temporary `RELEASE_<version>.md` (use
   `.claude.local.temp/` so it isn't committed).

5. **Confirm with the user.** Show the drafted notes. If they don't confirm,
   delete the temp file and stop.

6. **Determine the target branch.** Default `main`. Ask if releasing from another
   branch (e.g. a hotfix branch).

7. **Create the draft release** (title is the bare version):
   ```bash
   gh release create <version> --draft --target <branch> \
     --title "<version>" --notes-file .claude.local.temp/RELEASE_<version>.md \
     --repo yandex/implicits
   ```

8. **Ask** whether to run the release workflow now.

9. **Run the workflow** (if confirmed):
   ```bash
   gh workflow run release.yml --repo yandex/implicits
   ```
   It validates the draft, runs the full CI gate on the target commit, creates
   and pushes the tag, and publishes the release. Monitor at
   https://github.com/yandex/implicits/actions/workflows/release.yml

10. **Clean up** the temporary `RELEASE_<version>.md`.

**Do NOT** manually create the tag or flip the draft to published — the workflow
handles tagging and publishing. Your job ends at creating the draft and (if
confirmed) dispatching the workflow.
