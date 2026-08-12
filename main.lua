-- ========== W424HUB - v3.8 (ARSENAL EDITION) ==========
local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========== JENDELA UTAMA ==========
local Window = Kairo:CreateWindow({
    Title = "W424HUB",
    Theme = "Crimson",
    Size = UDim2.fromOffset(300, 580),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"v3.8"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    Config = { Enabled = true, Folder = "W424HUB_Config", AutoLoad = true }
})

Window:Notify({
    Title = "W424HUB v3.8",
    Description = "Arsenal Edition!",
    Content = "Fast Fire, Fast Reload, Skin Changer, Unlock All, Silent Hitbox, Reduce Map",
    Color = Color3.fromRGB(0, 200, 50),
    Delay = 3
})

-- ========== TAB ==========
local TabAim = Window:CreateTab("Aim", "rbxassetid://16932740082")
local TabVisual = Window:CreateTab("Vis", "rbxassetid://16932740082")
local TabPlayer = Window:CreateTab("Player", "rbxassetid://16932740082")
local TabArsenal = Window:CreateTab("Arsenal", "rbxassetid://16932740082")

-- =====================================================
-- TAB AIM - AIMBOT (SAMA SEPERTI SEBELUMNYA)
-- =====================================================
Window:AddParagraph(TabAim, "Aimbot", "Camera & Silent")

local aimbotAktif = false
local aimModeType = "Camera"
local aimModeTrigger = "Saat Nembak"
local isShooting = false
local targetPartName = "Head"
local headshotOnly = false
local aimSmoothness = 1
local useTeamCheck = true
local fovRadius = 100
local maxAimDistance = 300
local usePrediction = false
local predictionFactor = 0.2
local useVisibilityCheck = true
local target = nil

-- FOV CIRCLE
if CoreGui:FindFirstChild("W424_FOV_GUI") then CoreGui.W424_FOV_GUI:Destroy() end
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "W424_FOV_GUI"
fovGui.Parent = CoreGui
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true

local fovFrame = Instance.new("Frame")
fovFrame.BackgroundTransparency = 1
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
fovFrame.Visible = false
fovFrame.Parent = fovGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovFrame
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local function updateFOVSize()
    fovFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
end

Window:AddToggle(TabAim, "Aimbot", "Aktifkan", false, function(s) aimbotAktif = s end, "AimbotToggle")
Window:AddDropdown(TabAim, "Mode", "Camera/Silent", {"Camera","Silent"}, false, "Camera", function(v) aimModeType = v end, "AimModeType")
Window:AddDropdown(TabAim, "Trigger", "Kapan aktif", {"Saat Nembak","Selalu Nempel"}, false, "Saat Nembak", function(v) aimModeTrigger = v end, "AimModeDrop")
Window:AddToggle(TabAim, "FOV Circle", "Tampilkan", false, function(s) fovFrame.Visible = s end, "FOVSidesToggle")
Window:AddSlider(TabAim, "FOV Radius", "30-400", 30, 400, 100, function(v) fovRadius = v; updateFOVSize() end, "FOVRadius", true)
Window:AddSlider(TabAim, "Jarak Maks", "50-500", 50, 500, 300, function(v) maxAimDistance = v end, "MaxDistance", true)
Window:AddToggle(TabAim, "Anti Team", "Hindari teman", true, function(s) useTeamCheck = s end, "AimTeamCheck")
Window:AddToggle(TabAim, "Vis Check", "Cek tembok", true, function(s) useVisibilityCheck = s end, "VisCheck")
Window:AddToggle(TabAim, "Prediction", "Aim ke depan", false, function(s) usePrediction = s end, "PredictToggle")
Window:AddSlider(TabAim, "Pred Factor", "0-100", 0, 100, 20, function(v) predictionFactor = v/100 end, "PredictFactor", true)
Window:AddToggle(TabAim, "Headshot Only", "Paksa ke kepala", false, function(s) headshotOnly = s; if s then targetPartName = "Head" end end, "HeadshotToggle")
Window:AddDropdown(TabAim, "Target Part", "Bagian tubuh", {"Head","HumanoidRootPart","Torso","UpperTorso"}, false, "Head", function(v) if not headshotOnly then targetPartName = v end end, "TargetPartDrop")
Window:AddSlider(TabAim, "Smooth", "1-10", 1, 10, 10, function(v) aimSmoothness = v/10 end, "AimSmooth", true)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isShooting = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isShooting = false end
end)

local function isVisible(part)
    if not useVisibilityCheck then return true end
    local origin = camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local direction = (part.Position - origin)
    local result = workspace:Raycast(origin, direction, params)
    if result then
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
    local myPos = myChar:FindFirstChild("HumanoidRootPart")
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
        if headshotOnly then part = c:FindFirstChild("Head")
        else part = c:FindFirstChild(targetPartName) end
        if not part then part = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
        if not part then continue end

        local targetPos = part.Position
        if usePrediction then
            local velocity = part.Velocity or Vector3.new(0,0,0)
            targetPos = targetPos + (velocity * predictionFactor)
        end
        if headshotOnly then targetPos = targetPos + Vector3.new(0, 0.5, 0) end

        local jarak = (targetPos - myPos).Magnitude
        if jarak > maxAimDistance then continue end
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

RunService.RenderStepped:Connect(function()
    if not aimbotAktif or aimModeType ~= "Camera" then return end
    local canAim = (aimModeTrigger == "Saat Nembak" and isShooting) or (aimModeTrigger == "Selalu Nempel")
    if not canAim then return end
    local best = getBestTarget()
    if best then
        target = best
        local targetPos = best.Position
        local targetCF = CFrame.new(camera.CFrame.Position, targetPos)
        camera.CFrame = aimSmoothness >= 1 and targetCF or camera.CFrame:Lerp(targetCF, aimSmoothness)
    else target = nil end
end)

pcall(function()
    local gc = getgc()
    for i, v in pairs(gc) do
        if type(v) == "function" and islclosure(v) then
            local constants = debug.getconstants(v)
            local upvalues = debug.getupvalues(v)
            local hasKeyword = false
            for _, c in pairs(constants) do
                if type(c) == "string" then
                    local lower = c:lower()
                    if lower:find("fire") or lower:find("shoot") or lower:find("ray") or lower:find("bullet") then hasKeyword = true; break end
                end
            end
            local hasRaycastParams = false
            for _, u in pairs(upvalues) do
                if type(u) == "table" and pcall(function() return u:IsA("RaycastParams") end) then hasRaycastParams = true; break end
            end
            if hasKeyword or hasRaycastParams then
                local old
                old = hookfunction(v, function(p1, p2)
                    if aimbotAktif and aimModeType == "Silent" then
                        local canAim = (aimModeTrigger == "Saat Nembak" and isShooting) or (aimModeTrigger == "Selalu Nempel")
                        if canAim then
                            local best = getBestTarget()
                            if best then
                                local myChar = LocalPlayer.Character
                                if myChar then
                                    local startPart = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
                                    if startPart then
                                        pcall(function()
                                            if type(p1) == "userdata" and p1:IsA("Ray") then
                                                local direction = (best.Position - startPart.Position)
                                                p1 = Ray.new(startPart.Position, direction)
                                            elseif type(p2) == "userdata" and p2:IsA("CFrame") then
                                                local direction = (best.Position - startPart.Position)
                                                p2 = CFrame.new(startPart.Position, startPart.Position + direction)
                                            elseif type(p1) == "Vector3" and type(p2) == "Vector3" then
                                                local direction = (best.Position - startPart.Position)
                                                p1 = startPart.Position
                                                p2 = direction
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
-- TAB VISUAL - ESP CHAMS + OPTIMASI
-- =====================================================
Window:AddParagraph(TabVisual, "ESP Chams", "Warnai tubuh musuh")

local espEnabled = false
local espColor = Color3.fromRGB(255, 0, 0)
local espTeam = true
local fillTrans = 0.3
local highlightObjects = {}

local function clearESP()
    for _, h in pairs(highlightObjects) do if h then h:Destroy() end end
    highlightObjects = {}
end

Window:AddToggle(TabVisual, "Aktifkan ESP", "Warnai tubuh", false, function(s) espEnabled = s; if not s then clearESP() end end, "ESPChamsToggle")
Window:AddColorPicker(TabVisual, "Warna ESP", "", Color3.fromRGB(255, 0, 0), function(c) espColor = c; for _, h in pairs(highlightObjects) do if h then h.FillColor = c end end end, "ESPColorPicker")
Window:AddSlider(TabVisual, "Transparansi", "0-10", 0, 10, 3, function(v) fillTrans = v/10; for _, h in pairs(highlightObjects) do if h then h.FillTransparency = fillTrans end end end, "ESPTrans", true)
Window:AddToggle(TabVisual, "Team Check", "Sembunyi teman", true, function(s) espTeam = s; if espEnabled then clearESP(); for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then local char = p.Character; if char then local h = Instance.new("Highlight"); h.Parent = char; h.FillColor = espColor; h.OutlineColor = espColor; h.FillTransparency = fillTrans; h.OutlineTransparency = 0.5; h.Enabled = true; highlightObjects[p] = h end end end end end, "ESPTeamCheck")

local function updateESP()
    if not espEnabled then clearESP(); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then if highlightObjects[p] then highlightObjects[p]:Destroy(); highlightObjects[p] = nil end continue end
        if espTeam and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then if highlightObjects[p] then highlightObjects[p].Enabled = false end continue end
        if not highlightObjects[p] then
            local h = Instance.new("Highlight"); h.Parent = char; h.FillColor = espColor; h.OutlineColor = espColor; h.FillTransparency = fillTrans; h.OutlineTransparency = 0.5; h.Enabled = true; highlightObjects[p] = h
        else
            highlightObjects[p].Parent = char; highlightObjects[p].Enabled = true
        end
    end
    for p, h in pairs(highlightObjects) do if not p.Parent or not Players:FindFirstChild(p.Name) then h:Destroy(); highlightObjects[p] = nil end end
end

Players.PlayerAdded:Connect(updateESP)
Players.PlayerRemoving:Connect(function(p) if highlightObjects[p] then highlightObjects[p]:Destroy(); highlightObjects[p] = nil end end)
RunService.RenderStepped:Connect(updateESP)

-- ===== ULTRA LOW MODE & REDUCE MAP =====
Window:AddDivider(TabVisual, "Optimasi")
local ultraLow = false
local function disableParticles(instance)
    if not ultraLow then return end
    for _, child in ipairs(instance:GetDescendants()) do
        if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Sparkles") then child.Enabled = false end
        if child:IsA("Decal") then child.Transparency = 1 end
        if child:IsA("Texture") then child.Transparency = 1 end
    end
end

Window:AddToggle(TabVisual, "Mode Ultra Low", "Potato mode", false, function(s)
    ultraLow = s
    if s then
        pcall(function() StarterGui:SetCore("MinimapEnabled", false) end)
        for _, gui in ipairs(CoreGui:GetChildren()) do if gui.Name:lower():find("minimap") then gui.Enabled = false end end
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do if gui.Name:lower():find("minimap") then gui.Enabled = false end end
        pcall(function() Lighting.GlobalShadows = false; Lighting.Brightness = 0.5; Lighting.Ambient = Color3.new(0.5,0.5,0.5); Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5); for _, child in ipairs(Lighting:GetChildren()) do if child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") or child:IsA("BlurEffect") or child:IsA("DepthOfFieldEffect") then child.Enabled = false end; if child:IsA("Atmosphere") then child.Enabled = false end end end)
        pcall(function() local settings = UserSettings(); if settings and settings.GameSettings then settings.GameSettings.GraphicsQualityLevel = 1 end end)
        pcall(function() disableParticles(Workspace) end)
        pcall(function() if Workspace.Terrain then Workspace.Terrain.WaterWaveSize = 0; Workspace.Terrain.WaterWaveSpeed = 0; Workspace.Terrain.WaterReflectance = 0; Workspace.Terrain.WaterTransparency = 1 end end)
    else
        pcall(function() Lighting.GlobalShadows = true; Lighting.Brightness = 1; Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1) end)
        pcall(function() local settings = UserSettings(); if settings and settings.GameSettings then settings.GameSettings.GraphicsQualityLevel = 10 end end)
    end
end, "UltraLowToggle")

-- ========== REDUCE MAP UI ==========
local reduceMap = false
Window:AddToggle(TabVisual, "Reduce Map", "Matikan minimap", false, function(s)
    reduceMap = s
    if s then
        pcall(function() StarterGui:SetCore("MinimapEnabled", false) end)
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name:lower():find("minimap") then gui.Enabled = false end
        end
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name:lower():find("minimap") then gui.Enabled = false end
        end
    else
        pcall(function() StarterGui:SetCore("MinimapEnabled", true) end)
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name:lower():find("minimap") then gui.Enabled = true end
        end
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name:lower():find("minimap") then gui.Enabled = true end
        end
    end
end, "ReduceMapToggle")

-- =====================================================
-- TAB PLAYER - NO RECOIL, NO SPREAD, ANTI RAGDOLL
-- =====================================================
Window:AddParagraph(TabPlayer, "Player Mods", "Fitur karakter")
local noRecoil = false; local noSpread = false; local antiRagdoll = false
Window:AddToggle(TabPlayer, "No Recoil", "Hilangkan getaran", false, function(s) noRecoil = s end, "NoRecoilToggle")
Window:AddToggle(TabPlayer, "No Spread", "Peluru lurus", false, function(s) noSpread = s end, "NoSpreadToggle")
Window:AddToggle(TabPlayer, "Anti Ragdoll", "Cegah jatuh", false, function(s) antiRagdoll = s end, "AntiRagdollToggle")

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if antiRagdoll then
        if hum.PlatformStand or hum.Sit then hum.PlatformStand = false; hum.Sit = false; local hrp = char:FindFirstChild("HumanoidRootPart"); if hrp then hrp.Velocity = Vector3.new(0,0,0); hrp.RotVelocity = Vector3.new(0,0,0) end end
        if hum.SeatPart then hum.Sit = false end
    end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        if noRecoil then
            for _, prop in ipairs({"Recoil","recoil","Kickback","GunRecoil","Shake","CameraRecoil"}) do local success, val = pcall(function() return tool[prop] end); if success and val ~= nil and type(val) == "number" then tool[prop] = 0; break end end
            if tool:FindFirstChild("Recoil") and tool.Recoil:IsA("NumberValue") then tool.Recoil.Value = 0 end
        end
        if noSpread then
            for _, prop in ipairs({"Spread","spread","Accuracy","Inaccuracy","BulletSpread","Deviation"}) do local success, val = pcall(function() return tool[prop] end); if success and val ~= nil and type(val) == "number" then tool[prop] = 0; break end end
            if tool:FindFirstChild("Spread") and tool.Spread:IsA("NumberValue") then tool.Spread.Value = 0 end
            if tool:FindFirstChild("Inaccuracy") and tool.Inaccuracy:IsA("NumberValue") then tool.Inaccuracy.Value = 0 end
        end
        for _, child in ipairs(tool:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") or child:IsA("FloatValue") then
                local name = child.Name:lower()
                if noRecoil and (name:find("recoil") or name:find("kick") or name:find("shake")) then child.Value = 0 end
                if noSpread and (name:find("spread") or name:find("inaccuracy") or name:find("accuracy") or name:find("deviation")) then child.Value = 0 end
            end
        end
    end
end)

-- =====================================================
-- TAB ARSENAL - FITUR SPESIFIK ARSENAL
-- =====================================================
Window:AddParagraph(TabArsenal, "Arsenal Mods", "Fast Fire, Fast Reload, Unlock, Skin Changer")

-- Variabel untuk fitur Arsenal
local fastFire = false
local fastReload = false
local infiniteAmmo = false
local arsenalNoRecoil = false
local arsenalNoSpread = false

-- Referensi ke data Arsenal
local Weapons = ReplicatedStorage:FindFirstChild("Weapons")
local Items = ReplicatedStorage:FindFirstChild("ItemData") and ReplicatedStorage.ItemData:FindFirstChild("Images")
local InventoryData = nil
local LoadoutData = nil
local EquippedSkin = ""
local EquippedMelee = ""
local EquippedGunSkin = ""
local EquippedKillEffect = ""
local EquippedAnnouncer = ""

-- Ambil InventoryData dan Loadout dari memori
pcall(function()
    for i,v in next, getgc(true) do
        if typeof(v) == 'table' and rawget(v, 'Loadout') and typeof(v.Items) == 'table' then
            InventoryData = v.Items
            LoadoutData = v.Loadout
        end
    end
end)

-- Fungsi Add Every Item (Unlock All)
local function AddEveryItem()
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
    Window:Notify({Title="Unlock All Items", Description="Semua item berhasil dibuka!", Color=Color3.fromRGB(0,200,50), Delay=2})
end

-- Fungsi Change Skin (karakter, melee, gun, kill effect, announcer)
local function ChangeArsenalSkin(skinType, skinName)
    if skinType == "Character" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Skin") then
            LocalPlayer.Data.Skin.Value = skinName
            EquippedSkin = skinName
        end
    elseif skinType == "Melee" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Melee") then
            LocalPlayer.Data.Melee.Value = skinName
            EquippedMelee = skinName
        end
    elseif skinType == "GunSkin" then
        if LocalPlayer:FindFirstChild("Equipped") then
            LocalPlayer.Equipped.Value = skinName
            EquippedGunSkin = skinName
        end
    elseif skinType == "KillEffect" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("KillEffect") then
            LocalPlayer.Data.KillEffect.Value = skinName
            EquippedKillEffect = skinName
        end
    elseif skinType == "Announcer" then
        if LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Announcer") then
            LocalPlayer.Data.Announcer.Value = skinName
            EquippedAnnouncer = skinName
        end
    end
end

-- Fungsi untuk mendapatkan daftar skin dari Items
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

-- --- UI KONTROL ARSENAL ---

-- Infinite Ammo
Window:AddToggle(TabArsenal, "Infinite Ammo", "Amunisi tidak pernah habis", false, function(s)
    infiniteAmmo = s
    if s then
        pcall(function()
            if ReplicatedStorage:FindFirstChild("wkspc") and ReplicatedStorage.wkspc:FindFirstChild("CurrentCurse") then
                ReplicatedStorage.wkspc.CurrentCurse.Value = 'Infinite Ammo'
            end
        end)
    end
end, "InfiniteAmmoToggle")

-- Fast Fire Rate
Window:AddToggle(TabArsenal, "Fast Fire Rate", "Kecepatan tembak super cepat", false, function(s)
    fastFire = s
    if Weapons then
        for _, v in ipairs(Weapons:GetChildren()) do
            if v:FindFirstChild("FireRate") then
                v.FireRate.Value = s and 0.01 or 0.1
            end
            if v:FindFirstChild("BFireRate") then
                v.BFireRate.Value = s and 0.01 or 0.1
            end
        end
    end
end, "FastFireToggle")

-- Fast Reload
Window:AddToggle(TabArsenal, "Fast Reload", "Reload hampir instan", false, function(s)
    fastReload = s
    if Weapons then
        for _, v in ipairs(Weapons:GetChildren()) do
            if v:FindFirstChild("ReloadTime") then
                v.ReloadTime.Value = s and 0.01 or 1.5
            end
        end
    end
end, "FastReloadToggle")

-- No Recoil (Arsenal version)
Window:AddToggle(TabArsenal, "No Recoil (Arsenal)", "Set RecoilControl ke 0", false, function(s)
    arsenalNoRecoil = s
    if Weapons then
        for _, v in ipairs(Weapons:GetChildren()) do
            if v:FindFirstChild("RecoilControl") then
                v.RecoilControl.Value = s and 0 or 1
            end
        end
    end
end, "ArsenalNoRecoilToggle")

-- No Spread (Arsenal version)
Window:AddToggle(TabArsenal, "No Spread (Arsenal)", "Set MaxSpread & SpreadRecovery", false, function(s)
    arsenalNoSpread = s
    if Weapons then
        for _, v in ipairs(Weapons:GetChildren()) do
            if v:FindFirstChild("MaxSpread") then
                v.MaxSpread.Value = s and 0.01 or 1
            end
            if v:FindFirstChild("SpreadRecovery") then
                v.SpreadRecovery.Value = s and 0.01 or 0.5
            end
        end
    end
end, "ArsenalNoSpreadToggle")

-- Divider
Window:AddDivider(TabArsenal, "Unlock & Skin Changer")

-- Tombol Unlock All Items
Window:AddButton(TabArsenal, "Unlock All Items", "Buka semua skin & item", function()
    AddEveryItem()
end, "UnlockButton")

-- Karakter Skin
local charSkins = GetSkinList("Character")
Window:AddDropdown(TabArsenal, "Character Skin", "Pilih skin karakter", charSkins, false, charSkins[1] or "Default", function(v)
    ChangeArsenalSkin("Character", v)
end, "CharSkinDrop")

-- Melee Skin
local meleeSkins = GetSkinList("Melee")
Window:AddDropdown(TabArsenal, "Melee Skin", "Pilih skin melee", meleeSkins, false, meleeSkins[1] or "Default", function(v)
    ChangeArsenalSkin("Melee", v)
end, "MeleeSkinDrop")

-- Gun Skin
local gunSkins = GetSkinList("Gun")
Window:AddDropdown(TabArsenal, "Gun Skin", "Pilih skin senjata", gunSkins, false, gunSkins[1] or "Default", function(v)
    ChangeArsenalSkin("GunSkin", v)
end, "GunSkinDrop")

-- Kill Effect
local killSkins = GetSkinList("KillEffect")
Window:AddDropdown(TabArsenal, "Kill Effect", "Pilih efek kematian", killSkins, false, killSkins[1] or "Default", function(v)
    ChangeArsenalSkin("KillEffect", v)
end, "KillEffectDrop")

-- Announcer
local announcerSkins = GetSkinList("Announcer")
Window:AddDropdown(TabArsenal, "Announcer", "Pilih suara announcer", announcerSkins, false, announcerSkins[1] or "Default", function(v)
    ChangeArsenalSkin("Announcer", v)
end, "AnnouncerDrop")

-- ========== SILENT HITBOX UI (TAMBAHAN) ==========
Window:AddDivider(TabArsenal, "Silent Hitbox")

-- Variabel & fungsi untuk Silent Hitbox
local silentHitbox = false
local hitboxExpansion = 13
local hitboxAlpha = 0.3
local targetPartsChoice = "All"
local silentLoopRunning = false
local silentLoopStop = false

local function getTargetParts(char)
    local parts = {}
    if not char then return parts end

    if targetPartsChoice == "All" or targetPartsChoice == "Head" then
        local head = char:FindFirstChild("Head")
        if head then table.insert(parts, head) end
        local headHB = char:FindFirstChild("HeadHB")
        if headHB then table.insert(parts, headHB) end
    end
    if targetPartsChoice == "All" or targetPartsChoice == "Torso" then
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
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

local function silentHitboxLoop()
    while silentLoopRunning and not silentLoopStop do
        if silentHitbox then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local parts = getTargetParts(player.Character)
                    for _, part in ipairs(parts) do
                        pcall(function()
                            part.Transparency = hitboxAlpha
                            part.CanCollide = false
                            part.Size = Vector3.new(hitboxExpansion, hitboxExpansion, hitboxExpansion)
                        end)
                    end
                end
            end
        else
            -- Reset semua part ke default
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local parts = getTargetParts(player.Character)
                    for _, part in ipairs(parts) do
                        pcall(function()
                            part.Transparency = 0
                            part.CanCollide = true
                            local name = part.Name
                            if name == "HumanoidRootPart" then part.Size = Vector3.new(2,2,1)
                            elseif name:find("Leg") then part.Size = Vector3.new(1,2,1)
                            elseif name == "Head" or name == "HeadHB" then part.Size = Vector3.new(2,1,1)
                            elseif name == "Torso" or name == "UpperTorso" then part.Size = Vector3.new(2,1.5,1)
                            else part.Size = Vector3.new(1,1,1) end
                        end)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end

local function startSilentHitbox()
    if silentLoopRunning then return end
    silentLoopRunning = true
    silentLoopStop = false
    task.spawn(silentHitboxLoop)
end

local function stopSilentHitbox()
    silentLoopStop = true
    task.wait(0.4)
    silentLoopRunning = false
    -- Reset semua part ke default
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local parts = getTargetParts(player.Character)
            for _, part in ipairs(parts) do
                pcall(function()
                    part.Transparency = 0
                    part.CanCollide = true
                    local name = part.Name
                    if name == "HumanoidRootPart" then part.Size = Vector3.new(2,2,1)
                    elseif name:find("Leg") then part.Size = Vector3.new(1,2,1)
                    elseif name == "Head" or name == "HeadHB" then part.Size = Vector3.new(2,1,1)
                    elseif name == "Torso" or name == "UpperTorso" then part.Size = Vector3.new(2,1.5,1)
                    else part.Size = Vector3.new(1,1,1) end
                end)
            end
        end
    end
end

-- UI Elements untuk Silent Hitbox
Window:AddToggle(TabArsenal, "Silent Hitbox", "Perbesar hitbox musuh", false, function(v)
    silentHitbox = v
    if v then
        startSilentHitbox()
    else
        stopSilentHitbox()
    end
end, "SilentHitboxToggle")

Window:AddDropdown(TabArsenal, "Target Parts", "Pilih bagian tubuh", {"All","Head","Torso","Legs"}, false, "All", function(v)
    targetPartsChoice = v
    if silentHitbox then
        stopSilentHitbox()
        startSilentHitbox()
    end
end, "HitboxTargetDrop")

Window:AddSlider(TabArsenal, "Hitbox Expansion", "Ukuran (1-30)", 1, 30, 13, function(v)
    hitboxExpansion = v
end, "HitboxExpand", true)

Window:AddSlider(TabArsenal, "Hitbox Alpha", "Transparansi (0-10)", 0, 10, 3, function(v)
    hitboxAlpha = v / 10
end, "HitboxAlpha", true)

Window:AddButton(TabArsenal, "Reset Hitbox", "Kembalikan ukuran asli", function()
    stopSilentHitbox()
    if silentHitbox then startSilentHitbox() end
    Window:Notify({Title="Reset Hitbox", Description="Hitbox dikembalikan ke default", Color=Color3.fromRGB(255,255,0), Delay=2})
end, "ResetHitboxBtn")

-- =====================================================
-- FPS & PING DRAGGABLE
-- =====================================================
if CoreGui:FindFirstChild("W424_STATS_GUI") then CoreGui.W424_STATS_GUI:Destroy() end
local statsGui = Instance.new("ScreenGui")
statsGui.Name = "W424_STATS_GUI"
statsGui.Parent = CoreGui
statsGui.ResetOnSpawn = false
statsGui.IgnoreGuiInset = true

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 140, 0, 28)
statsFrame.Position = UDim2.new(0, 10, 0, 10)
statsFrame.BackgroundTransparency = 0.5
statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statsFrame.Visible = false
statsFrame.Parent = statsGui
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0, 4)

local statsText = Instance.new("TextLabel")
statsText.Size = UDim2.new(1, 0, 1, 0)
statsText.BackgroundTransparency = 1
statsText.TextColor3 = Color3.fromRGB(0, 255, 100)
statsText.Font = Enum.Font.GothamBold
statsText.TextSize = 12
statsText.Text = " FPS:0  Ping:0ms"
statsText.Parent = statsFrame

local dragging = false
local dragStart, startPos
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local mousePos = input.Position
        local framePos = statsFrame.AbsolutePosition
        local frameSize = statsFrame.AbsoluteSize
        if mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
           mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y then
            dragging = true
            dragStart = input.Position
            startPos = statsFrame.Position
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            statsFrame.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local statsOn = false
Window:AddToggle(TabVisual, "FPS & Ping", "Tampilkan", false, function(s)
    statsOn = s
    statsFrame.Visible = s
end, "StatsToggle")

local frameCount = 0
local timeAcc = 0
RunService.RenderStepped:Connect(function(dt)
    if statsOn then
        frameCount = frameCount + 1
        timeAcc = timeAcc + dt
        if timeAcc >= 1 then
            local ping = 0
            pcall(function() ping = LocalPlayer:GetNetworkPing() * 1000 end)
            statsText.Text = string.format(" FPS:%d  Ping:%.0fms", frameCount, ping)
            frameCount = 0
            timeAcc = 0
        end
    end
end)

print("W424HUB v3.8 loaded - Arsenal Edition with Silent Hitbox & Reduce Map!")