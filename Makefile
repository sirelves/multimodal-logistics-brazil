# Everything is pure Bend 2 (https://github.com/bendlang/bend), tested with 2.0.25.
BEND ?= bend
# `make bench` compiles a native binary and needs clang >= 14 first on PATH.
# On macOS, if another clang shadows Apple's: make bench CLANG_DIR=/Library/Developer/CommandLineTools/usr/bin
CLANG_DIR ?=

.PHONY: all test figures bench clean

all: test figures

test:
	$(BEND) tests/tests.bend

figures:
	$(BEND) simulations/validation.bend
	$(BEND) simulations/fronts.bend
	$(BEND) simulations/seasonal.bend
	$(BEND) simulations/capacity.bend
	$(BEND) simulations/disruption.bend

bench:
	BEND="$(BEND)" CLANG_DIR="$(CLANG_DIR)" sh scripts/bench.sh

clean:
	rm -rf build results/*.svg results/*.csv
