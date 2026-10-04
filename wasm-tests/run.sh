#!/usr/bin/env bash
# Builds each program under wasm-tests/ for the wasm target, compiling the
# runtime from this checkout's sources, runs it under Node and compares what
# it prints with the run.expected beside it. Needs `ghul` (ghul.cli) and
# Node.js 22 or newer on the path.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ghul="${GHUL:-ghul}"
failed=0

for test in "$root"/*/; do
    name="$(basename "$test")"

    if ! (cd "$test" && "$ghul" build) > "$test/build.log" 2>&1; then
        echo "FAIL $name: the build failed" >&2
        cat "$test/build.log" >&2
        failed=1
        continue
    fi

    if ! node "$test/out/wasm/$name.mjs" > "$test/run.out" 2>&1; then
        echo "FAIL $name: the program exited with an error" >&2
        cat "$test/run.out" >&2
        failed=1
        continue
    fi

    if ! diff -u "$test/run.expected" "$test/run.out" >&2; then
        echo "FAIL $name: the output differs from run.expected" >&2
        failed=1
        continue
    fi

    echo "pass $name" >&2
done

exit $failed
