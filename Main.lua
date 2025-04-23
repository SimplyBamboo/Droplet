--💦 Droplet | V0 | 



local DropletInfo = {
    version = "0"
}

--=====--
-- Modules
--=====--
local repo = 'https://raw.githubusercontent.com/SimplyBamboo/Droplet/main/'

local UiLibrary, ThemeManager, SaveManager

local success, UiLibrary = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/Lib.lua'))()
end)

if not success or not UiLibrary then
    warn("Failed UILib")
    return 
end

local success, ThemeManager = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/Addons/ThemeManager.lua'))()
end)

if not success or not ThemeManager then
    warn("Failed ThemeManager")
    return 
end

local success, SaveManager = pcall(function()
    return loadstring(game:HttpGet(repo .. 'UI/Addons/SaveManager.lua'))()
end)

if not success or not SaveManager then
    warn("Failed SaveManager")
    return 
end


--=====--
-- UI Setup
--=====--

-- Configuration for the main window
local Window = Library:CreateWindow({
    Title = '💦 Droplet | ',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})
local Tabs = {
    HomeTab = Window:AddTab('Main'),
    SettingsTab = Window:AddTab('Settings'),
}



-- HOME TAB



