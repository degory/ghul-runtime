# AI Agent Guide for the ghūl runtime library

## Purpose

This guide is for AI agents and other automated contributors working on the ghūl runtime library in this repository.

## Background

- This package provides the internal types every [ghūl](https://ghul.dev/) application needs, the pipe operator and fluent pipe methods (`filter`, `map`, `reduce`, …), and the MSBuild targets that build ghūl projects.
- The ghūl compiler and test tool are provided as .NET local tools. Run `dotnet tool restore` if needed.
- See [GHUL.md](./GHUL.md) for a quick language tutorial and reference. This file is a synced copy — see "Keeping GHUL.md in sync" below.

## Keeping GHUL.md in sync

`GHUL.md` is **not authored here.** The master copy lives in the [`ghul`](https://github.com/degory/ghul) compiler repo (`ghul/GHUL.md`), which is updated whenever the language changes. The copy in this repo exists so the runtime is self-contained.

When you open a PR that touches this repo, check whether the master `GHUL.md` has moved ahead of the copy here, and if so refresh it as part of your PR:

```sh
diff path/to/ghul/GHUL.md GHUL.md   # any output => out of date
cp  path/to/ghul/GHUL.md GHUL.md    # refresh, then commit
```

Only sync when it's genuinely out of date and you're already touching this repo — don't open a PR solely to sync (the compiler repo's own PRs keep the master current). Never hand-edit `GHUL.md` here to fix a language-reference error; fix it in the `ghul` repo's master copy and let the sync carry it over.

## Additional Notes

- Keep commits focused and well documented.
- See [README.md](./README.md) for an overview of what this package provides.
