// VMS is built using raylib-zig (c) Nikolas Wipper 202// raylib-zig (c) Nikolas Wipper 2023

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
    defer rl.closeWindow(); // Closes window

    rl.setTargetFPS(60); // Sets FPS to 60

    // Main loop
    while (!rl.windowShouldClose()) {
        // Update

        // Sees if clear or back key were pressed respectfully and then does the respective actions if so.
        clearScreen();
        removeLastLine();

        // Checks to see if user wants to change the line thickness
        try lineThicknessChange(rl.getKeyPressed());

        // Checks to see if the user wants to change the line color and then stores it in colorIndex
        colorEncoder(rl.getKeyPressed());

        // Clears the background to be drawn on.
        rl.clearBackground(rl.Color.black);

        // Sees if user added a point and then stores the point data to points while incrementing index.
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            // index is set to points.len so that you don't have to dig around in the code to find this if statement. They should have the same max value/array length so it should be fine.
            // checks to see if index is at max capacity
            if (index == (points.len - 1)) {
                // Debug statement telling the user if it is at max capacity
                try stdout.print("Input ignored. Index has reached max capacity ({d}).\n", .{index});
            } else {
                // Stores new point in points
                points[index] = rl.getMousePosition();
                // Increments index
                index += 1;
                // Debug statement to tell the user what the index is
                try stdout.print("index is: {d}\n", .{index});
            }
        }

        // Begins raylib drawing
        rl.beginDrawing();
        // Waits to end it until we want to
        defer rl.endDrawing();

        // Draws the lines with the previous point and current point with current color and current lineThickness.
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
        // Doesn't do anything if none of the keys are pressed.
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
                // if something goes horribly wrong or if I don't know what I'm doing, it will just default to the default color.
                return colorParser(defaultColor);
            }
        },
    }
}

// Checks to see if user wants to change the line thickness
fn lineThicknessChange(key: rl.KeyboardKey) !void {
    switch (key) {
        // Increment lineThickness up (with debug message)
        rl.KeyboardKey.key_up => {
            lineThickness += 1;
            try stdout.print("Line Thickness: {d}\n", .{lineThickness});
        },
        // Increment lineThickness down (with debug message)
        rl.KeyboardKey.key_down => {
            if (lineThickness > 1) {
                lineThickness -= 1;
            }
            try stdout.print("Line Thickness: {d}\n", .{lineThickness});
        },
        else => {},
    }
}

// Clears screen of all of the points
fn clearScreen() void {
    if (rl.isKeyPressed(clearKey)) {
        points = undefined;
        previousColor = undefined;
        colorIndex = undefined;
        index = 0;
    }
}

// Removes the last line
fn removeLastLine() void {
    if (rl.isKeyPressed(backKey) and index >= 1) {
        points[index] = undefined;
        //previous color might have some issues here since the "correct"
        previousColor = colorIndex[index - 2];
        colorIndex[index] = undefined;
        index -= 1;
    }
}
