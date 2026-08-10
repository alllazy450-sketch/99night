-- ==========================================
-- W424 HUB | v5.23 Beta
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

-- Warna Biru Khas untuk Notifikasi & UI
local BLUE_COLOR = Color3.fromRGB(0, 120, 255)

-- Daftar senjata yang aman dari Auto Grind / Bring Item
local weaponBlacklist = {
    ["Rifle"] = true,
    ["Pistol"] = true,
    ["Revolver"] = true,
    ["Air Rifle"] = true,
    ["Chainsaw"] = true,
    ["Spear"] = true,
    ["Old Flashlight"] = true
}

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
        task.wait(0.03) -- Dipercepat agar lebih responsif
        
        if not item:IsDescendantOf(workspace) then return end
        resetVelocity(item)
        setItemCFrame(item, pos)
        
        task.wait(0.03)
        
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
    Badges = {"MOBILE", "v5.23"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    MinimizeButton_Image = "rbxassetid://116850882259653",
    Config = { Enabled = true, Folder = "W424_Config", AutoLoad = true }
})

local MainTab = Window:CreateTab("Main", "rbxassetid://16932740082")
local CombatTab = Window:CreateTab("Aura", "rbxassetid://16932740082")
local BringItemTab = Window:CreateTab("Bring Item", "rbxassetid://16932740082") -- Diubah dari Item TP
local TeleportsTab = Window:CreateTab("Teleports", "rbxassetid://16932740082") 
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")
local MiscTab = Window:CreateTab("Misc", "rbxassetid://16932740082")

-- ==========================================
-- MAIN TAB
-- ==========================================
Window:AddParagraph(MainTab, "Auto Farm & Automation", "Otomatisasi Makanan, Grind & Foliage")

local autoEatEnabled = false
local autoCookEnabled = false
local autoGrindEnabled = false -- Toggle On/Off Auto Grind
local autoFuelEnabled = false -- Toggle On/Off Auto Fuel
local autoFoliageChop = false
local autoEatFoods = {"Cooked Steak", "Cooked Morsel", "Berry", "Carrot", "Apple"}
local rawFoodsToCook = {"Morsel", "Steak"}
local maxGrindRadius = 10000 -- Diatur maksimal 10000 sesuai fandom 99 nights

Window:AddToggle(MainTab, "Auto Eat", "Makan otomatis saat HP < 70%", false, function(state) autoEatEnabled = state end, "AutoEat")
Window:AddToggle(MainTab, "Auto Cook", "Masak makanan mentah di Campfire", false, function(state) autoCookEnabled = state end, "AutoCook")
Window:AddToggle(MainTab, "Auto Grind", "Nyalakan/matikan otomatisasi kirim item ke mesin", false, function(state) autoGrindEnabled = state end, "AutoGrindToggle")
Window:AddToggle(MainTab, "Auto Feed Campfire", "Nyalakan/matikan otomatisasi bahan bakar", false, function(state) autoFuelEnabled = state end, "AutoFuelToggle")
Window:AddToggle(MainTab, "Auto Chop Foliage", "Tebang pohon/objek di workspace.Map.Foliage otomatis", false, function(state) autoFoliageChop = state end, "AutoFoliage")

Window:AddDivider(MainTab, "Radius Pengambilan")
Window:AddInput(MainTab, "Max Radius (10000)", "Batas jarak jangkauan", "10000", function(value)
    local num = tonumber(value)
    if num then maxGrindRadius = num end
end, "MaxGrabRadius")

local autoGrindItems = {}
Window:AddMultiDropdown(MainTab, "Select Grind Items", "Pilih item untuk mesin",
    {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Cultist Gem", "Sheet Metal", "Old Radio", "Tyre", "Washing Machine", "Gem of the Forest Fragment", "Broken Microwave"},
    {}, function(selected)
        autoGrindItems = {}
        for _, v in ipairs(selected) do autoGrindItems[v] = true end
    end, "AutoGrind"
)

local autoFuelItems = {}
Window:AddMultiDropdown(MainTab, "Select Fuel Items", "Pilih bahan bakar Campfire",
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
-- AURA TAB
-- ==========================================
Window:AddParagraph(CombatTab, "Combat", "Kill Aura (Improved & Fast)")
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

Window:AddToggle(CombatTab, "Kill Aura", "Serang mobs di sekitar dengan cepat", false, function(state) killAuraEnabled = state end, "KillAura")
Window:AddInput(CombatTab, "Radius", "Jangkauan serangan", "350", function(value)
    local num = tonumber(value)
    if num then auraRadius = num end
end, "AuraRadius")

-- ==========================================
-- BRING ITEM TAB (IMPROVED UP TO 10000 RADIUS)
-- ==========================================
Window:AddParagraph(BringItemTab, "Bring Items", "Tarik item ke karakter dengan cepat, presisi, dan luas (Max 10000)")

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
    Window:AddDropdown(BringItemTab, catName:gsub("_", " "), "Pilih item", listItems, false, listItems[1], function(value) selectedItems[catName] = value end, "Bring_" .. catName)
    Window:AddButton(BringItemTab, "Bring " .. catName:gsub("_", " "), "Tarik semua item kategori ini", "rbxassetid://16932740082", function()
        local hrp = getRootPart()
        if not hrp then return end
        local selected = selectedItems[catName]
        local count = 0
        local allItems = ItemsFolder:GetDescendants()
        local toProcess = {}
        for _, item in ipairs(allItems) do
            if item.Name == selected and not weaponBlacklist[item.Name] and (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then
                table.insert(toProcess, item)
            end
        end
        local basePos = hrp.Position + (hrp.CFrame.LookVector * 5)
        for i, item in ipairs(toProcess) do
            local itemPos = getItemPosition(item)
            if itemPos and (itemPos - hrp.Position).Magnitude <= maxGrindRadius then
                local tpPos = basePos + Vector3.new(0, 1 + (count * 1.2), 0)
                task.spawn(function() reliableDragItemToPos(item, tpPos) end)
                count = count + 1
            end
            if i % 5 == 0 then task.wait(0.02) end 
        end
        Window:Notify({Title = "Success", Description = "Bring Item", Content = "Berhasil menarik " .. count .. "x " .. selected, Color = BLUE_COLOR, Delay = 3})
    end)
    Window:AddDivider(BringItemTab, "")
end

-- ==========================================
-- MISC TAB (POTATO MODE & UTILS)
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
        
        Window:Notify({Title = "Success", Description = "Potato Mode", Content = "Map di-optimize! FPS meningkat drastis.", Color = BLUE_COLOR, Delay = 3})
    end)
end)

local fpsPingGui = Instance.new("ScreenGui")
fpsPingGui.Name = "W424_FPS_Ping"
fpsPingGui.ResetOnSpawn = false
fpsPingGui.Parent = CoreGui
fpsPingGui.Enabled = false

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 150, 0, 30)
fpsLabel.Position = UDim2.new(0, 10, 0, 120)
fpsLabel.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
fpsLabel.BackgroundTransparency = 0.4
fpsLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
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
        if chars then for _, mob in ipairs(chars:GetChildren()) do createESP(mob, mob.Name, Color3.fromRGB(0, 150, 255)) end end
    end
    if espItemsEnabled then
        for _, item in ipairs(ItemsFolder:GetChildren()) do createESP(item, item.Name, Color3.fromRGB(0, 255, 120)) end
    end
end

Window:AddToggle(VisualsTab, "ESP Mobs", "Tampilkan lokasi mobs", false, function(state) espMobsEnabled = state; refreshESP() end, "ESPMobs")
Window:AddToggle(VisualsTab, "ESP Items", "Tampilkan lokasi items", false, function(state) espItemsEnabled = state; refreshESP() end, "ESPItems")

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

-- ==========================================
-- BACKGROUND LOOPS & AUTOMATIONS
-- ==========================================

-- 1. Day / Night Automatic Notification System
task.spawn(function()
    local lastState = nil
    while ScriptRunning do
        pcall(function()
            local timeOfDay = Lighting.ClockTime
            -- Jam 6 pagi sampai 6 sore dianggap Pagi/Siang (Day), selebihnya Malam (Night)
            local isDay = (timeOfDay >= 6 and timeOfDay < 18)
            local currentState = isDay and "Morning" or "Night"
            
            if lastState ~= nil and lastState ~= currentState then
                if currentState == "Morning" then
                    Window:Notify({
                        Title = "W424 Time Alert",
                        Description = "Pagi Telah Tiba",
                        Content = "☀️ Matahari terbit! Waktu siang hari dimulai.",
                        Color = BLUE_COLOR,
                        Delay = 5
                    })
                else
                    Window:Notify({
                        Title = "W424 Time Alert",
                        Description = "Malam Telah Tiba",
                        Content = "🌙 Hari mulai gelap! Waspada terhadap mob malam.",
                        Color = Color3.fromRGB(20, 50, 150),
                        Delay = 5
                    })
                end
            end
            lastState = currentState
        end)
        task.wait(10)
    end
end)

-- 2. Improved Kill Aura Loop
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
        task.wait(0.01) -- Dibuat sangat cepat
    end
end)

-- 3. Foliage Auto Chop Loop
task.spawn(function()
    while ScriptRunning do
        if autoFoliageChop then
            local hrp = getRootPart()
            local tool, damageID = getBestSpoofTool()
            local foliageFolder = workspace.Map:FindFirstChild("Foliage")
            if hrp and tool and damageID and foliageFolder then
                pcall(function() RemoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                for _, foliageObj in ipairs(foliageFolder:GetChildren()) do
                    if not autoFoliageChop then break end
                    local part = findValidPart(foliageObj)
                    if part and (part.Position - hrp.Position).Magnitude <= 50 then
                        pcall(function()
                            RemoteEvents.ToolDamageObject:InvokeServer(foliageObj, tool, damageID, part.CFrame)
                        end)
                        task.wait(0.05)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- 4. Auto Grind & Auto Fuel Loop (Controlled by Toggle On/Off)
local processingItems = {}
task.spawn(function()
    while ScriptRunning do
        local hrp = getRootPart()
        -- Jalankan hanya jika salah satu fitur (Auto Grind atau Auto Fuel) aktif melalui toggle
        if hrp and (autoGrindEnabled or autoFuelEnabled) then
            for _, item in ipairs(ItemsFolder:GetDescendants()) do
                if not item or not item:IsDescendantOf(workspace) then continue end
                if not (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) then continue end
                
                if weaponBlacklist[item.Name] then continue end
                
                local itemId = tostring(item)
                if processingItems[itemId] then continue end
                
                local shouldGrind = autoGrindEnabled and (autoGrindItems[item.Name] == true)
                local shouldFuel = autoFuelEnabled and (autoFuelItems[item.Name] == true)
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
                            task.wait(0.5) 
                            processingItems[itemId] = nil
                        end)
                        task.wait(0.05) 
                    end
                end
            end
        end
        task.wait(0.3) 
    end
end)

-- 5. Auto Eat Loop
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

Window:Notify({ Title = "W424 Hub", Description = "Loaded Successfully", Content = "v5.23: Bring Item 10K & Blue Theme Active!", Color = BLUE_COLOR, Delay = 5 })
