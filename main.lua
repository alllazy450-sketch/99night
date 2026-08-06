-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ADVANCED AUTO TREE FARM & NEW ITEM DETECTOR
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- State Variables
local KillAuraEnabled = false
local KillAuraRadius = 500

local AutoWoodEnabled = false
local AutoHuntEnabled = false
local SelectedMob = "Wolf"

local AutoClaimEnabled = false
local AutoFeedEnabled = false

local SavedBasecampCFrame = nil

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- Utility Functions
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getAnyToolWithDamageID()
    local inv = LocalPlayer and LocalPlayer:FindFirstChild("Inventory")
    if not inv then return nil, nil end
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = inv:FindFirstChild(toolName)
        if tool then return tool, damageID end
    end
    return nil, nil
end

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) or not remoteEvents then return end
    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
    if part then
        pcall(function()
            remoteEvents.RequestStartDraggingItem:FireServer(item)
            part.CFrame = CFrame.new(position)
            remoteEvents.StopDraggingItem:FireServer(item)
        end)
    end
end

-- ==========================================
-- REAL-TIME AUTO CLAIM (EVENT DETECTION)
-- ==========================================

local function isClaimableItem(item)
    local name = item.Name
    return name:find("Meat") or name:find("Pelt") or name == "Bunny Foot" or name == "Log" or name:find("Steak") or name:find("Morsel")
end

-- Listener ketika ada item baru yang drop/spawn
itemFolder.ChildAdded:Connect(function(child)
    if AutoClaimEnabled then
        task.wait(0.2) -- Beri sedikit jeda agar part ter-render sempurna
        local hrp = getHRP()
        if hrp and isClaimableItem(child) then
            moveItemToPos(child, hrp.Position + Vector3.new(0, 2, 0))
        end
    end
end)

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================

-- 1. Kill Aura Loop
task.spawn(function()
    while true do
        if KillAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents and characterFolder then
                    local tool, damageID = getAnyToolWithDamageID()
                    if tool and damageID then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob:IsA("Model") then
                                local part = mob:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= KillAuraRadius then
                                    remoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.05)
    end
end)

-- 2. Auto Farm Wood (TP ke setiap jenis pohon & Hit sampai tumbang)
local function getAllTreesInMap()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name
                -- Deteksi Pohon Biasa, Hard Tree, Brightwood, Fairy/Suci
                if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then
                    table.insert(trees, obj)
                end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if map then
        scan(map:FindFirstChild("Foliage"))
        scan(map:FindFirstChild("Landmarks"))
    end
    return trees
end

task.spawn(function()
    while true do
        if AutoWoodEnabled then
            local hrp = getHRP()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                local treeList = getAllTreesInMap()
                for _, tree in ipairs(treeList) do
                    if not AutoWoodEnabled then break end
                    
                    if tree and tree:IsDescendantOf(Workspace) then
                        local trunk = tree:FindFirstChild("Trunk") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                        if trunk then
                            -- Teleport dekat ke depan pohon
                            hrp.CFrame = CFrame.new(trunk.Position + Vector3.new(0, 0, 3), trunk.Position)
                            task.wait(0.1)
                            
                            -- Pukul terus-menerus sampai pohon hancur/hilang dari workspace
                            while AutoWoodEnabled and tree and tree:IsDescendantOf(Workspace) do
                                remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                                remoteEvents.ToolDamageObject:InvokeServer(tree, tool, damageID, CFrame.new(trunk.Position))
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- 3. Auto Hunt Mob
task.spawn(function()
    local wasHunting = false
    while true do
        if AutoHuntEnabled then
            local hrp = getHRP()
            if hrp then
                if not wasHunting then
                    SavedBasecampCFrame = hrp.CFrame
                    wasHunting = true
                end

                pcall(function()
                    local tool, damageID = getAnyToolWithDamageID()
                    if tool and damageID and characterFolder then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob.Name == SelectedMob then
                                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                if part then
                                    remoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                end
                            end
                        end
                    end
                end)
            end
        else
            if wasHunting then
                local hrp = getHRP()
                if hrp and SavedBasecampCFrame then
                    hrp.CFrame = SavedBasecampCFrame
                end
                wasHunting = false
                SavedBasecampCFrame = nil
            end
        end
        task.wait(0.1)
    end
end)

-- 4. Auto Claim Periodic Sweep & Auto Feed
task.spawn(function()
    while true do
        pcall(function()
            local hrp = getHRP()
            if AutoClaimEnabled and hrp and itemFolder then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if isClaimableItem(item) then
                        moveItemToPos(item, hrp.Position + Vector3.new(0, 2, 0))
                    end
                end
            end
            if AutoFeedEnabled and itemFolder then
                local campfireDropPos = Vector3.new(0, 19, 0)
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name == "Log" or item.Name == "Coal" or item.Name == "Biofuel" then
                        moveItemToPos(item, campfireDropPos)
                    end
                end
            end
        end)
        task.wait(1.5)
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Advanced Wood & Realtime Claim",
    Author = "alllazy450-sketch",
    Folder = "W424Hub",
    Size = UDim2.fromOffset(580, 420),
    Transparent = true,
    Theme = "Dark"
})

local MainTab   = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389" })
local AutoTab   = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://10734950309" })
local ItemTab   = Window:Tab({ Title = "Item TP", Icon = "rbxassetid://10723345380" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "rbxassetid://10747373176" })

MainTab:Section({ Title = "Combat System" })

MainTab:Toggle({
    Title = "Kill Aura (All Mobs)",
    Default = false,
    Callback = function(v) KillAuraEnabled = v end
})

MainTab:Input({
    Title = "Kill Aura Range (Studs)",
    Value = "500",
    Placeholder = "Ketik Range",
    Callback = function(v)
        local num = tonumber(v)
        if num then KillAuraRadius = num end
    end
})

AutoTab:Section({ Title = "Smart Farm Features" })

AutoTab:Toggle({
    Title = "Auto Farm All Trees (TP & Cut)",
    Default = false,
    Callback = function(v) AutoWoodEnabled = v end
})

AutoTab:Toggle({
    Title = "Auto Hunt Mob (Target Hit Aura)",
    Default = false,
    Callback = function(v) AutoHuntEnabled = v end
})

AutoTab:Dropdown({
    Title = "Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Default = "Wolf",
    Callback = function(v) SelectedMob = v end
})

AutoTab:Toggle({
    Title = "Realtime Auto Claim Items",
    Default = false,
    Callback = function(v) AutoClaimEnabled = v end
})

AutoTab:Toggle({
    Title = "Auto Feed Campfire",
    Default = false,
    Callback = function(v) AutoFeedEnabled = v end
})

ItemTab:Section({ Title = "Bulk Item Teleport" })

ItemTab:Dropdown({
    Title = "Bring Item to Player",
    Values = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"},
    Callback = function(itemName)
        local hrp = getHRP()
        if not hrp or not itemFolder then return end
        local count = 0
        for _, item in ipairs(itemFolder:GetChildren()) do
            if item.Name == itemName then
                moveItemToPos(item, hrp.Position + Vector3.new(0, count * 2, 0))
                count = count + 1
            end
        end
    end
})

PlayerTab:Input({
    Title = "WalkSpeed",
    Value = "16",
    Placeholder = "Ketik Kecepatan",
    Callback = function(v)
        local num = tonumber(v)
        local char = LocalPlayer and LocalPlayer.Character
        if num and char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = num
        end
    end
})

WindUI:Notify({
    Title = "Updated & Ready",
    Content = "Sistem Auto Farm Tree & Realtime Claim Siap!",
    Duration = 5
})
