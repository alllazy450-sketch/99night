-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- REBUILD v4 - REMOTE SPY FIX
-- ==========================================

local PLRS = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LIGHTING = game:GetService("Lighting")
local RUN = game:GetService("RunService")
local TW = game:GetService("TweenService")
local LP = PLRS.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- DEBUG
-- ==========================================
local DEBUG_MODE = true
local function log(tag, msg)
    if DEBUG_MODE then print("[W424][" .. tag .. "] " .. tostring(msg)) end
end

-- ==========================================
-- REMOTES (DARI REMOTE SPY)
-- ==========================================
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)

local Remotes = {
    ToolDamage = RemoteEvents:WaitForChild("ToolDamageObject"),
    EquipItem = RemoteEvents:WaitForChild("EquipItemHandle"),
    UnequipItem = RemoteEvents:FindFirstChild("UnequipItemHandle"),
    StartDrag = RemoteEvents:WaitForChild("RequestStartDraggingItem"),
    StopDrag = RemoteEvents:WaitForChild("StopDraggingItem"),
    BurnItem = RemoteEvents:FindFirstChild("RequestBurnItem"),
    ConsumeItem = RemoteEvents:FindFirstChild("RequestConsumeItem"),
    ReplicateSound = RemoteEvents:FindFirstChild("RequestReplicateSound"),
}

-- ==========================================
-- DAMAGE ID AUTO-DETECT (DARI TOOL INSTANCE)
-- ==========================================
-- Damage ID disimpan di attribute/value tool, atau kita track dari server response
local knownDamageIDs = {} -- cache per tool name
local damageIDCounter = {} -- counter untuk generate ID baru

local function getDamageID(toolInstance)
    if not toolInstance then return "1_9883131443" end
    
    -- Coba ambil dari cache
    if knownDamageIDs[toolInstance.Name] then
        return knownDamageIDs[toolInstance.Name]
    end
    
    -- Coba cari StringValue/NumberValue di dalam tool
    for _, child in ipairs(toolInstance:GetDescendants()) do
        if child:IsA("StringValue") and child.Name:find("Damage") or child.Name:find("ID") then
            knownDamageIDs[toolInstance.Name] = child.Value
            return child.Value
        end
    end
    
    -- Fallback: pakai pattern dari remote spy (format: number_9883131443)
    -- Kita generate incremental ID
    if not damageIDCounter[toolInstance.Name] then
        damageIDCounter[toolInstance.Name] = math.random(15, 25)
    else
        damageIDCounter[toolInstance.Name] = damageIDCounter[toolInstance.Name] + 1
        if damageIDCounter[toolInstance.Name] > 99 then
            damageIDCounter[toolInstance.Name] = 15
        end
    end
    
    local id = tostring(damageIDCounter[toolInstance.Name]) .. "_9883131443"
    knownDamageIDs[toolInstance.Name] = id
    return id
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
-- CHARACTER
-- ==========================================
local CHAR, HRP, HUM
local function refreshCharacter()
    CHAR = LP.Character
    if CHAR then
        HRP = CHAR:WaitForChild("HumanoidRootPart", 3)
        HUM = CHAR:WaitForChild("Humanoid", 3)
    end
end
refreshCharacter()
LP.CharacterAdded:Connect(function(c)
    CHAR = c
    HRP = c:WaitForChild("HumanoidRootPart", 3)
    HUM = c:WaitForChild("Humanoid", 3)
    cachedTool = nil
end)

-- ==========================================
-- ITEM FOLDER
-- ==========================================
local function getItemsFolder()
    return Workspace:FindFirstChild("Items")
end

-- ==========================================
-- LOOT DETECTION
-- ==========================================
local lootKeywords = {"meat", "pelt", "log", "bolt", "sheet metal", "coal", "berry", "carrot", "morsel", "steak", "bunny foot", "medkit", "bandage"}
local function isLootItem(item)
    if not item or not item.Name then return false end
    local name = item.Name:lower()
    for _, kw in ipairs(lootKeywords) do
        if name:find(kw) then return true end
    end
    return false
end

-- ==========================================
-- BACK SYSTEM
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
    TW:Create(BACK_BTN, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()
end)
BACK_BTN.MouseLeave:Connect(function()
    TW:Create(BACK_BTN, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
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

local TP_CONN, LAST_POS, SAVED_POS = nil, nil, nil
local function tpTo(cf)
    if not HRP then return end
    LAST_POS = HRP.CFrame
    if TP_CONN then TP_CONN:Disconnect() TP_CONN = nil end
    HRP.Anchored = true
    HRP.CFrame = cf
    local elapsed = 0
    TP_CONN = RUN.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if not HRP then TP_CONN:Disconnect() TP_CONN = nil return end
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
    if TP_CONN then TP_CONN:Disconnect() TP_CONN = nil end
    if HRP then HRP.Anchored = false end
    if LAST_POS and HRP then HRP.CFrame = LAST_POS end
    hideBack()
end)

-- ==========================================
-- TOOL SYSTEM (FIXED - DARI REMOTE SPY)
-- ==========================================
local cachedTool = nil
local lastEquipTime = 0

local function getToolFromInventory(toolName)
    -- PRIORITAS: Player.Inventory (dari remote spy)
    local inv = LP:FindFirstChild("Inventory")
    if inv then
        for _, item in ipairs(inv:GetChildren()) do
            if item:IsA("Tool") and item.Name == toolName then
                log("TOOL", "Found in Inventory: " .. toolName)
                return item
            end
        end
    end
    
    -- Fallback: Backpack
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name == toolName then
                log("TOOL", "Found in Backpack: " .. toolName)
                return item
            end
        end
    end
    
    -- Fallback: StarterGear
    local sg = LP:FindFirstChild("StarterGear")
    if sg then
        for _, item in ipairs(sg:GetChildren()) do
            if item:IsA("Tool") and item.Name == toolName then
                log("TOOL", "Found in StarterGear: " .. toolName)
                return item
            end
        end
    end
    
    log("TOOL", "NOT FOUND anywhere: " .. toolName)
    return nil
end

local function equipTool(toolName)
    if not CHAR then return nil end

    -- Sudah di tangan?
    for _, child in ipairs(CHAR:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then
            cachedTool = child
            return child
        end
    end

    if cachedTool and cachedTool.Parent == CHAR then
        return cachedTool
    end

    if tick() - lastEquipTime < 1 then
        return cachedTool
    end
    lastEquipTime = tick()

    local tool = getToolFromInventory(toolName)
    if not tool then return nil end

    -- Method dari remote spy: EquipItemHandle:FireServer("FireAllClients", toolInstance)
    if Remotes.EquipItem then
        pcall(function()
            Remotes.EquipItem:FireServer("FireAllClients", tool)
        end)
        task.wait(0.2)
        
        -- Cek lagi
        for _, child in ipairs(CHAR:GetChildren()) do
            if child:IsA("Tool") and child.Name == toolName then
                cachedTool = child
                log("EQUIP", "Success via EquipItemHandle")
                return child
            end
        end
    end

    -- Fallback: Humanoid
    if HUM then
        pcall(function() HUM:EquipTool(tool) end)
        task.wait(0.2)
        for _, child in ipairs(CHAR:GetChildren()) do
            if child:IsA("Tool") and child.Name == toolName then
                cachedTool = child
                log("EQUIP", "Success via Humanoid")
                return child
            end
        end
    end

    -- Last resort
    pcall(function() tool.Parent = CHAR end)
    task.wait(0.2)
    for _, child in ipairs(CHAR:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then
            cachedTool = child
            return child
        end
    end
    
    return nil
end

-- ==========================================
-- ATTACK TARGET (EXACT DARI REMOTE SPY)
-- ==========================================
local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    if not target:IsDescendantOf(Workspace) then return false end

    local mainPart = target:FindFirstChild("HumanoidRootPart")
        or target:FindFirstChild("Head")
        or target:FindFirstChild("Trunk")
        or target:FindFirstChild("MainPart")
        or target.PrimaryPart
        or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end

    -- Swing animasi
    pcall(function() tool:Activate() end)
    task.wait(0.05)
    local swing = tool:FindFirstChild("Swing")
    if swing then pcall(function() swing:FireServer() end) end

    -- Sound effect (opsional, dari remote spy)
    if Remotes.ReplicateSound then
        pcall(function()
            Remotes.ReplicateSound:FireServer("FireAllClients", "WoodChop", {
                Instance = CHAR and CHAR:FindFirstChild("Head"),
                Volume = 0.4
            })
        end)
    end

    -- EXACT dari remote spy: InvokeServer(tree, tool, damageID, cframe, false)
    if Remotes.ToolDamage then
        local ok, result = pcall(function()
            return Remotes.ToolDamage:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position), false)
        end)
        
        if ok then
            log("ATTACK", "SUCCESS on " .. target.Name .. " | ID=" .. damageID)
            return true
        else
            log("ATTACK", "FAIL on " .. target.Name .. " | " .. tostring(result))
        end
    end

    return false
end

-- ==========================================
-- DRAG ITEM (EXACT DARI SOURCE VALID)
-- ==========================================
local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end

    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
    if not part then return end

    if not item.PrimaryPart then
        pcall(function() item.PrimaryPart = part end)
    end

    pcall(function()
        if Remotes.StartDrag then
            Remotes.StartDrag:FireServer(item)
        end
        
        task.wait(0.05)
        
        if item:IsA("Model") and item.PrimaryPart then
            item:SetPrimaryPartCFrame(CFrame.new(position))
        elseif part then
            part.CFrame = CFrame.new(position)
        end
        
        task.wait(0.05)
        
        if Remotes.StopDrag then
            Remotes.StopDrag:FireServer(item)
        end
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
-- CAMPFIRE
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
-- MOB SCANNER
-- ==========================================
local function getMobs()
    local mobs = {}
    local charFolder = Workspace:FindFirstChild("Characters")
    if charFolder then
        for _, obj in ipairs(charFolder:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LP.Character then
                table.insert(mobs, obj)
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LP.Character then
                table.insert(mobs, obj)
            end
        end
    end
    return mobs
end

-- ==========================================
-- ENGINE LOOPS
-- ==========================================

-- 1. Chop Aura + Auto Wood
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.ChopAura or getgenv().W424.AutoWood then
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                
                -- Auto-detect damage ID
                local damageID = getDamageID(tool)
                local radius = getgenv().W424.ChopAura and getgenv().W424.ChopRadius or getgenv().W424.WoodRadius
                local trees = getFilteredTrees()
                
                for _, tree in ipairs(trees) do
                    if not (getgenv().W424.ChopAura or getgenv().W424.AutoWood) then break end
                    local part = getTreePart(tree)
                    if part and part:IsDescendantOf(Workspace) and (HRP.Position - part.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.15)
                    end
                end
            end)
        end
    end
end)

-- 2. Kill Aura + Auto Hunt
task.spawn(function()
    while task.wait(0.35) do
        if getgenv().W424.KillAura or getgenv().W424.AutoHunt then
            pcall(function()
                if not HRP then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                
                local damageID = getDamageID(tool)
                local radius = getgenv().W424.KillAura and getgenv().W424.KillRadius or getgenv().W424.HuntRadius
                local mobs = getMobs()
                
                for _, mob in ipairs(mobs) do
                    if not (getgenv().W424.KillAura or getgenv().W424.AutoHunt) then break end
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local shouldAttack = true
                        if getgenv().W424.AutoHunt and not mob.Name:find(getgenv().W424.TargetMob) then
                            shouldAttack = false
                        end
                        if shouldAttack then
                            local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                            if part and part:IsDescendantOf(Workspace) and (HRP.Position - part.Position).Magnitude <= radius then
                                attackTarget(mob, tool, damageID)
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end())
        end
    end
end)

-- 3. Auto Claim Drops
local claimedItems = {}
task.spawn(function()
    while task.wait(0.6) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                if not HRP then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end

                for item, _ in pairs(claimedItems) do
                    if not item or not item:IsDescendantOf(Workspace) then
                        claimedItems[item] = nil
                    end
                end

                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) and not item.Name:lower():find("chest") and isLootItem(item) then
                        if not claimedItems[item] then
                            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            if part and (HRP.Position - part.Position).Magnitude <= 50 then
                                claimedItems[item] = true
                                moveItemToPos(item, HRP.Position + Vector3.new(0, 1.5, 0))
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Bring Selected Item
task.spawn(function()
    while task.wait(0.6) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                if not HRP then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                local targetItem = getgenv().W424.SelectedItem
                
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) and not item.Name:lower():find("chest") then
                        if targetItem == "All" or item.Name == targetItem then
                            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            if part and (HRP.Position - part.Position).Magnitude <= 80 then
                                moveItemToPos(item, HRP.Position + Vector3.new(0, 1.5, 0))
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Feed
task.spawn(function()
    while task.wait(1.2) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                if not Remotes.BurnItem then return end
                local inv = LP:FindFirstChild("Inventory") or LP:FindFirstChild("Backpack")
                if not inv then return end
                local feedMat = getgenv().W424.FeedMaterial:lower()
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name:lower():find(feedMat) then
                        Remotes.BurnItem:FireServer(item)
                        task.wait(0.4)
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Cook
task.spawn(function()
    while task.wait(2.5) do
        if getgenv().W424.AutoCook then
            pcall(function()
                if not HRP then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                local cookMat = getgenv().W424.CookMaterial:lower()
                local campfirePos = getCampfirePosition()
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(cookMat) then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part and (HRP.Position - part.Position).Magnitude <= 60 then
                            moveItemToPos(item, campfirePos + Vector3.new(0, 1, 0))
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
    end
end)

-- 7. Auto Loot Chest
task.spawn(function()
    while task.wait(0.8) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                if not HRP then return end
                local itemsFolder = getItemsFolder()
                if not itemsFolder then return end
                for _, chest in ipairs(itemsFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:lower():find("chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    if fireproximityprompt then
                                        fireproximityprompt(obj)
                                    end
                                    task.wait(0.3)
                                    for _, loot in ipairs(itemsFolder:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") and loot:IsDescendantOf(Workspace) then
                                            local lp = loot.PrimaryPart or loot:FindFirstChildWhichIsA("BasePart")
                                            if lp and (HRP.Position - lp.Position).Magnitude <= 40 then
                                                moveItemToPos(loot, HRP.Position + Vector3.new(0, 2, 0))
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
-- ESP SYSTEM
-- ==========================================
local ESP_OBJS = {}
local espConnections = {}

local function clearESP(tag)
    if not ESP_OBJS[tag] then ESP_OBJS[tag] = {} return end
    for _, o in ipairs(ESP_OBJS[tag]) do
        pcall(function() o:Destroy() end)
    end
    ESP_OBJS[tag] = {}
end

local function createESP(obj, tag, color)
    if not obj or not obj:IsA("Model") then return end
    if not ESP_OBJS[tag] then ESP_OBJS[tag] = {} end

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
    if espConnections[tag] then espConnections[tag]:Disconnect() end
    espConnections[tag] = folder.ChildAdded:Connect(function(obj)
        task.wait(0.1)
        if not ESP_OBJS[tag] then return end
        createESP(obj, tag, color)
    end)
end

-- ==========================================
-- MOVEMENT SYSTEMS
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
        if NOCLIP_CONN then NOCLIP_CONN:Disconnect() NOCLIP_CONN = nil end
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
-- ORVION LIB UI
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()

local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    Icon  = "rbxassetid://7733965386"
})

local Tabs = {
    Main   = Window:AddTab("Main"),
    Farm   = Window:AddTab("Farming"),
    Loot   = Window:AddTab("Looting"),
    Move   = Window:AddTab("Movement"),
    Visual = Window:AddTab("Visuals"),
    Pos    = Window:AddTab("Positions"),
}

-- --- MAIN TAB ---
Tabs.Main:AddParagraph({Title = "Tool Selection", Content = "Select your primary tool"})

Tabs.Main:AddDropdown({
    Title = "Select Tool",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    DefaultValue = "Old Axe",
    Callback = function(v)
        getgenv().W424.SelectedTool = v
        cachedTool = nil
    end
})

Tabs.Main:AddButton({
    Title = "Teleport to Campfire",
    Callback = function()
        local map = Workspace:FindFirstChild("Map")
        if not map then OrvionLib:Notify("Error", "Map not found", 3) return end
        local camp = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if not camp then OrvionLib:Notify("Error", "Campground not found", 3) return end
        local fire = camp:FindFirstChild("MainFire") or camp:FindFirstChild("Campfire")
        if not fire then OrvionLib:Notify("Error", "Campfire not found", 3) return end
        local center = fire:FindFirstChild("Center") or fire
        local cf = center:IsA("BasePart") and center.CFrame or CFrame.new(center:GetPivot().Position)
        tpTo(cf + Vector3.new(0, 5, 0))
        OrvionLib:Notify("Teleported", "Campfire", 2)
    end
})

-- --- FARMING TAB ---
local chopSection = Tabs.Farm:AddCollapsibleSection("Chop Aura", false)
chopSection:AddToggle({
    Title = "Enable Chop Aura",
    Default = false,
    Callback = function(v) getgenv().W424.ChopAura = v end
})
chopSection:AddInput({
    Title = "Chop Radius",
    Default = "30",
    Placeholder = "10-60",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424.ChopRadius = math.clamp(n, 10, 60) end
    end
})

local killSection = Tabs.Farm:AddCollapsibleSection("Kill Aura", false)
killSection:AddToggle({
    Title = "Enable Kill Aura",
    Default = false,
    Callback = function(v) getgenv().W424.KillAura = v end
})
killSection:AddInput({
    Title = "Kill Radius",
    Default = "30",
    Placeholder = "10-60",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424.KillRadius = math.clamp(n, 10, 60) end
    end
})

local woodSection = Tabs.Farm:AddCollapsibleSection("Auto Wood", false)
woodSection:AddToggle({
    Title = "Enable Auto Wood",
    Default = false,
    Callback = function(v) getgenv().W424.AutoWood = v end
})
woodSection:AddInput({
    Title = "Wood Radius",
    Default = "30",
    Placeholder = "10-60",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424.WoodRadius = math.clamp(n, 10, 60) end
    end
})
woodSection:AddDropdown({
    Title = "Tree Type",
    Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    DefaultValue = "All Trees",
    Callback = function(v) getgenv().W424.TreeType = v end
})

local huntSection = Tabs.Farm:AddCollapsibleSection("Auto Hunt", false)
huntSection:AddToggle({
    Title = "Enable Auto Hunt",
    Default = false,
    Callback = function(v) getgenv().W424.AutoHunt = v end
})
huntSection:AddInput({
    Title = "Hunt Radius",
    Default = "30",
    Placeholder = "10-60",
    Callback = function(v)
        local n = tonumber(v)
        if n then getgenv().W424.HuntRadius = math.clamp(n, 10, 60) end
    end
})
huntSection:AddDropdown({
    Title = "Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    DefaultValue = "Wolf",
    Callback = function(v) getgenv().W424.TargetMob = v end
})

-- --- LOOTING TAB ---
local claimSection = Tabs.Loot:AddCollapsibleSection("Auto Claim", false)
claimSection:AddToggle({
    Title = "Auto Claim Drops",
    Default = false,
    Callback = function(v) getgenv().W424.AutoClaim = v end
})

local bringSection = Tabs.Loot:AddCollapsibleSection("Auto Bring", false)
bringSection:AddToggle({
    Title = "Auto Bring Selected Item",
    Default = false,
    Callback = function(v) getgenv().W424.AutoBringSelected = v end
})

local itemList = {
    "All", "Log", "Meat", "Pelt", "Bunny Foot", "Sheet Metal", "Bolt", "Coal", "Berry", "Carrot",
    "Alien Chest", "Alpha Wolf Pelt", "Apple", "Bandage", "Bear Pelt", "Biofuel",
    "Chainsaw", "Cultist Gem", "Fuel Canister", "Good Axe", "MedKit", "Morsel",
    "Old Flashlight", "Old Radio", "Revolver", "Rifle", "Steak", "Wolf Pelt"
}
Tabs.Loot:AddDropdown({
    Title = "Select Item",
    Values = itemList,
    DefaultValue = "All",
    Callback = function(v) getgenv().W424.SelectedItem = v end
})

local chestSection = Tabs.Loot:AddCollapsibleSection("Auto Loot Chest", false)
chestSection:AddToggle({
    Title = "Auto Loot Chest",
    Default = false,
    Callback = function(v) getgenv().W424.AutoLootChest = v end
})

local feedSection = Tabs.Loot:AddCollapsibleSection("Auto Feed", false)
feedSection:AddToggle({
    Title = "Auto Feed Campfire",
    Default = false,
    Callback = function(v) getgenv().W424.AutoFeed = v end
})
feedSection:AddDropdown({
    Title = "Fuel Material",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    DefaultValue = "Log",
    Callback = function(v) getgenv().W424.FeedMaterial = v end
})

local cookSection = Tabs.Loot:AddCollapsibleSection("Auto Cook", false)
cookSection:AddToggle({
    Title = "Auto Cook",
    Default = false,
    Callback = function(v) getgenv().W424.AutoCook = v end
})
cookSection:AddDropdown({
    Title = "Cook Material",
    Values = {"Morsel", "Steak"},
    DefaultValue = "Morsel",
    Callback = function(v) getgenv().W424.CookMaterial = v end
})

-- --- MOVEMENT TAB ---
Tabs.Move:AddParagraph({Title = "WalkSpeed", Content = "Enter value (16-250)"})
Tabs.Move:AddInput({
    Title = "WalkSpeed Value",
    Default = "16",
    Placeholder = "16-250",
    Callback = function(v)
        local n = tonumber(v)
        if n then
            getgenv().W424.WalkSpeed = math.clamp(n, 16, 250)
            applyWalkSpeed(getgenv().W424.WalkSpeed)
        end
    end
})

Tabs.Move:AddToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v) getgenv().W424.InfiniteJump = v end
})

Tabs.Move:AddToggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().W424.Noclip = v
        toggleNoclip(v)
    end
})

-- --- VISUALS TAB ---
Tabs.Visual:AddToggle({
    Title = "Characters ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = Workspace:FindFirstChild("Characters")
            addESP(folder, "chars", Color3.fromRGB(255, 60, 60))
        else
            clearESP("chars")
            if espConnections["chars"] then espConnections["chars"]:Disconnect() espConnections["chars"] = nil end
        end
    end
})

Tabs.Visual:AddToggle({
    Title = "NPCs ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = Workspace:FindFirstChild("NPCs")
            addESP(folder, "npcs", Color3.fromRGB(255, 165, 0))
        else
            clearESP("npcs")
            if espConnections["npcs"] then espConnections["npcs"]:Disconnect() espConnections["npcs"] = nil end
        end
    end
})

Tabs.Visual:AddToggle({
    Title = "Items ESP",
    Default = false,
    Callback = function(v)
        if v then
            local folder = getItemsFolder()
            addESP(folder, "items", Color3.fromRGB(80, 255, 80))
        else
            clearESP("items")
            if espConnections["items"] then espConnections["items"]:Disconnect() espConnections["items"] = nil end
        end
    end
})

Tabs.Visual:AddToggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(v)
        getgenv().W424.Fullbright = v
        toggleFullbright(v)
    end
})

-- --- POSITIONS TAB ---
Tabs.Pos:AddButton({
    Title = "Save Position",
    Callback = function()
        if not HRP then OrvionLib:Notify("Error", "Character not found", 3) return end
        SAVED_POS = HRP.CFrame
        if setclipboard then setclipboard(tostring(HRP.Position)) end
        OrvionLib:Notify("Saved", "Position copied to clipboard", 3)
    end
})

Tabs.Pos:AddButton({
    Title = "Go to Saved Position",
    Callback = function()
        if SAVED_POS then tpTo(SAVED_POS)
        else OrvionLib:Notify("Error", "No saved position", 3) end
    end
})

Tabs.Pos:AddButton({
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
    end
})

Tabs.Pos:AddButton({
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
    end
})

-- ==========================================
-- BUBBLE TOGGLE
-- ==========================================
local BubbleGui = Instance.new("ScreenGui")
BubbleGui.Name = "W424_BubbleToggle"
BubbleGui.ResetOnSpawn = false
BubbleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
BubbleGui.Parent = CoreGui

local BubbleBtn = Instance.new("TextButton")
BubbleBtn.Name = "BubbleButton"
BubbleBtn.Size = UDim2.new(0, 50, 0, 50)
BubbleBtn.Position = UDim2.new(0, 20, 0.5, -25)
BubbleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BubbleBtn.BackgroundTransparency = 0.1
BubbleBtn.Text = "⚡"
BubbleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BubbleBtn.TextScaled = true
BubbleBtn.Font = Enum.Font.GothamBold
BubbleBtn.BorderSizePixel = 0
BubbleBtn.Parent = BubbleGui
Instance.new("UICorner", BubbleBtn).CornerRadius = UDim.new(1, 0)

local BubbleStroke = Instance.new("UIStroke", BubbleBtn)
BubbleStroke.Color = Color3.fromRGB(100, 100, 100)
BubbleStroke.Thickness = 2

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
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        BubbleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local uiVisible = true
BubbleBtn.MouseButton1Click:Connect(function()
    if dragging then return end
    uiVisible = not uiVisible
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:find("Orvion") or gui.Name:find("orvion")) then
            gui.Enabled = uiVisible
        end
    end
    if uiVisible then
        BubbleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        BubbleBtn.Text = "⚡"
    else
        BubbleBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
        BubbleBtn.Text = "✕"
    end
end)

BubbleBtn.MouseEnter:Connect(function()
    TW:Create(BubbleBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 55, 0, 55)}):Play()
end)
BubbleBtn.MouseLeave:Connect(function()
    TW:Create(BubbleBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 50)}):Play()
end)

-- ==========================================
-- NOTIFICATION
-- ==========================================
task.wait(0.5)
OrvionLib:Notify("W424 Ultimate", "v4 - Remote Spy Fix Applied", 5)
log("INIT", "v4 Loaded. Damage ID auto-detect active.")
