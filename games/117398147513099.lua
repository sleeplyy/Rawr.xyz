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
    print("[Rivals] Executor: " .. execName .. " | Version: " .. execVersion)
    notif('Rivals', 'Executor: ' .. execName .. ' | v' .. execVersion, 5, 'info')
    local allowed = {Madium = true, Velocity = true, Sirhurt = true, Volt = true, LX63 = true}
    if not allowed[execName] then
        notif('Rivals', 'Your Executor is too bad to use all features :(', 6, 'alert')
    end
end

local function safeCall(desc, func)
    local ok, err = pcall(func)
    if not ok then
        notif('Rivals', desc .. ' failed: ' .. tostring(err), 3, 'alert')
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

local t = {
    sa = {target = nil, enabled = false}
}

-- ============== SILENT AIM (IMPROVED) ==============
run(function()
    local SilentAim
    local Mode, Range, ShowTarget, CircleColor, CircleTransparency, CircleFilled, CircleObject
    local renderConnection, autoClickConnection = nil, nil
    local isLeftDown, isRightDown = false, false
    local lastClickTime = 0
    local clickInterval = 0.10

    local function isLobbyVisible()
        local mainGui = lplr.PlayerGui:FindFirstChild("MainGui")
        if mainGui then
            local mainFrame = mainGui:FindFirstChild("MainFrame")
            if mainFrame then
                local lobby = mainFrame:FindFirstChild("Lobby")
                if lobby then
                    local currency = lobby:FindFirstChild("Currency")
                    if currency then
                        return currency.Visible == true
                    end
                end
            end
        end
        return false
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

    local function lockCameraToHead(player)
        if not player or not player.Character or not player.Character:FindFirstChild("Head") then return end
        local head = player.Character.Head
        local camPos = gameCamera.CFrame.Position
        gameCamera.CFrame = CFrame.new(camPos, head.Position)
    end

    local function autoClick()
        if autoClickConnection then
            autoClickConnection:Disconnect()
        end
        autoClickConnection = runService.Heartbeat:Connect(function()
            if (isLeftDown or isRightDown) and (tick() - lastClickTime >= clickInterval) then
                if not isLobbyVisible() and canClick() then
                    mouse1click()
                    lastClickTime = tick()
                end
            else
                -- keep connection alive, just don't click
            end
        end)
    end

    local function startAutoClick()
        if autoClickConnection then autoClickConnection:Disconnect() end
        autoClickConnection = runService.Heartbeat:Connect(function()
            if (isLeftDown or isRightDown) and (tick() - lastClickTime >= clickInterval) then
                if not isLobbyVisible() and canClick() then
                    mouse1click()
                    lastClickTime = tick()
                end
            end
        end)
    end

    local function stopAutoClick()
        if autoClickConnection then
            autoClickConnection:Disconnect()
            autoClickConnection = nil
        end
    end

    -- Track mouse buttons
    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftDown = true
            if SilentAim and SilentAim.Enabled then startAutoClick() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightDown = true
            if SilentAim and SilentAim.Enabled then startAutoClick() end
        end
    end)
    inputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftDown = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightDown = false
        end
        if not isLeftDown and not isRightDown then
            stopAutoClick()
        end
    end)

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            if callback then
                renderConnection = runService.Heartbeat:Connect(function()
                    if not isLobbyVisible() then
                        local player = getClosestPlayerToMouse()
                        t.sa.target = player
                        if player then
                            lockCameraToHead(player)
                            if ShowTarget and ShowTarget.Enabled then
                                targetinfo.Targets[player] = tick() + 1
                            end
                        end
                    end
                end)
            else
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                stopAutoClick()
                t.sa.target = nil
            end
        end,
        Tooltip = 'Locks camera to closest visible enemy.'
    })

    Mode = SilentAim:CreateDropdown({
        Name = 'Mode',
        List = {'Mouse'},
        Default = 'Mouse',
        Tooltip = 'Target nearest player to cursor'
    })
    Range = SilentAim:CreateSlider({
        Name = 'Max Distance',
        Min = 1, Max = 1000, Default = 200,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    ShowTarget = SilentAim:CreateToggle({
        Name = 'Show Target Info',
        Default = true,
        Tooltip = 'Show detection box on target'
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
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color', Function = function(hue,sat,val) if CircleObject then CircleObject.Color = Color3.fromHSV(hue,sat,val) end end,
        Darker = true, Visible = false
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency', Min = 0, Max = 1, Decimal = 10, Default = 0.5,
        Function = function(val) if CircleObject then CircleObject.Transparency = 1 - val end end,
        Darker = true, Visible = false
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled', Function = function(callback) if CircleObject then CircleObject.Filled = callback end end,
        Darker = true, Visible = false
    })
end)

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
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
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
                if stretchConnection then
                    stretchConnection:Disconnect()
                    stretchConnection = nil
                end
                camera.FieldOfView = defaultFOV
            end
        end
    })

    FovModule:CreateSlider({
        Name = "Vertical",
        Min = 10, Max = 120, Default = defaultFOV,
        Function = function(val) vertFOV = val end,
        Suffix = "°", Tooltip = "Vertical field of view"
    })
    FovModule:CreateSlider({
        Name = "Horizontal Scale",
        Min = 50, Max = 150, Default = 100,
        Function = function(val) horizScale = val / 100 end,
        Suffix = "%", Tooltip = "Stretches view horizontally"
    })
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

    local walkSpeedSlider = SpeedModule:CreateSlider({
        Name = "Walk Speed",
        Min = 10, Max = 100, Default = 16,
        Function = function(val)
            if entitylib and entitylib.character then
                local hum = entitylib.character.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
        Suffix = "studs/s"
    })

    local cframeEnabled = false
    local cframeSpeedSlider = nil
    local cframeConnection = nil

    local function cframeBoost()
        if not cframeEnabled then return end
        if entitylib and entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
            local root = entitylib.character.RootPart
            local speed = cframeSpeedSlider and cframeSpeedSlider.Value or 2
            local moveDir = root.CFrame.LookVector * speed * 0.1
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
                if cframeConnection then
                    cframeConnection:Disconnect()
                    cframeConnection = nil
                end
            end
        end
    })

    cframeSpeedSlider = SpeedModule:CreateSlider({
        Name = "CFrame Multiplier",
        Min = 1, Max = 10, Default = 2,
        Darker = true,
        Visible = false,
        Function = function(val) end,
        Suffix = "x"
    })

    SpeedModule:CreateToggle({
        Name = "CFrame Speed",
        Default = false,
        Function = function(callback)
            cframeEnabled = callback
            if cframeSpeedSlider then
                cframeSpeedSlider.Object.Visible = callback
            end
            if callback then
                cframeConnection = runService.Heartbeat:Connect(cframeBoost)
            else
                if cframeConnection then
                    cframeConnection:Disconnect()
                    cframeConnection = nil
                end
            end
        end
    })
end)

entitylib.start()

print("Rivals V4.1.0")
