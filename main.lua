-- ==========================================
-- W424 - 99 NIGHTS (KAIRO UI + ANTI-FREEZE)
-- ==========================================

local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

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

local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function getRootPart()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function findValidPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("MeshPart") then return child end
    end
    return nil
end

local function getItemPosition(item)
    if not item or not item:IsDescendantOf(workspace) then return nil end
    if item:IsA("Model") then
        return item:GetPivot().Position
    elseif item:IsA("BasePart") or item:IsA("MeshPart") then
        return item.Position
    else
        local part = findValidPart(item)
        return part and part.Position or nil
    end
end

local function setItemPosition(item, targetPos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    local success = false
    pcall(function()
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            item.AssemblyLinearVelocity = Vector3.zero
            item.AssemblyAngularVelocity = Vector3.zero
            item.CFrame = CFrame.new(targetPos)
            success = true
        elseif item:IsA("Model") then
            item:PivotTo(CFrame.new(targetPos))
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            success = true
        end
    end)
    return success
end

-- ==========================================
-- ANTI-FREEZE DRAG (For Auto Grind only)
-- ==========================================
local processingItems = {}
local lastProcessed = {}

local function dragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    local itemId = tostring(item)
    local currentTime = tick()
    
    if lastProcessed[itemId] and (currentTime - lastProcessed[itemId]) < 2 then
        return false
    end
    if processingItems[itemId] then return false end
    processingItems[itemId] = true
    
    local startPos = getItemPosition(item)
    if not startPos then 
        processingItems[itemId] = nil
        return false 
    end
    
    local hrp = getRootPart()
    if hrp then
        local distToPlayer = (startPos - hrp.Position).Magnitude
        if distToPlayer > 500 then
            processingItems[itemId] = nil
            return false
        end
    end
    
    local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
    local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
    local success = false
    
    for attempt = 1, 3 do
        if not item:IsDescendantOf(workspace) then break end
        pcall(function()
            if dragStart then dragStart:FireServer(item) end
            task.wait(0.15)
            if not item:IsDescendantOf(workspace) then return end
            setItemPosition(item, pos)
            task.wait(0.15)
            if not item:IsDescendantOf(workspace) then return end
            local newPos = getItemPosition(item)
            if newPos then
                local distToTarget = (newPos - pos).Magnitude
                if distToTarget <= 10 then
                    success = true
                else
                    setItemPosition(item, pos)
                    task.wait(0.15)
                end
            end
            if dragStop then dragStop:FireServer(item) end
            task.wait(0.1)
        end)
        if success then break end
        task.wait(0.2)
    end
    
    lastProcessed[itemId] = tick()
    processingItems[itemId] = nil
    return success
end

-- ==========================================
-- FAST DRAG (For Item TP - no cooldown, parallel)
-- ==========================================
local function fastDragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.03)
        if not item:IsDescendantOf(workspace) then return end
        setItemPosition(item, pos)
        task.wait(0.03)
        if dragStop then dragStop:FireServer(item) end
    end)
    return true
end

-- ==========================================
-- KAIRO UI SETUP (Midnight = Biru Tua)
-- ==========================================
local Window = Kairo:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    Theme = "Midnight",
    Size = UDim2.fromOffset(580, 520),
    Center = true,
    Draggable = true,
    Resize = true,
    Badges = {"OP", "v3.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = {
        Enabled = true,
        Folder = "W424_Config",
        AutoLoad = true
    }
})

local MainTab = Window:CreateTab("Main Farm", "rbxassetid://16932740082")
local CombatTab = Window:CreateTab("Aura", "rbxassetid://16932740082")
local ItemTPTab = Window:CreateTab("Item TP", "rbxassetid://16932740082")
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")

-- ==========================================
-- MAIN FARM TAB
-- ==========================================
Window:AddParagraph(MainTab, "Auto Farm", "Configure automatic farming features")

local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local rawFoodsToCook = {"Morsel", "Steak"}

Window:AddToggle(MainTab, "Auto Eat (HP Based)", "Auto eat when HP below 70%", false,
    function(state) autoEatEnabled = state end,
    "AutoEat"
)

Window:AddToggle(MainTab, "Auto Cook Raw Food", "Auto cook raw meat at campfire", false,
    function(state) autoCookEnabled = state end,
    "AutoCook"
)

Window:AddDivider(MainTab, "Machine & Campfire")

local autoGrindItems = {}
Window:AddMultiDropdown(MainTab, "Auto Machine Grind", "Select items to auto grind",
    {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    {},
    function(selectedValues)
        autoGrindItems = {}
        for _, v in ipairs(selectedValues) do autoGrindItems[v] = true end
    end,
    "AutoGrindMulti"
)

local autoFuelItems = {}
Window:AddMultiDropdown(MainTab, "Auto Feed Campfire", "Select fuel items",
    {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    {},
    function(selectedValues)
        autoFuelItems = {}
        for _, v in ipairs(selectedValues) do autoFuelItems[v] = true end
    end,
    "AutoFuelMulti"
)

-- ==========================================
-- AURA TAB
-- ==========================================
Window:AddParagraph(CombatTab, "Combat Settings", "Configure aura attack settings")

local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 200

local toolIds = {
    ["Old Axe"] = "1", ["Good Axe"] = "112", ["Strong Axe"] = "116",
    ["Chainsaw"] = "647", ["Spear"] = "196"
}

-- FIXED: Check Inventory, Backpack, AND Character + auto-equip
local function getAnyToolWithDamageID()
    local locations = {LocalPlayer.Inventory, LocalPlayer.Backpack, LocalPlayer.Character}
    for _, location in ipairs(locations) do
        if location then
            for toolName, prefix in pairs(toolIds) do
                local tool = location:FindFirstChild(toolName)
                if tool then
                    -- Auto equip if not in character
                    if location ~= LocalPlayer.Character and tool:IsA("Tool") then
                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then pcall(function() hum:EquipTool(tool) end) end
                    end
                    return tool, prefix .. "_" .. tostring(LocalPlayer.UserId)
                end
            end
        end
    end
    return nil, nil
end

Window:AddToggle(CombatTab, "Kill Aura (Mobs Only)", "Auto attack nearby mobs", false,
    function(state) killAuraEnabled = state end,
    "KillAura"
)

Window:AddToggle(CombatTab, "Aura Chop (Trees Only)", "Auto chop nearby trees", false,
    function(state) treeAuraEnabled = state end,
    "TreeAura"
)

Window:AddInput(CombatTab, "Aura Radius", "Enter attack radius", "200",
    function(value)
        local num = tonumber(value)
        if num then auraRadius = num end
    end,
    "AuraRadius"
)

-- ==========================================
-- ITEM TP TAB (FAST & WIDE)
-- ==========================================
Window:AddParagraph(ItemTPTab, "Item Teleport", "Bring items to you instantly")

local itemCategories = {
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave"},
    Equipment_Weapons = {"Rifle", "Revolver", "Rifle Ammo", "Revolver Ammo", "Chainsaw", "Old Flashlight", "MedKit", "Bandage"},
    Food_Consumables = {"Berry", "Carrot", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs", "Cake"}
}

local selectedItems = {}

for catName, listItems in pairs(itemCategories) do
    selectedItems[catName] = listItems[1]
    
    Window:AddDropdown(ItemTPTab, "Select: " .. catName:gsub("_", " "), "Choose item to bring",
        listItems, false, listItems[1],
        function(value)
            selectedItems[catName] = value
        end,
        "ItemTP_" .. catName
    )
    
    Window:AddButton(ItemTPTab, "Bring " .. catName:gsub("_", " "), "Teleport ALL matching items to you instantly",
        "rbxassetid://16932740082",
        function()
            local count = 0
            local hrp = getRootPart()
            if not hrp then
                Window:Notify({
                    Title = "Error", Description = "Teleport", Content = "Character not found!",
                    Color = Color3.fromRGB(200, 50, 50), Delay = 3
                })
                return
            end
            
            local selectedCatItem = selectedItems[catName]
            local items = ItemsFolder:GetDescendants()
            
            for _, item in ipairs(items) do
                if item.Name == selectedCatItem and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                    local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                    -- PARALLEL FAST TELEPORT - no cooldown, no delay between items
                    task.spawn(function()
                        fastDragItemToPos(item, targetPos)
                    end)
                    count = count + 1
                end
            end
            
            Window:Notify({
                Title = "Success", Description = "Item Teleport",
                Content = "Brought " .. count .. "x " .. selectedCatItem,
                Color = Color3.fromRGB(10, 30, 60), Delay = 3
            })
        end
    )
    
    Window:AddDivider(ItemTPTab, "")
end

-- ==========================================
-- VISUALS TAB
-- ==========================================
Window:AddParagraph(VisualsTab, "ESP Settings", "Configure visual overlays")

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

Window:AddToggle(VisualsTab, "ESP Mobs", "Highlight all mobs with distance", false,
    function(state)
        espMobsEnabled = state
        refreshESP()
    end,
    "ESPMobs"
)

Window:AddToggle(VisualsTab, "ESP Items", "Highlight all items with distance", false,
    function(state)
        espItemsEnabled = state
        refreshESP()
    end,
    "ESPItems"
)

-- ==========================================
-- PLAYER TAB
-- ==========================================
Window:AddParagraph(PlayerTab, "Character", "Modify player stats")

Window:AddSlider(PlayerTab, "WalkSpeed", "Adjust movement speed", 0, 200, 16,
    function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end,
    "WalkSpeedSlider",
    true
)

-- ==========================================
-- KILL AURA LOOP
-- ==========================================
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

-- ==========================================
-- AURA CHOP (TREES) - FIXED
-- ==========================================
local choppedTrees = {}

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
                        if obj:IsA("Model") and obj.Parent == map.Foliage and not choppedTrees[obj] then
                            local trunk = obj:FindFirstChild("Trunk")
                            if trunk and trunk:IsA("BasePart") then
                                if (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                                    choppedTrees[obj] = tick()
                                    task.spawn(function()
                                        -- FIXED: Pisahkan pcall sound dan damage
                                        pcall(function()
                                            RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"), 
                                                Volume = 0.4
                                            })
                                        end)
                                        pcall(function()
                                            if obj.Parent == map.Foliage and obj:FindFirstChild("Trunk") then
                                                RemoteEvents.ToolDamageObject:InvokeServer(obj, tool, damageID, trunk.CFrame, true)
                                            end
                                        end)
                                    end)
                                    task.delay(1.5, function() choppedTrees[obj] = nil end)
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
-- AUTO GRIND LOOP (Anti-Freeze)
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        if hrp then
            local items = ItemsFolder:GetChildren()
            for _, item in ipairs(items) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                local shouldGrind = autoGrindItems[item.Name] == true
                local shouldFuel = autoFuelItems[item.Name] == true
                local shouldCook = autoCookEnabled and table.find(rawFoodsToCook, item.Name)
                if shouldGrind or shouldFuel or shouldCook then
                    local targetPos = shouldGrind and MACHINE_POS or CAMPFIRE_POS
                    local itemPos = getItemPosition(item)
                    if itemPos then
                        local dist = (itemPos - hrp.Position).Magnitude
                        if dist <= 500 then
                            local ok = dragItemToPos(item, targetPos)
                            if ok then task.wait(0.3) end
                        end
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)

-- ==========================================
-- AUTO EAT LOOP
-- ==========================================
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
-- ESP REFRESH LOOP
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        if espMobsEnabled or espItemsEnabled then refreshESP() end
        task.wait(5)
    end
end)

-- ==========================================
-- CACHE CLEANUP
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        local currentTime = tick()
        for id, time in pairs(lastProcessed) do
            if currentTime - time > 30 then
                lastProcessed[id] = nil
            end
        end
        task.wait(10)
    end
end)

-- ==========================================
-- NOTIFICATION
-- ==========================================
Window:Notify({
    Title = "W424 Hub",
    Description = "Loaded",
    Content = "Kairo UI (Midnight) + Anti-Freeze + Fast Item TP Active!",
    Color = Color3.fromRGB(10, 30, 60),
    Delay = 5
})
