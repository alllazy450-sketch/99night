-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE MASTER EDITION (REBUILT & IMPROVED AURA)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL STATE & CONFIGURATIONS
-- ==========================================
getgenv().W424 = {
    ChopAura = false,
    ChopRadius = 100,
    BlinkHit = true, -- Fitur baru: Bypass server-side agar kayu pasti drop
    
    KillAura = false,
    KillRadius = 100,
    
    AutoClaim = false,
    AutoBringChest = false
}

-- Mapping ID Kapak & Senjata
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getAnyToolWithDamageID()
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") and toolsDamageIDs[child.Name] then
                return child, toolsDamageIDs[child.Name]
            end
        end
    end
    
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then
        for toolName, damageID in pairs(toolsDamageIDs) do
            local tool = inv:FindFirstChild(toolName)
            if tool then
                return tool, damageID
            end
        end
    end
    return nil, nil
end

local function equipTool(tool)
    if tool and RemotesFolder and RemotesFolder:FindFirstChild("EquipItemHandle") then
        pcall(function()
            RemotesFolder.EquipItemHandle:FireServer("FireAllClients", tool)
        end)
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and tool and tool.Parent ~= char then
        pcall(function() char.Humanoid:EquipTool(tool) end)
    end
end

-- ==========================================
-- IMPROVED PHYSICS & HIT EXECUTION (BYPASS DROP)
-- ==========================================
local function executeHit(target, tool, damageID, targetPart)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPart then return end

    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if not damageRemote then return end

    local originalCFrame = hrp.CFrame
    local distance = (hrp.Position - targetPart.Position).Magnitude

    -- Jika jarak jauh dan BlinkHit aktif, teleport kilat sesaat agar server mengesahkan item drop
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

-- ==========================================
-- 1. IMPROVED CHOP AURA LOOP (Lebih Luas & Presisi)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyToolWithDamageID()
                if tool and damageID then
                    equipTool(tool)

                    local map = Workspace:FindFirstChild("Map")
                    local foliage = map and map:FindFirstChild("Foliage")
                    
                    if foliage then
                        for _, tree in ipairs(foliage:GetChildren()) do
                            if not getgenv().W424.ChopAura then break end
                            
                            -- Deteksi multi-part agar semua jenis pohon terbaca luas
                            local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.ChopRadius then
                                executeHit(tree, tool, damageID, part)
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 2. KILL AURA LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyToolWithDamageID()
                if tool and damageID then
                    equipTool(tool)

                    local charactersFolder = Workspace:FindFirstChild("Characters")
                    if charactersFolder then
                        for _, mob in ipairs(charactersFolder:GetChildren()) do
                            if not getgenv().W424.KillAura then break end
                            if mob:IsA("Model") and mob ~= LocalPlayer.Character then
                                local part = mob:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.KillRadius then
                                    executeHit(mob, tool, damageID, part)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 3. AUTO CLAIM DROPS & CHEST MANAGER
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not itemFolder then continue end

        local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")

        -- Auto Claim Drops (Kayu, Item, dll)
        if getgenv().W424.AutoClaim then
            pcall(function()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and not item.Name:find("Chest") then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part and startDrag and stopDrag then
                            startDrag:FireServer(item)
                            part.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0)
                            part.Velocity = Vector3.zero
                            stopDrag:FireServer(item)
                        end
                    end
                end
            end)
        end

        -- Auto Bring & Open Chest
        if getgenv().W424.AutoBringChest then
            pcall(function()
                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                        if main and startDrag and stopDrag then
                            startDrag:FireServer(chest)
                            main.CFrame = hrp.CFrame + Vector3.new(0, 2, 2)
                            main.Velocity = Vector3.zero
                            stopDrag:FireServer(chest)

                            -- Buka proximity prompt peti secara otomatis
                            for _, obj in ipairs(chest:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    fireproximityprompt(obj)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- RAYFIELD UI INTERFACE (STABLE & MOBILE SAFE)
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 99 Nights",
   LoadingTitle = "Memuat Master Sistem...",
   LoadingSubtitle = "Ultimate Edition",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Aura & Farming", 4483362458)
local TabLoot = Window:CreateTab("Loot & Automation", 4483362458)

-- TAB 1: AURA & FARMING
TabMain:CreateSection("Wood Farming (Improved)")

TabMain:CreateToggle({
   Name = "Auto Farm Wood (Chop Aura)",
   CurrentValue = getgenv().W424.ChopAura,
   Flag = "ChopAuraTog",
   Callback = function(Value) getgenv().W424.ChopAura = Value end,
})

TabMain:CreateToggle({
   Name = "Enable Blink Hit (Fix Kayu Tidak Drop)",
   CurrentValue = getgenv().W424.BlinkHit,
   Flag = "BlinkHitTog",
   Callback = function(Value) getgenv().W424.BlinkHit = Value end,
})

TabMain:CreateSlider({
   Name = "Chop Aura Radius",
   Range = {20, 5000},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.ChopRadius,
   Flag = "ChopRad",
   Callback = function(Value) getgenv().W424.ChopRadius = Value end,
})

TabMain:CreateSection("Combat Automation")

TabMain:CreateToggle({
   Name = "Kill Aura (Mob / Characters)",
   CurrentValue = getgenv().W424.KillAura,
   Flag = "KillAuraTog",
   Callback = function(Value) getgenv().W424.KillAura = Value end,
})

TabMain:CreateSlider({
   Name = "Kill Aura Radius",
   Range = {20, 5000},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.KillRadius,
   Flag = "KillRad",
   Callback = function(Value) getgenv().W424.KillRadius = Value end,
})

-- TAB 2: LOOT & AUTOMATION
TabLoot:CreateSection("Item & Chest Manager")

TabLoot:CreateToggle({
   Name = "Auto Claim Drops (Log/Items)",
   CurrentValue = getgenv().W424.AutoClaim,
   Flag = "ClaimTog",
   Callback = function(Value) getgenv().W424.AutoClaim = Value end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring & Open Chests",
   CurrentValue = getgenv().W424.AutoBringChest,
   Flag = "ChestTog",
   Callback = function(Value) getgenv().W424.AutoBringChest = Value end,
})

Rayfield:Notify({
   Title = "W424 Hub Master Loaded!",
   Content = "Chop Aura (Blink Physics) & Kill Aura aktif!",
   Duration = 5,
   Image = 4483362458
})
