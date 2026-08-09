-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE REBUILD - ALL FEATURES MERGED
-- WITH ORVION UI & GRID BRING ITEM
-- ==========================================

-- ==========================================
-- LOAD LIBRARY ORVION
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

-- ==========================================
-- SERVICES
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local RUN = game:GetService("RunService")
local LIGHTING = game:GetService("Lighting")
local TW = game:GetService("TweenService")

local LP = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ==========================================
-- REMOTES (DARI SOURCE VALID)
-- ==========================================
local Remotes = {
    ToolDamage = RemoteEvents:WaitForChild("ToolDamageObject"),
    EquipItem = RemoteEvents:WaitForChild("EquipItemHandle"),
    UnequipItem = RemoteEvents:WaitForChild("UnequipItemHandle"),
    StartDrag = RemoteEvents:WaitForChild("RequestStartDraggingItem"),
    StopDrag = RemoteEvents:WaitForChild("StopDraggingItem"),
    BurnItem = RemoteEvents:FindFirstChild("RequestBurnItem"),
    ConsumeItem = RemoteEvents:WaitForChild("RequestConsumeItem"),
}

-- ==========================================
-- DAMAGE IDs (VALID DARI SOURCE)
-- ==========================================
local DamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016",
}

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    SelectedTool = "Old Axe",
    ChopAura = false, ChopRadius = 30,
    KillAura = false, KillRadius = 30,
    AutoWood = false, WoodRadius = 30, TreeType = "All Trees",
    AutoHunt = false, HuntRadius = 30, TargetMob = "Wolf",
    AutoClaim = false,
    AutoBringSelected = false, SelectedItem = "All",
    AutoFeed = false, FeedMaterial = "Log",
    AutoCook = false, CookMaterial = "Morsel",
    AutoLootChest = false,
    AutoEat = false,
    AutoGrind = false,
    AutoBiofuel = false,
    TreeBring = false,
    Noclip = false,
    InfiniteJump = false,
    Fullbright = false,
    WalkSpeed = 16,
}

-- ==========================================
-- CHARACTER
-- ==========================================
local HRP, HUM
local function refreshChar()
    local c = LP.Character
    if c then
        HRP = c:WaitForChild("HumanoidRootPart", 3)
        HUM = c:WaitForChild("Humanoid", 3)
    end
end
refreshChar()
LP.CharacterAdded:Connect(function(c)
    refreshChar()
end)

-- ==========================================
-- TOOL SYSTEM (DARI SOURCE WORK)
-- ==========================================
local function getTool(toolName)
    local inv = LP:FindFirstChild("Inventory")
    if inv then
        local t = inv:FindFirstChild(toolName)
        if t then return t end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        local t = bp:FindFirstChild(toolName)
        if t then return t end
    end
    return nil
end

local function getEquippedTool(toolName)
    local c = LP.Character
    if not c then return nil end
    return c:FindFirstChild(toolName)
end

local function equipTool(toolName)
    local tool = getEquippedTool(toolName)
    if tool then return tool end
    tool = getTool(toolName)
    if not tool then return nil end
    Remotes.EquipItem:FireServer("FireAllClients", tool)
    task.wait(0.2)
    return getEquippedTool(toolName)
end

local function unequipTool(toolName)
    local tool = getEquippedTool(toolName)
    if tool then
        Remotes.UnequipItem:FireServer("FireAllClients", tool)
    end
end

-- ==========================================
-- ATTACK (DARI SOURCE WORK)
-- ==========================================
local function attack(target, tool, damageID)
    if not target or not tool then return end
    if not target:IsDescendantOf(Workspace) then return end
    local part = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
        or target:FindFirstChild("Trunk") or target:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    pcall(function() tool:Activate() end)
    pcall(function()
        Remotes.ToolDamage:InvokeServer(target, tool, damageID, CFrame.new(part.Position), false)
    end)
end

-- ==========================================
-- ITEM UTILITIES (DENGAN GRID LAYOUT & SKIP CHEST)
-- ==========================================
local ItemsFolder = Workspace:WaitForChild("Items")

local function getItemPart(item)
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

local function canMoveItem(item)
    if not item or not item:IsDescendantOf(Workspace) then return false end
    if item.Name:lower():find("chest") then return false end
    return true
end

-- BRING MULTIPLE ITEMS WITH GRID LAYOUT (5 KOLOM)
local function bringItemsGrid(items, position)
    if not items or #items == 0 then return end
    local itemList = {}
    for _, item in ipairs(items) do
        if canMoveItem(item) then
            local part = getItemPart(item)
            if part then
                table.insert(itemList, {item = item, part = part})
            end
        end
    end
    if #itemList == 0 then return end

    -- Sort by name for nicer arrangement
    table.sort(itemList, function(a,b) return a.item.Name < b.item.Name end)

    local cols = 5
    local spacing = 3.5
    local startX = -(cols - 1) * spacing / 2
    for i, data in ipairs(itemList) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local pos = position + Vector3.new(startX + col * spacing, row * 2.2 + 0.5, 0)
        pcall(function()
            Remotes.StartDrag:FireServer(data.item)
            task.wait(0.05)
            if data.item:IsA("Model") and data.item.PrimaryPart then
                data.item:SetPrimaryPartCFrame(CFrame.new(pos))
            else
                data.part.CFrame = CFrame.new(pos)
            end
            task.wait(0.05)
            Remotes.StopDrag:FireServer(data.item)
        end)
        task.wait(0.03)
    end
end

-- SINGLE BRING (FALLBACK)
local function moveItemToPos(item, position)
    if not canMoveItem(item) then return end
    local part = getItemPart(item)
    if not part then return end
    pcall(function()
        Remotes.StartDrag:FireServer(item)
        task.wait(0.05)
        if item:IsA("Model") and item.PrimaryPart then
            item:SetPrimaryPartCFrame(CFrame.new(position))
        else
            part.CFrame = CFrame.new(position)
        end
        task.wait(0.05)
        Remotes.StopDrag:FireServer(item)
    end)
end

-- ==========================================
-- TREE SYSTEM
-- ==========================================
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
                if tType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") then match = true end
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
        for _, f in ipairs({"Foliage","Landmarks","Trees","Environment","Resources"}) do
            scan(map:FindFirstChild(f))
        end
        scan(map)
    end
    return trees
end

-- ==========================================
-- MOB SCANNER
-- ==========================================
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

-- ==========================================
-- LOOT CHECK
-- ==========================================
local lootKeywords = {"meat","pelt","log","bolt","sheet metal","coal","berry","carrot","morsel","steak","bunny foot","medkit","bandage"}
local function isLoot(name)
    name = name:lower()
    for _, k in ipairs(lootKeywords) do if name:find(k) then return true end end
    return false
end

-- ==========================================
-- CAMPFIRE & POSITIONS
-- ==========================================
local campfireDropPos = Vector3.new(0, 19, 0)
local machineDropPos = Vector3.new(21, 16, -5)

local function getCampfirePos()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local cg = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if cg then
            local f = cg:FindFirstChild("MainFire") or cg:FindFirstChild("Campfire")
            if f then
                local p = f:IsA("BasePart") and f or f:FindFirstChildWhichIsA("BasePart")
                if p then return p.Position end
            end
        end
    end
    return campfireDropPos
end

-- ==========================================
-- BACK SYSTEM (TETAP ADA)
-- ==========================================
local SG = Instance.new("ScreenGui", CoreGui)
SG.Name = "W424_BackUI" SG.ResetOnSpawn = false
local FRAME = Instance.new("Frame", SG)
FRAME.Size = UDim2.new(0, 160, 0, 70)
FRAME.Position = UDim2.new(1, -180, 1, -90)
FRAME.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
FRAME.BorderSizePixel = 0 FRAME.Visible = false
Instance.new("UICorner", FRAME).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", FRAME).Color = Color3.fromRGB(60, 60, 60)
local LBL = Instance.new("TextLabel", FRAME)
LBL.Size = UDim2.new(1, 0, 0.42, 0) LBL.Position = UDim2.new(0, 0, 0, 4)
LBL.BackgroundTransparency = 1 LBL.TextColor3 = Color3.fromRGB(140, 140, 140)
LBL.TextScaled = true LBL.Font = Enum.Font.Gotham LBL.Text = "W424"
local BACK = Instance.new("TextButton", FRAME)
BACK.Size = UDim2.new(1, -20, 0, 28) BACK.Position = UDim2.new(0, 10, 1, -36)
BACK.BackgroundColor3 = Color3.fromRGB(30, 30, 30) BACK.TextColor3 = Color3.fromRGB(220, 220, 220)
BACK.TextScaled = true BACK.Font = Enum.Font.GothamBold BACK.Text = "← back"
BACK.AutoButtonColor = false
Instance.new("UICorner", BACK).CornerRadius = UDim.new(0, 8)

local TP_CONN, LAST_POS, SAVED_POS
local function tpTo(cf)
    if not HRP then return end
    LAST_POS = HRP.CFrame
    if TP_CONN then TP_CONN:Disconnect() end
    HRP.Anchored = true HRP.CFrame = cf
    local e = 0
    TP_CONN = RUN.Heartbeat:Connect(function(dt)
        e = e + dt
        if not HRP then TP_CONN:Disconnect() return end
        if e < 2 then HRP.CFrame = cf else HRP.Anchored = false TP_CONN:Disconnect() end
    end)
    FRAME.Visible = true
end
BACK.MouseButton1Click:Connect(function()
    if TP_CONN then TP_CONN:Disconnect() end
    if HRP then HRP.Anchored = false end
    if LAST_POS and HRP then HRP.CFrame = LAST_POS end
    FRAME.Visible = false
end)

-- ==========================================
-- ENGINE LOOPS
-- ==========================================

-- Chop + Auto Wood
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.ChopAura or getgenv().W424.AutoWood then
            pcall(function()
                if not HRP then return end
                local toolName = getgenv().W424.SelectedTool
                local tool = equipTool(toolName)
                if not tool then return end
                local dmgID = DamageIDs[toolName] or "1_8982038982"
                local r = getgenv().W424.ChopAura and getgenv().W424.ChopRadius or getgenv().W424.WoodRadius
                for _, tree in ipairs(getTrees()) do
                    if not (getgenv().W424.ChopAura or getgenv().W424.AutoWood) then break end
                    local p = getTreePart(tree)
                    if p and (HRP.Position - p.Position).Magnitude <= r then
                        attack(tree, tool, dmgID)
                        task.wait(0.12)
                    end
                end
            end)
        end
    end
end)

-- Kill + Auto Hunt
task.spawn(function()
    while task.wait(0.35) do
        if getgenv().W424.KillAura or getgenv().W424.AutoHunt then
            pcall(function()
                if not HRP then return end
                local toolName = getgenv().W424.SelectedTool
                local tool = equipTool(toolName)
                if not tool then return end
                local dmgID = DamageIDs[toolName] or "1_8982038982"
                local r = getgenv().W424.KillAura and getgenv().W424.KillRadius or getgenv().W424.HuntRadius
                for _, mob in ipairs(getMobs()) do
                    if not (getgenv().W424.KillAura or getgenv().W424.AutoHunt) then break end
                    local h = mob:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then
                        if getgenv().W424.AutoHunt and not mob.Name:find(getgenv().W424.TargetMob) then continue end
                        local p = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
                        if p and (HRP.Position - p.Position).Magnitude <= r then
                            attack(mob, tool, dmgID)
                            task.wait(0.12)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Claim
local claimed = {}
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                if not HRP then return end
                for item, _ in pairs(claimed) do
                    if not item or not item:IsDescendantOf(Workspace) then claimed[item] = nil end
                end
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item:IsA("Model") and canMoveItem(item) and isLoot(item.Name) then
                        if not claimed[item] then
                            local p = getItemPart(item)
                            if p and (HRP.Position - p.Position).Magnitude <= 50 then
                                claimed[item] = true
                                moveItemToPos(item, HRP.Position + Vector3.new(0, 2, 0))
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Bring Selected (dengan grid layout)
task.spawn(function()
    while task.wait(1.5) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                if not HRP then return end
                local target = getgenv().W424.SelectedItem
                local found = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item:IsA("Model") and canMoveItem(item) then
                        if target == "All" or item.Name == target then
                            local p = getItemPart(item)
                            if p and (HRP.Position - p.Position).Magnitude <= 80 then
                                table.insert(found, item)
                            end
                        end
                    end
                end
                if #found > 0 then
                    bringItemsGrid(found, HRP.Position)
                end
            end)
        end
    end
end)

-- Auto Loot Chest
task.spawn(function()
    while task.wait(0.8) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                if not HRP then return end
                for _, chest in ipairs(ItemsFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:lower():find("chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    if fireproximityprompt then fireproximityprompt(obj) end
                                    task.wait(0.3)
                                    local loots = {}
                                    for _, loot in ipairs(ItemsFolder:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") and canMoveItem(loot) then
                                            local p = getItemPart(loot)
                                            if p and (HRP.Position - p.Position).Magnitude <= 40 then
                                                table.insert(loots, loot)
                                            end
                                        end
                                    end
                                    if #loots > 0 then
                                        bringItemsGrid(loots, HRP.Position + Vector3.new(0, 2, 0))
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

-- Auto Feed
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                local inv = LP:FindFirstChild("Inventory") or LP:FindFirstChild("Backpack")
                if not inv or not Remotes.BurnItem then return end
                local mat = getgenv().W424.FeedMaterial:lower()
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name:lower():find(mat) then
                        Remotes.BurnItem:FireServer(item)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
end)

-- Auto Cook
task.spawn(function()
    while task.wait(2) do
        if getgenv().W424.AutoCook then
            pcall(function()
                if not HRP then return end
                local mat = getgenv().W424.CookMaterial:lower()
                local cfPos = getCampfirePos()
                local found = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item:IsA("Model") and canMoveItem(item) and item.Name:lower():find(mat) then
                        local p = getItemPart(item)
                        if p and (HRP.Position - p.Position).Magnitude <= 60 then
                            table.insert(found, item)
                        end
                    end
                end
                if #found > 0 then
                    bringItemsGrid(found, cfPos + Vector3.new(0, 1, 0))
                end
            end)
        end
    end
end)

-- Auto Eat
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
task.spawn(function()
    while task.wait(3) do
        if getgenv().W424.AutoEat then
            pcall(function()
                local available = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if table.find(autoEatFoods, item.Name) then
                        table.insert(available, item)
                    end
                end
                if #available > 0 then
                    local food = available[math.random(1, #available)]
                    pcall(function() Remotes.ConsumeItem:InvokeServer(food) end)
                end
            end)
        end
    end
end)

-- Auto Grind
local grindItems = {"UFO Junk","UFO Component","Old Car Engine","Broken Fan","Old Microwave","Bolt","Log","Cultist Gem","Sheet Metal","Old Radio","Tyre","Washing Machine","Cultist Experiment","Cultist Component","Gem of the Forest Fragment","Broken Microwave"}
task.spawn(function()
    while task.wait(2.5) do
        if getgenv().W424.AutoGrind then
            pcall(function()
                local found = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item:IsA("Model") and canMoveItem(item) and table.find(grindItems, item.Name) then
                        table.insert(found, item)
                    end
                end
                if #found > 0 then
                    bringItemsGrid(found, machineDropPos)
                end
            end)
        end
    end
end)

-- Auto Biofuel
local biofuelItems = {"Carrot","Cooked Morsel","Morsel","Steak","Cooked Steak","Log"}
local biofuelProcessorPos
task.spawn(function()
    while task.wait(2) do
        if getgenv().W424.AutoBiofuel then
            pcall(function()
                if not biofuelProcessorPos then
                    local proc = Workspace:FindFirstChild("Structures") and Workspace.Structures:FindFirstChild("Biofuel Processor")
                    local part = proc and proc:FindFirstChild("Part")
                    if part then biofuelProcessorPos = part.Position + Vector3.new(0, 5, 0) end
                end
                if biofuelProcessorPos then
                    local found = {}
                    for _, item in ipairs(ItemsFolder:GetChildren()) do
                        if item:IsA("Model") and canMoveItem(item) and table.find(biofuelItems, item.Name) then
                            table.insert(found, item)
                        end
                    end
                    if #found > 0 then
                        bringItemsGrid(found, biofuelProcessorPos)
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- TREE BRING SYSTEM (DARI SOURCE)
-- ==========================================
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
end

local function bringAllTrees()
    if not HRP then return end
    local target = CFrame.new(HRP.Position + HRP.CFrame.LookVector * 10)
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

-- ==========================================
-- MOVEMENT
-- ==========================================
local NC
local function setNoclip(v)
    if v then
        NC = RUN.Stepped:Connect(function()
            local c = LP.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if NC then NC:Disconnect() end
        local c = LP.Character
        if c then
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
        LIGHTING.Brightness = 5
        LIGHTING.Ambient = Color3.fromRGB(255, 255, 255)
        LIGHTING.GlobalShadows = false
    else
        LIGHTING.Brightness = OB
        LIGHTING.Ambient = OA
        LIGHTING.GlobalShadows = OS
    end
end

-- ==========================================
-- ESP (LENGKAP)
-- ==========================================
local ESPs = {}
local ESPconns = {}
local function clearESP(tag)
    if not ESPs[tag] then return end
    for _, o in ipairs(ESPs[tag]) do pcall(function() o:Destroy() end) end
    ESPs[tag] = {}
    if ESPconns[tag] then ESPconns[tag]:Disconnect() ESPconns[tag] = nil end
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
    ESPconns[tag] = folder.ChildAdded:Connect(function(o)
        task.wait(0.1)
        makeESP(o, tag, color)
    end)
end

-- ==========================================
-- UI ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub",
    Icon = "rbxassetid://7733965386"
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Combat = Window:AddTab("Combat"),
    Wood = Window:AddTab("Wood"),
    Hunt = Window:AddTab("Hunt"),
    Farm = Window:AddTab("Farm"),
    Items = Window:AddTab("Items"),
    Settings = Window:AddTab("Settings"),
    Misc = Window:AddTab("Misc"),
}

local statusPara = Tabs.Main:AddParagraph({Title = "Status", Content = "Ready"})

-- ==========================================
-- MAIN TAB
-- ==========================================
Tabs.Main:AddButton({Title = "TP Campfire", Callback = function()
    local cf = CFrame.new(getCampfirePos())
    tpTo(cf)
end})

Tabs.Main:AddButton({Title = "TP Stronghold", Callback = function()
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Landmarks") then
        local strong = map.Landmarks:FindFirstChild("Stronghold")
        if strong and strong:FindFirstChild("Functional") and strong.Functional:FindFirstChild("EntryDoors") then
            local dr = strong.Functional.EntryDoors:FindFirstChild("DoorRight")
            if dr and dr:FindFirstChild("Model") then
                local children = dr.Model:GetChildren()
                if #children >= 5 and children[5]:IsA("BasePart") then
                    tpTo(children[5].CFrame)
                end
            end
        end
    end
end})

Tabs.Main:AddButton({Title = "Save Position", Callback = function()
    if HRP then SAVED_POS = HRP.CFrame end
    statusPara:SetDesc("Position saved")
end})

Tabs.Main:AddButton({Title = "Go Saved", Callback = function()
    if SAVED_POS then tpTo(SAVED_POS) end
end})

Tabs.Main:AddToggle({
    Title = "Tree Bring (Small Trees)",
    Default = false,
    Callback = function(state)
        getgenv().W424.TreeBring = state
        if state then bringAllTrees() else restoreTrees() end
    end
})

-- ==========================================
-- COMBAT TAB
-- ==========================================
Tabs.Combat:AddDropdown({
    Title = "Weapon",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    DefaultValue = "Old Axe",
    Callback = function(v) getgenv().W424.SelectedTool = v end
})

Tabs.Combat:AddToggle({
    Title = "Kill Aura (All Mobs)",
    Default = false,
    Callback = function(s) getgenv().W424.KillAura = s end
})
Tabs.Combat:AddInput({
    Title = "Kill Radius",
    Default = "30",
    Callback = function(v) local n=tonumber(v) if n then getgenv().W424.KillRadius = math.max(5, n) end end
})

Tabs.Combat:AddToggle({
    Title = "Auto Hunt",
    Default = false,
    Callback = function(s) getgenv().W424.AutoHunt = s end
})
Tabs.Combat:AddInput({
    Title = "Hunt Radius",
    Default = "30",
    Callback = function(v) local n=tonumber(v) if n then getgenv().W424.HuntRadius = math.max(5, n) end end
})
Tabs.Combat:AddDropdown({
    Title = "Target Mob",
    Values = {"Wolf", "Bear", "Cultist", "Alien", "Bunny"},
    DefaultValue = "Wolf",
    Callback = function(v) getgenv().W424.TargetMob = v end
})

Tabs.Combat:AddToggle({
    Title = "Chop Aura (Trees)",
    Default = false,
    Callback = function(s) getgenv().W424.ChopAura = s end
})
Tabs.Combat:AddInput({
    Title = "Chop Radius",
    Default = "30",
    Callback = function(v) local n=tonumber(v) if n then getgenv().W424.ChopRadius = math.max(5, n) end end
})

-- ==========================================
-- WOOD TAB
-- ==========================================
Tabs.Wood:AddToggle({
    Title = "Auto Wood",
    Default = false,
    Callback = function(s) getgenv().W424.AutoWood = s end
})
Tabs.Wood:AddInput({
    Title = "Wood Radius",
    Default = "30",
    Callback = function(v) local n=tonumber(v) if n then getgenv().W424.WoodRadius = math.max(5, n) end end
})
Tabs.Wood:AddDropdown({
    Title = "Tree Type",
    Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    DefaultValue = "All Trees",
    Callback = function(v) getgenv().W424.TreeType = v end
})

-- ==========================================
-- HUNT TAB
-- ==========================================
Tabs.Hunt:AddToggle({Title = "Auto Claim (Loot)", Default = false, Callback = function(s) getgenv().W424.AutoClaim = s end})
Tabs.Hunt:AddToggle({Title = "Auto Loot Chest", Default = false, Callback = function(s) getgenv().W424.AutoLootChest = s end})

-- ==========================================
-- FARM TAB
-- ==========================================
Tabs.Farm:AddToggle({Title = "Auto Feed (Burn)", Default = false, Callback = function(s) getgenv().W424.AutoFeed = s end})
Tabs.Farm:AddDropdown({
    Title = "Feed Material",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    DefaultValue = "Log",
    Callback = function(v) getgenv().W424.FeedMaterial = v end
})

Tabs.Farm:AddToggle({Title = "Auto Cook", Default = false, Callback = function(s) getgenv().W424.AutoCook = s end})
Tabs.Farm:AddDropdown({
    Title = "Cook Material",
    Values = {"Morsel", "Steak", "Bunny Meat"},
    DefaultValue = "Morsel",
    Callback = function(v) getgenv().W424.CookMaterial = v end
})

Tabs.Farm:AddToggle({Title = "Auto Grind", Default = false, Callback = function(s) getgenv().W424.AutoGrind = s end})
Tabs.Farm:AddToggle({Title = "Auto Biofuel", Default = false, Callback = function(s) getgenv().W424.AutoBiofuel = s end})
Tabs.Farm:AddToggle({Title = "Auto Eat (Hunger)", Default = false, Callback = function(s) getgenv().W424.AutoEat = s end})

-- ==========================================
-- ITEMS TAB
-- ==========================================
local allItems = {
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
}

local itemSelectionSec = Tabs.Items:AddCollapsibleSection("Select Items to Bring", true)
local itemToggles = {}

for _, itemName in ipairs(allItems) do
    local tog = itemSelectionSec:AddToggle({
        Title = itemName,
        Default = false,
        Callback = function(state)
            local selected = getgenv().W424.SelectedItems or {}
            if state then
                if not table.find(selected, itemName) then table.insert(selected, itemName) end
            else
                for i, v in ipairs(selected) do
                    if v == itemName then table.remove(selected, i) break end
                end
            end
            getgenv().W424.SelectedItems = selected
        end
    })
    itemToggles[itemName] = tog
end

Tabs.Items:AddButton({
    Title = "Bring Selected Now (Grid, Skip Chest)",
    Callback = function()
        local selected = getgenv().W424.SelectedItems or {}
        if #selected == 0 then statusPara:SetDesc("No items selected") return end
        local found = {}
        for _, itemName in ipairs(selected) do
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item:IsA("Model") and item.Name == itemName and canMoveItem(item) then
                    local p = getItemPart(item)
                    if p and (HRP.Position - p.Position).Magnitude <= 80 then
                        table.insert(found, item)
                    end
                end
            end
        end
        if #found > 0 then
            bringItemsGrid(found, HRP.Position)
            statusPara:SetDesc("Brought " .. #found .. " items")
        else
            statusPara:SetDesc("No items found")
        end
    end
})

Tabs.Items:AddToggle({
    Title = "Auto Bring Selected (Grid, Every 1.5s)",
    Default = false,
    Callback = function(s) getgenv().W424.AutoBringSelected = s end
})

Tabs.Items:AddInput({
    Title = "Bring Radius",
    Default = "80",
    Callback = function(v) local n=tonumber(v) if n then getgenv().W424.BringRadius = math.max(10, n) end end
})

Tabs.Items:AddButtonGrid(
    { Title = "Select All", Callback = function()
        for name, tog in pairs(itemToggles) do
            tog:SetValue(true)
            local s = getgenv().W424.SelectedItems or {}
            if not table.find(s, name) then table.insert(s, name) end
            getgenv().W424.SelectedItems = s
        end
    end},
    { Title = "Deselect All", Callback = function()
        for _, tog in pairs(itemToggles) do tog:SetValue(false) end
        getgenv().W424.SelectedItems = {}
    end}
)

Tabs.Items:AddToggle({
    Title = "Item ESP",
    Default = false,
    Callback = function(s)
        if s then addESP(ItemsFolder, "items", Color3.fromRGB(80,255,80))
        else clearESP("items") end
    end
})

-- ==========================================
-- SETTINGS TAB
-- ==========================================
Tabs.Settings:AddToggle({
    Title = "Noclip",
    Default = false,
    Callback = function(s) getgenv().W424.Noclip = s setNoclip(s) end
})
Tabs.Settings:AddToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(s) getgenv().W424.InfiniteJump = s end
})
Tabs.Settings:AddToggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(s) getgenv().W424.Fullbright = s setBright(s) end
})
Tabs.Settings:AddSlider({
    Title = "Walk Speed",
    Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        getgenv().W424.WalkSpeed = v
        if HUM then HUM.WalkSpeed = v end
    end
})
Tabs.Settings:AddToggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(s)
        local chars = Workspace:FindFirstChild("Characters")
        if s then addESP(chars, "players", Color3.fromRGB(255,60,60))
        else clearESP("players") end
    end
})

-- ==========================================
-- MISC TAB
-- ==========================================
Tabs.Misc:AddButton({Title = "Anti AFK", Callback = function()
    local vu = game:service'VirtualUser'
    LP.Idled:connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
    statusPara:SetDesc("Anti-AFK active")
end})
Tabs.Misc:AddButton({Title = "Infinite Yield", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})
Tabs.Misc:AddButton({Title = "Turtle Spy", Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))()
end})

-- ==========================================
-- BUBBLE TOGGLE
-- ==========================================
local BUBBLE = Instance.new("ScreenGui", CoreGui)
BUBBLE.Name = "W424Bubble" BUBBLE.ResetOnSpawn = false
local BTN = Instance.new("ImageButton", BUBBLE)
BTN.Size = UDim2.new(0, 55, 0, 55)
BTN.Position = UDim2.new(0, 15, 0.5, -27)
BTN.BackgroundColor3 = Color3.fromRGB(30,30,40)
BTN.BackgroundTransparency = 0.2
BTN.Image = "rbxassetid://7733965386"
BTN.ImageColor3 = Color3.fromRGB(200,150,255)
BTN.ScaleType = Enum.ScaleType.Fit
local sh = Instance.new("ImageLabel", BTN)
sh.Size = UDim2.new(1.2,0,1.2,0) sh.Position = UDim2.new(-0.1,0,-0.1,0)
sh.Image = "rbxassetid://1316045217" sh.ImageColor3 = Color3.fromRGB(0,0,0)
sh.ImageTransparency = 0.7 sh.ScaleType = Enum.ScaleType.Slice
sh.SliceCenter = Rect.new(10,10,118,118) sh.BackgroundTransparency = 1 sh.ZIndex = -1
Instance.new("UICorner", BTN).CornerRadius = UDim.new(1,0)

local dragging, dragInput, dragStart, startPos
BTN.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = BTN.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
BTN.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        dragInput = i
    end
end)
UIS.InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local delta = i.Position - dragStart
        BTN.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local uiVisible = true
BTN.MouseButton1Click:Connect(function()
    if dragging then return end
    uiVisible = not uiVisible
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g:IsA("ScreenGui") and (g.Name:find("Orvion") or g.Name == "W424_BackUI") then
            g.Enabled = uiVisible
        end
    end
    BTN.ImageColor3 = uiVisible and Color3.fromRGB(200,150,255) or Color3.fromRGB(100,100,100)
    BTN.BackgroundColor3 = uiVisible and Color3.fromRGB(30,30,40) or Color3.fromRGB(20,20,20)
end)

-- ==========================================
-- STARTUP
-- ==========================================
task.wait(0.5)
OrvionLib:Notify("W424 Hub", "Loaded! All features ready.", 5)
statusPara:SetDesc("Ready")
print("[W424 Hub] Loaded successfully.")