# ghūl compiler runtime library

[![CI/CD](https://img.shields.io/github/actions/workflow/status/degory/ghul-runtime/cicd.yml?branch=main)](https://github.com/degory/ghul-runtime/actions/workflows/cicd.yml?query=branch%3Amain)
[![NuGet version (ghul.runtime)](https://img.shields.io/nuget/v/ghul.runtime.svg)](https://www.nuget.org/packages/ghul.runtime/)
[![Release](https://img.shields.io/github/v/release/degory/ghul-runtime?label=release)](https://github.com/degory/ghul-runtime/releases)
[![Release Date](https://img.shields.io/github/release-date/degory/ghul-runtime)](https://github.com/degory/ghul-runtime/releases) 
[![Issues](https://img.shields.io/github/issues-search/degory/ghul?query=is%3Aopen%20is%3Aissue%20label%3Aghul-runtime&label=issues)](https://github.com/degory/ghul/issues?q=is%3Aopen+is%3Aissue+label%3Aghul-runtime) 
[![License](https://img.shields.io/github/license/degory/ghul-runtime)](https://github.com/degory/ghul-runtime/blob/main/LICENSE)
[![ghūl](https://img.shields.io/badge/gh%C5%ABl-100%25!-information)](https://ghul.dev)

This package provides: 
- internal types required by all [ghūl](https://ghul.dev) applications
- support for the ghūl pipe operator and fluent methods on pipes, such as `filter`, `map` and `reduce`
- `view`, which windows part of an array, list or string without copying it: `xs |> view(1..4)`
- MSBuild targets needed to build ghūl projects

## Building a library or an executable

The targets follow the standard `OutputType` property:

- `Library` (the .NET SDK's default when the project does not set one) builds a
  library. It needs no `entry()` function.
- `Exe` or `WinExe` builds an executable, which needs an `entry()` function.

Other values are rejected. To choose directly, regardless of `OutputType`, set
`GhulLibrary` to `true` or `false`.

```xml
<PropertyGroup>
  <OutputType>Library</OutputType>
</PropertyGroup>
```



## Issues

[View open issues](https://github.com/degory/ghul/issues?q=is%3Aopen+is%3Aissue+label%3Aghul-runtime) or [raise a new one](https://github.com/degory/ghul/issues/new?labels=ghul-runtime).
