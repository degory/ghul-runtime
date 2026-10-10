# Native AOT test project

This project renders a range of values with `$` and checks that a Native AOT
build of it prints the same as a JIT build, and that both print
`run.expected`. Native AOT keeps reflection metadata only for what it can see
being reflected over, so the rendering takes a path of its own there.

A map is left out: compiled ahead of time, its entries render by their own
`to_string()`, as `[key, value]`, rather than as `(key, value)`.

It needs a platform linker (`clang`) and the package built into `../nupkg`:

```sh
dotnet pack -p:Version=<version> && dotnet setversion <version> Directory.Build.props
cd native-aot-tests
dotnet run > jit.txt && diff jit.txt run.expected
dotnet publish -r linux-x64 -o out && out/native-aot-tests | diff - run.expected
```
