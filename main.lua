-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- RAYFIELD ULTIMATE EDITION (BUG-FREE MOBILE)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    AutoWood = false, WoodRadius = 50, BlinkHit = true,
    AutoHunt = false, HuntRadius = 50, TargetMob = "Bunny",
    AutoBringChest = false, AutoClaimDrops = false,
    AutoFeed = false, FeedMaterial = "Log"
}

-- Mapping ID Kapak/Senjata agar valid di server
local function getDamageID(toolName)
    if toolName:find("Good") then return "112_" .. tostring(LocalPlayer.UserId) end
    if toolName:find("Strong") then return "116_" .. tostring(LocalPlayer.UserId) end
    if toolName:find("Sword") then return "12_" .. tostring(LocalPlayer.UserId) end
    return "1_" .. tostring(LocalPlayer.UserId)
end

-- ==========================================
-- UTILITY & PHYSICS ENGINE
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

local function executeHit(target, tool, targetPart)
    local hrp = getHRP()
    if not hrp or not targetPart then return end

    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if not damageRemote then return end

    local damageID = getDamageID(tool.Name)
    local originalCFrame = hrp.CFrame
    local distance = (hrp.Position - targetPart.Position).Magnitude
    
    -- Ghost Hit/Blink Physics Bypass
    if distance > 20 and getgenv().W424.BlinkHit then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3) 
        task.wait(0.05) 
        
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position))
        end)
        
        task.wait(0.05)
        hrp.CFrame = originalCFrame 
    else
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position))
        end)
    end
end

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

-- ==========================================
-- ENGINE LOOPS
-- ==========================================
-- 1. Chop Aura
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
                        local mainPart = v:FindFirstChild("Trunk") or v:FindFirstChild("Trunk1") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                        if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.WoodRadius then
                            executeHit(v, tool, mainPart)
                            task.wait(0.1) 
                        end
                    end
                end
            end)
        end
    end
end)

-- 2. Kill Aura Mob
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
                        if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.HuntRadius then
                            executeHit(v, tool, mainPart)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Chest & Claim Drops
task.spawn(function()
    while task.wait(0.5) do
        local hrp = getHRP()
        if not hrp or not itemFolder then continue end

        if getgenv().W424.AutoBringChest then
            pcall(function()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoBringChest then break end
                    if item.Name:find("Chest") then
                        local main = item:FindFirstChild("Main") or item.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    dragItemToPlayer(item, hrp.Position + Vector3.new(0, 2, 2))
                                    task.wait(0.1)
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

        if getgenv().W424.AutoClaimDrops then
            pcall(function()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if not item.Name:find("Chest") and item:IsA("Model") then
                        dragItemToPlayer(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Feed
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
                        task.wait(0.3) 
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- RAYFIELD UI INTERFACE (NO BUBBLE NEEDED)
-- ==========================================
-- Rayfield otomatis menyediakan tombol/ikon melayang di tengah atas layar untuk buka/tutup!
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 99 Nights",
   LoadingTitle = "Memuat Fitur...",
   LoadingSubtitle = "Ultimate Edition",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabFarm = Window:CreateTab("Aura Farming", 4483362458)
local TabLoot = Window:CreateTab("Loot & Automation", 4483362458)

-- Tab 1: Farming
TabFarm:CreateSection("Wood Farming")

TabFarm:CreateToggle({
   Name = "Auto Farm Wood (Aura)",
   CurrentValue = getgenv().W424.AutoWood,
   Flag = "AutoWoodTog", 
   Callback = function(Value) getgenv().W424.AutoWood = Value end,
})

TabFarm:CreateToggle({
   Name = "Enable Blink Hit (Bypass Server-Side)",
   CurrentValue = getgenv().W424.BlinkHit,
   Flag = "BlinkTog",
   Callback = function(Value) getgenv().W424.BlinkHit = Value end,
})

-- Format Slider Rayfield sangat aman untuk Mobile
TabFarm:CreateSlider({
   Name = "Wood Aura Radius",
   Range = {10, 5000},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.WoodRadius,
   Flag = "WoodRad",
   Callback = function(Value) getgenv().W424.WoodRadius = Value end,
})

TabFarm:CreateSection("Mob Hunting")

TabFarm:CreateToggle({
   Name = "Auto Kill Mob (Aura)",
   CurrentValue = getgenv().W424.AutoHunt,
   Flag = "AutoHuntTog",
   Callback = function(Value) getgenv().W424.AutoHunt = Value end,
})

TabFarm:CreateDropdown({
   Name = "Select Target Mob",
   Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Deer", "Cultist", "Boss"},
   CurrentOption = {getgenv().W424.TargetMob},
   MultipleOptions = false,
   Flag = "MobDrop",
   Callback = function(Option) getgenv().W424.TargetMob = Option[1] end,
})

TabFarm:CreateSlider({
   Name = "Kill Aura Radius",
   Range = {10, 5000},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.HuntRadius,
   Flag = "HuntRad",
   Callback = function(Value) getgenv().W424.HuntRadius = Value end,
})

-- Tab 2: Loot & Feed
TabLoot:CreateSection("Chest & Drops Manager")

TabLoot:CreateToggle({
   Name = "Auto Bring & Open Chests",
   CurrentValue = getgenv().W424.AutoBringChest,
   Flag = "ChestTog",
   Callback = function(Value) getgenv().W424.AutoBringChest = Value end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring All Drops (Wood/Items)",
   CurrentValue = getgenv().W424.AutoClaimDrops,
   Flag = "ClaimTog",
   Callback = function(Value) getgenv().W424.AutoClaimDrops = Value end,
})

TabLoot:CreateSection("Campfire Manager")

TabLoot:CreateToggle({
   Name = "Auto Feed Campfire",
   CurrentValue = getgenv().W424.AutoFeed,
   Flag = "FeedTog",
   Callback = function(Value) getgenv().W424.AutoFeed = Value end,
})

TabLoot:CreateDropdown({
   Name = "Feed Material Index",
   Options = {"Log", "Stick", "Coal", "Fiber", "Meat", "Fish"},
   CurrentOption = {getgenv().W424.FeedMaterial},
   MultipleOptions = false,
   Flag = "MatDrop",
   Callback = function(Option) getgenv().W424.FeedMaterial = Option[1] end,
})

Rayfield:Notify({
   Title = "W424 Hub Loaded!",
   Content = "Semua error telah diatasi. Selamat bermain!",
   Duration = 5,
   Image = 4483362458
})
