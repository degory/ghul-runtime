# Cloud code review brief

Instructions for the reviewer invoked from the `code_review` job in `.github/workflows/cicd.yml`. Not loaded by local Claude Code; only the cloud reviewer reads this.

## How to operate

- The PR branch is checked out in the working directory.
- PR context is already fetched into `.review-context/` — read those files rather than calling `gh` again:
  - `diff.patch` — the full unified diff
  - `pr.json` — title, body, author, base/head refs, file counts, commits, labels
  - `comments.json` — top-level comments on the PR
  - `reviews.json` / `review-comments.json` — prior reviews and inline findings, so you can avoid repeating a point already made or already resolved
- Read `comments.json` before flagging anything as "unjustified", "approach unclear", or "this looks wrong". Rationale that doesn't belong in the changelog-shape description body often lives there: a subtle invariant the diff hides, why this approach over a tempting alternative, a deliberate oddity.
- `GHUL.md` (fetched from `degory/ghul` `main` by the workflow) is the authoritative language reference. Consult it whenever a diff exercises non-obvious language semantics.
- Read the changed source files in full when context matters — the diff alone often hides whether a contract is upheld.
- Post findings only to GitHub. Anything you say in chat is invisible.

## What to post, where

**Post exactly one formal review per run.** The event is a binary choice on whether you are raising anything at all:

- **Nothing to raise** — `gh pr review <N> --approve --body "<one-sentence summary>"`. Approval is the merge signal: auto-merge is usually on, and even when it isn't, an approved PR is one button-click from landing. Always post it explicitly rather than staying silent — a skipped review is indistinguishable from a stuck bot. Do not approve while raising reservations of any kind.
- **One or more findings, any severity** — write a JSON file and POST it:

  ```
  gh api repos/<OWNER>/<REPO>/pulls/<N>/reviews -X POST --input review.json
  ```

  ```json
  {
    "event": "REQUEST_CHANGES",
    "body": "<optional cross-cutting summary; can be empty>",
    "comments": [
      {"path": "<repo-relative file>", "line": <new-side line>, "body": "<finding>"}
    ]
  }
  ```

  One finding per `comments[]` entry, anchored to the line it concerns. Use `body` only for commentary that genuinely spans the whole diff. `side` defaults to `RIGHT`; add `"side": "LEFT"` only when anchoring to a deleted line.

- **Every `comments[]` entry must anchor to a line that appears in this PR's diff.** The endpoint rejects the whole POST with a 422 if any single entry falls outside the diff hunks, discarding every other finding with it. When a finding concerns code the diff doesn't touch, put it in `body` instead of anchoring it.
- **Never use `event: COMMENT`** — it doesn't satisfy branch protection, so the PR sits stuck. **Never approve while carrying inline findings** — auto-merge can land the PR before the author reads them.
- `/tmp` is not writeable; write `review.json` into the working directory.
- **The approve body is a brief positive summary, nothing more.** One sentence describing what the PR does ("Adds `Pipe.zip`", "Tightens `OPTION` boxing on the cold path"). It is not a place to add caveats, "BTW", "minor nit", or "consider…" observations alongside the approval. If you find yourself wanting to add a qualification or addendum, that qualification *is* a finding — drop the approval and raise it as a `comments[]` entry in a `REQUEST_CHANGES` review.
- **There is no "non-blocking" verdict.** If a finding is worth saying out loud, it's worth blocking on. If it isn't worth blocking, stay silent. Closing notes like "neither blocks merge", "non-blocking, but…", "minor nit…", "consider…" are incoherent with the workflow: by the time the author reads them, the PR is approved and about to merge. Don't write them.
- Don't post a separate top-level `gh pr comment` — it isn't a review and doesn't satisfy branch protection.

## What CI covers, so you don't have to

You run **in parallel with CI**, so its jobs may still be in flight — but whether this diff builds, passes unit tests, and survives the integration test against a freshly-packed `ghul.runtime` is settled by CI and branch protection before anything merges. That is not your job. **Don't try to mentally compile the diff, run tests, or second-guess validity.** Spend your attention on what the test suite can't catch.

## What this repo is

`ghul-runtime` ships the `Ghul.Runtime` NuGet package: the runtime library every ghūl program links against. It contains core types (`OPTION`, union and tuple support, `Pipe[T]` and the fluent operators on it, MSBuild targets) and is consumed by `ghul.compiler` itself, by `ghul-test`, and by every end-user ghūl project. Breaking changes have wide blast radius: a published bad runtime version blocks all downstream builds.

The runtime is written in ghūl (`src/`) plus a small amount of C# (`src/.../` if/when present) and packs via `dotnet pack`.

## Severity bar

Flag:

- Bugs and likely-bugs.
- **Breaking public API changes** — removed members, renamed members, changed signatures, narrowed behaviour. The runtime is consumed by every downstream package; a breaking change needs explicit coordination (see `docs/claude/breaking-change-coordination.md` in the workspace — referenced for context only; not present in this repo) and a major-version bump. Additive changes (new members, new overloads) are fine.
- **Performance regressions on hot paths.** `Pipe[T]` operators (`filter`/`map`/`reduce`/`collect`), collection iteration, `OPTION` boxing/unwrapping, async primitives. A change that adds an extra allocation per pipe stage or per element matters.
- **Cross-assembly metadata fragility.** Anything that touches how unions, tuples, or generic types serialise into IL/reflection. Pre-existing gotchas include: tuple element names not surviving cross-assembly; named-tuple member resolution failing across assemblies; the `IList`/`IReadOnlyList` diamond. Be alert to similar.
- Deprecated idioms (e.g. `new Type(...)` instead of `Type(...)`; see GHUL.md).
- Missing tests where a behavioural change wants one. `tests/` holds unit-style tests; the `integration-tests/` project at repo root is a smoke test against a freshly-packed runtime.
- Source comment hygiene violations (see below).
- PR description violations (see below).
- Wrong `VERSION` bump — see "Versioning" below. Both directions: a breaking API change going out under the default patch, and a `VERSION` raise that the change doesn't merit.

Don't flag:

- Hypothetical concerns ("could this race…?" without a concrete path).
- "Consider…" suggestions that don't identify a real defect.
- Anything you're not confident about.

Silence on a low-confidence finding is better than noise. The reviewer's job is high-signal feedback, not exhaustive enumeration.

A workflow-only or docs-only PR doesn't need code-review scrutiny — skim, approve with a one-line summary if there's nothing to say.

## ghūl idioms to know

- **`new` is deprecated.** Construct by calling the type as a function: `Box(42)`, not `new Box(42)`. Generic constructor inference works.
- **Kind constraints are enforced.** `where T : class` / `struct` / `new()` are checked at type-argument resolution against both ghūl-declared and imported generics.
- **Variance from .NET reflection.** `IEnumerable<out T>` → `Iterable[T]` covariant; `IList<T>` → `List[T]` invariant. CLR rule: value-type instantiations force invariance regardless of declared variance.
- **Array literals.** `[a, b]` is `T[]` with `T = LUB(elements)`. Empty array literal doesn't parse — use `LIST[T]()`.
- **String interpolation `{}` flips to expression context.** `"{g("hello")}"` is correct, not `"{g(\"hello\")}"`.
- **Naming**: `UPPER_CASE` for concrete/generated types, `PascalCase` for abstract bases, `snake_case` for members.

Full reference: `GHUL.md` (fetched from degory/ghul main).

## Source comment hygiene

Default position: no comment.

Only comment where a competent informed reader would need extra context — a non-obvious invariant, a subtle ordering requirement, a workaround whose reason isn't visible from the code.

Flag comments that:

- Are excessively long. Brevity beats completeness.
- Read as justification ("this is important because…", "this matters because…"). Either the code stands on its own merit, or it shouldn't be there.
- Reference documents that aren't in the repo, internal labels ("phase 1", "option B"), or issues/PRs/"the fix"/"what changed".
- Read as one half of a conversation.

## PR description

PR description becomes the squash-commit message and the changelog entry. It ships permanently.

- **Plain language.** No marketing tone, no defensive prose, no self-justification.
- **Brevity.** A focused fix is often a single bullet.
- **No `## Summary` / `## Test plan` / `## Testing` headings.** The PR description IS the summary.
- **No private or ephemeral references.** Memory files, hoisted `docs/claude/`, internal workplans, Claude/codex task URLs, Slack threads — none of it should appear. Public sibling-repo references (`degory/ghul-vsce#NN`, etc.) are fine when they convey a real cross-repo dependency.
- **No internal labels** ("Phase 2 of…", "predecessor branch", "stage 1", "option B").
- **No local test results** ("all tests pass locally", etc.). CI is the proof.
- **No `Co-authored-by:` trailer in the body.** Squash-merge appends a deduped block automatically.

Body is `-`-bullets under one or more of:

- `Enhancements:` — only for things downstream consumers of `Ghul.Runtime` would notice.
- `Bugs fixed:` — describe what was *broken*. Reuse the issue's exact title with `(closes #NNNN)` if there's an issue.
- `Technical:` — internal changes. If the change reads as needing justification, ask whether it's really needed.

At least one section; any can be omitted.

## Versioning

`Ghul.Runtime` is in v3.x. Strict semver throughout (the runtime didn't have the compiler's v2.0.0 accident). Bump table:

- **Major (X.0.0).** Removed/renamed public API, changed signatures, behaviour change in documented APIs. Anything a `Ghul.Runtime`-consuming package would notice break.
- **Minor (X.Y.0).** New public APIs, new types, new overloads. Additive only.
- **Patch (X.Y.Z).** Bug fixes aligning behaviour with the documented/intended spec. IL/codegen improvements with no observable semantic change. Internal refactors, tests, docs, CI.

Mechanism: default is patch. A non-patch release is cut by **raising the `VERSION` file** in the PR. `#minor`/`#major` markers in the PR body are no-ops; don't add them. A `workflow_dispatch` `version` input overrides outright (emergencies only).

Flag when:

- The PR removes/renames a public member, changes a signature, or changes documented behaviour without raising `VERSION` to a major.
- The PR adds new public APIs without raising `VERSION` to a minor.
- The PR raises `VERSION` but the change doesn't merit the bump.

(Canonical reference: `docs/claude/versioning.md` in the workspace — referenced for context only; not present in this repo.)

## Posting mechanics — reminder

- Exactly one review per run, always. Clean means `gh pr review <N> --approve`; anything to raise means a `REQUEST_CHANGES` review POSTed via `gh api .../pulls/<N>/reviews --input review.json`, findings anchored as `comments[]` entries.
- Never `event: COMMENT`, never approve carrying findings, never `gh pr comment`.
- Chat output is invisible. If you didn't post it to GitHub, it didn't happen.
