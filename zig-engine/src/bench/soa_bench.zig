// src/bench/soa_bench.zig — PRT-02: SoA vs AoS benchmark using MultiArrayList.
//
// Run: zig build bench
//
// Pass criteria (from PRT-02):
//   - SoA iteration ≥ 40% faster than AoS iteration over 50k nodes
//   - Process exits with code 1 if criterion not met.
//
// Simulates the frustum-culling inner loop: accumulate X+Y across all nodes.
// The metadata padding in TFNode makes AoS cache-miss penalty realistic.
const std = @import("std");

const NODE_COUNT: usize = 50_000;
const RUNS: usize = 100;

/// TFNode includes metadata padding to make AoS cache-miss penalty realistic.
const TFNode = struct {
    id: i32,
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    name: [32]u8 = [_]u8{0} ** 32,
    resource_type: [16]u8 = [_]u8{0} ** 16,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // ── Seed both datasets identically ───────────────────────────────────────
    var rng = std.Random.DefaultPrng.init(42);
    var random = rng.random();

    // ── AoS setup ─────────────────────────────────────────────────────────────
    // Zig 0.15: ArrayList is unmanaged — allocator passed to each mutating call.
    var aos_list = std.ArrayList(TFNode){};
    defer aos_list.deinit(alloc);
    try aos_list.ensureTotalCapacity(alloc, NODE_COUNT);
    for (0..NODE_COUNT) |i| {
        try aos_list.append(alloc, .{
            .id = @intCast(i),
            .x = random.intRangeLessThan(i32, 0, 1_000_000),
            .y = random.intRangeLessThan(i32, 0, 1_000_000),
            .w = 50 + random.intRangeLessThan(i32, 0, 200),
            .h = 30 + random.intRangeLessThan(i32, 0, 100),
        });
    }

    // ── SoA setup ─────────────────────────────────────────────────────────────
    var soa_list = std.MultiArrayList(TFNode){};
    defer soa_list.deinit(alloc);
    try soa_list.ensureTotalCapacity(alloc, NODE_COUNT);
    // Reset RNG to same seed so SoA has identical data values.
    rng = std.Random.DefaultPrng.init(42);
    random = rng.random();
    for (0..NODE_COUNT) |i| {
        try soa_list.append(alloc, .{
            .id = @intCast(i),
            .x = random.intRangeLessThan(i32, 0, 1_000_000),
            .y = random.intRangeLessThan(i32, 0, 1_000_000),
            .w = 50 + random.intRangeLessThan(i32, 0, 200),
            .h = 30 + random.intRangeLessThan(i32, 0, 100),
        });
    }

    // ── Benchmark AoS ─────────────────────────────────────────────────────────
    var aos_total_ns: u64 = 0;
    var aos_sink: i64 = 0;
    for (0..RUNS) |_| {
        var timer = try std.time.Timer.start();
        var acc: i64 = 0;
        for (aos_list.items) |node| acc +%= node.x + node.y;
        aos_total_ns += timer.read();
        aos_sink +%= acc;
    }
    const aos_avg_ns = aos_total_ns / RUNS;

    // ── Benchmark SoA ─────────────────────────────────────────────────────────
    // Access ONLY x and y slices — metadata fields never touch L1 cache.
    var soa_total_ns: u64 = 0;
    var soa_sink: i64 = 0;
    for (0..RUNS) |_| {
        var timer = try std.time.Timer.start();
        var acc: i64 = 0;
        const xs = soa_list.items(.x);
        const ys = soa_list.items(.y);
        for (0..NODE_COUNT) |i| acc +%= xs[i] + ys[i];
        soa_total_ns += timer.read();
        soa_sink +%= acc;
    }
    const soa_avg_ns = soa_total_ns / RUNS;

    // ── Results ───────────────────────────────────────────────────────────────
    std.debug.print("\n=== PRT-02: SoA vs AoS ({d} nodes x {d} runs) ===\n\n", .{ NODE_COUNT, RUNS });
    std.debug.print("  AoS (ArrayList<TFNode>)   avg: {d:>8} us\n", .{aos_avg_ns / 1000});
    std.debug.print("  SoA (MultiArrayList)      avg: {d:>8} us\n", .{soa_avg_ns / 1000});

    const speedup_x100: u64 = if (soa_avg_ns > 0) (aos_avg_ns * 100) / soa_avg_ns else 0;
    const si = speedup_x100 / 100;
    const sd = speedup_x100 % 100;
    std.debug.print("  Speedup:                      {d}.{d:0>2}x\n", .{ si, sd });

    // Suppress sink optimisation.
    if (aos_sink == soa_sink) std.debug.print("  (sinks match: {d})\n", .{aos_sink});

    // PRT-02 assertion: SoA must be >= 1.40x faster.
    if (speedup_x100 < 140) {
        std.debug.print("\nPRT-02 FAIL: {d}.{d:0>2}x < required 1.40x\n", .{ si, sd });
        std.process.exit(1);
    }
    std.debug.print("\nPRT-02 PASS  SoA is {d}.{d:0>2}x faster than AoS\n", .{ si, sd });
}
