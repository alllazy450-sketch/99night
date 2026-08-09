-- ==========================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT (FINAL DETAILED VERSION)
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

local ScriptRunning = true

-- ==========================================
-- KOORDINAT ABSOLUT
-- ==========================================
local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)

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
    return CAMPFIRE_POS
end

local function findValidPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("MeshPart") then return child end
    end
    return nil
end

local function dragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return end
    
    local part = findValidPart(item)
    if not part then return end
    
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.05) 

        if not item:IsDescendantOf(workspace) then return end 

        if item:IsA("Model") and item.PrimaryPart then
            item:SetPrimaryPartCFrame(CFrame.new(pos))
        else
            part.CFrame = CFrame.new(pos)
        end
        
        task.wait(0.05)
        if dragStop then dragStop:FireServer(item) end
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
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

local dragging, dragInput, dragStart, startPos
local dragStartPos = Vector2.new(0, 0)
local uiVisible = true

bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = bubble.Position
        dragStartPos = input.Position
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                connection:Disconnect()
                
                if (input.Position - dragStartPos).Magnitude < 5 then
                    uiVisible = not uiVisible
                    for _, gui in ipairs(CoreGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and gui.Name ~= "W424_ToggleBubble" then
                            if gui:FindFirstChild("MainFrame") or gui:FindFirstChild("Container") or gui:FindFirstChild("Main") then
                                gui.Enabled = uiVisible
                            end
                        end
                    end
                end
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

-- ==========================================
-- TAMBAH TAB
-- ==========================================
local Tabs = {
    Main    = Window:AddTab("Main Farm"),
    Combat  = Window:AddTab("Aura"),
    ItemTP  = Window:AddTab("Item TP"),
    Visuals = Window:AddTab("Visuals (ESP)"),
    Player  = Window:AddTab("Player"),
}

-- ==========================================
-- AURA & COMBAT TAB
-- ==========================================
local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

local toolIds = {
    ["Old Axe"] = "1", ["Good Axe"] = "112", ["Strong Axe"] = "116",
    ["Chainsaw"] = "647", ["Spear"] = "196"
}

local function getAnyToolWithDamageID()
    for toolName, prefix in pairs(toolIds) do
        local tool = LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then return tool, prefix .. "_" .. tostring(LocalPlayer.UserId) end
    end
    return nil, nil
end

Tabs.Combat:AddToggle({ Title = "Kill Aura (Mobs Only)", Default = false, Callback = function(state) killAuraEnabled = state end })
Tabs.Combat:AddToggle({ Title = "Aura Chop (Trees Only)", Default = false, Callback = function(state) treeAuraEnabled = state end })

Tabs.Combat:AddInput({ Title = "Aura Radius (Angka)", Default = "200", Placeholder = "Ketik radius...", Callback = function(value)
    local num = tonumber(value)
    if num then auraRadius = num end
end})

-- 1. KILL AURA (Mobs)
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
                        local mobHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or findValidPart(mob)
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if mobHrp and hum and hum.Health > 0 then
                            if (mobHrp.Position - hrp.Position).Magnitude <= auraRadius then
                                task.spawn(function()
                                    pcall(function()
                                        RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, mobHrp.CFrame)
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- 2. AURA CHOP (DEATHMODEL 0.75s COOLDOWN SYNC)
local choppedTrees = setmetatable({}, {__mode = "k"})

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
                        if obj:IsA("Model") and obj.Parent == map.Foliage then
                            local trunk = obj:FindFirstChild("Trunk")
                            if trunk and trunk:IsA("BasePart") and (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                                
                                if not choppedTrees[obj] or (tick() - choppedTrees[obj] > 1.2) then
                                    choppedTrees[obj] = tick()
                                    
                                    task.spawn(function()
                                        pcall(function()
                                            RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"), Volume = 0.4
                                            })
                                            RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, trunk.CFrame, true)
                                        end)
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

-- ==========================================
-- MAIN FARM TAB (AUTO GRIND & AUTO COOK)
-- ==========================================
local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple", "Cake"}
local rawFoodsToCook = {"Morsel", "Steak"}

Tabs.Main:AddToggle({ Title = "Auto Eat (HP Based)", Default = false, Callback = function(state) autoEatEnabled = state end })
Tabs.Main:AddToggle({ Title = "Auto Cook Raw Food", Default = false, Callback = function(state) autoCookEnabled = state end })

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

task.spawn(function()
    while ScriptRunning do
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if item and item:IsDescendantOf(workspace) then
                if autoGrindItems[item.Name] then
                    dragItemToPos(item, MACHINE_POS)
                    task.wait(0.1)
                elseif autoFuelItems[item.Name] or (autoCookEnabled and table.find(rawFoodsToCook, item.Name)) then
                    dragItemToPos(item, getCampfirePosition())
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
                    if table.find(autoEatFoods, item.Name) and item:IsDescendantOf(workspace) then 
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
-- ITEM TP TAB (KATEGORI TERKELOMPOK DENGAN ITEM SPESIFIK PILIHAN)
-- ==========================================
local itemCategories = {
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave"},
    Weapons_Gear = {"Pistol", "Revolver", "Rifle", "Chainsaw", "Old Flashlight", "MedKit", "Bandage"},
    Food_Items = {"Berry", "Carrot", "Cake", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs"}
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
            
            for _, item in ipairs(ItemsFolder:GetDescendants()) do
                if item.Name == selectedCatItem and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                    local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                    dragItemToPos(item, targetPos)
                    count = count + 1
                end
            end
            OrvionLib:Notify("Success", "Ditarik: " .. count .. " " .. selectedCatItem, 3)
        end
    })
end

-- ==========================================
-- VISUALS (ESP) TAB
-- ==========================================
local espMobsEnabled = false
local espItemsEnabled = false
local espFolder = Instance.new("Folder")
espFolder.Name = "W424_ESP_Folder"
espFolder.Parent = CoreGui

local function createESP(instance, name, color)
    local part = findValidPart(instance)
    if not part then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = instance
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Parent = espFolder

    local bg = Instance.new("BillboardGui")
    bg.Adornee = part
    bg.Size = UDim2.new(0, 150, 0, 30)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = espFolder

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0.2
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = bg

    task.spawn(function()
        while bg.Parent and instance.Parent do
            local hrp = getRootPart()
            if hrp then
                local dist = math.floor((part.Position - hrp.Position).Magnitude)
                txt.Text = string.format("%s [%dm]", name, dist)
            end
            task.wait(0.5)
        end
        hl:Destroy()
        bg:Destroy()
    end)
end

local function refreshESP()
    espFolder:ClearAllChildren()
    if espMobsEnabled then
        local chars = Workspace:FindFirstChild("Characters")
        if chars then
            for _, mob in ipairs(chars:GetChildren()) do
                createESP(mob, mob.Name, Color3.fromRGB(255, 50, 50))
            end
        end
    end
    if espItemsEnabled then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            createESP(item, item.Name, Color3.fromRGB(50, 255, 50))
        end
    end
end

Tabs.Visuals:AddToggle({ Title = "ESP Mobs", Default = false, Callback = function(state) espMobsEnabled = state refreshESP() end })
Tabs.Visuals:AddToggle({ Title = "ESP Items", Default = false, Callback = function(state) espItemsEnabled = state refreshESP() end })

task.spawn(function()
    while ScriptRunning do
        if espMobsEnabled or espItemsEnabled then refreshESP() end
        task.wait(5)
    end
end)

-- ==========================================
-- PLAYER TAB (WALKSPEED & TP TO CAMPFIRE)
-- ==========================================
Tabs.Player:AddInput({
    Title       = "WalkSpeed (Angka)",
    Default     = "16",
    Placeholder = "Ketik speed...",
    Callback    = function(value)
        local speed = tonumber(value)
        if speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = speed
        end
    end
})

Tabs.Player:AddButton({
    Title    = "Teleport Back to Campfire",
    Callback = function()
        local hrp = getRootPart()
        if hrp then
            hrp.CFrame = CFrame.new(getCampfirePosition() + Vector3.new(0, 3, 0))
            OrvionLib:Notify("Success", "Teleported back to Campfire!", 3)
        end
    end
})

OrvionLib:Notify("W424 Hub", "Script Loaded: Fully Optimized & Campfire TP Added!", 3)
