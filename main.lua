-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE EDITION - FULL CODE (NO CUT)
-- ==========================================

local PLRS = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LIGHTING = game:GetService("Lighting")
local RUN = game:GetService("RunService")
local TW = game:GetService("TweenService")
local LP = PLRS.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- REMOTE SCANNER (AUTO-DETECT)
-- ==========================================
local function findRemote(namePattern)
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if remote.Name:find(namePattern) then
                return remote
            end
        end
    end
    return nil
end

local Remotes = {
    ToolDamage = findRemote("ToolDamage") or findRemote("Damage") or findRemote("Hit"),
    EquipItem = findRemote("Equip") or findRemote("EquipItem") or findRemote("SelectTool"),
    StartDrag = findRemote("StartDrag") or findRemote("RequestStartDragging"),
    StopDrag = findRemote("StopDrag") or findRemote("StopDragging"),
    BurnItem = findRemote("Burn") or findRemote("RequestBurn"),
    ConsumeItem = findRemote("Consume") or findRemote("RequestConsume"),
}

-- ==========================================
-- DAMAGE ID MAPPING (BISA DI-UPDATE)
-- ==========================================
local toolsDamageIDs = {
    ["Old Axe"] = "1_9883131443",
    ["Good Axe"] = "112_9883131443",
    ["Strong Axe"] = "116_9883131443",
    ["Chainsaw"] = "647_9883131443",
    ["Spear"] = "196_9883131443",
}
local function getDamageID(name)
    return toolsDamageIDs[name] or "1_9883131443"
end

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
    Noclip = false,
    InfiniteJump = false,
    Fullbright = false,
    WalkSpeed = 16,
}

-- ==========================================
-- LOAD FLUENT UI
-- ==========================================
local FLUENT = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local WIN = FLUENT:CreateWindow({
    Title = "W424 Hub",
    SubTitle = "99 Nights - Ultimate",
    Theme = "Dark",
    Acrylic = false,
    Resize = true,
    Size = UDim2.fromOffset(700, 500),
    TabWidth = 160,
    MinimizeKey = Enum.KeyCode.RightControl,
    MinSize = Vector2.new(500, 400),
})

-- ==========================================
-- VARIABLES
-- ==========================================
local CHAR = LP.Character or LP.CharacterAdded:Wait()
local HRP = CHAR:WaitForChild("HumanoidRootPart")
local HUM = CHAR:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    CHAR = c
    HRP = c:WaitForChild("HumanoidRootPart")
    HUM = c:WaitForChild("Humanoid")
end)

local function getItemsFolder()
    return Workspace:FindFirstChild("Items")
end

local SELECTED_ITEM = ""
local SAVED_POS = nil
local LAST_POS = nil

-- ==========================================
-- BACK SYSTEM (LENGKAP)
-- ==========================================
local SG = Instance.new("ScreenGui")
SG.Name = "W424_BackUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CoreGui

local FRAME = Instance.new("Frame")
FRAME.Size = UDim2.new(0, 160, 0, 70)
FRAME.Position = UDim2.new(1, -180, 1, -90)
FRAME.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
FRAME.BackgroundTransparency = 0.05
FRAME.BorderSizePixel = 0
FRAME.Visible = false
FRAME.Parent = SG

Instance.new("UICorner", FRAME).CornerRadius = UDim.new(0, 12)
local STROKE = Instance.new("UIStroke", FRAME)
STROKE.Color = Color3.fromRGB(60, 60, 60)
STROKE.Thickness = 1

local LABEL = Instance.new("TextLabel", FRAME)
LABEL.Size = UDim2.new(1, 0, 0.42, 0)
LABEL.Position = UDim2.new(0, 0, 0, 4)
LABEL.BackgroundTransparency = 1
LABEL.TextColor3 = Color3.fromRGB(140, 140, 140)
LABEL.TextScaled = true
LABEL.Font = Enum.Font.Gotham
LABEL.Text = "W424"

local BACK_BTN = Instance.new("TextButton", FRAME)
BACK_BTN.Size = UDim2.new(1, -20, 0, 28)
BACK_BTN.Position = UDim2.new(0, 10, 1, -36)
BACK_BTN.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BACK_BTN.BorderSizePixel = 0
BACK_BTN.TextColor3 = Color3.fromRGB(220, 220, 220)
BACK_BTN.TextScaled = true
BACK_BTN.Font = Enum.Font.GothamBold
BACK_BTN.Text = "← back"
BACK_BTN.AutoButtonColor = false

Instance.new("UICorner", BACK_BTN).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", BACK_BTN).Color = Color3.fromRGB(55, 55, 55)

BACK_BTN.MouseEnter:Connect(function()
    TW:Create(BACK_BTN, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 50, 50) }):Play()
end)
BACK_BTN.MouseLeave:Connect(function()
    TW:Create(BACK_BTN, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }):Play()
end)

local function showBack()
    FRAME.Visible = true
    FRAME.Position = UDim2.new(1, -180, 1, -70)
    TW:Create(FRAME, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -180, 1, -90)
    }):Play()
end

local function hideBack()
    local t = TW:Create(FRAME, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(1, -180, 1, -70)
    })
    t:Play()
    t.Completed:Connect(function() FRAME.Visible = false end)
end

local TP_CONN = nil
local function tpTo(cf)
    if not HRP then return end
    LAST_POS = HRP.CFrame
    if TP_CONN then TP_CONN:Disconnect() TP_CONN = nil end
    HRP.Anchored = true
    HRP.CFrame = cf
    local elapsed = 0
    TP_CONN = RUN.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if not HRP then
            TP_CONN:Disconnect()
            TP_CONN = nil
            return
        end
        if elapsed < 2 then
            HRP.CFrame = cf
        else
            HRP.Anchored = false
            TP_CONN:Disconnect()
            TP_CONN = nil
        end
    end)
    showBack()
end

BACK_BTN.MouseButton1Click:Connect(function()
    if TP_CONN then
        TP_CONN:Disconnect()
        TP_CONN = nil
    end
    if HRP then HRP.Anchored = false end
    if LAST_POS and HRP then HRP.CFrame = LAST_POS end
    hideBack()
end)

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function getHRP()
    local char = LP.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- Equip Tool (dengan remote scanner)
local function equipTool(toolName)
    local char = LP.Character
    if not char then return nil end

    -- Sudah di tangan?
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then
            return child
        end
    end

    -- Cari di Inventory, Backpack, StarterGear
    local containers = {
        LP:FindFirstChild("Inventory"),
        LP:FindFirstChild("Backpack"),
        LP:FindFirstChild("StarterGear")
    }
    local tool = nil
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    tool = item
                    break
                end
            end
        end
        if tool then break end
    end
    if not tool then return nil end

    -- Equip via remote (multi metode)
    if Remotes.EquipItem then
        pcall(function() Remotes.EquipItem:FireServer("FireAllClients", tool) end)
        task.wait(0.15)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
        pcall(function() Remotes.EquipItem:FireServer(tool) end)
        task.wait(0.15)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
        pcall(function() Remotes.EquipItem:FireServer(toolName) end)
        task.wait(0.15)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end

    -- Humanoid:EquipTool
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end

    -- Last resort
    pcall(function() tool.Parent = char end)
    task.wait(0.2)
    return char:FindFirstChild(toolName)
end

-- ==========================================
-- ATTACK TARGET (VALIDASI HASIL InvokeServer)
-- ==========================================
local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    local mainPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
        or target:FindFirstChild("Trunk") or target:FindFirstChild("MainPart")
        or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end

    -- Serangan fisik (opsional)
    pcall(function() tool:Activate() end)
    task.wait(0.05)
    local swing = tool:FindFirstChild("Swing")
    if swing then pcall(function() swing:FireServer() end) end

    if not Remotes.ToolDamage then return false end

    local success = false
    local variants = {
        {target, tool, damageID},
        {target, tool, damageID, CFrame.new(mainPart.Position)},
        {target, tool, damageID, CFrame.new(mainPart.Position), false},
        {target, tool, damageID, CFrame.new(mainPart.Position), true},
        {target, damageID},
    }

    for _, args in ipairs(variants) do
        local ok, result = pcall(function()
            return Remotes.ToolDamage:InvokeServer(unpack(args))
        end)
        if ok and result then
            success = true
            break
        end
    end

    if not success then
        local hitRemote = findRemote("Hit") or findRemote("DealDamage")
        if hitRemote then
            local ok = pcall(function() hitRemote:FireServer(target, tool) end)
            if ok then success = true end
        end
    end

    if not success then
        pcall(function()
            local clickDetector = tool:FindFirstChildWhichIsA("ClickDetector")
            if clickDetector then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                success = true
            end
        end)
    end

    return success
end

-- ==========================================
-- DRAG ITEM (LEBIH ROBUST)
-- ==========================================
local function dragItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        if Remotes.StartDrag then Remotes.StartDrag:FireServer(item) end
        task.wait(0.05)
        local part = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if part and part:IsDescendantOf(Workspace) then
            part.CFrame = CFrame.new(position)
            part.Velocity = Vector3.new(0, 0, 0)
        end
        if Remotes.StopDrag then Remotes.StopDrag:FireServer(item) end
    end)
end

-- ==========================================
-- TREE FUNCTIONS
-- ==========================================
local function getTreePart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChild("Head")
        or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
end

local function getFilteredTrees()
    local trees = {}
    local treeType = getgenv().W424.TreeType
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                local match = false
                if treeType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then match = true end
                elseif treeType == "Small Trees" and name == "Small Tree" then match = true
                elseif treeType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then match = true
                elseif treeType == "Brightwood Trees" and name:find("Brightwood") then match = true
                elseif treeType == "Fairy Trees" and (name:find("Fairy") or name:find("Suci")) then match = true
                end
                if match and getTreePart(obj) then table.insert(trees, obj) end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if map then
        local folders = {"Foliage", "Landmarks", "Trees", "Environment", "Resources"}
        for _, fname in ipairs(folders) do
            local f = map:FindFirstChild(fname)
            if f then scan(f) end
        end
        scan(map)
    end
    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood") or obj.Name:find("Fairy")) then
                if getTreePart(obj) then table.insert(trees, obj) end
            end
        end
    end
    return trees
end

-- ==========================================
-- CAMPFIRE POSITION
-- ==========================================
local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local campground = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if campground then
            local mainFire = campground:FindFirstChild("MainFire") or campground:FindFirstChild("Campfire") or campground.PrimaryPart
            if mainFire then
                local part = mainFire:IsA("BasePart") and mainFire or mainFire:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position end
            end
        end
    end
    local campfire = Workspace:FindFirstChild("Campfire") or Workspace:FindFirstChild("Fireplace")
    if campfire then
        local part = campfire.PrimaryPart or campfire:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position end
    end
    return Vector3.new(0, 19, 0)
end

-- ==========================================
-- FIND MOBS (SCAN SELURUH WORKSPACE)
-- ==========================================
local function getMobs()
    local mobs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LP.Character then
            table.insert(mobs, obj)
        end
    end
    return mobs
end

-- ==========================================
-- FILTER ITEM UNTUK AUTO CLAIM (HANYA LOOT)
-- ==========================================
local lootKeywords = {"Meat", "Pelt", "Log", "Bolt", "Sheet Metal", "Coal", "Berry", "Carrot", "Morsel", "Steak", "Bunny Foot", "MedKit", "Bandage"}
local function isLootItem(item)
    if not item or not item.Name then return false end
    for _, keyword in ipairs(lootKeywords) do
        if item.Name:find(keyword) then
            return true
        end
    end
    return false
end

-- ==========================================
-- ENGINE LOOPS (GABUNGAN & EFISIEN)
-- ==========================================

-- 1. Chop Aura + Auto Wood (Gabungan)
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura or getgenv().W424.AutoWood then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.ChopAura and getgenv().W424.ChopRadius or getgenv().W424.WoodRadius
                local trees = getFilteredTrees()
                for _, tree in ipairs(trees) do
                    if not (getgenv().W424.ChopAura or getgenv().W424.AutoWood) then break end
                    local part = getTreePart(tree)
                    if part and (hrp.Position - part.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.05)
                    end
                end
            end)
        end
    end
end)

-- 2. Kill Aura + Auto Hunt (Gabungan & Scan Workspace)
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.KillAura or getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.KillAura and getgenv().W424.KillRadius or getgenv().W424.HuntRadius
                local mobs = getMobs()
                for _, mob in ipairs(mobs) do
                    if not (getgenv().W424.KillAura or getgenv().W424.AutoHunt) then break end
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        if getgenv().W424.AutoHunt and not mob.Name:find(getgenv().W424.TargetMob) then
                            -- skip (tanpa continue)
                        else
                            local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                            if part and (hrp.Position - part.Position).Magnitude <= radius then
                                attackTarget(mob, tool, damageID)
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Claim Drops (Filter Loot Only)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) and not item.Name:find("Chest") and isLootItem(item) then
                        dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Bring Selected Item
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                local targetItem = getgenv().W424.SelectedItem
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) and not item.Name:find("Chest") then
                        if targetItem == "All" or item.Name == targetItem then
                            dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Feed Campfire
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                if not Remotes.BurnItem then return end
                local inv = LP:FindFirstChild("Inventory")
                if not inv then return end
                local feedMat = getgenv().W424.FeedMaterial
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name:lower():find(feedMat:lower()) then
                        Remotes.BurnItem:FireServer(item)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Cook
task.spawn(function()
    while task.wait(2) do
        if getgenv().W424.AutoCook then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                local cookMat = getgenv().W424.CookMaterial
                local campfirePos = getCampfirePosition()
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(cookMat:lower()) then
                        dragItemToPos(item, campfirePos + Vector3.new(0, 1, 0))
                    end
                end
            end)
        end
    end
end)

-- 7. Auto Loot Chest
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                for _, chest in ipairs(itemsFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    if fireproximityprompt then
                                        fireproximityprompt(obj)
                                    end
                                    task.wait(0.2)
                                    for _, loot in ipairs(itemsFolder:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") and loot:IsDescendantOf(Workspace) then
                                            dragItemToPos(loot, hrp.Position + Vector3.new(0, 2, 0))
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
-- ESP DINAMIS (DENGAN LISTENER)
-- ==========================================
local ESP_OBJS = {}

local function clearESP(tag)
    if not ESP_OBJS[tag] then
        ESP_OBJS[tag] = {}
        return
    end
    for _, o in ipairs(ESP_OBJS[tag]) do
        pcall(function() o:Destroy() end)
    end
    ESP_OBJS[tag] = {}
end

local function createESP(obj, tag, color)
    if not obj or not obj:IsA("Model") then return end
    if not ESP_OBJS[tag] then
        ESP_OBJS[tag] = {}
    end

    local hl = Instance.new("Highlight")
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.Adornee = obj
    hl.Parent = CoreGui
    table.insert(ESP_OBJS[tag], hl)

    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
    if not root then return end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 25)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = root
    bb.Parent = CoreGui
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = obj.Name
    table.insert(ESP_OBJS[tag], bb)
end

local function addESP(folder, tag, color)
    clearESP(tag)
    if not folder then return end
    for _, obj in ipairs(folder:GetChildren()) do
        createESP(obj, tag, color)
    end
    -- Listener untuk item baru
    folder.ChildAdded:Connect(function(obj)
        if not ESP_OBJS[tag] then return end
        createESP(obj, tag, color)
    end)
end

-- ==========================================
-- NOCLIP, INFINITE JUMP, FULLBRIGHT, WALKSPEED
-- ==========================================
local NOCLIP_CONN = nil
local function toggleNoclip(v)
    if v then
        NOCLIP_CONN = RUN.Stepped:Connect(function()
            if not CHAR then return end
            for _, p in ipairs(CHAR:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        if NOCLIP_CONN then
            NOCLIP_CONN:Disconnect()
            NOCLIP_CONN = nil
        end
        if CHAR then
            for _, p in ipairs(CHAR:GetDescendants()) do
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

local ORIG_BRIGHT = LIGHTING.Brightness
local ORIG_AMBIENT = LIGHTING.Ambient
local ORIG_SHADOW = LIGHTING.GlobalShadows
local function toggleFullbright(v)
    if v then
        LIGHTING.Brightness = 5
        LIGHTING.Ambient = Color3.fromRGB(255, 255, 255)
        LIGHTING.GlobalShadows = false
    else
        LIGHTING.Brightness = ORIG_BRIGHT
        LIGHTING.Ambient = ORIG_AMBIENT
        LIGHTING.GlobalShadows = ORIG_SHADOW
    end
end

local function applyWalkSpeed(v)
    if HUM then HUM.WalkSpeed = v end
end

-- ==========================================
-- FLUENT UI (LENGKAP)
-- ==========================================
local MAIN_TAB = WIN:CreateTab({ Title = "Main", Icon = "phosphor-hammer-bold" })
local FARM_TAB = WIN:CreateTab({ Title = "Farming", Icon = "phosphor-tree-bold" })
local LOOT_TAB = WIN:CreateTab({ Title = "Looting", Icon = "phosphor-suitcase-bold" })
local MOVE_TAB = WIN:CreateTab({ Title = "Movement", Icon = "phosphor-run-bold" })
local VIS_TAB  = WIN:CreateTab({ Title = "Visuals", Icon = "phosphor-eye-bold" })
local POS_TAB  = WIN:CreateTab({ Title = "Positions", Icon = "phosphor-map-pin-bold" })

-- MAIN TAB
MAIN_TAB:CreateDropdown("ToolDropdown", {
    Title = "Select Tool",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    Default = "Old Axe",
    Callback = function(v) getgenv().W424.SelectedTool = v end,
})

MAIN_TAB:CreateButton({
    Title = "Teleport to Campfire",
    Callback = function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        local camp = map:FindFirstChild("Campground")
        if not camp then return end
        local fire = camp:FindFirstChild("MainFire")
        if not fire then return end
        local center = fire:FindFirstChild("Center") or fire
        local cf = center:IsA("BasePart") and center.CFrame or CFrame.new(center:GetPivot().Position)
        tpTo(cf + Vector3.new(0, 5, 0))
    end,
})

-- FARMING TAB
FARM_TAB:CreateSection("Chop Aura")
FARM_TAB:CreateToggle("ChopToggle", {
    Title = "Chop Aura",
    Default = false,
    Callback = function(v) getgenv().W424.ChopAura = v end,
})
FARM_TAB:CreateSlider("ChopRadius", {
    Title = "Radius",
    Min = 10, Max = 60, Default = 30,
    Callback = function(v) getgenv().W424.ChopRadius = v end,
})

FARM_TAB:CreateSection("Kill Aura")
FARM_TAB:CreateToggle("KillToggle", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(v) getgenv().W424.KillAura = v end,
})
FARM_TAB:CreateSlider("KillRadius", {
    Title = "Radius",
    Min = 10, Max = 60, Default = 30,
    Callback = function(v) getgenv().W424.KillRadius = v end,
})

FARM_TAB:CreateSection("Auto Wood")
FARM_TAB:CreateToggle("AutoWoodToggle", {
    Title = "Auto Wood",
    Default = false,
    Callback = function(v) getgenv().W424.AutoWood = v end,
})
FARM_TAB:CreateSlider("WoodRadius", {
    Title = "Radius",
    Min = 10, Max = 60, Default = 30,
    Callback = function(v) getgenv().W424.WoodRadius = v end,
})
FARM_TAB:CreateDropdown("TreeType", {
    Title = "Tree Type",
    Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    Default = "All Trees",
    Callback = function(v) getgenv().W424.TreeType = v end,
})

FARM_TAB:CreateSection("Auto Hunt")
FARM_TAB:CreateToggle("AutoHuntToggle", {
    Title = "Auto Hunt",
    Default = false,
    Callback = function(v) getgenv().W424.AutoHunt = v end,
})
FARM_TAB:CreateSlider("HuntRadius", {
    Title = "Radius",
    Min = 10, Max = 60, Default = 30,
    Callback = function(v) getgenv().W424.HuntRadius = v end,
})
FARM_TAB:CreateDropdown("MobTarget", {
    Title = "Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Default = "Wolf",
    Callback = function(v) getgenv().W424.TargetMob = v end,
})

-- LOOTING TAB
LOOT_TAB:CreateSection("Auto Claim")
LOOT_TAB:CreateToggle("AutoClaimToggle", {
    Title = "Auto Claim Drops",
    Default = false,
    Callback = function(v) getgenv().W424.AutoClaim = v end,
})

LOOT_TAB:CreateSection("Auto Bring Item")
LOOT_TAB:CreateToggle("AutoBringToggle", {
    Title = "Auto Bring Selected Item",
    Default = false,
    Callback = function(v) getgenv().W424.AutoBringSelected = v end,
})

local itemList = {
    "All", "Log", "Meat", "Pelt", "Bunny Foot", "Sheet Metal", "Bolt", "Coal", "Berry", "Carrot",
    "Alien Chest", "Alpha Wolf Pelt", "Apple", "Bandage", "Bear Pelt", "Biofuel",
    "Chainsaw", "Cultist Gem", "Fuel Canister", "Good Axe", "MedKit", "Morsel",
    "Old Flashlight", "Old Radio", "Revolver", "Rifle", "Steak", "Wolf Pelt"
}
LOOT_TAB:CreateDropdown("ItemDropdown", {
    Title = "Select Item",
    Values = itemList,
    Default = "All",
    Callback = function(v) getgenv().W424.SelectedItem = v end,
})

LOOT_TAB:CreateSection("Auto Loot Chest")
LOOT_TAB:CreateToggle("ChestToggle", {
    Title = "Auto Loot Chest",
    Default = false,
    Callback = function(v) getgenv().W424.AutoLootChest = v end,
})

LOOT_TAB:CreateSection("Auto Feed & Cook")
LOOT_TAB:CreateToggle("FeedToggle", {
    Title = "Auto Feed Campfire",
    Default = false,
    Callback = function(v) getgenv().W424.AutoFeed = v end,
})
LOOT_TAB:CreateDropdown("FeedMaterial", {
    Title = "Fuel Material",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    Default = "Log",
    Callback = function(v) getgenv().W424.FeedMaterial = v end,
})
LOOT_TAB:CreateToggle("CookToggle", {
    Title = "Auto Cook",
    Default = false,
    Callback = function(v) getgenv().W424.AutoCook = v end,
})
LOOT_TAB:CreateDropdown("CookMaterial", {
    Title = "Cook Material",
    Values = {"Morsel", "Steak"},
    Default = "Morsel",
    Callback = function(v) getgenv().W424.CookMaterial = v end,
})

-- MOVEMENT TAB
MOVE_TAB:CreateSlider("WSSlider", {
    Title = "WalkSpeed",
    Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        getgenv().W424.WalkSpeed = v
        applyWalkSpeed(v)
    end,
})
MOVE_TAB:CreateToggle("InfJump", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v) getgenv().W424.InfiniteJump = v end,
})
MOVE_TAB:CreateToggle("Noclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().W424.Noclip = v
        toggleNoclip(v)
    end,
})

-- VISUALS TAB
VIS_TAB:CreateToggle("CharESP", {
    Title = "Characters ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = Workspace:FindFirstChild("Characters")
            addESP(folder, "chars", Color3.fromRGB(255, 60, 60))
        else
            clearESP("chars")
        end
    end,
})
VIS_TAB:CreateToggle("NpcESP", {
    Title = "NPCs ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = Workspace:FindFirstChild("NPCs")
            addESP(folder, "npcs", Color3.fromRGB(255, 165, 0))
        else
            clearESP("npcs")
        end
    end,
})
VIS_TAB:CreateToggle("ItemESP", {
    Title = "Items ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = getItemsFolder()
            addESP(folder, "items", Color3.fromRGB(80, 255, 80))
        else
            clearESP("items")
        end
    end,
})
VIS_TAB:CreateToggle("AllESP", {
    Title = "All ESP",
    Default = false,
    Callback = function(v)
        if v then
            local charFolder = Workspace:FindFirstChild("Characters")
            local npcFolder = Workspace:FindFirstChild("NPCs")
            local itemFolder = getItemsFolder()
            addESP(charFolder, "chars", Color3.fromRGB(255, 60, 60))
            addESP(npcFolder, "npcs", Color3.fromRGB(255, 165, 0))
            addESP(itemFolder, "items", Color3.fromRGB(80, 255, 80))
        else
            clearESP("chars")
            clearESP("npcs")
            clearESP("items")
        end
    end,
})
VIS_TAB:CreateToggle("Fullbright", {
    Title = "Fullbright",
    Default = false,
    Callback = function(v)
        getgenv().W424.Fullbright = v
        toggleFullbright(v)
    end,
})

-- POSITIONS TAB
POS_TAB:CreateButton({
    Title = "Save Position",
    Callback = function()
        if not HRP then return end
        SAVED_POS = HRP.CFrame
        if setclipboard then
            setclipboard(tostring(HRP.Position))
        end
        FLUENT:Notify({
            Title = "Position Saved",
            Content = "Position copied to clipboard.",
            Duration = 3,
        })
    end,
})
POS_TAB:CreateButton({
    Title = "Go to Saved Position",
    Callback = function()
        if SAVED_POS then tpTo(SAVED_POS) end
    end,
})
POS_TAB:CreateButton({
    Title = "Teleport to Stronghold",
    Callback = function()
        local map = Workspace:FindFirstChild("Map")
        if not map then return end
        local landmarks = map:FindFirstChild("Landmarks")
        if not landmarks then return end
        local stronghold = landmarks:FindFirstChild("Stronghold")
        if not stronghold then return end
        local functional = stronghold:FindFirstChild("Functional")
        if not functional then return end
        local doors = functional:FindFirstChild("EntryDoors")
        if not doors then return end
        local doorRight = doors:FindFirstChild("DoorRight")
        if not doorRight then return end
        local model = doorRight:FindFirstChild("Model")
        if not model then return end
        local children = model:GetChildren()
        if #children >= 5 then
            local dest = children[5]
            if dest and dest:IsA("BasePart") then
                tpTo(dest.CFrame + Vector3.new(0, 5, 0))
            end
        end
    end,
})
POS_TAB:CreateButton({
    Title = "Teleport to Diamond Chest",
    Callback = function()
        local items = getItemsFolder()
        if not items then return end
        local chest = items:FindFirstChild("Stronghold Diamond Chest")
        if not chest then return end
        local lid = chest:FindFirstChild("ChestLid")
        if not lid then return end
        local mesh = lid:FindFirstChild("Meshes/diamondchest_Cube.002")
        if mesh and mesh:IsA("BasePart") then
            tpTo(mesh.CFrame + Vector3.new(0, 5, 0))
        end
    end,
})

-- ==========================================
-- NOTIFICATION
-- ==========================================
WIN:SelectTab(1)
task.wait(1)
FLUENT:Notify({
    Title = "W424 Ultimate",
    Content = "Full code - no cuts! All features ready.",
    Duration = 5,
})