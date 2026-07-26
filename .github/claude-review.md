# Cloud code review brief

What this repository is, and what to watch for in it. Everything else — what PR
context is available, how to post a review, what makes a finding worth raising,
comment hygiene, PR-description shape, the versioning mechanism — comes from the
review workflow's runtime notes. Don't restate it here: this file is read first,
so a stale copy would silently override the current text.

Not loaded by local Claude Code; only the cloud reviewer reads this.

## What this repo is

`ghul-runtime` ships the `Ghul.Runtime` NuGet package: the runtime library every
ghūl program links against. It contains core types (`OPTION`, union and tuple
support, `Pipe[T]` and the fluent operators on it, MSBuild targets) and is
consumed by `ghul.compiler` itself, by `ghul-test`, and by every end-user ghūl
project.

Blast radius is wide: a published bad runtime version blocks all downstream
builds. `tests/` holds unit-style tests; the `integration-tests/` project at repo
root is a smoke test against a freshly-packed runtime.

## What to watch for here

- **Breaking public API changes** — removed or renamed members, changed
  signatures, narrowed behaviour. Anything a `Ghul.Runtime`-consuming package
  would notice break. Additive changes are fine.
- **Performance regressions on hot paths.** `Pipe[T]` operators
  (`filter`/`map`/`reduce`/`collect`), collection iteration, `OPTION`
  boxing and unwrapping, async primitives. An extra allocation per pipe stage or
  per element matters here in a way it wouldn't elsewhere.
- **Cross-assembly metadata fragility.** Anything touching how unions, tuples or
  generic types serialise into IL and reflection. Known gotchas: tuple element
  names not surviving cross-assembly, named-tuple member resolution failing
  across assemblies, the `IList`/`IReadOnlyList` diamond. Be alert to similar.
- **Missing tests** where a behavioural change wants one.

## Versioning

`Ghul.Runtime` is in v3.x, strict semver throughout — it never had the
compiler's v2.0.0 accident. For this package, major means removed or renamed
public API, a changed signature, or a behaviour change in a documented API;
minor means new public APIs, types or overloads, additive only.
