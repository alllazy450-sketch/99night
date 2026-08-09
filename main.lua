-- =============================================
-- W424 - 99 NIGHTS ULTIMATE SCRIPT
-- All-in-one cheat for 99 Nights in the Forest
-- UI: Rayfield (Fluent)
-- Features: Kill Aura (BRUTAL), ESP, Teleport, Auto Farm, Player Mods, etc.
-- =============================================

-- =============================================
-- 1. LOAD UI LIBRARY (Rayfield)
-- =============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then
    warn("Failed to load Rayfield, trying backup...")
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end
if not Rayfield then
    error("Could not load Rayfield UI Library.")
end

-- =============================================
-- 2. SERVICES & GLOBALS
-- =============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = RemoteEvents:FindFirstChild("RequestConsumeItem") or RemoteEvents:WaitForChild("RequestConsumeItem")

-- Flag untuk loop dan cleanup
local ScriptRunning = true
local AllConnections = {}

local function trackConnection(conn)
    if conn then table.insert(AllConnections, conn) end
    return conn
end

local function disconnectAll()
    for _, conn in ipairs(AllConnections) do
        pcall(function()
            if conn and conn.Connected then conn:Disconnect() end
        end)
    end
    AllConnections = {}
end

-- Helper: get root part of local player
local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Helper: find any BasePart inside a model/instance recursively
local function findPartDeep(container, partName)
    if not container then return nil end
    for _, descendant in ipairs(container:GetDescendants()) do
        if descendant:IsA("BasePart") and (partName == nil or descendant.Name == partName) then
            return descendant
        end
    end
    return nil
end

-- Helper: get campfire position dynamically
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

-- Helper: get biofuel/machine position dynamically
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

-- Update dynamic positions
campfireDropPos = getCampfirePosition()
machineDropPos = getMachinePosition()

-- =============================================
-- 3. CREATE UI WINDOW
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "W424 - 99 Nights",
    SubTitle = "All-in-one | by W424",
    Theme = "Dark",
    Acrylic = false,
    Resize = true,
    Size = UDim2.fromOffset(700, 500),
    TabWidth = 160,
    MinimizeKey = Enum.KeyCode.RightControl,
    MinSize = Vector2.new(470, 380),
})

-- =============================================
-- 4. TABS
-- =============================================
local MainTab = Window:CreateTab({ Title = "Main", Icon = "phosphor-hammer-bold" })
local ESPTab = Window:CreateTab({ Title = "ESP", Icon = "phosphor-eye-bold" })
local ItemTPTab = Window:CreateTab({ Title = "Item TP", Icon = "phosphor-package-bold" })
local GameTPTab = Window:CreateTab({ Title = "Game TP", Icon = "phosphor-map-pin-bold" })
local MobTPTab = Window:CreateTab({ Title = "Mob TP", Icon = "phosphor-robot" })
local PlayerTab = Window:CreateTab({ Title = "Player", Icon = "phosphor-user-bold" })
local VisualTab = Window:CreateTab({ Title = "Visuals", Icon = "phosphor-palette" })
local MiscTab = Window:CreateTab({ Title = "Misc", Icon = "phosphor-cube" })

-- =============================================
-- 5. MAIN TAB - Kill Aura (BRUTAL)
-- =============================================
MainTab:CreateSection("🔥 Kill Aura (BRUTAL)")

local killAuraEnabled = false
local killAuraRadius = 200
local killAuraConnection = nil

-- Supported weapons and damage IDs (from source)
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
        if tool then
            return tool, damageID
        end
    end
    return nil, nil
end

local function equipTool(tool)
    if tool then
        pcall(function()
            RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
        end)
    end
end

local function unequipTool(tool)
    if tool then
        pcall(function()
            RemoteEvents.UnequipItemHandle:FireServer("FireAllClients", tool)
        end)
    end
end

local function startKillAura()
    if killAuraConnection then return end
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not killAuraEnabled then return end
        local hrp = getRootPart()
        if not hrp then return end
        
        local tool, damageID = getAnyToolWithDamageID()
        if not tool or not damageID then
            return
        end
        
        equipTool(tool)
        
        -- Scan all mobs in Characters folder
        local characters = Workspace:FindFirstChild("Characters")
        if characters then
            for _, mob in ipairs(characters:GetChildren()) do
                if mob:IsA("Model") then
                    local humanoid = mob:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = mob:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= killAuraRadius then
                            pcall(function()
                                RemoteEvents.ToolDamageObject:InvokeServer(
                                    mob,
                                    tool,
                                    damageID,
                                    CFrame.new(part.Position)
                                )
                            end)
                        end
                    end
                end
            end
        end
    end)
    trackConnection(killAuraConnection)
end

local function stopKillAura()
    if killAuraConnection then
        killAuraConnection:Disconnect()
        killAuraConnection = nil
    end
end

MainTab:CreateToggle({
    Name = "Enable Kill Aura (BRUTAL)",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        killAuraEnabled = Value
        if Value then
            startKillAura()
        else
            stopKillAura()
        end
    end
})

MainTab:CreateSlider({
    Name = "Kill Aura Radius",
    Range = {20, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "KillAuraRadius",
    Callback = function(Value)
        killAuraRadius = Value
    end
})

-- =============================================
-- 6. MAIN TAB - Auto Farm Features
-- =============================================
MainTab:CreateSection("⚡ Auto Farm")

-- Auto Generator
local autoGenEnabled = false
local autoGenMode = "great" -- atau "normal"

MainTab:CreateToggle({
    Name = "Auto Complete Generators",
    CurrentValue = false,
    Flag = "AutoGenerator",
    Callback = function(Value)
        autoGenEnabled = Value
    end
})

MainTab:CreateDropdown({
    Name = "Generator Mode",
    Options = {"Great (Fast)", "Normal (Slow)"},
    CurrentOption = "Great (Fast)",
    Flag = "GeneratorMode",
    Callback = function(Option)
        autoGenMode = (Option == "Great (Fast)") and "great" or "normal"
    end
})

-- Auto Eat (3s interval)
local autoEatEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}

MainTab:CreateToggle({
    Name = "Auto Eat (3s interval)",
    CurrentValue = false,
    Flag = "AutoEat",
    Callback = function(Value)
        autoEatEnabled = Value
    end
})

-- Auto Eat (HP based)
local autoEatHPEnabled = false

MainTab:CreateToggle({
    Name = "Auto Eat (HP based)",
    CurrentValue = false,
    Flag = "AutoEatHP",
    Callback = function(Value)
        autoEatHPEnabled = Value
    end
})

-- Auto Feed Campfire (Always)
local alwaysFeedEnabledItems = {}
MainTab:CreateDropdown({
    Name = "Auto Feed Campfire (Always)",
    Values = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    Multi = true,
    Default = {},
    Flag = "AlwaysFeed",
    Callback = function(Value)
        alwaysFeedEnabledItems = Value
    end
})

-- Auto Feed Campfire (HP based)
local autoFuelEnabledItems = {}
MainTab:CreateDropdown({
    Name = "Auto Feed Campfire (HP based)",
    Values = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    Multi = true,
    Default = {},
    Flag = "HPFeed",
    Callback = function(Value)
        autoFuelEnabledItems = Value
    end
})

-- Auto Cook
local autoCookEnabledItems = {}
MainTab:CreateDropdown({
    Name = "Auto Cook Food",
    Values = {"Morsel", "Steak"},
    Multi = true,
    Default = {},
    Flag = "AutoCook",
    Callback = function(Value)
        autoCookEnabledItems = Value
    end
})

-- Auto Grind
local autoGrindEnabledItems = {}
local autoGrindItems = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Cultist Experiment", "Cultist Component", "Gem of the Forest Fragment", "Broken Microwave"}
MainTab:CreateDropdown({
    Name = "Auto Machine Grind",
    Values = autoGrindItems,
    Multi = true,
    Default = {},
    Flag = "AutoGrind",
    Callback = function(Value)
        autoGrindEnabledItems = Value
    end
})

-- Auto Biofuel
local autoBiofuelEnabledItems = {}
local biofuelItems = {"Carrot", "Cooked Morsel", "Morsel", "Steak", "Cooked Steak", "Log"}
MainTab:CreateDropdown({
    Name = "Auto Biofuel Processor",
    Values = biofuelItems,
    Multi = true,
    Default = {},
    Flag = "AutoBiofuel",
    Callback = function(Value)
        autoBiofuelEnabledItems = Value
    end
})

-- =============================================
-- 7. ESP TAB
-- =============================================
ESPTab:CreateSection("👁️ Player ESP")

local espEnabled = false
local chamsEnabled = false
local espTransparency = 0.4
local teamCheck = true

-- Billboard ESP
local BillboardESPs = {}
local ESPConnections = {}

local function createBillboardESP(plr)
    if BillboardESPs[plr] or plr == LocalPlayer then return end
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end
    
    local gui = Instance.new("BillboardGui")
    gui.Name = "Billboard_ESP"
    gui.Adornee = plr.Character.Head
    gui.Parent = plr.Character.Head
    gui.Size = UDim2.new(0, 100, 0, 40)
    gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel")
    label.Parent = gui
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    
    local conn = RunService.RenderStepped:Connect(function()
        if not plr.Character or not plr.Character:FindFirstChild("Humanoid") then
            gui:Destroy()
            if conn then conn:Disconnect() end
            BillboardESPs[plr] = nil
            ESPConnections[plr] = nil
            return
        end
        local hp = math.floor(plr.Character.Humanoid.Health / plr.Character.Humanoid.MaxHealth * 100)
        label.Text = plr.Name .. " | " .. hp .. "%"
    end)
    
    BillboardESPs[plr] = gui
    ESPConnections[plr] = conn
end

local function cleanupBillboardESP()
    for _, gui in pairs(BillboardESPs) do
        if gui then gui:Destroy() end
    end
    for _, conn in pairs(ESPConnections) do
        if conn then conn:Disconnect() end
    end
    BillboardESPs = {}
    ESPConnections = {}
end

-- Chams ESP
local ChamsESPs = {}
local function createChamsESP(plr)
    if ChamsESPs[plr] or plr == LocalPlayer then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local folder = Instance.new("Folder")
    folder.Name = "Chams_ESP"
    folder.Parent = CoreGui
    ChamsESPs[plr] = folder
    
    for _, part in ipairs(plr.Character:GetChildren()) do
        if part:IsA("BasePart") then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "Cham_" .. plr.Name
            box.Adornee = part
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Size = part.Size
            box.Transparency = espTransparency
            local color = teamCheck and (plr.TeamColor == LocalPlayer.TeamColor and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)) or Color3.fromRGB(255,255,255)
            box.Color3 = color
            box.Parent = folder
        end
    end
end

local function cleanupChamsESP()
    for _, folder in pairs(ChamsESPs) do
        if folder then folder:Destroy() end
    end
    ChamsESPs = {}
end

local function handlePlayerESP(plr)
    if espEnabled then createBillboardESP(plr) end
    if chamsEnabled then createChamsESP(plr) end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then createBillboardESP(plr) end
        if chamsEnabled then createChamsESP(plr) end
    end)
end

ESPTab:CreateToggle({
    Name = "ESP (Billboard)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            cleanupBillboardESP()
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    createBillboardESP(plr)
                end
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Chams",
    CurrentValue = false,
    Flag = "Chams",
    Callback = function(Value)
        chamsEnabled = Value
        if not Value then
            cleanupChamsESP()
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    createChamsESP(plr)
                end
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Team Check (Green/Red)",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        teamCheck = Value
        if chamsEnabled then
            cleanupChamsESP()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    createChamsESP(plr)
                end
            end
        end
    end
})

ESPTab:CreateSlider({
    Name = "ESP Transparency",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.4,
    Flag = "ESPTransparency",
    Callback = function(Value)
        espTransparency = Value
        if chamsEnabled then
            cleanupChamsESP()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    createChamsESP(plr)
                end
            end
        end
    end
})

-- Item ESP
local itemEspEnabled = false
local itemEspConnections = {}
local itemNames = {
    ["Revolver"] = true, ["Oil Barrel"] = true, ["Chainsaw"] = true, ["Giant Sack"] = true,
    ["Bunny Foot"] = true, ["MedKit"] = true, ["Alien Chest"] = true, ["Berry"] = true,
    ["Bolt"] = true, ["Broken Fan"] = true, ["Carrot"] = true, ["Coal"] = true,
    ["Coin Stack"] = true, ["Hologram Emitter"] = true, ["Item Chest"] = true,
    ["Laser Fence Blueprint"] = true, ["Log"] = true, ["Old Flashlight"] = true,
    ["Old Radio"] = true, ["Sheet Metal"] = true, ["Bandage"] = true, ["Rifle"] = true
}

local function createItemESP(model)
    if not model:IsA("Model") or not itemNames[model.Name] then return end
    if not model.PrimaryPart or model:FindFirstChild("ESP") then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.Adornee = model.PrimaryPart
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextSize = 17
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(0, 1, 0)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = false
    label.Font = Enum.Font.GothamBold
    label.Text = model.Name
    label.Parent = billboard
    billboard.Parent = model
end

local function removeAllItemESP()
    for _, model in ItemsFolder:GetChildren() do
        local esp = model:FindFirstChild("ESP")
        if esp then esp:Destroy() end
    end
end

ESPTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Flag = "ItemESP",
    Callback = function(Value)
        itemEspEnabled = Value
        if Value then
            for _, model in ItemsFolder:GetChildren() do
                createItemESP(model)
            end
            local conn = ItemsFolder.ChildAdded:Connect(function(model)
                if model:IsA("Model") and itemNames[model.Name] then
                    model:GetPropertyChangedSignal("PrimaryPart"):Wait()
                    createItemESP(model)
                end
            end)
            table.insert(itemEspConnections, conn)
        else
            removeAllItemESP()
            for _, conn in ipairs(itemEspConnections) do
                if conn and conn.Disconnect then conn:Disconnect() end
            end
            itemEspConnections = {}
        end
    end
})

-- =============================================
-- 8. ITEM TP TAB
-- =============================================
ItemTPTab:CreateSection("📦 Teleport to Item")

local itemFolder = ItemsFolder
local itemList = {
    "Revolver", "MedKit", "Alien Chest", "Berry", "Bolt", "Broken Fan",
    "Carrot", "Coal", "Coin Stack", "Hologram Emitter", "Item Chest",
    "Laser Fence Blueprint", "Log", "Old Flashlight", "Old Radio",
    "Sheet Metal", "Bandage", "Rifle"
}

local function getModelPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

local dropdownTP = ItemTPTab:CreateDropdown({
    Name = "Select Item",
    Values = itemList,
    Multi = false,
    Default = itemList[1],
    Flag = "ItemTPSelect"
})

ItemTPTab:CreateButton({
    Name = "Teleport to Selected Item",
    Callback = function()
        local selected = dropdownTP.Value
        if not selected then return end
        local candidates = {}
        for _, model in pairs(itemFolder:GetChildren()) do
            if model:IsA("Model") and model.Name == selected then
                local part = getModelPart(model)
                if part then table.insert(candidates, part) end
            end
        end
        if #candidates == 0 then
            warn("No " .. selected .. " found.")
            return
        end
        local targetPart = candidates[math.random(1, #candidates)]
        local hrp = getRootPart()
        if hrp then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
        end
    end
})

ItemTPTab:CreateSection("📦 Bring Item to You")

local function teleportItem(itemName)
    local count = 0
    local sources = {
        ItemsFolder,
        ReplicatedStorage:FindFirstChild("TempStorage")
    }
    for _, source in ipairs(sources) do
        if not source then continue end
        for _, item in ipairs(source:GetChildren()) do
            if item.Name == itemName then
                local targetPart = nil
                for _, child in ipairs(item:GetDescendants()) do
                    if child:IsA("MeshPart") or child:IsA("Part") then
                        targetPart = child
                        break
                    end
                end
                if targetPart then
                    pcall(function()
                        RemoteEvents.RequestStartDraggingItem:FireServer(item)
                        local offset = Vector3.new(0, count * 2, 0)
                        targetPart.CFrame = rootPart.CFrame + offset
                        RemoteEvents.StopDraggingItem:FireServer(item)
                    end)
                    count = count + 1
                end
            end
        end
    end
    print("Moved " .. count .. " " .. itemName .. "(s)")
end

local bringItemList = {
    "Alien Chest", "Alpha Wolf Pelt", "Anvil Front", "Anvil Back", "Apple",
    "Bandage", "Bear Corpse", "Bear Pelt", "Berry", "Biofuel", "Bolt",
    "Broken Fan", "Bunny Foot", "Carrot", "Coal", "Coin Stack",
    "Cooked Morsel", "Cooked Steak", "Chainsaw", "Cultist", "Cultist Gem",
    "Flower", "Fuel Canister", "Hologram Emitter", "Item Chest",
    "Laser Fence Blueprint", "Leather Body", "Iron Body", "Thorn Body",
    "Log", "MedKit", "Morsel", "Old Flashlight", "Old Radio",
    "Good Sack", "Good Axe", "Raygun", "Giant Sack", "Strong Axe",
    "Oil Barrel", "Old Car Engine", "Rifle", "Rifle Ammo", "Revolver",
    "Revolver Ammo", "Sapling", "Sheet Metal", "Steak", "Wolf Pelt",
    "Gem of the Forest Fragment", "Tyre", "Washing Machine", "Broken Microwave"
}

local bringDropdown = ItemTPTab:CreateDropdown({
    Name = "Select Item to Bring",
    Values = bringItemList,
    Multi = false,
    Default = bringItemList[1],
    Flag = "BringItemSelect"
})

ItemTPTab:CreateButton({
    Name = "Bring Selected Item",
    Callback = function()
        local selected = bringDropdown.Value
        if selected then
            teleportItem(selected)
        end
    end
})

-- =============================================
-- 9. GAME TP TAB
-- =============================================
GameTPTab:CreateSection("🚀 Location Teleports")

local function teleportToTarget(cf, duration)
    local hrp = getRootPart()
    if not hrp then return end
    if duration and duration > 0 then
        local info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, info, {CFrame = cf})
        tween:Play()
    else
        hrp.CFrame = cf
    end
end

local storyCoords = {
    {"Campsite", "0, 8, -0"},
    {"Safe Zone", "0, 110, -0"},
    {"Stronghold", "50, 10, 20"},
    {"Cave Entrance", "100, 5, -30"}
}

for _, entry in ipairs(storyCoords) do
    local name, coord = entry[1], entry[2]
    local x, y, z = coord:match("([^,]+),%s*([^,]+),%s*([^,]+)")
    GameTPTab:CreateButton({
        Name = "TP to " .. name,
        Callback = function()
            teleportToTarget(CFrame.new(tonumber(x), tonumber(y), tonumber(z)), 0.1)
        end
    })
end

-- =============================================
-- 10. MOB TP TAB
-- =============================================
MobTPTab:CreateSection("🦴 Teleport Mob to You")

local characterFolder = Workspace:FindFirstChild("Characters")
local possibleCharacters = {
    "Alpha Wolf", "Bear", "Lost Child", "Lost Child2", "Lost Child3",
    "Lost Child4", "Wolf", "Bunny", "Cultist", "Alien"
}

local function getMainPart(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

local function teleportCharacter(characterName)
    if not characterFolder then return end
    local count = 0
    local stackOffsetY = 3
    for _, model in ipairs(characterFolder:GetChildren()) do
        if model.Name == characterName then
            local mainPart = getMainPart(model)
            if mainPart and rootPart then
                local targetCFrame = rootPart.CFrame + Vector3.new(0, count * stackOffsetY, 0)
                if model.PrimaryPart then
                    model:SetPrimaryPartCFrame(targetCFrame)
                else
                    mainPart.CFrame = targetCFrame
                end
                count = count + 1
            end
        end
    end
    print("Brought " .. count .. " " .. characterName .. "(s)")
end

local mobDropdown = MobTPTab:CreateDropdown({
    Name = "Select Mob",
    Values = possibleCharacters,
    Multi = false,
    Default = possibleCharacters[1],
    Flag = "MobSelect"
})

MobTPTab:CreateButton({
    Name = "Bring Selected Mob",
    Callback = function()
        local selected = mobDropdown.Value
        if selected then
            teleportCharacter(selected)
        end
    end
})

-- =============================================
-- 11. PLAYER TAB
-- =============================================
PlayerTab:CreateSection("🏃 Movement")

local hackedWalkSpeed = 16

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        hackedWalkSpeed = Value
        if humanoid then
            humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 700},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        if humanoid then
            humanoid.JumpPower = Value
        end
    end
})

-- Noclip
local noclipEnabled = false
local noclipConnection = nil

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        noclipEnabled = Value
        if Value then
            noclipConnection = RunService.Stepped:Connect(function()
                if not character then return end
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- Infinite Jump
local infJumpEnabled = false
PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        infJumpEnabled = Value
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- =============================================
-- 12. VISUAL TAB
-- =============================================
VisualTab:CreateSection("🌞 Visuals")

-- Fullbright
local fullbrightEnabled = false
local origBrightness = Lighting.Brightness
local origAmbient = Lighting.Ambient
local origShadows = Lighting.GlobalShadows

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(Value)
        fullbrightEnabled = Value
        if Value then
            Lighting.Brightness = 5
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = origBrightness
            Lighting.Ambient = origAmbient
            Lighting.GlobalShadows = origShadows
        end
    end
})

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Transparency = 1
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.ZIndex = 2
local fovRadius = 100

VisualTab:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "FOVCircle",
    Callback = function(Value)
        fovCircle.Visible = Value
    end
})

VisualTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 200},
    Increment = 10,
    CurrentValue = 100,
    Flag = "FOVRadius",
    Callback = function(Value)
        fovRadius = Value
    end
})

RunService.RenderStepped:Connect(function()
    if fovCircle.Visible then
        fovCircle.Radius = fovRadius
        fovCircle.Position = UserInputService:GetMouseLocation()
    end
end)

-- =============================================
-- 13. MISC TAB
-- =============================================
MiscTab:CreateSection("🔧 Extra Scripts")

-- Anti-AFK
local antiAFKEnabled = false
local antiAFKConnection = nil

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        antiAFKEnabled = Value
        if Value then
            antiAFKConnection = UserInputService.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
        else
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
                antiAFKConnection = nil
            end
        end
    end
})

-- Infinite Yield (loadstring)
MiscTab:CreateButton({
    Name = "Load Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

-- Emote GUI
MiscTab:CreateButton({
    Name = "Load Emote GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/dimension-sources/random-scripts-i-found/refs/heads/main/r6%20animations"))()
    end
})

-- Turtle Spy
MiscTab:CreateButton({
    Name = "Load Turtle Spy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Turtle-Brand/Turtle-Spy/main/source.lua", true))()
    end
})

-- =============================================
-- 14. AUTO FARM BACKGROUND COROUTINES
-- =============================================

-- Auto Generator Loop
task.spawn(function()
    while ScriptRunning do
        task.wait(0.2)
        if not autoGenEnabled then continue end
        
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if not remotes then return end
            local genRemotes = remotes:FindFirstChild("Generator")
            if not genRemotes then return end
            local repairEvent = genRemotes:FindFirstChild("RepairEvent")
            local skillCheckEvent = genRemotes:FindFirstChild("SkillCheckResultEvent")
            if not repairEvent or not skillCheckEvent then return end
            
            local map = Workspace:FindFirstChild("Map")
            if not map then return end
            
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Generator" then
                    for _, point in ipairs(obj:GetChildren()) do
                        if point.Name:find("GeneratorPoint") then
                            pcall(function()
                                repairEvent:FireServer(point, true)
                                local result = (autoGenMode == "great") and "success" or "neutral"
                                local value = (autoGenMode == "great") and 1 or 0
                                skillCheckEvent:FireServer(result, value, obj, point)
                            end)
                        end
                    end
                end
            end
        end)
    end
end)

-- Auto Eat (3s interval)
task.spawn(function()
    while ScriptRunning do
        task.wait(3)
        if not autoEatEnabled then continue end
        
        local available = {}
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            if table.find(autoEatFoods, item.Name) then
                table.insert(available, item)
            end
        end
        if #available > 0 then
            local food = available[math.random(1, #available)]
            pcall(function()
                RemoteConsume:InvokeServer(food)
            end)
        end
    end
end)

-- Auto Eat (HP based)
task.spawn(function()
    while ScriptRunning do
        if autoEatHPEnabled then
            local campfire = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Campground") and Workspace.Map.Campground:FindFirstChild("MainFire")
            if campfire then
                local fillFrame = campfire:FindFirstChild("Center") and campfire.Center:FindFirstChild("BillboardGui") and campfire.Center.BillboardGui:FindFirstChild("Frame") and campfire.Center.BillboardGui.Frame:FindFirstChild("Background") and campfire.Center.BillboardGui.Frame.Background:FindFirstChild("Fill")
                if fillFrame and fillFrame.Size.X.Scale < 0.7 then
                    local available = {}
                    for _, item in ipairs(ItemsFolder:GetChildren()) do
                        if table.find(autoEatFoods, item.Name) then
                            table.insert(available, item)
                        end
                    end
                    if #available > 0 then
                        local food = available[math.random(1, #available)]
                        pcall(function()
                            RemoteConsume:InvokeServer(food)
                        end)
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- Auto Feed Campfire (Always)
task.spawn(function()
    while ScriptRunning do
        for itemName, enabled in pairs(alwaysFeedEnabledItems) do
            if enabled then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item.Name == itemName then
                        pcall(function()
                            local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                            if part then
                                part.CFrame = CFrame.new(campfireDropPos)
                            end
                        end)
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- Auto Feed Campfire (HP based)
task.spawn(function()
    while ScriptRunning do
        local campfire = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Campground") and Workspace.Map.Campground:FindFirstChild("MainFire")
        if campfire then
            local fillFrame = campfire:FindFirstChild("Center") and campfire.Center:FindFirstChild("BillboardGui") and campfire.Center.BillboardGui:FindFirstChild("Frame") and campfire.Center.BillboardGui.Frame:FindFirstChild("Background") and campfire.Center.BillboardGui.Frame.Background:FindFirstChild("Fill")
            if fillFrame and fillFrame.Size.X.Scale < 0.7 then
                for itemName, enabled in pairs(autoFuelEnabledItems) do
                    if enabled then
                        for _, item in ipairs(ItemsFolder:GetChildren()) do
                            if item.Name == itemName then
                                pcall(function()
                                    local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                                    if part then
                                        part.CFrame = CFrame.new(campfireDropPos)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- Auto Cook
task.spawn(function()
    while ScriptRunning do
        for itemName, enabled in pairs(autoCookEnabledItems) do
            if enabled then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item.Name == itemName then
                        pcall(function()
                            local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                            if part then
                                part.CFrame = CFrame.new(campfireDropPos)
                            end
                        end)
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)

-- Auto Grind
task.spawn(function()
    while ScriptRunning do
        for itemName, enabled in pairs(autoGrindEnabledItems) do
            if enabled then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item.Name == itemName then
                        pcall(function()
                            local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                            if part then
                                part.CFrame = CFrame.new(machineDropPos)
                            end
                        end)
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)

-- Auto Biofuel
task.spawn(function()
    while ScriptRunning do
        for itemName, enabled in pairs(autoBiofuelEnabledItems) do
            if enabled then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if item.Name == itemName then
                        pcall(function()
                            local part = item:FindFirstChildWhichIsA("BasePart") or item.PrimaryPart
                            if part then
                                part.CFrame = CFrame.new(machineDropPos)
                            end
                        end)
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)

-- =============================================
-- 15. INIT PLAYER ESP ON JOIN
-- =============================================
Players.PlayerAdded:Connect(function(plr)
    if espEnabled then
        task.wait(1)
        createBillboardESP(plr)
    end
    if chamsEnabled then
        task.wait(1)
        createChamsESP(plr)
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        if espEnabled then createBillboardESP(plr) end
        if chamsEnabled then createChamsESP(plr) end
    end
end

-- =============================================
-- 16. UNLOAD / CLEANUP
-- =============================================
local function unloadScript()
    ScriptRunning = false
    stopKillAura()
    cleanupBillboardESP()
    cleanupChamsESP()
    removeAllItemESP()
    if noclipConnection then noclipConnection:Disconnect() end
    if antiAFKConnection then antiAFKConnection:Disconnect() end
    disconnectAll()
    pcall(function() Rayfield:Destroy() end)
end

-- Tambahkan tombol unload di UI
MiscTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        unloadScript()
    end
})

-- =============================================
-- 17. NOTIFICATION LOADED
-- =============================================
Rayfield:Notify({
    Title = "W424 Loaded",
    Content = "All features ready!",
    Duration = 3
})

print("W424 - 99 Nights Ultimate Script loaded successfully!")
print("Kill Aura (BRUTAL) is ready. Use with caution!")

-- =============================================
-- END OF SCRIPT
-- =============================================