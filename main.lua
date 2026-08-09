-- ==========================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT (SEPARATED SYSTEMS)
-- ==========================================
local OrvionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = ReplicatedStorage:FindFirstChild("RequestConsumeItem")

local ScriptRunning = true

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Campground") and map.Campground:FindFirstChild("MainFire") then
        local center = map.Campground.MainFire:FindFirstChild("Center") or map.Campground.MainFire
        if center:IsA("BasePart") then
            return center.Position + Vector3.new(0, 5, 0)
        end
    end
    return Vector3.new(0, 22, 0)
end

local function getMachinePosition()
    local structures = Workspace:FindFirstChild("Structures")
    if structures and structures:FindFirstChild("Biofuel Processor") then
        local part = structures["Biofuel Processor"]:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position + Vector3.new(0, 5, 0)
        end
    end
    return Vector3.new(21, 19, -5)
end

local function teleportItemSafe(item, targetPos)
    if not item or not item.Parent then return end
    
    pcall(function()
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if not part then return end

        RemoteEvents.RequestStartDraggingItem:FireServer(item)
        task.wait(0.05) 

        if item:IsA("Model") then
            item:SetPrimaryPartCFrame(CFrame.new(targetPos))
        else
            part.CFrame = CFrame.new(targetPos)
        end

        RemoteEvents.StopDraggingItem:FireServer(item)
    end)
end

-- ==========================================
-- BUAT WINDOW ORVION
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    Icon  = ""
})

-- ==========================================
-- BUAT FLOATING BUBBLE (HURUF W)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "W424_ToggleBubble"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local bubble = Instance.new("TextButton")
bubble.Name = "BubbleButton"
bubble.Parent = screenGui
bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bubble.BorderColor3 = Color3.fromRGB(0, 160, 255)
bubble.BorderSizePixel = 2
bubble.Position = UDim2.new(0.05, 0, 0.15, 0)
bubble.Size = UDim2.new(0, 45, 0, 45)
bubble.Font = Enum.Font.GothamBold
bubble.Text = "W"
bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
bubble.TextSize = 22
bubble.AutoButtonColor = true

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = bubble

local dragging, dragInput, dragStart, startPos

bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = bubble.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

bubble.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        bubble.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local uiVisible = true
bubble.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    if Window.MainFrame and Window.MainFrame.Parent then
        Window.MainFrame.Visible = uiVisible
    elseif Window.Container and Window.Container.Parent then
        Window.Container.Visible = uiVisible
    else
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:FindFirstChild("MainFrame") or gui:FindFirstChild("Container") then
                gui.Enabled = uiVisible
            end
        end
    end
end)

-- ==========================================
-- TAMBAH TAB
-- ==========================================
local Tabs = {
    Main    = Window:AddTab("Main Farm"),
    Combat  = Window:AddTab("Aura"),
    ItemTP  = Window:AddTab("Item TP"),
    Player  = Window:AddTab("Player"),
}

-- ==========================================
-- AURA & COMBAT TAB (DIPISAH ANTARA KILL & CHOP)
-- ==========================================
local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

local toolsDamageIDs = {
    ["Old Axe"] = "1_9883131443", 
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

Tabs.Combat:AddToggle({
    Title    = "Kill Aura (Mobs Only)",
    Default  = false,
    Callback = function(state)
        killAuraEnabled = state
    end
})

Tabs.Combat:AddToggle({
    Title    = "Aura Chop (Trees Only)",
    Default  = false,
    Callback = function(state)
        treeAuraEnabled = state
    end
})

Tabs.Combat:AddInput({
    Title       = "Aura Radius",
    Default     = "200",
    Placeholder = "Enter radius...",
    Callback    = function(value)
        local num = tonumber(value)
        if num then auraRadius = num end
    end
})

-- 1. LOOP KHUSUS KILL AURA (Murni untuk Mobs)
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                
                local characters = Workspace:FindFirstChild("Characters")
                if characters then
                    for _, mob in ipairs(characters:GetChildren()) do
                        if mob:IsA("Model") and mob.Parent then
                            local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
                            if mobHumanoid and mobHumanoid.Health > 0 then
                                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                    pcall(function()
                                        RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position), true)
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

-- 2. LOOP KHUSUS AURA CHOP (Murni untuk Pohon/Foliage)
task.spawn(function()
    while ScriptRunning do
        if treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                
                local map = Workspace:FindFirstChild("Map")
                if map then
                    local foliage = map:FindFirstChild("Foliage") or map
                    for _, obj in ipairs(foliage:GetDescendants()) do
                        if obj:IsA("Model") and obj.Parent then
                            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                                pcall(function()
                                    RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                        Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"),
                                        Volume = 0.4
                                    })
                                    RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, CFrame.new(part.Position), true)
                                end)
                                task.wait(0.25)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- ==========================================
-- MAIN FARM TAB (FIXED AUTO GRIND & FEED)
-- ==========================================
local autoEatEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}

Tabs.Main:AddToggle({
    Title    = "Auto Eat (HP Based)",
    Default  = false,
    Callback = function(state)
        autoEatEnabled = state
    end
})

local autoGrindItems = {}
Tabs.Main:AddDropdown({
    Title        = "Auto Machine Grind",
    Values       = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    DefaultValue = "",
    Callback     = function(value)
        autoGrindItems[value] = not autoGrindItems[value]
    end
})

local autoFuelItems = {}
Tabs.Main:AddDropdown({
    Title        = "Auto Feed Campfire",
    Values       = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    DefaultValue = "",
    Callback     = function(value)
        autoFuelItems[value] = not autoFuelItems[value]
    end
})

-- Memperbaiki loop Auto Grind dan Feed agar benar-benar merespons data tabel
task.spawn(function()
    while ScriptRunning do
        local machinePos = getMachinePosition()
        local firePos = getCampfirePosition()
        
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item and item.Parent then
                if autoGrindItems[item.Name] then
                    teleportItemSafe(item, machinePos)
                    task.wait(0.1)
                elseif autoFuelItems[item.Name] then
                    teleportItemSafe(item, firePos)
                    task.wait(0.1)
                end
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if autoEatEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hp = LocalPlayer.Character.Humanoid.Health
            local maxHp = LocalPlayer.Character.Humanoid.MaxHealth
            if hp < (maxHp * 0.7) then
                local available = {}
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if table.find(autoEatFoods, item.Name) and item.Parent then 
                        table.insert(available, item) 
                    end
                end
                if #available > 0 then
                    pcall(function() RemoteConsume:InvokeServer(available[math.random(1, #available)]) end)
                end
            end
        end
        task.wait(2)
    end
end)

-- ==========================================
-- ITEM TP TAB (BRING DIKELOMPOKKAN)
-- ==========================================
local itemCategories = {
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave"},
    Equipment_Weapons = {"Rifle", "Revolver", "Rifle Ammo", "Revolver Ammo", "Chainsaw", "Old Flashlight", "MedKit", "Bandage"}
}

for catName, listItems in pairs(itemCategories) do
    local selectedCatItem = listItems[1]
    
    Tabs.ItemTP:AddDropdown({
        Title        = "Bring: " .. catName:gsub("_", " "),
        Values       = listItems,
        DefaultValue = listItems[1],
        Callback     = function(value)
            selectedCatItem = value
        end
    })
    
    Tabs.ItemTP:AddButton({
        Title    = "Execute Bring (" .. catName:gsub("_", " ") .. ")",
        Callback = function()
            local count = 0
            local hrp = getRootPart()
            if not hrp then return end
            
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if item.Name == selectedCatItem and item.Parent then
                    local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                    teleportItemSafe(item, targetPos)
                    count = count + 1
                end
            end
            OrvionLib:Notify("Success", "Berhasil menarik " .. count .. " " .. selectedCatItem, 3)
        end
    })
end

-- ==========================================
-- PLAYER TAB (WalkSpeed)
-- ==========================================
Tabs.Player:AddInput({
    Title       = "WalkSpeed",
    Default     = "16",
    Placeholder = "Set speed...",
    Callback    = function(value)
        local speed = tonumber(value)
        if speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = speed
        end
    end
})

-- ==========================================
-- NOTIFIKASI LOADED
-- ==========================================
OrvionLib:Notify("W424 Hub", "Script loaded with separated Aura & Categorized Bring!", 3)
