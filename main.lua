-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- IMPROVED v8 (Fix Auto Claim, Feed, Kill Aura)
-- ==========================================

-- ==========================================
-- 1. SERVICES & REMOTES
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local RUN = game:GetService("RunService")
local LIGHTING = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Remote Events (fallback nama)
local ToolDamage = RemoteEvents:FindFirstChild("ToolDamageObject") or RemoteEvents:FindFirstChild("DamageObject")
local EquipItem = RemoteEvents:FindFirstChild("EquipItemHandle") or RemoteEvents:FindFirstChild("EquipTool")
local StartDrag = RemoteEvents:FindFirstChild("RequestStartDraggingItem") or RemoteEvents:FindFirstChild("StartDragging")
local StopDrag = RemoteEvents:FindFirstChild("StopDraggingItem") or RemoteEvents:FindFirstChild("StopDragging")
local BurnItem = RemoteEvents:FindFirstChild("RequestBurnItem") or RemoteEvents:FindFirstChild("BurnItem")
local ConsumeItem = RemoteEvents:FindFirstChild("RequestConsumeItem") or RemoteEvents:FindFirstChild("ConsumeItem")
local DestroyObject = RemoteEvents:FindFirstChild("DestroyObject")

-- Damage IDs (diperbarui dari spy dan tebakan)
local DamageIDs = {
    ["Old Axe"] = "21_9883131443",   -- dikonfirmasi
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016",
}

-- ==========================================
-- 2. STATE / CONFIG
-- ==========================================
getgenv().W424 = {
    SelectedTool = "Old Axe",
    ChopAura = false, ChopRadius = 100,
    KillAura = false, KillRadius = 100,
    AutoWood = false, WoodRadius = 100, TreeType = "All Trees",
    AutoHunt = false, HuntRadius = 100, TargetMob = "Wolf",
    AutoClaim = false, ClaimRadius = 100,
    AutoBringSelected = false, BringRadius = 150, SelectedItem = "All",
    AutoFeed = false,
    AutoCook = false, CookMaterial = "Morsel",
    AutoLootChest = false, LootRadius = 80,
    AutoEatHP = false,
    InstantChop = false,  -- mode instan destroy
    Noclip = false,
    InfiniteJump = false,
    Fullbright = false,
    WalkSpeed = 16,
    JumpPower = 50,
}

-- ==========================================
-- 3. KARAKTER REFRESH
-- ==========================================
local HRP, HUM
local function refreshChar()
    local c = LP.Character
    if c then
        HRP = c:FindFirstChild("HumanoidRootPart")
        HUM = c:FindFirstChild("Humanoid")
    end
end
refreshChar()
LP.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    refreshChar()
end)

-- ==========================================
-- 4. FUNGSI DASAR
-- ==========================================

-- 4a. Tool System
local function getToolInstance(toolName)
    for _, container in ipairs({LP:FindFirstChild("Inventory"), LP:FindFirstChild("Backpack")}) do
        if container then
            local t = container:FindFirstChild(toolName)
            if t then return t end
        end
    end
    return nil
end

local function equipTool(toolName)
    local c = LP.Character
    if c and c:FindFirstChild(toolName) then return c:FindFirstChild(toolName) end
    local tool = getToolInstance(toolName)
    if tool and EquipItem then
        EquipItem:FireServer("FireAllClients", tool)
        task.wait(0.15)
        if c and c:FindFirstChild(toolName) then return c:FindFirstChild(toolName) end
    end
    return nil
end

-- 4b. Attack (dengan damage ID)
local function attack(target, tool, damageID)
    if not target or not tool or not target:IsDescendantOf(Workspace) then return end
    local part = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") 
        or target:FindFirstChild("Trunk") or target:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    pcall(function() tool:Activate() end)
    if ToolDamage then
        pcall(function() 
            ToolDamage:InvokeServer(target, tool, damageID, CFrame.new(part.Position), false) 
        end)
    end
end

-- 4c. Instant Destroy Tree (menggunakan DestroyObject)
local function instantDestroyTree(treeModel)
    if not treeModel or not treeModel:IsDescendantOf(Workspace) then return end
    if not DestroyObject then return end
    local cf = treeModel.PrimaryPart and treeModel.PrimaryPart.CFrame or CFrame.new()
    pcall(function()
        -- Coba method Fire (server)
        DestroyObject:FireServer(treeModel)
    end)
    pcall(function()
        -- Coba firesignal (client)
        firesignal(DestroyObject.OnClientEvent, treeModel, cf)
    end)
end

-- 4d. Item Part
local function getItemPart(item)
    if not item then return nil end
    if item:IsA("Model") then
        if item.PrimaryPart then return item.PrimaryPart end
        for _, c in ipairs(item:GetDescendants()) do
            if c:IsA("BasePart") or c:IsA("MeshPart") then return c end
        end
    elseif item:IsA("BasePart") or item:IsA("MeshPart") then
        return item
    end
    return nil
end

-- 4e. Bring Item (Pindahkan item ke posisi)
local function bringItem(item, position)
    if not item or not item:IsDescendantOf(Workspace) or not StartDrag or not StopDrag then return end
    local part = getItemPart(item)
    if not part then return end
    pcall(function()
        StartDrag:FireServer(item)
        task.wait(0.05)
        if item:IsA("Model") and item.PivotTo then
            item:PivotTo(CFrame.new(position))
        else
            part.CFrame = CFrame.new(position)
        end
        task.wait(0.05)
        StopDrag:FireServer(item)
    end)
end

-- 4f. Tree Scanner
local function getTreePart(tree)
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChildWhichIsA("BasePart")
end

local function getTrees()
    local trees = {}
    local tType = getgenv().W424.TreeType
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                local match = false
                if tType == "All Trees" and (name:find("Tree") or name:find("Brightwood") or name:find("Fairy")) then match = true
                elseif tType == "Small Trees" and name == "Small Tree" then match = true
                elseif tType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then match = true
                elseif tType == "Brightwood Trees" and name:find("Brightwood") then match = true
                elseif tType == "Fairy Trees" and name:find("Fairy") then match = true
                end
                if match and getTreePart(obj) then table.insert(trees, obj) end
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, f in ipairs({"Foliage","Landmarks","Trees","Environment","Resources"}) do scan(map:FindFirstChild(f)) end
        scan(map)
    end
    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Tree") and getTreePart(obj) then table.insert(trees, obj) end
        end
    end
    return trees
end

-- 4g. Mob Scanner
local function getMobs()
    local mobs = {}
    local chars = Workspace:FindFirstChild("Characters")
    if chars then
        for _, m in ipairs(chars:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m ~= LP.Character then
                table.insert(mobs, m)
            end
        end
    end
    return mobs
end

-- 4h. Items & Campfire
local function getItems()
    return Workspace:FindFirstChild("Items")
end

local function getCampfirePos()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local cg = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if cg then
            local f = cg:FindFirstChild("MainFire") or cg:FindFirstChild("Campfire") or cg.PrimaryPart
            if f then
                local p = f:IsA("BasePart") and f or f:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position end
            end
        end
    end
    return Vector3.new(0, 19, 0)
end

-- 4i. Teleport Player with Back
local SG_Back, FRAME_Back, TP_CONN, LAST_POS, SAVED_POS
local function initBackUI()
    SG_Back = Instance.new("ScreenGui", CoreGui)
    SG_Back.Name = "W424_BackUI"
    SG_Back.ResetOnSpawn = false
    FRAME_Back = Instance.new("Frame", SG_Back)
    FRAME_Back.Size = UDim2.new(0,160,0,70)
    FRAME_Back.Position = UDim2.new(1,-180,1,-90)
    FRAME_Back.BackgroundColor3 = Color3.fromRGB(12,12,12)
    FRAME_Back.BorderSizePixel = 0
    FRAME_Back.Visible = false
    Instance.new("UICorner", FRAME_Back).CornerRadius = UDim.new(0,12)
    local LBL = Instance.new("TextLabel", FRAME_Back)
    LBL.Size = UDim2.new(1,0,0.42,0) LBL.Position = UDim2.new(0,0,0,4)
    LBL.BackgroundTransparency = 1 LBL.TextColor3 = Color3.fromRGB(140,140,140)
    LBL.TextScaled = true LBL.Font = Enum.Font.Gotham LBL.Text = "W424"
    local BACK_Btn = Instance.new("TextButton", FRAME_Back)
    BACK_Btn.Size = UDim2.new(1,-20,0,28) BACK_Btn.Position = UDim2.new(0,10,1,-36)
    BACK_Btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    BACK_Btn.TextColor3 = Color3.fromRGB(220,220,220)
    BACK_Btn.TextScaled = true BACK_Btn.Font = Enum.Font.GothamBold BACK_Btn.Text = "← back"
    Instance.new("UICorner", BACK_Btn).CornerRadius = UDim.new(0,8)
    BACK_Btn.MouseButton1Click:Connect(function()
        if TP_CONN then TP_CONN:Disconnect() end
        if HRP then HRP.Anchored = false end
        if LAST_POS and HRP then HRP.CFrame = LAST_POS end
        FRAME_Back.Visible = false
    end)
end
initBackUI()

local function teleportWithBack(cf)
    if not HRP then return end
    LAST_POS = HRP.CFrame
    if TP_CONN then TP_CONN:Disconnect() end
    HRP.Anchored = true
    HRP.CFrame = cf
    local elapsed = 0
    TP_CONN = RUN.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if not HRP then TP_CONN:Disconnect() return end
        if elapsed < 2 then HRP.CFrame = cf else HRP.Anchored = false TP_CONN:Disconnect() end
    end)
    FRAME_Back.Visible = true
end

-- ==========================================
-- 5. NOCLIP & FULLBRIGHT
-- ==========================================
local NC_Conn
local function setNoclip(v)
    if v then
        NC_Conn = RUN.Stepped:Connect(function()
            local c = LP.Character if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if NC_Conn then NC_Conn:Disconnect() end
        local c = LP.Character if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

UIS.JumpRequest:Connect(function()
    if getgenv().W424.InfiniteJump and HUM then
        HUM:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local OB, OA, OS = LIGHTING.Brightness, LIGHTING.Ambient, LIGHTING.GlobalShadows
local function setBright(v)
    if v then
        LIGHTING.Brightness = 5 LIGHTING.Ambient = Color3.fromRGB(255,255,255) LIGHTING.GlobalShadows = false
    else
        LIGHTING.Brightness = OB LIGHTING.Ambient = OA LIGHTING.GlobalShadows = OS
    end
end

-- ==========================================
-- 6. SAFEZONE
-- ==========================================
local safezoneBaseplates = {}
local function createSafeZone()
    if Workspace:FindFirstChild("SafeZoneBaseplate") then return end
    local baseplateSize = Vector3.new(2048,1,2048)
    local baseY = 100
    for dx = -1,1 do
        for dz = -1,1 do
            local pos = Vector3.new(dx*baseplateSize.X, baseY, dz*baseplateSize.Z)
            local bp = Instance.new("Part")
            bp.Name = "SafeZoneBaseplate"
            bp.Size = baseplateSize
            bp.Position = pos
            bp.Anchored = true
            bp.CanCollide = true
            bp.Transparency = 1
            bp.Parent = workspace
            table.insert(safezoneBaseplates, bp)
        end
    end
end
createSafeZone()

-- ==========================================
-- 7. ESP SYSTEM
-- ==========================================
local ESPs = {}
local ESPconns = {}
local function clearESP(tag)
    if ESPs[tag] then
        for _, o in ipairs(ESPs[tag]) do pcall(function() o:Destroy() end) end
        ESPs[tag] = {}
    end
end

local function makeESP(obj, tag, color)
    if not obj or not obj:IsA("Model") then return end
    if not ESPs[tag] then ESPs[tag] = {} end
    local hl = Instance.new("Highlight")
    hl.FillColor = color hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5 hl.OutlineTransparency = 0
    hl.Adornee = obj hl.Parent = CoreGui
    table.insert(ESPs[tag], hl)
    local r = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
    if r then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0,100,0,25) bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true bb.Adornee = r bb.Parent = CoreGui
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1,0,1,0) lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color lbl.TextStrokeTransparency = 0
        lbl.TextScaled = true lbl.Font = Enum.Font.GothamBold
        lbl.Text = obj.Name
        table.insert(ESPs[tag], bb)
    end
end

local function addESP(folder, tag, color)
    clearESP(tag)
    if not folder then return end
    for _, o in ipairs(folder:GetChildren()) do makeESP(o, tag, color) end
    if ESPconns[tag] then ESPconns[tag]:Disconnect() end
    ESPconns[tag] = folder.ChildAdded:Connect(function(o)
        task.wait(0.1) makeESP(o, tag, color)
    end)
end

-- ==========================================
-- 8. ENGINE LOOPS (IMPROVED)
-- ==========================================

-- 8a. Chop + Auto Wood (dengan Instant mode)
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.ChopAura or getgenv().W424.AutoWood then
            pcall(function()
                if not HRP then return end
                local r = getgenv().W424.ChopAura and getgenv().W424.ChopRadius or getgenv().W424.WoodRadius
                local useInstant = getgenv().W424.InstantChop
                local tool = equipTool(getgenv().W424.SelectedTool)
                local dmgID = DamageIDs[getgenv().W424.SelectedTool] or "21_9883131443"

                for _, tree in ipairs(getTrees()) do
                    if not (getgenv().W424.ChopAura or getgenv().W424.AutoWood) then break end
                    local p = getTreePart(tree)
                    if p and (HRP.Position - p.Position).Magnitude <= r then
                        if useInstant and DestroyObject then
                            instantDestroyTree(tree)
                        elseif tool then
                            attack(tree, tool, dmgID)
                        end
                        task.wait(0.08)
                    end
                end
            end)
        end
    end
end)

-- 8b. Kill Aura + Auto Hunt (dengan radius lebih besar)
task.spawn(function()
    while task.wait(0.25) do
        if getgenv().W424.KillAura or getgenv().W424.AutoHunt then
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local dmgID = DamageIDs[getgenv().W424.SelectedTool] or "21_9883131443"
                local r = getgenv().W424.KillAura and getgenv().W424.KillRadius or getgenv().W424.HuntRadius

                for _, mob in ipairs(getMobs()) do
                    if not (getgenv().W424.KillAura or getgenv().W424.AutoHunt) then break end
                    local h = mob:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        if getgenv().W424.AutoHunt and not mob.Name:find(getgenv().W424.TargetMob) then continue end
                        local p = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                        if p and (HRP.Position - p.Position).Magnitude <= r then
                            attack(mob, tool, dmgID)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 8c. Auto Claim (semua item, tanpa batas, radius besar)
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                if not HRP then return end
                local items = getItems()
                if not items then return end
                local r = getgenv().W424.ClaimRadius
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and not item.Name:lower():find("chest") then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= r then
                            bringItem(item, HRP.Position + Vector3.new(0, 2, 0))
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- 8d. Auto Bring Selected (tanpa batas)
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                if not HRP then return end
                local items = getItems()
                if not items then return end
                local target = getgenv().W424.SelectedItem
                local r = getgenv().W424.BringRadius
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and not item.Name:lower():find("chest") then
                        if target == "All" or item.Name == target then
                            local p = getItemPart(item)
                            if p and (HRP.Position - p.Position).Magnitude <= r then
                                bringItem(item, HRP.Position + Vector3.new(0, 2, 0))
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 8e. Auto Feed Campfire (perbaiki posisi dan remote)
task.spawn(function()
    while task.wait(0.8) do
        if getgenv().W424.AutoFeed and BurnItem then
            pcall(function()
                local inv = LP:FindFirstChild("Inventory") or LP:FindFirstChild("Backpack")
                if not inv then return end
                -- Cari item fuel di inventory
                local fuelItems = {"Log","Coal","Biofuel","Fuel Canister"}
                for _, item in ipairs(inv:GetChildren()) do
                    for _, fuel in ipairs(fuelItems) do
                        if item.Name == fuel then
                            -- Kirim remote burn
                            BurnItem:FireServer(item)
                            task.wait(0.2)
                            break
                        end
                    end
                end
            end)
        end
    end
end)

-- 8f. Auto Cook (perbaiki posisi drop)
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().W424.AutoCook then
            pcall(function()
                if not HRP then return end
                local items = getItems()
                if not items then return end
                local mat = getgenv().W424.CookMaterial:lower()
                local cfPos = getCampfirePos() + Vector3.new(0, 1, 0)
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(mat) then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 100 then
                            bringItem(item, cfPos)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 8g. Auto Eat HP
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoEatHP and HRP and HUM then
            pcall(function()
                if HUM.Health / HUM.MaxHealth < 0.5 then
                    local foods = {"Cooked Steak","Cooked Morsel","Berry","Carrot","Apple"}
                    local inv = LP:FindFirstChild("Inventory")
                    if inv then
                        for _, f in ipairs(foods) do
                            local item = inv:FindFirstChild(f)
                            if item and ConsumeItem then
                                ConsumeItem:InvokeServer(item)
                                task.wait(0.5)
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 8h. Auto Loot Chest (perbaiki radius)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                if not HRP then return end
                local items = getItems()
                if not items then return end
                local r = getgenv().W424.LootRadius
                for _, chest in ipairs(items:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:lower():find("chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main and (HRP.Position - main.Position).Magnitude <= r then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    if fireproximityprompt then fireproximityprompt(obj) end
                                    task.wait(0.3)
                                    -- Ambil loot dari chest
                                    for _, loot in ipairs(items:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") then
                                            local lp = getItemPart(loot)
                                            if lp and (HRP.Position - lp.Position).Magnitude <= r then
                                                bringItem(loot, HRP.Position + Vector3.new(0, 3, 0))
                                                task.wait(0.1)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 9. UI W424 (OrvionLib)
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()
local Window = OrvionLib:CreateWindow({Title = "W424 Hub v8 | 99 Nights", Icon = "rbxassetid://7733965386"})

local T = {
    Main = Window:AddTab("Main"),
    Farm = Window:AddTab("Farming"),
    Loot = Window:AddTab("Looting"),
    Move = Window:AddTab("Movement"),
    Vis = Window:AddTab("Visuals"),
    Pos = Window:AddTab("Positions"),
    Misc = Window:AddTab("Misc"),
}

-- === MAIN TAB ===
T.Main:AddDropdown({
    Title = "Select Tool",
    Values = {"Old Axe","Good Axe","Strong Axe","Chainsaw","Spear"},
    DefaultValue = "Old Axe",
    Callback = function(v) getgenv().W424.SelectedTool = v end
})
T.Main:AddButton({Title = "TP Campfire", Callback = function()
    local pos = getCampfirePos()
    if pos then teleportWithBack(CFrame.new(pos + Vector3.new(0,5,0))) end
end})
T.Main:AddButton({Title = "TP Stronghold", Callback = function()
    local m = Workspace:FindFirstChild("Map")
    if m and m:FindFirstChild("Landmarks") then
        local s = m.Landmarks:FindFirstChild("Stronghold")
        if s and s:FindFirstChild("Functional") and s.Functional:FindFirstChild("EntryDoors") then
            local dr = s.Functional.EntryDoors:FindFirstChild("DoorRight")
            if dr and dr:FindFirstChild("Model") then
                local mo = dr.Model
                local c = mo:GetChildren()
                if #c >= 5 and c[5]:IsA("BasePart") then
                    teleportWithBack(c[5].CFrame + Vector3.new(0,5,0))
                end
            end
        end
    end
end})
T.Main:AddButton({Title = "TP Diamond Chest", Callback = function()
    local items = getItems()
    if items then
        local chest = items:FindFirstChild("Stronghold Diamond Chest")
        if chest and chest:FindFirstChild("ChestLid") then
            local lid = chest.ChestLid
            local mesh = lid:FindFirstChild("Meshes/diamondchest_Cube.002")
            if mesh and mesh:IsA("BasePart") then
                teleportWithBack(mesh.CFrame + Vector3.new(0,5,0))
            end
        end
    end
end})

-- === FARMING TAB ===
local cs = T.Farm:AddCollapsibleSection("Chop Aura", false)
cs:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.ChopAura = v end})
cs:AddToggle({Title = "Instant Destroy (risky)", Default = false, Callback = function(v) getgenv().W424.InstantChop = v end})
cs:AddInput({Title = "Radius", Default = "100", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.ChopRadius = math.clamp(n,10,300) end
end})

local ks = T.Farm:AddCollapsibleSection("Kill Aura", false)
ks:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.KillAura = v end})
ks:AddInput({Title = "Radius", Default = "100", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.KillRadius = math.clamp(n,10,300) end
end})

local ws = T.Farm:AddCollapsibleSection("Auto Wood", false)
ws:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoWood = v end})
ws:AddInput({Title = "Radius", Default = "100", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.WoodRadius = math.clamp(n,10,300) end
end})
ws:AddDropdown({Title = "Tree Type", Values = {"All Trees","Small Trees","Hard Trees","Brightwood Trees","Fairy Trees"},
    DefaultValue = "All Trees", Callback = function(v) getgenv().W424.TreeType = v end})

local hs = T.Farm:AddCollapsibleSection("Auto Hunt", false)
hs:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoHunt = v end})
hs:AddInput({Title = "Radius", Default = "100", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.HuntRadius = math.clamp(n,10,300) end
end})
hs:AddDropdown({Title = "Target", Values = {"Bunny","Wolf","Alpha Wolf","Bear","Cultist"},
    DefaultValue = "Wolf", Callback = function(v) getgenv().W424.TargetMob = v end})

-- === LOOTING TAB ===
local cl = T.Loot:AddCollapsibleSection("Auto Claim (All Items)", false)
cl:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoClaim = v end})
cl:AddInput({Title = "Radius", Default = "100", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.ClaimRadius = math.clamp(n,10,300) end
end})

local bl = T.Loot:AddCollapsibleSection("Auto Bring Selected", false)
bl:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoBringSelected = v end})
bl:AddInput({Title = "Radius", Default = "150", Placeholder = "10-300", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.BringRadius = math.clamp(n,10,300) end
end})
T.Loot:AddDropdown({Title = "Select Item", Values = {
    "All","Log","Meat","Pelt","Bunny Foot","Sheet Metal","Bolt","Coal","Berry","Carrot",
    "Alien Chest","Alpha Wolf Pelt","Apple","Bandage","Bear Pelt","Biofuel",
    "Chainsaw","Cultist Gem","Fuel Canister","Good Axe","MedKit","Morsel",
    "Old Flashlight","Old Radio","Revolver","Rifle","Steak","Wolf Pelt"
}, DefaultValue = "All", Callback = function(v) getgenv().W424.SelectedItem = v end})

local ch = T.Loot:AddCollapsibleSection("Auto Loot Chest", false)
ch:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoLootChest = v end})
ch:AddInput({Title = "Radius", Default = "80", Placeholder = "10-200", Callback = function(v)
    local n = tonumber(v) if n then getgenv().W424.LootRadius = math.clamp(n,10,200) end
end})

local fl = T.Loot:AddCollapsibleSection("Auto Feed Campfire", false)
fl:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoFeed = v end})

local ck = T.Loot:AddCollapsibleSection("Auto Cook", false)
ck:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoCook = v end})
ck:AddDropdown({Title = "Cook", Values = {"Morsel","Steak"},
    DefaultValue = "Morsel", Callback = function(v) getgenv().W424.CookMaterial = v end})

local ek = T.Loot:AddCollapsibleSection("Auto Eat (HP < 50%)", false)
ek:AddToggle({Title = "Enable", Default = false, Callback = function(v) getgenv().W424.AutoEatHP = v end})

-- === MOVEMENT TAB ===
T.Move:AddInput({Title = "WalkSpeed", Default = "16", Placeholder = "16-250", Callback = function(v)
    local n = tonumber(v) if n then
        getgenv().W424.WalkSpeed = math.clamp(n,16,250)
        if HUM then HUM.WalkSpeed = getgenv().W424.WalkSpeed end
    end
end})
T.Move:AddInput({Title = "JumpPower", Default = "50", Placeholder = "30-200", Callback = function(v)
    local n = tonumber(v) if n then
        getgenv().W424.JumpPower = math.clamp(n,30,200)
        if HUM then HUM.JumpPower = getgenv().W424.JumpPower end
    end
end})
T.Move:AddToggle({Title = "Infinite Jump", Default = false, Callback = function(v) getgenv().W424.InfiniteJump = v end})
T.Move:AddToggle({Title = "Noclip", Default = false, Callback = function(v) getgenv().W424.Noclip = v setNoclip(v) end})

-- === VISUALS TAB ===
T.Vis:AddToggle({Title = "Char ESP", Default = false, Callback = function(v)
    if v then addESP(Workspace:FindFirstChild("Characters"), "chars", Color3.fromRGB(255,60,60))
    else clearESP("chars") if ESPconns["chars"] then ESPconns["chars"]:Disconnect() end end
end})
T.Vis:AddToggle({Title = "NPC ESP", Default = false, Callback = function(v)
    if v then addESP(Workspace:FindFirstChild("NPCs"), "npcs", Color3.fromRGB(255,165,0))
    else clearESP("npcs") if ESPconns["npcs"] then ESPconns["npcs"]:Disconnect() end end
end})
T.Vis:AddToggle({Title = "Item ESP", Default = false, Callback = function(v)
    if v then addESP(getItems(), "items", Color3.fromRGB(80,255,80))
    else clearESP("items") if ESPconns["items"] then ESPconns["items"]:Disconnect() end end
end})
T.Vis:AddToggle({Title = "Fullbright", Default = false, Callback = function(v) getgenv().W424.Fullbright = v setBright(v) end})

-- === POSITIONS TAB ===
T.Pos:AddButton({Title = "Save Pos", Callback = function()
    if HRP then SAVED_POS = HRP.CFrame end
    if setclipboard and HRP then setclipboard(tostring(HRP.Position)) end
    OrvionLib:Notify("Saved","Position saved",3)
end})
T.Pos:AddButton({Title = "Go Saved", Callback = function() if SAVED_POS then teleportWithBack(SAVED_POS) end end})
T.Pos:AddButton({Title = "TP to Nearest Tree", Callback = function()
    local trees = getTrees()
    local nearest, dist = nil, math.huge
    for _, tree in ipairs(trees) do
        local p = getTreePart(tree)
        if p and HRP then
            local d = (HRP.Position - p.Position).Magnitude
            if d < dist then dist = d; nearest = p end
        end
    end
    if nearest then
        teleportWithBack(nearest.CFrame + Vector3.new(0,3,0))
        OrvionLib:Notify("Teleport","To nearest tree",2)
    end
end})

-- === MISC TAB ===
T.Misc:AddToggle({Title = "Show Safe Zone", Default = false, Callback = function(v)
    for _, bp in ipairs(safezoneBaseplates) do
        bp.Transparency = v and 0.8 or 1
        bp.CanCollide = v
    end
end})

T.Misc:AddButton({Title = "Anti AFK", Callback = function()
    local bb = game:service'VirtualUser'
    game:service'Players'.LocalPlayer.Idled:connect(function()
        bb:CaptureController() bb:ClickButton2(Vector2.new())
    end)
    OrvionLib:Notify("Anti-AFK","Active",3)
end})

T.Misc:AddButton({Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- ==========================================
-- 10. BUBBLE TOGGLE
-- ==========================================
local BG = Instance.new("ScreenGui", CoreGui)
BG.Name = "W424_Bubble" BG.ResetOnSpawn = false
local BB = Instance.new("TextButton", BG)
BB.Size = UDim2.new(0,50,0,50) BB.Position = UDim2.new(0,20,0.5,-25)
BB.BackgroundColor3 = Color3.fromRGB(30,30,30) BB.Text = "⚡"
BB.TextColor3 = Color3.new(1,1,1) BB.TextScaled = true
BB.Font = Enum.Font.GothamBold BB.BorderSizePixel = 0
Instance.new("UICorner", BB).CornerRadius = UDim.new(1,0)

local drag, dStart, dPos
BB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true dStart = i.Position dPos = BB.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        BB.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end
end)

local vis = true
BB.MouseButton1Click:Connect(function()
    if drag then return end
    vis = not vis
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and (g.Name:find("Orvion") or g.Name:find("orvion")) then
            g.Enabled = vis
        end
    end
    BB.BackgroundColor3 = vis and Color3.fromRGB(30,30,30) or Color3.fromRGB(60,20,20)
    BB.Text = vis and "⚡" or "✕"
end)

-- ==========================================
-- 11. NOTIFIKASI START
-- ==========================================
task.wait(0.5)
OrvionLib:Notify("W424 Hub v8","All features improved!",5)
print("[W424] v8 Loaded with fixes.")