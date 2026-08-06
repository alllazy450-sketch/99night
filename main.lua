-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- Repo: alllazy450-sketch/99night
-- Source Engine: menk9999 Logic + WindUI
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- State Variables (Logika dari Repo Lama)
local KillAuraEnabled = false
local KillAuraRadius = 200

local AutoBringTreesEnabled = false
local AutoHuntEnabled = false
local SelectedMob = "Wolf"

local AutoClaimEnabled = false
local AutoFeedEnabled = false

local SavedBasecampCFrame = nil
local OriginalTreeCFrames = {}

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

local function getMainPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

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
        scan(map:FindFirstChild("Foliage"))
        scan(map:FindFirstChild("Landmarks"))
    end
    return trees
end

local function findTrunk(tree)
    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Trunk" then return part end
    end
    return nil
end

-- ==========================================
-- BACKGROUND LOOPS (ENGINE FROM OLD REPO)
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
        task.wait(0.1)
    end
end)

-- 2. Bring Small Trees (Auto Wood)
task.spawn(function()
    local treesBrought = false
    while true do
        if AutoBringTreesEnabled then
            local hrp = getHRP()
            if hrp and not treesBrought then
                local target = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 10)
                for _, tree in ipairs(getAllSmallTrees()) do
                    local trunk = findTrunk(tree)
                    if trunk then
                        if not OriginalTreeCFrames[tree] then OriginalTreeCFrames[tree] = trunk.CFrame end
                        tree.PrimaryPart = trunk
                        trunk.Anchored = false
                        trunk.CanCollide = false
                        tree:SetPrimaryPartCFrame(target + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
                        trunk.Anchored = true
                    end
                end
                treesBrought = true
            end
        else
            if treesBrought then
                for tree, cframe in pairs(OriginalTreeCFrames) do
                    local trunk = findTrunk(tree)
                    if trunk then
                        tree.PrimaryPart = trunk
                        tree:SetPrimaryPartCFrame(cframe)
                        trunk.Anchored = true
                        trunk.CanCollide = true
                    end
                end
                OriginalTreeCFrames = {}
                treesBrought = false
            end
        end
        task.wait(1)
    end
end)

-- 3. Bring Mobs + Auto Return to Basecamp
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
                    local stackOffsetY = 3
                    local count = 0
                    if characterFolder then
                        for _, model in ipairs(characterFolder:GetChildren()) do
                            if model.Name == SelectedMob then
                                local mainPart = getMainPart(model)
                                if mainPart then
                                    local targetCFrame = hrp.CFrame + Vector3.new(0, count * stackOffsetY, 0)
                                    if model.PrimaryPart then
                                        model:SetPrimaryPartCFrame(targetCFrame)
                                    else
                                        mainPart.CFrame = targetCFrame
                                    end
                                    count = count + 1
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
        task.wait(0.3)
    end
end)

-- 4. Auto Claim & Auto Feed
task.spawn(function()
    while true do
        pcall(function()
            local hrp = getHRP()
            if AutoClaimEnabled and hrp and itemFolder then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name:find("Meat") or item.Name:find("Pelt") or item.Name == "Bunny Foot" or item.Name == "Log" then
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
        task.wait(2)
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Old Repo Engine",
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
    Title = "Kill Aura",
    Default = false,
    Callback = function(v) KillAuraEnabled = v end
})

MainTab:Slider({
    Title = "Kill Aura Range",
    Min = 50, Max = 500, Default = 200,
    Callback = function(v) KillAuraRadius = v end
})

AutoTab:Section({ Title = "Automation Features" })

AutoTab:Toggle({
    Title = "Bring All Small Trees (Auto Wood)",
    Default = false,
    Callback = function(v) AutoBringTreesEnabled = v end
})

AutoTab:Toggle({
    Title = "Bring Mobs to You (Auto Mob)",
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
    Title = "Auto Claim Items (Meat/Log/Pelts)",
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

PlayerTab:Slider({
    Title = "WalkSpeed",
    Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        local char = LocalPlayer and LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end
})

WindUI:Notify({
    Title = "alllazy450 Repo Ready",
    Content = "Logika Repo Lama Berhasil Diterapkan!",
    Duration = 5
})
