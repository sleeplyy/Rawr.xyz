--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

-- FB
if not mouse1click then mouse1click = function() return false end end
if not isrbxactive then isrbxactive = function() return true end end
if not iswindowactive then iswindowactive = function() return true end end
if not mouse1press then mouse1press = function() end end
if not mouse1release then mouse1release = function() end end

-- Environment fallbacks
local isfile = isfile or function(file) local ok,res = pcall(readfile,file) return ok and res ~= nil and res ~= '' end
local writefile = writefile or function(file,data) end
local isfolder = isfolder or function(folder) return false end
local makefolder = makefolder or function(folder) end
local readfile = readfile or function(file) return '' end
local getcustomaudio = getcustomaudio or function(path) return nil end

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
        if v.Active and v.Visible and obj and obj.Enabled then return false end
    end
    for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then return false end
    end
    local scaledGui = vape.gui.ScaledGui
    local clickGuiVisible = scaledGui and scaledGui.ClickGui and scaledGui.ClickGui.Visible
    return not clickGuiVisible and not inputService:GetFocusedTextBox()
end

for _, v in {'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'} do vape:Remove(v) end

local t = { sa = { redirect = nil }, hs = nil }

run(function()
    local SilentAim
    local AimPart, HitChance, ClickInterval, ShowTarget
    local CircleColor, CircleTransparency, CircleFilled, CircleObject
    local autoClickConnection = nil
    local isRightDown = false
    local lastRightClick = 0
    local aimPart = "Head"
    local hitChance = 100
    local clickInterval = 0.10
    local rand = Random.new()
    local shootRemote = nil

    local function findShootRemote()
        local gunRemotes = replicatedStorage:FindFirstChild("GunRemotes")
        if gunRemotes then
            local ev = gunRemotes:FindFirstChild("ShootEvent")
            if ev then return ev end
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
        notif('Rawr.xyz', 'Shoot remote not found – SilentAim may not work', 5, 'alert')
    end

    local function getClosestPlayerToMouse()
        local closest = nil
        local shortest = math.huge
        local mousePos = inputService:GetMouseLocation()
        for _, player in ipairs(playersService:GetPlayers()) do
            if player ~= lplr and player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local screenPos, onScreen = gameCamera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortest then
                        closest = player
                        shortest = dist
                    end
                end
            end
        end
        return closest
    end

    local function getAimPart(player, partName)
        if not player or not player.Character then return nil end
        if partName == "Head" then return player.Character:FindFirstChild("Head")
        elseif partName == "Body" then return player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
        elseif partName == "Random" then
            local parts = {}
            local h = player.Character:FindFirstChild("Head")
            local r = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
            if h then table.insert(parts, h) end
            if r then table.insert(parts, r) end
            if #parts > 0 then return parts[rand.NextInteger(rand, 1, #parts)] end
        end
        return player.Character:FindFirstChild("Head")
    end

    local function redirectShots(args)
        if not SilentAim or not SilentAim.Enabled then return end
        if rand.NextNumber(rand, 0, 100) > hitChance then return end
        local target = getClosestPlayerToMouse()
        if not target then return end
        local part = getAimPart(target, aimPart)
        if not part then return end
        local origin = lplr.Character and lplr.Character:FindFirstChild("Head") and lplr.Character.Head.Position
        if not origin then return end

        local hits = args[1]
        if typeof(hits) ~= "table" then return end
        local newHits = table.create(#hits)
        for i = 1, #hits do
            newHits[i] = {origin, part.Position, part}
        end
        args[1] = newHits

        if ShowTarget and ShowTarget.Enabled and targetinfo then
            targetinfo.Targets[target] = tick() + 1
        end
        if t.hs and t.hs.play then t.hs.play() end
    end

    if shootRemote then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self == shootRemote and not checkcaller() then
                local args = {...}
                if t.sa.redirect then
                    t.sa.redirect(args)
                end
                return oldNamecall(self, unpack(args))
            end
            return oldNamecall(self, ...)
        end))
        vape:Clean(function() hookmetamethod(game, "__namecall", oldNamecall) end)
    end

    local function startRightAutoClick()
        if autoClickConnection then autoClickConnection:Disconnect() end
        autoClickConnection = runService.Heartbeat:Connect(function()
            if isRightDown and (tick() - lastRightClick >= clickInterval) then
                if canClick() then
                    mouse1click()
                    lastRightClick = tick()
                end
            end
        end)
    end

    local function stopRightAutoClick()
        if autoClickConnection then autoClickConnection:Disconnect(); autoClickConnection = nil end
    end

    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if SilentAim and SilentAim.Enabled and canClick() then
                mouse1click()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            if not isRightDown then
                isRightDown = true
                if SilentAim and SilentAim.Enabled then startRightAutoClick() end
            end
        end
    end)
    inputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightDown = false
            stopRightAutoClick()
        end
    end)

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            if callback then
                t.sa.redirect = redirectShots
            else
                t.sa.redirect = nil
                stopRightAutoClick()
            end
        end,
        Tooltip = 'Fake camera aim – bullets go to the nearest enemy. Left‑click = single, Right‑click = auto.'
    })

    AimPart = SilentAim:CreateDropdown({
        Name = 'Aim Part', List = {'Head', 'Body', 'Random'}, Default = 'Head',
        Function = function(val) aimPart = val end,
        Tooltip = 'Part of the body to aim at'
    })
    HitChance = SilentAim:CreateSlider({
        Name = 'Hit Chance', Min = 0, Max = 100, Default = 100,
        Function = function(val) hitChance = val end,
        Suffix = '%', Tooltip = 'Chance to redirect bullets'
    })
    ClickInterval = SilentAim:CreateSlider({
        Name = 'Click Interval', Min = 1, Max = 50, Default = 10,
        Function = function(val) clickInterval = val / 100 end,
        Suffix = 'ms', Tooltip = 'Time between auto‑clicks'
    })
    ShowTarget = SilentAim:CreateToggle({
        Name = 'Show Target Info', Default = true,
        Tooltip = 'Display ESP box on target'
    })

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
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled and CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor and CircleColor.Hue or 0, CircleColor and CircleColor.Sat or 1, CircleColor and CircleColor.Value or 1)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = 150
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

run(function()
    local crosshairEnabled = false
    local crosshairColor = Color3.fromRGB(128,128,128)
    local crosshairStyle = "Cross"
    local crosshairSpin = true
    local crosshairLength = 10
    local crosshairRadius = 11
    local crosshairWidth = 1.5
    local dotSize = 0
    local outlineEnabled = false
    local outlineColor = Color3.new(0,0,0)
    local outlineThickness = 0.5
    local circleThickness = 1.5
    local drawings = { lines = {}, texts = {}, dot = nil, outlines = {}, circle = nil }
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
        drawings.circle = Drawing.new('Circle')
        drawings.texts[1] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=Color3.new(1,1,1)})
        drawings.texts[2] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rivals',Color=crosshairColor})
    end

    local function updateCrosshair()
        local pos = inputService:GetMouseLocation()
        drawings.texts[1].Visible = crosshairEnabled
        drawings.texts[2].Visible = crosshairEnabled

        if crosshairEnabled then
            if text_x == 0 then text_x = drawings.texts[1].TextBounds.X + drawings.texts[2].TextBounds.X end
            drawings.texts[1].Position = pos + Vector2.new(-text_x/2, crosshairRadius+crosshairLength+15)
            drawings.texts[2].Position = drawings.texts[1].Position + Vector2.new(drawings.texts[1].TextBounds.X, 0)
            drawings.texts[2].Color = crosshairColor

            if crosshairSpin then lastSpinAngle = (tick()*360) % 360 end

            for i = 1, 8 do drawings.lines[i].Visible = false end
            for i = 1, 4 do drawings.outlines[i].Visible = false end
            drawings.dot.Visible = false
            drawings.circle.Visible = false

            if crosshairStyle == "Cross" then
                for idx = 1, 4 do
                    local inline = drawings.lines[idx+4]
                    local outline = drawings.outlines[idx]
                    local angle = (idx-1)*90 + lastSpinAngle
                    local dir = solve(angle,1)
                    local fromPos = pos + dir * crosshairRadius
                    local toPos = pos + dir * (crosshairRadius + crosshairLength)

                    inline.Visible = true; inline.Color = crosshairColor
                    inline.From = fromPos; inline.To = toPos; inline.Thickness = crosshairWidth

                    if outlineEnabled then
                        outline.Visible = true
                        outline.From = pos + dir * (crosshairRadius - outlineThickness)
                        outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                        outline.Thickness = crosshairWidth + 1.2
                        outline.Color = outlineColor
                    end
                end
            elseif crosshairStyle == "Circle" then
                drawings.circle.Visible = true
                drawings.circle.Position = pos
                drawings.circle.Radius = crosshairRadius
                drawings.circle.Filled = false
                drawings.circle.Color = crosshairColor
                drawings.circle.Thickness = circleThickness
                drawings.circle.Transparency = 0
            elseif crosshairStyle == "Dot" then
                drawings.dot.Visible = true
                drawings.dot.Position = pos
                drawings.dot.Radius = dotSize
                drawings.dot.Filled = true
                drawings.dot.Color = crosshairColor
                drawings.dot.Transparency = 0
            end
        else
            for i = 1, 8 do drawings.lines[i].Visible = false end
            for i = 1, 4 do drawings.outlines[i].Visible = false end
            drawings.dot.Visible = false
            drawings.circle.Visible = false
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
                drawings.circle.Visible = false
                drawings.texts[1].Visible = false
                drawings.texts[2].Visible = false
            end
        end
    })

    CrosshairModule:CreateDropdown({
        Name = "Style", List = {"Cross", "Circle", "Dot"}, Default = "Cross",
        Function = function(v) crosshairStyle = v end
    })
    CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
    CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth = v; circleThickness = v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px", Tooltip="0 = no dot"})
    CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
    CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})
end)

run(function()
    --
    local assetSounds = {
        {name = "Bameware", id = "rbxassetid://3124331820"},
        {name = "Bell", id = "rbxassetid://6534947240"},
        {name = "Bubble", id = "rbxassetid://6534947588"},
        {name = "Pick", id = "rbxassetid://1347140027"},
        {name = "Pop", id = "rbxassetid://198598793"},
        {name = "Rust", id = "rbxassetid://1255040462"},
        {name = "Sans", id = "rbxassetid://3188795283"},
        {name = "Fart", id = "rbxassetid://130833677"},
        {name = "Big", id = "rbxassetid://5332005053"},
        {name = "Vine", id = "rbxassetid://5332680810"},
        {name = "Bruh", id = "rbxassetid://4578740568"},
        {name = "Skeet", id = "rbxassetid://5633695679"},
        {name = "Neverlose", id = "rbxassetid://6534948092"},
        {name = "Fatality", id = "rbxassetid://6534947869"},
        {name = "Bonk", id = "rbxassetid://5766898159"},
        {name = "Minecraft", id = "rbxassetid://4018616850"},
    }

    local soundNames = {}
    local soundMap = {}
    for _, s in ipairs(assetSounds) do
        table.insert(soundNames, s.name)
        soundMap[s.name] = s.id
    end

    local hitsoundEnabled = false
    local currentSoundId = soundMap["Bell"]
    local soundCooldown = 0.1
    local lastSoundTime = 0

    local function playHitsound(soundId)
        if tick() - lastSoundTime < soundCooldown then return end
        lastSoundTime = tick()

        if soundId:match("^rbxassetid://") then
            -- 
            local sound = Instance.new("Sound", workspace.CurrentCamera)
            sound.Volume = 1
            sound.SoundId = soundId
            sound:Play()
            sound.Ended:Connect(function() sound:Destroy() end)
        else
            --
            local audioId
            local success = pcall(function()
                audioId = getcustomaudio(soundId)
            end)
            if success and audioId then
                local sound = Instance.new("Sound", workspace.CurrentCamera)
                sound.Volume = 1
                sound.SoundId = audioId
                sound:Play()
                sound.Ended:Connect(function() sound:Destroy() end)
            else
                pcall(function()
                    if syn and syn.play_audio then syn.play_audio(soundId) end
                end)
            end
        end
    end

    t.hs = {play = function()
        if hitsoundEnabled then playHitsound(currentSoundId) end
    end}

    local HitsoundModule = vape.Categories.Utility:CreateModule({
        Name = "Hitsound",
        Function = function(callback) end
    })

    HitsoundModule:CreateToggle({
        Name = "Hitsound",
        Default = false,
        Function = function(callback) hitsoundEnabled = callback end
    })

    HitsoundModule:CreateDropdown({
        Name = "Select Sound",
        List = soundNames,
        Function = function(val)
            local id = soundMap[val]
            if id then
                currentSoundId = id
                notif('Hitsound', 'Selected: ' .. val, 2, 'success')
            end
        end
    })

    HitsoundModule:CreateButton({
        Name = "Preview Sound",
        Function = function()
            if hitsoundEnabled then
                playHitsound(currentSoundId)
            else
                notif('Hitsound', 'Enable Hitsound first', 2, 'alert')
            end
        end
    })
end)

run(function()
    local Lighting = game:GetService("Lighting")
    local origBrightness = Lighting.Brightness; local origClockTime = Lighting.ClockTime
    local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart
    local origGlobalShadows = Lighting.GlobalShadows; local origOutdoorAmbient = Lighting.OutdoorAmbient
    vape.Categories.World:CreateModule({
        Name = "Fullbright",
        Function = function(callback)
            if callback then
                Lighting.Brightness = 3; Lighting.ClockTime = 12
                Lighting.FogEnd = 100000; Lighting.FogStart = 100000
                Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime
                Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart
                Lighting.GlobalShadows = origGlobalShadows; Lighting.OutdoorAmbient = origOutdoorAmbient
            end
        end
    })
end)

run(function()
    local Lighting = game:GetService("Lighting")
    local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart
    vape.Categories.World:CreateModule({
        Name = "No Fog",
        Function = function(callback)
            if callback then Lighting.FogEnd = 100000; Lighting.FogStart = 100000
            else Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart end
        end
    })
end)

run(function()
    local camera = workspace.CurrentCamera
    local defaultFOV = 70
    local stretchConnection = nil
    local vertFOV = defaultFOV
    local horizScale = 1.0
    local zoomDistance = 12
    local lockFOV = false

    local function applyStretch()
        if lockFOV then return end
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

    FovModule:CreateSlider({Name="Vertical FOV", Min=10, Max=120, Default=defaultFOV, Function=function(v) vertFOV=v end, Suffix="°", Tooltip="Vertical field of view"})
    FovModule:CreateSlider({Name="Horizontal Scale", Min=50, Max=150, Default=100, Function=function(v) horizScale=v/100 end, Suffix="%", Tooltip="Stretches view horizontally"})
    FovModule:CreateSlider({Name="Zoom Distance", Min=1, Max=50, Default=12, Function=function(v) zoomDistance=v end, Suffix="studs", Tooltip="Camera distance from character"})
    FovModule:CreateToggle({Name="Lock FOV", Default=false, Function=function(v) lockFOV=v end, Tooltip="Prevent FOV from being changed by the game"})
end)

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
    local cframeSpeedSlider

    SpeedModule:CreateToggle({
        Name = "CFrame Speed",
        Default = false,
        Function = function(callback)
            cframeEnabled = callback
            if cframeSpeedSlider then cframeSpeedSlider.Object.Visible = callback end
            if callback then
                cframeConnection = runService.Heartbeat:Connect(function()
                    if entitylib and entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
                        local root = entitylib.character.RootPart
                        local moveDir = root.CFrame.LookVector * cframeMultiplier * 0.1
                        root.CFrame = root.CFrame + moveDir
                    end
                end)
            else
                if cframeConnection then cframeConnection:Disconnect(); cframeConnection = nil end
            end
        end
    })

    cframeSpeedSlider = SpeedModule:CreateSlider({
        Name = "CFrame Multiplier", Min = 1, Max = 10, Default = 2,
        Darker = true, Visible = false,
        Function = function(v) cframeMultiplier = v end,
        Suffix = "x"
    })
end)

entitylib.start()

print("V4.1.7")
