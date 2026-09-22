#!/bin/sh
# Parallel speed-up of the Monte Carlo scenario tree (2^18 trips), native build.
# Writes results/benchmark.csv: threads, seconds, speed-up vs 1 thread.
set -e
BEND=${BEND:-bend}
if [ -n "$CLANG_DIR" ]; then PATH="$CLANG_DIR:$PATH"; fi
if [ "$(uname)" = Darwin ] && [ -z "$SDKROOT" ]; then SDKROOT=$(xcrun --sdk macosx --show-sdk-path); export SDKROOT; fi
mkdir -p build
$BEND simulations/bench.bend -o build/bench
echo "threads,seconds,speedup" > results/benchmark.csv
base=""
for t in 1 2 4 8; do
  best=""
  for rep in 1 2 3; do
    s=$( { /usr/bin/time -p build/bench --threads $t > build/bench.out; } 2>&1 | awk '/^real/ {print $2}' | tr ',' '.')
    if [ -z "$best" ] || [ "$(echo "$s < $best" | bc)" = 1 ]; then best=$s; fi
  done
  [ -z "$base" ] && base=$best
  echo "$t,$best,$(echo "scale=2; $base / $best" | bc)" >> results/benchmark.csv
  cat build/bench.out
done
cat results/benchmark.csv
