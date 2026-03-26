// cmd/gen-tfstate generates a synthetic .tfstate JSON file with N resources.
// Usage: go run ./cmd/gen-tfstate [--count=50000] [--seed=42] > fixture.tfstate.json
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
)

// resource matches the fields ParseTFState extracts.
type resource struct {
	Index int32 `json:"index"`
	X     int32 `json:"x"`
	Y     int32 `json:"y"`
	W     int32 `json:"w"`
	H     int32 `json:"h"`
}

type tfState struct {
	FormatVersion string     `json:"format_version"`
	Resources     []resource `json:"resources"`
}

func main() {
	count := flag.Int("count", 50_000, "number of synthetic resources")
	seed := flag.Int64("seed", 42, "random seed for reproducibility")
	flag.Parse()

	rng := rand.New(rand.NewSource(*seed))
	resources := make([]resource, *count)
	for i := range resources {
		resources[i] = resource{
			Index: int32(i),
			// Positions spread across a large canvas (e.g. 1M × 1M units).
			X: rng.Int31n(1_000_000),
			Y: rng.Int31n(1_000_000),
			// Width/Height mimicking typical Terraform resource boxes.
			W: 50 + rng.Int31n(200),
			H: 30 + rng.Int31n(100),
		}
	}

	state := tfState{
		FormatVersion: "1.0",
		Resources:     resources,
	}

	enc := json.NewEncoder(os.Stdout)
	if err := enc.Encode(state); err != nil {
		fmt.Fprintf(os.Stderr, "gen-tfstate: encode error: %v\n", err)
		os.Exit(1)
	}
}
