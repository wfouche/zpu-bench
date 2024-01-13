const std = @import("std");

// https://godbolt.org/
//
// long countDownToZero(long n) {
//     while (n) {
//         n -= 1;
//     }
//     return n;
// }
//
// countDownToZero:
//         testq   %rdi, %rdi
//         je      .L2
// .L3:
//         subq    $1, %rdi
//         jne     .L3
// .L2:
//         movl    $0, %eax
//         ret

fn countDownToZero(N: u64) u64 {
    var n = N;
    while (n != 0) {
        n -= 1;
    }
    return n;
}

pub fn main() !void {
    std.debug.print("zpu-bench v0.0.0\n", .{});

    std.debug.print("\nbegin....\n", .{});
    _ = countDownToZero(1000_000_000);
    std.debug.print("end....\n", .{});
}
