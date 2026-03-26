const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── PRT-01: Integration Test ───────────────────────────────────────────────
    // Links against libbridge.so (compiled from go-bridge/).
    // Run: zig build test
    const lib_bridge_path = b.option(
        []const u8,
        "bridge-path",
        "Path to directory containing libbridge.so and bridge.h",
    ) orelse "../go-bridge";

    const test_step = b.step("test", "Run PRT-01 integration test (FFI bridge)");

    const prt01_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    prt01_mod.addIncludePath(.{ .cwd_relative = lib_bridge_path });
    prt01_mod.addLibraryPath(.{ .cwd_relative = lib_bridge_path });
    prt01_mod.linkSystemLibrary("bridge", .{});

    const prt01 = b.addTest(.{
        .root_module = prt01_mod,
    });

    const run_prt01 = b.addRunArtifact(prt01);
    test_step.dependOn(&run_prt01.step);

    // ── PRT-02: SoA vs AoS Benchmark ──────────────────────────────────────────
    // Run: zig build bench
    const bench_step = b.step("bench", "Run PRT-02 SoA vs AoS benchmark");

    const bench_mod = b.createModule(.{
        .root_source_file = b.path("src/bench/soa_bench.zig"),
        .target = target,
        // ReleaseFast enables SIMD/vectorisation — necessary for realistic perf.
        .optimize = .ReleaseFast,
    });

    const bench_exe = b.addExecutable(.{
        .name = "soa_bench",
        .root_module = bench_mod,
    });

    const run_bench = b.addRunArtifact(bench_exe);
    bench_step.dependOn(&run_bench.step);

    b.installArtifact(bench_exe);
}
