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
var selLinePoints: [128]rl.Vector2 = undefined;
var selLineIndex: u9 = 0;
// Index-1 doesn't work for a slice, so I'll just store the last color value.
var previousColor: u5 = undefined;
var colorIndex: [128]u5 = undefined;
// Technically lineThickness can be f32 but I don't see why it would need to be above f16 (with a max value of 65.5k) and if it were to be higher then it might not work with drawSelLine when it adds it and selBoarderThickness together
var lineThickness: f16 = 1;
const selBoarderThickness: f16 = 2;

/// User Defined values:
// Color codes are found in the colorParser function.
const defaultColor: u5 = 5;
const selBoarderColor: u5 = 7;
// Clears screen.
const clearKey: rl.KeyboardKey = rl.KeyboardKey.key_delete;
// Removes last placed line.
const backKey: rl.KeyboardKey = rl.KeyboardKey.key_backspace;
// The button used to select objects
const selButton: rl.MouseButton = rl.MouseButton.mouse_button_right;
const holdSelKey: rl.KeyboardKey = rl.KeyboardKey.key_left_shift;
// The number of pixels that create an area where an object is considered selected if clicked
const selectionThreshold: i32 = 10;

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
        try Lines();

        // Figure out is the user is pressing the selButton and is near a line where it will then store the value in selPoints.
        selectLines();

        // Begins raylib drawing
        rl.beginDrawing();
        // Waits to end it until we want to end the drawing
        defer rl.endDrawing();

        // Draws lines if there are enough points
        drawLines();
        // if there are selLinePoints, it will draw the selLines
        drawSelLines();
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

fn clearSelLines() void {
    selLinePoints = undefined;
    selLineIndex = 0;
}

// Sees if user added a point and then stores the point data to points while incrementing index.
fn Lines() !void {
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
}

fn selectLines() void {
    // Checks to see if selButton is pressed and that there are enough points to check for selected lines. If so, it will determine what/if lines are selected and then store them if there are
    if (rl.isMouseButtonPressed(selButton) and index >= 2) {
        if (!rl.isKeyDown(holdSelKey)) {
            clearSelLines();
        }

        // Increments through all of the stored points
        for (1..index) |i| {

            // Defintions for the first stored point, second stored point, and mouse position.
            const point1: rl.Vector2 = points[i - 1];
            const point2: rl.Vector2 = points[i];
            const currentPoint: rl.Vector2 = rl.getMousePosition();
            // Checks to see if the points to see if they have been selected.
            if (rl.checkCollisionPointLine(currentPoint, point1, point2, selectionThreshold)) {
                //Stores selLinePoints and then increments the respective index.
                selLinePoints[selLineIndex] = point1;
                selLinePoints[selLineIndex + 1] = point2;
                selLineIndex += 2;
            }
        }
    }
}

// Draws lines if there are enough points
fn drawLines() void {
    if (index >= 2) {
        for (1..index) |i| {
            rl.drawLineEx(points[i - 1], points[i], lineThickness, colorParser(colorIndex[i]));
        }
    }
}

// if there are selLinePoints, it will draw the selLines
fn drawSelLines() void {
    if (selLineIndex >= 2) {
        for (0..selLineIndex) |i| {
            if (i % 2 == 0) {
                rl.drawLineEx(selLinePoints[i], selLinePoints[i + 1], (lineThickness + selBoarderThickness), colorParser(selBoarderColor));
            }
        }
    }
}
