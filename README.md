# sky-dozer-for-terraform

> **High-performance Zoomable UI for Terraform infrastructure graphs — 50,000+ resources at 60 FPS.**

[![Sprint](https://img.shields.io/badge/sprint-1%20%E2%80%94%20foundation-blue)](docs/journal/sprint-1.md)
[![Go](https://img.shields.io/badge/go-1.25%2B-00ADD8?logo=go)](go-bridge/)
[![Zig](https://img.shields.io/badge/zig-0.15%2B-F7A41D?logo=zig)](zig-engine/)
[![License](https://img.shields.io/badge/license-TBD-lightgrey)](#license)

---

## The Problem

Existing Terraform visualization tools fail at enterprise scale:

| Tool | Limit | Problem |
|---|---|---|
| **Rover** | ~200 resources | Browser locks up generating SVG/DOM |
| **Pluralith** | Unlimited | Static PDF only — no interactivity |
| **terraform graph** | Unlimited | Raw DOT output, no spatial layout |

sky-dozer is building a **Zoomable User Interface (ZUI)** — think Google Maps for your cloud infrastructure — that handles 50,000+ resources with smooth pan/zoom at 60 FPS.

---

## Architecture

The engine is built on four performance hypotheses, each validated by a PoC gate:

```
┌─────────────────────┐         C ABI / FFI         ┌──────────────────────┐
│   go-bridge (.so)   │◄────────────────────────────►│   zig-engine         │
│                     │                              │                      │
│  ParseTFState()     │  Zig pre-allocates buffer    │  ArenaAllocator      │
│  HCL/TFState parser │  Go writes flat records      │  MultiArrayList SoA  │
│  (encoding/json)    │  No Go heap ptrs cross back  │  R-Tree (Sprint 2)   │
└─────────────────────┘                              │  Raylib/Mach (Spr 3) │
                                                     └──────────────────────┘
```

**Key design decisions:**
- **Go c-shared library** — reuses HashiCorp's grammar via Go's `encoding/json`; zero JSON subprocess overhead
- **Zig ArenaAllocator** — 50k nodes freed in a single O(1) call; no GC pauses
- **SoA via `MultiArrayList`** — geometry arrays (`x[]`, `y[]`) are contiguous in memory; L1 cache stays hot during culling
- **R-Tree** (Sprint 2) — superior to Quadtrees for overlapping rectangular geometries (VPC ⊃ Subnet ⊃ EC2)

---

## Sprint 1 Results

| Gate | Criterion | Result |
|---|---|---|
| **PRT-01** Parse 50k nodes via FFI | < 500ms | **70ms** ✅ |
| **PRT-02** SoA vs AoS speedup | ≥ 1.40× | **12.45×** ✅ |

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Go | ≥ 1.21 | [go.dev/dl](https://go.dev/dl/) |
| Zig | **0.15.x** | [ziglang.org/download](https://ziglang.org/download/) |
| Make | any | `apt install make` / `brew install make` |
| PlantUML | optional | `apt install plantuml` (for diagrams only) |

> ⚠️ **Zig version matters.** The engine requires Zig ≥ 0.15.0. Earlier versions have breaking API differences. Run `zig version` to confirm.

---

## Getting Started

### 1 — Clone & enter

```bash
git clone git@github.com:gmrodrigues/sky-dozer-for-terraform.git
cd sky-dozer-for-terraform
```

### 2 — Generate the synthetic test fixture

```bash
mkdir -p zig-engine/testdata
go run go-bridge/cmd/gen-tfstate/main.go --count=50000 --seed=42 \
    > zig-engine/testdata/fixture.tfstate.json
```

### 3 — Run the Go unit tests (PRT-01)

```bash
cd go-bridge
go test ./... -v -run TestParseTFState -count=1
```

Expected output:
```
--- PASS: TestParseTFState_Timing (0.09s)    # 70ms, well under 500ms limit
--- PASS: TestParseTFState_ByteCount (0.09s)
--- PASS: TestParseTFState_IDSpotCheck (0.08s)
--- PASS: TestParseTFState_NilGuards (0.00s)
```

### 4 — Run the SoA vs AoS benchmark (PRT-02)

```bash
cd zig-engine
zig build bench
```

Expected output:
```
=== PRT-02: SoA vs AoS (50000 nodes x 100 runs) ===

  AoS (ArrayList<TFNode>)   avg:       70 us
  SoA (MultiArrayList)      avg:        5 us
  Speedup:                      12.45x

PRT-02 PASS  SoA is 12.45x faster than AoS
```

### 5 — Run everything at once

```bash
make all
```

---

## Project Structure

```
sky-dozer-for-terraform/
├── Makefile                        # Orchestrates Go + Zig toolchains
│
├── go-bridge/                      # Go c-shared parser library
│   ├── bridge.go                   # ParseTFState — C ABI export
│   ├── bridge_test.go              # PRT-01 unit tests
│   └── cmd/gen-tfstate/main.go     # Synthetic 50k-node .tfstate generator
│
├── zig-engine/                     # Zig rendering engine
│   ├── build.zig                   # `zig build test` + `zig build bench`
│   ├── src/main.zig                # PRT-01 integration test (ArenaAllocator)
│   ├── src/bench/soa_bench.zig     # PRT-02 SoA vs AoS benchmark
│   └── testdata/                   # Generated fixtures (gitignored)
│
└── docs/
    ├── PTEC.md                     # Technical proposal & architecture spec
    ├── PRT.md                      # PoC validation gates (PRT-01 to PRT-04)
    ├── Sprints.md                  # Sprint plan
    ├── journal/sprint-1.md         # Delivery report (Sprint 1)
    ├── prompts/sprint-1.md         # AI prompt log
    └── review/sprint-1/            # Stakeholder reviews (14 perspectives)
```

---

## Roadmap

| Sprint | Focus | Status |
|---|---|---|
| **Sprint 1** | Go bridge FFI + SoA benchmark | ✅ Done |
| **Sprint 2** | R-Tree spatial index + view-frustum culling | 🔜 Next |
| **Sprint 3** | Semantic LoD + Raylib/Mach rendering | ⬜ Planned |
| **Sprint 4** | Go GC tuning (`GOGC=off`) + async reload | ⬜ Planned |

---

## Documentation

| Document | Description |
|---|---|
| [PTEC.md](docs/PTEC.md) | Architecture specification — WHY this stack |
| [PRT.md](docs/PRT.md) | PoC validation gates with binary pass/fail criteria |
| [Sprints.md](docs/Sprints.md) | Full sprint execution plan |
| [journal/sprint-1.md](docs/journal/sprint-1.md) | Sprint 1 delivery report with results |
| [review/](docs/review/) | 14 stakeholder reviews (PO, TechLead, SecOps, CEO, UX, Domain…) |

---

## Development Notes

### Building `libbridge.so` (Go → C shared library)

```bash
cd go-bridge
go build -buildmode=c-shared -o libbridge.so .
# Produces: libbridge.so (2.9MB) + bridge.h
```

### Re-generating PlantUML diagrams

```bash
plantuml -tpng docs/journal/diagrams/*.puml
```

---

## License

TBD — see [lawyer review](docs/review/sprint-1/lawyer.md) for trademark and licensing considerations.

---

## Contributing

This project is in active PoC phase. If you're interested in contributing, read the [architecture spec](docs/PTEC.md) and the [Sprint 1 journal](docs/journal/sprint-1.md) first to understand the design constraints.

For onboarding guidance, see the [Jr. Developer review](docs/review/sprint-1/jr-developer.md) — it honestly describes what's accessible and what requires deeper systems knowledge.
