local run = function(func, issue)
    if issue then return end
    func()
end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local teamService = cloneref(game:GetService('Teams'))
local workspaceService = cloneref(game:GetService('Workspace'))
local replicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local guiService = cloneref(game:GetService('GuiService'))
local vimService = cloneref(game:GetService('VirtualInputManager'))
local playerGui = cloneref(playersService.LocalPlayer:WaitForChild("PlayerGui"))

local remotes = replicatedStorageService:WaitForChild("Remotes")
local gunRemotes = replicatedStorageService:WaitForChild("GunRemotes")

local ShootEvent = gunRemotes:WaitForChild("ShootEvent")

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo

local function notif(...) return vape:CreateNotification(...) end

local function canClick()
    local mousepos =
        (inputService:GetMouseLocation() - guiService:GetGuiInset())
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
    return (not vape.gui.ScaledGui.ClickGui.Visible) and
               (not inputService:GetFocusedTextBox())
end

for _, v in {
    'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'
} do vape:Remove(v) end

local t = {
    d = {l = CFrame.new(), s = CFrame.new()}, -- desync
    bt = {m = false, q = false, p = Vector3.new()}, -- bullet manip (client)
    sa = {hooks = {}, toggle = nil}, -- silent aim
    hn = {e = false} -- hit notifications
}

run(function()
    vape:Clean(runService.Heartbeat:Connect(function()
        if lplr.Character and t.d.s ~= CFrame.new() then
            local character = lplr.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                t.d.l = root.CFrame
                root.CFrame = t.d.s
                runService.RenderStepped:Wait()
                root.CFrame = t.d.l
            end
        end
    end))

    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if t.d.s ~= CFrame.new() and not checkcaller() and key == "CFrame" and
            lplr.Character and lplr.Character.HumanoidRootPart and self ==
            lplr.Character.HumanoidRootPart then return t.d.l end
        return old(self, key)
    end))

    vape:Clean(function() hookmetamethod(game, "__index", old) end)
end)

run(function() -- visual bullet manip
    vape:Clean(gameCamera.ChildAdded:Connect(function(child)
        if typeof(child.Transparency) == "number" then
            child.Transparency = 1
        end
        if child.Name ~= "RayPart" or not child:IsA("BasePart") or not t.bt.m then
            if typeof(child.Transparency) == "number" then
                child.Transparency = 0
            end
            return
        end

        task.spawn(function()
            task.wait()

            local length = child.Size.Z
            local lookVector = child.CFrame.LookVector
            local mid = child.CFrame.Position

            local start = mid - lookVector * (length / 2)
            local dist =
                (start - entitylib.character.RootPart.Position).Magnitude
            if dist > 5 then return end

            local newEnd = t.bt.p
            local newLength = (newEnd - start).Magnitude
            local newMid = (start + newEnd) / 2

            child.Size = Vector3.new(child.Size.X, child.Size.Y, newLength)
            child.CFrame = CFrame.new(newMid, newEnd)

            if t.bt.q == false then
                t.bt.q = true
                task.delay(1, function()
                    t.bt.m = false
                    t.bt.q = false
                end)
            end
        end)

        child.Transparency = 0
    end))
end)

run(function() -- this is always on bcuz uh i said so
    local old

    old = hookmetamethod(game, '__namecall', function(self, ...)
        if getnamecallmethod() ~= "FireServer" or self ~= ShootEvent then
            return old(self, ...)
        end
        if checkcaller() then return old(self, ...) end

        local args = {...}
        if typeof(args[1]) == "table" then t.sa.hooks.PrisonLife(args) end

        return old(self, unpack(args))
    end)

    vape:Clean(function() hookmetamethod(game, "__namecall", old) end)
end)

run(function()
    local RequestTeamChange = remotes:WaitForChild("RequestTeamChange")
    local Shippingcontainers = workspaceService:WaitForChild(
                                   "Shippingcontainers")
    local TeamSwitcher
    local Team

    TeamSwitcher = vape.Categories.Utility:CreateModule({
        Name = "TeamSwitcher",
        Function = function(callback)
            if callback == true then
                notif('Vape', 'Please expand this module to use it', 3, 'alert')
                TeamSwitcher:Toggle()
            end
        end
    })
    Team = TeamSwitcher:CreateDropdown({
        Name = "Select Team",
        List = {"Criminals", "Inmates", "Guards", "Neutral"},
        Tooltip = "Select a team to switch to"
    })
    TeamSwitcher:CreateButton({
        Name = "Switch",
        Function = function()
            if Team.Value == "Neutral" then
                RequestTeamChange:InvokeServer(teamService.Neutral, 1)
            elseif Team.Value == "Guards" then
                RequestTeamChange:InvokeServer(teamService.Neutral, 1)
                task.wait(1.5)
                RequestTeamChange:InvokeServer(teamService.Guards, 1)
                task.delay(1, function()
                    if lplr.Team ~= teamService.Guards then
                        notif('Vape',
                              'Failed to switch to guards team, please try again later',
                              3, 'alert')
                    end
                end)
            elseif Team.Value == "Criminals" then
                if lplr.Team == teamService.Inmates then
                    repeat
                        t.d.s = Shippingcontainers.WorldPivot
                        task.wait(0.05)
                    until lplr.Team == teamService.Criminals
                    t.d.s = CFrame.new()
                    -- entitylib.character.Humanoid.Health = 0
                else
                    notif('Vape',
                          'Please switch to the inmates team and try again', 3,
                          'alert')
                end
            elseif Team.Value == "Inmates" then
                RequestTeamChange:InvokeServer(game:GetService("Teams").Neutral,
                                               1)
                task.wait(1.5)
                RequestTeamChange:InvokeServer(game:GetService("Teams").Inmates,
                                               1)
                task.delay(1, function()
                    if lplr.Team ~= teamService.Inmates then
                        notif('Vape',
                              'Failed to switch to inmates team, please try again later',
                              3, 'alert')
                    end
                end)
            end
        end
    })
end)

entitylib.start()

run(function()
    local AutoReload
    local AutoSwitch
    local AutoReloadConnection
    local ItemAddedConnection
    local ToolConnection
    local OwnShotgun = false
    local OwnSniper = false
    local Shotgun = nil
    local Sniper = nil

    local function reload()
        vimService:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        vimService:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end

    local function getAmmoOrReloading(v) -- we have this so that we can check guns we haven't used yet
        local reloading = v:GetAttribute("Local_ReloadSession")
        if reloading and reloading == 0 then return true end
        local ammo = v:GetAttribute("Local_CurrentAmmo")
        local maxAmmo = v:GetAttribute("MaxAmmo")
        local serverAmmo = v:GetAttribute("CurrentAmmo")
        if ammo and ammo > 0 or (ammo == 0 and serverAmmo == maxAmmo) then
            return true
        end
    end

    local function getToolWithAmmo()
        local backpack = lplr:FindFirstChildOfClass("Backpack")
        if entitylib.isAlive and backpack then
            local tools = backpack:GetChildren()

            if OwnSniper and Sniper and getAmmoOrReloading(Sniper) then
                entitylib.character.Character.Humanoid:UnequipTools()
                entitylib.character.Character.Humanoid:EquipTool(Sniper)
                return
            end

            if OwnShotgun and Shotgun and getAmmoOrReloading(Shotgun) then
                entitylib.character.Character.Humanoid:UnequipTools()
                entitylib.character.Character.Humanoid:EquipTool(Shotgun)
                return
            end

            for _, v in pairs(tools) do
                if v:IsA("Tool") and v.Name ~= "Taser" then
                    if getAmmoOrReloading(v) then
                        entitylib.character.Character.Humanoid:UnequipTools()
                        entitylib.character.Character.Humanoid:EquipTool(v)
                        return
                    end
                end
            end
        end
    end

    local function itemAdded(v)
        if ToolConnection then ToolConnection:Disconnect() end
        if v:IsA("Tool") then
            if v:GetAttribute("Behavior") == "Sniper" then
                OwnSniper = true
                Sniper = v
            elseif v:GetAttribute("Behavior") == "Shotgun" then
                OwnShotgun = true
                Shotgun = v
            end
            ToolConnection = v:GetAttributeChangedSignal("Local_CurrentAmmo")
                                 :Connect(function()
                    local ammo = v:GetAttribute("Local_CurrentAmmo")
                    if ammo and ammo <= 0 then
                        reload()
                        if AutoSwitch.Enabled and v.Name ~= "Taser" then
                            repeat
                                getToolWithAmmo()
                                task.wait()
                            until entitylib.character.Character:FindFirstChildOfClass(
                                "Tool") and
                                entitylib.character.Character:FindFirstChildOfClass(
                                    "Tool") and
                                entitylib.character.Character:FindFirstChildOfClass(
                                    "Tool"):GetAttribute("Local_CurrentAmmo") and
                                entitylib.character.Character:FindFirstChildOfClass(
                                    "Tool"):GetAttribute("Local_CurrentAmmo") >
                                0
                        end
                    end
                end)
        end
    end

    local function characterAdded(char)
        ItemAddedConnection = char.Character.ChildAdded:Connect(itemAdded)
        ItemAddedConnection = lplr.Backpack.ChildAdded:Connect(itemAdded)
        OwnShotgun = false
        OwnSniper = false
        Sniper = nil
        Shotgun = nil
    end

    AutoReload = vape.Categories.Combat:CreateModule({
        Name = "AutoReload",
        Function = function(callback)
            if callback then
                AutoReloadConnection = entitylib.Events.LocalAdded:Connect(
                                           characterAdded)
                if entitylib.isAlive then
                    characterAdded(entitylib.character)
                end
            else
                if AutoReloadConnection then
                    AutoReloadConnection:Disconnect()
                end
                if ItemAddedConnection then
                    ItemAddedConnection:Disconnect()
                end
            end
        end
    }) -- we would use module:Clean() however it's deciding to not work for some reason, so we will just disconnect the connections manually
    AutoSwitch = AutoReload:CreateToggle({
        Name = "AutoSwitch",
        Tooltip = "Auto switches to a gun with ammo. Forces you to always hold a gun."
    })
end)

local mouseClicked
run(function()
    local SilentAim
    local Target
    local Mode
    local Range
    local HitChance
    local HeadshotChance
    local AutoFire
    local AutoFireShootDelay
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleObject
    local Face
    local ShowTarget
    local rand, delayCheck = Random.new(), tick()
    local GunTracers =
        require(replicatedStorageService.SharedModules.GunTracers)
    local hud = playerGui:FindFirstChild("Home"):FindFirstChild("Hud")
    -- local IgnorePrisoners
    local Method

    local function tryShoot(origin, targetPart, tool)
        if tool then
            if tool:GetAttribute("Local_CurrentAmmo") and
                tool:GetAttribute("Local_CurrentAmmo") <= 0 then
                return
            elseif not tool:GetAttribute("Local_CurrentAmmo") then
                return
            end

            if tool:GetAttribute("Local_CurrentAmmo") > 0 and
                tool:GetAttribute("Local_ReloadSession") <= 0 then
                tool:SetAttribute("Local_IsShooting", true)
                local projectileCount = tool:GetAttribute("ProjectileCount") or
                                            1
                local hits = {}
                for _ = 1, projectileCount do
                    local muzzle = (tool:FindFirstChild("muzzle") and
                                       tool.muzzle.Position) or origin

                    if tool:GetAttribute("Behavior") == "Sniper" then
                        GunTracers.createSniper(muzzle, targetPart.Position)
                    elseif tool:GetAttribute("Behavior") == "Taser" then
                        GunTracers.createTaser(muzzle, targetPart.Position)
                    else
                        GunTracers.createBullet(muzzle, targetPart.Position)
                    end

                    table.insert(hits, {origin, targetPart.Position, targetPart})
                end

                ShootEvent:FireServer(hits)

                local newAmmo = tool:GetAttribute("Local_CurrentAmmo") - 1
                tool:SetAttribute("Local_CurrentAmmo", newAmmo)

                local BottomRightFrame = hud and
                                             hud:FindFirstChild(
                                                 "BottomRightFrame")
                if BottomRightFrame then
                    local gunFrame = BottomRightFrame:FindFirstChild("GunFrame")
                    if gunFrame then
                        local bulletsLabel = gunFrame and
                                                 gunFrame:FindFirstChild(
                                                     "BulletsLabel")

                        if tool:GetAttribute("Behavior") == "Sniper" and
                            bulletsLabel then
                            bulletsLabel.Text = newAmmo .. " | " ..
                                                    tool:GetAttribute(
                                                        "StoredAmmo")
                        else
                            bulletsLabel.Text = newAmmo .. "/" ..
                                                    tool:GetAttribute("MaxAmmo")
                        end
                    end
                end
            end
            tool:SetAttribute("Local_IsShooting", false)
        end
    end

    local function getTarget(origin, obj)
        if rand.NextNumber(rand, 0, 100) >
            (AutoFire.Enabled and 100 or HitChance.Value) then return end
        local targetPart = (rand.NextNumber(rand, 0, 100) <
                               (AutoFire.Enabled and 100 or HeadshotChance.Value)) and
                               'Head' or 'RootPart'
        local ent = entitylib['Entity' .. Mode.Value]({
            Range = Range.Value,
            Wallcheck = Target.Walls.Enabled and (obj or true) or nil,
            Part = targetPart,
            Origin = origin,
            Players = Target.Players.Enabled,
            NPCs = Target.NPCs.Enabled
        })

        if ent then targetinfo.Targets[ent] = tick() + 1 end

        return ent, ent and ent[targetPart], origin
    end

    t.sa.hooks.PrisonLife = function(args)
        local ent, targetPart, origin = getTarget(
                                            entitylib.isAlive and
                                                entitylib.character.Head
                                                    .Position)
        if not ent or typeof(args[1]) ~= "table" then return end

        local originalHits = args[1]
        local count = math.clamp(#originalHits, 1, 20)
        if SilentAim.Enabled then
            local newHits = table.create(count)

            for i = 1, count do
                newHits[i] = {origin, targetPart.Position, targetPart}
            end

            args[1] = newHits

            if t.hn.e then
                notif('Vape', 'attempted to hit ' .. targetPart.Parent.Name ..
                          "'s " .. targetPart.Name, 3)
            end
            return
        else
            if t.hn.e then
                for _, v in originalHits do
                    local part = v[3]
                    if typeof(part) == "Instance" and part.Parent and
                        part.Parent:FindFirstChild("Humanoid") then
                        notif('Vape',
                              'hit ' .. part.Parent.Name .. "'s " .. part.Name,
                              3)
                    end
                end
            end
            return
        end
        return
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if CircleObject then
                CircleObject.Visible = callback and Mode.Value == 'Mouse'
            end
            if callback then
                repeat
                    if entitylib.isAlive then
                        local origin = entitylib.isAlive and
                                           entitylib.character.Head.CFrame
                        local ent = entitylib['Entity' .. Mode.Value]({
                            Range = Range.Value,
                            Wallcheck = Target.Walls.Enabled or nil,
                            Part = 'Head',
                            Origin = origin.Position,
                            Players = Target.Players.Enabled,
                            NPCs = Target.NPCs.Enabled
                        })

                        if ShowTarget.Enabled and ent then
                            targetinfo.Targets[ent] = tick() + 1
                        end

                        if CircleObject then
                            CircleObject.Position =
                                inputService:GetMouseLocation()
                        end
                        if AutoFire.Enabled then

                            if mouse1click and (isrbxactive or iswindowactive)() then
                                if ent and canClick() then
                                    if Method.Value == 'Click' then
                                        if delayCheck < tick() then
                                            if mouseClicked then
                                                mouse1release()
                                                delayCheck = tick() +
                                                                 AutoFireShootDelay.Value
                                            else
                                                mouse1press()
                                            end
                                            mouseClicked = not mouseClicked
                                        else
                                            if mouseClicked then
                                                mouse1release()
                                                mouseClicked = false
                                            end
                                        end
                                    else
                                        if delayCheck < tick() then
                                            delayCheck = tick() +
                                                             AutoFireShootDelay.Value
                                            tryShoot(origin.Position, ent.Head,
                                                     entitylib.character
                                                         .Character:FindFirstChildOfClass(
                                                         "Tool"))
                                        end
                                    end
                                end
                            end
                        end

                        if Face.Enabled and ent then
                            local vec = ent.HumanoidRootPart.Position *
                                            Vector3.new(1, 0, 1)
                            entitylib.character.RootPart.CFrame = CFrame.lookAt(
                                                                      entitylib.character
                                                                          .RootPart
                                                                          .Position,
                                                                      Vector3.new(
                                                                          vec.X,
                                                                          entitylib.character
                                                                              .RootPart
                                                                              .Position
                                                                              .Y +
                                                                              0.01,
                                                                          vec.Z))
                        end

                        if ent and ent.Character and
                            ent.Character:FindFirstChild("HumanoidRootPart") then
                            t.bt.m = true
                            t.bt.p = ent.HumanoidRootPart.Position
                        end
                    end
                    task.wait()
                until not SilentAim.Enabled
            end
        end,
        Tooltip = 'Silently adjusts your aim towards the enemy'
    })
    Target = SilentAim:CreateTargets({Players = true})
    Mode = SilentAim:CreateDropdown({
        Name = 'Mode',
        List = {'Mouse', 'Position'},
        Function = function(val)
            if CircleObject then
                CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
            end
        end,
        Tooltip = 'Mouse - Checks for entities near the mouses position\nPosition - Checks for entities near the local character'
    })
    Range = SilentAim:CreateSlider({
        Name = 'Range',
        Min = 1,
        Max = 1000,
        Default = 150,
        Function = function(val)
            if CircleObject then CircleObject.Radius = val end
        end,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    HitChance = SilentAim:CreateSlider({
        Name = 'Hit Chance',
        Min = 0,
        Max = 100,
        Default = 85,
        Suffix = '%'
    })
    HeadshotChance = SilentAim:CreateSlider({
        Name = 'Headshot Chance',
        Min = 0,
        Max = 100,
        Default = 65,
        Suffix = '%'
    })
    AutoFire = SilentAim:CreateToggle({
        Name = 'AutoFire',
        Function = function(callback)
            AutoFireShootDelay.Object.Visible = callback
            Method.Object.Visible = callback
        end
    })
    AutoFireShootDelay = SilentAim:CreateSlider({
        Name = 'Next Shot Delay',
        Min = 0,
        Max = 1,
        Decimal = 100,
        Visible = false,
        Darker = true,
        Suffix = function(val) return val == 1 and 'second' or 'seconds' end
    })
    Method = SilentAim:CreateDropdown({
        Name = 'Shoot Method',
        List = {'Simulation', 'Click'}
    })
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor.Hue,
                                                    CircleColor.Sat,
                                                    CircleColor.Value)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = Range.Value
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - CircleTransparency.Value
                CircleObject.Visible = SilentAim.Enabled and Mode.Value ==
                                           'Mouse'
            else
                pcall(function()
                    CircleObject.Visible = false
                    CircleObject:Remove()
                end)
            end
            CircleColor.Object.Visible = callback
            CircleTransparency.Object.Visible = callback
            CircleFilled.Object.Visible = callback
        end
    })
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color',
        Function = function(hue, sat, val)
            if CircleObject then
                CircleObject.Color = Color3.fromHSV(hue, sat, val)
            end
        end,
        Darker = true,
        Visible = false
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency',
        Min = 0,
        Max = 1,
        Decimal = 10,
        Default = 0.5,
        Function = function(val)
            if CircleObject then CircleObject.Transparency = 1 - val end
        end,
        Darker = true,
        Visible = false
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled',
        Function = function(callback)
            if CircleObject then CircleObject.Filled = callback end
        end,
        Darker = true,
        Visible = false
    })
    Face = SilentAim:CreateToggle({Name = 'Face target'})
    ShowTarget = SilentAim:CreateToggle({Name = "Show Target Info"})
    -- IgnorePrisoners = SilentAim:CreateToggle({Name = "Ignore Prisoners"})
end)

run(function()
    local Pitch
    local Original = CFrame.new()

    Pitch = vape.Categories.Blatant:CreateModule({
        Name = 'Head Pitch Spinbot (Client)',
        Function = function(callback)
            if callback then
                if entitylib.character and entitylib.character.Character and
                    entitylib.character.Character:FindFirstChild("Torso") and
                    entitylib.character.Character.Torso:FindFirstChild("Neck") then
                    Original = entitylib.character.Character.Torso.Neck.C1

                    Pitch:Clean(runService.PreSimulation:Connect(function()
                        if entitylib.isAlive then
                            local character = entitylib.character.Character
                            local torso = character:FindFirstChild("Torso")
                            if torso then
                                torso.Neck.C1 = torso.Neck.C1 *
                                                    CFrame.Angles(math.rad(145),
                                                                  0, 0)
                            end
                        end
                    end))
                end
            else
                if entitylib.isAlive then
                    local character = entitylib.character.Character
                    local torso = character:FindFirstChild("Torso")
                    if torso then torso.Neck.C1 = Original end
                end
            end
        end
    })
end)

run(function()
    vape.Categories.Combat:CreateModule({
        Name = "HitNotifications",
        Function = function(callback) t.hn.e = callback end
    })
end)

run(function()
    local GunMods
    local Range
    local SpreadRadius
    local FireRate

    local function itemAdded(v)
        if v and v:IsA("Tool") and v:GetAttribute("Local_ReloadSession") then
            v:SetAttribute("Range", Range.Value)
            v:SetAttribute("AccurateRange", Range.Value)
            v:SetAttribute("SpreadRadius", SpreadRadius.Value)
            v:SetAttribute("FireRate", FireRate.Value)
        end
    end

    local function characterAdded(char)
        GunMods:Clean(char.Character.ChildAdded:Connect(itemAdded))
        GunMods:Clean(lplr.Backpack.ChildAdded:Connect(itemAdded))

        for _, v in char.Character:GetChildren() do itemAdded(v) end

        for _, v in lplr.Backpack:GetChildren() do itemAdded(v) end
    end

    GunMods = vape.Categories.Combat:CreateModule({
        Name = "GunMods",
        Function = function(callback)
            if callback then
                if entitylib.character then
                    characterAdded(entitylib.character)
                end
                GunMods:Clean(
                    entitylib.Events.LocalAdded:Connect(characterAdded))
            end
        end
    })
    Range = GunMods:CreateSlider({
        Name = "Range",
        Min = 1,
        Max = 9999,
        Default = 150,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    SpreadRadius = GunMods:CreateSlider({
        Name = "Spread Radius",
        Min = 0,
        Max = 1,
        Default = 0.03,
        Decimal = 100,
        Suffix = 'studs'
    })
    FireRate = GunMods:CreateSlider({
        Name = "Fire Rate",
        Min = 0,
        Max = 1,
        Decimal = 100,
        Default = 0.1,
        Suffix = function(val) return val == 1 and 'second' or 'seconds' end
    })
end)

run(function()
    local AutoPickup
    local PrisonItems = {}
    local Keycard
    local M9
    local GiverPressed = remotes:WaitForChild("GiverPressed")

    local function checkInv(v, name)
        local backpack = entitylib.character.Player.Backpack
        local character = entitylib.character.Character

        if backpack and character then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.Name == (name or v.Name) then
                    return true
                end
            end
            for _, tool in pairs(character:GetChildren()) do
                if tool:IsA("Tool") and tool.Name == (name or v.Name) then
                    return true
                end
            end
        end

        return false
    end

    local function pickUp(v, name)
        if not entitylib.isAlive then return end
        if checkInv(v) then return end

        local handle = v:FindFirstChildWhichIsA("MeshPart") or
                           v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart

        if handle then
            local position = handle.CFrame
            local new = CFrame.new(position.X, position.Y - 5, position.Z)

            repeat
                t.d.s = new
                GiverPressed:FireServer(v)
                task.wait(0.5)
            until checkInv(v, name) or not entitylib.isAlive

            t.d.s = CFrame.new()

            return
        end
    end

    local function canPickup(v)
        if v and v.Parent and v.Parent.Name == "Model" then
            if entitylib.character.Player.Team == teamService.Criminals then
                return true
            else
                return false
            end
        end

        if entitylib.character.Player.Team ==
            (teamService.Inmates or teamService.Guards) then return true end
    end

    AutoPickup = vape.Categories.Utility:CreateModule({
        Name = "AutoPickup",
        Function = function(callback)
            if callback then
                AutoPickup:Clean(entitylib.Events.LocalAdded:Connect(function()
                    if entitylib.isAlive then
                        for _, item in pairs(PrisonItems) do
                            if item.Enabled and item.Object and
                                canPickup(item.Object) then
                                pickUp(item.Object, item.Gun)
                            end
                        end
                    end
                end))

                AutoPickup:Clean(workspaceService.ChildAdded:Connect(function(v)
                    if (v.Name == "Key card" and Keycard.Enabled) or
                        (v.Name == "M9" and M9.Enabled) and lplr.Team ~=
                        teamService.Guards then
                        pickUp(v) -- there might be an issue with picking up these items, don't wanna look into right now
                    end
                end))
            end
        end,
        Tooltip = "Automatically picks up guns when you respawn, or keycard and m9 when dropped."
    })

    Keycard = AutoPickup:CreateToggle({
        Name = "Key card",
        Function = function() end
    })
    M9 = AutoPickup:CreateToggle({Name = "M9", Function = function() end})

    for _, i in pairs(workspaceService:GetDescendants()) do
        if i.Name == "TouchGiver" then
            local tool = i:GetAttribute("ToolName")
            if not PrisonItems[tool] and tool then
                PrisonItems[tool] = AutoPickup:CreateToggle({
                    Name = tool,
                    Function = function() end,
                    Tooltip = "Only works on respawn" ..
                        (i and i.Parent and i.Parent.Name == "Model" and
                            " and as a criminal" or " and as an inmate or guard")
                })
                PrisonItems[tool].Object = i
                PrisonItems[tool].Gun = tool
            end
        end
    end
end)

run(function()
    local meleeEvent = replicatedStorageService:WaitForChild("meleeEvent")
    local Killaura
    local Targets
    local CPS
    local AttackRange
    local AngleSlider
    local Max
    local BoxSwingColor
    local BoxAttackColor
    local ParticleTexture
    local ParticleColor1
    local ParticleColor2
    local ParticleSize
    local Face
    local Overlay = OverlapParams.new()
    Overlay.FilterType = Enum.RaycastFilterType.Include
    local Particles, Boxes, AttackDelay = {}, {}, tick()

    Killaura = vape.Categories.Blatant:CreateModule({
        Name = 'KillAura',
        Function = function(callback)
            if callback then
                repeat
                    local attacked = {}
                    local plrs = entitylib.AllPosition({
                        Range = AttackRange.Value,
                        Wallcheck = Targets.Walls.Enabled or nil,
                        Part = 'RootPart',
                        Players = Targets.Players.Enabled,
                        NPCs = Targets.NPCs.Enabled,
                        Limit = Max.Value
                    })

                    if #plrs > 0 then
                        local selfpos = entitylib.character.RootPart.Position
                        local localfacing =
                            entitylib.character.RootPart.CFrame.LookVector *
                                Vector3.new(1, 0, 1)

                        for _, v in plrs do
                            local delta = (v.RootPart.Position - selfpos)
                            local angle = math.acos(
                                              localfacing:Dot((delta *
                                                                  Vector3.new(1,
                                                                              0,
                                                                              1)).Unit))
                            if angle > (math.rad(AngleSlider.Value) / 2) then

                                table.insert(attacked, {
                                    Entity = v,
                                    Check = delta.Magnitude > AttackRange.Value and
                                        BoxSwingColor or BoxAttackColor
                                })
                                targetinfo.Targets[v] = tick() + 1

                                if AttackDelay < tick() then
                                    AttackDelay = tick() +
                                                      (1 / CPS.GetRandomValue())
                                    meleeEvent:FireServer(v.Player, 1, 1)
                                end

                            end
                        end
                    end

                    for i, v in Boxes do
                        v.Adornee =
                            attacked[i] and attacked[i].Entity.RootPart or nil
                        if v.Adornee then
                            v.Color3 = Color3.fromHSV(attacked[i].Check.Hue,
                                                      attacked[i].Check.Sat,
                                                      attacked[i].Check.Value)
                            v.Transparency = 1 - attacked[i].Check.Opacity
                        end
                    end

                    for i, v in Particles do
                        v.Position = attacked[i] and
                                         attacked[i].Entity.RootPart.Position or
                                         Vector3.new(9e9, 9e9, 9e9)
                        v.Parent = attacked[i] and gameCamera or nil
                    end

                    if Face.Enabled and attacked[1] then
                        local vec = attacked[1].Entity.RootPart.Position *
                                        Vector3.new(1, 0, 1)
                        entitylib.character.RootPart.CFrame = CFrame.lookAt(
                                                                  entitylib.character
                                                                      .RootPart
                                                                      .Position,
                                                                  Vector3.new(
                                                                      vec.X,
                                                                      entitylib.character
                                                                          .RootPart
                                                                          .Position
                                                                          .Y +
                                                                          0.01,
                                                                      vec.Z))
                    end

                    task.wait()
                until not Killaura.Enabled
            else
                for _, v in Boxes do v.Adornee = nil end
                for _, v in Particles do v.Parent = nil end
            end
        end,
        Tooltip = 'Attack players around you\nwithout aiming at them.'
    })
    Targets = Killaura:CreateTargets({Players = true})
    CPS = Killaura:CreateTwoSlider({
        Name = 'Attacks per Second',
        Min = 1,
        Max = 15,
        DefaultMin = 8,
        DefaultMax = 12
    })
    AttackRange = Killaura:CreateSlider({
        Name = 'Attack range',
        Min = 1,
        Max = 30,
        Default = 13,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    AngleSlider = Killaura:CreateSlider({
        Name = 'Max angle',
        Min = 1,
        Max = 360,
        Default = 90
    })
    Max = Killaura:CreateSlider({
        Name = 'Max targets',
        Min = 1,
        Max = 10,
        Default = 10
    })
    Killaura:CreateToggle({
        Name = 'Show target',
        Function = function(callback)
            BoxSwingColor.Object.Visible = callback
            BoxAttackColor.Object.Visible = callback
            if callback then
                for i = 1, 10 do
                    local box = Instance.new('BoxHandleAdornment')
                    box.Adornee = nil
                    box.AlwaysOnTop = true
                    box.Size = Vector3.new(3, 5, 3)
                    box.CFrame = CFrame.new(0, -0.5, 0)
                    box.ZIndex = 0
                    box.Parent = vape.gui
                    Boxes[i] = box
                end
            else
                for _, v in Boxes do v:Destroy() end
                table.clear(Boxes)
            end
        end
    })
    BoxSwingColor = Killaura:CreateColorSlider({
        Name = 'Target Color',
        Darker = true,
        DefaultHue = 0.6,
        DefaultOpacity = 0.5,
        Visible = false
    })
    BoxAttackColor = Killaura:CreateColorSlider({
        Name = 'Attack Color',
        Darker = true,
        DefaultOpacity = 0.5,
        Visible = false
    })
    Killaura:CreateToggle({
        Name = 'Target particles',
        Function = function(callback)
            ParticleTexture.Object.Visible = callback
            ParticleColor1.Object.Visible = callback
            ParticleColor2.Object.Visible = callback
            ParticleSize.Object.Visible = callback
            if callback then
                for i = 1, 10 do
                    local part = Instance.new('Part')
                    part.Size = Vector3.new(2, 4, 2)
                    part.Anchored = true
                    part.CanCollide = false
                    part.Transparency = 1
                    part.CanQuery = false
                    part.Parent = Killaura.Enabled and gameCamera or nil
                    local particles = Instance.new('ParticleEmitter')
                    particles.Brightness = 1.5
                    particles.Size = NumberSequence.new(ParticleSize.Value)
                    particles.Shape = Enum.ParticleEmitterShape.Sphere
                    particles.Texture = ParticleTexture.Value
                    particles.Transparency = NumberSequence.new(0)
                    particles.Lifetime = NumberRange.new(0.4)
                    particles.Speed = NumberRange.new(16)
                    particles.Rate = 128
                    particles.Drag = 16
                    particles.ShapePartial = 1
                    particles.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(
                                                      ParticleColor1.Hue,
                                                      ParticleColor1.Sat,
                                                      ParticleColor1.Value)),
                        ColorSequenceKeypoint.new(1,
                                                  Color3.fromHSV(
                                                      ParticleColor2.Hue,
                                                      ParticleColor2.Sat,
                                                      ParticleColor2.Value))
                    })
                    particles.Parent = part
                    Particles[i] = part
                end
            else
                for _, v in Particles do v:Destroy() end
                table.clear(Particles)
            end
        end
    })
    ParticleTexture = Killaura:CreateTextBox({
        Name = 'Texture',
        Default = 'rbxassetid://14736249347',
        Function = function()
            for _, v in Particles do
                v.ParticleEmitter.Texture = ParticleTexture.Value
            end
        end,
        Darker = true,
        Visible = false
    })
    ParticleColor1 = Killaura:CreateColorSlider({
        Name = 'Color Begin',
        Function = function(hue, sat, val)
            for _, v in Particles do
                v.ParticleEmitter.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
                    ColorSequenceKeypoint.new(1,
                                              Color3.fromHSV(ParticleColor2.Hue,
                                                             ParticleColor2.Sat,
                                                             ParticleColor2.Value))
                })
            end
        end,
        Darker = true,
        Visible = false
    })
    ParticleColor2 = Killaura:CreateColorSlider({
        Name = 'Color End',
        Function = function(hue, sat, val)
            for _, v in Particles do
                v.ParticleEmitter.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(
                                                  ParticleColor1.Hue,
                                                  ParticleColor1.Sat,
                                                  ParticleColor1.Value)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
                })
            end
        end,
        Darker = true,
        Visible = false
    })
    ParticleSize = Killaura:CreateSlider({
        Name = 'Size',
        Min = 0,
        Max = 1,
        Default = 0.2,
        Decimal = 100,
        Function = function(val)
            for _, v in Particles do
                v.ParticleEmitter.Size = NumberSequence.new(val)
            end
        end,
        Darker = true,
        Visible = false
    })
    Face = Killaura:CreateToggle({Name = 'Face target'})
end)

run(function()
    local ArrestPlayer = remotes:WaitForChild("ArrestPlayer")
    local InteractWithItem = remotes:WaitForChild("InteractWithItem")
    local Cooldown = 0
    local Players = {}
    local AutoArrest
    local ArrestRange

    local function Arrest(player, char)
        task.wait()
        if player then
            ArrestPlayer:InvokeServer(player, 1)
            InteractWithItem:InvokeServer(char.Head)

            task.spawn(function()
                while Cooldown > 0 do
                    task.wait(0.1)
                    Cooldown = math.max(0, Cooldown - 0.1)
                end
            end)
        end
    end

    local function Cleanup(plr)
        if Players[plr] then
            for _, conn in pairs(Players[plr]) do conn:Disconnect() end
            Players[plr] = nil
        end
    end

    local function Auto(v)
        if not AutoArrest.Enabled then return end
        if not entitylib.isAlive then return end

        Cleanup(v)
        Players[v] = {}

        local function Listener(char)
            local TasedConnection = char:GetAttributeChangedSignal("Tased")
                                        :Connect(function()
                    if tick() - Cooldown >= 7.5 then
                        if entitylib.isAlive and entitylib.character.RootPart and
                            char:FindFirstChild("HumanoidRootPart") then
                            local dist =
                                (entitylib.character.RootPart.Position -
                                    char.HumanoidRootPart.Position).Magnitude
                            if dist > ArrestRange.Value then
                                return
                            end
                        end

                        if char:GetAttribute("Tased") == true and lplr.Team ==
                            teamService.Guards then
                            if (v.Team == teamService.Criminals) or
                                (v.Team == teamService.Inmates and
                                    (char:GetAttribute("Trespassing") or
                                        char:GetAttribute("Hostile"))) then
                                local Handcuffs =
                                    char:FindFirstChild("Handcuffs") or
                                        lplr.Backpack:FindFirstChild("Handcuffs")
                                if Handcuffs then
                                    Handcuffs.Parent = char
                                    repeat
                                        t.d.s = char:FindFirstChild("HumanoidRootPart").CFrame
                                        Arrest(v, char)
                                        task.wait(0.1)
                                    until not char or
                                        char:GetAttribute("Arrested")
                                    Handcuffs.Parent = lplr.Backpack
                                    t.d.s = CFrame.new()
                                end
                                t.d.s = CFrame.new()
                            end
                        end
                    else
                        vape:CreateNotification('Vape', 'Arrest Cooldown: ' ..
                                                    math.ceil(
                                                        7.5 -
                                                            (tick() - Cooldown)) ..
                                                    's', 3)
                    end
                end)
            Players[v].TasedConnection = TasedConnection
        end

        if v.Character then Listener(v.Character) end

        Players[v].leaveConnection = entitylib.Events.EntityRemoved:Connect(
                                         function(plr)
                if plr.Player == v then
                    Cleanup(v)
                end
            end)
    end

    AutoArrest = vape.Categories.Blatant:CreateModule({
        Name = "AutoArrest",
        Function = function(callback)
            if callback then
                local function setup(plr)
                    AutoArrest:Clean(plr.CharacterAdded:Connect(function()
                        Auto(plr)
                    end))

                    if plr.Character then Auto(plr) end
                end

                for _, plr in pairs(entitylib.List) do
                    setup(plr.Player)
                end

                AutoArrest:Clean(entitylib.Events.EntityAdded:Connect(function(
                    plr) setup(plr.Player) end))
            else
                for _, conns in pairs(Players) do
                    for _, conn in pairs(conns) do
                        conn:Disconnect()
                    end
                end
                Players = {}
            end
        end
    })
    ArrestRange = AutoArrest:CreateSlider({
        Name = "Arrest Range",
        Min = 1,
        Max = 1000,
        Default = 100,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
end)
