-- ==========================================
-- W424 - 99 NIGHTS (KAIRO UI v5.5 - JACKPOT ITEMS TP)
-- ==========================================

local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

local Players = game:GetService("Players")
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
-- IMPROVED TELEPORT FUNCTIONS
-- ==========================================
local function reliableDragItemToPos(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return false end
    local success = false
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.1) 
        
        if not item:IsDescendantOf(workspace) then return end
        resetVelocity(item)
        setItemCFrame(item, pos)
        
        task.wait(0.1) 
        
        if not item:IsDescendantOf(workspace) then return end
        resetVelocity(item)
        if dragStop then dragStop:FireServer(item) end
        
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
-- MOBILE UI
-- ==========================================
local cam = workspace.CurrentCamera
local screenSize = cam and cam.ViewportSize or Vector2.new(800, 600)
local uiWidth = math.min(340, math.max(300, screenSize.X * 0.9))
local uiHeight = math.min(420, math.max(320, screenSize.Y * 0.78))

local Window = Kairo:CreateWindow({
    Title = "W424 Hub",
    Theme = "Midnight",
    Size = UDim2.fromOffset(uiWidth, uiHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"MOBILE", "v5.5"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = { Enabled = true, Folder = "W424_Config", AutoLoad = true }
})

local MainTab = Window:CreateTab("Main", "rbxassetid://16932740082")
local CombatTab = Window:CreateTab("Aura", "rbxassetid://16932740082")
local ItemTPTab = Window:CreateTab("Item TP", "rbxassetid://16932740082")
local TeleportsTab = Window:CreateTab("Teleports", "rbxassetid://16932740082") 
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")

-- ==========================================
-- MAIN FARM TAB
-- ==========================================
Window:AddParagraph(MainTab, "Auto Farm", "Otomatisasi Makanan & Grind")

local autoEatEnabled = false
local autoCookEnabled = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local rawFoodsToCook = {"Morsel", "Steak"}
local maxGrindRadius = 1000 

Window:AddToggle(MainTab, "Auto Eat", "Makan otomatis saat HP < 70%", false, function(state) autoEatEnabled = state end, "AutoEat")
Window:AddToggle(MainTab, "Auto Cook", "Masak makanan mentah di Campfire", false, function(state) autoCookEnabled = state end, "AutoCook")
Window:AddDivider(MainTab, "Grind & Fuel")
Window:AddInput(MainTab, "Max Grab Radius", "Batas jarak ambil item (default 1000)", "1000", function(value)
    local num = tonumber(value)
    if num then maxGrindRadius = num end
end, "MaxGrabRadius")

local autoGrindItems = {}
Window:AddMultiDropdown(MainTab, "Auto Grind", "Pilih item untuk mesin",
    {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    {}, function(selected)
        autoGrindItems = {}
        for _, v in ipairs(selected) do autoGrindItems[v] = true end
    end, "AutoGrind"
)

local autoFuelItems = {}
Window:AddMultiDropdown(MainTab, "Auto Fuel", "Pilih bahan bakar Campfire",
    {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"},
    {}, function(selected)
        autoFuelItems = {}
        for _, v in ipairs(selected) do autoFuelItems[v] = true end
    end, "AutoFuel"
)

-- ==========================================
-- TELEPORTS & AURA TAB
-- ==========================================
Window:AddParagraph(TeleportsTab, "Locations", "Teleportasi Karakter")
Window:AddButton(TeleportsTab, "TP to Campfire", "Kembali ke area perapian", "rbxassetid://16932740082", function() teleportPlayerTo(CAMPFIRE_POS) end)

Window:AddParagraph(CombatTab, "Combat", "Kill Aura (Damage Spoofing)")
local killAuraEnabled = false
local auraRadius = 300 
local toolPriority = {"Chainsaw", "Strong Axe", "Good Axe", "Spear", "Old Axe"}
local toolIds = { ["Chainsaw"]="647", ["Strong Axe"]="116", ["Good Axe"]="112", ["Spear"]="196", ["Old Axe"]="1" }

local function getBestSpoofTool()
    local locations = {LocalPlayer.Inventory, LocalPlayer.Backpack, LocalPlayer.Character}
    for _, toolName in ipairs(toolPriority) do
        for _, loc in ipairs(locations) do
            if loc then
                local tool = loc:FindFirstChild(toolName)
                if tool then return tool, toolIds[toolName] .. "_" .. tostring(LocalPlayer.UserId) end
            end
        end
    end
    return nil, nil
end

Window:AddToggle(CombatTab, "Kill Aura", "Serang mobs di sekitar", false, function(state) killAuraEnabled = state end, "KillAura")
Window:AddInput(CombatTab, "Radius", "Jangkauan serangan (Max 1000)", "300", function(value)
    local num = tonumber(value)
    if num then auraRadius = num end
end, "AuraRadius")

-- ==========================================
-- ITEM TP TAB (JACKPOT UPDATE!)
-- ==========================================
Window:AddParagraph(ItemTPTab, "Item TP", "Tarik item ke karakter melingkar")

-- Air Rifle dan armor ditambahkan sesuai path yang ditemukan
local itemCategories = {
    Food_Consumables = {"Berry", "Carrot", "Cake", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs"},
    Equipment_Weapons = {"Air Rifle", "Pistol", "Revolver", "Rifle", "Chainsaw", "Old Flashlight", "Rifle Ammo", "Revolver Ammo", "Spear"},
    Medic_Items = {"MedKit", "Bandage"},
    Armor_Clothing = {"Iron Body", "Leather Body"},
    Fuel_Items = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel", "Chair", "Metal Chair"},
    Junk_Materials = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Broken Microwave", "Mossy Coin"}
}

local selectedItems = {}

for catName, listItems in pairs(itemCategories) do
    selectedItems[catName] = listItems[1]
    Window:AddDropdown(ItemTPTab, catName:gsub("_", " "), "Pilih item", listItems, false, listItems[1], function(value) selectedItems[catName] = value end, "TP_" .. catName)
    Window:AddButton(ItemTPTab, "Bring " .. catName:gsub("_", " "), "Tarik semua item", "rbxassetid://16932740082", function()
        local hrp = getRootPart()
        if not hrp then return end
        local selected = selectedItems[catName]
        local count = 0
        local allItems = ItemsFolder:GetDescendants()
        local toProcess = {}
        for _, item in ipairs(allItems) do
            -- Kita pakai .match untuk nama Air Rifle dsb supaya akurat dengan nama instance
            if item.Name:match(selected) and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                table.insert(toProcess, item)
            end
        end
        
        local basePos = hrp.Position
        for i, item in ipairs(toProcess) do
            local angle = count * (math.pi * 2 / 8) 
            local radius = 3 + math.floor(count / 8) * 1.5 
            local tpPos = basePos + Vector3.new(math.cos(angle) * radius, 1, math.sin(angle) * radius)
            
            task.spawn(function() reliableDragItemToPos(item, tpPos) end)
            count = count + 1
            if i % 3 == 0 then task.wait(0.1) end 
        end
        Window:Notify({Title = "Success", Description = "Item TP", Content = "Berhasil menarik " .. count .. "x " .. selected, Color = Color3.fromRGB(10, 30, 60), Delay = 3})
    end)
    Window:AddDivider(ItemTPTab, "")
end

-- ==========================================
-- VISUALS TAB
-- ==========================================
Window:AddParagraph(VisualsTab, "ESP", "Deteksi lokasi visual")
local espMobsEnabled, espItemsEnabled = false, false
local espFolder = Instance.new("Folder")
espFolder.Name = "W424_ESP"
espFolder.Parent = CoreGui

local function createESP(instance, name, color)
    local part = findValidPart(instance)
    if not part then return end
    local hl = Instance.new("Highlight", espFolder)
    hl.Adornee, hl.FillColor, hl.OutlineColor = instance, color, Color3.new(1,1,1)
    hl.FillTransparency, hl.OutlineTransparency = 0.6, 0
    local bg = Instance.new("BillboardGui", espFolder)
    bg.Adornee, bg.Size, bg.AlwaysOnTop, bg.StudsOffset = part, UDim2.new(0, 120, 0, 25), true, Vector3.new(0, 3, 0)
    local txt = Instance.new("TextLabel", bg)
    txt.Size, txt.BackgroundTransparency, txt.TextColor3, txt.TextStrokeTransparency, txt.Font, txt.TextScaled = UDim2.new(1,0,1,0), 1, color, 0.2, Enum.Font.GothamBold, true
    task.spawn(function()
        while bg.Parent and instance.Parent do
            local hrp = getRootPart()
            if hrp then txt.Text = string.format("%s [%dm]", name, math.floor((part.Position - hrp.Position).Magnitude)) end
            task.wait(0.5)
        end
        hl:Destroy() bg:Destroy()
    end)
end

local function refreshESP()
    espFolder:ClearAllChildren()
    if espMobsEnabled then
        local chars = Workspace:FindFirstChild("Characters")
        if chars then for _, mob in ipairs(chars:GetChildren()) do createESP(mob, mob.Name, Color3.fromRGB(255,50,50)) end end
    end
    if espItemsEnabled then
        for _, item in ipairs(ItemsFolder:GetChildren()) do createESP(item, item.Name, Color3.fromRGB(50,255,50)) end
    end
end

Window:AddToggle(VisualsTab, "ESP Mobs", "Tampilkan lokasi mobs", false, function(state) espMobsEnabled = state; refreshESP() end, "ESPMobs")
Window:AddToggle(VisualsTab, "ESP Items", "Tampilkan lokasi items", false, function(state) espItemsEnabled = state; refreshESP() end, "ESPItems")

-- ==========================================
-- PLAYER TAB (INF JUMP)
-- ==========================================
Window:AddParagraph(PlayerTab, "Stats", "Modifikasi Karakter")
Window:AddSlider(PlayerTab, "WalkSpeed", "Kecepatan berjalan", 0, 200, 16, function(value)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = value end
end, "WalkSpeed", true)

local infiniteJumpEnabled = false
Window:AddToggle(PlayerTab, "Infinite Jump", "Lompat tanpa batas di udara", false, function(state) infiniteJumpEnabled = state end, "InfJump")
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ==========================================
-- AURA LOOPS
-- ==========================================
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getBestSpoofTool()
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                local chars = Workspace:FindFirstChild("Characters")
                if chars then
                    for _, mob in ipairs(chars:GetChildren()) do
                        local mobHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or findValidPart(mob)
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        if mobHrp and hum and hum.Health > 0 and (mobHrp.Position - hrp.Position).Magnitude <= auraRadius then
                            task.spawn(function() pcall(function() RemoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, mobHrp.CFrame) end) end)
                        end
                    end
                end
            end
        end
        task.wait(0.03) 
    end
end)

-- ==========================================
-- STABILIZED AUTO GRIND & FUEL
-- ==========================================
local processingItems = {}
task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        if hrp then
            for _, item in ipairs(ItemsFolder:GetDescendants()) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                if not (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then continue end
                local itemId = tostring(item)
                if processingItems[itemId] then continue end
                local shouldGrind = autoGrindItems[item.Name] == true
                local shouldFuel = autoFuelItems[item.Name] == true
                local shouldCook = autoCookEnabled and table.find(rawFoodsToCook, item.Name)
                
                if shouldGrind or shouldFuel or shouldCook then
                    local targetPos = shouldGrind and MACHINE_POS or CAMPFIRE_POS
                    local itemPos = getItemPosition(item)
                    if itemPos then
                        if (itemPos - hrp.Position).Magnitude > maxGrindRadius then continue end
                        if (itemPos - targetPos).Magnitude < 12 then continue end
                        processingItems[itemId] = true
                        task.spawn(function()
                            reliableDragItemToPos(item, targetPos)
                            task.wait(1) 
                            processingItems[itemId] = nil
                        end)
                        task.wait(0.1) 
                    end
                end
            end
        end
        task.wait(0.5) 
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
                    if table.find(autoEatFoods, item.Name) and item:IsDescendantOf(workspace) then table.insert(available, item) end
                end
                if #available > 0 then pcall(function() RemoteConsume:InvokeServer(available[math.random(1, #available)]) end) end
            end
        end
        task.wait(2)
    end
end)

Window:Notify({ Title = "W424 Hub", Description = "Loaded", Content = "v5.5: Air Rifle & Armors Added to TP!", Color = Color3.fromRGB(10, 30, 60), Delay = 5 })
