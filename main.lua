-- ========== W424HUB v4.4 - Rayfield UI (Zero ID, Zero Errors) ==========
-- Validasi Place ID: Hanya untuk Arsenal
local placeId = game.PlaceId
local targetGameId = 286090429

if placeId ~= targetGameId then
    game.Players.LocalPlayer:Kick("❌ W424HUB only for Arsenal!")
    return
end

-- ========== LOAD RAYFIELD ==========
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
if not Rayfield then
    warn("Failed to load Rayfield")
    return
end

-- ========== CREATE WINDOW (NO ICON) ==========
local Window = Rayfield:CreateWindow({
    Name = "W424HUB",
    LoadingTitle = "Loading W424HUB...",
    LoadingSubtitle = "by W424",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "W424HUB",
        FileName = "Config"
    },
    Discord = { Enabled = false },
    KeySystem = false,
    RayfieldVersion = "1.0"
})

-- ========== TABS (NO ICON) ==========
local AimTab = Window:CreateTab("Aim")
local VisualTab = Window:CreateTab("Visual")
local PlayerTab = Window:CreateTab("Player")
local ArsenalTab = Window:CreateTab("Arsenal")
local MiscTab = Window:CreateTab("Misc")

-- ========== SECTIONS ==========
local AimLeft = AimTab:CreateSection("Aimbot")
local AimRight = AimTab:CreateSection("Settings")
local VisualLeft = VisualTab:CreateSection("ESP")
local VisualRight = VisualTab:CreateSection("FOV")
local PlayerLeft = PlayerTab:CreateSection("Mods")
local ArsenalLeft = ArsenalTab:CreateSection("Silent Hitbox")
local ArsenalRight = ArsenalTab:CreateSection("Arsenal Extras")
local MiscLeft = MiscTab:CreateSection("Utilities")

-- =====================================================
-- VARIABLES
-- =====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local aimbotEnabled = false
local aimMode = "Camera"
local aimTrigger = "On Shoot"
local isShooting = false
local targetPart = "Head"
local headshotOnly = false
local fovRadius = 100
local maxDistance = 300
local usePrediction = false
local predFactor = 0.2
local useVisCheck = true
local useTeamCheck = true
local smoothness = 1
local target = nil

local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0)
local espTeam = true

local noRecoil = false
local noSpread = false
local antiRagdoll = false

local silentHitbox = false
local hitboxExpansion = 13
local hitboxAlpha = 0.3
local targetPartsChoice = "All"
local fastFire = false
local fastReload = false
local infiniteAmmo = false
local arsenalNoRecoil = false
local arsenalNoSpread = false

local Weapons = ReplicatedStorage:FindFirstChild("Weapons")
local Items = ReplicatedStorage:FindFirstChild("ItemData") and ReplicatedStorage.ItemData:FindFirstChild("Images")
local InventoryData = nil

pcall(function()
    for i,v in next, getgc(true) do
        if typeof(v) == 'table' and rawget(v, 'Loadout') and typeof(v.Items) == 'table' then
            InventoryData = v.Items
        end
    end
end)

-- =====================================================
-- FOV CIRCLE (Drawing) - NO ID
-- =====================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end)

-- =====================================================
-- SAFE GET PART (Menghindari error invalid member)
-- =====================================================
local function safeGetPart(char, partName)
    if not char then return nil end
    local part = char:FindFirstChild(partName)
    if part then return part end
    part = char:FindFirstChild("Head")
    if part then return part end
    part = char:FindFirstChild("HumanoidRootPart")
    if part then return part end
    part = char:FindFirstChild("Torso")
    if part then return part end
    part = char:FindFirstChild("UpperTorso")
    if part then return part end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- =====================================================
-- CORE FUNCTIONS
-- =====================================================
local function isVisible(part)
    if not useVisCheck or not part then return true end
    local success, result = pcall(function()
        local origin = camera.CFrame.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.IgnoreWater = true
        local direction = (part.Position - origin)
        return workspace:Raycast(origin, direction, params)
    end)
    if success and result then
        local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
        if hitChar then
            local player = Players:GetPlayerFromCharacter(hitChar)
            return player ~= nil
        end
        return false
    else
        return true
    end
end

local function getBestTarget()
    local center = camera.ViewportSize / 2
    local best, bestDist = nil, math.huge
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myPos = safeGetPart(myChar, "HumanoidRootPart")
    if not myPos then return nil end
    myPos = myPos.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        if useTeamCheck and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then continue end

        local part
        if headshotOnly then
            part = safeGetPart(c, "Head")
        else
            part = safeGetPart(c, targetPart)
        end
        if not part then continue end

        local targetPos = part.Position
        if usePrediction then
            local velocity = part.Velocity or Vector3.new(0,0,0)
            targetPos = targetPos + (velocity * predFactor)
        end
        if headshotOnly then
            targetPos = targetPos + Vector3.new(0, 0.5, 0)
        end

        local jarak = (targetPos - myPos).Magnitude
        if jarak > maxDistance then continue end
        if not isVisible(part) then continue end

        local pos, on = camera:WorldToViewportPoint(targetPos)
        if on then
            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if dist <= fovRadius and dist < bestDist then
                bestDist = dist
                best = { Part = part, Position = targetPos, Player = p }
            end
        end
    end
    return best
end

-- =====================================================
-- AIMBOT (Camera Mode)
-- =====================================================
local frameSkip = 0
RunService.RenderStepped:Connect(function()
    frameSkip = frameSkip + 1
    if frameSkip % 2 ~= 0 then return end

    if not aimbotEnabled or aimMode ~= "Camera" then return end
    local canAim = (aimTrigger == "On Shoot" and isShooting) or (aimTrigger == "Always")
    if not canAim then return end
    local best = getBestTarget()
    if best then
        target = best
        local targetPos = best.Position
        local targetCF = CFrame.new(camera.CFrame.Position, targetPos)
        camera.CFrame = smoothness >= 1 and targetCF or camera.CFrame:Lerp(targetCF, smoothness)
    else target = nil end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isShooting = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isShooting = false
    end
end)

-- =====================================================
-- SILENT AIM
-- =====================================================
pcall(function()
    local gc = getgc()
    for i, v in pairs(gc) do
        if type(v) == "function" and islclosure(v) then
            local constants = debug.getconstants(v)
            local hasKeyword = false
            for _, c in pairs(constants) do
                if type(c) == "string" then
                    local lower = c:lower()
                    if lower:find("fire") or lower:find("shoot") or lower:find("ray") or lower:find("bullet") then
                        hasKeyword = true
                        break
                    end
                end
            end
            if hasKeyword then
                local old
                old = hookfunction(v, function(p1, p2)
                    if aimbotEnabled and aimMode == "Silent" then
                        local canAim = (aimTrigger == "On Shoot" and isShooting) or (aimTrigger == "Always")
                        if canAim then
                            local best = getBestTarget()
                            if best then
                                local myChar = LocalPlayer.Character
                                if myChar then
                                    local startPart = safeGetPart(myChar, "Head") or safeGetPart(myChar, "HumanoidRootPart")
                                    if startPart then
                                        pcall(function()
                                            if type(p1) == "userdata" and p1:IsA("Ray") then
                                                local direction = (best.Position - startPart.Position)
                                                p1 = Ray.new(startPart.Position, direction)
                                            elseif type(p2) == "userdata" and p2:IsA("CFrame") then
                                                local direction = (best.Position - startPart.Position)
                                                p2 = CFrame.new(startPart.Position, startPart.Position + direction)
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    return old(p1, p2)
                end)
                break
            end
        end
    end
end)

-- =====================================================
-- ESP (Highlight Chams) - Update setiap 1 detik
-- =====================================================
local highlightObjects = {}
local lastPlayerList = {}

local function clearESP()
    for _, h in pairs(highlightObjects) do
        pcall(function() h:Destroy() end)
    end
    highlightObjects = {}
end

local function updateESP()
    if not espEnabled then clearESP(); return end

    local currentPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then currentPlayers[p.Name] = p end
    end

    local changed = false
    for name, _ in pairs(currentPlayers) do
        if not lastPlayerList[name] then changed = true; break end
    end
    if not changed then
        for name, _ in pairs(lastPlayerList) do
            if not currentPlayers[name] then changed = true; break end
        end
    end
    if not changed then return end

    lastPlayerList = currentPlayers

    for p, h in pairs(highlightObjects) do
        if not p.Parent or not Players:FindFirstChild(p.Name) then
            pcall(function() h:Destroy() end)
            highlightObjects[p] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then
            if highlightObjects[p] then
                pcall(function() highlightObjects[p]:Destroy() end)
                highlightObjects[p] = nil
            end
            continue
        end
        if espTeam and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then
            if highlightObjects[p] then highlightObjects[p].Enabled = false end
            continue
        end
        if not highlightObjects[p] then
            local h = Instance.new("Highlight")
            h.Parent = char
            h.FillColor = espColor
            h.OutlineColor = espColor
            h.FillTransparency = 0.3
            h.OutlineTransparency = 0.5
            h.Enabled = true
            highlightObjects[p] = h
        else
            highlightObjects[p].Parent = char
            highlightObjects[p].Enabled = true
        end
    end
end

Players.PlayerAdded:Connect(updateESP)
Players.PlayerRemoving:Connect(function(p)
    if highlightObjects[p] then
        pcall(function() highlightObjects[p]:Destroy() end)
        highlightObjects[p] = nil
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        pcall(updateESP)
    end
end)

-- =====================================================
-- NO RECOIL, NO SPREAD, ANTI RAGDOLL
-- =====================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if antiRagdoll then
        pcall(function()
            if hum.PlatformStand or hum.Sit then
                hum.PlatformStand = false
                hum.Sit = false
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0,0,0)
                    hrp.RotVelocity = Vector3.new(0,0,0)
                end
            end
            if hum.SeatPart then hum.Sit = false end
        end)
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        if noRecoil then
            for _, prop in ipairs({"Recoil","recoil","Kickback","GunRecoil","Shake","CameraRecoil"}) do
                pcall(function()
                    local val = tool[prop]
                    if val ~= nil and type(val) == "number" then tool[prop] = 0 end
                end)
            end
        end
        if noSpread then
            for _, prop in ipairs({"Spread","spread","Accuracy","Inaccuracy","BulletSpread","Deviation"}) do
                pcall(function()
                    local val = tool[prop]
                    if val ~= nil and type(val) == "number" then tool[prop] = 0 end
                end)
            end
        end
    end
end)

-- =====================================================
-- SILENT HITBOX (Arsenal)
-- =====================================================
local silentLoopConnections = {}

local function getTargetParts(char)
    local parts = {}
    if not char then return parts end

    if targetPartsChoice == "All" or targetPartsChoice == "Head" then
        local head = safeGetPart(char, "Head")
        if head then table.insert(parts, head) end
        local headHB = char:FindFirstChild("HeadHB")
        if headHB then table.insert(parts, headHB) end
    end
    if targetPartsChoice == "All" or targetPartsChoice == "Torso" then
        local torso = safeGetPart(char, "Torso") or safeGetPart(char, "UpperTorso")
        if torso then table.insert(parts, torso) end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(parts, hrp) end
    end
    if targetPartsChoice == "All" or targetPartsChoice == "Legs" then
        for _, name in pairs({"RightUpperLeg","LeftUpperLeg","RightLowerLeg","LeftLowerLeg"}) do
            local leg = char:FindFirstChild(name)
            if leg then table.insert(parts, leg) end
        end
    end
    return parts
end

local function startSilentHitbox()
    if silentLoopConnections.transparencyLoop then silentLoopConnections.transparencyLoop:Disconnect() end
    if silentLoopConnections.hitboxLoop then silentLoopConnections.hitboxLoop:Disconnect() end

    silentLoopConnections.transparencyLoop = RunService.Heartbeat:Connect(function()
        if not silentHitbox then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local parts = getTargetParts(player.Character)
                for _, part in ipairs(parts) do
                    pcall(function()
                        if part then
                            part.Transparency = hitboxAlpha
                        end
                    end)
                end
            end
        end
        task.wait(0.2)
    end)

    silentLoopConnections.hitboxLoop = RunService.Heartbeat:Connect(function()
        if not silentHitbox then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local parts = getTargetParts(player.Character)
                for _, part in ipairs(parts) do
                    pcall(function()
                        if part then
                            part.CanCollide = false
                            part.Size = Vector3.new(hitboxExpansion, hitboxExpansion, hitboxExpansion)
                        end
                    end)
                end
            end
        end
        task.wait(0.2)
    end)
end

local function stopSilentHitbox()
    if silentLoopConnections.transparencyLoop then silentLoopConnections.transparencyLoop:Disconnect(); silentLoopConnections.transparencyLoop = nil end
    if silentLoopConnections.hitboxLoop then silentLoopConnections.hitboxLoop:Disconnect(); silentLoopConnections.hitboxLoop = nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local parts = getTargetParts(player.Character)
            for _, part in ipairs(parts) do
                pcall(function()
                    if part then
                        part.Transparency = 0
                        part.CanCollide = true
                        local name = part.Name
                        if name == "HumanoidRootPart" then part.Size = Vector3.new(2,2,1)
                        elseif name:find("Leg") then part.Size = Vector3.new(1,2,1)
                        elseif name == "Head" or name == "HeadHB" then part.Size = Vector3.new(2,1,1)
                        elseif name == "Torso" or name == "UpperTorso" then part.Size = Vector3.new(2,1.5,1)
                        else part.Size = Vector3.new(1,1,1) end
                    end
                end)
            end
        end
    end
end

-- =====================================================
-- UNLOCK ALL ITEMS
-- =====================================================
local function unlockAllItems()
    if not InventoryData or not Items then return end
    for _, v in ipairs(Items:GetChildren()) do
        if InventoryData[v.Name] then
            for _, f in ipairs(v:GetChildren()) do
                if not InventoryData[v.Name][f.Name] then
                    InventoryData[v.Name][f.Name] = 1
                end
            end
        end
    end
    Rayfield:Notify({
        Title = "Unlock All",
        Content = "All items unlocked!",
        Duration = 2,
    })
end

-- =====================================================
-- SKIN CHANGER FUNCTIONS
-- =====================================================
local function ChangeArsenalSkin(skinType, skinName)
    if skinType == "Character" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Skin") then
            LocalPlayer.Data.Skin.Value = skinName
        end
    elseif skinType == "Melee" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Melee") then
            LocalPlayer.Data.Melee.Value = skinName
        end
    elseif skinType == "GunSkin" then
        if LocalPlayer:FindFirstChild("Equipped") then
            LocalPlayer.Equipped.Value = skinName
        end
    elseif skinType == "KillEffect" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("KillEffect") then
            LocalPlayer.Data.KillEffect.Value = skinName
        end
    elseif skinType == "Announcer" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Announcer") then
            LocalPlayer.Data.Announcer.Value = skinName
        end
    end
end

local function GetSkinList(category)
    local list = {"Default"}
    if not Items then return list end
    for _, v in ipairs(Items:GetChildren()) do
        if v.Name == category then
            for _, f in ipairs(v:GetChildren()) do
                table.insert(list, f.Name)
            end
        end
    end
    return list
end

-- =====================================================
-- UI ELEMENTS (Rayfield, NO ID)
-- =====================================================

-- AIM TAB (Left)
AimLeft:AddToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "aimbot_enabled",
    Callback = function(v) aimbotEnabled = v end
})

AimLeft:AddDropdown({
    Name = "Aim Mode",
    Options = {"Camera", "Silent"},
    CurrentOption = "Camera",
    Flag = "aim_mode",
    Callback = function(v) aimMode = v end
})

AimLeft:AddDropdown({
    Name = "Trigger",
    Options = {"On Shoot", "Always"},
    CurrentOption = "On Shoot",
    Flag = "aim_trigger",
    Callback = function(v) aimTrigger = v end
})

AimLeft:AddDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Flag = "target_part",
    Callback = function(v) targetPart = v end
})

AimLeft:AddToggle({
    Name = "Headshot Only",
    CurrentValue = false,
    Flag = "headshot_only",
    Callback = function(v) headshotOnly = v end
})

AimLeft:AddToggle({
    Name = "Anti Team",
    CurrentValue = true,
    Flag = "anti_team",
    Callback = function(v) useTeamCheck = v end
})

AimLeft:AddToggle({
    Name = "Visibility Check",
    CurrentValue = true,
    Flag = "vis_check",
    Callback = function(v) useVisCheck = v end
})

AimLeft:AddToggle({
    Name = "Prediction",
    CurrentValue = false,
    Flag = "prediction",
    Callback = function(v) usePrediction = v end
})

-- AIM TAB (Right)
AimRight:AddSlider({
    Name = "FOV Radius",
    Min = 50,
    Max = 300,
    Default = 100,
    Suffix = "px",
    Flag = "fov_radius",
    Callback = function(v)
        fovRadius = v
        fovCircle.Radius = v
    end
})

AimRight:AddSlider({
    Name = "Max Distance",
    Min = 50,
    Max = 500,
    Default = 300,
    Suffix = "stud",
    Flag = "max_distance",
    Callback = function(v) maxDistance = v end
})

AimRight:AddSlider({
    Name = "Pred Factor",
    Min = 0,
    Max = 100,
    Default = 20,
    Suffix = "%",
    Flag = "pred_factor",
    Callback = function(v) predFactor = v / 100 end
})

AimRight:AddSlider({
    Name = "Smoothness",
    Min = 1,
    Max = 100,
    Default = 100,
    Suffix = "%",
    Flag = "smoothness",
    Callback = function(v) smoothness = v / 100 end
})

AimRight:AddToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "fov_circle",
    Callback = function(v) fovCircle.Visible = v end
})

-- VISUAL TAB (Left)
VisualLeft:AddToggle({
    Name = "ESP Chams",
    CurrentValue = false,
    Flag = "esp_enabled",
    Callback = function(v) espEnabled = v end
})

VisualLeft:AddToggle({
    Name = "ESP Team Check",
    CurrentValue = true,
    Flag = "esp_team",
    Callback = function(v) espTeam = v end
})

VisualLeft:AddColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "esp_color",
    Callback = function(c)
        espColor = c
        for _, h in pairs(highlightObjects) do
            if h then h.FillColor = c end
        end
    end
})

-- VISUAL TAB (Right) - FOV Slider
VisualRight:AddSlider({
    Name = "FOV Slider",
    Min = 70,
    Max = 120,
    Default = 70,
    Suffix = "°",
    Flag = "fov_slider",
    Callback = function(v)
        pcall(function()
            if camera then
                camera.FieldOfView = v
            end
        end)
    end
})

-- PLAYER TAB
PlayerLeft:AddToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Flag = "no_recoil",
    Callback = function(v) noRecoil = v end
})

PlayerLeft:AddToggle({
    Name = "No Spread",
    CurrentValue = false,
    Flag = "no_spread",
    Callback = function(v) noSpread = v end
})

PlayerLeft:AddToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "anti_ragdoll",
    Callback = function(v) antiRagdoll = v end
})

-- ARSENAL TAB (Left)
ArsenalLeft:AddToggle({
    Name = "Silent Hitbox",
    CurrentValue = false,
    Flag = "silent_hitbox",
    Callback = function(v)
        silentHitbox = v
        if v then startSilentHitbox() else stopSilentHitbox() end
    end
})

ArsenalLeft:AddDropdown({
    Name = "Target Parts",
    Options = {"All", "Head", "Torso", "Legs"},
    CurrentOption = "All",
    Flag = "hitbox_target",
    Callback = function(v)
        targetPartsChoice = v
        if silentHitbox then
            stopSilentHitbox()
            startSilentHitbox()
        end
    end
})

ArsenalLeft:AddSlider({
    Name = "Hitbox Expansion",
    Min = 1,
    Max = 30,
    Default = 13,
    Suffix = "x",
    Flag = "hitbox_expansion",
    Callback = function(v)
        hitboxExpansion = v
        if silentHitbox then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local parts = getTargetParts(p.Character)
                    for _, part in ipairs(parts) do
                        if part then part.Size = Vector3.new(v, v, v) end
                    end
                end
            end
        end
    end
})

ArsenalLeft:AddSlider({
    Name = "Hitbox Alpha",
    Min = 0,
    Max = 10,
    Default = 3,
    Suffix = "/10",
    Flag = "hitbox_alpha",
    Callback = function(v)
        hitboxAlpha = v / 10
        if silentHitbox then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local parts = getTargetParts(p.Character)
                    for _, part in ipairs(parts) do
                        if part then part.Transparency = hitboxAlpha end
                    end
                end
            end
        end
    end
})

ArsenalLeft:AddButton({
    Name = "Reset Hitbox",
    Flag = "reset_hitbox",
    Callback = function()
        stopSilentHitbox()
        if silentHitbox then startSilentHitbox() end
        Rayfield:Notify({ Title = "Reset", Content = "Hitbox reset to default", Duration = 2 })
    end
})

-- ARSENAL TAB (Right)
ArsenalRight:AddToggle({
    Name = "Fast Fire Rate",
    CurrentValue = false,
    Flag = "fast_fire",
    Callback = function(v)
        fastFire = v
        if Weapons then
            for _, w in ipairs(Weapons:GetChildren()) do
                if w:FindFirstChild("FireRate") then w.FireRate.Value = v and 0.01 or 0.1 end
                if w:FindFirstChild("BFireRate") then w.BFireRate.Value = v and 0.01 or 0.1 end
            end
        end
    end
})

ArsenalRight:AddToggle({
    Name = "Fast Reload",
    CurrentValue = false,
    Flag = "fast_reload",
    Callback = function(v)
        fastReload = v
        if Weapons then
            for _, w in ipairs(Weapons:GetChildren()) do
                if w:FindFirstChild("ReloadTime") then w.ReloadTime.Value = v and 0.01 or 1.5 end
            end
        end
    end
})

ArsenalRight:AddToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "infinite_ammo",
    Callback = function(v)
        infiniteAmmo = v
        if v then
            pcall(function()
                if ReplicatedStorage:FindFirstChild("wkspc") and ReplicatedStorage.wkspc:FindFirstChild("CurrentCurse") then
                    ReplicatedStorage.wkspc.CurrentCurse.Value = 'Infinite Ammo'
                end
            end)
        end
    end
})

ArsenalRight:AddToggle({
    Name = "No Recoil (Arsenal)",
    CurrentValue = false,
    Flag = "arsenal_no_recoil",
    Callback = function(v)
        arsenalNoRecoil = v
        if Weapons then
            for _, w in ipairs(Weapons:GetChildren()) do
                if w:FindFirstChild("RecoilControl") then w.RecoilControl.Value = v and 0 or 1 end
            end
        end
    end
})

ArsenalRight:AddToggle({
    Name = "No Spread (Arsenal)",
    CurrentValue = false,
    Flag = "arsenal_no_spread",
    Callback = function(v)
        arsenalNoSpread = v
        if Weapons then
            for _, w in ipairs(Weapons:GetChildren()) do
                if w:FindFirstChild("MaxSpread") then w.MaxSpread.Value = v and 0.01 or 1 end
                if w:FindFirstChild("SpreadRecovery") then w.SpreadRecovery.Value = v and 0.01 or 0.5 end
            end
        end
    end
})

ArsenalRight:AddButton({
    Name = "Unlock All Items",
    Flag = "unlock_all",
    Callback = unlockAllItems
})

-- Skin Changer
ArsenalRight:AddDivider()
local charSkins = GetSkinList("Character")
ArsenalRight:AddDropdown({
    Name = "Character Skin",
    Options = charSkins,
    CurrentOption = charSkins[1] or "Default",
    Flag = "char_skin",
    Callback = function(v) ChangeArsenalSkin("Character", v) end
})

local meleeSkins = GetSkinList("Melee")
ArsenalRight:AddDropdown({
    Name = "Melee Skin",
    Options = meleeSkins,
    CurrentOption = meleeSkins[1] or "Default",
    Flag = "melee_skin",
    Callback = function(v) ChangeArsenalSkin("Melee", v) end
})

local gunSkins = GetSkinList("Gun")
ArsenalRight:AddDropdown({
    Name = "Gun Skin",
    Options = gunSkins,
    CurrentOption = gunSkins[1] or "Default",
    Flag = "gun_skin",
    Callback = function(v) ChangeArsenalSkin("GunSkin", v) end
})

local killSkins = GetSkinList("KillEffect")
ArsenalRight:AddDropdown({
    Name = "Kill Effect",
    Options = killSkins,
    CurrentOption = killSkins[1] or "Default",
    Flag = "kill_effect",
    Callback = function(v) ChangeArsenalSkin("KillEffect", v) end
})

local announcerSkins = GetSkinList("Announcer")
ArsenalRight:AddDropdown({
    Name = "Announcer",
    Options = announcerSkins,
    CurrentOption = announcerSkins[1] or "Default",
    Flag = "announcer",
    Callback = function(v) ChangeArsenalSkin("Announcer", v) end
})

-- MISC TAB
MiscLeft:AddToggle({
    Name = "FPS & Ping",
    CurrentValue = false,
    Flag = "fps_ping",
    Callback = function(v)
        if v then
            if not statsText then
                statsText = Drawing.new("Text")
                statsText.Position = Vector2.new(10, 10)
                statsText.Size = 14
                statsText.Color = Color3.new(1,1,1)
                statsText.Outline = true
                statsText.OutlineColor = Color3.new(0,0,0)
                statsText.Font = Drawing.Fonts.UI
                statsText.Text = "FPS: 0 | Ping: 0ms"
            end
            statsText.Visible = true
        else
            if statsText then statsText.Visible = false end
        end
    end
})

MiscLeft:AddButton({
    Name = "Rejoin Game",
    Flag = "rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

-- =====================================================
-- FPS & PING UPDATER
-- =====================================================
local statsText = nil
local frameCount = 0
local timeAcc = 0

RunService.RenderStepped:Connect(function(dt)
    if statsText and statsText.Visible then
        frameCount = frameCount + 1
        timeAcc = timeAcc + dt
        if timeAcc >= 1 then
            local ping = 0
            pcall(function() ping = LocalPlayer:GetNetworkPing() * 1000 end)
            statsText.Text = string.format("FPS: %d | Ping: %.0fms", frameCount, ping)
            frameCount = 0
            timeAcc = 0
        end
    end
end)

-- =====================================================
-- STARTUP NOTIFICATION
-- =====================================================
Rayfield:Notify({
    Title = "W424HUB Loaded!",
    Content = "Zero ID - Clean script!",
    Duration = 3,
})

print("✅ W424HUB v4.4 - Zero ID, Zero Errors loaded!")