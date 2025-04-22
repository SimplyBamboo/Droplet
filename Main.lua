--💦Droplet | V0.1 (Optimized)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Core Objects
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerMouse = localPlayer:GetMouse()

-- State Variables
local isAimingActive = false

-- Cache frequently used values
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local CFrame_lookAt = CFrame.lookAt
local Enum_RaycastFilterType_Blacklist = Enum.RaycastFilterType.Blacklist
local RaycastParams_new = RaycastParams.new

-- Helper Functions
local function predictPosition(targetPart, travelTime)
    if not targetPart or travelTime <= 0 then
        return targetPart.Position
    end

    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart")
    if not rootPart then return targetPart.Position end

    local velocity = rootPart.AssemblyLinearVelocity
    return targetPart.Position + (velocity * travelTime)
end

local function isVisible(targetPart)
    if not Toggles.VisibleCheck.Value or not targetPart then return true end

    local origin = camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = targetPos - origin
    local distance = direction.Magnitude

    if distance <= 0 then return true end

    local raycastParams = RaycastParams_new()
    raycastParams.FilterDescendantsInstances = {targetPart.Parent, localPlayer.Character}
    raycastParams.FilterType = Enum_RaycastFilterType_Blacklist
    raycastParams.IgnoreWater = true

    return not Workspace:Raycast(origin, direction.Unit * (distance + 0.1), raycastParams)
end

-- Core Logic
local function findTarget()
    if not Toggles.AimbotEnabled.Value then return end

    local closestPart, closestDist = nil, Options.AimbotFOV.Value
    local localTeam = localPlayer.Team
    local aimMode = Options.AimMode.Value
    local aimPart = Options.AimPart.Value

    for _, player in Players:GetPlayers() do
        if player == localPlayer then continue end
        if Toggles.TeamCheck.Value and player.Team == localTeam then continue end

        local character = player.Character
        if not character then continue end

        local targetPart = character:FindFirstChild(aimPart)
        if not targetPart then continue end

        if Toggles.VisibleCheck.Value and not isVisible(targetPart) then continue end

        local distance
        if aimMode == "Camera" then
            local screenPos = camera:WorldToViewportPoint(targetPart.Position)
            if not screenPos.Z > 0 then continue end
            distance = (Vector2_new(screenPos.X, screenPos.Y) - Vector2_new(playerMouse.X, playerMouse.Y)).Magnitude
        else
            local mouseHitPosition = playerMouse.Hit.Position
            if mouseHitPosition.Magnitude > 10000 then continue end
            distance = (targetPart.Position - mouseHitPosition).Magnitude
        end

        if distance < closestDist then
            closestDist, closestPart = distance, targetPart
        end
    end

    return closestPart
end

local function performAim(targetPart)
    if not targetPart then return end

    local predictedPosition = predictPosition(targetPart, Options.Prediction.Value)
    local targetCFrame = CFrame_lookAt(camera.CFrame.Position, predictedPosition)
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 - math.clamp(Options.Smoothness.Value, 0, 1))
end

-- UI Setup
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local Window = Library:CreateWindow({
    Title = 'DROPLET @Simply.Bamboo',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.5
})

local Tabs = {
    Home = Window:AddTab('Home'),
    Aimbot = Window:AddTab('Aimbot')
}

-- Home Tab
local HomeGroup = Tabs.Home:AddLeftGroupbox('Info')
HomeGroup:AddDivider()
HomeGroup:AddLabel('Created by: Simply.Bamboo')
HomeGroup:AddLabel('Discord: https://discord.gg/zADP8sEd9x')
HomeGroup:AddDivider()
HomeGroup:AddLabel('This is a paid cheat')

-- Aimbot Tab
local AimbotGroup = Tabs.Aimbot:AddLeftGroupbox('Aimbot Settings')
AimbotGroup:AddToggle('AimbotEnabled', {Text = 'Enable Aimbot', Default = false})

AimbotGroup:AddSlider('AimbotFOV', {
    Text = 'Aimbot FOV',
    Default = 100,
    Min = 1,
    Max = 360,
    Rounding = 0
})

AimbotGroup:AddDropdown('AimPart', {
    Text = 'Aim Part',
    Default = 'Head',
    Values = {'Head', 'HumanoidRootPart'}
})

AimbotGroup:AddSlider('Smoothness', {
    Text = 'Smoothness',
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2
})

AimbotGroup:AddSlider('Prediction', {
    Text = 'Prediction',
    Default = 0.15,
    Min = 0,
    Max = 1,
    Rounding = 2
})

AimbotGroup:AddDropdown('AimMode', {
    Text = 'Aim Mode',
    Default = 'Camera',
    Values = {'Camera', 'Cursor'}
})

AimbotGroup:AddToggle('TeamCheck', {Text = 'Team Check', Default = false})
AimbotGroup:AddToggle('VisibleCheck', {Text = 'Visible Check', Default = true})

local TriggerKeyPicker = AimbotGroup:AddLabel('Aimbot Keybind'):AddKeyPicker('Trigger', {
    Default = 'MB2',
    Mode = 'Toggle',
    Text = 'Aimbot trigger key',
    NoUI = false, -- Set to true if you don't want it to appear in the keybinds list
})

-- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == TriggerKeyPicker.Value then
        isAimingActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == TriggerKeyPicker.Value then
        isAimingActive = false
    end
end)

-- Main Loop
local renderConnection = RunService.RenderStepped:Connect(function()
    if isAimingActive then
        performAim(findTarget())
    end
end)

Library:OnUnload(function()
    renderConnection:Disconnect()
end)