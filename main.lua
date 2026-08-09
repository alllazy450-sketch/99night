-- =============================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT (FIXED TP & PHYSICS)
-- =============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = RemoteEvents:FindFirstChild("RequestConsumeItem")

local ScriptRunning = true

-- Helper untuk posisi player
local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Helper untuk posisi mesin/api (ditambah ketinggian agar jatuh natural)
local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Campground") and map.Campground:FindFirstChild("MainFire") then
        local center = map.Campground.MainFire:FindFirstChild("Center") or map.Campground.MainFire
        if center:IsA("BasePart") then
            return center.Position + Vector3.new(0, 5, 0) -- Jatuh dari atas
        end
    end
    return Vector3.new(0, 22, 0)
end

local function getMachinePosition()
    local structures = Workspace:FindFirstChild("Structures")
    if structures and structures:FindFirstChild("Biofuel Processor") then
        local part = structures["Biofuel Processor"]:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position + Vector3.new(0, 5, 0) -- Jatuh dari atas
        end
    end
    return Vector3.new(21, 19, -5)
end

-- =============================================
-- SAFE TELEPORT ITEM LOGIC (ANTI-BUG/HILANG)
-- =============================================
local function teleportItemSafe(item, targetPos)
    pcall(function()
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if not part then return end

        -- 1. Minta izin ke server untuk memegang item
        RemoteEvents.RequestStartDraggingItem:FireServer(item)
        task.wait(0.05) -- Jeda wajib agar server memberikan hak akses fisik (Network Ownership)

        -- 2. Pindahkan posisi
        if item:IsA("Model") then
            item:SetPrimaryPartCFrame(CFrame.new(targetPos))
        else
            part.CFrame = CFrame.new(targetPos)
        end

        -- 3. Lepaskan item agar gravitasi bekerja
        RemoteEvents.StopDraggingItem:FireServer(item)
    end)
end

-- =============================================
-- UI SETUP
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "W424 - 99 Nights (ULTIMATE)",
    LoadingTitle = "All-in-one | by W424",
    LoadingSubtitle = "Physics & TP Fixed",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)
local ItemTPTab = Window:CreateTab("Item TP", 4483345998)
local PlayerTab = Window:CreateTab("Player", 4483345998)

-- =============================================
-- COMBAT / AURA
-- =============================================
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getAnyToolWithDamageID()
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then return tool, damageID end
    end
    return nil, nil
end

MainTab:CreateSection("🔥 Aura (Combat & Gathering)")

local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

MainTab:CreateSlider({
    Name = "Aura Radius",
    Range = {20, 500},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(Value) auraRadius = Value end
})

MainTab:CreateToggle({
    Name = "Kill Aura (BRUTAL MOBS)",
    CurrentValue = false,
    Callback = function(Value) killAuraEnabled = Value end
})

MainTab:CreateToggle({
    Name = "Aura Chop (TREES)",
    CurrentValue = false,
    Callback = function(Value) treeAuraEnabled = Value end
})

-- MAIN AURA LOOP
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled or treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                
                -- KILL AURA
                if killAuraEnabled then
                    local characters = Workspace:FindFirstChild("Characters")
                    if characters then
                        for _, mob in ipairs(characters:GetChildren()) do
                            if mob:IsA("Model") then
                                local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
                                if mobHumanoid and mobHumanoid.Health > 0 then
                                    local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                    if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                        task.spawn(function()
                                            for i = 1, 3 do -- 3x hit agar cepat tapi tidak merusak server
                                                RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- AURA CHOP (Trees)
                if treeAuraEnabled then
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        for _, obj in ipairs(map:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Log")) then
                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                    task.spawn(function()
                                        -- Cukup 1x hit per loop agar server sempat merespon item drop
                                        RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(part.Position))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- =============================================
-- AUTO FARM & GRIND
-- =============================================
MainTab:CreateSection("⚡ Auto Farm / Grind (Fixed Physics)")

local autoEatEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}

MainTab:CreateToggle({
    Name = "Auto Eat (HP Based)",
    CurrentValue = false,
    Callback = function(Value) autoEatEnabled = Value end
})

local autoGrindItems = {}
MainTab:CreateDropdown({
    Name = "Auto Machine Grind",
    Options = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(Value)
        autoGrindItems = {}
        for _, item in ipairs(Value) do autoGrindItems[item] = true end
    end
})

local autoFuelItems = {}
MainTab:CreateDropdown({
    Name = "Auto Feed Campfire",
    Options = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    MultipleOptions = true,
    CurrentOption = {},
    Callback = function(Value)
        autoFuelItems = {}
        for _, item in ipairs(Value) do autoFuelItems[item] = true end
    end
})

local function processAutoTP(itemSet, destinationPos)
    for itemName, enabled in pairs(itemSet) do
        if enabled then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item.Name == itemName then
                    -- Menggunakan fungsi aman
                    teleportItemSafe(item, destinationPos)
                    task.wait(0.1) -- Jeda antar item agar tidak nabrak
                end
            end
        end
    end
end

-- Loop Auto TP Grind / Feed
task.spawn(function()
    while ScriptRunning do
        processAutoTP(autoGrindItems, getMachinePosition())
        processAutoTP(autoFuelItems, getCampfirePosition())
        task.wait(2)
    end
end)

-- Loop Auto Eat
task.spawn(function()
    while ScriptRunning do
        if autoEatEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hp = LocalPlayer.Character.Humanoid.Health
            local maxHp = LocalPlayer.Character.Humanoid.MaxHealth
            if hp < (maxHp * 0.7) then
                local available = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if table.find(autoEatFoods, item.Name) then table.insert(available, item) end
                end
                if #available > 0 then
                    pcall(function() RemoteConsume:InvokeServer(available[math.random(1, #available)]) end)
                end
            end
        end
        task.wait(2)
    end
end)

-- =============================================
-- ITEM TP TAB
-- =============================================
ItemTPTab:CreateSection("📦 Bring Item to You")

local bringItemList = {
    "Alien Chest", "Berry", "Biofuel", "Bolt", "Broken Fan", "Carrot", "Coal", "Coin Stack",
    "Cooked Morsel", "Cooked Steak", "Chainsaw", "Cultist Gem", "Fuel Canister", "Item Chest",
    "Log", "MedKit", "Morsel", "Old Flashlight", "Old Radio", "Oil Barrel", "Old Car Engine",
    "Rifle", "Revolver", "Sheet Metal", "Steak", "Wolf Pelt", "Tyre", "Washing Machine"
}

local currentBringItem = bringItemList[1]
ItemTPTab:CreateDropdown({
    Name = "Select Item",
    Options = bringItemList,
    CurrentOption = bringItemList[1],
    Callback = function(Option)
        currentBringItem = type(Option) == "table" and Option[1] or Option
    end
})

ItemTPTab:CreateButton({
    Name = "Bring Selected Item",
    Callback = function()
        local selected = currentBringItem
        if not selected then return end
        
        local count = 0
        local hrp = getRootPart()
        if not hrp then return end
        
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item.Name == selected then
                -- Susun secara rapi ke atas agar tidak nyangkut di tanah
                local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                teleportItemSafe(item, targetPos)
                count = count + 1
            end
        end
        Rayfield:Notify({Title = "Bring Success", Content = "Berhasil menarik " .. count .. " " .. selected, Duration = 3})
    end
})

-- =============================================
-- PLAYER TAB
-- =============================================
PlayerTab:CreateSection("🏃 Movement")

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

Rayfield:LoadConfiguration()
