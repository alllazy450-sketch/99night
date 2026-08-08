-- ============================================================
-- 99 NIGHTS HUB | ORVION UI | FINAL VERSION
-- BASED ON WIKI ITEMS | FIXED AUTO WOOD & KILL AURA
-- ============================================================

-- ============================================================
-- 1. LOAD LIBRARY ORVION
-- ============================================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ============================================================
-- 2. SERVICES & REMOTES
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Remote Events
local StartDrag = RemoteEvents:FindFirstChild("RequestStartDraggingItem") or RemoteEvents:FindFirstChild("StartDragging")
local StopDrag  = RemoteEvents:FindFirstChild("StopDraggingItem") or RemoteEvents:FindFirstChild("StopDragging")
local EquipItem = RemoteEvents:FindFirstChild("EquipItemHandle") or RemoteEvents:FindFirstChild("EquipTool")
local UnequipItem = RemoteEvents:FindFirstChild("UnequipItemHandle") or RemoteEvents:FindFirstChild("UnequipTool")
local ToolDamage = RemoteEvents:FindFirstChild("ToolDamageObject") or RemoteEvents:FindFirstChild("DamageObject")
local ConsumeItem = RemoteEvents:FindFirstChild("RequestConsumeItem") or RemoteEvents:FindFirstChild("ConsumeItem")
local BurnItem = RemoteEvents:FindFirstChild("RequestBurnItem") or RemoteEvents:FindFirstChild("BurnItem")

-- Damage IDs (dari spy terbaru)
local toolsDamageIDs = {
    ["Old Axe"]     = "114_9883131443",
    ["Good Axe"]    = "112_8982038982",
    ["Strong Axe"]  = "116_8982038982",
    ["Chainsaw"]    = "647_8992824875",
    ["Spear"]       = "196_8999010016",
}

-- State
getgenv().NightsHub = {
    SelectedTool = "Old Axe",
    KillAura = false,
    KillRadius = 250,
    AutoWood = false,
    WoodRadius = 50,
    AutoFeed = false,
    AutoFeedAlways = false,
    FuelType = "Log",
    AutoCook = false,
    CookItem = "Morsel",
    AutoGrind = false,
    AutoBiofuel = false,
    AutoEatHP = false,
    ShowSafeZone = false,
    ESP = false,
    Chams = false,
    Fullbright = false,
}

-- ============================================================
-- 3. KARAKTER REFRESH
-- ============================================================
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

-- ============================================================
-- 4. FUNGSI DASAR
-- ============================================================

-- Tool system
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
        pcall(function()
            EquipItem:FireServer("FireAllClients", tool)
        end)
        task.wait(0.15)
        if c and c:FindFirstChild(toolName) then return c:FindFirstChild(toolName) end
    end
    return nil
end

local function unequipTool(tool)
    if tool and UnequipItem then
        pcall(function() UnequipItem:FireServer("FireAllClients", tool) end)
    end
end

-- Attack dengan swing
local function attack(target, tool, damageID)
    if not target or not tool or not target:IsDescendantOf(Workspace) then return end
    local part = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
        or target:FindFirstChild("Trunk") or target:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    pcall(function() tool:Activate() end)
    task.wait(0.05)

    if ToolDamage then
        pcall(function()
            ToolDamage:InvokeServer(target, tool, damageID, CFrame.new(part.Position), false)
        end)
    end
end

-- Item Part Finder (mendalam)
local function getItemPart(item)
    if not item then return nil end
    if item:IsA("Model") then
        if item.PrimaryPart then return item.PrimaryPart end
        for _, c in ipairs(item:GetDescendants()) do
            if c:IsA("BasePart") or c:IsA("MeshPart") or c:IsA("Part") or c:IsA("UnionOperation") then
                return c
            end
        end
    elseif item:IsA("BasePart") or item:IsA("MeshPart") then
        return item
    end
    return nil
end

-- Cek item bisa dipindahkan
local function canMoveItem(item)
    if not item then return false end
    if not item:IsDescendantOf(Workspace) then return false end
    return true
end

-- Bring item dengan drag
local function bringItem(item, position)
    if not item or not canMoveItem(item) or not StartDrag or not StopDrag then return end
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

-- Tree scanner untuk Small Tree
local function getTreePart(tree)
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChildWhichIsA("BasePart")
end

local function getAllSmallTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Small Tree" and getTreePart(obj) then
                table.insert(trees, obj)
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        if map:FindFirstChild("Foliage") then scan(map.Foliage) end
        if map:FindFirstChild("Landmarks") then scan(map.Landmarks) end
        if map:FindFirstChild("Trees") then scan(map.Trees) end
    end
    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Small Tree" and getTreePart(obj) then
                table.insert(trees, obj)
            end
        end
    end
    return trees
end

-- Mob scanner
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

-- Items folder & campfire
local function getItemsFolder()
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

local function getCampfireCFrame()
    return CFrame.new(getCampfirePos())
end

-- Teleport player
local function tpPlayer(cf)
    if HRP then
        HRP.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

-- ============================================================
-- 5. SAFE ZONE & ESP
-- ============================================================
local safezoneBaseplates = {}
local function createSafeZone()
    if Workspace:FindFirstChild("SafeZoneBaseplate") then return end
    local baseplateSize = Vector3.new(2048, 1, 2048)
    local baseY = 100
    for dx = -1, 1 do
        for dz = -1, 1 do
            local pos = Vector3.new(dx * baseplateSize.X, baseY, dz * baseplateSize.Z)
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
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Adornee = obj
    hl.Parent = CoreGui
    table.insert(ESPs[tag], hl)
    local r = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
    if r then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0,100,0,25)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        bb.Adornee = r
        bb.Parent = CoreGui
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
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
        task.wait(0.1)
        makeESP(o, tag, color)
    end)
end

-- ============================================================
-- 6. ENGINE LOOPS (FIXED)
-- ============================================================

-- Kill Aura Loop
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().NightsHub.KillAura then
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().NightsHub.SelectedTool)
                if not tool then
                    local c = LP.Character
                    if c then
                        for _, child in ipairs(c:GetChildren()) do
                            if child:IsA("Tool") and toolsDamageIDs[child.Name] then
                                tool = child
                                break
                            end
                        end
                    end
                end
                if not tool then return end
                local dmgID = toolsDamageIDs[getgenv().NightsHub.SelectedTool] or "114_9883131443"
                local r = getgenv().NightsHub.KillRadius

                for _, mob in ipairs(getMobs()) do
                    local h = mob:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        local p = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                        if p and (HRP.Position - p.Position).Magnitude <= r then
                            pcall(function() tool:Activate() end)
                            task.wait(0.03)
                            if ToolDamage then
                                pcall(function()
                                    ToolDamage:InvokeServer(mob, tool, dmgID, CFrame.new(p.Position), false)
                                end)
                            end
                            task.wait(0.08)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Wood (Teleport ke Small Tree + Attack)
local AutoWoodActive = false
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().NightsHub.AutoWood then
            if not AutoWoodActive then
                AutoWoodActive = true
            end
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().NightsHub.SelectedTool)
                if not tool then
                    local c = LP.Character
                    if c then
                        for _, child in ipairs(c:GetChildren()) do
                            if child:IsA("Tool") and toolsDamageIDs[child.Name] then
                                tool = child
                                break
                            end
                        end
                    end
                end
                if not tool then return end
                local dmgID = toolsDamageIDs[getgenv().NightsHub.SelectedTool] or "114_9883131443"
                local r = getgenv().NightsHub.WoodRadius

                local trees = getAllSmallTrees()
                local nearest = nil
                local nearestDist = math.huge

                for _, tree in ipairs(trees) do
                    if tree and tree:IsDescendantOf(Workspace) then
                        local p = getTreePart(tree)
                        if p then
                            local d = (HRP.Position - p.Position).Magnitude
                            if d < nearestDist then
                                nearestDist = d
                                nearest = tree
                            end
                        end
                    end
                end

                if nearest and nearestDist <= r then
                    local trunk = getTreePart(nearest)
                    if trunk and trunk:IsDescendantOf(Workspace) then
                        local lookDir = (trunk.Position - HRP.Position).Unit
                        if lookDir.Magnitude < 0.1 then lookDir = Vector3.new(1,0,0) end
                        local tpPos = trunk.Position - lookDir * 2.5 + Vector3.new(0, 0.5, 0)
                        HRP.CFrame = CFrame.new(tpPos, trunk.Position)
                        task.wait(0.05)
                        pcall(function() tool:Activate() end)
                        task.wait(0.05)
                        if ToolDamage then
                            pcall(function()
                                ToolDamage:InvokeServer(nearest, tool, dmgID, CFrame.new(trunk.Position), false)
                            end)
                        end
                        task.wait(0.1)
                    end
                else
                    if nearest then
                        local trunk = getTreePart(nearest)
                        if trunk and trunk:IsDescendantOf(Workspace) then
                            local lookDir = (trunk.Position - HRP.Position).Unit
                            if lookDir.Magnitude < 0.1 then lookDir = Vector3.new(1,0,0) end
                            local tpPos = trunk.Position - lookDir * 2.5 + Vector3.new(0, 0.5, 0)
                            HRP.CFrame = CFrame.new(tpPos, trunk.Position)
                            task.wait(0.05)
                            pcall(function() tool:Activate() end)
                            task.wait(0.05)
                            if ToolDamage then
                                pcall(function()
                                    ToolDamage:InvokeServer(nearest, tool, dmgID, CFrame.new(trunk.Position), false)
                                end)
                            end
                            task.wait(0.1)
                        end
                    else
                        task.wait(1)
                    end
                end
            end)
        else
            if AutoWoodActive then
                AutoWoodActive = false
                local cf = getCampfireCFrame()
                if cf and HRP then
                    tpPlayer(cf)
                end
            end
            task.wait(0.5)
        end
    end
end)

-- Auto Feed Always (BurnItem)
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().NightsHub.AutoFeedAlways and BurnItem then
            pcall(function()
                local inv = LP:FindFirstChild("Inventory") or LP:FindFirstChild("Backpack")
                if not inv then return end
                local fuel = getgenv().NightsHub.FuelType
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name == fuel and canMoveItem(item) then
                        BurnItem:FireServer(item)
                        task.wait(0.3)
                        break
                    end
                end
            end)
        end
    end
end)

-- Auto Feed HP Based (Drag ke api)
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().NightsHub.AutoFeed then
            pcall(function()
                if not HRP then return end
                local items = getItemsFolder()
                if not items then return end
                local fuel = getgenv().NightsHub.FuelType
                local cfPos = getCampfirePos() + Vector3.new(0, 1.5, 0)

                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and item.Name == fuel and canMoveItem(item) then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 150 then
                            bringItem(item, cfPos)
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Cook
task.spawn(function()
    while task.wait(2) do
        if getgenv().NightsHub.AutoCook then
            pcall(function()
                if not HRP then return end
                local items = getItemsFolder()
                if not items then return end
                local cookItem = getgenv().NightsHub.CookItem:lower()
                local cfPos = getCampfirePos() + Vector3.new(0, 1.5, 0)

                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(cookItem) and canMoveItem(item) then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 150 then
                            bringItem(item, cfPos)
                            task.wait(0.15)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Grind
task.spawn(function()
    local grindPos = Vector3.new(21, 16, -5)
    while task.wait(2) do
        if getgenv().NightsHub.AutoGrind then
            pcall(function()
                if not HRP then return end
                local items = getItemsFolder()
                if not items then return end
                local grindItems = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Cultist Experiment", "Cultist Component", "Gem of the Forest Fragment", "Broken Microwave"}
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and canMoveItem(item) then
                        for _, name in ipairs(grindItems) do
                            if item.Name == name then
                                local p = getItemPart(item)
                                if p and (HRP.Position - p.Position).Magnitude <= 150 then
                                    bringItem(item, grindPos)
                                    task.wait(0.1)
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Biofuel
task.spawn(function()
    while task.wait(2) do
        if getgenv().NightsHub.AutoBiofuel then
            pcall(function()
                if not HRP then return end
                local items = getItemsFolder()
                if not items then return end
                local processor = Workspace:FindFirstChild("Structures") and Workspace.Structures:FindFirstChild("Biofuel Processor")
                local part = processor and processor:FindFirstChild("Part")
                if part then
                    local bioPos = part.Position + Vector3.new(0, 5, 0)
                    local bioItems = {"Carrot", "Cooked Morsel", "Morsel", "Steak", "Cooked Steak", "Log"}
                    for _, item in ipairs(items:GetChildren()) do
                        if item:IsA("Model") and canMoveItem(item) then
                            for _, name in ipairs(bioItems) do
                                if item.Name == name then
                                    local p = getItemPart(item)
                                    if p and (HRP.Position - p.Position).Magnitude <= 150 then
                                        bringItem(item, bioPos)
                                        task.wait(0.1)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Eat HP
task.spawn(function()
    while task.wait(1) do
        if getgenv().NightsHub.AutoEatHP and HRP and HUM then
            pcall(function()
                if HUM.Health / HUM.MaxHealth < 0.5 then
                    local foods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
                    local inv = LP:FindFirstChild("Inventory")
                    if inv and ConsumeItem then
                        for _, f in ipairs(foods) do
                            local item = inv:FindFirstChild(f)
                            if item then
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

-- ============================================================
-- 7. UI ORVION
-- ============================================================
local Window = OrvionLib:CreateWindow({
    Title = "99 Nights Hub",
    Icon = "rbxassetid://7733965386"
})

-- Tab: Main
local T_Main = Window:AddTab("Main")
local statusPara = T_Main:AddParagraph({
    Title = "Status",
    Content = "Ready"
})

T_Main:AddButton({
    Title = "TP Campfire",
    Callback = function()
        local cf = getCampfireCFrame()
        if cf then tpPlayer(cf) end
    end
})

T_Main:AddButton({
    Title = "TP Stronghold",
    Callback = function()
        local m = Workspace:FindFirstChild("Map")
        if m and m:FindFirstChild("Landmarks") then
            local s = m.Landmarks:FindFirstChild("Stronghold")
            if s and s:FindFirstChild("Functional") and s.Functional:FindFirstChild("EntryDoors") then
                local dr = s.Functional.EntryDoors:FindFirstChild("DoorRight")
                if dr and dr:FindFirstChild("Model") then
                    local mo = dr.Model
                    local c = mo:GetChildren()
                    if #c >= 5 and c[5]:IsA("BasePart") then
                        tpPlayer(c[5].CFrame)
                    end
                end
            end
        end
    end
})

T_Main:AddButton({
    Title = "TP Diamond Chest",
    Callback = function()
        local items = getItemsFolder()
        if items then
            local chest = items:FindFirstChild("Stronghold Diamond Chest")
            if chest and chest:FindFirstChild("ChestLid") then
                local lid = chest.ChestLid
                local mesh = lid:FindFirstChild("Meshes/diamondchest_Cube.002")
                if mesh and mesh:IsA("BasePart") then
                    tpPlayer(mesh.CFrame)
                end
            end
        end
    end
})

T_Main:AddButton({
    Title = "Save Position",
    Callback = function()
        if HRP then SAVED_POS = HRP.CFrame end
        statusPara:SetDesc("Position saved!")
        task.wait(1)
        statusPara:SetDesc("Ready")
    end
})

T_Main:AddButton({
    Title = "Go to Saved Position",
    Callback = function()
        if SAVED_POS then tpPlayer(SAVED_POS) end
    end
})

-- Tab: Combat
local T_Combat = Window:AddTab("Combat")

T_Combat:AddDropdown({
    Title = "Select Tool",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    DefaultValue = "Old Axe",
    Callback = function(v)
        getgenv().NightsHub.SelectedTool = v
    end
})

T_Combat:AddToggle({
    Title = "Kill Aura",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.KillAura = state
        statusPara:SetDesc(state and "Kill Aura: ON" or "Kill Aura: OFF")
        task.wait(1)
        statusPara:SetDesc("Ready")
    end
})

T_Combat:AddInput({
    Title = "Kill Radius",
    Default = "250",
    Placeholder = "20-500",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().NightsHub.KillRadius = math.clamp(n, 20, 500) end
    end
})

-- Tab: Wood
local T_Wood = Window:AddTab("Wood")

T_Wood:AddToggle({
    Title = "Auto Wood (Teleport + Attack)",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoWood = state
        if state then
            statusPara:SetDesc("Auto Wood: ON")
        else
            statusPara:SetDesc("Auto Wood: OFF - Returning to campfire")
        end
        task.wait(1)
        statusPara:SetDesc("Ready")
    end
})

T_Wood:AddInput({
    Title = "Wood Radius",
    Default = "50",
    Placeholder = "10-200",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().NightsHub.WoodRadius = math.clamp(n, 10, 200) end
    end
})

-- Tab: Auto Farm
local T_Auto = Window:AddTab("Auto Farm")

local autoFeedSec = T_Auto:AddCollapsibleSection("Auto Feed (HP Based - Drag to Fire)", false)
autoFeedSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoFeed = state
    end
})
autoFeedSec:AddDropdown({
    Title = "Fuel",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    DefaultValue = "Log",
    Callback = function(v)
        getgenv().NightsHub.FuelType = v
    end
})

local autoFeedAlwaysSec = T_Auto:AddCollapsibleSection("Auto Feed (Always - BurnItem Remote)", false)
autoFeedAlwaysSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoFeedAlways = state
    end
})
autoFeedAlwaysSec:AddDropdown({
    Title = "Fuel",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    DefaultValue = "Log",
    Callback = function(v)
        getgenv().NightsHub.FuelType = v
    end
})

local autoCookSec = T_Auto:AddCollapsibleSection("Auto Cook", false)
autoCookSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoCook = state
    end
})
autoCookSec:AddDropdown({
    Title = "Item",
    Values = {"Morsel", "Steak"},
    DefaultValue = "Morsel",
    Callback = function(v)
        getgenv().NightsHub.CookItem = v
    end
})

local autoGrindSec = T_Auto:AddCollapsibleSection("Auto Grind", false)
autoGrindSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoGrind = state
    end
})

local autoBioSec = T_Auto:AddCollapsibleSection("Auto Biofuel", false)
autoBioSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoBiofuel = state
    end
})

local autoEatSec = T_Auto:AddCollapsibleSection("Auto Eat (HP < 50%)", false)
autoEatSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoEatHP = state
    end
})

-- Tab: Item (dengan item dari wiki)
local T_Item = Window:AddTab("Item")

-- Teleport to Item
T_Item:AddDropdown({
    Title = "Teleport to Item",
    Values = {
        "Revolver", "Medkit", "Alien Chest", "Berry", "Bolt", "Broken Fan",
        "Carrot", "Coal", "Coin Stack", "Hologram Emitter", "Item Chest",
        "Laser Fence Blueprint", "Log", "Old Flashlight", "Old Radio",
        "Sheet Metal", "Bandage", "Rifle", "Good Sack", "Strong Axe",
        "Giant Sack", "Chainsaw", "Apple", "Pistol", "Fuel Canister",
        "Bunny Foot", "Oil Barrel", "Corn", "Pumpkin", "Cultist Gem",
        "Wolf Pelt", "Bear Pelt", "Alpha Wolf Pelt", "UFO Component",
        "UFO Scrap", "Old Car Engine", "Broken Microwave", "Tyre",
        "Washing Machine", "Cultist Experiment", "Cultist Component",
        "Gem of the Forest Fragment", "Steak", "Morsel", "Cooked Steak",
        "Cooked Morsel", "Cake", "Stew", "Meat Sandwich"
    },
    DefaultValue = "Log",
    Callback = function(itemName)
        local items = getItemsFolder()
        if not items then return end
        for _, model in ipairs(items:GetChildren()) do
            if model:IsA("Model") and model.Name == itemName then
                local part = getItemPart(model)
                if part then
                    tpPlayer(part.CFrame)
                    break
                end
            end
        end
    end
})

-- Bring Item to You (diperluas)
T_Item:AddDropdown({
    Title = "Bring Item to You",
    Values = {
        "Alien Chest", "Alpha Wolf Pelt", "Apple", "Bandage", "Bear Pelt",
        "Berry", "Biofuel", "Bolt", "Broken Fan", "Bunny Foot", "Carrot",
        "Coal", "Coin Stack", "Cooked Morsel", "Cooked Steak", "Chainsaw",
        "Cultist Gem", "Fuel Canister", "Item Chest", "Log", "MedKit",
        "Morsel", "Old Flashlight", "Old Radio", "Good Sack", "Good Axe",
        "Raygun", "Giant Sack", "Strong Axe", "Oil Barrel", "Rifle",
        "Rifle Ammo", "Revolver", "Revolver Ammo", "Sheet Metal", "Steak",
        "Wolf Pelt", "Tyre", "Washing Machine", "Broken Microwave",
        "Pistol", "Laser Fence Blueprint", "Hologram Emitter", "Corn",
        "Pumpkin", "UFO Component", "UFO Scrap", "Old Car Engine",
        "Cultist Experiment", "Cultist Component", "Gem of the Forest Fragment",
        "Cake", "Stew", "Meat Sandwich", "Candy Corn", "Candy Apple"
    },
    DefaultValue = "Log",
    Callback = function(itemName)
        local items = getItemsFolder()
        if not items or not HRP then return end
        local count = 0
        for _, item in ipairs(items:GetChildren()) do
            if item:IsA("Model") and item.Name == itemName and canMoveItem(item) then
                local part = getItemPart(item)
                if part then
                    local dist = (HRP.Position - part.Position).Magnitude
                    if dist <= 200 then
                        local pos = HRP.Position + Vector3.new(0, count * 2, 0)
                        bringItem(item, pos)
                        count = count + 1
                        task.wait(0.05)
                    end
                end
            end
        end
        statusPara:SetDesc("Brought " .. count .. " " .. itemName)
        task.wait(2)
        statusPara:SetDesc("Ready")
    end
})

T_Item:AddToggle({
    Title = "Item ESP",
    Default = false,
    Callback = function(state)
        local items = getItemsFolder()
        if state then
            addESP(items, "items", Color3.fromRGB(80,255,80))
        else
            clearESP("items")
            if ESPconns["items"] then ESPconns["items"]:Disconnect() end
        end
    end
})

-- Tab: Visuals
local T_Vis = Window:AddTab("Visuals")

T_Vis:AddToggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(state)
        local chars = Workspace:FindFirstChild("Characters")
        if state then
            addESP(chars, "chars", Color3.fromRGB(255,60,60))
        else
            clearESP("chars")
            if ESPconns["chars"] then ESPconns["chars"]:Disconnect() end
        end
    end
})

T_Vis:AddToggle({
    Title = "Chams",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.Chams = state
        local chars = Workspace:FindFirstChild("Characters")
        if state then
            addESP(chars, "chams", Color3.fromRGB(0,255,255))
        else
            clearESP("chams")
            if ESPconns["chams"] then ESPconns["chams"]:Disconnect() end
        end
    end
})

T_Vis:AddToggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.Fullbright = state
        if state then
            Lighting.Brightness = 5
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(127,127,127)
            Lighting.GlobalShadows = true
        end
    end
})

-- Tab: Misc
local T_Misc = Window:AddTab("Misc")

T_Misc:AddToggle({
    Title = "Show Safe Zone",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.ShowSafeZone = state
        for _, bp in ipairs(safezoneBaseplates) do
            bp.Transparency = state and 0.8 or 1
            bp.CanCollide = state
        end
    end
})

T_Misc:AddButton({
    Title = "Anti AFK",
    Callback = function()
        local bb = game:service'VirtualUser'
        game:service'Players'.LocalPlayer.Idled:connect(function()
            bb:CaptureController()
            bb:ClickButton2(Vector2.new())
        end)
        statusPara:SetDesc("Anti-AFK Active")
        task.wait(2)
        statusPara:SetDesc("Ready")
    end
})

T_Misc:AddButton({
    Title = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

T_Misc:AddButton({
    Title = "Turtle Spy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))()
    end
})

-- ============================================================
-- 8. BUBBLE TOGGLE (TIDAK IKUT CLOSE)
-- ============================================================
local BubbleGui = Instance.new("ScreenGui")
BubbleGui.Name = "NightsHubBubble"
BubbleGui.ResetOnSpawn = false
BubbleGui.Parent = CoreGui

local BubbleBtn = Instance.new("ImageButton")
BubbleBtn.Size = UDim2.new(0, 55, 0, 55)
BubbleBtn.Position = UDim2.new(0, 15, 0.5, -27)
BubbleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BubbleBtn.BackgroundTransparency = 0.2
BubbleBtn.Image = "rbxassetid://7733965386"
BubbleBtn.ImageColor3 = Color3.fromRGB(200, 150, 255)
BubbleBtn.ScaleType = Enum.ScaleType.Fit
BubbleBtn.Parent = BubbleGui

local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1.2, 0, 1.2, 0)
Shadow.Position = UDim2.new(-0.1, 0, -0.1, 0)
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Color3.fromRGB(0,0,0)
Shadow.ImageTransparency = 0.7
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10,10,118,118)
Shadow.BackgroundTransparency = 1
Shadow.ZIndex = -1
Shadow.Parent = BubbleBtn

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1,0)
Corner.Parent = BubbleBtn

local dragging, dragInput, dragStart, startPos
BubbleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = BubbleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

BubbleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        BubbleBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local uiVisible = true
BubbleBtn.MouseButton1Click:Connect(function()
    if dragging then return end
    uiVisible = not uiVisible
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and g.Name ~= "NightsHubBubble" then
            if g.Name:find("Orvion") or g.Name:find("orvion") or g.Name == "NightsHubUI" then
                g.Enabled = uiVisible
            end
        end
    end
    BubbleBtn.ImageColor3 = uiVisible and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(100, 100, 100)
    BubbleBtn.BackgroundColor3 = uiVisible and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(20, 20, 20)
end)

-- ============================================================
-- 9. STARTUP
-- ============================================================
task.wait(0.5)
OrvionLib:Notify("99 Nights Hub", "Loaded! Damage ID: 114", 5)
statusPara:SetDesc("Ready")
print("[99 Nights Hub] Loaded successfully!")