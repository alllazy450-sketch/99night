-- ==========================================
-- W424 - 99 NIGHTS (ROBUST LOAD + ANTI-FREEZE)
-- ==========================================

-- ==========================================
-- ROBUST LIBRARY LOADER (3 Method Fallback)
-- ==========================================
local OrvionLib
local loadError = ""

-- Method 1: game:HttpGet (PC Executor)
local s1, r1 = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua", true)
end)
if s1 and r1 and #r1 > 500 then
    local s2, r2 = pcall(function() return loadstring(r1)() end)
    if s2 and r2 then OrvionLib = r2 end
end

-- Method 2: request() (Mobile Executor: Delta, Codex, etc)
if not OrvionLib and request then
    local s3, r3 = pcall(function()
        local res = request({
            Url = "https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua",
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0"}
        })
        return res and res.Body
    end)
    if s3 and r3 and #r3 > 500 then
        local s4, r4 = pcall(function() return loadstring(r3)() end)
        if s4 and r4 then OrvionLib = r4 end
    end
end

-- Method 3: http_request (Alternative mobile)
if not OrvionLib and http_request then
    local s5, r5 = pcall(function()
        local res = http_request({
            Url = "https://raw.githubusercontent.com/KnullXDgt/orvion/refs/heads/main/orvionlibrary.lua",
            Method = "GET",
            Headers = {["User-Agent"] = "Mozilla/5.0"}
        })
        return res and res.Body
    end)
    if s5 and r5 and #r5 > 500 then
        local s6, r6 = pcall(function() return loadstring(r5)() end)
        if s6 and r6 then OrvionLib = r6 end
    end
end

-- Jika masih gagal, beri error yang jelas
if not OrvionLib then
    local msg = [[
    =========================================
    ❌ ORVIONLIB GAGAL DI-LOAD!
    =========================================
    Penyebab umum:
    • Executor mobile sering blok GitHub Raw
    • Koneksi internet terbatas
    • URL library sudah tidak valid
    
    Solusi:
    1. Coba pakai executor PC (KRNL, Synapse, Fluxus)
    2. Atau load library manual via Pastebin/Alternative URL
    3. Atau gunakan VPN jika GitHub diblok
    =========================================]]
    warn(msg)
    
    -- Tampilkan di game juga
    local sg = Instance.new("ScreenGui")
    sg.Parent = game:GetService("CoreGui")
    local tl = Instance.new("TextLabel")
    tl.Parent = sg
    tl.Size = UDim2.new(0, 400, 0, 200)
    tl.Position = UDim2.new(0.5, -200, 0.5, -100)
    tl.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
    tl.TextColor3 = Color3.fromRGB(255, 100, 100)
    tl.TextWrapped = true
    tl.Text = "❌ ORVIONLIB GAGAL LOAD!\n\nCek console (F9) untuk detail.\n\nSolusi:\n• Pakai executor PC\n• Atau load library manual\n• Atau gunakan VPN"
    tl.TextSize = 18
    Instance.new("UICorner", tl)
    return -- STOP script
end

-- ==========================================
-- SERVICES & VARIABLES
-- ==========================================
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
-- ANTI-FREEZE CONFIG
-- ==========================================
local MAX_GRIND_DISTANCE = 500
local TELEPORT_TIMEOUT = 8
local RETRY_ATTEMPTS = 3
local PROCESS_COOLDOWN = 2
local TELEPORT_DELAY = 0.15

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

-- ==========================================
-- ANTI-FREEZE: GET ITEM POSITION
-- ==========================================
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

-- ==========================================
-- ANTI-FREEZE: SET POSITION WITH VELOCITY RESET
-- ==========================================
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
-- ANTI-FREEZE: IMPROVED DRAG SYSTEM
-- ==========================================
local processingItems = {}
local lastProcessed = {}

local function dragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    local itemId = tostring(item)
    local currentTime = tick()
    
    if lastProcessed[itemId] and (currentTime - lastProcessed[itemId]) < PROCESS_COOLDOWN then
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
        if distToPlayer > MAX_GRIND_DISTANCE then
            processingItems[itemId] = nil
            return false
        end
    end
    
    local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
    local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
    local success = false
    
    for attempt = 1, RETRY_ATTEMPTS do
        if not item:IsDescendantOf(workspace) then break end
        pcall(function()
            if dragStart then dragStart:FireServer(item) end
            task.wait(TELEPORT_DELAY)
            if not item:IsDescendantOf(workspace) then return end
            setItemPosition(item, pos)
            task.wait(TELEPORT_DELAY)
            if not item:IsDescendantOf(workspace) then return end
            local newPos = getItemPosition(item)
            if newPos then
                local distToTarget = (newPos - pos).Magnitude
                if distToTarget <= 10 then
                    success = true
                else
                    setItemPosition(item, pos)
                    task.wait(TELEPORT_DELAY)
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
-- UI SETUP
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

local Tabs = {
    Main    = Window:AddTab("Main Farm"),
    Combat  = Window:AddTab("Aura"),
    ItemTP  = Window:AddTab("Item TP"),
    Visuals = Window:AddTab("Visuals (ESP)"),
    Player  = Window:AddTab("Player"),
}

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
-- AURA CHOP (TREES) - IMPROVED
-- ==========================================
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
                        if obj:IsA("Model") and obj.Parent == map.Foliage and not choppedTrees[obj] then
                            local trunk = obj:FindFirstChild("Trunk")
                            if trunk and trunk:IsA("BasePart") then
                                if (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                                    choppedTrees[obj] = tick()
                                    task.spawn(function()
                                        pcall(function()
                                            if obj.Parent == map.Foliage and obj:FindFirstChild("Trunk") then
                                                RemoteEvents.RequestReplicateSound:FireServer("FireAllClients", "WoodChop", {
                                                    Instance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"), 
                                                    Volume = 0.4
                                                })
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
-- MAIN FARM FEATURES
-- ==========================================
local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
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

-- ==========================================
-- IMPROVED AUTO GRIND LOOP (ANTI-FREEZE)
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        if hrp then
            local items = ItemsFolder:GetChildren()
            for _, item in ipairs(items) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                local shouldGrind = autoGrindItems[item.Name]
                local shouldFuel = autoFuelItems[item.Name]
                local shouldCook = autoCookEnabled and table.find(rawFoodsToCook, item.Name)
                if shouldGrind or shouldFuel or shouldCook then
                    local targetPos = shouldGrind and MACHINE_POS or CAMPFIRE_POS
                    local itemPos = getItemPosition(item)
                    if itemPos then
                        local dist = (itemPos - hrp.Position).Magnitude
                        if dist <= MAX_GRIND_DISTANCE then
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
-- ITEM TELEPORT
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
            for _, item in ipairs(ItemsFolder:GetDescendants()) do
                if item.Name == selectedCatItem and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                    local targetPos = hrp.Position + (hrp.CFrame.LookVector * 5) + Vector3.new(0, 3 + (count * 1.5), 0)
                    dragItemToPos(item, targetPos)
                    count = count + 1
                end
            end
            OrvionLib:Notify("Success", "Ditarik: " .. count + 0 .. " " .. selectedCatItem, 3)
        end
    })
end

-- ==========================================
-- ESP SYSTEM
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
Tabs.Visuals:AddToggle({ Title = "ESP Items", Default = false, Callback = function(state) espItemsEnabled = state refreshESP() and refreshESP() end })

task.spawn(function()
    while ScriptRunning do
        if espMobsEnabled or espItemsEnabled then refreshESP() end
        task.wait(5)
    end
end)

-- ==========================================
-- PLAYER TAB
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

OrvionLib:Notify("W424 Hub", "Script Loaded: Anti-Freeze System Active!", 3)
