// raylib-zig (c) Nikolas Wipper 202// raylib-zig (c) Nikolas Wipper 2023

// Zig definitions
const std = @import("std");
const rl = @import("raylib");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn();

/// Indexes and program variables::
// This (points being stored in an array) seems really bad, but I am not sure by how much or how to make it better at the mome.
var points: [128]rl.Vector2 = undefined;
var index: u9 = 0;
// Index-1 doesn't work for a slice, so I'll just store the last color value.
var previousColor: u8 = undefined;
var colorIndex: [128]u8 = undefined;
var lineThickness: f32 = 1;

/// User Defined values:
// Color codes are found in the colorParser function.
const defaultColor: u8 = 5;
// Clears screen.
const clearKey: rl.KeyboardKey = rl.KeyboardKey.key_delete;
// Removes last placed line.
const backKey: rl.KeyboardKey = rl.KeyboardKey.key_backspace;

/// Custom hardcoded values:
const clear: rl.Color = rl.Color.init(0, 0, 0, 0);
// The screen and display values will be figured out later, but now they are hardcoded.
const screenWidth = 1200;
const screenHeight = 600;
//const displayHeight = 1080;
//const displayWidth = 1920;

pub fn main() anyerror!void {
    // Initialization

    // First value set so that it doesn't return the previous color when called.
    colorIndex[1] = defaultColor;

    rl.initWindow(screenWidth, screenHeight, "Vardeltus Manufacturing Software");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update

        // Sees if clear or back key were pressed respectfully and then does the respective actions if so.
        clearScreen();
        removeLastLine();

        //Add a thing where you are able to input the Line thickness instead of just incrementing it. (make sure the fact that it is f32 is known)
        try lineThicknessChange(rl.getKeyPressed());

        colorEncoder(rl.getKeyPressed());

        rl.clearBackground(rl.Color.black);
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            // Find a good way of having a lot of lines/points. Also the colorEncoder will cause the program to crash if the index was the full 64, so if this is the final way of doing it, make sure to increment this counter down by 1 from index's max or fix the encoder issue..
            // index is set to points.len so that you don't have to dig around in the code to find this if statement. They should have the same max value/array length so it should be fine.
            if (index == (points.len - 1)) {
                try stdout.print("Input ignored. Index has reached max capacity ({d}).\n", .{index});
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
                rl.drawLineEx(points[i - 1], points[i], lineThickness, colorParser(colorIndex[i]));
            }
        }
    }
}

//When the user inputs 1-9 that value will be stored in the future entry of the colorIndex (so that the color of the line you are about to create is changed and not the past line.)
fn colorEncoder(key: rl.KeyboardKey) void {
    switch (key) {
        rl.KeyboardKey.key_one => {
            colorIndex[index] = 1;
        },
        rl.KeyboardKey.key_two => {
            colorIndex[index] = 2;
        },
        rl.KeyboardKey.key_three => {
            colorIndex[index] = 3;
        },
        rl.KeyboardKey.key_four => {
            colorIndex[index] = 4;
        },
        rl.KeyboardKey.key_five => {
            colorIndex[index] = 5;
        },
        rl.KeyboardKey.key_six => {
            colorIndex[index] = 6;
        },
        rl.KeyboardKey.key_seven => {
            colorIndex[index] = 7;
        },
        rl.KeyboardKey.key_eight => {
            colorIndex[index] = 8;
        },
        rl.KeyboardKey.key_nine => {
            colorIndex[index] = 9;
        },
        else => {},
    }
}

// Decodes the colorIndex entry and returns the respective color.
fn colorParser(entry: u8) rl.Color {
    switch (entry) {
        1 => {
            previousColor = 1;
            return rl.Color.red;
        },
        2 => {
            previousColor = 2;
            return rl.Color.orange;
        },
        3 => {
            previousColor = 3;
            return rl.Color.yellow;
        },
        4 => {
            previousColor = 4;
            return rl.Color.green;
        },
        5 => {
            previousColor = 5;
            return rl.Color.blue;
        },
        6 => {
            previousColor = 6;
            return rl.Color.purple;
        },
        7 => {
            previousColor = 7;
            return rl.Color.white;
        },
        8 => {
            previousColor = 8;
            return rl.Color.gray;
        },
        9 => {
            previousColor = 9;
            return clear;
        },
        else => {
            // Returns the last color so that you don't have to specify which color you want every time.
            if (previousColor > 0 and previousColor < 10) {
                return colorParser(previousColor);
            } else {
                return colorParser(defaultColor);
            }
        },
    }
}

fn lineThicknessChange(key: rl.KeyboardKey) !void {
    switch (key) {
        rl.KeyboardKey.key_up => {
            lineThickness += 1;
            try stdout.print("Line Thickness: {d}\n", .{lineThickness});
        },
        rl.KeyboardKey.key_down => {
            if (lineThickness > 1) {
                lineThickness -= 1;
            }
            try stdout.print("Line Thickness: {d}\n", .{lineThickness});
        },
        else => {},
    }
}

fn clearScreen() void {
    if (rl.isKeyPressed(clearKey)) {
        points = undefined;
        previousColor = undefined;
        colorIndex = undefined;
        index = 0;
    }
}

fn removeLastLine() void {
    if (rl.isKeyPressed(backKey) and index >= 1) {
        points[index] = undefined;
        //previous color might have some issues here since the "correct"
        previousColor = colorIndex[index - 2];
        colorIndex[index] = undefined;
        index -= 1;
    }
}
