// VMS is built using raylib-zig (c) Nikolas Wipper 202// raylib-zig (c) Nikolas Wipper 2023

// Zig definitions
const std = @import("std");
const rl = @import("raylib");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn();

/// Indexes and program variables::
// This (points being stored in an array) seems really bad, but I am not sure by how much or how to make it better at the mome.
// Stores the points for lines
var points: [128]rl.Vector2 = undefined;
// Stores the number of entries in points
var index: u8 = 0;
// Stores the index of selected lines.
var selLinePoints: [128]u9 = undefined;
// Stores the number of entries in selLinePoints
var selLineIndex: u8 = 0;
// Index-1 doesn't work for a slice, so I'll just store the last color value.
var previousColor: u5 = undefined;
// Stores the encoded colors of the lines
var colorIndex: [128]u5 = undefined;
// Technically lineThickness can be f32 but I don't see why it would need to be above f16 (with a max value of 65.5k) and if it were to be higher then it might not work with drawSelLine when it adds it and selBoarderThickness together
var lineThickness: f16 = 1;
// The thickness of the selLine
const selBoarderThickness: f16 = 2;

/// User Defined values:
// Color codes are found in the colorParser function.
const defaultColor: u5 = 5;
const selColor: u5 = 7;
// Clears screen.
const clearKey: rl.KeyboardKey = rl.KeyboardKey.key_delete;
// Removes last placed line.
const backKey: rl.KeyboardKey = rl.KeyboardKey.key_backspace;
// The button used to select objects
const selButton: rl.MouseButton = rl.MouseButton.mouse_button_right;
const holdSelKey: rl.KeyboardKey = rl.KeyboardKey.key_left_shift;
// The number of pixels that create an area where an object is considered selected if clicked
const selectionThreshold: i32 = 10;
const selLinesMoveAmount: u8 = 5;
const autoConnectLines: bool = true;

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
    colorIndex[0] = defaultColor;

    rl.initWindow(screenWidth, screenHeight, "Vardeltus Manufacturing Software");
    defer rl.closeWindow(); // Closes window

    rl.setTargetFPS(60); // Sets FPS to 60

    // Main loop
    while (!rl.windowShouldClose()) {
        // Update

        // Gets current pressed key. You can't call the function multiple times per frame so this is handy.
        const currentPressedKey: rl.KeyboardKey = rl.getKeyPressed();

        // Sees if clear or back key were pressed respectfully and then does the respective actions if so.
        clearScreen();
        removeLastLine();

        // Checks to see if the user wants to change the line color and then stores it in colorIndex
        colorEncoder(currentPressedKey);

        // Clears the background to be drawn on.
        rl.clearBackground(rl.Color.black);

        // Sees if user added a point and then stores the point data to points while incrementing index.
        try Lines();

        // Figure out is the user is pressing the selButton and is near a line where it will then store the value in selPoints.
        selectLines();

        // Checks to see if selLines should be moved and moves them
        try moveSelLines(currentPressedKey);

        // Begins raylib drawing
        rl.beginDrawing();
        // Waits to end it until we want to end the drawing
        defer rl.endDrawing();

        // Draws lines if there are enough points
        try drawLines();
        // if there are selLinePoints, it will draw the selLines
        drawSelLines();
        if (rl.isMouseButtonPressed(selButton)) {
            try stdout.print("SLP: {d}\n\n", .{selLinePoints});
        }
    }
}

//When the user inputs 1-9 that value will be stored in the future entry (index - 1 because of fun incrementing variables stuff.) of the colorIndex (so that the color of the line you are about to create is changed and not the past line.)
fn colorEncoder(key: rl.KeyboardKey) void {
    switch (key) {
        rl.KeyboardKey.key_one => {
            colorIndex[index - 1] = 1;
        },
        rl.KeyboardKey.key_two => {
            colorIndex[index - 1] = 2;
        },
        rl.KeyboardKey.key_three => {
            colorIndex[index - 1] = 3;
        },
        rl.KeyboardKey.key_four => {
            colorIndex[index - 1] = 4;
        },
        rl.KeyboardKey.key_five => {
            colorIndex[index - 1] = 5;
        },
        rl.KeyboardKey.key_six => {
            colorIndex[index - 1] = 6;
        },
        rl.KeyboardKey.key_seven => {
            colorIndex[index - 1] = 7;
        },
        rl.KeyboardKey.key_eight => {
            colorIndex[index - 1] = 8;
        },
        rl.KeyboardKey.key_nine => {
            colorIndex[index - 1] = 9;
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

// Clears screen of all of the points
fn clearScreen() void {
    if (rl.isKeyPressed(clearKey)) {
        points = undefined;
        previousColor = undefined;
        colorIndex = undefined;
        index = 0;
        colorIndex[0] = defaultColor;
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
            // This exists because I can't figure out how to stop drawLines from drawing an extra invisible line to 0,0 after the regular lines (which is noticable when you try to select in that general area)
            points[index + 1] = rl.getMousePosition();

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
        for (0..index) |i| {

            // Defintions for the first stored point, second stored point, and mouse position.
            const point1: rl.Vector2 = points[i];
            const point2: rl.Vector2 = points[i + 1];
            const currentPoint: rl.Vector2 = rl.getMousePosition();
            // Checks to see if the points to see if they have been selected.
            if (rl.checkCollisionPointLine(currentPoint, point1, point2, selectionThreshold)) {
                //Stores selLinePoints and then increments the respective index.

                selLinePoints[selLineIndex] = @intCast(i);
                selLinePoints[selLineIndex + 1] = @intCast(i + 1);
                selLineIndex += 2;
            }
        }
    }
}

// Draws lines if there are enough points
fn drawLines() !void {
    // This makes sure that there are enough points to draw a line
    if (index >= 2) {
        for (0..(index - 1)) |i| {
            // If autoConnectLines is set to false then it will not draw the connecting lines.
            if (!autoConnectLines and i % 2 != 0) break;
            // This draws the lines
            rl.drawLineEx(points[i], points[i + 1], lineThickness, colorParser(colorIndex[i]));
        }
    }
}

// if there are selLinePoints, it will draw the selLines
fn drawSelLines() void {
    if (selLineIndex >= 2) {
        for (0..selLineIndex) |i| {
            if (i % 2 == 0) {
                const point1: rl.Vector2 = points[selLinePoints[i]];
                const point2: rl.Vector2 = points[selLinePoints[i + 1]];
                rl.drawLineEx(point1, point2, (lineThickness + selBoarderThickness), colorParser(selColor));
            }
        }
    }
}

// Checks to see if selLines should be moved and moves them
fn moveSelLines(key: rl.KeyboardKey) !void {
    // Makes sure that there are selLines
    if (selLineIndex >= 2) {
        // Only works on selLine pairs
        for (0..selLineIndex) |i| {
            var selPoint = points[selLinePoints[i]];
            if (i % 2 == 0) {
                switch (key) {
                    rl.KeyboardKey.key_left => {
                        selPoint.x -= selLinesMoveAmount;
                        try stdout.print("Tried to move selPoint left\n", .{});
                    },
                    rl.KeyboardKey.key_right => {
                        selPoint.x += selLinesMoveAmount;
                    },
                    rl.KeyboardKey.key_down => {
                        selPoint.y -= selLinesMoveAmount;
                    },
                    rl.KeyboardKey.key_up => {
                        selPoint.y += selLinesMoveAmount;
                    },
                    rl.KeyboardKey.key_q => try stdout.print("Well This works\n", .{}),
                    else => {},
                }
            }
        }
    }
}
