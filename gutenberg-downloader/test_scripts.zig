const std = @import("std");

pub fn main() !void {
    const scripts = [_][]const u8{
        "python download_books.py",
        "node download_books.js",
        "ruby download_books.rb",
        "cargo run --bin download_books",
        "zig run download_books.zig",
        "java DownloadBooks",
        "npx tsx download_books.ts",
    };

    const runs = 3;

    var file = try std.fs.cwd().createFile("newtimings.md", .{});
    defer file.close();

    try file.writeAll("| Script | Time |\n|--------|------|\n");

    for (scripts) |script| {
        var times: [runs]f64 = undefined;
        var count: usize = 0;

        for (0..runs) |_| {
            // Remove book files
            _ = std.os.system("rm -f book_*.txt");

            // Time the script
            var timer = try std.time.Timer.start();
            _ = std.os.system(script.ptr);
            const elapsed = timer.read();
            times[count] = @as(f64, elapsed) / std.time.ns_per_s;
            count += 1;
        }

        if (count > 0) {
            var sum: f64 = 0;
            for (times[0..count]) |t| sum += t;
            const avg = sum / @as(f64, count);
            const display = script; // Use script name as display
            var buf: [64]u8 = undefined;
            const formatted = std.fmt.bufPrint(&buf, "0m{d:.3}s", .{avg}) catch "0m0.000s";
            try file.writer().print("| {s} | {s} |\n", .{display, formatted});
        }
    }

    std.debug.print("Results written to newtimings.md\n", .{});
}
            _ = std.process.execv(allocator, argv.items) catch |err| {
                std.debug.print("Error running {s}: {}\n", .{script, err});
                continue;
            };
            const elapsed = timer.read();
            times[count] = @as(f64, elapsed) / std.time.ns_per_s;
            count += 1;
        }

        if (count > 0) {
            var sum: f64 = 0;
            for (times[0..count]) |t| sum += t;
            const avg = sum / @as(f64, count);
            const display = script;
            var buf: [64]u8 = undefined;
            const formatted = std.fmt.bufPrint(&buf, "0m{d:.3}s", .{avg}) catch "0m0.000s";
            try file.writer().print("| {s} | {s} |\n", .{display, formatted});
        }
    }
            _ = std.process.execv(allocator, argv.items) catch |err| {
                std.debug.print("Error running {s}: {}\n", .{script, err});
                continue;
            };
            const elapsed = timer.read();
            times[count] = @as(f64, elapsed) / std.time.ns_per_s;
            count += 1;
        }

        if (count > 0) {
            var sum: f64 = 0;
            for (times[0..count]) |t| sum += t;
            const avg = sum / @as(f64, count);
            try results.put(script, avg);
        }
    }
            _ = std.process.execv(allocator, argv.items) catch |err| {
                std.debug.print("Error running {s}: {}\n", .{ script, err });
                continue;
            };
            const elapsed = timer.read();
            try times.append(@as(f64, elapsed) / std.time.ns_per_s);
        }

        if (times.items.len > 0) {
            var sum: f64 = 0;
            for (times.items) |t| sum += t;
            const avg = sum / @as(f64, times.items.len);
            try results.put(script, avg);
        }
    }

    var file = try std.fs.cwd().createFile("newtimings.md", .{});
    defer file.close();

    try file.writeAll("| Script | Time |\n|--------|------|\n");

    var it = results.iterator();
    while (it.next()) |entry| {
        const script = entry.key_ptr.*;
        const avg = entry.value_ptr.*;
        const display = if (std.mem.eql(u8, script, "python download_books.py")) "Python"
                        else if (std.mem.eql(u8, script, "node download_books.js")) "JavaScript"
                        else if (std.mem.eql(u8, script, "ruby download_books.rb")) "Ruby"
                        else if (std.mem.eql(u8, script, "cargo run --bin download_books")) "Rust"
                        else if (std.mem.eql(u8, script, "zig run download_books.zig")) "Zig"
                        else if (std.mem.eql(u8, script, "java DownloadBooks")) "Java"
                        else if (std.mem.eql(u8, script, "npx tsx download_books.ts")) "TypeScript"
                        else script;
        var buf: [64]u8 = undefined;
        const formatted = std.fmt.bufPrint(&buf, "0m{d:.3}s", .{avg}) catch "0m0.000s";
        try file.writer().print("| {s} | {s} |\n", .{display, formatted});
    }

    std.debug.print("Results written to newtimings.md\n", .{});
}
