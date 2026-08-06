-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FULL IMPROVED ENGINE & CUSTOM FEATURES
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
local KillAuraRadius = 1000

local AutoWoodEnabled = false
local SelectedTreeType = "All Trees"

local AutoHuntEnabled = false
local SelectedMob = "Wolf"

local BulkTPEnabled = false
local SelectedBulkItem = "Log"
local TPDestination = "To Player"

local AutoClaimEnabled = false
local AutoFeedEnabled = false
local SelectedFeedMaterials = {
    ["Log"] = true,
    ["Coal"] = true,
    ["Biofuel"] = true,
    ["Fuel Canister"] = true
}

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

local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local campground = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if campground then
            local mainFire = campground:FindFirstChild("MainFire") or campground.PrimaryPart
            if mainFire then
                local part = mainFire:IsA("BasePart") and mainFire or mainFire:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position + Vector3.new(0, 3, 0) end
            end
        end
    end
    return Vector3.new(0, 19, 0) -- Default Fallback Position
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
-- REAL-TIME AUTO CLAIM (EVENT LISTENER)
-- ==========================================

local function isClaimableItem(item)
    local name = item.Name
    return name:find("Meat") or name:find("Pelt") or name == "Bunny Foot" or name == "Log" or name:find("Steak") or name:find("Morsel")
end

itemFolder.ChildAdded:Connect(function(child)
    if AutoClaimEnabled then
        task.wait(0.2)
        local hrp = getHRP()
        if hrp and isClaimableItem(child) then
            moveItemToPos(child, hrp.Position + Vector3.new(0, 2, 0))
        end
    end
end)

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================

-- 1. Extended Kill Aura Loop
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
                                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
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

-- 2. Accurate Auto Wood TP Loop
local function getFilteredTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") then
                local name = obj.Name
                local match = false
                if SelectedTreeType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then match = true end
                elseif SelectedTreeType == "Small Trees" and name == "Small Tree" then
                    match = true
                elseif SelectedTreeType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then
                    match = true
                elseif SelectedTreeType == "Brightwood Trees" and name:find("Brightwood") then
                    match = true
                elseif SelectedTreeType == "Fairy Trees" and (name:find("Fairy") or name:find("Suci")) then
                    match = true
                end
                if match then table.insert(trees, obj) end
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
                local treeList = getFilteredTrees()
                for _, tree in ipairs(treeList) do
                    if not AutoWoodEnabled then break end
                    
                    if tree and tree:IsDescendantOf(Workspace) then
                        local trunk = tree:FindFirstChild("Trunk") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                        if trunk then
                            -- Teleport presisi di depan Trunk pohon
                            hrp.CFrame = CFrame.new(trunk.Position + Vector3.new(0, 0, 3), trunk.Position)
                            task.wait(0.1)
                            
                            while AutoWoodEnabled and tree and tree:IsDescendantOf(Workspace) do
                                remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                                remoteEvents.ToolDamageObject:InvokeServer(tree, tool, damageID, CFrame.new(trunk.Position))
                                task.wait(0.12)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- 3. Auto Hunt Mob Loop
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

-- 4. Bulk Item Teleport Loop (Toggle)
task.spawn(function()
    while true do
        if BulkTPEnabled then
            pcall(function()
                local hrp = getHRP()
                if itemFolder then
                    local targetPos = (TPDestination == "To Player" and hrp) and (hrp.Position + Vector3.new(0, 2, 0)) or getCampfirePosition()
                    local count = 0
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item.Name == SelectedBulkItem then
                            moveItemToPos(item, targetPos + Vector3.new(0, count * 1.5, 0))
                            count = count + 1
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- 5. Configurable Auto Feed Loop
task.spawn(function()
    while true do
        if AutoFeedEnabled then
            pcall(function()
                if itemFolder then
                    local dropPos = getCampfirePosition()
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if SelectedFeedMaterials[item.Name] then
                            moveItemToPos(item, dropPos)
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Fully Improved Edition",
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
    Value = "1000",
    Placeholder = "Ketik Range",
    Callback = function(v)
        local num = tonumber(v)
        if num then KillAuraRadius = num end
    end
})

AutoTab:Section({ Title = "Wood & Mob Farming" })

AutoTab:Toggle({
    Title = "Auto Farm Wood (TP & Cut)",
    Default = false,
    Callback = function(v) AutoWoodEnabled = v end
})

AutoTab:Dropdown({
    Title = "Target Tree Type",
    Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    Default = "All Trees",
    Callback = function(v) SelectedTreeType = v end
})

AutoTab:Toggle({
    Title = "Auto Hunt Mob",
    Default = false,
    Callback = function(v) AutoHuntEnabled = v end
})

AutoTab:Dropdown({
    Title = "Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Default = "Wolf",
    Callback = function(v) SelectedMob = v end
})

AutoTab:Section({ Title = "Campfire & Claim Settings" })

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

AutoTab:Dropdown({
    Title = "Campfire Feed Item",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    Default = "Log",
    Callback = function(v)
        SelectedFeedMaterials = {[v] = true}
    end
})

ItemTab:Section({ Title = "Item Teleport Toggle" })

ItemTab:Toggle({
    Title = "Auto Bring Selected Item",
    Default = false,
    Callback = function(v) BulkTPEnabled = v end
})

ItemTab:Dropdown({
    Title = "Item Name",
    Values = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"},
    Default = "Log",
    Callback = function(v) SelectedBulkItem = v end
})

ItemTab:Dropdown({
    Title = "Teleport Destination",
    Values = {"To Player", "To Campfire"},
    Default = "To Player",
    Callback = function(v) TPDestination = v end
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
    Title = "System Updated",
    Content = "Semua Fitur Baru Berhasil Diterapkan!",
    Duration = 5
})
