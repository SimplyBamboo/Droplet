--💦 Droplet | V0 | 
print("--==--==--==--==--==Droplet")

local Droplet = {
    Info = {
        Version = "0.1",
        Dev = true
    },
    Urls = {},
    Modules = {
        UiLibrary = nil,
        ThemeManager = nil,
        SaveManager = nil
    }
}

--=====--
-- Services
--=====-

local RunService = game:GetService('RunService')
local StatsService = game:GetService('Stats') 

--=====--
-- Utils
--=====-

local function base64Decode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end


--=====--
-- Modules
--=====--

local function GetUrl(repoUrl, encodedPath)
    return repoUrl .. base64Decode(encodedPath)
end

local function initializeUrls()
    local EncodedUrls = {
        Repo = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1NpbXBseUJhbWJvby9Ecm9wbGV0L21haW4v",
        UILib = "VUkvTGliLmx1YQ==",
        ThemeManager = "VUkvQWRkb25zL1RoZW1lTWFuYWdlci5sdWE=",
        SaveManager = "VUkvQWRkb25zL1NhdmVNYW5hZ2VyLmx1YQ=="
    }
    
    local repoUrl = base64Decode(EncodedUrls.Repo)
    Droplet.Urls = {
        Repo = repoUrl,
        UILib = GetUrl(repoUrl, EncodedUrls.UILib),
        ThemeManager = GetUrl(repoUrl, EncodedUrls.ThemeManager),
        SaveManager = GetUrl(repoUrl, EncodedUrls.SaveManager)
    }
end

initializeUrls()

local function loadModules()
    local success, err = pcall(function()
        Droplet.Modules.UiLibrary = loadstring(game:HttpGet(Droplet.Urls.UILib))()
    end)

    if not success or not Droplet.Modules.UiLibrary then
        warn("Failed UILib: " .. tostring(err))
        return false
    end

    success, err = pcall(function()
        Droplet.Modules.ThemeManager = loadstring(game:HttpGet(Droplet.Urls.ThemeManager))()
    end)

    if not success or not Droplet.Modules.ThemeManager then
        warn("Failed ThemeManager: " .. tostring(err))
        return false
    end

    success, err = pcall(function()
        Droplet.Modules.SaveManager = loadstring(game:HttpGet(Droplet.Urls.SaveManager))()
    end)

    if not success or not Droplet.Modules.SaveManager then
        warn("Failed SaveManager: " .. tostring(err))
        return false
    end
    
    return true
end

if not loadModules() then
    return
end


--=====--
-- Main
--=====--




--=====--
-- UI Setup
--=====--


local function setupUI()
    local Library = Droplet.Modules.UiLibrary
    local ThemeManager = Droplet.Modules.ThemeManager
    local SaveManager = Droplet.Modules.SaveManager

    local Window = Library:CreateWindow({
        Title = '💦 Droplet | ' .. Droplet.Info.Version .. (Droplet.Info.Dev and ' | Dev Build' or ''),
        Center = true,
        AutoShow = true,
        TabPadding = 3,
        MenuFadeTime = 0.1
    })
    
    local Tabs = {
        HomeTab = Window:AddTab('Main'),
        AimbotTab = Window:AddTab('Aimbot'),
        WallhacksTab = Window:AddTab('WallHacks'),
        CharacerTab = Window:AddTab('Character'),
        SettingsTab = Window:AddTab('Settings')
    }

    --==
    -- Home Tab
    --==
    local LeftGroupBox = Tabs.HomeTab:AddLeftGroupbox("Main")
    LeftGroupBox:AddLabel('Private Cheat | @Simply.Bamboo')
    LeftGroupBox:AddDivider()
    

    --==
    -- Setting Tab
    --==

    local LeftGroupBox = Tabs.SettingsTab:AddLeftGroupbox("Settings")
    LeftGroupBox:AddDivider()
    LeftGroupBox:AddButton('Unload', function() Library:Unload() end)
    LeftGroupBox:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'Backspace', NoUI = true, Text = 'Menu keybind' })

    Library.ToggleKeybind = Options.MenuKeybind 

    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder('Dropletthemes')

    SaveManager:SetLibrary(Library)
    SaveManager:SetFolder('DroplettSaves')
    SaveManager:IgnoreThemeSettings()

    SaveManager:LoadAutoloadConfig()

    SaveManager:BuildConfigSection(Tabs.SettingsTab)
    ThemeManager:ApplyToTab(Tabs.SettingsTab)

    --==
    -- Watermark
    --==
    
    local FrameCounter = 0
    local LastUpdateTime = os.clock()
    local UpdateInterval = 0.5 
    
    local DisplayFPS = 0 
    local DisplayPing = 0
    
    local HeartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        FrameCounter += 1
        local currentTime = os.clock()
    
        if (currentTime - LastUpdateTime) >= UpdateInterval then
            DisplayFPS = FrameCounter / (currentTime - LastUpdateTime)
            local pingItem = StatsService.Network.ServerStatsItem['Data Ping']
            if pingItem then
                DisplayPing = pingItem:GetValue()
            end
    
            Library:SetWatermark(('Droplet | %s fps | %s ms'):format(
                math.floor(DisplayFPS),
                math.floor(DisplayPing)
            ))
    
            FrameCounter = 0
            LastUpdateTime = currentTime
        end
    end)
    
    return {
        --[[
        Window = Window,
        Tabs = Tabs,
        Library = Library, 
        Unload = function()
            WatermarkConnection:Disconnect()
            Library:Unload() 
        end
        ]]
    }
end

setupUI()

