-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FINAL FIX (BERDASARKAN REMOTE SPY)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- DAFTAR ITEM LENGKAP (DARI SOURCE VIETNAM)
-- ==========================================
local itemList = {
    "Alien Chest", "Alpha Wolf Pelt", "Anvil Front", "Anvil Back", "Apple",
    "Bandage", "Bear Corpse", "Bear Pelt", "Berry", "Biofuel", "Bolt",
    "Broken Fan", "Bunny Foot", "Carrot", "Coal", "Coin Stack",
    "Cooked Morsel", "Cooked Steak", "Chainsaw", "Cultist", "Cultist Gem",
    "Flower", "Fuel Canister", "Hologram Emitter", "Item Chest",
    "Laser Fence Blueprint", "Leather Body", "Iron Body", "Thorn Body",
    "Log", "MedKit", "Morsel", "Old Flashlight", "Old Radio",
    "Good Sack", "Good Axe", "Raygun", "Giant Sack", "Strong Axe",
    "Oil Barrel", "Old Car Engine", "Rifle", "Rifle Ammo", "Revolver",
    "Revolver Ammo", "Sapling", "Sheet Metal", "Steak", "Wolf Pelt",
    "Gem of the Forest Fragment", "Tyre", "Washing Machine", "Broken Microwave"
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
    AutoBringSelected = false,
    SelectedItem = "All",
    AutoFeed = false, FeedMaterial = "Log",
    AutoCook = false, CookMaterial = "Morsel",
    AutoLootChest = false,
}

-- ==========================================
-- DAMAGE ID MAPPING (BERDASARKAN REMOTE SPY)
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
-- UTILITY FUNCTIONS
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function equipTool(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then return child end
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
                if item:IsA("Tool") and item.Name == toolName then
                    tool = item
                    break
                end
            end
        end
        if tool then break end
    end
    if not tool then return nil end
    local equipRemote = RemotesFolder:FindFirstChild("EquipItemHandle")
    if equipRemote then
        pcall(function() equipRemote:FireServer("FireAllClients", tool) end)
        task.wait(0.15)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end
    local equipRemotes = {
        RemotesFolder:FindFirstChild("EquipItem"),
        RemotesFolder:FindFirstChild("EquipTool"),
        RemotesFolder:FindFirstChild("SelectTool")
    }
    for _, remote in ipairs(equipRemotes) do
        if remote then
            pcall(function() remote:FireServer(tool) end)
            task.wait(0.15)
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
            pcall(function() remote:FireServer(toolName) end)
            task.wait(0.15)
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
        end
    end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end
    pcall(function() tool.Parent = char end)
    task.wait(0.2)
    return char:FindFirstChild(toolName)
end

-- ==========================================
-- ATTACK TARGET (DENGAN PARAMETER BOOLEAN)
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

    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if damageRemote then
        pcall(function()
            -- 5 parameter: target, tool, damageID, CFrame, boolean (false)
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position), false)
            success = true
        end)
    end

    local hitRemote = RemotesFolder:FindFirstChild("Hit") or RemotesFolder:FindFirstChild("DealDamage")
    if hitRemote then pcall(function() hitRemote:FireServer(target, tool) success = true end) end

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
-- DRAG ITEM TO POSITION
-- ==========================================
local function dragItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
        if startDrag then startDrag:FireServer(item) end
        task.wait(0.05)
        local part = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if part and part:IsDescendantOf(Workspace) then
            part.CFrame = CFrame.new(position)
            part.Velocity = Vector3.new(0, 0, 0)
        end
        if stopDrag then stopDrag:FireServer(item) end
    end)
end

-- ==========================================
-- GET TREE PART
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
-- ENGINE LOOPS (SEMUA FITUR)
-- ==========================================
-- 1. Chop Aura
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.ChopRadius
                local foliage = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if foliage then
                    for _, tree in ipairs(foliage:GetChildren()) do
                        if not getgenv().W424.ChopAura then break end
                        local part = getTreePart(tree)
                        if part and (hrp.Position - part.Position).Magnitude <= radius then
                            attackTarget(tree, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. Kill Aura
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.KillRadius
                local charactersFolder = Workspace:FindFirstChild("Characters")
                if charactersFolder then
                    for _, mob in ipairs(charactersFolder:GetChildren()) do
                        if not getgenv().W424.KillAura then break end
                        if mob:IsA("Model") and mob ~= LocalPlayer.Character then
                            local humanoid = mob:FindFirstChildOfClass("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                                if part and (hrp.Position - part.Position).Magnitude <= radius then
                                    attackTarget(mob, tool, damageID)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Wood
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.AutoWood then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.WoodRadius
                local trees = getFilteredTrees()
                for _, tree in ipairs(trees) do
                    if not getgenv().W424.AutoWood then break end
                    local part = getTreePart(tree)
                    if part and (hrp.Position - part.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Hunt
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local targetName = getgenv().W424.TargetMob
                local radius = getgenv().W424.HuntRadius
                local charactersFolder = Workspace:FindFirstChild("Characters")
                if charactersFolder then
                    for _, mob in ipairs(charactersFolder:GetChildren()) do
                        if not getgenv().W424.AutoHunt then break end
                        if mob:IsA("Model") and mob.Name:find(targetName) then
                            local humanoid = mob:FindFirstChildOfClass("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                                if part and (hrp.Position - part.Position).Magnitude <= radius then
                                    attackTarget(mob, tool, damageID)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Claim Drops
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) and not item.Name:find("Chest") then
                        dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Bring Selected Item
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                local targetItem = getgenv().W424.SelectedItem
                for _, item in ipairs(itemFolder:GetChildren()) do
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

-- 7. Auto Feed Campfire
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                local burnRemote = RemotesFolder:FindFirstChild("RequestBurnItem")
                local inv = LocalPlayer:FindFirstChild("Inventory")
                if not burnRemote or not inv then return end
                local feedMat = getgenv().W424.FeedMaterial
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name:lower():find(feedMat:lower()) then
                        burnRemote:FireServer(item)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
end)

-- 8. Auto Cook
task.spawn(function()
    while task.wait(2) do
        if getgenv().W424.AutoCook then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                local cookMat = getgenv().W424.CookMaterial
                local campfirePos = getCampfirePosition()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(cookMat:lower()) then
                        dragItemToPos(item, campfirePos + Vector3.new(0, 1, 0))
                    end
                end
            end)
        end
    end
end)

-- 9. Auto Loot Chest
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    fireproximityprompt(obj)
                                    task.wait(0.2)
                                    for _, loot in ipairs(itemFolder:GetChildren()) do
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
-- RESPAWN HANDLER
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function()
    print("[W424] Karakter respawn.")
end)

-- ==========================================
-- RAYFIELD UI (LENGKAP)
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 99 Nights",
   LoadingTitle = "Memuat Fitur Lengkap...",
   LoadingSubtitle = "by W424 (Remote Spy Fix)",
   Theme = "DarkBlue",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- TAB 1: COMBAT
local TabCombat = Window:CreateTab("Combat", 4483362458)
TabCombat:CreateSection("Pengaturan Senjata")
TabCombat:CreateDropdown({
   Name = "Pilih Tool",
   Options = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
   CurrentOption = getgenv().W424.SelectedTool,
   Flag = "ToolDropdown",
   Callback = function(opt)
      getgenv().W424.SelectedTool = opt
   end,
})

TabCombat:CreateSection("Aura")
TabCombat:CreateToggle({
   Name = "Chop Aura",
   CurrentValue = getgenv().W424.ChopAura,
   Flag = "ChopTog",
   Callback = function(v)
      getgenv().W424.ChopAura = v
   end,
})
TabCombat:CreateSlider({
   Name = "Chop Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.ChopRadius,
   Flag = "ChopRad",
   Callback = function(v)
      getgenv().W424.ChopRadius = v
   end,
})

TabCombat:CreateToggle({
   Name = "Kill Aura",
   CurrentValue = getgenv().W424.KillAura,
   Flag = "KillTog",
   Callback = function(v)
      getgenv().W424.KillAura = v
   end,
})
TabCombat:CreateSlider({
   Name = "Kill Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.KillRadius,
   Flag = "KillRad",
   Callback = function(v)
      getgenv().W424.KillRadius = v
   end,
})

-- TAB 2: AUTO FARM
local TabFarm = Window:CreateTab("Auto Farm", 4483362458)
TabFarm:CreateSection("Auto Wood")
TabFarm:CreateToggle({
   Name = "Auto Wood (Radius)",
   CurrentValue = getgenv().W424.AutoWood,
   Flag = "WoodTog",
   Callback = function(v)
      getgenv().W424.AutoWood = v
   end,
})
TabFarm:CreateSlider({
   Name = "Wood Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.WoodRadius,
   Flag = "WoodRad",
   Callback = function(v)
      getgenv().W424.WoodRadius = v
   end,
})
TabFarm:CreateDropdown({
   Name = "Jenis Pohon",
   Options = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
   CurrentOption = getgenv().W424.TreeType,
   Flag = "TreeDropdown",
   Callback = function(opt)
      getgenv().W424.TreeType = opt
   end,
})

TabFarm:CreateSection("Auto Hunt")
TabFarm:CreateToggle({
   Name = "Auto Hunt (Radius)",
   CurrentValue = getgenv().W424.AutoHunt,
   Flag = "HuntTog",
   Callback = function(v)
      getgenv().W424.AutoHunt = v
   end,
})
TabFarm:CreateSlider({
   Name = "Hunt Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.HuntRadius,
   Flag = "HuntRad",
   Callback = function(v)
      getgenv().W424.HuntRadius = v
   end,
})
TabFarm:CreateDropdown({
   Name = "Target Mob",
   Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
   CurrentOption = getgenv().W424.TargetMob,
   Flag = "MobDropdown",
   Callback = function(opt)
      getgenv().W424.TargetMob = opt
   end,
})

-- TAB 3: LOOTING
local TabLoot = Window:CreateTab("Looting", 4483362458)
TabLoot:CreateSection("Auto Claim Drops")
TabLoot:CreateToggle({
   Name = "Auto Claim Drops (Semua Item)",
   CurrentValue = getgenv().W424.AutoClaim,
   Flag = "ClaimTog",
   Callback = function(v)
      getgenv().W424.AutoClaim = v
   end,
})

TabLoot:CreateSection("Auto Bring Item (Spesifik)")
TabLoot:CreateToggle({
   Name = "Auto Bring Selected Item",
   CurrentValue = getgenv().W424.AutoBringSelected,
   Flag = "BringTog",
   Callback = function(v)
      getgenv().W424.AutoBringSelected = v
   end,
})
local itemOptions = {"All"}
for _, name in ipairs(itemList) do
    table.insert(itemOptions, name)
end
TabLoot:CreateDropdown({
   Name = "Pilih Item",
   Options = itemOptions,
   CurrentOption = "All",
   Flag = "ItemDropdown",
   Callback = function(opt)
      getgenv().W424.SelectedItem = opt
   end,
})

TabLoot:CreateSection("Auto Loot Chest")
TabLoot:CreateToggle({
   Name = "Auto Loot Chest (Buka & Ambil)",
   CurrentValue = getgenv().W424.AutoLootChest,
   Flag = "ChestTog",
   Callback = function(v)
      getgenv().W424.AutoLootChest = v
   end,
})

-- TAB 4: UTILITY
local TabUtil = Window:CreateTab("Utility", 4483362458)
TabUtil:CreateSection("Campfire")
TabUtil:CreateToggle({
   Name = "Auto Feed Campfire",
   CurrentValue = getgenv().W424.AutoFeed,
   Flag = "FeedTog",
   Callback = function(v)
      getgenv().W424.AutoFeed = v
   end,
})
TabUtil:CreateDropdown({
   Name = "Bahan Bakar",
   Options = {"Log", "Coal", "Biofuel", "Fuel Canister"},
   CurrentOption = getgenv().W424.FeedMaterial,
   Flag = "FeedMatDropdown",
   Callback = function(opt)
      getgenv().W424.FeedMaterial = opt
   end,
})

TabUtil:CreateSection("Auto Cook")
TabUtil:CreateToggle({
   Name = "Auto Cook (Drop ke Campfire)",
   CurrentValue = getgenv().W424.AutoCook,
   Flag = "CookTog",
   Callback = function(v)
      getgenv().W424.AutoCook = v
   end,
})
TabUtil:CreateDropdown({
   Name = "Bahan Masak",
   Options = {"Morsel", "Steak"},
   CurrentOption = getgenv().W424.CookMaterial,
   Flag = "CookMatDropdown",
   Callback = function(opt)
      getgenv().W424.CookMaterial = opt
   end,
})

-- ==========================================
-- NOTIFIKASI
-- ==========================================
Rayfield:Notify({
   Title = "W424 Hub Ready!",
   Content = "Damage ID & parameter remote telah diperbaiki.",
   Duration = 5,
   Image = 4483362458
})

print("[W424] Final fix berdasarkan Remote Spy loaded.")