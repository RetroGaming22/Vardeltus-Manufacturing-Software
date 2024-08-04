// VMS is built using raylib-zig (c) Nikolas Wipper 2023
// As well as using the zig language by Andrew Kelly

// Zig definitions
const std = @import("std");
const rl = @import("raylib");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn();

// Program variables
/// An object with two points
const Object2 = struct {
    type: u8,
    p1: rl.Vector2,
    p2: rl.Vector2,
    color: rl.Color,
    // This exists so that I am able to determine if it has a color and then giving it one if it doesn't in the colorInterpolater
    colored: bool,
    selected: bool,
    // A value used to mark p1 to be overwritten
    overwrite: bool,
};

// This (points being stored in an array) seems really bad, but I am not sure by how much or how to make it better at the mome.
/// Stores the points for lines
var objects: [128]Object2 = undefined;
/// Stores the number of entries in objects
var index: u8 = 0;

// User Defined values:
// Technically lineThickness can be f32 but I don't see why it would need to be above f16 (with a max value of 65.5k) and if it were to be higher then it might not work with drawSelLine when it adds it and selBoarderThickness together
/// The thickness of the lines
var lineThickness: f16 = 1;
/// The thickness of the selLine
const selBoarderThickness: f16 = 2;
/// The thickness of the grid lines
const gridLineThickness: f16 = 2;
/// The spacing between the lines of the grid in pixels.
const gridSpacing: u16 = 50;
/// The default color
const defaultColor: rl.Color = rl.Color.blue;
/// The color of the selected lines
const selColor: rl.Color = rl.Color.white;
/// The color of the grid lines
const gridColor: rl.Color = rl.Color.gray;
/// Clears screen.
const clearKey: rl.KeyboardKey = rl.KeyboardKey.key_delete;
/// Removes last placed line.
const backKey: rl.KeyboardKey = rl.KeyboardKey.key_backspace;
/// The button used to select objects
const selButton: rl.MouseButton = rl.MouseButton.mouse_button_right;
/// The key used to "maintain" your selection in order to select multiple lines which may not be close together
const holdSelKey: rl.KeyboardKey = rl.KeyboardKey.key_left_shift;
/// The number of pixels that create an area where an object is considered selected if clicked
const selectionThreshold: i32 = 10;
// Draws a grid with selLinesMoveAmount spacing
const grid: bool = true;

// Custom hardcoded values:
/// A clear "color"
const clear: rl.Color = rl.Color.init(0, 0, 0, 0);
// The screen and display values will be figured out later, but now they are hardcoded.
const screenWidth = 1200;
const screenHeight = 600;

pub fn main() anyerror!void {
    // Initialization
    rl.initWindow(screenWidth, screenHeight, "Vardeltus Manufacturing Software");
    // Closes Window when finished
    defer rl.closeWindow();

    // Sets FPS to 60
    rl.setTargetFPS(60);

    // Main loop
    while (!rl.windowShouldClose()) {
        // Update

        // Gets current pressed key. You can't call the function multiple times per frame so this is handy.
        const currentPressedKey: rl.KeyboardKey = rl.getKeyPressed();

        // Sees if clear or back key were pressed respectfully and then does the respective actions if so.
        ClearScreen();
        RemoveLastLine();

        // Checks to see if the user wants to change the line color and then stores it in colorIndex
        ColorEncoder(currentPressedKey);

        // Clears the background to be drawn on.
        rl.clearBackground(rl.Color.black);

        // Draws a grid in the background if grid = true
        drawGrid();

        // Writes the points for line objectsand then increments the index
        try Lines();

        // Determines if any of the lines have been selected and marks them as so
        SelLines();

        // "Fills in" the colors that were not directly written
        ColorInterpolater();

        // Begins raylib drawing
        rl.beginDrawing();
        // Waits to end it until we want to end the drawing
        defer rl.endDrawing();

        // Draws the line objects
        DrawLines();

        // Draws the selected line objects as being selected
        DrawSelLines();
    }
}

/// When the user inputs 1-9, the color will be stored in the current object and then the fact that it has been written to will also be written for the colorInterpolater
fn ColorEncoder(key: rl.KeyboardKey) void {
    switch (key) {
        rl.KeyboardKey.key_one => {
            objects[index].color = rl.Color.red;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_two => {
            objects[index].color = rl.Color.orange;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_three => {
            objects[index].color = rl.Color.yellow;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_four => {
            objects[index].color = rl.Color.green;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_five => {
            objects[index].color = rl.Color.blue;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_six => {
            objects[index].color = rl.Color.purple;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_seven => {
            objects[index].color = rl.Color.white;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_eight => {
            objects[index].color = rl.Color.gray;
            objects[index].colored = true;
        },
        rl.KeyboardKey.key_nine => {
            objects[index].color = clear;
            objects[index].colored = true;
        },
        // Doesn't do anything if none of the keys are pressed.
        else => {},
    }
}

/// "Fills in" the colors that were not directly written
fn ColorInterpolater() void {
    if (index >= 1) {
        if (!objects[0].colored) objects[0].color = defaultColor;
        for (1..index) |i| {
            if (!objects[i].colored) {
                objects[i].color = objects[i - 1].color;
            }
        }
    }
}

/// Clears the screen of all objects
fn ClearScreen() void {
    if (rl.isKeyPressed(clearKey)) {
        for (0..index) |i| {
            objects[i].overwrite = true;
            objects[i].color = defaultColor;
        }
        index = 0;
    }
}

/// Removes the last object
fn RemoveLastLine() void {
    if (rl.isKeyPressed(backKey) and index >= 1) {
        index -= 1;
        objects[index].overwrite = true;
        objects[index].color = defaultColor;
    }
}

/// Writes the points for line objectsand then increments the index
fn Lines() !void {
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        if (index == (objects.len - 1)) {
            // Debug statement telling the user if it is at max capacity
            try stdout.print("Input ignored. Index has reached max capacity ({d}).\n", .{index});
        } else {
            if (objects[index].p1.x == undefined or objects[index].overwrite) {
                objects[index].p1 = rl.getMousePosition();
                objects[index].overwrite = false;
            } else {
                objects[index].p2 = rl.getMousePosition();
                objects[index].type = 'l';

                try stdout.print("p1: {d}, {d}\np2: {d}, {d}\n\n", .{ objects[index].p1.x, objects[index].p1.y, objects[index].p2.x, objects[index].p2.y });

                // Increments index
                index += 1;
                // Debug statement to tell the user what the index is
                try stdout.print("index is: {d}\n", .{index});
            }
        }
    }
}

/// Determines if any of the lines have been selected and marks them as so
fn SelLines() void {
    if (rl.isMouseButtonPressed(selButton) and index >= 1) {
        const currentPoint: rl.Vector2 = rl.getMousePosition();
        if (!rl.isKeyDown(holdSelKey)) {
            for (0..index) |i| {
                objects[i].selected = false;
            }
        }
        for (0..index) |i| {
            if (rl.checkCollisionPointLine(currentPoint, objects[i].p1, objects[i].p2, selectionThreshold)) {
                objects[i].selected = true;
            }
        }
    }
}

/// Draws the line objects
fn DrawLines() void {
    if (index >= 1) {
        for (0..index) |i| {
            if (objects[i].type == 'l') {
                rl.drawLineEx(objects[i].p1, objects[i].p2, lineThickness, objects[i].color);
            }
        }
    }
}

/// Draws the selected line objects as being selected
fn DrawSelLines() void {
    if (index >= 1) {
        for (0..index) |i| {
            if (objects[i].selected and objects[i].type == 'l') {
                rl.drawLineEx(objects[i].p1, objects[i].p2, (lineThickness + selBoarderThickness), selColor);
            }
        }
    }
}

/// Draws a grid in the background if grid = true
fn drawGrid() void {
    // Stops the grid from being drawn if grid is false
    if (!grid) return;

    var startPos: rl.Vector2 = undefined;
    var endPos: rl.Vector2 = undefined;
    // The number of vertical grid lines
    const gridLineNumH: u16 = @truncate(screenHeight / gridSpacing);
    // The number of vertical grid lines
    const gridLineNumV: u16 = @truncate(screenWidth / gridSpacing);

    // prepares start and end Pos for drawing the vertical lines
    startPos.x = 0;
    endPos.x = screenWidth;
    // Draws the vertical lines
    for (0..gridLineNumH) |_| {
        rl.drawLineEx(startPos, endPos, gridLineThickness, gridColor);
        startPos.y += gridSpacing;
        endPos.y += gridSpacing;
    }

    // Resets the endPos's x cord
    endPos.x = 0;

    // prepares start and end Pos for drawing the horizontal lines
    startPos.y = 0;
    endPos.y = screenHeight;
    // Draws the vertical lines
    for (0..gridLineNumV) |_| {
        rl.drawLineEx(startPos, endPos, gridLineThickness, gridColor);
        startPos.x += gridSpacing;
        endPos.x += gridSpacing;
    }
}
