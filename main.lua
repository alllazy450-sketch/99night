local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
if not Fluent then warn("Gagal memuat Fluent UI!") return end

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "99 Nights in the Forest | W424 Hub",
    SubTitle = "script by lohjc & W424 Team",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Auto = Window:AddTab({ Title = "Auto Farm", Icon = "sparkles" }),
    ItemTP = Window:AddTab({ Title = "Item TP / ESP", Icon = "box" }),
    GameTP = Window:AddTab({ Title = "Game TP", Icon = "map-pin" }),
    MobTP = Window:AddTab({ Title = "Mob TP", Icon = "skull" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local function getCharacterInfo()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, hrp
end

-- ==========================================
-- 1. MAIN TAB & SAFE ZONE
-- ==========================================
local safezoneBaseplates = {}
local baseplateSize = Vector3.new(2048, 1, 2048)
local baseY = 100
local centerPos = Vector3.new(0, baseY, 0)

for dx = -1, 1 do
    for dz = -1, 1 do
        local pos = centerPos + Vector3.new(dx * baseplateSize.X, 0, dz * baseplateSize.Z)
        local baseplate = Instance.new("Part")
        baseplate.Name = "SafeZoneBaseplate"
        baseplate.Size = baseplateSize
        baseplate.Position = pos
        baseplate.Anchored = true
        baseplate.CanCollide = false
        baseplate.Transparency = 1
        baseplate.Color = Color3.fromRGB(255, 255, 255)
        baseplate.Parent = workspace
        table.insert(safezoneBaseplates, baseplate)
    end
end

Tabs.Main:AddToggle("ShowSafeZone", {
    Title = "Show Safe Zone",
    Default = false,
    Callback = function(enabled)
        for _, baseplate in ipairs(safezoneBaseplates) do
            baseplate.Transparency = enabled and 0.8 or 1
            baseplate.CanCollide = enabled
        end
    end
})

-- KILL AURA
local killAuraToggle = false
local killAuraRadius = 200

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getAnyToolWithDamageID()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return nil, nil end
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = inventory:FindFirstChild(toolName)
        if tool then return tool, damageID end
    end
    return nil, nil
end

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function killAuraLoop()
    while killAuraToggle do
        local _, hrp = getCharacterInfo()
        if hrp then
            local tool, damageID = getAnyToolWithDamageID()
            if tool and damageID then
                pcall(function() remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                local mobs = workspace:FindFirstChild("Characters")
                if mobs then
                    for _, mob in ipairs(mobs:GetChildren()) do
                        if mob:IsA("Model") then
                            local part = mob:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= killAuraRadius then
                                pcall(function()
                                    remoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

Tabs.Main:AddToggle("KillAura", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(state)
        killAuraToggle = state
        if state then task.spawn(killAuraLoop) end
    end
})

Tabs.Main:AddSlider("KillAuraRadius", {
    Title = "Kill Aura Radius",
    Default = 200,
    Min = 20,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        killAuraRadius = value
    end
})

-- ==========================================
-- 2. GAME TP TAB
-- ==========================================
local function stringToCFrame(str)
    local x, y, z = str:match("([^,]+),%s*([^,]+),%s*([^,]+)")
    return CFrame.new(tonumber(x), tonumber(y), tonumber(z))
end

local function teleportToTarget(cf)
    local _, hrp = getCharacterInfo()
    if hrp then hrp.CFrame = cf end
end

Tabs.GameTP:AddButton({
    Title = "Teleport to Campsite",
    Callback = function() teleportToTarget(stringToCFrame("0, 8, 0")) end
})

Tabs.GameTP:AddButton({
    Title = "Teleport to Safezone",
    Callback = function() teleportToTarget(stringToCFrame("0, 110, 0")) end
})

Tabs.GameTP:AddButton({
    Title = "Teleport to Stronghold",
    Callback = function()
        local targetPart = workspace:FindFirstChild("Map")
            and workspace.Map:FindFirstChild("Landmarks")
            and workspace.Map.Landmarks:FindFirstChild("Stronghold")
            and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional")
            and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("EntryDoors")
            and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors:FindFirstChild("DoorRight")
            and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors.DoorRight:FindFirstChild("Model")
        if targetPart then
            local children = targetPart:GetChildren()
            local destination = children[5]
            if destination and destination:IsA("BasePart") then
                teleportToTarget(destination.CFrame + Vector3.new(0, 5, 0))
            end
        end
    end
})

Tabs.GameTP:AddButton({
    Title = "Teleport to Diamond Chest",
    Callback = function()
        local items = workspace:FindFirstChild("Items")
        if not items then return end
        local chest = items:FindFirstChild("Stronghold Diamond Chest")
        if not chest then return end
        local chestLid = chest:FindFirstChild("ChestLid")
        if not chestLid then return end
        local diamondchest = chestLid:FindFirstChild("Meshes/diamondchest_Cube.002")
        if diamondchest then teleportToTarget(diamondchest.CFrame + Vector3.new(0, 5, 0)) end
    end
})

-- ==========================================
-- 3. ITEM TP & ESP TAB
-- ==========================================
local itemFolder = workspace:WaitForChild("Items")

Tabs.ItemTP:AddToggle("ItemESP", {
    Title = "Item ESP",
    Default = false,
    Callback = function(state)
        local itemNames = {
            ["Revolver"] = true, ["Oil Barrel"] = true, ["Chainsaw"] = true, ["Giant Sack"] = true,
            ["Bunny Foot"] = true, ["MedKit"] = true, ["Alien Chest"] = true, ["Berry"] = true,
            ["Bolt"] = true, ["Broken Fan"] = true, ["Carrot"] = true, ["Coal"] = true,
            ["Coin Stack"] = true, ["Hologram Emitter"] = true, ["Item Chest"] = true,
            ["Laser Fence Blueprint"] = true, ["Log"] = true, ["Old Flashlight"] = true,
            ["Old Radio"] = true, ["Sheet Metal"] = true, ["Bandage"] = true, ["Rifle"] = true
        }

        local function createESP(model)
            if not model:IsA("Model") or not itemNames[model.Name] then return end
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if not part or model:FindFirstChild("ESP") then return end

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP"
            billboard.Size = UDim2.new(0, 100, 0, 30)
            billboard.Adornee = part
            billboard.AlwaysOnTop = true
            billboard.StudsOffset = Vector3.new(0, 3, 0)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.TextSize = 14
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0.5
            label.Text = model.Name
            label.Parent = billboard
            billboard.Parent = model
        end

        if state then
            for _, model in ipairs(itemFolder:GetChildren()) do createESP(model) end
        else
            for _, model in ipairs(itemFolder:GetChildren()) do
                local esp = model:FindFirstChild("ESP")
                if esp then esp:Destroy() end
            end
        end
    end
})

local itemNamesList = {
    "Revolver", "Medkit", "Alien Chest", "Berry", "Bolt", "Broken Fan",
    "Carrot", "Coal", "Coin Stack", "Hologram Emitter", "Item Chest",
    "Laser Fence Blueprint", "Log", "Old Flashlight", "Old Radio",
    "Sheet Metal", "Bandage", "Rifle"
}

Tabs.ItemTP:AddDropdown("TPToItem", {
    Title = "Teleport to Item",
    Values = itemNamesList,
    Multi = false,
    Default = 1,
    Callback = function(itemName)
        local candidates = {}
        for _, model in pairs(itemFolder:GetChildren()) do
            if model:IsA("Model") and model.Name == itemName then
                local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if part then table.insert(candidates, part) end
            end
        end
        if #candidates > 0 then
            local targetPart = candidates[math.random(1, #candidates)]
            teleportToTarget(targetPart.CFrame + Vector3.new(0, 5, 0))
        end
    end
})

local possibleItems = {
    "Alien Chest","Alpha Wolf Pelt","Anvil Front","Anvil Back","Apple","Bandage",
    "Bear Corpse","Bear Pelt","Berry","Biofuel","Bolt","Broken Fan","Bunny Foot",
    "Carrot","Coal","Coin Stack","Cooked Morsel","Cooked Steak","Chainsaw","Cultist",
    "Cultist Gem","Flower","Fuel Canister","Hologram Emitter","Item Chest",
    "Laser Fence Blueprint","Leather Body","Iron Body","Thorn Body","Log","MedKit",
    "Morsel","Old Flashlight","Old Radio","Good Sack","Good Axe","Raygun","Giant Sack",
    "Strong Axe","Oil Barrel","Old Car Engine","Rifle","Rifle Ammo","Revolver",
    "Revolver Ammo","Sapling","Sheet Metal","Steak","Wolf Pelt","Gem of the Forest Fragment",
    "Tyre","Washing Machine","Broken Microwave"
}

Tabs.ItemTP:AddDropdown("BringBulkItem", {
    Title = "Bring Item to You (Bulk)",
    Values = possibleItems,
    Multi = false,
    Default = 1,
    Callback = function(itemName)
        local _, hrp = getCharacterInfo()
        if not hrp then return end
        local count = 0
        for _, item in ipairs(itemFolder:GetChildren()) do
            if item.Name == itemName then
                local targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    pcall(function()
                        remoteEvents.RequestStartDraggingItem:FireServer(item)
                        targetPart.CFrame = hrp.CFrame + Vector3.new(0, count * 2, 0)
                        remoteEvents.StopDraggingItem:FireServer(item)
                    end)
                    count = count + 1
                end
            end
        end
    end
})

-- ==========================================
-- 4. MOB TP TAB
-- ==========================================
local possibleCharacters = {
    "Alpha Wolf","Bear","Lost Child","Lost Child2","Lost Child3","Lost Child4",
    "Wolf","Bunny","Cultist","Alien"
}

Tabs.MobTP:AddDropdown("BringMob", {
    Title = "Bring Mob to You",
    Values = possibleCharacters,
    Multi = false,
    Default = 1,
    Callback = function(characterName)
        local _, hrp = getCharacterInfo()
        if not hrp then return end
        local characterFolder = workspace:FindFirstChild("Characters")
        if not characterFolder then return end
        local count = 0
        for _, model in ipairs(characterFolder:GetChildren()) do
            if model.Name == characterName then
                local mainPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                if mainPart then
                    local targetCFrame = hrp.CFrame + Vector3.new(0, count * 3, 0)
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
})

-- ==========================================
-- 5. AUTO FARM TAB
-- ==========================================
local campfireDropPos = Vector3.new(0, 19, 0)
local machineDropPos = Vector3.new(21, 16, -5)

local campfireFuelItems = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"}
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}

local autoFeedAlways = {}
local autoEatEnabled = false

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(workspace) then return end
    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    pcall(function()
        remoteEvents.RequestStartDraggingItem:FireServer(item)
        task.wait(0.05)
        part.CFrame = CFrame.new(position)
        task.wait(0.05)
        remoteEvents.StopDraggingItem:FireServer(item)
    end)
end

Tabs.Auto:AddDropdown("AutoFeedCampfire", {
    Title = "Auto Feed Campfire",
    Values = campfireFuelItems,
    Multi = true,
    Default = {},
    Callback = function(Value)
        autoFeedAlways = Value
    end
})

Tabs.Auto:AddToggle("AutoEat", {
    Title = "Auto Eat Food (3s Interval)",
    Default = false,
    Callback = function(state)
        autoEatEnabled = state
    end
})

task.spawn(function()
    while true do
        for itemName, enabled in pairs(autoFeedAlways) do
            if enabled then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name == itemName then moveItemToPos(item, campfireDropPos) end
                end
            end
        end
        task.wait(2)
    end
end)

local remoteConsume = remoteEvents:WaitForChild("RequestConsumeItem")

task.spawn(function()
    while true do
        if autoEatEnabled then
            local available = {}
            for _, item in ipairs(itemFolder:GetChildren()) do
                if table.find(autoEatFoods, item.Name) then table.insert(available, item) end
            end
            if #available > 0 then
                local food = available[math.random(1, #available)]
                pcall(function() remoteConsume:InvokeServer(food) end)
            end
        end
        task.wait(3)
    end
end)

-- ==========================================
-- 6. PLAYER TAB
-- ==========================================
Tabs.Player:AddSlider("WalkSpeed", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

Tabs.Player:AddSlider("JumpPower", {
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = Value
        end
    end
})

-- ==========================================
-- 7. VISUALS TAB
-- ==========================================
local BillboardESPs = {}

Tabs.Visuals:AddToggle("PlayerESP", {
    Title = "Player ESP",
    Default = false,
    Callback = function(state)
        if not state then
            for _, gui in pairs(BillboardESPs) do if gui then gui:Destroy() end end
            BillboardESPs = {}
        else
            for _, plrObj in pairs(Players:GetPlayers()) do
                if plrObj ~= LocalPlayer and plrObj.Character and plrObj.Character:FindFirstChild("Head") then
                    local gui = Instance.new("BillboardGui")
                    gui.Name = "Billboard_ESP"
                    gui.Adornee = plrObj.Character.Head
                    gui.Parent = plrObj.Character.Head
                    gui.Size = UDim2.new(0, 100, 0, 40)
                    gui.AlwaysOnTop = true
                    gui.StudsOffset = Vector3.new(0, 2, 0)

                    local label = Instance.new("TextLabel", gui)
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(1, 1, 1)
                    label.TextStrokeTransparency = 0.5
                    label.Text = plrObj.Name
                    BillboardESPs[plrObj] = gui
                end
            end
        end
    end
})

Fluent:Notify({
    Title = "W424 Hub Loaded",
    Content = "Script 99 Nights in the Forest berhasil dimuat!",
    Duration = 5
})
