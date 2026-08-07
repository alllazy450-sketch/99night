-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE REWRITE V5 (BYPASS PHYSICS & 1K+ RADIUS)
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL STATE & SETTINGS
-- ==========================================
getgenv().W424 = {
    -- Auto Wood
    AutoWood = false,
    WoodRadius = 50, -- Bisa diset sampai 5000 via UI
    BlinkHit = true, -- Teleport sekilas untuk bypass server-side drop
    
    -- Auto Hunt Mob
    AutoHunt = false,
    HuntRadius = 50,
    TargetMob = "Bunny",
    
    -- Auto Chest & Claim
    AutoBringChest = false,
    AutoClaimDrops = false,
    
    -- Auto Feed Campfire
    AutoFeed = false,
    FeedMaterial = "Log"
}

-- Mapping ID Kapak/Senjata agar valid di server
local function getDamageID(toolName)
    if toolName:find("Good") then return "112_" .. tostring(LocalPlayer.UserId) end
    if toolName:find("Strong") then return "116_" .. tostring(LocalPlayer.UserId) end
    if toolName:find("Sword") then return "12_" .. tostring(LocalPlayer.UserId) end
    -- Default / Old Axe
    return "1_" .. tostring(LocalPlayer.UserId)
end

-- ==========================================
-- ROBUST UTILITY FUNCTIONS
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end

    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end

    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for _, v in pairs(inv:GetChildren()) do
            if v:IsA("Tool") and (v.Name:find("Axe") or v.Name:find("Sword") or v.Name:find("Spear")) then
                local hum = char:FindFirstChild("Humanoid")
                if hum then 
                    pcall(function() hum:EquipTool(v) end) 
                    task.wait(0.2)
                end
                return v
            end
        end
    end
    return nil
end

-- ==========================================
-- PHYSICS & HIT ENGINE (BYPASS SERVER SIDE)
-- ==========================================
local function executeHit(target, tool, targetPart)
    local hrp = getHRP()
    if not hrp or not targetPart then return end

    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if not damageRemote then return end

    local damageID = getDamageID(tool.Name)
    local originalCFrame = hrp.CFrame

    -- Jika jarak terlalu jauh, lakukan Blink (Ghost Hit) agar item DROP disahkan server
    local distance = (hrp.Position - targetPart.Position).Magnitude
    if distance > 20 and getgenv().W424.BlinkHit then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3) -- Teleport 3 stud di depan target
        task.wait(0.05) -- Tunggu server mendaftarkan posisi baru
        
        -- Eksekusi Hit dengan CFrame yang sangat presisi
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position))
        end)
        
        task.wait(0.05)
        hrp.CFrame = originalCFrame -- Kembali ke posisi awal
    else
        -- Jika dekat, langsung pukul murni (Pure Aura)
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position))
        end)
    end
end

-- ==========================================
-- 1. AUTO FARM WOOD (IMPROVED DETECTION)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.AutoWood then
            pcall(function()
                local hrp = getHRP()
                local tool = getEquippedWeapon()
                if not hrp or not tool then return end
                
                local foliage = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if foliage then
                    for _, v in ipairs(foliage:GetChildren()) do
                        if not getgenv().W424.AutoWood then break end
                        
                        -- Deteksi lebih luas untuk jenis part pohon
                        local mainPart = v:FindFirstChild("Trunk") or v:FindFirstChild("Trunk1") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                        if mainPart then
                            local dist = (hrp.Position - mainPart.Position).Magnitude
                            if dist <= getgenv().W424.WoodRadius then
                                executeHit(v, tool, mainPart)
                                task.wait(0.1) -- Jeda antar tebangan agar tidak di-kick
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 2. AUTO HUNT MOB (AURA / BLINK)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                local tool = getEquippedWeapon()
                if not hrp or not tool then return end

                local targetName = getgenv().W424.TargetMob
                local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace

                for _, v in ipairs(enemiesFolder:GetChildren()) do
                    if not getgenv().W424.AutoHunt then break end
                    
                    if v:IsA("Model") and v.Name:find(targetName) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local mainPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                        if mainPart then
                            local dist = (hrp.Position - mainPart.Position).Magnitude
                            if dist <= getgenv().W424.HuntRadius then
                                executeHit(v, tool, mainPart)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 3. BRING CHEST & CLAIM DROPS (ADVANCED)
-- ==========================================
local function dragItemToPlayer(item, targetPos)
    pcall(function()
        local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
        
        if startDrag then startDrag:FireServer(item) end
        task.wait(0.05)
        
        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if part then
            part.CFrame = CFrame.new(targetPos)
            part.Velocity = Vector3.new(0, 0, 0)
        end
        
        if stopDrag then stopDrag:FireServer(item) end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        local hrp = getHRP()
        if not hrp or not itemFolder then continue end

        -- Fitur Bring Chest & Buka Otomatis[span_0](start_span)[span_0](end_span)[span_1](start_span)[span_1](end_span)
        if getgenv().W424.AutoBringChest then
            pcall(function()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoBringChest then break end
                    
                    if item.Name:find("Chest") then
                        local main = item:FindFirstChild("Main") or item.PrimaryPart
                        if main then
                            -- Cari ProximityPrompt di dalam Chest
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    -- Bawa peti ke pemain dulu
                                    dragItemToPlayer(item, hrp.Position + Vector3.new(0, 2, 2))
                                    task.wait(0.1)
                                    
                                    -- Bypass Line of Sight & Buka
                                    obj.RequiresLineOfSight = false
                                    fireproximityprompt(obj)
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- Fitur Auto Claim Drops (Kayu, Coin, dll)
        if getgenv().W424.AutoClaimDrops then
            pcall(function()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if not item.Name:find("Chest") and item:IsA("Model") then
                        -- Bawa semua item drop langsung ke HRP pemain
                        dragItemToPlayer(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 4. AUTO FEED CAMPFIRE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                local burnRemote = RemotesFolder:FindFirstChild("RequestBurnItem")
                local inv = LocalPlayer:FindFirstChild("Inventory")
                if not burnRemote or not inv then return end

                local feedMat = getgenv().W424.FeedMaterial
                for _, item in ipairs(inv:GetChildren()) do
                    if item.Name:lower():find(feedMat:lower()) then
                        burnRemote:FireServer(item)
                        task.wait(0.3) -- Jeda agar tidak spam remote
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- FLUENT UI INTERFACE
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    SubTitle = "Ultimate Edition (Bypass Physics)",
    TabWidth = 140,
    Size = UDim2.new(0, 520, 0, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Aura & Farming", Icon = "zap" }),
    Loot = Window:AddTab({ Title = "Loot & Feed", Icon = "box" })
}

-- TAB: AURA & FARMING
Tabs.Farm:AddParagraph({ Title = "Wood Farming Engine", Content = "Blink Hit memastikan kayu 100% drop walaupun dari jauh." })

Tabs.Farm:AddToggle("AutoWood", {Title = "Auto Farm Wood (Aura)", Default = getgenv().W424.AutoWood}):OnChanged(function(v) getgenv().W424.AutoWood = v end)

Tabs.Farm:AddToggle("BlinkHit", {Title = "Enable Blink Hit (Bypass Server-Side)", Default = getgenv().W424.BlinkHit}):OnChanged(function(v) getgenv().W424.BlinkHit = v end)

-- Slider dengan Input, bisa diketik sampai 5000+
Tabs.Farm:AddSlider("WoodRadius", {
    Title = "Wood Aura Radius (Studs)",
    Min = 10,
    Max = 5000, 
    Default = getgenv().W424.WoodRadius,
    Callback = function(v) getgenv().W424.WoodRadius = v end
})

Tabs.Farm:AddParagraph({ Title = "Mob Hunting Engine", Content = "" })
Tabs.Farm:AddToggle("AutoHunt", {Title = "Auto Kill Mob (Aura)", Default = getgenv().W424.AutoHunt}):OnChanged(function(v) getgenv().W424.AutoHunt = v end)

Tabs.Farm:AddDropdown("TargetMob", {
    Title = "Select Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Deer", "Cultist", "Boss"},
    Default = getgenv().W424.TargetMob,
    Callback = function(v) getgenv().W424.TargetMob = v end
})

Tabs.Farm:AddSlider("HuntRadius", {
    Title = "Kill Aura Radius (Studs)",
    Min = 10,
    Max = 5000, 
    Default = getgenv().W424.HuntRadius,
    Callback = function(v) getgenv().W424.HuntRadius = v end
})

-- TAB: LOOT & FEED
Tabs.Loot:AddParagraph({ Title = "Chest & Drops Manager", Content = "" })

Tabs.Loot:AddToggle("AutoChest", {Title = "Auto Bring & Open Chests", Default = getgenv().W424.AutoBringChest}):OnChanged(function(v) getgenv().W424.AutoBringChest = v end)
Tabs.Loot:AddToggle("AutoClaim", {Title = "Auto Bring All Drops (Wood/Items)", Default = getgenv().W424.AutoClaimDrops}):OnChanged(function(v) getgenv().W424.AutoClaimDrops = v end)

Tabs.Loot:AddParagraph({ Title = "Campfire Manager", Content = "" })

Tabs.Loot:AddToggle("AutoFeed", {Title = "Auto Feed Campfire", Default = getgenv().W424.AutoFeed}):OnChanged(function(v) getgenv().W424.AutoFeed = v end)

Tabs.Loot:AddDropdown("FeedMaterial", {
    Title = "Feed Material Index",
    Values = {"Log", "Stick", "Coal", "Fiber", "Meat", "Fish"},
    Default = getgenv().W424.FeedMaterial,
    Callback = function(v) getgenv().W424.FeedMaterial = v end
})

-- ==========================================
-- SUPER BUBBLE UI (FLOATING TOGGLE)
-- ==========================================
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("W424_Toggle") then CoreGui.W424_Toggle:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "W424_Toggle"
    ScreenGui.Parent = CoreGui
    ScreenGui.DisplayOrder = 2147483647 
    ScreenGui.ResetOnSpawn = false

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 15, 0.25, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ToggleBtn.Text = "UI"
    ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 16
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true
    
    local UICorner = Instance.new("UICorner", ToggleBtn)
    UICorner.CornerRadius = UDim.new(1, 0)
    
    local UIStroke = Instance.new("UIStroke", ToggleBtn)
    UIStroke.Color = Color3.fromRGB(0, 255, 150)
    UIStroke.Thickness = 2.5

    -- Menghubungkan tombol melayang dengan minimize key bawaan Fluent UI
    ToggleBtn.MouseButton1Down:Connect(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)
end)

Fluent:Notify({ Title = "System Matang", Content = "Blink Physics & 5000+ Radius Aktif!", Duration = 4 })
