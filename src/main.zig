const std = @import("std");

const target_duration_ms: i64 = 15*1000;

const max_cpus: u8 = 255;

const ZpuInfo = struct {
    loop_counter: i64 = 0,
    duration_ms: i64 = 0
};

var timings: [max_cpus]i64 = undefined;
var zpu_info = ZpuInfo {};

var waiting: bool = true;

comptime {
    asm (
        \\.global asm_cdtz;
        \\.type asm_cdtz, @function;
        \\asm_cdtz:
        \\  testq   %rdi, %rdi
        \\  je      asm_cdtz2
        \\asm_cdtz3:
        \\  subq    $1, %rdi
        \\  jne     asm_cdtz3
        \\asm_cdtz2:
        \\  movl    $0, %eax
        \\  ret
    );
}

extern fn asm_cdtz(n: i64) i64;

// Measure the elapsed time (in millis) it takes
// to count down from 'n' to 0.
fn timedCountDownToZeroInMillis(n: i64) i64 {
    const start_time = std.time.milliTimestamp();
    _ = asm_cdtz(n);
    const end_time = std.time.milliTimestamp();
    const elapsedTimeMillis = end_time - start_time;
    return elapsedTimeMillis;
}

// Determine the value to start counting down from
// that will take 15 seconds to count down to zero.
fn calibrateMainLoop() void {
    var iterations: u8 = 0;
    var loop_counter: i64 = 2;
    var current_duration_ms: i64 = 0;
    const max_iterations: u8 = 4;
    while (iterations < max_iterations) {
        current_duration_ms = timedCountDownToZeroInMillis(loop_counter);
        if (current_duration_ms > 10) {
            //std.debug.print("counter = {d}, duration_ms = {d}\n", .{loop_counter, current_duration_ms});
            if (@abs(target_duration_ms-current_duration_ms) < 100) {
                //std.debug.print("[BR] counter = {d}, duration_ms = {d}\n", .{loop_counter, current_duration_ms});
                break;
            }
        }
        if (current_duration_ms < 1000) {
            loop_counter = loop_counter * 2;
        }
        else {
            loop_counter = @divTrunc(loop_counter * target_duration_ms,current_duration_ms);
            iterations += 1;
        }
    }
    if (iterations == max_iterations) {
        std.debug.print("Failed!\n", .{});
    }
    else {
        zpu_info.duration_ms = current_duration_ms;
        zpu_info.loop_counter = loop_counter;
    }
    return;
}

fn workerThread(threadIdx: u8) void {
    while (waiting) {
        // Sleep for 10 milliseconds.
        std.time.sleep(std.time.ns_per_ms*10);
    }
    //std.debug.print("workerThread {d}, loop_counter {d}\n", .{threadIdx, zpu_info.loop_counter});
    timings[threadIdx] = timedCountDownToZeroInMillis(zpu_info.loop_counter);
}

pub fn main() !void {
    std.debug.print("zpu-bench v0.0.3\n\n", .{});
    const num_zpus = try std.Thread.getCpuCount();
    std.debug.print("CPU = {d}\n", .{num_zpus});
    calibrateMainLoop();
    std.debug.print("COUNTER_I64 = {d}\nDURATION_MS = {d}\n", .{zpu_info.loop_counter, zpu_info.duration_ms});

    var threads: [max_cpus]std.Thread = undefined;
    
    // -----------------------------------------------
    var i: u8 = 0;
    while (i < num_zpus) {
        threads[i] = try std.Thread.spawn(.{}, workerThread, .{@as(u8,i)});
        i += 1;
    }
    // -----------------------------------------------

    //std.debug.print("Sleep for 5 seconds\n", .{});
    std.time.sleep(std.time.ns_per_s*5);
    //std.debug.print("Woke up after 5 seconds\n", .{});
    waiting = false;

    // -----------------------------------------------
    i = 0;
    while (i < num_zpus) {
        threads[i].join();
        i += 1;
    }
    // -----------------------------------------------

    const f_duration_ms:f32 = @floatFromInt(zpu_info.duration_ms);

    // -----------------------------------------------
    i = 0;
    var dop: f32 = 0;
    while (i < num_zpus) {
        //std.debug.print("Timings {d} is {d}\n", .{i, timings[i]});
        dop += f_duration_ms / @as(f32,@floatFromInt(timings[i]));
        i += 1;
    }
    // -----------------------------------------------

    std.debug.print("DOP = {d:.3} \n", .{dop});
}
