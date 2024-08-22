// VMS is built using raylib-zig (c) Nikolas Wipper 2023
// As well as using the zig language by Andrew Kelly
// Vardeltus Manufacturing Softare - Copyright (C) 2024 RetroGaming22\nThis program comes with ABSOLUTELY NO WARRANTY and this is free software; you are welcome to redistribute it under certain conditions. Look in the LICENSE file or visit https://www.gnu.org/licenses/#GPL for more details.

// Zig definitions
const std = @import("std");
const rl = @import("raylib");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn();

// Program variables
/// An object with two points
const Object2 = struct {
    /// The type of object (Rectangle, Line, Circle, etc)
    type: u8,
    /// The first point of the object
    p1: rl.Vector2,
    /// The second point of the object
    p2: rl.Vector2,
    /// The color of the object
    color: rl.Color,
    /// This exists so that I am able to determine if it has a color and then giving it one if it doesn't in the colorInterpolater
    colored: bool,
    /// Whether or not the object is selected
    selected: bool,
    /// A value used to mark p1 (and thus the object as a whole) to be overwritten
    overwrite: bool,
};

// This (objects being stored in an array) seems really bad, so I might change it to be done with more dynmaic memory allocation later.
/// Stores the points for objects
var objects: [128]Object2 = undefined;
/// Stores the number of entries in objects
var index: u8 = 0;
/// Keeps track of the current mode the user is in
var mode: u8 = defaultMode;

// User Defined values:
// Technically lineThickness can be f32 but I don't see why it would need to be above f16 (with a max value of 65.5k) and if it were to be higher then it might not work with drawSelLine when it adds it and selLineThickness together
/// The thickness of the lines that make up the objects
var lineThickness: f16 = 2;
/// The thickness of the selLines that make up the objects
const selLineThickness: f16 = 3;
/// The thickness of the grid lines
const gridLineThickness: f16 = 2;
/// The spacing between the lines of the grid in pixels.
const gridSpacing: u16 = 50;
/// The default color
const defaultColor: rl.Color = rl.Color.blue;
/// The color of the selected objects
const selColor: rl.Color = rl.Color.white;
/// The color of the grid lines
const gridColor: rl.Color = rl.Color.gray;
/// Clears screen
const clearKey: rl.KeyboardKey = rl.KeyboardKey.key_delete;
/// Removes last inputted object
const backKey: rl.KeyboardKey = rl.KeyboardKey.key_backspace;
/// The button used to select objects
const selButton: rl.MouseButton = rl.MouseButton.mouse_button_left;
/// The key used to disable deselecting temporarily
const holdSelKey: rl.KeyboardKey = rl.KeyboardKey.key_left_shift;
/// The key used to change your mode to draw lines
const lineModeKey: rl.KeyboardKey = rl.KeyboardKey.key_l;
/// The key used to change your mode to draw circle
const circleModeKey: rl.KeyboardKey = rl.KeyboardKey.key_c;
/// The key used to change your mode to select objects
const selectModeKey: rl.KeyboardKey = rl.KeyboardKey.key_space;
/// The key used to change your mode to draw rectangles
const rectangleModeKey: rl.KeyboardKey = rl.KeyboardKey.key_r;
/// The default mode if none is provided. l = line, c = circle, s = select, r = rectangle
const defaultMode: u8 = 'l';
/// The number of pixels that create an area where an object is considered selected if clicked
const selectionThreshold: i32 = 6;
/// Draws a grid if true
const grid: bool = true;
/// The size of the text displayed
const fontSize: i32 = 20;
/// The color of the text displayed
const fontColor: rl.Color = rl.Color.white;
/// If true, when removing last object, instead of carrying the last inputted color, the function will not change the order of the object colors.
// For example, if you had an orange and green line and was about to create a purple one, but you decided that the green line was not what you wanted. By default, it would make it so that you had the orange line and then the next object you made would be purple. With this setting set to true, the next object would be green, and then the one after that would be purple, which would then carry on until the next color is inputted.
const retainColors: bool = false;
/// Will deselect all objects currently selected.
const clearSelKey: rl.KeyboardKey = rl.KeyboardKey.key_backslash;
/// The alpha of the object preview color
const previewColorAlphaPercent: f32 = 60;
/// The object that you are about to draw
var previewObject: Object2 = undefined;

// Custom hardcoded values:
// The screen and display values will be figured out later, but now they are hardcoded.
const screenWidth = 1200;
const screenHeight = 600;

pub fn main() anyerror!void {
    // Initialization

    // Creates window
    rl.initWindow(screenWidth, screenHeight, "Vardeltus Manufacturing Software");

    // Disables esc from closing the program
    rl.setExitKey(rl.KeyboardKey.key_null);

    // Closes Window when finished
    defer rl.closeWindow();

    // Sets program to run at 60 FPS
    rl.setTargetFPS(60);

    // Main loop
    while (!rl.windowShouldClose()) {
        // Update

        // Gets current pressed key. You can't call the function mmiple times per frame so this is handy.
        const currentPressedKey: rl.KeyboardKey = rl.getKeyPressed();

        // Will change the mode if the user requests it and also displays the current mode in the bottom left corner
        modeChanger(currentPressedKey);

        // Sees if clear or back key were pressed respectfully and then does the respective actions if so.
        clearScreen();
        removeLastObject();

        // Checks to see if the user wants to change the object color and then stores it in the color field in the current object
        colorEncoder(currentPressedKey);

        // Clears the background to be drawn on.
        rl.clearBackground(rl.Color.black);

        // Draws a grid in the background if grid = true
        drawGrid();

        // Writes the points and type for objects and preview object; then increments the index
        try storeObjectPoints();

        // "Fills in" the colors that were not directly written - NTS: Make sure that this is called after storeObjectPoints because it messes with p1 in storeObjectsPooints.
        colorInterpolater();

        // Determines if any of the objects have been selected and marks them as so
        selObjects();

        // Begins raylib drawing
        rl.beginDrawing();
        // Waits to end it until we want to end the drawing
        defer rl.endDrawing();

        // Draws the objects
        drawObjects();
        // Draws the preview object
        drawObjectPreview();
    }
}

/// When the user inputs 1-9, the color will be stored in the current object and then the fact that it has been written to will also be written for the colorInterpolater
fn colorEncoder(key: rl.KeyboardKey) void {
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
            objects[index].color = rl.Color.black;
            objects[index].colored = true;
        },
        // Doesn't do anything if none of the keys are pressed.
        else => {},
    }
}

/// "Fills in" the colors that were not directly written
fn colorInterpolater() void {
    // Sets the first color to the default if none is provided by the user
    if (!objects[0].colored) {
        objects[0].color = defaultColor;
        objects[0].colored = true;
    }

    if (index >= 1) {
        // Goes through the objects and sets the color if it isn't colored already
        for (1..index) |i| {
            if (!objects[i].colored) {
                objects[i].color = objects[i - 1].color;
                objects[i].colored = true;
            }
        }
    }
    // Sets the preview object color to the last color but with a different alpha value
    if (objects[index].colored) {
        previewObject.color = rl.colorAlpha(objects[index].color, (previewColorAlphaPercent / 100));
    } else {
        previewObject.color = rl.colorAlpha(objects[index - 1].color, (previewColorAlphaPercent / 100));
    }
}

/// Clears the screen of all objects
fn clearScreen() void {
    if (rl.isKeyPressed(clearKey)) {
        for (0..index) |i| {
            objects[i].overwrite = true;
            objects[i].colored = false;
            objects[i].selected = false;
        }
        index = 0;
    }
}

/// Removes the last object
fn removeLastObject() void {
    if (rl.isKeyPressed(backKey) and index >= 1) {
        // Marks the last object to be overwritten
        objects[index - 1].overwrite = true;
        objects[index - 1].selected = false;

        if (retainColors) {
            // Tells the program that the object has been removed
            index -= 1;
            // Exits the function before the code that makes it so that the color is not retained is not run
            return;
        }

        // Sets the next color to be the last inputted color
        for (index..objects.len) |i| {
            if (objects[i].colored) objects[index - 1].color = objects[i].color;
        }
        // Removes all future colors
        for (index + 1..objects.len) |i| {
            objects[i].colored = false;
        }
        // Tells the program that the object has been removed
        index -= 1;
    }
}

/// Writes the points and type for the objects and preview object; then increments the index
fn storeObjectPoints() !void {
    // Stops program from storing points when user is in selection mode
    if (mode == 's') return;

    // A varible to avoid checking if objects.p1.x doesn't exist twice because zig makes it no longer undefined after it is checked
    var noP1: bool = undefined;
    if (objects[index].p1.x == undefined) noP1 = true else noP1 = false;

    // Displays a preview of the shape you are about to draw if the user already gave an input
    if (!noP1) {
        // Carries the first point to the next index value in order to avoid the issue of the object corresponding to the index value switching between the preview object and the last inputted object. (Which has issues with color)
        previewObject.p1 = objects[index].p1;
        // Sets the second point of the preview object to the current mouse position
        previewObject.p2 = rl.getMousePosition();
        // Sets the preview object type to the current mode
        previewObject.type = mode;
    }
    if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
        if (index == (objects.len - 1)) {
            // Debug statement telling the user if it is at max capacity
            try stdout.print("Input ignored. Index has reached max capacity ({d}).\n", .{index});
        } else {
            // Writes the first point if it doesn't exist or needs to be overwritten
            if (noP1 or objects[index].overwrite) {
                objects[index].p1 = rl.getMousePosition();
                objects[index].overwrite = false;
            } else {
                // Writes the second point and type before incrementing the index to tell the program that another object has been inputted
                objects[index].p2 = rl.getMousePosition();
                objects[index].type = mode;

                try stdout.print("p1: {d}, {d}\np2: {d}, {d}\n", .{ objects[index].p1.x, objects[index].p1.y, objects[index].p2.x, objects[index].p2.y });

                // Increments index
                index += 1;
                // Debug statement to tell the user what the index is
                try stdout.print("index is: {d}\n\n", .{index});
            }
        }
    }
}

/// Determines if any of the objects have been selected and marks them as so
fn selObjects() void {
    // If the user is not in selection mode, then this function will be ignored
    if (mode != 's') return;

    // If clearSelKey is pressed, then all objects will be unselected
    if (rl.isKeyDown(clearSelKey)) {
        for (0..index) |i| {
            objects[i].selected = false;
        }
    }
    // If the selButton is pressed and if there is a object, then it will check to see if anything was selected
    if (rl.isMouseButtonPressed(selButton) and index >= 1) {
        const currentPoint: rl.Vector2 = rl.getMousePosition();

        for (0..index) |i| {

            // This segment of code takes care of the assumptions that the latter end of this function makes about the relative positions of the rectangle points
            var P1X: f32 = undefined;
            var P1Y: f32 = undefined;
            var P2X: f32 = undefined;
            var P2Y: f32 = undefined;

            if (objects[i].p1.x < objects[i].p2.x) {
                P1X = objects[i].p1.x;
                P2X = objects[i].p2.x;
            } else {
                P1X = objects[i].p2.x;
                P2X = objects[i].p1.x;
            }

            if (objects[i].p1.y < objects[i].p2.y) {
                P1Y = objects[i].p1.y;
                P2Y = objects[i].p2.y;
            } else {
                P1Y = objects[i].p2.y;
                P2Y = objects[i].p1.y;
            }

            // Definitions for different dimensions or shapes used in the collision dectection.
            // Inner dimensions/shapes are used to ignore the collisions with the inside of the shape (since raylib checks for collisions with a filled shape)
            // Outer dimensions/shapes are the inverse of the inner ones and together they form an area that has similar "selection properties" as the line collisions
            const innerCircleRadius: f32 = rl.Vector2.distance(objects[i].p1, objects[i].p2) - selectionThreshold;
            const outerCircleRadius: f32 = rl.Vector2.distance(objects[i].p1, objects[i].p2) + selectionThreshold;
            const innerRecWidth: f32 = P2X - P1X - selectionThreshold * 2;
            const innerRecHeight: f32 = P2Y - P1Y - selectionThreshold * 2;
            const outerRecWidth: f32 = P2X - P1X + selectionThreshold * 2;
            const outerRecHeight: f32 = P2Y - P1Y + selectionThreshold * 2;

            const innerRec: rl.Rectangle = rl.Rectangle.init(P1X + selectionThreshold, P1Y + selectionThreshold, innerRecWidth, innerRecHeight);
            const outerRec: rl.Rectangle = rl.Rectangle.init(P1X - selectionThreshold, P1Y - selectionThreshold, outerRecWidth, outerRecHeight);

            // if there is a collision around an object then it is marked as being selected unless it is already selected and holdSelKey is not being held down
            if (rl.checkCollisionPointLine(currentPoint, objects[i].p1, objects[i].p2, selectionThreshold) and objects[i].type == 'l') {
                if (objects[i].selected and !rl.isKeyDown(holdSelKey)) {
                    objects[i].selected = false;
                } else {
                    objects[i].selected = true;
                }
            }
            if (rl.checkCollisionPointCircle(currentPoint, objects[i].p1, outerCircleRadius) and !rl.checkCollisionPointCircle(currentPoint, objects[i].p1, innerCircleRadius) and objects[i].type == 'c') {
                if (objects[i].selected and !rl.isKeyDown(holdSelKey)) {
                    objects[i].selected = false;
                } else {
                    objects[i].selected = true;
                }
            }
            if (rl.checkCollisionPointRec(currentPoint, outerRec) and !rl.checkCollisionPointRec(currentPoint, innerRec) and objects[i].type == 'r') {
                if (objects[i].selected and !rl.isKeyDown(holdSelKey)) {
                    objects[i].selected = false;
                } else {
                    objects[i].selected = true;
                }
            }
        }
    }
}

fn drawObjects() void {
    if (index >= 1) {
        for (0..index) |i| {
            // Draws the line objects
            if (objects[i].type == 'l') {
                rl.drawLineEx(objects[i].p1, objects[i].p2, lineThickness, objects[i].color);
            }

            // Draws the circle objects
            if (objects[i].type == 'c') {
                const center: rl.Vector2 = objects[i].p1;
                const radius: f32 = rl.Vector2.distance(objects[i].p1, objects[i].p2);

                rl.drawRing(center, radius - (lineThickness / 2), radius + (lineThickness / 2), 0, 360, 1, objects[i].color);
            }

            // Draws the rectangle objects
            if (objects[i].type == 'r') {
                var P1X: f32 = undefined;
                var P1Y: f32 = undefined;
                var P2X: f32 = undefined;
                var P2Y: f32 = undefined;

                if (objects[i].p1.x < objects[i].p2.x) {
                    P1X = objects[i].p1.x;
                    P2X = objects[i].p2.x;
                } else {
                    P1X = objects[i].p2.x;
                    P2X = objects[i].p1.x;
                }

                if (objects[i].p1.y < objects[i].p2.y) {
                    P1Y = objects[i].p1.y;
                    P2Y = objects[i].p2.y;
                } else {
                    P1Y = objects[i].p2.y;
                    P2Y = objects[i].p1.y;
                }
                const width: f32 = P2X - P1X;
                const height: f32 = P2Y - P1Y;

                rl.drawRectangleLinesEx(rl.Rectangle.init(P1X, P1Y, width, height), lineThickness, objects[i].color);
            }
            // Draws the selected line objects as being selected
            if (objects[i].selected and objects[i].type == 'l') {
                rl.drawLineEx(objects[i].p1, objects[i].p2, selLineThickness, selColor);
            }
            // Draws the selected circle objects as being selected
            if (objects[i].selected and objects[i].type == 'c') {
                const center: rl.Vector2 = objects[i].p1;
                const radius: f32 = rl.Vector2.distance(objects[i].p1, objects[i].p2);
                rl.drawRing(center, radius - (selLineThickness / 2), radius + (selLineThickness / 2), 0, 360, 1, selColor);
            }
            // Draws the selected rectangle objects as being selected
            if (objects[i].selected and objects[i].type == 'r') {
                var P1X: f32 = undefined;
                var P1Y: f32 = undefined;
                var P2X: f32 = undefined;
                var P2Y: f32 = undefined;

                if (objects[i].p1.x < objects[i].p2.x) {
                    P1X = objects[i].p1.x;
                    P2X = objects[i].p2.x;
                } else {
                    P1X = objects[i].p2.x;
                    P2X = objects[i].p1.x;
                }

                if (objects[i].p1.y < objects[i].p2.y) {
                    P1Y = objects[i].p1.y;
                    P2Y = objects[i].p2.y;
                } else {
                    P1Y = objects[i].p2.y;
                    P2Y = objects[i].p1.y;
                }
                const width: f32 = P2X - P1X;
                const height: f32 = P2Y - P1Y;

                rl.drawRectangleLinesEx(rl.Rectangle.init(P1X, P1Y, width, height), selLineThickness, selColor);
            }
        }
    }
}

fn drawObjectPreview() void {

    // Doesn't draw the preview object if user is in selection mode, if the current object was just removed, or if the user hasn't inputted the first point of the object (Otherwise when changing color you would notice that the last object changes color as the preview object is drawn above it)
    if (mode == 's' or objects[index].overwrite or (previewObject.p1.equals(objects[index].p1)) == 0) return;

    if (index >= 0) {
        // Draws the preview object as a line if it is one
        if (previewObject.type == 'l') {
            rl.drawLineEx(previewObject.p1, previewObject.p2, lineThickness, previewObject.color);
        }

        // Draws the preview object as a circle if it is one
        if (previewObject.type == 'c') {
            const center: rl.Vector2 = previewObject.p1;
            const radius: f32 = rl.Vector2.distance(previewObject.p1, previewObject.p2);

            rl.drawRing(center, radius - (lineThickness / 2), radius + (lineThickness / 2), 0, 360, 1, previewObject.color);
        }

        // Draws the preview object as a rectangle if it is one
        if (previewObject.type == 'r') {
            var P1X: f32 = undefined;
            var P1Y: f32 = undefined;
            var P2X: f32 = undefined;
            var P2Y: f32 = undefined;

            if (previewObject.p1.x < previewObject.p2.x) {
                P1X = previewObject.p1.x;
                P2X = previewObject.p2.x;
            } else {
                P1X = previewObject.p2.x;
                P2X = previewObject.p1.x;
            }

            if (previewObject.p1.y < previewObject.p2.y) {
                P1Y = previewObject.p1.y;
                P2Y = previewObject.p2.y;
            } else {
                P1Y = previewObject.p2.y;
                P2Y = previewObject.p1.y;
            }
            const width: f32 = P2X - P1X;
            const height: f32 = P2Y - P1Y;

            rl.drawRectangleLinesEx(rl.Rectangle.init(P1X, P1Y, width, height), lineThickness, previewObject.color);
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

    // Prepares start and end Pos for drawing the vertical lines
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

/// Will change the mode if the user requests it and also displays the current mode in the bottom left corner
fn modeChanger(key: rl.KeyboardKey) void {
    if (key == lineModeKey) mode = 'l';
    if (key == circleModeKey) mode = 'c';
    if (key == selectModeKey) mode = 's';
    if (key == rectangleModeKey) mode = 'r';

    // Display what the current mode is
    switch (mode) {
        'l' => {
            rl.drawText("Mode: Line", 0, screenHeight - fontSize, fontSize, fontColor);
        },
        'c' => {
            rl.drawText("Mode: Circle", 0, screenHeight - fontSize, fontSize, fontColor);
        },
        's' => {
            rl.drawText("Mode: Select", 0, screenHeight - fontSize, fontSize, fontColor);
        },
        'r' => {
            rl.drawText("Mode: Rectangle", 0, screenHeight - fontSize, fontSize, fontColor);
        },
        else => {},
    }
}
