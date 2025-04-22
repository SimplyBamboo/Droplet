-- This is a LocalScript (should go in StarterPlayerScripts or similar)

-- Define the path to your DrawingLib ModuleScript
-- Adjust this path based on where you saved the ModuleScript
local Drawing = require(game.ReplicatedStorage.DrawingLib)

local myLine = Drawing.new("Line", {
    From = Vector2.new(100, 100),
    To = Vector2.new(400, 200),
    Thickness = 3,
    Color = Color3.new(1, 0, 0), 
    Transparency = 0 
})

local myCircle = Drawing.new("Circle", {
    Position = Vector2.new(500, 600),
    Radius = 75,
    Color = Color3.new(1, 1, 0), 
    Filled = true,
    Transparency = 0.2 -
})

local mySquare = Drawing.new("Square", {
    Position = Vector2.new(150, 500),
    Size = Vector2.new(100, 100),
    Color = Color3.new(1, 0, 1), 
    Thickness = 4,
    Filled = false
})


-- --- Example 5: Drawing an Image ---
local IMAGE_ASSET_ID = "rbxassetid://0"
local myImage = Drawing.new("Image", {
    Position = Vector2.new(800, 200),
    Size = Vector2.new(150, 150),
    Color = Color3.new(1, 0.7, 0.7),
    myImage = Transparency = 0.3
    DataURL = IMAGE_ASSET_ID,
    Transparency = 0.5
})
