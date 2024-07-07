// raylib-zig (c) Nikolas Wipper 202// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn();

pub fn main() anyerror!void {
    // Initialization

    const screenWidth = 1200;
    const screenHeight = 600;
    //const displayHeight = 1080;
    //const displayWidth = 1920;

    // This seems really bad, but I am not sure by how much or how to make it better at the mome.
    var points: [64]rl.Vector2 = undefined;
    var index: u8 = 0;
    var color: rl.Color = rl.Color.red;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update

        switch (rl.getKeyPressed()) {
            rl.KeyboardKey.key_one => color = rl.Color.red,
            rl.KeyboardKey.key_two => color = rl.Color.orange,
            rl.KeyboardKey.key_three => color = rl.Color.yellow,
            rl.KeyboardKey.key_four => color = rl.Color.green,
            rl.KeyboardKey.key_five => color = rl.Color.blue,
            rl.KeyboardKey.key_six => color = rl.Color.purple,
            rl.KeyboardKey.key_seven => color = rl.Color.white,
            rl.KeyboardKey.key_eight => color = rl.Color.gray,
            rl.KeyboardKey.key_nine => color = rl.Color.black,
            else => {},
        }

        rl.clearBackground(rl.Color.black);
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            // Find a good way of having a lot of lines/points.
            if (index == 64) {
                try stdout.print("Input ignored. Index has reached max capacity.\n", .{});
            } else {
                points[index] = rl.getMousePosition();
                index += 1;
                try stdout.print("index is: {d}\n", .{index});
            }
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        if (index >= 2) {
            for (1..index) |i| {
                rl.drawLineV(points[i - 1], points[i], color);
            }
        }
    }
}

//fn drawUserLine2(color: rl.Color) !void {
//    var startPos: rl.Vector2 = undefined;
//    var endPos: rl.Vector2 = undefined;
//    var i: u4 = 0;
//
//    while (i < 3) {
//        if (isMouseButtonPressedL() and i == 0) {
//            startPos = rl.getMousePosition();
//            i += 1;
//        }
//        if (isMouseButtonPressedL() and i == 1) {
//            endPos = rl.getMousePosition();
//            i += 1;
//        }
//        if (i == 2) {
//            rl.drawLineV(startPos, endPos, color);
//        }
//    }
//}

//if (rl.isKeyPressed(rl.KeyboardKey.key_l)) {
//     try stdout.print("You pressed l!", .{});
//            {
//                const handle = try std.Thread.spawn(.{}, drawUserLine2(rl.Color.red), .{1});
//                defer handle.join();
