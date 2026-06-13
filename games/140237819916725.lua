local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local inputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")

local lplr = playersService.LocalPlayer
local vape = shared.vape

local category = nil
if vape.Categories then
    if vape.Categories.Utility then
        category = vape.Categories.Utility
    elseif vape.Categories.Misc then
        category = vape.Categories.Misc
    elseif vape.Categories.Other then
        category = vape.Categories.Other
    else
        for _, cat in pairs(vape.Categories) do
            category = cat
            break
        end
    end
end

local function createModule(name, callback)
    if category then
        return category:CreateModule({Name = name, Function = callback})
    else
        return vape:CreateModule({Name = name, Function = callback})
    end
end

local config = lplr:FindFirstChild("config")
if not config then
    config = lplr:WaitForChild("config", 10)
end

local mainEvent = replicatedStorage:FindFirstChild("remotes")
if mainEvent then mainEvent = mainEvent:FindFirstChild("events") end
if mainEvent then mainEvent = mainEvent:FindFirstChild("main_event") end

local function notif(...)
    if vape and vape.CreateNotification then
        return vape:CreateNotification(...)
    end
end

local soundIds = {
    "1255040462", "6534947240", "6534947588", "1347140027", "198598793",
    "3188795283", "130833677", "5332005053", "5332680810", "4578740568",
    "5633695679", "6534947869", "5766898159", "4018616850", "7553397015", "3124331820"
}

local soundNames = {}
for _, id in ipairs(soundIds) do
    table.insert(soundNames, id)
end

local headSoundId = "1255040462"
local limbSoundId = "1255040462"
local torsoSoundId = "1255040462"
local hitSoundsEnabled = false

local function applyHitSounds()
    if not config then return end
    if not hitSoundsEnabled then return end
    config.head_hit_sound = headSoundId
    config.limb_hit_sound = limbSoundId
    config.torso_hit_sound = torsoSoundId
end

local function resetHitSounds()
    if not config then return end
    config.head_hit_sound = ""
    config.limb_hit_sound = ""
    config.torso_hit_sound = ""
end

local hitSoundsModule = createModule("Hit Sounds", function(callback)
    hitSoundsEnabled = callback
    if callback then applyHitSounds() else resetHitSounds() end
end)

if hitSoundsModule then
    hitSoundsModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            hitSoundsEnabled = c
            if c then applyHitSounds() else resetHitSounds() end
        end
    })
    
    hitSoundsModule:CreateDropdown({
        Name = "Head Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            headSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    hitSoundsModule:CreateDropdown({
        Name = "Limb Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            limbSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    hitSoundsModule:CreateDropdown({
        Name = "Torso Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            torsoSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
end

local crosshairEnabled = false
local cursorId = "426730675"

local function applyCrosshair()
    if not config then return end
    if not crosshairEnabled then return end
    config.cursor_id = cursorId
end

local function resetCrosshair()
    if not config then return end
    config.cursor_id = ""
end

local crosshairModule = createModule("Crosshair", function(callback)
    crosshairEnabled = callback
    if callback then applyCrosshair() else resetCrosshair() end
end)

if crosshairModule then
    crosshairModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            crosshairEnabled = c
            if c then applyCrosshair() else resetCrosshair() end
        end
    })
    
    crosshairModule:CreateTextBox({
        Name = "Crosshair ID",
        Placeholder = "Enter asset ID",
        Default = "426730675",
        Function = function(val)
            cursorId = val
            if crosshairEnabled then applyCrosshair() end
        end
    })
end

local autoSprintEnabled = false
local sprintToggled = false

local function setSprint(value)
    if not config then return end
    config.toggle_sprint = value
end

inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not autoSprintEnabled then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintToggled = not sprintToggled
        setSprint(sprintToggled)
        if notif then notif("Auto Sprint", sprintToggled and "Sprint ON" or "Sprint OFF", 1, "info") end
    end
end)

local autoSprintModule = createModule("Auto Sprint", function(callback)
    autoSprintEnabled = callback
    if not callback then
        sprintToggled = false
        setSprint(false)
    end
end)

if autoSprintModule then
    autoSprintModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            autoSprintEnabled = c
            if not c then
                sprintToggled = false
                setSprint(false)
            end
        end
    })
end

local noSpreadEnabled = false

local function modifySpread()
    local playersFolder = workspaceService:FindFirstChild("players")
    if not playersFolder then return end
    
    for _, player in pairs(playersFolder:GetChildren()) do
        for _, tool in pairs(player:GetChildren()) do
            if tool:IsA("Tool") and noSpreadEnabled then
                tool:SetAttribute("spread", 0)
            end
        end
    end
end

local function watchForWeapons()
    local playersFolder = workspaceService:FindFirstChild("players")
    if not playersFolder then return end
    
    playersFolder.ChildAdded:Connect(function(player)
        player.ChildAdded:Connect(function(tool)
            task.wait(0.1)
            modifySpread()
        end)
    end)
    
    for _, player in pairs(playersFolder:GetChildren()) do
        player.ChildAdded:Connect(function(tool)
            task.wait(0.1)
            modifySpread()
        end)
    end
end

task.spawn(watchForWeapons)

local noSpreadModule = createModule("No Spread", function(callback)
    noSpreadEnabled = callback
    if callback then modifySpread() end
end)

if noSpreadModule then
    noSpreadModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            noSpreadEnabled = c
            if c then modifySpread() end
        end
    })
end

local silentAimEnabled = false
local aimPart = "Head"
local fovRadius = 200
local hitChance = 100
local range = 800
local oldFire = nil

local function getClosestEnemy()
    local myChar = lplr.Character
    if not myChar then return nil end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return nil end
    
    local playersFolder = workspaceService:FindFirstChild("players")
    if not playersFolder then return nil end
    
    local camera = workspaceService.CurrentCamera
    local mousePos = inputService:GetMouseLocation()
    
    local closest, closestDist = nil, math.huge
    
    for _, player in pairs(playersFolder:GetChildren()) do
        if player.Name ~= lplr.Name then
            local targetPart = player:FindFirstChild(aimPart) or player:FindFirstChild("Head")
            local hum = player:FindFirstChildOfClass("Humanoid")
            
            if targetPart and hum and hum.Health > 0 then
                local dist = (targetPart.Position - myHead.Position).Magnitude
                if dist <= range then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if fovDist < closestDist and fovDist <= fovRadius then
                            closestDist = fovDist
                            closest = targetPart
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

if mainEvent then
    oldFire = mainEvent.FireServer
    mainEvent.FireServer = function(self, data, token)
        if silentAimEnabled and data and type(data) == "table" and math.random(100) <= hitChance then
            local target = getClosestEnemy()
            if target then
                local myHead = lplr.Character and lplr.Character:FindFirstChild("Head")
                if myHead then
                    if type(data) == "table" then
                        for i, hit in pairs(data) do
                            if type(hit) == "table" then
                                hit[2] = target.Position
                                hit[3] = target
                            end
                        end
                    elseif data[1] and type(data[1]) == "table" then
                        for i, hit in pairs(data) do
                            if type(hit) == "table" then
                                hit[2] = target.Position
                                hit[3] = target
                            end
                        end
                    end
                end
            end
        end
        return oldFire(self, data, token)
    end
end

local silentAimModule = createModule("Silent Aim", function(callback)
    silentAimEnabled = callback
end)

if silentAimModule then
    silentAimModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            silentAimEnabled = c
        end
    })
    
    silentAimModule:CreateDropdown({
        Name = "Aim Part",
        List = {"Head", "Torso", "HumanoidRootPart"},
        Default = "Head",
        Function = function(v)
            aimPart = v
        end
    })
    
    silentAimModule:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 200,
        Suffix = "px",
        Function = function(v)
            fovRadius = v
        end
    })
    
    silentAimModule:CreateSlider({
        Name = "Range",
        Min = 50,
        Max = 1000,
        Default = 800,
        Suffix = "studs",
        Function = function(v)
            range = v
        end
    })
    
    silentAimModule:CreateSlider({
        Name = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%",
        Function = function(v)
            hitChance = v
        end
    })
end

if vape and vape.Clean then
    vape:Clean(function()
        if config then
            config.head_hit_sound = ""
            config.limb_hit_sound = ""
            config.torso_hit_sound = ""
            config.cursor_id = ""
            config.toggle_sprint = false
        end
        
        if mainEvent and oldFire then
            mainEvent.FireServer = oldFire
        end
        
        if notif then notif("Prison Duels", "All modules cleaned up", 2, "info") end
    end)
end

if notif then notif("Prison Duels", "Loaded successfully!", 3, "success") end
