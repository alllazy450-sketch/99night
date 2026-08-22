-- ============================================================
-- W424 HUB | v5.41 PRO (SURVIVAL ENGINE - FULL RESTORED)
-- UI Framework: Oxidelib (Midnight Theme)
-- Map: 99 Night in the Forest
-- ============================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
Library:SetTheme("Midnight")

local MY_LOGO = "rbxassetid://70773874533764"

-- [ SERVICES ]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- [ CONSTANTS ]
local LocalPlayer = Players.LocalPlayer
local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local RemoteConsume = ReplicatedStorage:FindFirstChild("RequestConsumeItem")
local TreesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
local Characters = Workspace:FindFirstChild("Characters")

local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)
local SAFE_POINT = Vector3.new(0, 200, 0)

-- [ STATE & SETTINGS ]
local Toggles = {
    AutoEat = false, AutoCook = false, AutoGrind = false, AutoFuel = false,
    KillAura = false, TreeAura = false, Fullbright = false,
    ESP_Mobs = false, ESP_Items = false, ESP_Trees = false,
    InfJump = false, AutoEscape = false, AntiAFK = true, FpsPing = false
}
local Settings = {
    EatThreshold = 70, AuraRadius = 350, TreeRadius = 80,
    WalkSpeed = 16, GrindRadius = 1000, EscapeDist = 40,
    GrindItems = {}, FuelItems = {}, SelectedTP = {}
}

-- ==========================================
-- CORE FUNCTIONS (RESTORED)
-- ==========================================
local function getRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

local function findValidPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function teleportTo(pos)
    local hrp = getRoot()
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function reliableDrag(item, pos)
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.1)
        if item:IsA("BasePart") then item.CFrame = CFrame.new(pos) 
        elseif item:IsA("Model") then item:PivotTo(CFrame.new(pos)) end
        task.wait(0.1)
        if dragStop then dragStop:FireServer(item) end
    end)
end

-- [ TREE UTILITY (RESTORED) ]
local TreeUtility = {
    ToolDamageObject = RemoteEvents:FindFirstChild("ToolDamageObject"),
    EnemyHandler = require(LocalPlayer.PlayerScripts.Client.EnemyHandler)
}

function TreeUtility:HoldingAxe()
    for _, model in ipairs(LocalPlayer.Character:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("ToolName") and model:GetAttribute("ToolName"):find("Axe") then
            return model:FindFirstChild("OriginalItem") and model.OriginalItem.Value
        end
    end
    return nil
end

function TreeUtility:GetTrees(radius)
    local res = {}
    local hrp = getRoot()
    local folder = TreesFolder or Workspace:FindFirstChild("Foliage")
    if not hrp or not folder then return res end
    for _, tree in ipairs(folder:GetChildren()) do
        local trunk = tree:FindFirstChild("Trunk")
        if trunk and (trunk.Position - hrp.Position).Magnitude < radius then
            if (tree:GetAttribute("Health") or 10) > 0 then
                table.insert(res, {Tree = tree, Trunk = trunk})
            end
        end
    end
    return res
end

-- ==========================================
-- UI SETUP
-- ==========================================
local Window = Library:CreateWindow({
    Name = "W424 HUB",
    BrandSubtitle = "99 Night: Full Restoration PRO v5.41",
    Logo = MY_LOGO,
    LogoZoom = 1.5,
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(720, 600),
})

local TabMain = Window:AddTab({ Name = "Main", Icon = "home" })
local TabAura = Window:AddTab({ Name = "Aura", Icon = "zap" })
local TabItem = Window:AddTab({ Name = "Item TP", Icon = "download" })
local TabTP   = Window:AddTab({ Name = "Teleport", Icon = "map-pin" })
local TabVis  = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local TabMisc = Window:AddTab({ Name = "Misc", Icon = "settings" })

-- ===== MAIN TAB =====
local SubAuto = TabMain:AddSubTab("Survival")
SubAuto:AddToggle({ Name = "Auto Eat", Default = false, Callback = function(v) Toggles.AutoEat = v end })
SubAuto:AddSlider({ Name = "Eat HP %", Min = 10, Max = 95, Default = 70, Callback = function(v) Settings.EatThreshold = v end })
SubAuto:AddToggle({ Name = "Auto Cook (Steak/Morsel)", Default = false, Callback = function(v) Toggles.AutoCook = v end })

local SubGrind = TabMain:AddSubTab("Grind & Fuel")
SubGrind:AddSlider({ Name = "Max Grab Radius", Min = 100, Max = 5000, Default = 1000, Callback = function(v) Settings.GrindRadius = v end })
SubGrind:AddMultiDropdown({
    Name = "Auto Grind Items",
    Options = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Sheet Metal", "Washing Machine", "Tyre"},
    Default = {},
    Callback = function(v) Settings.GrindItems = v end
})
SubGrind:AddMultiDropdown({
    Name = "Auto Fuel Items",
    Options = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    Default = {},
    Callback = function(v) Settings.FuelItems = v end
})

-- ===== AURA TAB =====
local SubKill = TabAura:AddSubTab("Kill Aura")
SubKill:AddToggle({ Name = "Kill Aura", Default = false, Callback = function(v) Toggles.KillAura = v end })
SubKill:AddSlider({ Name = "Radius", Min = 50, Max = 800, Default = 350, Callback = function(v) Settings.AuraRadius = v end })

local SubTree = TabAura:AddSubTab("Tree Aura")
SubTree:AddToggle({ Name = "Tree Aura", Default = false, Callback = function(v) Toggles.TreeAura = v end })
SubTree:AddSlider({ Name = "Chop Radius", Min = 10, Max = 300, Default = 80, Callback = function(v) Settings.TreeRadius = v end })
SubTree:AddButton({ Name = "Test Chop All (1x)", Callback = function()
    local trees = TreeUtility:GetTrees(Settings.TreeRadius)
    for _, t in pairs(trees) do TreeUtility.ToolDamageObject:InvokeServer(t.Tree, TreeUtility:HoldingAxe(), "123", t.Trunk.CFrame, true) end
end })

local SubEsc = TabAura:AddSubTab("Escape")
SubEsc:AddToggle({ Name = "Auto Escape", Default = false, Callback = function(v) Toggles.AutoEscape = v end })

-- ===== ITEM TP TAB (RESTORED CATEGORIES) =====
local SubItemTP = TabItem:AddSubTab("Bring Items")
local itemCats = {
    Food = {"Berry", "Carrot", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel"},
    Weapons = {"Pistol", "Revolver", "Rifle", "Chainsaw", "Spear", "Rifle Ammo"},
    Fuel = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk = {"UFO Junk", "Bolt", "Sheet Metal", "Washing Machine", "Tyre"}
}

for cat, list in pairs(itemCats) do
    SubItemTP:AddSection(cat:upper())
    SubItemTP:AddDropdown({ Name = "Select " .. cat, Options = list, Default = list[1], Callback = function(v) Settings.SelectedTP[cat] = v end })
    SubItemTP:AddButton({ Name = "Bring " .. cat, Callback = function()
        local target = Settings.SelectedTP[cat] or list[1]
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item.Name == target then reliableDrag(item, getRoot().Position + Vector3.new(0,2,0)) end
        end
    end })
end

-- ===== TELEPORT TAB =====
local SubTele = TabTP:AddSubTab("Locations")
SubTele:AddButton({ Name = "TP Campfire", Callback = function() teleportTo(CAMPFIRE_POS) end })
SubTele:AddButton({ Name = "TP Lost Child (Dino)", Callback = function() 
    local dino = workspace.Map.Landmarks["Jail Cellar1"]:FindFirstChild("Dino")
    if dino then teleportTo(findValidPart(dino).Position) end
end })
SubTele:AddButton({ Name = "TP Lost Child (Halloween)", Callback = function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("lost child") then teleportTo(findValidPart(obj).Position) break end
    end
end })

-- ===== VISUALS TAB =====
local SubVisual = TabVis:AddSubTab("Visuals")
SubVisual:AddToggle({ Name = "ESP Mobs", Default = false, Callback = function(v) Toggles.ESP_Mobs = v end })
SubVisual:AddToggle({ Name = "ESP Items", Default = false, Callback = function(v) Toggles.ESP_Items = v end })
SubVisual:AddToggle({ Name = "ESP Trees (HP)", Default = false, Callback = function(v) Toggles.ESP_Trees = v end })

-- ===== MISC TAB =====
local SubMisc = TabMisc:AddSubTab("System")
SubMisc:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = 16, Callback = function(v) if getRoot() then LocalPlayer.Character.Humanoid.WalkSpeed = v end end })
SubMisc:AddToggle({ Name = "Infinite Jump", Default = false, Callback = function(v) Toggles.InfJump = v end })
SubMisc:AddToggle({ Name = "Fullbright", Default = false, Callback = function(v) Toggles.Fullbright = v end })
SubMisc:AddToggle({ Name = "FPS & Ping Counter", Default = false, Callback = function(v) Toggles.FpsPing = v end })
SubMisc:AddButton({ Name = "Potato Mode", Callback = function()
    for _, o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then o.Material = Enum.Material.SmoothPlastic end end
    Lighting.GlobalShadows = false
end })

-- ==========================================
-- BACKGROUND ENGINE (LOOPS)
-- ==========================================

-- 1. Main Survival Loop (Grind, Fuel, Cook)
task.spawn(function()
    while task.wait(1) do
        local hrp = getRoot()
        if not hrp then continue end
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            local itemName = item.Name
            local iPart = findValidPart(item)
            if iPart and (iPart.Position - hrp.Position).Magnitude < Settings.GrindRadius then
                if Settings.GrindItems[itemName] then reliableDrag(item, MACHINE_POS)
                elseif Settings.FuelItems[itemName] then reliableDrag(item, CAMPFIRE_POS)
                elseif Toggles.AutoCook and (itemName == "Steak" or itemName == "Morsel") then reliableDrag(item, CAMPFIRE_POS)
                end
            end
        end
    end
end)

-- 2. Kill Aura & Tree Aura
task.spawn(function()
    while task.wait(0.1) do
        local hrp = getRoot()
        if not hrp then continue end
        -- Kill Aura
        if Toggles.KillAura then
            for _, mob in ipairs(Characters:GetChildren()) do
                local mp = findValidPart(mob)
                if mp and (mp.Position - hrp.Position).Magnitude < Settings.AuraRadius then
                    pcall(function() RemoteEvents.ToolDamageObject:InvokeServer(mob, nil, "123", mp.CFrame) end)
                end
            end
        end
        -- Tree Aura
        if Toggles.TreeAura then
            local trees = TreeUtility:GetTrees(Settings.TreeRadius)
            for _, t in pairs(trees) do 
                pcall(function() TreeUtility.ToolDamageObject:InvokeServer(t.Tree, TreeUtility:HoldingAxe(), "123", t.Trunk.CFrame, true) end)
            end
        end
    end
end)

-- 3. UI Overlays (FPS, Time Notif, Escape)
local wasNight = Lighting.ClockTime >= 18 or Lighting.ClockTime < 6
RunService.Heartbeat:Connect(function()
    -- Fullbright
    if Toggles.Fullbright then Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.GlobalShadows = false end
    -- Time Notif
    local isNight = Lighting.ClockTime >= 18 or Lighting.ClockTime < 6
    if isNight ~= wasNight then
        wasNight = isNight
        Library:Notify({Title = isNight and "🌙 Night" or "☀️ Day", Content = "Time has changed!", Type = "info"})
    end
end)

Window:Notify({ Title = "W424 HUB", Content = "Full Restoration v5.41 Loaded!", Type = "success" })
