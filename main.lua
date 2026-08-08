-- ==========================================
-- 99 NIGHTS HUB | ORVION UI
-- FULL MERGE + FIXES FOR MOBILE
-- ==========================================

-- ==========================================
-- 1. LOAD LIBRARY ORVION
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ==========================================
-- 2. SERVICES & GLOBAL VARS
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- Remote Events (dengan fallback)
local StartDrag = RemoteEvents:FindFirstChild("RequestStartDraggingItem") or RemoteEvents:FindFirstChild("StartDragging")
local StopDrag  = RemoteEvents:FindFirstChild("StopDraggingItem") or RemoteEvents:FindFirstChild("StopDragging")
local EquipItem = RemoteEvents:FindFirstChild("EquipItemHandle") or RemoteEvents:FindFirstChild("EquipTool")
local UnequipItem = RemoteEvents:FindFirstChild("UnequipItemHandle") or RemoteEvents:FindFirstChild("UnequipTool")
local ToolDamage = RemoteEvents:FindFirstChild("ToolDamageObject") or RemoteEvents:FindFirstChild("DamageObject")
local ConsumeItem = RemoteEvents:FindFirstChild("RequestConsumeItem") or RemoteEvents:FindFirstChild("ConsumeItem")
local BurnItem = RemoteEvents:FindFirstChild("RequestBurnItem") or RemoteEvents:FindFirstChild("BurnItem")

-- Damage IDs (dikonfirmasi dari spy: Old Axe = "21_9883131443")
local toolsDamageIDs = {
    ["Old Axe"]     = "21_9883131443",
    ["Good Axe"]    = "112_8982038982",
    ["Strong Axe"]  = "116_8982038982",
    ["Chainsaw"]    = "647_8992824875",
    ["Spear"]       = "196_8999010016",
}

-- State
getgenv().NightsHub = {
    SelectedTool = "Old Axe",
    KillAura = false,
    KillRadius = 200,
    AutoFeed = false,
    AutoFeedAlways = false,
    FuelType = "Log",
    AutoCook = false,
    CookItem = "Morsel",
    AutoGrind = false,
    AutoBiofuel = false,
    AutoEatHP = false,
    AutoTrees = false,
    ShowSafeZone = false,
    ESP = false,
    Chams = false,
    FOVCircle = false,
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

-- Attack
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

-- Item Part Finder
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

-- Bring item (drag + drop)
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

-- Move item ke posisi (untuk auto farm)
local function moveItemToPos(item, position)
    bringItem(item, position)
end

-- Tree scanner (diperluas)
local function getTreePart(tree)
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChildWhichIsA("BasePart")
end

local function getTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                if (name:find("Tree") or name:find("Brightwood") or name:find("Fairy")) and getTreePart(obj) then
                    table.insert(trees, obj)
                end
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, f in ipairs({"Foliage","Landmarks","Trees","Environment","Resources"}) do
            scan(map:FindFirstChild(f))
        end
        scan(map)
    end
    -- fallback: scan seluruh workspace
    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Tree") and getTreePart(obj) then
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

-- Items folder & campfire pos
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

-- Teleport player dengan CFrame
local function tpPlayer(cf)
    if HRP then
        HRP.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

-- Save/Load position
local SAVED_POS = nil

-- ==========================================
-- 5. SAFE ZONE (9 baseplate)
-- ==========================================
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

-- ==========================================
-- 6. ESP SYSTEM (Highlight + Billboard)
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

-- ==========================================
-- 7. ENGINE LOOPS
-- ==========================================

-- Kill Aura Loop
task.spawn(function()
    while task.wait(0.25) do
        if getgenv().NightsHub.KillAura then
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().NightsHub.SelectedTool)
                if not tool then return end
                local dmgID = toolsDamageIDs[getgenv().NightsHub.SelectedTool] or "21_9883131443"
                local r = getgenv().NightsHub.KillRadius
                for _, mob in ipairs(getMobs()) do
                    local h = mob:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
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

-- Auto Feed (Always)
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().NightsHub.AutoFeedAlways and BurnItem then
            pcall(function()
                local inv = LP:FindFirstChild("Inventory") or LP:FindFirstChild("Backpack")
                if not inv then return end
                local fuel = getgenv().NightsHub.FuelType
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name == fuel then
                        BurnItem:FireServer(item)
                        task.wait(0.3)
                        break
                    end
                end
            end)
        end
    end
end)

-- Auto Feed (HP Based) - drag item ke api
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().NightsHub.AutoFeed then
            pcall(function()
                if not HRP then return end
                local items = getItemsFolder()
                if not items then return end
                local fuel = getgenv().NightsHub.FuelType
                local cfPos = getCampfirePos() + Vector3.new(0, 1, 0)
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and item.Name == fuel then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 100 then
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
                local cfPos = getCampfirePos() + Vector3.new(0, 1, 0)
                for _, item in ipairs(items:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(cookItem) then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 100 then
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
                    if item:IsA("Model") then
                        for _, name in ipairs(grindItems) do
                            if item.Name == name then
                                local p = getItemPart(item)
                                if p and (HRP.Position - p.Position).Magnitude <= 100 then
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
                        if item:IsA("Model") then
                            for _, name in ipairs(bioItems) do
                                if item.Name == name then
                                    local p = getItemPart(item)
                                    if p and (HRP.Position - p.Position).Magnitude <= 100 then
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

-- Auto Eat (HP Based)
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

-- Auto Bring Small Trees
local originalTreeCFrames = {}
local treesBrought = false

local function getAllSmallTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Small Tree" then
                table.insert(trees, obj)
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        if map:FindFirstChild("Foliage") then scan(map.Foliage) end
        if map:FindFirstChild("Landmarks") then scan(map.Landmarks) end
    end
    return trees
end

local function findTrunk(tree)
    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Trunk" then return part end
    end
    return nil
end

local function bringAllTrees()
    if not HRP then return end
    local target = HRP.CFrame + HRP.CFrame.LookVector * 10
    for _, tree in ipairs(getAllSmallTrees()) do
        local trunk = findTrunk(tree)
        if trunk then
            if not originalTreeCFrames[tree] then originalTreeCFrames[tree] = trunk.CFrame end
            tree.PrimaryPart = trunk
            trunk.Anchored = false
            trunk.CanCollide = false
            task.wait()
            tree:SetPrimaryPartCFrame(target + Vector3.new(math.random(-5,5), 0, math.random(-5,5)))
            trunk.Anchored = true
        end
    end
    treesBrought = true
end

local function restoreTrees()
    for tree, cframe in pairs(originalTreeCFrames) do
        local trunk = findTrunk(tree)
        if trunk then
            tree.PrimaryPart = trunk
            tree:SetPrimaryPartCFrame(cframe)
            trunk.Anchored = true
            trunk.CanCollide = true
        end
    end
    originalTreeCFrames = {}
    treesBrought = false
end

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().NightsHub.AutoTrees then
            if not treesBrought then bringAllTrees() end
        else
            if treesBrought then restoreTrees() end
        end
    end
end)

-- ==========================================
-- 8. UI ORVION
-- ==========================================
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
        local pos = getCampfirePos()
        if pos then tpPlayer(CFrame.new(pos)) end
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
        if setclipboard and HRP then setclipboard(tostring(HRP.Position)) end
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
    Title = "Radius",
    Default = "200",
    Placeholder = "20-500",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().NightsHub.KillRadius = math.clamp(n, 20, 500) end
    end
})

-- Tab: Auto
local T_Auto = Window:AddTab("Auto")

local autoFeedSec = T_Auto:AddCollapsibleSection("Auto Feed (HP Based)", false)
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

local autoFeedAlwaysSec = T_Auto:AddCollapsibleSection("Auto Feed (Always from Inventory)", false)
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

local autoTreeSec = T_Auto:AddCollapsibleSection("Auto Bring Small Trees", false)
autoTreeSec:AddToggle({
    Title = "Enable",
    Default = false,
    Callback = function(state)
        getgenv().NightsHub.AutoTrees = state
    end
})

-- Tab: Item
local T_Item = Window:AddTab("Item")

-- Teleport to Item
local tpItemDropdown = T_Item:AddDropdown({
    Title = "Teleport to Item",
    Values = {
        "Revolver", "Medkit", "Alien Chest", "Berry", "Bolt", "Broken Fan",
        "Carrot", "Coal", "Coin Stack", "Hologram Emitter", "Item Chest",
        "Laser Fence Blueprint", "Log", "Old Flashlight", "Old Radio",
        "Sheet Metal", "Bandage", "Rifle"
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

-- Bring Item to You
local bringItemDropdown = T_Item:AddDropdown({
    Title = "Bring Item to You",
    Values = {
        "Alien Chest", "Alpha Wolf Pelt", "Apple", "Bandage", "Bear Pelt",
        "Berry", "Biofuel", "Bolt", "Broken Fan", "Bunny Foot", "Carrot",
        "Coal", "Coin Stack", "Cooked Morsel", "Cooked Steak", "Chainsaw",
        "Cultist Gem", "Fuel Canister", "Item Chest", "Log", "MedKit",
        "Morsel", "Old Flashlight", "Old Radio", "Good Sack", "Good Axe",
        "Raygun", "Giant Sack", "Strong Axe", "Oil Barrel", "Rifle",
        "Rifle Ammo", "Revolver", "Revolver Ammo", "Sheet Metal", "Steak",
        "Wolf Pelt", "Tyre", "Washing Machine", "Broken Microwave"
    },
    DefaultValue = "Log",
    Callback = function(itemName)
        local items = getItemsFolder()
        if not items or not HRP then return end
        local count = 0
        for _, item in ipairs(items:GetChildren()) do
            if item:IsA("Model") and item.Name == itemName then
                local pos = HRP.Position + Vector3.new(0, count * 2, 0)
                bringItem(item, pos)
                count = count + 1
                task.wait(0.05)
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
        -- Chams menggunakan Highlight, sudah termasuk di ESP
        -- Tapi kita tambahkan toggle terpisah
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
    Title = "Emote GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dimension-sources/random-scripts-i-found/refs/heads/main/r6%20animations"))()
    end
})

T_Misc:AddButton({
    Title = "Turtle Spy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))()
    end
})

-- ==========================================
-- 9. STARTUP NOTIFICATION
-- ==========================================
task.wait(0.5)
OrvionLib:Notify("99 Nights Hub", "Loaded! All features ready.", 5)
statusPara:SetDesc("Ready")
print("[99 Nights Hub] Loaded successfully!")