# terraform-panel — Sprint 1 Makefile
#
# Usage:
#   make gen-fixture     — Generate the 50k synthetic .tfstate JSON
#   make go-test         — Run PRT-01 Go unit tests
#   make go-build-so     — Build the Go c-shared library (libbridge.so + bridge.h)
#   make zig-test        — Run PRT-01 Zig integration test (needs libbridge.so)
#   make zig-bench       — Run PRT-02 SoA vs AoS benchmark
#   make all             — Run the full Sprint 1 test suite in order
#   make perf-bench      — Run bench under `perf stat` to check L1 cache misses

BRIDGE_DIR  := go-bridge
ENGINE_DIR  := zig-engine
TESTDATA    := zig-engine/testdata
FIXTURE     := $(TESTDATA)/fixture.tfstate.json

.PHONY: all gen-fixture go-test go-build-so zig-test zig-bench perf-bench

all: gen-fixture go-test go-build-so zig-test zig-bench

# ── 1. Generate the 50k-node synthetic fixture ────────────────────────────────
gen-fixture:
	@mkdir -p $(TESTDATA)
	@echo "→ Generating $(FIXTURE) with 50,000 nodes..."
	go run $(BRIDGE_DIR)/cmd/gen-tfstate/main.go --count=50000 --seed=42 > $(FIXTURE)
	@echo "   Done. Size: $$(du -h $(FIXTURE) | cut -f1)"

# ── 2. Go unit tests (PRT-01) ─────────────────────────────────────────────────
go-test:
	@echo "→ Running Go PRT-01 unit tests..."
	cd $(BRIDGE_DIR) && go test ./... -v -count=1 -run "TestParseTFState|BenchmarkParseTFState"
	@echo "   PRT-01 Go tests complete."

# ── 2b. Run Go benchmarks ─────────────────────────────────────────────────────
go-bench:
	cd $(BRIDGE_DIR) && go test ./... -bench=BenchmarkParseTFState -benchmem -run='^$$' -count=5

# ── 3. Build Go c-shared library ─────────────────────────────────────────────
go-build-so:
	@echo "→ Compiling libbridge.so..."
	cd $(BRIDGE_DIR) && go build -buildmode=c-shared -o libbridge.so .
	@echo "   Produced: $(BRIDGE_DIR)/libbridge.so and $(BRIDGE_DIR)/bridge.h"

# ── 4. Zig integration test (PRT-01) ──────────────────────────────────────────
zig-test: go-build-so gen-fixture
	@echo "→ Running Zig PRT-01 integration test..."
	cd $(ENGINE_DIR) && zig build test -Dbridge-path=../go-bridge
	@echo "   PRT-01 Zig integration test complete."

# ── 5. SoA vs AoS benchmark (PRT-02) ─────────────────────────────────────────
zig-bench:
	@echo "→ Running Zig PRT-02 SoA vs AoS benchmark..."
	cd $(ENGINE_DIR) && zig build bench
	@echo "   PRT-02 benchmark complete."

# ── 6. perf stat around benchmark (optional, needs linux perf tools) ──────────
perf-bench: go-build-so
	@echo "→ Building bench binary..."
	cd $(ENGINE_DIR) && zig build -Doptimize=ReleaseFast
	@echo "→ Running under perf stat (L1 cache misses)..."
	perf stat \
		-e L1-dcache-loads,L1-dcache-load-misses,cache-misses,cache-references \
		$(ENGINE_DIR)/zig-out/bin/soa_bench
