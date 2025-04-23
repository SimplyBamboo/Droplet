--💦 Droplet | V1.1 | Main - Refactored - FPS, Watermark Toggle, Theme & Save Manager Added

-- This script demonstrates the integration of Droplet UI Library with Theme Manager and Save Manager.
-- It has been simplified from the original example to focus on these core functionalities.

--=====--
-- Modules
--=====--
local repo = 'https://raw.githubusercontent.com/SimplyBamboo/Droplet/main/'

-- Attempt to load required modules
local uiLibrary, themeManager, saveManager

local success, lib = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/Lib.lua'))()
end)

if not success or not lib then
    warn("Failed to load Droplet UI Library. Aborting script execution.")
    return -- Exit if the core library fails to load
else
    uiLibrary = lib
    print("Droplet UI Library loaded successfully.")
end

local successTM, tm = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/addons/ThemeManager.lua'))()
end)
if successTM and tm then
    themeManager = tm
    print("Theme Manager loaded successfully.")
else
    warn("Failed to load Theme Manager.")
end

local successSM, sm = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/addons/SaveManager.lua'))()
end)
if successSM and sm then
    saveManager = sm
    print("Save Manager loaded successfully.")
else
    warn("Failed to load Save Manager.")
end


--=====--
-- UI Setup
--=====--

-- Configuration for the main window
local windowConfig = {
    Title = 'Droplet Example UI',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
}

-- Create main window
local Window = uiLibrary:CreateWindow(windowConfig)

-- Define and create tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    ['Settings'] = Window:AddTab('Settings'),
}

-- Table to store UI element options/values.
-- Elements added here can potentially be saved/loaded by the Save Manager.
local Options = {}


--=====--
-- MAIN TAB CONTENT (Simplified for demonstration)
--=====--

-- Left Groupbox: Example Controls
local mainControlsGroup = Tabs.Main:AddLeftGroupbox('Example Controls')

-- Add a few representative elements for Save Manager to interact with
Options.MainToggle = mainControlsGroup:AddToggle('MainToggle', {
    Text = 'Enable Feature',
    Default = false,
    Tooltip = 'A simple toggle',
    Callback = function(value)
        print('Main toggle changed to:', value)
    end
})

Options.IntensitySlider = mainControlsGroup:AddSlider('IntensitySlider', {
    Text = 'Intensity',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Tooltip = 'A slider for intensity',
    Callback = function(value)
        print('Intensity set to:', value)
    end
})

Options.ModeSelector = mainControlsGroup:AddDropdown('ModeSelector', {
    Values = {'Mode A', 'Mode B', 'Mode C'},
    Default = 1,
    Text = 'Select Mode',
    Tooltip = 'A dropdown for mode selection',
    Callback = function(value)
        print('Mode changed to:', value)
    end
})


--=====--
-- UI SETTINGS TAB CONTENT
--=====--

-- Left Groupbox: Menu Options
local uiSettingsMenuGroup = Tabs['Settings']:AddLeftGroupbox('Menu Options')

-- Watermark Toggle
-- This toggle's state will control the visibility of the FPS/Ping watermark.
Options.WatermarkEnabled = uiSettingsMenuGroup:AddToggle('WatermarkEnabled', {
    Text = 'Enable Watermark',
    Default = true, -- Watermark enabled by default
    Tooltip = 'Toggles the visibility of the FPS/Ping watermark',
    -- The callback here will only set the initial visibility;
    -- the RenderStepped loop handles continuous updates based on its value.
    Callback = function(value)
         uiLibrary:SetWatermarkVisibility(value)
    end
})

uiSettingsMenuGroup:AddButton('Unload UI', function()
    uiLibrary:Unload()
end)

-- Menu Keybind (Ignored by Save Manager by default)
Options.MenuKeybind = uiSettingsMenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'Backspace',
    NoUI = true, -- Hide the key picker itself from the UI list for saving/loading
    Text = 'Toggle UI Visibility'
})
uiLibrary.ToggleKeybind = Options.MenuKeybind -- Assign the keybind to the library


--=====--
-- Addon Setup (UI Elements and Functionality)
--=====--

-- Setup Theme Manager if loaded
if themeManager then
    themeManager:SetLibrary(uiLibrary)
    themeManager:SetFolder('DropletThemes') -- Folder name for themes
    -- Add Theme Manager UI elements to the left side of the Settings tab
    themeManager:ApplyToTab(Tabs['Settings'])
end

-- Setup Save Manager if loaded
if saveManager then
    saveManager:SetLibrary(uiLibrary)
    -- Ignore theme settings when saving/loading user configurations
    saveManager:IgnoreThemeSettings()
    -- Specify which UI elements to ignore from saving/loading.
    -- WatermarkEnabled is included so its state isn't overridden by config loads.
    saveManager:SetIgnoreIndexes({'MenuKeybind', 'WatermarkEnabled'})
    saveManager:SetFolder('DropletConfigs') -- Folder name for configurations
    -- Add Save Manager UI elements to the right side of the Settings tab
    saveManager:BuildConfigSection(Tabs['Settings'])
    -- Attempt to load the last auto-saved config on startup
    saveManager:LoadAutoloadConfig()
end


--=====--
-- Watermark (FPS/Ping Display)
--=====--

local RunService = game:GetService('RunService')
local lastFrameTime = tick()
local fps = 0

-- Function to update the watermark text and visibility
local function updateWatermark()
    local ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    local currentTime = tick()
    local deltaTime = currentTime - lastFrameTime
    lastFrameTime = currentTime
    -- Calculate FPS, avoid division by zero
    if deltaTime > 0 then
        fps = math.floor(1 / deltaTime)
    else
        fps = 999 -- Or some large number if deltaTime is zero
    end

    -- Update watermark only if it's enabled via the toggle
    if Options.WatermarkEnabled.Value then
        uiLibrary:SetWatermark(string.format('Droplet 💦 | FPS: %d | Ping: %d ms', fps, ping))
        uiLibrary:SetWatermarkVisibility(true) -- Ensure visible
    else
        uiLibrary:SetWatermarkVisibility(false) -- Ensure hidden
    end
end

-- Connect the watermark update function to RenderStepped to update every frame
-- This connection only needs to happen once.
RunService.RenderStepped:Connect(updateWatermark)

-- Ensure the initial watermark visibility matches the default state of the toggle
uiLibrary:SetWatermarkVisibility(Options.WatermarkEnabled.Default)

print("Droplet UI script finished execution.")