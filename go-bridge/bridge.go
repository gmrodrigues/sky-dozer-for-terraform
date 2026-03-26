// Package main is compiled as a c-shared library.
// Build with: go build -buildmode=c-shared -o libbridge.so .
package main

/*
#include <stdint.h>
#include <stddef.h>

// NodeRecord mirrors the struct the Zig engine expects.
// 5 × int32 = 20 bytes per node (no padding with explicit layout).
typedef struct {
    int32_t id;
    int32_t x;
    int32_t y;
    int32_t w;
    int32_t h;
} NodeRecord;
*/
import "C"

import (
	"encoding/json"
	"unsafe"
)

// NodeRecordSize is the exact byte size of one NodeRecord.
const NodeRecordSize = 5 * 4 // 5 × int32

// tfResource is the Go-side representation of one resource in a .tfstate file.
// Only geometry fields are extracted; everything else is discarded.
type tfResource struct {
	Index int32 `json:"index"`
	X     int32 `json:"x"`
	Y     int32 `json:"y"`
	W     int32 `json:"w"`
	H     int32 `json:"h"`
}

// tfState is the minimal .tfstate shape we care about.
type tfState struct {
	Resources []tfResource `json:"resources"`
}

// ParseTFState reads a JSON-encoded tfstate from jsonData (a C string owned by
// the caller) and writes flat NodeRecord entries into outBuf (a C buffer
// pre-allocated by the caller with capacity for at least maxNodes records).
//
// Returns the number of nodes written, or -1 on error.
//
// SAFETY CONTRACT (cgo rules):
//   - Go does not retain any copy of outBuf after this function returns.
//   - outBuf is allocated by Zig's ArenaAllocator; Go never frees it.
//   - No Go heap pointer is stored inside the C buffer.
//
//export ParseTFState
func ParseTFState(jsonData *C.char, outBuf unsafe.Pointer, maxNodes C.int32_t) C.int32_t {
	if jsonData == nil || outBuf == nil || maxNodes <= 0 {
		return -1
	}

	// Convert the C string to a Go []byte without copying the data.
	// GoString allocates a new Go string — this is intentional so the parser
	// only touches Go-managed memory during unmarshalling.
	raw := C.GoString(jsonData)

	var state tfState
	if err := json.Unmarshal([]byte(raw), &state); err != nil {
		return -1
	}

	limit := int(maxNodes)
	if len(state.Resources) < limit {
		limit = len(state.Resources)
	}

	// Write records directly into the C buffer.
	// We cast outBuf to a pointer to the first NodeRecord and then index into it.
	// After this loop, Go holds no reference to outBuf.
	base := uintptr(outBuf)
	for i := 0; i < limit; i++ {
		r := state.Resources[i]
		rec := (*C.NodeRecord)(unsafe.Pointer(base + uintptr(i)*NodeRecordSize))
		rec.id = C.int32_t(r.Index)
		rec.x = C.int32_t(r.X)
		rec.y = C.int32_t(r.Y)
		rec.w = C.int32_t(r.W)
		rec.h = C.int32_t(r.H)
	}

	return C.int32_t(limit)
}

func main() {}
