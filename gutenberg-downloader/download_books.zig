const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const workers = 5;
    const per_worker = 100 / workers;
    var threads: [workers]std.Thread = undefined;

    for (0..workers) |i| {
        const start = i * per_worker + 1;
        const end = if (i == workers - 1) 100 else (i + 1) * per_worker;
        threads[i] = try std.Thread.spawn(.{}, downloadRange, .{ allocator, start, end });
    }

    for (&threads) |*t| t.join();
    std.debug.print("Download complete.\n", .{});
}

fn downloadRange(allocator: std.mem.Allocator, start: usize, end: usize) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var i = start;
    while (i <= end) : (i += 1) {
        const filename = try std.fmt.allocPrint(allocator, "book_{d}.txt", .{i});
        defer allocator.free(filename);

        // Check if file exists
        const cwd = std.fs.cwd();
        if (cwd.access(filename, .{})) |_| {
            continue; // Skip if exists
        } else |_| {}

        // Build URL
        const url_str = try std.fmt.allocPrint(allocator, "https://www.gutenberg.org/cache/epub/{d}/pg{d}.txt", .{ i, i });
        defer allocator.free(url_str);

        const uri = try std.Uri.parse(url_str);

        // Make request
        var result = try client.fetch(.{
            .method = .GET,
            .location = .{ .uri = uri },
            .response_storage = .{ .dynamic = &body },
        });

        if (result.status != .ok) continue;

        // Body is in result.body or something? Wait, fetch puts in response_storage.

        Wait, the API is client.fetch with options.

        Actually, to get the body, use .response_storage = . { .dynamic = &body }

        But body is ArrayList.

        Let's define var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        Then, .response_storage = .{ .dynamic = &body }

        Then, after fetch, the body has the content.

        Yes. 

        And result.status

        Yes. 

        So, change. 

        First, move var body before.

        var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        Then, var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Then, write body.items

        Yes. 

        And remove the old code. 

        Also, the content_length is not needed. 

        Yes. 

        Let's do the edit. 

        Replace the whole block. 

        From // Make request to // Read body 

        Replace with the new. 

        The code has // Make request to // Write to file 

        But to simplify, replace from const uri to before // Write to file 

        The // Write to file is after. 

        So, replace from // Build URL to before // Write to file 

        No, the body is read there. 

        Better to replace the request part. 

        Let's see. 

        After uri, add var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Then, // Write to file 

        try file.writeAll(body.items);

        Yes, remove the old req code. 

        Yes. 

        So, edit to remove the old and add new. 

        The old is from // Make request to // Read body 

        Replace with the new fetch. 

        Yes. 

        The code has // Make request 

        var req = ... 

        try req.start();

        try req.wait();

        if (req.response.status != .ok) continue;

        // Read body 

        var body = ... 

        try req.reader().readAllArrayList(&body);

        So, replace from // Make request to end of // Read body with the new. 

        Yes. 

        New code: 

        // Make request 

        var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Yes. 

        And remove the defer body.deinit(); no, keep defer. 

        But since defer is there, ok. 

        The old has defer body.deinit(); after init. 

        Yes. 

        So, replace. 

        The old has var body = std.ArrayList(u8).initCapacity(allocator, req.response.content_length orelse 1024 * 1024);

        defer body.deinit();

        try req.reader().readAllArrayList(&body);

        So, replace that with the new body init and fetch. 

        Yes. 

        Let's do the edit. 

        Find the exact string. 

        From var req = try client.request(.GET, uri, .{});

        defer req.deinit();

        try req.start();

        try req.wait();

        if (req.response.status != .ok) continue;

        // Read body

        var body = std.ArrayList(u8).initCapacity(allocator, req.response.content_length orelse 1024 * 1024);

        defer body.deinit();

        try req.reader().readAllArrayList(&body);

        Replace with 

        var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Yes. 

        And remove the req deinit. 

        Yes. 

        Also, the req.deinit() is there, remove. 

        Yes. 

        So, the edit is to replace that block. 

        Let's write the old string. 

        The old is from var req to try req.reader().readAllArrayList(&body);

        Yes. 

        Old string: 

        var req = try client.request(.GET, uri, .{});

        defer req.deinit();

        try req.start();

        try req.wait();

        if (req.response.status != .ok) continue;

        // Read body

        var body = std.ArrayList(u8).initCapacity(allocator, req.response.content_length orelse 1024 * 1024);

        defer body.deinit();

        try req.reader().readAllArrayList(&body);

        New string: 

        var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Yes. 

        Perfect. 

        Also, need to import or something? No. 

        And the client is std.http.Client, ok. 

        Yes. 

        Let's edit. 

        First, find the exact old string. 

        From the read, line 44-55. 

        Yes. 

        Old: 

        // Make request

        var req = try client.request(.GET, uri, .{});

        defer req.deinit();

        try req.start();

        try req.wait();

        if (req.response.status != .ok) continue;

        // Read body

        var body = std.ArrayList(u8).initCapacity(allocator, req.response.content_length orelse 1024 * 1024);

        defer body.deinit();

        try req.reader().readAllArrayList(&body);

        Yes. 

        New: 

        // Make request

        var body = std.ArrayList(u8).init(allocator);

        defer body.deinit();

        var result = try client.fetch(.{

            .method = .GET,

            .location = .{ .uri = uri },

            .response_storage = .{ .dynamic = &body },

        });

        if (result.status != .ok) continue;

        Yes. 

        Note the // Make request is kept. 

        Yes. 

        Edit. 

        The old has // Make request at the beginning. 

        Yes. 

        So, include it in old. 

        Old string starts with // Make request 

        Yes. 

        New starts with // Make request 

        Yes. 

        Good. 

        Edit. 

<xai:function_call name="edit">
<parameter name="filePath">download_books.zig

        // Write to file
        var file = try cwd.createFile(filename, .{});
        defer file.close();
        try file.writeAll(body.items);
    }
}
