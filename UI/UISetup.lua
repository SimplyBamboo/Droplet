--💦 Droplet UI Setup | V1.0
-- Fixed and optimized by [Your Name]

local repo = 'https://raw.githubusercontent.com/SimplyBamboo/Droplet/main/'

-- Load required libraries
local success, Library = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/Lib.lua'))()
end)

if not success or not Library then
    warn("Failed to load Droplet UI Library")
    return
end

local success, ThemeManager = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/addons/ThemeManager.lua'))()
end)

local success, SaveManager = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/addons/SaveManager.lua'))()
end)

-- Create main window
local Window = Library:CreateWindow({
    Title = 'Droplet UI Example',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ===== MAIN TAB CONTENT =====
local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Controls')

-- Add toggle
LeftGroupBox:AddToggle('MainToggle', {
    Text = 'Enable Feature',
    Default = false,
    Tooltip = 'Toggles the main feature',
    Callback = function(Value)
        print('Main toggle changed to:', Value)
    end
})

-- Add button with sub-button
local MainButton = LeftGroupBox:AddButton({
    Text = 'Main Action',
    Func = function()
        print('Main action triggered!')
    end,
    Tooltip = 'Primary action button'
})

MainButton:AddButton({
    Text = 'Sub Action',
    Func = function()
        print('Sub action triggered!')
    end,
    DoubleClick = true,
    Tooltip = 'Requires double click'
})

-- Add slider
LeftGroupBox:AddSlider('IntensitySlider', {
    Text = 'Effect Intensity',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        print('Intensity set to:', Value)
    end
})

-- Add dropdown
LeftGroupBox:AddDropdown('ModeSelector', {
    Values = {'Mode 1', 'Mode 2', 'Mode 3'},
    Default = 1,
    Text = 'Select Mode',
    Callback = function(Value)
        print('Mode changed to:', Value)
    end
})

-- Add color picker
LeftGroupBox:AddLabel('Color Settings'):AddColorPicker('PrimaryColor', {
    Default = Color3.fromRGB(0, 255, 140),
    Title = 'Primary Color',
    Transparency = 0,
    Callback = function(Value)
        print('Color changed to:', Value)
    end
})

-- Add keybind
LeftGroupBox:AddLabel('Activation Key'):AddKeyPicker('ActivationKey', {
    Default = 'F',
    Mode = 'Toggle',
    Text = 'Toggle Feature',
    Callback = function(Value)
        print('Keybind toggled:', Value)
    end
})

-- Right side groupbox
local RightGroupBox = Tabs.Main:AddRightGroupbox('Information')
RightGroupBox:AddLabel('Droplet UI Example'):AddLabel('Welcome to the example UI!')
RightGroupBox:AddDivider()

-- Add multiline label
RightGroupBox:AddLabel('This is an example of the Droplet UI library.\n\nYou can customize this to create powerful\nand user-friendly interfaces for your scripts!', true)

-- ===== UI SETTINGS TAB =====
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- Unload button
MenuGroup:AddButton('Unload UI', function()
    Library:Unload()
end)

-- Menu keybind
MenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = true,
    Text = 'Toggle UI Visibility'
})

Library.ToggleKeybind = Options.MenuKeybind

-- Set up theme manager
if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder('DropletThemes')
    ThemeManager:ApplyToTab(Tabs['UI Settings'])
end

-- Set up save manager
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({'MenuKeybind'})
    SaveManager:SetFolder('DropletConfigs')
    SaveManager:BuildConfigSection(Tabs['UI Settings'])
    SaveManager:LoadAutoloadConfig()
end

-- Watermark setup
Library:SetWatermarkVisibility(true)

local function updateWatermark()
    local ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    Library:SetWatermark(string.format('Droplet UI | %s ms', ping))
end

-- Update watermark every second
task.spawn(function()
    while true do
        updateWatermark()
        task.wait(1)
        if Library.Unloaded then break end
    end
end)

-- Unload handler
Library:OnUnload(function()
    print('Droplet UI unloaded!')
    Library.Unloaded = true
end)