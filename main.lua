-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FINAL RAYFIELD EDITION (ALL FEATURES)
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
-- GLOBAL STATE (SINKRON UI & LOOP)
-- ==========================================
getgenv().W424 = {
    -- Pilihan Tool
    SelectedTool = "Old Axe",
    
    -- Chop Aura
    ChopAura = false,
    ChopRadius = 25,
    
    -- Kill Aura
    KillAura = false,
    KillRadius = 25,
    
    -- Auto Wood
    AutoWood = false,
    WoodRadius = 30,
    TreeType = "All Trees",
    
    -- Auto Hunt
    AutoHunt = false,
    HuntRadius = 30,
    TargetMob = "Wolf",
    
    -- Auto Claim
    AutoClaim = false,
    
    -- Auto Feed
    AutoFeed = false,
    FeedMaterial = "Log",
    
    -- Auto Bring Selected Item
    AutoBringSelected = false,
    SelectedItem = "All",
    
    -- Auto Bring Chest
    AutoBringChest = false,
}

-- ==========================================
-- DAMAGE ID MAPPING (LENGKAP & AKURAT)
-- ==========================================
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016",
}
local function getDamageID(toolName)
    return toolsDamageIDs[toolName] or "1_" .. tostring(LocalPlayer.UserId)
end

-- ==========================================
-- EQUIP TOOL (ROBUST & AMAN)
-- ==========================================
local function equipTool(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end

    -- Cek apakah sudah di tangan
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then
            return child
        end
    end

    -- Cari di Inventory dan Backpack
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

    -- Equip via remote (coba beberapa event)
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
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
            pcall(function() remote:FireServer(toolName) end)
            task.wait(0.15)
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
        end
    end

    -- Humanoid:EquipTool (standar Roblox)
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end

    -- Last resort (risiko tool jatuh, tapi hanya jika semua gagal)
    pcall(function() tool.Parent = char end)
    task.wait(0.2)
    return char:FindFirstChild(toolName)
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

    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if damageRemote then
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position))
            success = true
        end)
    end

    local hitRemote = RemotesFolder:FindFirstChild("Hit") or RemotesFolder:FindFirstChild("DealDamage")
    if hitRemote then pcall(function() hitRemote:FireServer(target, tool) success = true end) end

    -- VirtualInputManager (jika ada ClickDetector)
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
-- GET TREE PART (UNTUK SEMUA JENIS POHON)
-- ==========================================
local function getTreePart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChild("Head")
        or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
end

-- ==========================================
-- GET FILTERED TREES (DARI MAP.FOLIAGE + FALLBACK)
-- ==========================================
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
    -- Fallback: scan seluruh Workspace
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
    -- Fallback
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

-- 1. Chop Aura (Radius)
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.ChopRadius
                local foliage = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliage then return end
                for _, tree in ipairs(foliage:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
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

-- 2. Kill Aura (Radius)
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.KillRadius
                local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("Characters")
                if not enemies then return end
                for _, mob in ipairs(enemies:GetChildren()) do
                    if not getgenv().W424.KillAura then break end
                    if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob ~= LocalPlayer.Character then
                        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if part and (hrp.Position - part.Position).Magnitude <= radius then
                            attackTarget(mob, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Wood (Radius, tanpa teleport)
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.AutoWood then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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

-- 4. Auto Hunt (Radius)
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local targetName = getgenv().W424.TargetMob
                local radius = getgenv().W424.HuntRadius
                local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("Characters")
                if not enemies then return end
                for _, mob in ipairs(enemies:GetChildren()) do
                    if not getgenv().W424.AutoHunt then break end
                    if mob:IsA("Model") and mob.Name:find(targetName) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if part and (hrp.Position - part.Position).Magnitude <= radius then
                            attackTarget(mob, tool, damageID)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Claim Drops (semua item di folder Items)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp or not itemFolder then return end
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                        dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Feed Campfire (dengan pilihan bahan bakar)
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

-- 7. Auto Bring Selected Item (dengan filter index)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoBringSelected then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp or not itemFolder then return end
                local selected = getgenv().W424.SelectedItem
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                        local match = (selected == "All") or item.Name:lower():find(selected:lower())
                        if match then
                            dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                        end
                    end
                end
            end)
        end
    end
end)

-- 8. Auto Bring Chest (buka dan tarik loot)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoBringChest then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp or not itemFolder then return end
                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoBringChest then break end
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            -- Tarik chest ke dekat pemain
                            dragItemToPos(chest, hrp.Position + Vector3.new(0, 2, 2))
                            -- Cari ProximityPrompt dan buka
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    fireproximityprompt(obj)
                                    task.wait(0.2)
                                    -- Tarik semua loot yang muncul
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
LocalPlayer.CharacterAdded:Connect(function(char)
    print("[W424] Karakter respawn, state tetap aktif.")
end)

-- ==========================================
-- RAYFIELD UI (LENGKAP DENGAN SEMUA FITUR)
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 99 Nights",
   LoadingTitle = "Memuat Fitur Lengkap...",
   LoadingSubtitle = "by W424",
   Theme = "DarkBlue",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- TAB 1: Combat & Aura
local TabCombat = Window:CreateTab("Combat & Aura", 4483362458)

TabCombat:CreateSection("Pengaturan Aura")

TabCombat:CreateDropdown({
   Name = "Pilih Tool / Senjata",
   Options = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
   CurrentOption = getgenv().W424.SelectedTool,
   Flag = "ToolDropdown",
   Callback = function(Option)
      getgenv().W424.SelectedTool = Option
   end,
})

TabCombat:CreateToggle({
   Name = "Chop Aura (Radius)",
   CurrentValue = getgenv().W424.ChopAura,
   Flag = "ChopTog",
   Callback = function(Value)
      getgenv().W424.ChopAura = Value
   end,
})

TabCombat:CreateSlider({
   Name = "Chop Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.ChopRadius,
   Flag = "ChopRad",
   Callback = function(Value)
      getgenv().W424.ChopRadius = Value
   end,
})

TabCombat:CreateToggle({
   Name = "Kill Aura (Mobs)",
   CurrentValue = getgenv().W424.KillAura,
   Flag = "KillTog",
   Callback = function(Value)
      getgenv().W424.KillAura = Value
   end,
})

TabCombat:CreateSlider({
   Name = "Kill Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.KillRadius,
   Flag = "KillRad",
   Callback = function(Value)
      getgenv().W424.KillRadius = Value
   end,
})

-- TAB 2: Auto Farm
local TabFarm = Window:CreateTab("Auto Farm", 4483362458)

TabFarm:CreateSection("Auto Wood (Radius)")

TabFarm:CreateToggle({
   Name = "Auto Wood (Radius)",
   CurrentValue = getgenv().W424.AutoWood,
   Flag = "WoodTog",
   Callback = function(Value)
      getgenv().W424.AutoWood = Value
   end,
})

TabFarm:CreateSlider({
   Name = "Wood Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.WoodRadius,
   Flag = "WoodRad",
   Callback = function(Value)
      getgenv().W424.WoodRadius = Value
   end,
})

TabFarm:CreateDropdown({
   Name = "Jenis Pohon",
   Options = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
   CurrentOption = getgenv().W424.TreeType,
   Flag = "TreeDropdown",
   Callback = function(Option)
      getgenv().W424.TreeType = Option
   end,
})

TabFarm:CreateSection("Auto Hunt (Mob)")

TabFarm:CreateToggle({
   Name = "Auto Hunt (Radius)",
   CurrentValue = getgenv().W424.AutoHunt,
   Flag = "HuntTog",
   Callback = function(Value)
      getgenv().W424.AutoHunt = Value
   end,
})

TabFarm:CreateSlider({
   Name = "Hunt Radius",
   Range = {10, 60},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.HuntRadius,
   Flag = "HuntRad",
   Callback = function(Value)
      getgenv().W424.HuntRadius = Value
   end,
})

TabFarm:CreateDropdown({
   Name = "Target Mob",
   Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
   CurrentOption = getgenv().W424.TargetMob,
   Flag = "MobDropdown",
   Callback = function(Option)
      getgenv().W424.TargetMob = Option
   end,
})

-- TAB 3: Looting & Utility
local TabLoot = Window:CreateTab("Looting & Utility", 4483362458)

TabLoot:CreateSection("Auto Claim & Feed")

TabLoot:CreateToggle({
   Name = "Auto Claim Drops",
   CurrentValue = getgenv().W424.AutoClaim,
   Flag = "ClaimTog",
   Callback = function(Value)
      getgenv().W424.AutoClaim = Value
   end,
})

TabLoot:CreateToggle({
   Name = "Auto Feed Campfire",
   CurrentValue = getgenv().W424.AutoFeed,
   Flag = "FeedTog",
   Callback = function(Value)
      getgenv().W424.AutoFeed = Value
   end,
})

TabLoot:CreateDropdown({
   Name = "Bahan Bakar",
   Options = {"Log", "Coal", "Biofuel", "Fuel Canister"},
   CurrentOption = getgenv().W424.FeedMaterial,
   Flag = "FeedDropdown",
   Callback = function(Option)
      getgenv().W424.FeedMaterial = Option
   end,
})

TabLoot:CreateSection("Item Selector & Chest")

TabLoot:CreateDropdown({
   Name = "Pilih Item untuk Ditarik",
   Options = {"All", "Log", "Meat", "Pelt", "Bunny Foot", "Sheet Metal", "Bolt"},
   CurrentOption = getgenv().W424.SelectedItem,
   Flag = "ItemDropdown",
   Callback = function(Option)
      getgenv().W424.SelectedItem = Option
   end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring Selected Item",
   CurrentValue = getgenv().W424.AutoBringSelected,
   Flag = "BringTog",
   Callback = function(Value)
      getgenv().W424.AutoBringSelected = Value
   end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring & Open Chests",
   CurrentValue = getgenv().W424.AutoBringChest,
   Flag = "ChestTog",
   Callback = function(Value)
      getgenv().W424.AutoBringChest = Value
   end,
})

-- ==========================================
-- NOTIFIKASI AWAL
-- ==========================================
Rayfield:Notify({
   Title = "W424 Hub Ready!",
   Content = "Semua fitur aktif. Selamat farming!",
   Duration = 5,
   Image = 4483362458
})

print("[W424] Script final loaded successfully.")