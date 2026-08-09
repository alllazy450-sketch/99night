-- =============================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT (FIXED & BRUTAL)
-- =============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = RemoteEvents:FindFirstChild("RequestConsumeItem")

local ScriptRunning = true
local AllConnections = {}

local function trackConnection(conn)
    if conn then table.insert(AllConnections, conn) end
    return conn
end

local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if not map then return Vector3.new(0, 19, 0) end
    local campground = map:FindFirstChild("Campground")
    if not campground then return Vector3.new(0, 19, 0) end
    local mainFire = campground:FindFirstChild("MainFire")
    if not mainFire then return Vector3.new(0, 19, 0) end
    local center = mainFire:FindFirstChild("Center") or mainFire
    if center:IsA("BasePart") then
        return center.Position + Vector3.new(0, 2, 0)
    end
    return Vector3.new(0, 19, 0)
end

local function getMachinePosition()
    local structures = Workspace:FindFirstChild("Structures")
    if not structures then return Vector3.new(21, 16, -5) end
    local processor = structures:FindFirstChild("Biofuel Processor")
    if not processor then return Vector3.new(21, 16, -5) end
    local part = processor:FindFirstChildWhichIsA("BasePart")
    if part then
        return part.Position + Vector3.new(0, 2, 0)
    end
    return Vector3.new(21, 16, -5)
end

local campfireDropPos = getCampfirePosition()
local machineDropPos = getMachinePosition()

-- =============================================
-- CREATE UI WINDOW
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "W424 - 99 Nights (BRUTAL)",
    LoadingTitle = "All-in-one | by W424",
    LoadingSubtitle = "Fixing TP & Dropdowns",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local MainTab = Window:CreateTab("Main Farm", 4483345998)
local ESPTab = Window:CreateTab("ESP", 4483345998)
local ItemTPTab = Window:CreateTab("Item TP", 4483345998)
local GameTPTab = Window:CreateTab("Game TP", 4483345998)
local PlayerTab = Window:CreateTab("Player", 4483345998)

-- =============================================
-- TOOLS & COMBAT LOGIC
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

local function equipTool(tool)
    if tool then
        pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
    end
end

-- =============================================
-- MAIN TAB - AURA
-- =============================================
MainTab:CreateSection("🔥 Aura (BRUTAL)")

local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

MainTab:CreateSlider({
    Name = "Aura Radius",
    Range = {20, 500},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(Value)
        auraRadius = Value
    end
})

MainTab:CreateToggle({
    Name = "Kill Aura (BRUTAL MOBS)",
    CurrentValue = false,
    Callback = function(Value)
        killAuraEnabled = Value
    end
})

MainTab:CreateToggle({
    Name = "Aura Chop (TREES)",
    CurrentValue = false,
    Callback = function(Value)
        treeAuraEnabled = Value
    end
})

-- MAIN AURA LOOP (MOBS & TREES)
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled or treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                equipTool(tool)
                
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
                                            -- Serangan BRUTAL: multi-hit per loop
                                            for i = 1, 4 do
                                                RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- TREE AURA (AURA CHOP)
                if treeAuraEnabled then
                    local map = Workspace:FindFirstChild("Map")
                    if map then
                        for _, obj in ipairs(map:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Log")) then
                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                    task.spawn(function()
                                        for i = 1, 2 do
                                            RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(part.Position))
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
                
            end
        end
        task.wait(0.1) -- Loop sangat cepat
    end
end)

-- =============================================
-- MAIN TAB - AUTO FARM & GRIND
-- =============================================
MainTab:CreateSection("⚡ Auto Farm / Grind (Fixed TP)")

local autoEatEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}

MainTab:CreateToggle({
    Name = "Auto Eat (HP Based)",
    CurrentValue = false,
    Callback = function(Value)
        autoEatEnabled = Value
    end
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

local function processAutoTP(itemSet, destination)
    for itemName, enabled in pairs(itemSet) do
        if enabled then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item.Name == itemName then
                    pcall(function()
                        local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                        if part then
                            part.Anchored = false -- Unanchor agar tidak stuck di udara
                            part.CFrame = CFrame.new(destination)
                        end
                    end)
                end
            end
        end
    end
end

task.spawn(function()
    while ScriptRunning do
        processAutoTP(autoGrindItems, machineDropPos)
        processAutoTP(autoFuelItems, campfireDropPos)
        task.wait(1.5)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if autoEatEnabled then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
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
        end
        task.wait(2)
    end
end)

-- =============================================
-- ITEM TP TAB (FIXED STRINGS)
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
        -- FIX: Rayfield Dropdown mengembalikan Table, kita ambil index ke-1 sebagai Teks
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
                local targetPart = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                if targetPart then
                    pcall(function()
                        targetPart.Anchored = false
                        RemoteEvents.RequestStartDraggingItem:FireServer(item)
                        targetPart.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * 4) + Vector3.new(0, count * 2, 0)
                        RemoteEvents.StopDraggingItem:FireServer(item)
                    end)
                    count = count + 1
                end
            end
        end
        Rayfield:Notify({Title = "Bring Success", Content = "Brought " .. count .. " " .. selected, Duration = 2})
    end
})

-- =============================================
-- ESP TAB (SEDERHANA)
-- =============================================
ESPTab:CreateSection("👁️ ESP")
local espEnabled = false
ESPTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            for _, model in ipairs(ItemsFolder:GetChildren()) do
                local esp = model:FindFirstChild("W424_ESP")
                if esp then esp:Destroy() end
            end
        end
    end
})

task.spawn(function()
    while ScriptRunning do
        if espEnabled then
            for _, model in ipairs(ItemsFolder:GetChildren()) do
                if model:IsA("Model") and model.PrimaryPart and not model:FindFirstChild("W424_ESP") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "W424_ESP"
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.Adornee = model.PrimaryPart
                    bb.AlwaysOnTop = true
                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(0, 1, 0)
                    lbl.TextStrokeTransparency = 0.5
                    lbl.Font = Enum.Font.GothamBold
                    lbl.Text = model.Name
                    bb.Parent = model
                end
            end
        end
        task.wait(2)
    end
end)

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
