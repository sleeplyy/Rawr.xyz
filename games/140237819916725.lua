
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
    return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local tween = vape.Libraries.tween
local targetinfo = vape.Libraries.targetinfo
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

for _, v in {
    'SilentAim', 'Reach', 'AntiFall', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot',
    'ChatSpammer', 'Arrest Highlight', 'HitNotifications',
    'Bullet Tracers', 'Head Pitch Spinbot (Client)', 'AutoArrest',
    'Anti Riot', 'Anti Taze', 'C4 ESP',
    'AutoReset', 'AutoHeal'
} do vape:Remove(v) end

local silentAimData = {
    enabled = false,
    active = false,
    targetplayer = nil,
    targetpart = nil,
    targetposition = nil,
    hitchance = 100,
    hitpart = "Head",
    fov = 200,
    mode = "sticky"
}

local function isTargetValid(player)
    if not player then return false end
    if player == lplr then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function getClosestToMouse()
    local mousePos = inputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    local closest, closestDist = nil, math.huge
    
    for _, player in pairs(playersService:GetPlayers()) do
        if isTargetValid(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist and dist <= silentAimData.fov then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if checkcaller() then return oldNamecall(self, ...) end
    local args = {...}
    local method = getnamecallmethod()
    
    if silentAimData.enabled and silentAimData.active and method == "FireServer" then
        if self.Name == "ShootEvent" or (self.Parent and self.Parent.Name == "GunRemotes") then
            if math.random(100) <= silentAimData.hitchance then
                local target = getClosestToMouse()
                if target and target.Character then
                    local targetPart = target.Character:FindFirstChild(silentAimData.hitpart) or target.Character:FindFirstChild("Head")
                    if targetPart then
                        if type(args[1]) == "table" then
                            for i, hit in pairs(args[1]) do
                                if type(hit) == "table" then
                                    hit[2] = targetPart.Position
                                    hit[3] = targetPart
                                end
                            end
                        end
                        silentAimData.targetplayer = target
                        silentAimData.targetpart = targetPart
                        silentAimData.targetposition = targetPart.Position
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

local oldIndex
local mouse = lplr:GetMouse()
local rawMeta = getrawmetatable(game)
local oldMetaIndex = rawMeta.__index

setreadonly(rawMeta, false)
rawMeta.__index = newcclosure(function(self, key)
    if silentAimData.enabled and silentAimData.active and self == mouse then
        if key == "Hit" and silentAimData.targetposition then
            return CFrame.new(silentAimData.targetposition)
        elseif key == "Target" and silentAimData.targetpart then
            return silentAimData.targetpart
        elseif (key == "X" or key == "Y") and silentAimData.targetposition then
            local screenPos = workspace.CurrentCamera:WorldToViewportPoint(silentAimData.targetposition)
            return screenPos[key == "X" and "X" or "Y"]
        end
    end
    return oldMetaIndex(self, key)
end)
setreadonly(rawMeta, true)

local silentAimModule = vape.Categories.Combat:CreateModule({
    Name = "Silent Aim",
    Function = function(callback)
        silentAimData.enabled = callback
        if not callback then
            silentAimData.active = false
            silentAimData.targetplayer = nil
            silentAimData.targetpart = nil
            silentAimData.targetposition = nil
        end
    end,
    Tooltip = "Redirect bullets to nearest enemy"
})

silentAimModule:CreateToggle({
    Name = "Enable",
    Default = false,
    Function = function(c)
        silentAimData.enabled = c
        if not c then
            silentAimData.active = false
        end
    end
})

silentAimModule:CreateToggle({
    Name = "Active",
    Default = false,
    Function = function(c)
        silentAimData.active = c
    end,
    Tooltip = "Toggle to activate silent aim"
})

silentAimModule:CreateSlider({
    Name = "FOV",
    Min = 10,
    Max = 500,
    Default = 200,
    Suffix = "px",
    Function = function(v)
        silentAimData.fov = v
    end
})

silentAimModule:CreateSlider({
    Name = "Hit Chance",
    Min = 0,
    Max = 100,
    Default = 100,
    Suffix = "%",
    Function = function(v)
        silentAimData.hitchance = v
    end
})

silentAimModule:CreateDropdown({
    Name = "Aim Part",
    List = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Function = function(v)
        silentAimData.hitpart = v
    end
})

local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not silentAimData.enabled then return end
    if input.KeyCode == Enum.KeyCode.C then
        silentAimData.active = not silentAimData.active
        vape:CreateNotification("Silent Aim", silentAimData.active and "ON" or "OFF", 1, "info")
    end
end)
