--!strict
-- Solara Drawing Lib (Refactored as Module)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService") -- Needed for Camera updates if drawing needs to follow 3D objects (not implemented here, but good practice)
local Camera = workspace.CurrentCamera

-- Ensure a ScreenGui exists in CoreGui for drawing
-- Note: Accessing CoreGui is often restricted to specific contexts (e.g., exploits).
-- For standard game development, parenting to PlayerGui is more common.
local drawingUI = CoreGui:FindFirstChild("DrawingScreenGui")
if not drawingUI then
    drawingUI = Instance.new("ScreenGui")
    drawingUI.Name = "DrawingScreenGui"
    drawingUI.IgnoreGuiInset = true
    drawingUI.DisplayOrder = 0x7fffffff -- Render on top
    drawingUI.Parent = CoreGui
end

-- Utility Functions
local function convertTransparency(transparency: number): number
    -- Converts a 0 (opaque) to 1 (transparent) range to Roblox's 0 (opaque) to 1 (transparent) range
    -- Note: This function is actually mapping transparency the same way Roblox does,
    -- so 1 - transparency isn't strictly necessary based on the original code's usage,
    -- but keeping it as per the original logic.
    return math.clamp(1 - transparency, 0, 1)
end

local function getFontFromIndex(fontIndex: number): Font
    local drawingFontsEnum = {
        [0] = Font.fromEnum(Enum.Font.Roboto), -- Corresponds to original "UI"
        [1] = Font.fromEnum(Enum.Font.Legacy), -- Corresponds to original "System"
        [2] = Font.fromEnum(Enum.Font.SourceSans), -- Corresponds to original "Plex" - assuming SourceSansSemiBold is a good match for Plex
        [3] = Font.fromEnum(Enum.Font.RobotoMono), -- Corresponds to original "Monospace"
    }
    return drawingFontsEnum[fontIndex] or drawingFontsEnum[0] -- Default to Roboto if index is invalid
end

-- Base Drawing Object Metatable
-- Provides common properties and methods
local baseDrawingMetatable = {
    __index = function(self, index)
        -- Default __index access to the internal properties table
        return rawget(self, "_properties")[index]
    end,
    __newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then -- Only allow setting predefined properties
            properties[index] = value
            -- Specific update logic will be handled by the individual drawing type's __newindex
            -- This base one just updates the internal table.
        end
    end,
    __tostring = function()
        return "DrawingObject"
    end
}

-- Common update logic for visual properties
local function updateVisualProperties(instance: GuiObject, properties: table)
    if properties.Visible ~= nil then instance.Visible = properties.Visible end
    if properties.ZIndex ~= nil then instance.ZIndex = properties.ZIndex end
    if properties.Transparency ~= nil then
        local transparency = convertTransparency(properties.Transparency)
        -- Apply transparency to appropriate properties based on instance type
        if instance:IsA("ImageLabel") then
            instance.ImageTransparency = transparency
        elseif instance:IsA("TextLabel") then
            instance.TextTransparency = transparency
            -- Assuming UIStroke transparency should match text transparency
            local uiStroke = instance:FindFirstChildWhichIsA("UIStroke")
            if uiStroke then uiStroke.Transparency = transparency end
        else -- Frame, etc.
            instance.BackgroundTransparency = transparency
        end
    end
    if properties.Color ~= nil then
        -- Apply color to appropriate properties based on instance type
        if instance:IsA("ImageLabel") then
            instance.ImageColor3 = properties.Color
        elseif instance:IsA("TextLabel") then
            instance.TextColor3 = properties.Color
            -- Assuming UIStroke color should match text color if not explicitly set
            local uiStroke = instance:FindFirstChildWhichIsA("UIStroke")
            if uiStroke and rawget(properties, "_uiStrokeColorManaged") then
                 uiStroke.Color = properties.Color
            end
        else -- Frame, etc.
            instance.BackgroundColor3 = properties.Color
            -- Assuming UIStroke color should match background color if not explicitly set
             local uiStroke = instance:FindFirstChildWhichIsA("UIStroke")
            if uiStroke and rawget(properties, "_uiStrokeColorManaged") then
                 uiStroke.Color = properties.Color
            end
        end
    end
end


-- Creator Functions for each Drawing Type
local function createLine(properties: table): table
    local lineObj = {
        _properties = {
            From = properties.From or Vector2.zero,
            To = properties.To or Vector2.zero,
            Thickness = properties.Thickness or 1,
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white
        },
        _instance = Instance.new("Frame"),
    }

    local lineFrame = lineObj._instance
    lineFrame.Name = "Drawing_Line" -- Use a descriptive name
    lineFrame.AnchorPoint = Vector2.new(0, 0.5) -- Anchor point at the start of the line
    lineFrame.BorderSizePixel = 0
    lineFrame.Parent = drawingUI

    -- Function to update the visual line based on From, To, and Thickness
    local function updateLineVisuals()
        local from = lineObj._properties.From
        local to = lineObj._properties.To
        local thickness = lineObj._properties.Thickness

        local direction = to - from
        local distance = direction.Magnitude
        local angle = math.deg(math.atan2(direction.Y, direction.X))

        lineFrame.Position = UDim2.fromOffset(from.X, from.Y)
        lineFrame.Size = UDim2.fromOffset(distance, thickness)
        lineFrame.Rotation = angle
    end

    -- Set initial properties
    updateLineVisuals()
    updateVisualProperties(lineFrame, lineObj._properties)

    -- Metatable for the Line object
    local lineMetatable = setmetatable({}, baseDrawingMetatable)
    lineMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then
            properties[index] = value
            if index == "From" or index == "To" or index == "Thickness" then
                updateLineVisuals()
            elseif index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" then
                 updateVisualProperties(lineFrame, properties)
            end
        end
    end
    lineMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                lineFrame:Destroy()
                setmetatable(self, nil) -- Remove metatable to potentially help GC
            end
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(lineObj, lineMetatable)
end

local function createText(properties: table): table
    local textObj = {
        _properties = {
            Text = properties.Text or "",
            Font = properties.Font or 0, -- Index into the font table
            Size = properties.Size or 14,
            Position = properties.Position or Vector2.zero,
            Center = properties.Center or false,
            Outline = properties.Outline or false,
            OutlineColor = properties.OutlineColor or Color3.new(0, 0, 0), -- Default black outline
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white text
            _uiStrokeColorManaged = true -- Internal flag to manage UIStroke color with main Color
        },
        _instance = Instance.new("TextLabel"),
        _uiStroke = Instance.new("UIStroke")
    }

    local textLabel = textObj._instance
    local uiStroke = textObj._uiStroke

    textLabel.Name = "Drawing_Text" -- Use a descriptive name
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5) -- Center the text label
    textLabel.BorderSizePixel = 0
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = false -- Ensure TextSize property is used

    uiStroke.Thickness = 1
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Apply stroke to the border

    textLabel.Parent = drawingUI
    uiStroke.Parent = textLabel

    local function updateTextVisuals()
        local props = textObj._properties
        textLabel.Text = props.Text
        textLabel.FontFace = getFontFromIndex(props.Font)
        textLabel.TextSize = props.Size
        uiStroke.Enabled = props.Outline
        uiStroke.Color = props.OutlineColor -- Use specific OutlineColor for stroke

        -- Update position based on Center property and TextBounds
        local textBounds = textLabel.TextBounds
        local position = props.Position
        local offset = textBounds / 2

        if props.Center then
            -- If centered, position relative to the center of the text bounds
             textLabel.Position = UDim2.fromOffset(position.X + offset.X, position.Y + offset.Y)
        else
            -- If not centered, position is the top-left corner, adjust by half bounds for center anchor
            textLabel.Position = UDim2.fromOffset(position.X + offset.X, position.Y + offset.Y)
        end
        textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y) -- Size the label to text bounds
    end

    -- Connect to TextBounds changes to update position/size
    textLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateTextVisuals)

    -- Set initial properties
    updateTextVisuals()
    updateVisualProperties(textLabel, textObj._properties)


    -- Metatable for the Text object
    local textMetatable = setmetatable({}, baseDrawingMetatable)
    textMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then
            properties[index] = value
            if index == "Text" or index == "Font" or index == "Size" or index == "Position" or index == "Center" or index == "Outline" or index == "OutlineColor" then
                 updateTextVisuals() -- Re-calculate text bounds and position
            elseif index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" then
                 updateVisualProperties(textLabel, properties)
            end
        end
    end
    textMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                textLabel:Destroy()
                setmetatable(self, nil) -- Remove metatable
            end
        elseif index == "TextBounds" then
            return textLabel.TextBounds
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(textObj, textMetatable)
end

local function createCircle(properties: table): table
    local circleObj = {
        _properties = {
            Radius = properties.Radius or 150,
            Position = properties.Position or Vector2.zero,
            Thickness = properties.Thickness or 0.7,
            Filled = properties.Filled or false,
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white
            _uiStrokeColorManaged = true -- Internal flag to manage UIStroke color with main Color
        },
        _instance = Instance.new("Frame"),
        _uiCorner = Instance.new("UICorner"),
        _uiStroke = Instance.new("UIStroke")
    }

    local circleFrame = circleObj._instance
    local uiCorner = circleObj._uiCorner
    local uiStroke = circleObj._uiStroke

    circleFrame.Name = "Drawing_Circle" -- Use a descriptive name
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Center the frame
    circleFrame.BorderSizePixel = 0

    uiCorner.CornerRadius = UDim.new(1, 0) -- Make it a circle

    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- Apply stroke to the border

    circleFrame.Parent = drawingUI
    uiCorner.Parent = circleFrame
    uiStroke.Parent = circleFrame

    local function updateCircleVisuals()
        local props = circleObj._properties
        local diameter = props.Radius * 2
        circleFrame.Size = UDim2.fromOffset(diameter, diameter)
        circleFrame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
        uiStroke.Thickness = math.clamp(props.Thickness, 0.6, math.huge) -- Ensure thickness is at least 0.6
        uiStroke.Enabled = not props.Filled
        circleFrame.BackgroundTransparency = (props.Filled and convertTransparency(props.Transparency)) or 1 -- Background only visible if filled
    end

    -- Set initial properties
    updateCircleVisuals()
    updateVisualProperties(circleFrame, circleObj._properties)
    uiStroke.Color = circleObj._properties.Color -- Explicitly set stroke color initially


    -- Metatable for the Circle object
    local circleMetatable = setmetatable({}, baseDrawingMetatable)
    circleMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then
            properties[index] = value
            if index == "Radius" or index == "Position" or index == "Thickness" or index == "Filled" then
                updateCircleVisuals()
            elseif index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" then
                 updateVisualProperties(circleFrame, properties)
            end
        end
    end
    circleMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                circleFrame:Destroy()
                setmetatable(self, nil) -- Remove metatable
            end
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(circleObj, circleMetatable)
end

local function createSquare(properties: table): table
     local squareObj = {
        _properties = {
            Size = properties.Size or Vector2.zero,
            Position = properties.Position or Vector2.zero,
            Thickness = properties.Thickness or 0.7,
            Filled = properties.Filled or false,
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white
             _uiStrokeColorManaged = true -- Internal flag to manage UIStroke color with main Color
        },
        _instance = Instance.new("Frame"),
        _uiStroke = Instance.new("UIStroke")
    }

    local squareFrame = squareObj._instance
    local uiStroke = squareObj._uiStroke

    squareFrame.Name = "Drawing_Square" -- Use a descriptive name
    squareFrame.BorderSizePixel = 0

    uiStroke.LineJoinMode = Enum.LineJoinMode.Miter -- Sharp corners for square stroke

    squareFrame.Parent = drawingUI
    uiStroke.Parent = squareFrame

    local function updateSquareVisuals()
        local props = squareObj._properties
        squareFrame.Size = UDim2.fromOffset(props.Size.X, props.Size.Y)
        squareFrame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
        uiStroke.Thickness = math.clamp(props.Thickness, 0.6, math.huge) -- Ensure thickness is at least 0.6
        uiStroke.Enabled = not props.Filled
        squareFrame.BackgroundTransparency = (props.Filled and convertTransparency(props.Transparency)) or 1 -- Background only visible if filled
    end

    -- Set initial properties
    updateSquareVisuals()
    updateVisualProperties(squareFrame, squareObj._properties)
    uiStroke.Color = squareObj._properties.Color -- Explicitly set stroke color initially

    -- Metatable for the Square object
    local squareMetatable = setmetatable({}, baseDrawingMetatable)
    squareMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then
            properties[index] = value
             if index == "Size" or index == "Position" or index == "Thickness" or index == "Filled" then
                updateSquareVisuals()
            elseif index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" then
                 updateVisualProperties(squareFrame, properties)
            end
        end
    end
    squareMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                squareFrame:Destroy()
                setmetatable(self, nil) -- Remove metatable
            end
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(squareObj, squareMetatable)
end

local function createImage(properties: table): table
     local imageObj = {
        _properties = {
            Data = properties.Data, -- Not fully implemented in original, keeping placeholder
            DataURL = properties.DataURL or "rbxassetid://0", -- Image Asset Id
            Size = properties.Size or Vector2.zero,
            Position = properties.Position or Vector2.zero,
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white tint
        },
        _instance = Instance.new("ImageLabel")
    }

    local imageFrame = imageObj._instance

    imageFrame.Name = "Drawing_Image" -- Use a descriptive name
    imageFrame.BorderSizePixel = 0
    imageFrame.ScaleType = Enum.ScaleType.Stretch
    imageFrame.BackgroundTransparency = 1 -- Make background transparent

    imageFrame.Parent = drawingUI

    local function updateImageVisuals()
        local props = imageObj._properties
        imageFrame.Image = props.DataURL
        imageFrame.Size = UDim2.fromOffset(props.Size.X, props.Size.Y)
        imageFrame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
    end

    -- Set initial properties
    updateImageVisuals()
    updateVisualProperties(imageFrame, imageObj._properties)

    -- Metatable for the Image object
    local imageMetatable = setmetatable({}, baseDrawingMetatable)
    imageMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
        if properties[index] ~= nil then
            properties[index] = value
             if index == "DataURL" or index == "Size" or index == "Position" then
                updateImageVisuals()
            elseif index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" then
                 updateVisualProperties(imageFrame, properties)
            end
        end
    end
    imageMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                imageFrame:Destroy()
                setmetatable(self, nil) -- Remove metatable
            end
         elseif index == "Data" then
            warn("DrawingLib: 'Data' property for Image is not yet implemented.")
            return nil
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(imageObj, imageMetatable)
end

local function createQuad(properties: table): table
    local quadObj = {
        _properties = {
            Thickness = properties.Thickness or 1,
            PointA = properties.PointA or Vector2.new(),
            PointB = properties.PointB or Vector2.new(),
            PointC = properties.PointC or Vector2.new(),
            PointD = properties.PointD or Vector2.new(),
            Filled = properties.Filled or false, -- Not fully implemented
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white
        },
        -- Quads are composed of 4 lines
        _lines = {
            LineAB = createLine({}),
            LineBC = createLine({}),
            LineCD = createLine({}),
            LineDA = createLine({})
        }
    }

    local function updateQuadLines()
        local props = quadObj._properties
        local lines = quadObj._lines

        lines.LineAB.From = props.PointA
        lines.LineAB.To = props.PointB

        lines.LineBC.From = props.PointB
        lines.LineBC.To = props.PointC

        lines.LineCD.From = props.PointC
        lines.LineCD.To = props.PointD

        lines.LineDA.From = props.PointD
        lines.LineDA.To = props.PointA

        -- Apply common properties to all lines
        for _, line in pairs(lines) do
            line.Thickness = props.Thickness
            line.Visible = props.Visible
            line.ZIndex = props.ZIndex
            line.Transparency = props.Transparency
            line.Color = props.Color
        end

        if props.Filled then
             -- Filling a quad requires a different approach (e.g., a polygon mesh or multiple frames)
             -- This is complex and left unimplemented as in the original.
             warn("DrawingLib: Filled Quads are not yet implemented.")
        end
    end

     -- Set initial properties
    updateQuadLines()


    -- Metatable for the Quad object
    local quadMetatable = setmetatable({}, baseDrawingMetatable)
    quadMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
         if properties[index] ~= nil then
            properties[index] = value
            -- Update all lines when relevant properties change
             if index == "Thickness" or index == "PointA" or index == "PointB" or index == "PointC" or index == "PointD" or index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" or index == "Filled" then
                updateQuadLines()
            end
         end
    end
    quadMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                -- Destroy all component lines
                for _, line in pairs(rawget(self, "_lines")) do
                    line:Destroy()
                end
                 setmetatable(self, nil) -- Remove metatable
            end
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(quadObj, quadMetatable)
end

local function createTriangle(properties: table): table
    local triangleObj = {
        _properties = {
            PointA = properties.PointA or Vector2.zero,
            PointB = properties.PointB or Vector2.zero,
            PointC = properties.PointC or Vector2.zero,
            Thickness = properties.Thickness or 1,
            Filled = properties.Filled or false, -- Not fully implemented
            Visible = properties.Visible ~= nil and properties.Visible or true,
            ZIndex = properties.ZIndex or 0,
            Transparency = properties.Transparency or 1,
            Color = properties.Color or Color3.new(1, 1, 1), -- Default white
        },
         -- Triangles are composed of 3 lines
        _lines = {
            LineAB = createLine({}),
            LineBC = createLine({}),
            LineCA = createLine({})
        }
    }

    local function updateTriangleLines()
         local props = triangleObj._properties
        local lines = triangleObj._lines

        lines.LineAB.From = props.PointA
        lines.LineAB.To = props.PointB

        lines.LineBC.From = props.PointB
        lines.LineBC.To = props.PointC

        lines.LineCA.From = props.PointC
        lines.LineCA.To = props.PointA

        -- Apply common properties to all lines
        for _, line in pairs(lines) do
            line.Thickness = props.Thickness
            line.Visible = props.Visible
            line.ZIndex = props.ZIndex
            line.Transparency = props.Transparency
            line.Color = props.Color
        end

         if props.Filled then
             -- Filling a triangle requires a different approach (e.g., a polygon mesh or multiple frames)
             -- This is complex and left unimplemented as in the original.
             warn("DrawingLib: Filled Triangles are not yet implemented.")
        end
    end

     -- Set initial properties
    updateTriangleLines()


    -- Metatable for the Triangle object
    local triangleMetatable = setmetatable({}, baseDrawingMetatable)
     triangleMetatable.__newindex = function(self, index, value)
        local properties = rawget(self, "_properties")
         if properties[index] ~= nil then
            properties[index] = value
             -- Update all lines when relevant properties change
             if index == "Thickness" or index == "PointA" or index == "PointB" or index == "PointC" or index == "Visible" or index == "ZIndex" or index == "Transparency" or index == "Color" or index == "Filled" then
                updateTriangleLines()
            end
         end
    end
     triangleMetatable.__index = function(self, index)
        if index == "Remove" or index == "Destroy" then
            return function()
                -- Destroy all component lines
                for _, line in pairs(rawget(self, "_lines")) do
                    line:Destroy()
                end
                 setmetatable(self, nil) -- Remove metatable
            end
        end
        return baseDrawingMetatable.__index(self, index)
    end

    return setmetatable(triangleObj, triangleMetatable)
end


-- The main Drawing Library Module
local DrawingLib = {}

-- Expose the font mapping
DrawingLib.Fonts = {
    ["UI"] = 0,
    ["System"] = 1,
    ["Plex"] = 2, -- Mapping to SourceSansSemiBold
    ["Monospace"] = 3
}

-- The main factory function
function DrawingLib.new(drawingType: string, properties: table): table
    local lowerType = string.lower(drawingType)

    if lowerType == "line" then
        return createLine(properties or {})
    elseif lowerType == "text" then
        return createText(properties or {})
    elseif lowerType == "circle" then
        return createCircle(properties or {})
    elseif lowerType == "square" then
        return createSquare(properties or {})
    elseif lowerType == "image" then
        return createImage(properties or {})
    elseif lowerType == "quad" then
        return createQuad(properties or {})
    elseif lowerType == "triangle" then
        return createTriangle(properties or {})
    else
        warn(`DrawingLib: Unknown drawing type "{drawingType}". Supported types: Line, Text, Circle, Square, Image, Quad, Triangle`)
        return {} -- Return an empty table for unknown types
    end
end

-- Clean up the drawing UI when the script is destroyed
script.AncestryChanged:Connect(function()
    if not script.Parent then
        if drawingUI and drawingUI.Parent == CoreGui then
            drawingUI:Destroy()
        end
    end
end)

-- Return the module
return DrawingLib