-- ==========================================
-- W424 HUB | v5.24 (Fixed Tree Aura + Drop)
-- ==========================================

local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteConsume = ReplicatedStorage:FindFirstChild("RequestConsumeItem")

local ScriptRunning = true
local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)

local LostChildPath = nil
pcall(function()
    LostChildPath = workspace.Map.Landmarks["Jail Cellar1"].Dino
end)

-- ==========================================
-- TREE AURA VARIABLES
-- ==========================================
local TreesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
local treeAuraEnabled = false
local treeAuraRadius = 350
local valueAxe = "1_" .. LocalPlayer.UserId

-- Tree ESP
local treeESPEnabled = false
local treeESPList = {}
local espFolder = Instance.new("Folder")
espFolder.Name = "W424_TreeESP"
espFolder.Parent = CoreGui

-- ==========================================
-- GODMODE VARIABLES
-- ==========================================
local godmodeEnabled = false
local godmodeRemote = RemoteEvents:FindFirstChild("DamagePlayer")

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
-- MOBILE UI SETUP
-- ==========================================
local cam = workspace.CurrentCamera
local screenSize = cam and cam.ViewportSize or Vector2.new(500, 420)
local uiWidth = math.min(340, math.max(300, screenSize.X * 0.9))
local uiHeight = math.min(420, math.max(320, screenSize.Y * 0.78))

local Window = Kairo:CreateWindow({
    Title = "W424 Hub",
    Theme = "Midnight",
    Size = UDim2.fromOffset(uiWidth, uiHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"v5.24", "FIXED"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = { Enabled = true, Folder = "W424_Config", AutoLoad = true }
})

local MainTab = Window:CreateTab("Main", "rbxassetid://16932740082")
local CombatTab = Window:CreateTab("Combat", "rbxassetid://16932740082")
local TreeTab = Window:CreateTab("Tree Aura", "rbxassetid://16932740082")
local ItemTPTab = Window:CreateTab("Item TP", "rbxassetid://16932740082")
local TeleportsTab = Window:CreateTab("Teleports", "rbxassetid://16932740082") 
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")
local MiscTab = Window:CreateTab("Misc", "rbxassetid://16932740082")

-- ==========================================
-- MAIN TAB
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
Window:AddInput(MainTab, "Max Grab Radius", "Batas jarak ambil item", "1000", function(value)
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
-- TELEPORTS TAB
-- ==========================================
Window:AddParagraph(TeleportsTab, "Locations", "Teleportasi Karakter")
Window:AddButton(TeleportsTab, "TP to Campfire", "Kembali ke area perapian", "rbxassetid://16932740082", function() teleportPlayerTo(CAMPFIRE_POS) end)
Window:AddButton(TeleportsTab, "TP to Lost Child", "Teleport ke Dino (Jail Cellar)", "rbxassetid://16932740082", function()
    if LostChildPath then
        local targetPart = findValidPart(LostChildPath)
        if targetPart then teleportPlayerTo(targetPart.Position) end
    end
end)

-- ==========================================
-- COMBAT TAB (Kill Aura)
-- ==========================================
Window:AddParagraph(CombatTab, "Kill Aura", "Serang mobs di sekitar")
local killAuraEnabled = false
local auraRadius = 350 
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
Window:AddInput(CombatTab, "Radius", "Jangkauan serangan", "350", function(value)
    local num = tonumber(value)
    if num then auraRadius = num end
end, "AuraRadius")

-- ==========================================
-- TREE AURA TAB (FIXED)
-- ==========================================
Window:AddParagraph(TreeTab, "Tree Aura", "Nebang pohon otomatis di sekitar")
Window:AddToggle(TreeTab, "Tree Aura", "Tebang pohon di radius tertentu", false, function(state) 
    treeAuraEnabled = state 
end, "TreeAura")
Window:AddInput(TreeTab, "Tree Radius", "Jarak tebang pohon", "350", function(value)
    local num = tonumber(value)
    if num then treeAuraRadius = num end
end, "TreeRadius")
Window:AddParagraph(TreeTab, "Info", "Pohon yang ditebang: Small Tree\nGunakan Old Axe di inventory")

-- ==========================================
-- ITEM TP TAB
-- ==========================================
Window:AddParagraph(ItemTPTab, "Item TP", "Tarik item ke karakter dengan stabil")

local itemCategories = {
    Food_Consumables = {"Berry", "Carrot", "Cake", "Apple", "Steak", "Morsel", "Cooked Steak", "Cooked Morsel", "Pumpkin", "Ribs"},
    Equipment_Weapons = {"Pistol", "Revolver", "Rifle", "Chainsaw", "Old Flashlight", "Rifle Ammo", "Revolver Ammo", "Spear"},
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
            if item.Name == selected and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                table.insert(toProcess, item)
            end
        end
        local basePos = hrp.Position + (hrp.CFrame.LookVector * 5)
        for i, item in ipairs(toProcess) do
            local tpPos = basePos + Vector3.new(0, 1 + (count * 1.5), 0)
            task.spawn(function() reliableDragItemToPos(item, tpPos) end)
            count = count + 1
            if i % 2 == 0 then task.wait(0.15) end 
        end
        Window:Notify({Title = "Success", Description = "Item TP", Content = "Berhasil menarik " .. count .. "x " .. selected, Color = Color3.fromRGB(10, 30, 60), Delay = 3})
    end)
    Window:AddDivider(ItemTPTab, "")
end

-- ==========================================
-- VISUALS TAB (FIXED TREE ESP)
-- ==========================================
Window:AddParagraph(VisualsTab, "ESP", "Deteksi lokasi visual")

-- ESP Mobs & Items
local espMobsEnabled, espItemsEnabled = false, false
local espFolderMobs = Instance.new("Folder")
espFolderMobs.Name = "W424_ESP_MobsItems"
espFolderMobs.Parent = CoreGui

local function createESP(instance, name, color)
    local part = findValidPart(instance)
    if not part then return end
    local hl = Instance.new("Highlight", espFolderMobs)
    hl.Adornee, hl.FillColor, hl.OutlineColor = instance, color, Color3.new(1,1,1)
    hl.FillTransparency, hl.OutlineTransparency = 0.6, 0
    local bg = Instance.new("BillboardGui", espFolderMobs)
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
    espFolderMobs:ClearAllChildren()
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

-- Tree ESP (FIXED)
local treeESPEnabled = false
local treeESPList = {}
local espFolderTree = Instance.new("Folder")
espFolderTree.Name = "W424_TreeESP"
espFolderTree.Parent = CoreGui

local function getTreePart(tree)
    -- Cari bagian pohon yang valid (Trunk atau PrimaryPart)
    local trunk = tree:FindFirstChild("Trunk")
    if trunk and trunk:IsA("BasePart") then return trunk end
    if tree.PrimaryPart then return tree.PrimaryPart end
    -- Cari part pertama yang bukan anak dari model lain
    for _, child in ipairs(tree:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("MeshPart") then
            return child
        end
    end
    return nil
end

local function createTreeESP(tree)
    if treeESPList[tree] then return end
    local part = getTreePart(tree)
    if not part then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "TreeESP"
    bb.Size = UDim2.fromScale(4, 1)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espFolderTree
    bb.Adornee = part

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0
    text.TextColor3 = Color3.fromRGB(0, 255, 0)
    text.Parent = bb

    treeESPList[tree] = {
        gui = bb,
        label = text,
        part = part
    }
end

local function updateTreeESP(tree)
    local esp = treeESPList[tree]
    if not esp then return end
    local hp = tree:GetAttribute("Health")
    if not hp then
        esp.gui:Destroy()
        treeESPList[tree] = nil
        return
    end
    esp.label.Text = ("HP: %d"):format(hp)
    if hp > 5 then
        esp.label.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif hp > 2 then
        esp.label.TextColor3 = Color3.fromRGB(255, 170, 0)
    else
        esp.label.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end

local function refreshTreeESP()
    for _, esp in pairs(treeESPList) do
        pcall(function() esp.gui:Destroy() end)
    end
    treeESPList = {}
    if treeESPEnabled and TreesFolder then
        for _, tree in ipairs(TreesFolder:GetChildren()) do
            if tree.Name == "Small Tree" then
                createTreeESP(tree)
                updateTreeESP(tree)
            end
        end
    end
end

Window:AddToggle(VisualsTab, "ESP Trees", "Tampilkan HP pohon", false, function(state) 
    treeESPEnabled = state
    if state then
        refreshTreeESP()
    else
        for _, esp in pairs(treeESPList) do
            pcall(function() esp.gui:Destroy() end)
        end
        treeESPList = {}
    end
end, "ESPTrees")

-- ==========================================
-- PLAYER TAB
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

-- Godmode
Window:AddToggle(PlayerTab, "Godmode", "Mengirim damage negatif ke server (tidak mati)", false, function(state)
    godmodeEnabled = state
    if state and not godmodeRemote then
        Window:Notify({
            Title = "Error",
            Description = "Remote DamagePlayer tidak ditemukan!",
            Content = "Godmode mungkin tidak bekerja.",
            Color = Color3.fromRGB(255, 0, 0),
            Delay = 3
        })
    elseif state and godmodeRemote then
        Window:Notify({
            Title = "Godmode",
            Description = "Godmode diaktifkan!",
            Content = "Mengirim damage negatif setiap 0.5 detik.",
            Color = Color3.fromRGB(0, 200, 255),
            Delay = 3
        })
    end
end, "Godmode")

-- ==========================================
-- MISC TAB
-- ==========================================
Window:AddParagraph(MiscTab, "Miscellaneous", "Fitur Tambahan & Optimasi")

local fullbrightConn = nil
Window:AddToggle(MiscTab, "Fullbright", "Membuat seluruh map menjadi terang benderang", false, function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        fullbrightConn = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        end)
    else
        if fullbrightConn then
            fullbrightConn:Disconnect()
            fullbrightConn = nil
        end
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
    end
end, "FullbrightToggle")

Window:AddButton(MiscTab, "Reduce Map (Potato Mode)", "Hapus tekstur, part kecil & efek berat untuk boost FPS", "rbxassetid://16932740082", function()
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                if obj.Size.Magnitude < 1.5 and not obj.Anchored and not obj:IsDescendantOf(LocalPlayer.Character) then
                    obj:Destroy()
                end
            elseif obj:IsA("Texture") or obj:IsA("Decal") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj:Destroy()
            elseif obj:IsA("PostEffect") then
                obj.Enabled = false
            end
        end
        
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
                effect:Destroy()
            end
        end
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
        
        Window:Notify({Title = "Success", Description = "Potato Mode", Content = "Map di-optimize! FPS meningkat drastis.", Color = Color3.fromRGB(0, 200, 0), Delay = 3})
    end)
end)

-- FPS & Ping Counter
local fpsPingGui = Instance.new("ScreenGui")
fpsPingGui.Name = "W424_FPS_Ping"
fpsPingGui.ResetOnSpawn = false
fpsPingGui.Parent = CoreGui
fpsPingGui.Enabled = false

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 150, 0, 30)
fpsLabel.Position = UDim2.new(0, 10, 0, 120)
fpsLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
fpsLabel.BackgroundTransparency = 0.4
fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
fpsLabel.TextSize = 14
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Text = "FPS: 0 | Ping: 0ms"
fpsLabel.Parent = fpsPingGui
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 6)

local lastTick = tick()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastTick >= 1 then
        local fps = math.round(frameCount / (tick() - lastTick))
        local ping = 0
        pcall(function()
            ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
        end)
        fpsLabel.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
        frameCount = 0
        lastTick = tick()
    end
end)

Window:AddToggle(MiscTab, "FPS & Ping Counter", "Tampilkan indikator FPS & Ping di layar", false, function(state)
    fpsPingGui.Enabled = state
end, "FpsPingToggle")

-- Auto Night/Day Notification
local wasNight = nil
local function checkTime()
    local currentTime = Lighting.ClockTime
    local isNight = (currentTime >= 18 or currentTime < 6)
    if wasNight == nil then
        wasNight = isNight
        return
    end
    if isNight and not wasNight then
        Window:Notify({
            Title = "🌙 Night Time",
            Description = "Hari telah berubah menjadi malam, hati hati dengan mob!",
            Content = string.format("Jam: %.1f", currentTime),
            Color = Color3.fromRGB(20, 20, 80),
            Delay = 4
        })
    elseif not isNight and wasNight then
        Window:Notify({
            Title = "☀️ Day Time",
            Description = "Hari telah berubah menjadi siang!",
            Content = string.format("Jam: %.1f", currentTime),
            Color = Color3.fromRGB(200, 180, 50),
            Delay = 4
        })
    end
    wasNight = isNight
end
checkTime()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(checkTime)

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================

-- 1. KILL AURA (MOBS)
task.spawn(function()
    while ScriptRunning do
        if killAuraEnabled then
            local hrp = getRootPart()
            local tool, damageID = getBestSpoofTool()
            if hrp and tool and damageID then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                
                local searchFolders = {Workspace:FindFirstChild("Characters"), Workspace}
                for _, folder in ipairs(searchFolders) do
                    if folder then
                        for _, mob in ipairs(folder:GetChildren()) do
                            local hum = mob:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 and mob ~= LocalPlayer.Character then
                                local mobHrp = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart or findValidPart(mob)
                                if mobHrp then
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
            end
        end
        task.wait(0.02) 
    end
end)

-- 2. TREE AURA (FIXED)
task.spawn(function()
    while ScriptRunning do
        if treeAuraEnabled and TreesFolder then
            local hrp = getRootPart()
            if hrp then
                -- Cari Old Axe
                local tool = nil
                local locations = {LocalPlayer.Inventory, LocalPlayer.Backpack, LocalPlayer.Character}
                for _, loc in ipairs(locations) do
                    if loc then
                        local axe = loc:FindFirstChild("Old Axe")
                        if axe then tool = axe; break end
                    end
                end
                if not tool then
                    task.wait(1)
                else
                    for _, tree in ipairs(TreesFolder:GetChildren()) do
                        if tree.Name == "Small Tree" and tree:IsDescendantOf(workspace) then
                            -- Cari bagian pohon yang valid
                            local treePart = getTreePart(tree)
                            if not treePart then continue end
                            local dist = (treePart.Position - hrp.Position).Magnitude
                            if dist <= treeAuraRadius then
                                local hp = tree:GetAttribute("Health")
                                if hp == nil then hp = 10 end -- default jika tidak ada atribut
                                if hp > 0 then
                                    pcall(function()
                                        RemoteEvents.ToolDamageObject:InvokeServer(tree, tool, valueAxe, treePart.CFrame)
                                    end)
                                    -- Beri jeda agar proses drop terjadi
                                    task.wait(0.15)
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

-- 3. AUTO GRIND / COOK / FUEL
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

-- 4. AUTO EAT
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

-- 5. TREE ESP REFRESH (FIXED)
task.spawn(function()
    while ScriptRunning do
        if treeESPEnabled and TreesFolder then
            for _, tree in ipairs(TreesFolder:GetChildren()) do
                if tree.Name == "Small Tree" then
                    createTreeESP(tree)
                    updateTreeESP(tree)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- 6. GODMODE LOOP
task.spawn(function()
    while ScriptRunning do
        if godmodeEnabled and godmodeRemote then
            pcall(function()
                godmodeRemote:FireServer(-math.huge)
            end)
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- INITIAL NOTIFICATION
-- ==========================================
Window:Notify({ 
    Title = "W424 Hub", 
    Description = "Loaded", 
    Content = "v5.24: Fixed Tree Aura + Drop", 
    Color = Color3.fromRGB(10, 30, 60), 
    Delay = 5 
})