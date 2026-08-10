-- ==========================================
-- W424 - 99 NIGHTS (KAIRO UI v5 - FINAL)
-- ==========================================

local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = RemoteEvents:FindFirstChild("RequestConsumeItem")

local ScriptRunning = true
local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)

-- Lost Child Path
local LostChildPath = nil
pcall(function()
    LostChildPath = workspace.Map.Landmarks["Jail Cellar1"].Dino
end)

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findValidPart(obj)
    if not obj then return nil end
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

local function resetVelocity(item)
    pcall(function()
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            item.AssemblyLinearVelocity = Vector3.zero
            item.AssemblyAngularVelocity = Vector3.zero
        elseif item:IsA("Model") then
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function setItemCFrame(item, pos)
    pcall(function()
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            item.CFrame = CFrame.new(pos)
        elseif item:IsA("Model") then
            item:PivotTo(CFrame.new(pos))
        end
    end)
end

-- ==========================================
-- TELEPORT FUNCTIONS
-- ==========================================
local function fastDragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return end
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.015)
        resetVelocity(item)
        setItemCFrame(item, pos)
        task.wait(0.015)
        if dragStop then dragStop:FireServer(item) end
    end)
end

local function stableDragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    local success = false
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.06)
        if not item:IsDescendantOf(workspace) then return end
        resetVelocity(item)
        setItemCFrame(item, pos)
        task.wait(0.06)
        if not item:IsDescendantOf(workspace) then return end
        resetVelocity(item)
        if dragStop then dragStop:FireServer(item) end
        task.wait(0.04)
        success = true
    end)
    return success
end

local function teleportPlayerTo(pos)
    local hrp = getRootPart()
    if hrp then
        pcall(function()
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        end)
    end
end

-- ==========================================
-- MOBILE UI SIZE
-- ==========================================
local cam = workspace.CurrentCamera
local screenSize = cam and cam.ViewportSize or Vector2.new(800, 600)
local uiWidth = math.min(340, math.max(300, screenSize.X * 0.9))
local uiHeight = math.min(420, math.max(320, screenSize.Y * 0.78))

-- ==========================================
-- KAIRO UI - MIDNIGHT
-- ==========================================
local Window = Kairo:CreateWindow({
    Title = "W424 Hub",
    Theme = "Midnight",
    Size = UDim2.fromOffset(uiWidth, uiHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"MOBILE", "v5.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = {
        Enabled = true,
        Folder = "W424_Config",
        AutoLoad = true
    }
})

local MainTab = Window:CreateTab("Main", "rbxassetid://16932740082")
local CombatTab = Window:CreateTab("Aura", "rbxassetid://16932740082")
local ItemTPTab = Window:CreateTab("Item TP", "rbxassetid://16932740082")
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")

-- ==========================================
-- MAIN FARM TAB
-- ==========================================
Window:AddParagraph(MainTab, "Auto Farm", "Fast & stable farming")

local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local rawFoodsToCook = {"Morsel", "Steak"}

Window:AddToggle(MainTab, "Auto Eat", "Eat when HP < 70%", false,
    function(state) autoEatEnabled = state end, "AutoEat"
)

Window:AddToggle(MainTab, "Auto Cook", "Cook raw at campfire", false,
    function(state) autoCookEnabled = state end, "AutoCook"
)

Window:AddDivider(MainTab, "Teleports")

-- Teleport to Lost Child
Window:AddButton(MainTab, "TP to Lost Child", "Teleport to Jail Cellar Dino",
    "rbxassetid://16932740082",
    function()
        if LostChildPath then
            local targetPart = findValidPart(LostChildPath)
            if targetPart then
                teleportPlayerTo(targetPart.Position)
                Window:Notify({
                    Title = "Teleport", Description = "Lost Child",
                    Content = "Teleported to Lost Child!", Color = Color3.fromRGB(10, 30, 60), Delay = 3
                })
            end
        else
            Window:Notify({
                Title = "Error", Description = "Lost Child",
                Content = "Lost Child not found in workspace!", Color = Color3.fromRGB(200, 50, 50), Delay = 3
            })
        end
    end
)

-- Teleport Back to Campfire
Window:AddButton(MainTab, "TP to Campfire", "Teleport back to campfire",
    "rbxassetid://16932740082",
    function()
        teleportPlayerTo(CAMPFIRE_POS)
        Window:Notify({
            Title = "Teleport", Description = "Campfire",
            Content = "Teleported to Campfire!", Color = Color3.fromRGB(10, 30, 60), Delay = 3
        })
    end
)

Window:AddDivider(MainTab, "Grind & Fuel")

local autoGrindItems = {}
Window:AddMultiDropdown(MainTab, "Auto Grind", "Items to machine grind",
    {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    {}, function(selected)
        autoGrindItems = {}
        for _, v in ipairs(selected) do autoGrindItems[v] = true end
    end, "AutoGrind"
)

local autoFuelItems = {}
Window:AddMultiDropdown(MainTab, "Auto Fuel", "Fuel for campfire",
    {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    {}, function(selected)
        autoFuelItems = {}
        for _, v in ipairs(selected) do autoFuelItems[v] = true end
    end, "AutoFuel"
)

-- ==========================================
-- AURA TAB (Kill Aura only)
-- ==========================================
Window:AddParagraph(CombatTab, "Combat", "Kill aura settings")

local killAuraEnabled = false
local auraRadius = 200

local toolIds = {
    ["Old Axe"] = "1", ["Good Axe"] = "112", ["Strong Axe"] = "116",
    ["Chainsaw"] = "647", ["Spear"] = "196"
}

local function getAnyToolWithDamageID()
    local locations = {LocalPlayer.Inventory, LocalPlayer.Backpack, LocalPlayer.Character}
    for _, loc in ipairs(locations) do
        if loc then
            for toolName, prefix in pairs(toolIds) do
                local tool = loc:FindFirstChild(toolName)
                if tool then
                    if loc ~= LocalPlayer.Character and tool:IsA("Tool") then
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

Window:AddToggle(CombatTab, "Kill Aura", "Attack nearby mobs", false,
    function(state) killAuraEnabled = state end, "KillAura"
)

Window:AddInput(CombatTab, "Radius", "Attack radius", "200",
    function(value)
        local num = tonumber(value)
        if num then auraRadius = num end
    end, "AuraRadius"
)

-- ==========================================
-- ITEM TP TAB (SUPER FAST)
-- ==========================================
Window:AddParagraph(ItemTPTab, "Item TP", "Super fast item teleport")

local itemCategories = {
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave"},
    Equipment_Weapons = {"Rifle", "Revolver", "Rifle Ammo", "Revolver Ammo", "Chainsaw", "Old Flashlight", "MedKit", "Bandage"},
    Food_Consumables = {"Berry", "Carrot", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs", "Cake"}
}

local selectedItems = {}

for catName, listItems in pairs(itemCategories) do
    selectedItems[catName] = listItems[1]
    
    Window:AddDropdown(ItemTPTab, catName:gsub("_", " "), "Select item",
        listItems, false, listItems[1],
        function(value) selectedItems[catName] = value end,
        "TP_" .. catName
    )
    
    Window:AddButton(ItemTPTab, "Bring " .. catName:gsub("_", " "), "Teleport ALL matching items",
        "rbxassetid://16932740082",
        function()
            local hrp = getRootPart()
            if not hrp then return end
            local selected = selectedItems[catName]
            local count = 0
            
            -- Get ALL descendants (lebih luas)
            local allItems = ItemsFolder:GetDescendants()
            local toProcess = {}
            
            for _, item in ipairs(allItems) do
                if item.Name == selected and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                    table.insert(toProcess, item)
                end
            end
            
            -- Batch process: 3 item per frame untuk speed + stability
            for i, item in ipairs(toProcess) do
                local pos = hrp.Position + (hrp.CFrame.LookVector * 4) + Vector3.new(0, 2 + (count * 1.2), 0)
                task.spawn(function()
                    fastDragItemToPos(item, pos)
                end)
                count = count + 1
                if i % 3 == 0 then task.wait(0.02) end -- batching delay
            end
            
            Window:Notify({
                Title = "Success", Description = "Item TP",
                Content = "Brought " .. count .. "x " .. selected,
                Color = Color3.fromRGB(10, 30, 60), Delay = 3
            })
        end
    )
    
    Window:AddDivider(ItemTPTab, "")
end

-- ==========================================
-- VISUALS TAB
-- ==========================================
Window:AddParagraph(VisualsTab, "ESP", "Visual overlays")

local espMobsEnabled = false
local espItemsEnabled = false
local espFolder = Instance.new("Folder")
espFolder.Name = "W424_ESP"
espFolder.Parent = CoreGui

local function createESP(instance, name, color)
    local part = findValidPart(instance)
    if not part then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = instance
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Parent = espFolder
    
    local bg = Instance.new("BillboardGui")
    bg.Adornee = part
    bg.Size = UDim2.new(0, 120, 0, 25)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = espFolder
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
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
                txt.Text = string.format("%s [%dm]", name, math.floor((part.Position - hrp.Position).Magnitude))
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
                createESP(mob, mob.Name, Color3.fromRGB(255,50,50))
            end
        end
    end
    if espItemsEnabled then
        for _, item in ipairs(ItemsFolder:GetChildren()) do
            createESP(item, item.Name, Color3.fromRGB(50,255,50))
        end
    end
end

Window:AddToggle(VisualsTab, "ESP Mobs", "Show mob locations", false,
    function(state) espMobsEnabled = state; refreshESP() end, "ESPMobs"
)

Window:AddToggle(VisualsTab, "ESP Items", "Show item locations", false,
    function(state) espItemsEnabled = state; refreshESP() end, "ESPItems"
)

-- ==========================================
-- PLAYER TAB
-- ==========================================
Window:AddParagraph(PlayerTab, "Stats", "Player modifications")

Window:AddSlider(PlayerTab, "WalkSpeed", "Movement speed", 0, 200, 16,
    function(value)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = value end
    end, "WalkSpeed", true
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
                local chars = Workspace:FindFirstChild("Characters")
                if chars then
                    for _, mob in ipairs(chars:GetChildren()) do
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
-- FAST AUTO GRIND & FUEL (v5 - Responsive)
-- ==========================================
local processingItems = {}

task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        if hrp then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                
                local itemId = tostring(item)
                if processingItems[itemId] then continue end
                
                local shouldGrind = autoGrindItems[item.Name] == true
                local shouldFuel = autoFuelItems[item.Name] == true
                local shouldCook = autoCookEnabled and table.find(rawFoodsToCook, item.Name)
                
                if shouldGrind or shouldFuel or shouldCook then
                    local targetPos = shouldGrind and MACHINE_POS or CAMPFIRE_POS
                    
                    -- Skip kalau sudah dekat target
                    local itemPos = getItemPosition(item)
                    if itemPos then
                        if (itemPos - targetPos).Magnitude < 10 then continue end
                    end
                    
                    processingItems[itemId] = true
                    stableDragItemToPos(item, targetPos)
                    task.delay(0.4, function()
                        processingItems[itemId] = nil
                    end)
                    
                    task.wait(0.1) -- delay antar item (cepat tapi stabil)
                end
            end
        end
        task.wait(0.3) -- loop cepat
    end
end)

-- ==========================================
-- AUTO EAT LOOP
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        if autoEatEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and hum.Health < (hum.MaxHealth * 0.7) then
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
-- ESP REFRESH
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        if espMobsEnabled or espItemsEnabled then refreshESP() end
        task.wait(5)
    end
end)

-- ==========================================
-- NOTIFY
-- ==========================================
Window:Notify({
    Title = "W424 Hub",
    Description = "Loaded",
    Content = "v5: Lost Child TP + Fast Grind + Campfire TP!",
    Color = Color3.fromRGB(10, 30, 60),
    Delay = 5
})
