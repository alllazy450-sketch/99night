-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FINAL EDITION (NO TELEPORT, FULL FEATURES)
-- ==========================================

-- Load Orion UI
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexsoftware/Orion/main/source')))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    -- Chop Aura (Radius)
    ChopAura = false,
    ChopRadius = 25,
    SelectedAxe = "Old Axe",
    
    -- Kill Aura
    KillAura = false,
    KillRadius = 25,
    
    -- Auto Wood (Radius, tanpa teleport)
    AutoWood = false,
    AutoWoodRadius = 30,
    TreeType = "All Trees",
    
    -- Auto Hunt (Radius)
    AutoHunt = false,
    AutoHuntRadius = 30,
    TargetMob = "Wolf",
    
    -- Auto Claim
    AutoClaim = false,
    
    -- Auto Feed
    AutoFeed = false,
    FeedMaterial = "Log",
    
    -- Auto Loot Chest
    AutoLootChest = false,
}

-- Damage IDs
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- State internal
local equippedTool = nil

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ==========================================
-- EQUIP TOOL (ROBUST)
-- ==========================================
local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name == toolName or child.Name:find(toolName)) then
            equippedTool = child
            return child
        end
    end

    local containers = {
        LocalPlayer:FindFirstChild("Inventory"),
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("StarterGear")
    }
    
    local tool = nil
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
                    tool = item
                    break
                end
            end
        end
        if tool then break end
    end

    if not tool then
        warn("Tool " .. toolName .. " tidak ditemukan!")
        return nil
    end

    -- Equip via remote
    if RemotesFolder then
        local equipRemotes = {
            RemotesFolder:FindFirstChild("EquipItemHandle"),
            RemotesFolder:FindFirstChild("EquipItem"),
            RemotesFolder:FindFirstChild("EquipTool"),
            RemotesFolder:FindFirstChild("SelectTool")
        }
        for _, remote in ipairs(equipRemotes) do
            if remote then
                pcall(function() remote:FireServer(tool) end)
                task.wait(0.15)
                if char:FindFirstChild(toolName) then
                    equippedTool = char:FindFirstChild(toolName)
                    return equippedTool
                end
                pcall(function() remote:FireServer(toolName) end)
                task.wait(0.15)
                if char:FindFirstChild(toolName) then
                    equippedTool = char:FindFirstChild(toolName)
                    return equippedTool
                end
            end
        end
    end

    -- Humanoid:EquipTool
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        pcall(function() humanoid:EquipTool(tool) end)
        task.wait(0.2)
        if char:FindFirstChild(toolName) then
            equippedTool = char:FindFirstChild(toolName)
            return equippedTool
        end
    end

    -- Last resort
    pcall(function() tool.Parent = char end)
    task.wait(0.2)
    if char:FindFirstChild(toolName) then
        equippedTool = char:FindFirstChild(toolName)
        return equippedTool
    end

    return nil
end

-- ==========================================
-- ATTACK TARGET (MULTI METODE)
-- ==========================================
local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    local mainPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") 
        or target:FindFirstChild("Trunk") or target:FindFirstChild("MainPart") 
        or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end

    local success = false
    pcall(function() tool:Activate() success = true end)
    task.wait(0.05)

    local swing = tool:FindFirstChild("Swing")
    if swing then pcall(function() swing:FireServer() success = true end) end

    if RemotesFolder then
        local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
        if damageRemote then
            pcall(function() damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position)) success = true end)
        end
        local hitRemote = RemotesFolder:FindFirstChild("Hit") or RemotesFolder:FindFirstChild("DealDamage")
        if hitRemote then pcall(function() hitRemote:FireServer(target, tool) success = true end) end
    end

    local damageEvent = tool:FindFirstChild("DamageEvent") or tool:FindFirstChild("OnAttack")
    if damageEvent then pcall(function() damageEvent:FireServer(target) success = true end) end

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
-- GET TREE MAIN PART
-- ==========================================
local function getTreeMainPart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree:FindFirstChild("MainPart")
        or tree:FindFirstChild("Head") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
    if part and part:IsA("BasePart") and part:IsDescendantOf(Workspace) then return part end
    return nil
end

-- ==========================================
-- GET FILTERED TREES
-- ==========================================
local function getFilteredTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                local match = false
                local treeType = getgenv().W424.TreeType
                if treeType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then match = true end
                elseif treeType == "Small Trees" and name == "Small Tree" then match = true
                elseif treeType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then match = true
                elseif treeType == "Brightwood Trees" and name:find("Brightwood") then match = true
                elseif treeType == "Fairy Trees" and (name:find("Fairy") or name:find("Suci")) then match = true
                end
                if match and getTreeMainPart(obj) then table.insert(trees, obj) end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if map then
        local possibleFolders = {"Foliage", "Landmarks", "Trees", "Environment", "Resources"}
        for _, folderName in ipairs(possibleFolders) do
            local folder = map:FindFirstChild(folderName)
            if folder then scan(folder) end
        end
        scan(map)
    end

    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood") or obj.Name:find("Fairy")) then
                if getTreeMainPart(obj) then table.insert(trees, obj) end
            end
        end
    end
    return trees
end

-- ==========================================
-- GET CAMPFIRE POSITION
-- ==========================================
local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local campground = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if campground then
            local mainFire = campground:FindFirstChild("MainFire") or campground:FindFirstChild("Campfire") or campground.PrimaryPart
            if mainFire then
                local part = mainFire:IsA("BasePart") and mainFire or mainFire:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position + Vector3.new(0, 3, 0) end
            end
        end
    end
    return Vector3.new(0, 19, 0)
end

-- ==========================================
-- MOVE ITEM (DRAG REMOTE)
-- ==========================================
local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        if RemotesFolder then
            local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
            if startDrag then startDrag:FireServer(item) end
        end
        task.wait(0.05)
        local targetPart = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if targetPart and targetPart:IsDescendantOf(Workspace) then
            targetPart.CFrame = CFrame.new(position)
            targetPart.Velocity = Vector3.new(0, 0, 0)
        end
        if RemotesFolder then
            local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
            if stopDrag then stopDrag:FireServer(item) end
        end
    end)
end

-- ==========================================
-- 1. CHOP AURA (RADIUS)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                if not tool then return end

                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                local foliageFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliageFolder then return end

                for _, v in ipairs(foliageFolder:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
                    local mainPart = getTreeMainPart(v)
                    if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.ChopRadius then
                        attackTarget(v, tool, damageID)
                        task.wait(0.05)
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 2. KILL AURA (MOB)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                if not tool then return end

                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                local entitiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace

                for _, v in ipairs(entitiesFolder:GetChildren()) do
                    if not getgenv().W424.KillAura then break end
                    if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v ~= LocalPlayer.Character then
                        local targetPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                        if targetPart and (hrp.Position - targetPart.Position).Magnitude <= getgenv().W424.KillRadius then
                            attackTarget(v, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 3. AUTO WOOD (RADIUS, TANPA TELEPORT)
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.AutoWood then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                if not tool then return end

                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                local treeList = getFilteredTrees()
                local radius = getgenv().W424.AutoWoodRadius

                for _, tree in ipairs(treeList) do
                    if not getgenv().W424.AutoWood then break end
                    if not tree:IsDescendantOf(Workspace) then continue end
                    local mainPart = getTreeMainPart(tree)
                    if mainPart and (hrp.Position - mainPart.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.1) -- jeda agar tidak spam
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 4. AUTO HUNT (RADIUS)
-- ==========================================
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                if not tool then return end

                local radius = getgenv().W424.AutoHuntRadius
                local entitiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace
                for _, v in ipairs(entitiesFolder:GetChildren()) do
                    if not getgenv().W424.AutoHunt then break end
                    if v:IsA("Model") and v.Name == getgenv().W424.TargetMob and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local targetPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                        if targetPart and (hrp.Position - targetPart.Position).Magnitude <= radius then
                            attackTarget(v, tool, damageID)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 5. AUTO CLAIM (BRING DROPS)
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = getHRP()
                if hrp and itemFolder then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                            moveItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 6. AUTO FEED CAMPFIRE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                local burnRemote = RemotesFolder:FindFirstChild("RequestBurnItem")
                if not burnRemote then return end

                local inventory = LocalPlayer:FindFirstChild("Inventory")
                if not inventory then return end

                local feedMat = getgenv().W424.FeedMaterial
                for _, item in ipairs(inventory:GetChildren()) do
                    if item.Name:lower():find(feedMat:lower()) then
                        burnRemote:FireServer(item)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 7. AUTO LOOT CHEST
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end

                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoLootChest then break end
                    if chest:IsA("Model") and string.find(chest.Name, "Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, child in ipairs(main:GetChildren()) do
                                if child:IsA("ProximityPrompt") then
                                    pcall(function() child.RequiresLineOfSight = false end)
                                    fireproximityprompt(child)
                                    task.wait(0.2)
                                    for _, loot in ipairs(itemFolder:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") and loot:IsDescendantOf(Workspace) then
                                            moveItemToPos(loot, hrp.Position + Vector3.new(0, 2, 0))
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
-- RESPAWN HANDLER
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function(char)
    equippedTool = nil
    if OrionLib then
        OrionLib:MakeNotification({
            Name = "Respawn",
            Content = "State direset.",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
end)

-- ==========================================
-- ORION UI (LENGKAP)
-- ==========================================
local Window = OrionLib:MakeWindow({
    Name = "W424 Hub | 99 Nights",
    HidePremium = true,
    SaveConfig = false,
    IntroText = "Full Feature - No Teleport",
})

-- TAB 1: COMBAT & AURA
local CombatTab = Window:MakeTab({
    Name = "Combat & Aura",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CombatTab:AddDropdown({
    Name = "Select Weapon/Axe",
    Default = getgenv().W424.SelectedAxe,
    Options = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    Callback = function(Value)
        getgenv().W424.SelectedAxe = Value
    end
})

CombatTab:AddToggle({
    Name = "Chop Aura (Radius)",
    Default = getgenv().W424.ChopAura,
    Callback = function(Value)
        getgenv().W424.ChopAura = Value
    end
})

CombatTab:AddSlider({
    Name = "Chop Radius",
    Min = 10, Max = 60, Default = getgenv().W424.ChopRadius,
    Color = Color3.fromRGB(0, 255, 150), Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        getgenv().W424.ChopRadius = Value
    end
})

CombatTab:AddToggle({
    Name = "Kill Aura (Mob)",
    Default = getgenv().W424.KillAura,
    Callback = function(Value)
        getgenv().W424.KillAura = Value
    end
})

CombatTab:AddSlider({
    Name = "Kill Radius",
    Min = 10, Max = 60, Default = getgenv().W424.KillRadius,
    Color = Color3.fromRGB(255, 50, 50), Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        getgenv().W424.KillRadius = Value
    end
})

-- TAB 2: AUTO FARM (RADIUS)
local FarmTab = Window:MakeTab({
    Name = "Auto Farm",
    Icon = "rbxassetid://6023426915",
    PremiumOnly = false
})

FarmTab:AddToggle({
    Name = "Auto Wood (Radius)",
    Default = getgenv().W424.AutoWood,
    Callback = function(Value)
        getgenv().W424.AutoWood = Value
    end
})

FarmTab:AddSlider({
    Name = "Auto Wood Radius",
    Min = 10, Max = 60, Default = getgenv().W424.AutoWoodRadius,
    Color = Color3.fromRGB(0, 200, 255), Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        getgenv().W424.AutoWoodRadius = Value
    end
})

FarmTab:AddDropdown({
    Name = "Tree Type",
    Default = getgenv().W424.TreeType,
    Options = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    Callback = function(Value)
        getgenv().W424.TreeType = Value
    end
})

FarmTab:AddToggle({
    Name = "Auto Hunt (Radius)",
    Default = getgenv().W424.AutoHunt,
    Callback = function(Value)
        getgenv().W424.AutoHunt = Value
    end
})

FarmTab:AddSlider({
    Name = "Auto Hunt Radius",
    Min = 10, Max = 60, Default = getgenv().W424.AutoHuntRadius,
    Color = Color3.fromRGB(255, 200, 0), Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        getgenv().W424.AutoHuntRadius = Value
    end
})

FarmTab:AddDropdown({
    Name = "Target Mob",
    Default = getgenv().W424.TargetMob,
    Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Callback = function(Value)
        getgenv().W424.TargetMob = Value
    end
})

-- TAB 3: AUTOMATION
local AutoTab = Window:MakeTab({
    Name = "Automation",
    Icon = "rbxassetid://6023426915",
    PremiumOnly = false
})

AutoTab:AddToggle({
    Name = "Auto Claim / Bring Drops",
    Default = getgenv().W424.AutoClaim,
    Callback = function(Value)
        getgenv().W424.AutoClaim = Value
    end
})

AutoTab:AddToggle({
    Name = "Auto Feed Campfire",
    Default = getgenv().W424.AutoFeed,
    Callback = function(Value)
        getgenv().W424.AutoFeed = Value
    end
})

AutoTab:AddDropdown({
    Name = "Feed Material",
    Default = getgenv().W424.FeedMaterial,
    Options = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    Callback = function(Value)
        getgenv().W424.FeedMaterial = Value
    end
})

AutoTab:AddToggle({
    Name = "Auto Loot Chests",
    Default = getgenv().W424.AutoLootChest,
    Callback = function(Value)
        getgenv().W424.AutoLootChest = Value
    end
})

-- Inisialisasi
OrionLib:Init()
OrionLib:MakeNotification({
    Name = "W424 Hub",
    Content = "Loaded! Semua fitur aktif tanpa teleport.",
    Image = "rbxassetid://4483345998",
    Time = 4
})