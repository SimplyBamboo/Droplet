local url = "https://raw.githubusercontent.com/SimplyBamboo/Droplet/refs/heads/main/Main.lua"

local function import(file)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url .. file))()
    end)

    if not success then
        warn('failed to import', file, result) 
    end
end

getgenv().import = import

import('/main.lua')
