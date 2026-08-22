-- ============================================================
-- W424 HUB | v5.40 PRO (SURVIVAL ENGINE)
-- Game: 99 Night in the Forest
-- Features: Auto Escape, Smart Grind, Halloween TP, Kill Aura
-- ============================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/Oxidelib/main/Oxidelib.lua"))()
Library:SetTheme("Midnight")

local MY_LOGO = "rbxassetid://70773874533764"

-- [ SERVICES & VARIABLES ]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ItemsFolder = Workspace:FindFirstChild("Items") or Workspace:WaitForChild("Items")
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local RemoteConsume = ReplicatedStorage:FindFirstChild("RequestConsumeItem")
local Characters = Workspace:FindFirstChild("Characters")

local CAMPFIRE_POS = Vector3.new(0, 19, 0)
local MACHINE_POS = Vector3.new(21, 16, -5)
local SAFE_POINT = Vector3.new(0, 200, 0) -- Koordinat aman di langit

local LostChildPath = nil
pcall(function() LostChildPath = workspace.Map.Landmarks["Jail Cellar1"].Dino end)

-- [ STATE SETTINGS ]
local Toggles = { 
    AutoEat = false, AutoCook = false, AutoGrind = false, 
    KillAura = false, TreeAura = false, Fullbright = false,
    ESP_Mobs = false, ESP_Items = false, ESP_Trees = false,
    InfJump = false, AutoEscape = false, AntiAFK = true
}
local Settings = {
    EatThreshold = 70, AuraRadius = 350, TreeRadius = 80,
    WalkSpeed = 16, GrindRadius = 1000, EscapeDist = 40
}

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function getRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

local function findValidPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function teleportPlayerTo(pos)
    local hrp = getRoot()
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
end

local function reliableDrag(item, pos)
    pcall(function()
        local dragStart = RemoteEvents:FindFirstChild("RequestStartDraggingItem")
        local dragStop = RemoteEvents:FindFirstChild("StopDraggingItem")
        if dragStart then dragStart:FireServer(item) end
        task.wait(0.1)
        if item:IsA("BasePart") then item.CFrame = CFrame.new(pos) 
        elseif item:IsA("Model") then item:PivotTo(CFrame.new(pos)) end
        task.wait(0.1)
        if dragStop then dragStop:FireServer(item) end
    end)
end

-- ==========================================
-- UI WINDOW SETUP
-- ==========================================
local Window = Library:CreateWindow({
    Name = "W424 HUB",
    BrandSubtitle = "99 Night PRO v5.40",
    Logo = MY_LOGO,
    LogoZoom = 1.5,
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(720, 580),
})

local TabMain = Window:AddTab({ Name = "Main", Icon = "home" })
local TabAura = Window:AddTab({ Name = "Aura", Icon = "zap" })
local TabTP   = Window:AddTab({ Name = "Teleport", Icon = "map-pin" })
local TabVis  = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local TabMisc = Window:AddTab({ Name = "Misc", Icon = "settings" })

-- ===== MAIN TAB =====
local SubAuto = TabMain:AddSubTab("Auto Survival")
SubAuto:AddSection("HUNGER & COOKING")
SubAuto:AddToggle({ Name = "Auto Eat", Default = false, Callback = function(v) Toggles.AutoEat = v end })
SubAuto:AddSlider({ Name = "Eat Threshold (%)", Min = 10, Max = 95, Default = 70, Callback = function(v) Settings.EatThreshold = v end })
SubAuto:AddToggle({ Name = "Auto Cook", Default = false, Callback = function(v) Toggles.AutoCook = v end })

local SubGrind = TabMain:AddSubTab("Machine Loop")
SubGrind:AddSection("SMART GRIND SETTINGS")
SubGrind:AddToggle({ Name = "Auto Grind Items (Loop)", Default = false, Tooltip = "Otomatis kirim Junk ke mesin", Callback = function(v) Toggles.AutoGrind = v end })
SubGrind:AddSlider({ Name = "Scan Radius", Min = 100, Max = 3000, Default = 1000, Callback = function(v) Settings.GrindRadius = v end })

-- ===== AURA TAB =====
local SubCombat = TabAura:AddSubTab("Kill Aura")
SubCombat:AddSection("COMBAT PROTECTION")
SubCombat:AddToggle({ Name = "Kill Aura (Mobs)", Default = false, Callback = function(v) Toggles.KillAura = v end })
SubCombat:AddSlider({ Name = "Aura Radius", Min = 50, Max = 800, Default = 350, Callback = function(v) Settings.AuraRadius = v end })

local SubEscape = TabAura:AddSubTab("Auto Escape")
SubEscape:AddSection("PANIC SYSTEM")
SubEscape:AddToggle({ Name = "Enable Auto Escape", Default = false, Tooltip = "Teleport ke langit jika bahaya", Callback = function(v) Toggles.AutoEscape = v end })
SubEscape:AddSlider({ Name = "Safety Distance", Min = 10, Max = 100, Default = 40, Callback = function(v) Settings.EscapeDist = v end })

-- ===== TELEPORT TAB =====
local SubTele = TabTP:AddSubTab("Locations")
SubTele:AddSection("GENERAL LOCATIONS")
SubTele:AddButton({ Name = "TP to Campfire", Callback = function() teleportPlayerTo(CAMPFIRE_POS) end })
SubTele:AddButton({ Name = "TP to Lost Child (Dino)", Callback = function()
    if LostChildPath then
        local targetPart = findValidPart(LostChildPath)
        if targetPart then teleportPlayerTo(targetPart.Position) end
    end
end })

SubTele:AddSection("EVENT LOCATIONS")
SubTele:AddButton({ Name = "TP to Lost Child (Halloween)", Callback = function()
    local found = false
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name and obj.Name:lower():find("lost child") then
            local part = findValidPart(obj)
            if part then
                teleportPlayerTo(part.Position)
                found = true
                Library:Notify({ Title = "TP Success", Content = "Found: " .. obj.Name, Type = "success" })
                break
            end
        end
    end
    if not found then Library:Notify({ Title = "TP Failed", Content = "Lost Child not found", Type = "warning" }) end
end })

-- ===== VISUALS TAB =====
local SubESP = TabVis:AddSubTab("ESP Settings")
SubESP:AddToggle({ Name = "ESP Mobs", Default = false, Callback = function(v) Toggles.ESP_Mobs = v end })
SubESP:AddToggle({ Name = "ESP Items", Default = false, Callback = function(v) Toggles.ESP_Items = v end })

-- ===== MISC TAB =====
local SubPlayer = TabMisc:AddSubTab("Player")
SubPlayer:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = 16, Callback = function(v) 
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end })
SubPlayer:AddToggle({ Name = "Infinite Jump", Default = false, Callback = function(v) Toggles.InfJump = v end })

-- ==========================================
-- LOGIC LOOPS
-- ==========================================

-- Smart Grind Loop (PRO Optimizer)
task.spawn(function()
    local junkItems = {"UFO Junk", "UFO Component", "Old Car Engine", "Broken Fan", "Old Microwave", "Bolt", "Log", "Sheet Metal", "Washing Machine", "Tyre"}
    while task.wait(1.5) do
        if Toggles.AutoGrind then
            local hrp = getRoot()
            if hrp then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if table.find(junkItems, item.Name) then
                        local iPart = findValidPart(item)
                        if iPart and (iPart.Position - hrp.Position).Magnitude <= Settings.GrindRadius then
                            reliableDrag(item, MACHINE_POS)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Escape (Panic System)
task.spawn(function()
    while task.wait(0.3) do
        if Toggles.AutoEscape then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = getRoot()
            if hum and hrp then
                -- Escape karena darah rendah
                if hum.Health < 30 then
                    teleportPlayerTo(SAFE_POINT)
                    Library:Notify({ Title = "LOW HEALTH", Content = "Teleported to Safe Point!", Type = "warning" })
                    task.wait(5)
                end
                -- Escape karena Mob dekat
                if Characters then
                    for _, mob in ipairs(Characters:GetChildren()) do
                        local mPart = findValidPart(mob)
                        if mPart and (mPart.Position - hrp.Position).Magnitude < Settings.EscapeDist then
                            teleportPlayerTo(SAFE_POINT)
                            Library:Notify({ Title = "MOB DETECTED", Content = "Teleported to Safe Point!", Type = "warning" })
                            task.wait(5)
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Eat Loop
task.spawn(function()
    while task.wait(1) do
        if Toggles.AutoEat then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < (hum.MaxHealth * (Settings.EatThreshold/100)) then
                for _, item in ipairs(ItemsFolder:GetChildren()) do
                    if table.find({"Berry", "Cooked Steak", "Cooked Morsel", "Apple"}, item.Name) then
                        reliableDrag(item, getRoot().Position)
                        task.wait(0.2)
                        if RemoteConsume then RemoteConsume:InvokeServer(item) end
                        break
                    end
                end
            end
        end
    end
end)

-- Kill Aura Loop
task.spawn(function()
    while task.wait(0.1) do
        if Toggles.KillAura then
            local hrp = getRoot()
            if hrp and Characters then
                for _, mob in ipairs(Characters:GetChildren()) do
                    local mPart = findValidPart(mob)
                    if mPart and (mPart.Position - hrp.Position).Magnitude < Settings.AuraRadius then
                        pcall(function() 
                            RemoteEvents.ToolDamageObject:InvokeServer(mob, nil, "123", mPart.CFrame) 
                        end)
                    end
                end
            end
        end
    end
end)

-- Misc Controls
UserInputService.JumpRequest:Connect(function()
    if Toggles.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Window:Notify({ Title = "W424 HUB PRO", Content = "99 Night v5.40 Loaded!", Type = "success" })
