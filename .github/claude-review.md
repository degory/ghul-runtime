# Cloud code review brief

Instructions for the Anthropic Claude Code Action invoked from the `code_review` job in `.github/workflows/cicd.yml`. Not loaded by local Claude Code; only the cloud reviewer reads this.

## How to operate

- The PR branch is checked out in the working directory.
- Get the diff via `gh pr diff <N>`, the body via `gh pr view <N> --json title,body`.
- `GHUL.md` (fetched from `degory/ghul` `main` by the workflow) is the authoritative language reference. Consult it whenever a diff exercises non-obvious language semantics.
- Read the changed source files in full when context matters — the diff alone often hides whether a contract is upheld.
- Post findings only to GitHub. Anything you say in chat is invisible.

## What to post, where

- **Inline comments** for specific code findings: `mcp__github_inline_comment__create_inline_comment` with `confirmed: true`. One finding per comment; don't pile multiple unrelated concerns into one.
- **End every review with one `gh pr review` verdict**, even on a clean PR. Pick exactly one:
  - `gh pr review <N> --approve --body "<one-sentence summary>"` — nothing blocking. Default verdict when you have not raised any inline finding that should hold up the merge.
  - `gh pr review <N> --request-changes --body "<one-paragraph summary of the theme>"` — at least one inline finding is a real defect that should block merge.
  - `gh pr review <N> --comment --body "..."` — non-blocking discussion only; reserve for the rare case where you want to flag something but explicitly don't want to block.
- Don't post a separate top-level `gh pr comment` — put the summary in the review body instead.

## What CI has already proven

You're invoked only after the CI workflow passes (build, unit tests, integration test against a freshly-packed `ghul.runtime`). That means: the runtime compiles, tests pass, and a downstream project consuming the new package builds and produces the expected output. **Don't second-guess validity.** Spend your attention on what the test suite can't catch.

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

## Posting mechanics — reminder

- Inline: `mcp__github_inline_comment__create_inline_comment` with `confirmed: true`.
- Verdict (exactly one, always): `gh pr review <N> --approve|--request-changes|--comment --body "..."`.
- Chat output is invisible. If you didn't post it to GitHub, it didn't happen.
