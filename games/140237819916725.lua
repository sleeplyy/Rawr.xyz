
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local inputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")

local lplr = playersService.LocalPlayer
local vape = shared.vape

local config = lplr:FindFirstChild("config")
if not config then
    config = lplr:WaitForChild("config", 10)
end

local mainEvent = replicatedStorage:FindFirstChild("remotes") and 
                  replicatedStorage.remotes:FindFirstChild("events") and
                  replicatedStorage.remotes.events:FindFirstChild("main_event")

local function notif(...) return vape:CreateNotification(...) end

local soundIds = {
    "1255040462",  -- Rust
    "6534947240",  -- Bell
    "6534947588",  -- Bubble
    "1347140027",  -- Pick
    "198598793",   -- Pop
    "3188795283",  -- Sans
    "130833677",   -- Fart
    "5332005053",  -- Big
    "5332680810",  -- Vine
    "4578740568",  -- Bruh
    "5633695679",  -- Skeet
    "6534947869",  -- Fatality
    "5766898159",  -- Bonk
    "4018616850",  -- Minecraft
    "7553397015",  -- TomScream
    "3124331820",  -- Bameware
}

local soundNames = {}
for _, id in ipairs(soundIds) do
    table.insert(soundNames, id)
end

run(function()
    local HitSounds
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
    
    HitSounds = vape.Categories.Utility:CreateModule({
        Name = "Hit Sounds",
        Function = function(callback)
            hitSoundsEnabled = callback
            if callback then applyHitSounds() else resetHitSounds() end
        end,
        Tooltip = "Custom sounds when you hit enemies"
    })
    
    HitSounds:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            hitSoundsEnabled = c
            if c then applyHitSounds() else resetHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Head Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            headSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Limb Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            limbSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Torso Sound",
        List = soundNames,
        Default = "1255040462",
        Function = function(val)
            torsoSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
end)

run(function()
    local CrosshairChanger
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
    
    CrosshairChanger = vape.Categories.Utility:CreateModule({
        Name = "Crosshair",
        Function = function(callback)
            crosshairEnabled = callback
            if callback then applyCrosshair() else resetCrosshair() end
        end,
        Tooltip = "Change your crosshair"
    })
    
    CrosshairChanger:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            crosshairEnabled = c
            if c then applyCrosshair() else resetCrosshair() end
        end
    })
    
    CrosshairChanger:CreateTextBox({
        Name = "Crosshair ID",
        Placeholder = "Enter asset ID",
        Default = "426730675",
        Function = function(val)
            cursorId = val
            if crosshairEnabled then applyCrosshair() end
        end
    })
end)

run(function()
    local AutoSprint
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
            notif("Auto Sprint", sprintToggled and "Sprint ON" or "Sprint OFF", 1, "info")
        end
    end)
    
    AutoSprint = vape.Categories.Utility:CreateModule({
        Name = "Auto Sprint",
        Function = function(callback)
            autoSprintEnabled = callback
            if not callback then
                sprintToggled = false
                setSprint(false)
            end
        end,
        Tooltip = "Press Shift once to toggle sprint"
    })
    
    AutoSprint:CreateToggle({
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
end)

-- gun mods

run(function()
    local NoSpread
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
    
    NoSpread = vape.Categories.Combat:CreateModule({
        Name = "No Spread",
        Function = function(callback)
            noSpreadEnabled = callback
            if callback then
                modifySpread()
            end
        end,
        Tooltip = "Removes bullet spread"
    })
    
    NoSpread:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            noSpreadEnabled = c
            if c then modifySpread() end
        end
    })
end)

-- silent

run(function()
    local SilentAim
    local enabled = false
    local aimPart = "Head"
    local fovRadius = 200
    local hitChance = 100
    local range = 800
    
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
                    if dist > range then continue end
                    
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
        
        return closest
    end
    
    if mainEvent then
        local oldFire = mainEvent.FireServer
        mainEvent.FireServer = function(self, data, token)
            if enabled and data and type(data) == "table" and math.random(100) <= hitChance then
                local target = getClosestEnemy()
                if target then
                    local myHead = lplr.Character and lplr.Character:FindFirstChild("Head")
                    if myHead then
                        for i, hit in pairs(data) do
                            if type(hit) == "table" then
                                hit[2] = target.Position
                                hit[3] = target
                            end
                        end
                    end
                end
            end
            return oldFire(self, data, token)
        end
    else
        warn("Silent Aim: Could not find main_event remote")
    end
    
    SilentAim = vape.Categories.Combat:CreateModule({
        Name = "Silent Aim",
        Function = function(callback)
            enabled = callback
        end,
        Tooltip = "Silently redirect bullets to enemies"
    })
    
    SilentAim:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            enabled = c
        end
    })
    
    SilentAim:CreateDropdown({
        Name = "Aim Part",
        List = {"Head", "Torso", "HumanoidRootPart"},
        Default = "Head",
        Function = function(v)
            aimPart = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 200,
        Suffix = "px",
        Function = function(v)
            fovRadius = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "Range",
        Min = 50,
        Max = 1000,
        Default = 800,
        Suffix = "studs",
        Function = function(v)
            range = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%",
        Function = function(v)
            hitChance = v
        end
    })
end)

-- CLEANUP

vape:Clean(function()
    if config then
        config.head_hit_sound = ""
        config.limb_hit_sound = ""
        config.torso_hit_sound = ""
        config.cursor_id = ""
        config.toggle_sprint = false
    end
    
    if mainEvent and mainEvent.FireServer then
    end
    
    notif("Prison Duels", "test", 2, "info")
end)

notif("Prison Duels", "rawr locked in", 3, "success")
