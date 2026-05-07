--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

-- FB
if not mouse1click then mouse1click = function() return false end end
if not isrbxactive then isrbxactive = function() return true end end
if not iswindowactive then iswindowactive = function() return true end end
if not mouse1press then mouse1press = function() end end
if not mouse1release then mouse1release = function() end end

local run = function(func, issue)
    if issue then return end
    pcall(func)
end

local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local workspaceService = cloneref(game:GetService('Workspace'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local guiService = cloneref(game:GetService('GuiService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo

local function notif(...) return vape:CreateNotification(...) end

if identifyexecutor then
    local execInfo = {identifyexecutor()}
    local execName = execInfo[1] or "Unknown"
    local execVersion = execInfo[2] or "Unknown"
    notif('Rawr.xyz', 'Executor: ' .. execName .. ' | v' .. execVersion, 5, 'info')
    local allowed = {Madium = true, Velocity = true, Sirhurt = true, Volt = true, LX63 = true}
    if not allowed[execName] then
        notif('Rawr.xyz', 'Your Executor is too bad to use all features :(', 6, 'alert')
    end
end

local function safeCall(desc, func)
    local ok, err = pcall(func)
    if not ok then
        notif('Rawr.xyz', desc .. ' failed: ' .. tostring(err), 3, 'alert')
    end
end

local function canClick()
    local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
    for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    local scaledGui = vape.gui.ScaledGui
    local clickGuiVisible = scaledGui and scaledGui.ClickGui and scaledGui.ClickGui.Visible
    return not clickGuiVisible and not inputService:GetFocusedTextBox()
end

for _, v in {'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'} do vape:Remove(v) end

local t = { sa = { redirect = nil } }

-- ============== SILENT AIM (bullets only, no camera lock) ==============
run(function()
    local SilentAim
    local Target, Mode, Range, HitChance, HeadshotChance
    local CircleColor, CircleTransparency, CircleFilled, CircleObject
    local filterTeamSA, TeamFilterSA
    local rand = Random.new()
    local delayCheck = tick()

    -- find shoot remote
    local shootRemote = nil
    local function findShootRemote()
        local gunRemotes = replicatedStorage:FindFirstChild("GunRemotes")
        if gunRemotes then
            return gunRemotes:FindFirstChild("ShootEvent")
        end
        for _, obj in ipairs(replicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and string.find(obj.Name:lower(), "shoot") then
                return obj
            end
        end
        return nil
    end
    shootRemote = findShootRemote()
    if not shootRemote then
        notif('Rawr.xyz', 'Could not find Shoot remote. Silent Aim may not work.', 5, 'alert')
    end

    local function passesTeamCheck(player)
        if not filterTeamSA then return true end
        return player and player.Team == filterTeamSA
    end

    local function getTarget(origin)
        local chance = HitChance and HitChance.Value or 100
        if not rand or rand.NextNumber(rand, 0, 100) > chance then return end
        local headshotChance = HeadshotChance and HeadshotChance.Value or 100
        local targetPart = (rand.NextNumber(rand, 0, 100) < headshotChance) and 'Head' or 'RootPart'
        local ent = entitylib['Entity' .. (Mode and Mode.Value or 'Mouse')]({
            Range = Range and Range.Value or 200,
            Wallcheck = Target and Target.Walls and Target.Walls.Enabled or nil,
            Part = targetPart,
            Origin = origin,
            Players = Target and Target.Players and Target.Players.Enabled,
            NPCs = Target and Target.NPCs and Target.NPCs.Enabled
        })
        if ent and targetinfo then targetinfo.Targets[ent] = tick() + 1 end
        if ent and ent.Player and not passesTeamCheck(ent.Player) then
            return nil
        end
        return ent, ent and ent[targetPart], origin
    end

    local function silentAimRedirect(args)
        if not entitylib or not entitylib.isAlive then return end
        local head = entitylib.character and entitylib.character.Head
        if not head then return end
        local origin = head.Position
        local ent, targetPart = getTarget(origin)
        if not ent or not targetPart or typeof(args[1]) ~= "table" then return end

        local originalHits = args[1]
        local count = math.clamp(#originalHits, 1, 20)
        if SilentAim and SilentAim.Enabled then
            local newHits = table.create(count)
            for i = 1, count do
                newHits[i] = {origin, targetPart.Position, targetPart}
            end
            args[1] = newHits
        end
    end

    -- Hook the remote
    if shootRemote then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self == shootRemote and not checkcaller() then
                local args = {...}
                if typeof(args[1]) == "table" and t.sa.redirect then
                    t.sa.redirect(args)
                end
                return oldNamecall(self, unpack(args))
            end
            return oldNamecall(self, ...)
        end))
        vape:Clean(function() hookmetamethod(game, "__namecall", oldNamecall) end)
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if callback then
                t.sa.redirect = silentAimRedirect
            else
                t.sa.redirect = nil
            end
        end,
        Tooltip = 'Redirects bullets to the closest enemy without moving your camera.'
    })

    Target = SilentAim:CreateTargets({Players = true})
    Mode = SilentAim:CreateDropdown({
        Name = 'Mode',
        List = {'Mouse', 'Position'},
        Default = 'Mouse',
        Function = function(val) end,
        Tooltip = 'Mouse - target near cursor, Position - target near player'
    })
    Range = SilentAim:CreateSlider({
        Name = 'Range', Min = 1, Max = 1000, Default = 200,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    HitChance = SilentAim:CreateSlider({
        Name = 'Hit Chance', Min = 0, Max = 100, Default = 100,
        Suffix = '%', Tooltip = 'Chance to hit the target'
    })
    HeadshotChance = SilentAim:CreateSlider({
        Name = 'Headshot Chance', Min = 0, Max = 100, Default = 100,
        Suffix = '%', Tooltip = 'Chance to aim for the head'
    })
    TeamFilterSA = SilentAim:CreateDropdown({
        Name = 'Team Filter',
        List = {'All', 'Criminals', 'Inmates', 'Guards', 'Neutral'},
        Function = function(val)
            local teams = game:GetService("Teams")
            if val == 'Criminals' then filterTeamSA = teams:FindFirstChild("Criminals") or "Criminals"
            elseif val == 'Inmates' then filterTeamSA = teams:FindFirstChild("Inmates") or "Inmates"
            elseif val == 'Guards' then filterTeamSA = teams:FindFirstChild("Guards") or "Guards"
            elseif val == 'Neutral' then filterTeamSA = teams:FindFirstChild("Neutral") or "Neutral"
            else filterTeamSA = nil end
        end,
        Tooltip = 'Only target players on the selected team'
    })
    -- Range circle sub‑options
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color', Darker = true, Visible = false,
        Function = function(h,s,v) if CircleObject then CircleObject.Color = Color3.fromHSV(h,s,v) end end
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency', Min = 0, Max = 1, Decimal = 10, Default = 0.5,
        Darker = true, Visible = false,
        Function = function(val) if CircleObject then CircleObject.Transparency = 1 - val end end
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled', Darker = true, Visible = false,
        Function = function(callback) if CircleObject then CircleObject.Filled = callback end end
    })
    SilentAim:CreateSlider({
        Name = 'Circle Spin Speed', Min = 0, Max = 360, Default = 0,
        Darker = true, Visible = false,
        Function = function(val)
            if CircleObject then CircleObject.Radius = val end
        end,
        Suffix = '°/s'
    })
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled and CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor and CircleColor.Hue or 0, CircleColor and CircleColor.Sat or 1, CircleColor and CircleColor.Value or 1)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = Range and Range.Value or 200
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - (CircleTransparency and CircleTransparency.Value or 0.5)
                CircleObject.Visible = SilentAim.Enabled
            else
                pcall(function() CircleObject:Remove() end)
                CircleObject = nil
            end
            if CircleColor then CircleColor.Object.Visible = callback end
            if CircleTransparency then CircleTransparency.Object.Visible = callback end
            if CircleFilled then CircleFilled.Object.Visible = callback end
        end
    })
end)

-- ============== CROSSHAIR ==============
run(function()
    local crosshairEnabled = false
    local crosshairColor = Color3.fromRGB(128,128,128)
    local crosshairSpin = true
    local crosshairLength = 10
    local crosshairRadius = 11
    local crosshairWidth = 1.5
    local crosshairStyle = "Cross"
    local dotSize = 0
    local outlineEnabled = false
    local outlineColor = Color3.new(0,0,0)
    local outlineThickness = 0.5
    local drawings = { lines = {}, texts = {}, dot = nil, outlines = {} }
    local renderConnection
    local text_x = 0
    local lastSpinAngle = 0

    local function solve(angle, radius)
        local rad = math.rad(angle)
        return Vector2.new(math.sin(rad)*radius, math.cos(rad)*radius)
    end

    local function createDrawings()
        for i = 1, 8 do drawings.lines[i] = Drawing.new('Line') end
        for i = 1, 4 do drawings.outlines[i] = Drawing.new('Line') end
        drawings.dot = Drawing.new('Circle')
        drawings.texts[1] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=Color3.new(1,1,1)})
        drawings.texts[2] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rivals',Color=crosshairColor})
    end

    local function updateCrosshair()
        local pos = inputService:GetMouseLocation()
        drawings.texts[1].Visible = crosshairEnabled
        drawings.texts[2].Visible = crosshairEnabled
        drawings.dot.Visible = crosshairEnabled and dotSize > 0

        if crosshairEnabled then
            -- texts
            drawings.texts[1].Position = pos + Vector2.new(-text_x/2, crosshairRadius+crosshairLength+15)
            drawings.texts[2].Position = drawings.texts[1].Position + Vector2.new(drawings.texts[1].TextBounds.X, 0)
            drawings.texts[2].Color = crosshairColor

            if crosshairSpin then lastSpinAngle = (tick()*360) % 360 end

            -- dot
            if dotSize > 0 then
                drawings.dot.Position = pos
                drawings.dot.Radius = dotSize
                drawings.dot.Filled = true
                drawings.dot.Color = crosshairColor
                drawings.dot.Transparency = 0
            end

            -- lines
            for idx = 1, 4 do
                local inline = drawings.lines[idx+4]
                local outline = drawings.outlines[idx]
                local angle = (idx-1)*90 + lastSpinAngle
                local dir = solve(angle,1)
                local fromPos = pos + dir * crosshairRadius
                local toPos = pos + dir * (crosshairRadius + crosshairLength)

                inline.Visible = true; inline.Color = crosshairColor
                inline.From = fromPos; inline.To = toPos; inline.Thickness = crosshairWidth

                outline.Visible = outlineEnabled
                if outlineEnabled then
                    outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2
                    outline.Color = outlineColor
                end
            end
        else
            for i = 1, 8 do drawings.lines[i].Visible = false end
            for i = 1, 4 do drawings.outlines[i].Visible = false end
            drawings.dot.Visible = false
        end
    end

    local CrosshairModule = vape.Categories.Utility:CreateModule({
        Name = "Crosshair",
        Function = function(callback)
            crosshairEnabled = callback
            if callback then
                if not drawings.lines[1] then createDrawings() end
                renderConnection = runService.RenderStepped:Connect(updateCrosshair)
            else
                if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
                for _, d in ipairs(drawings.lines) do if d then d.Visible = false end end
                for _, d in ipairs(drawings.outlines) do if d then d.Visible = false end end
                drawings.dot.Visible = false
                drawings.texts[1].Visible = false
                drawings.texts[2].Visible = false
            end
        end
    })

    CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
    CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px", Tooltip="0 = no dot"})
    CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
    CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})
end)

-- ============== FULLBRIGHT ==============
run(function()
    local Lighting = game:GetService("Lighting")
    local origBrightness = Lighting.Brightness
    local origClockTime = Lighting.ClockTime
    local origFogEnd = Lighting.FogEnd
    local origFogStart = Lighting.FogStart
    local origGlobalShadows = Lighting.GlobalShadows
    local origOutdoorAmbient = Lighting.OutdoorAmbient

    vape.Categories.World:CreateModule({
        Name = "Fullbright",
        Function = function(callback)
            if callback then
                Lighting.Brightness = 3
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100000
                Lighting.FogStart = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = origBrightness
                Lighting.ClockTime = origClockTime
                Lighting.FogEnd = origFogEnd
                Lighting.FogStart = origFogStart
                Lighting.GlobalShadows = origGlobalShadows
                Lighting.OutdoorAmbient = origOutdoorAmbient
            end
        end
    })
end)

-- ============== NO FOG ==============
run(function()
    local Lighting = game:GetService("Lighting")
    local origFogEnd = Lighting.FogEnd
    local origFogStart = Lighting.FogStart
    vape.Categories.World:CreateModule({
        Name = "No Fog",
        Function = function(callback)
            if callback then
                Lighting.FogEnd = 100000
                Lighting.FogStart = 100000
            else
                Lighting.FogEnd = origFogEnd
                Lighting.FogStart = origFogStart
            end
        end
    })
end)

-- ============== FOV CHANGER ==============
run(function()
    local camera = workspace.CurrentCamera
    local defaultFOV = 70
    local stretchConnection = nil
    local vertFOV = defaultFOV
    local horizScale = 1.0

    local function applyStretch()
        camera.FieldOfView = vertFOV
        if horizScale ~= 1.0 then
            camera.CFrame = camera.CFrame * CFrame.new(0,0,0, 1,0,0, 0, horizScale, 0, 0,0,1)
        end
    end

    local FovModule = vape.Categories.Utility:CreateModule({
        Name = "FOV",
        Function = function(callback)
            if callback then
                stretchConnection = runService.RenderStepped:Connect(applyStretch)
            else
                if stretchConnection then stretchConnection:Disconnect(); stretchConnection = nil end
                camera.FieldOfView = defaultFOV
            end
        end
    })

    FovModule:CreateSlider({Name="Vertical", Min=10, Max=120, Default=defaultFOV, Function=function(v) vertFOV=v end, Suffix="°", Tooltip="Vertical field of view"})
    FovModule:CreateSlider({Name="Horizontal Scale", Min=50, Max=150, Default=100, Function=function(v) horizScale=v/100 end, Suffix="%", Tooltip="Stretches view horizontally"})
end)

-- ============== SPEED (WalkSpeed + CFrame Boost) ==============
run(function()
    local SpeedModule = vape.Categories.Utility:CreateModule({
        Name = "Speed",
        Function = function(callback)
            if not callback then
                if lplr and lplr.Character then
                    local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end
        end
    })

    SpeedModule:CreateSlider({
        Name = "Walk Speed", Min = 10, Max = 100, Default = 16,
        Function = function(val)
            if entitylib and entitylib.character then
                local hum = entitylib.character.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
        Suffix = "studs/s"
    })

    local cframeEnabled = false
    local cframeMultiplier = 2
    local cframeConnection

    local function cframeBoost()
        if not cframeEnabled then return end
        if entitylib and entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
            local root = entitylib.character.RootPart
            local moveDir = root.CFrame.LookVector * cframeMultiplier * 0.1
            root.CFrame = root.CFrame + moveDir
        end
    end

    SpeedModule:CreateToggle({
        Name = "CFrame Speed",
        Default = false,
        Function = function(callback)
            cframeEnabled = callback
            if callback then
                cframeConnection = runService.Heartbeat:Connect(cframeBoost)
            else
                if cframeConnection then cframeConnection:Disconnect(); cframeConnection = nil end
            end
        end
    })

    SpeedModule:CreateSlider({
        Name = "CFrame Multiplier", Min = 1, Max = 10, Default = 2,
        Darker = true,
        Function = function(v) cframeMultiplier = v end,
        Suffix = "x"
    })
end)

entitylib.start()

print("Rivals V4.1.3")
