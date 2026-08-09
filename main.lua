-- ==========================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT (FIXED DAMAGE ID & BURN ITEM)
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
local RemoteConsume = RemoteEvents:FindFirstChild("RequestConsumeItem")
local RemoteBurn = RemoteEvents:FindFirstChild("RequestBurnItem")

local ScriptRunning = true

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportItemSafe(item, targetPos)
    if not item or not item.Parent then return end
    
    pcall(function()
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
        if not part then return end

        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.05) 

        if item:IsA("Model") then
            item:SetPrimaryPartCFrame(CFrame.new(targetPos))
        else
            part.CFrame = CFrame.new(targetPos)
        end

        if dragStop then dragStop:FireServer(item) end
    end)
end

-- ==========================================
-- BUAT WINDOW ORVION & FLOATING BUBBLE
-- ==========================================
local Window = OrvionLib:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    Icon  = ""
})

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
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
    end
end)

local Tabs = {
    Main    = Window:AddTab("Main Farm"),
    Combat  = Window:AddTab("Aura"),
    ItemTP  = Window:AddTab("Item TP"),
    Player  = Window:AddTab("Player"),
}

-- ==========================================
-- AURA & COMBAT TAB (FIXED DAMAGE ID & STRENGTHENED)
-- ==========================================
local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

-- Perbaikan: ID Damage sekarang digabung dengan LocalPlayer.UserId agar server menganggap serangan ini sah.
local toolIds = {
    ["Old Axe"] = "1", 
    ["Good Axe"] = "112",
    ["Strong Axe"] = "116",
    ["Chainsaw"] = "647",
    ["Spear"] = "196"
}

local function getAnyToolWithDamageID()
    for toolName, prefix in pairs(toolIds) do
        local tool = LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then 
            return tool, prefix .. "_" .. tostring(LocalPlayer.UserId)
        end
    end
    return nil, nil
end

Tabs.Combat:AddToggle({
    Title    = "Kill Aura (Mobs Only)",
    Default  = false,
    Callback = function(state) killAuraEnabled = state end
})

Tabs.Combat:AddToggle({
    Title    = "Aura Chop (Trees Only)",
    Default  = false,
    Callback = function(state) treeAuraEnabled = state end
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

-- 1. LOOP KILL AURA (Diperkuat)
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
                                    -- Eksekusi damage dalam thread terpisah agar tidak delay
                                    task.spawn(function()
                                        pcall(function()
                                            RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, part.CFrame)
                                        end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1) -- Jeda dikurangi dari 0.2 menjadi 0.1 agar lebih mematikan
    end
end)

-- 2. LOOP AURA CHOP (Diperbaiki Deteksi Objeknya)
task.spawn(function()
    while ScriptRunning do
        if treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                local map = Workspace:FindFirstChild("Map")
                if map and map:FindFirstChild("Foliage") then
                    for _, obj in ipairs(map.Foliage:GetChildren()) do
                        if obj:IsA("Model") then
                            local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if trunk and (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                                task.spawn(function()
                                    pcall(function()
                                        RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                            Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"), Volume = 0.4
                                        })
                                        RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, trunk.CFrame)
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ==========================================
-- MAIN FARM TAB (FIXED CAMPFIRE FEED VIA REMOTE)
-- ==========================================
local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local rawFoodsToCook = {"Morsel", "Steak"}

Tabs.Main:AddToggle({
    Title    = "Auto Eat (HP Based)",
    Default  = false,
    Callback = function(state) autoEatEnabled = state end
})

Tabs.Main:AddToggle({
    Title    = "Auto Cook Raw Food",
    Default  = false,
    Callback = function(state) autoCookEnabled = state end
})

local autoGrindItems = {}
Tabs.Main:AddDropdown({
    Title        = "Auto Machine Grind",
    Values       = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    DefaultValue = "",
    Callback     = function(value) autoGrindItems[value] = not autoGrindItems[value] end
})

local autoFuelItems = {}
Tabs.Main:AddDropdown({
    Title        = "Auto Feed Campfire",
    Values       = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    DefaultValue = "",
    Callback     = function(value) autoFuelItems[value] = not autoFuelItems[value] end
})

-- Background Worker Auto Feed & Grind
task.spawn(function()
    while ScriptRunning do
        local map = Workspace:FindFirstChild("Map")
        local campfireCenter = nil
        if map and map:FindFirstChild("Campground") and map.Campground:FindFirstChild("MainFire") then
            campfireCenter = map.Campground.MainFire:FindFirstChild("Center") or map.Campground.MainFire
        end

        local structures = Workspace:FindFirstChild("Structures")
        local machinePos = nil
        if structures and structures:FindFirstChild("Biofuel Processor") then
            local part = structures["Biofuel Processor"]:FindFirstChildWhichIsA("BasePart")
            if part then machinePos = part.Position + Vector3.new(0, 5, 0) end
        else
            machinePos = Vector3.new(21, 19, -5)
        end
        
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item and item.Parent then
                if autoGrindItems[item.Name] then
                    teleportItemSafe(item, machinePos)
                    task.wait(0.05)
                elseif autoFuelItems[item.Name] or (autoCookEnabled and table.find(rawFoodsToCook, item.Name)) then
                    -- PERBAIKAN: Gunakan RemoteBurnItem jika ada, atau teleport langsung ke Center
                    if RemoteBurn then
                        pcall(function()
                            if RemoteBurn:IsA("RemoteEvent") then
                                RemoteBurn:FireServer(item)
                            elseif RemoteBurn:IsA("RemoteFunction") then
                                RemoteBurn:InvokeServer(item)
                            end
                        end)
                    elseif campfireCenter and campfireCenter:IsA("BasePart") then
                        teleportItemSafe(item, campfireCenter.Position)
                    end
                    task.wait(0.05)
                end
            end
        end
        task.wait(1)
    end
end)

-- Background Worker Auto Eat
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
-- ITEM TP TAB (BRING TERKELOMPOK)
-- ==========================================
local itemCategories = {
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave"},
    Equipment_Weapons = {"Rifle", "Revolver", "Rifle Ammo", "Revolver Ammo", "Chainsaw", "Old Flashlight", "MedKit", "Bandage"},
    Food_Consumables = {"Berry", "Carrot", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs", "Cake"}
}

for catName, listItems in pairs(itemCategories) do
    local selectedCatItem = listItems[1]
    
    Tabs.ItemTP:AddDropdown({
        Title        = "Bring: " .. catName:gsub("_", " "),
        Values       = listItems,
        DefaultValue = listItems[1],
        Callback     = function(value) selectedCatItem = value end
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
-- PLAYER TAB
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

OrvionLib:Notify("W424 Hub", "Script updated with Fixed Damage IDs & Burn Remote!", 3)
