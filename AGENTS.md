# AI Agent Guide for the ghūl runtime library

## Purpose

This guide is for AI agents and other automated contributors working on the ghūl runtime library in this repository.

## Background

- This package provides the internal types every [ghūl](https://ghul.dev/) application needs, the pipe operator and fluent pipe methods (`filter`, `map`, `reduce`, …), and the MSBuild targets that build ghūl projects.
- The ghūl compiler and test tool are provided as .NET local tools. Run `dotnet tool restore` if needed.
- For a quick language tutorial and reference, see [`GHUL.md`](https://github.com/degory/ghul/blob/main/GHUL.md) in the `ghul` compiler repo, which owns it — this repo does not vendor a copy. The compiler repo updates it whenever the language changes; the link above always resolves to the current one on `main`, so it never goes stale here.

## Additional Notes

- Keep commits focused and well documented.
- See [README.md](./README.md) for an overview of what this package provides.
