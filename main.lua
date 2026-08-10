-- ==========================================
-- W424 - 99 NIGHTS (KAIRO UI v3 - MOBILE FAST)
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

-- ==========================================
-- FAST TELEPORT (Anti-freeze, no cooldown)
-- ==========================================
local function fastTeleport(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return end
    pcall(function()
        if item:IsA("BasePart") or item:IsA("MeshPart") then
            item.AssemblyLinearVelocity = Vector3.zero
            item.AssemblyAngularVelocity = Vector3.zero
            item.CFrame = CFrame.new(pos)
        elseif item:IsA("Model") then
            item:PivotTo(CFrame.new(pos))
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
    end)
end

local function fastDragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return end
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.02)
        fastTeleport(item, pos)
        task.wait(0.02)
        if dragStop then dragStop:FireServer(item) end
    end)
end

-- ==========================================
-- MOBILE UI SIZE (Auto-fit screen)
-- ==========================================
local cam = workspace.CurrentCamera
local screenSize = cam and cam.ViewportSize or Vector2.new(800, 600)
local uiWidth = math.min(380, math.max(300, screenSize.X * 0.92))
local uiHeight = math.min(440, math.max(350, screenSize.Y * 0.82))

-- ==========================================
-- KAIRO UI - MIDNIGHT (BIRU TUA)
-- ==========================================
local Window = Kairo:CreateWindow({
    Title = "W424 Hub",
    Theme = "Midnight",
    Size = UDim2.fromOffset(uiWidth, uiHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"MOBILE", "v3.2"},
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
Window:AddParagraph(MainTab, "Auto Farm", "Fast auto farm settings")

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

Window:AddDivider(MainTab, "Grind & Fuel")

local autoGrindItems = {}
Window:AddMultiDropdown(MainTab, "Auto Grind", "Select items to grind",
    {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    {}, function(selected)
        autoGrindItems = {}
        for _, v in ipairs(selected) do autoGrindItems[v] = true end
    end, "AutoGrind"
)

local autoFuelItems = {}
Window:AddMultiDropdown(MainTab, "Auto Fuel", "Select fuel for campfire",
    {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    {}, function(selected)
        autoFuelItems = {}
        for _, v in ipairs(selected) do autoFuelItems[v] = true end
    end, "AutoFuel"
)

-- ==========================================
-- AURA TAB
-- ==========================================
Window:AddParagraph(CombatTab, "Combat", "Aura attack settings")

local killAuraEnabled = false
local treeAuraEnabled = false
local auraRadius = 100

local toolIds = {
    ["Old Axe"] = "1", ["Good Axe"] = "112", ["Strong Axe"] = "116",
    ["Chainsaw"] = "647", ["Spear"] = "196"
}

-- Cari tool di Inventory, Backpack, DAN Character + auto-equip
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

Window:AddToggle(CombatTab, "Aura Chop", "Chop nearby small trees", false,
    function(state) treeAuraEnabled = state end, "SmalltreesAura"
)

Window:AddInput(CombatTab, "Radius", "Attack radius", "100",
    function(value)
        local num = tonumber(value)
        if num then auraRadius = num end
    end, "AuraRadius"
)

-- ==========================================
-- ITEM TP TAB (FAST & WIDE)
-- ==========================================
Window:AddParagraph(ItemTPTab, "Item TP", "Fast item teleport")

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
    
    Window:AddButton(ItemTPTab, "Bring " .. catName:gsub("_", " "), "Teleport all matching items",
        "rbxassetid://16932740082",
        function()
            local hrp = getRootPart()
            if not hrp then return end
            local selected = selectedItems[catName]
            local count = 0
            
            for _, item in ipairs(ItemsFolder:GetDescendants()) do
                if item.Name == selected and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                    local pos = hrp.Position + (hrp.CFrame.LookVector * 4) + Vector3.new(0, 2 + (count * 1.2), 0)
                    task.spawn(function()
                        fastDragItemToPos(item, pos)
                    end)
                    count = count + 1
                end
            end
            
            Window:Notify({
                Title = "Success", Description = "Teleport",
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
-- AURA CHOP (TREES) - FIXED
-- ==========================================
local choppedTrees = {}

task.spawn(function()
    while ScriptRunning do
        if treeAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getAnyToolWithDamageID()
            if hrp and tool and damageID then
                -- Equip dulu
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                task.wait(0.1) -- TUNGGU equip selesai
                
                local map = Workspace:FindFirstChild("Map")
                if map and map:FindFirstChild("Foliage") then
                    for _, obj in ipairs(map.Foliage:GetChildren()) do
                        if obj:IsA("Model") and obj.Parent == map.Foliage and not choppedTrees[obj] then
                            local trunk = obj:FindFirstChild("Trunk")
                            if trunk and trunk:IsA("BasePart") then
                                if (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                                    choppedTrees[obj] = tick()
                                    task.spawn(function()
                                        -- Sound (ignore error)
                                        pcall(function()
                                            RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"),
                                                Volume = 0.4
                                            })
                                        end)
                                        -- Damage (main)
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
-- SUPER FAST AUTO GRIND & FUEL LOOP
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        if hrp then
            for _, item in ipairs(ItemsFolder:GetChildren()) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                
                local shouldGrind = autoGrindItems[item.Name] == true
                local shouldFuel = autoFuelItems[item.Name] == true
                local shouldCook = autoCookEnabled and table.find(rawFoodsToCook, item.Name)
                
                if shouldGrind or shouldFuel or shouldCook then
                    local targetPos = shouldGrind and MACHINE_POS or CAMPFIRE_POS
                    -- PARALLEL + FAST: no distance check, no cooldown, instant
                    task.spawn(function()
                        fastDragItemToPos(item, targetPos)
                    end)
                end
            end
        end
        task.wait(0.1) -- LOOP CEPAT: 0.1 detik
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
    Content = "Mobile UI + Fast Grind + Aura Chop Fixed!",
    Color = Color3.fromRGB(10, 30, 60),
    Delay = 5
})
