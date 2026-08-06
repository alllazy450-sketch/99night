-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- INPUT NUMBER RANGE EDITION (TYPE YOUR RANGE)
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
local AutoWoodRadius = 500

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

-- 2. Auto Wood Hit Loop
task.spawn(function()
    while true do
        if AutoWoodEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents then
                    local tool, damageID = getAnyToolWithDamageID()
                    if tool and damageID then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                        for _, obj in ipairs(Workspace:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name == "Small Tree") then
                                local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if trunk and (trunk.Position - hrp.Position).Magnitude <= AutoWoodRadius then
                                    remoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(trunk.Position))
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

-- 3. Auto Hunt Mob Specific
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
        task.wait(1.5)
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Input Text Range Edition",
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
    Placeholder = "Ketik Range (cth: 1000)",
    Callback = function(v)
        local num = tonumber(v)
        if num then
            KillAuraRadius = num
        end
    end
})

AutoTab:Section({ Title = "Hit Farming Features" })

AutoTab:Toggle({
    Title = "Auto Farm Wood (Hit Aura Trees)",
    Default = false,
    Callback = function(v) AutoWoodEnabled = v end
})

AutoTab:Input({
    Title = "Auto Wood Range (Studs)",
    Value = "500",
    Placeholder = "Ketik Range (cth: 10000 buat Max Map)",
    Callback = function(v)
        local num = tonumber(v)
        if num then
            AutoWoodRadius = num
        end
    end
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

PlayerTab:Input({
    Title = "WalkSpeed",
    Value = "16",
    Placeholder = "Ketik Kecepatan (cth: 50)",
    Callback = function(v)
        local num = tonumber(v)
        local char = LocalPlayer and LocalPlayer.Character
        if num and char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = num
        end
    end
})

WindUI:Notify({
    Title = "Input System Ready",
    Content = "Sekarang Kamu Bisa Ketik Bebas Angka Range-nya!",
    Duration = 5
})
