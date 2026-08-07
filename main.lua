-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- RAYFIELD UI + CHOP & KILL AURA EDITION
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
    KillAura = false,
    KillRadius = 100,
    AutoClaim = false
}

-- Mapping ID Kapak & Senjata sesuai dengan struktur asli game[span_1](start_span)[span_1](end_span)
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- Fungsi untuk mendeteksi tool/senjata di inventory atau karakter[span_2](start_span)[span_2](end_span)
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
-- 1. CHOP AURA LOOP (Modifikasi dari Kill Aura)
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyToolWithDamageID()
                if tool and damageID then
                    equipTool(tool)

                    local map = Workspace:FindFirstChild("Map")
                    local foliage = map and map:FindFirstChild("Foliage")
                    
                    if foliage then
                        for _, tree in ipairs(foliage:GetChildren()) do
                            if not getgenv().W424.ChopAura then break end
                            
                            local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.ChopRadius then
                                local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
                                if damageRemote then
                                    damageRemote:InvokeServer(
                                        tree,
                                        tool,
                                        damageID,
                                        CFrame.new(part.Position)
                                    )
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
-- 2. KILL AURA LOOP (Sesuai source asli)[span_3](start_span)[span_3](end_span)
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().W424.KillAura then
            pcall(function()
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyToolWithDamageID()
                if tool and damageID then
                    equipTool(tool)

                    local charactersFolder = Workspace:FindFirstChild("Characters")
                    if charactersFolder then
                        for _, mob in ipairs(charactersFolder:GetChildren()) do
                            if not getgenv().W424.KillAura then break end
                            if mob:IsA("Model") and mob ~= character then
                                local part = mob:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.KillRadius then
                                    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
                                    if damageRemote then
                                        damageRemote:InvokeServer(
                                            mob,
                                            tool,
                                            damageID,
                                            CFrame.new(part.Position)
                                        )
                                    end
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
-- 3. AUTO CLAIM DROPS LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim and itemFolder then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
                    local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
                    
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") then
                            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                            if part and startDrag and stopDrag then
                                startDrag:FireServer(item)
                                part.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0)
                                part.Velocity = Vector3.zero
                                stopDrag:FireServer(item)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- RAYFIELD UI INTERFACE SETUP
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | 99 Nights",
   LoadingTitle = "Memuat Sistem...",
   LoadingSubtitle = "by W424",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Aura & Farming", 4483362458)

TabMain:CreateSection("Farming & Combat Aura")

TabMain:CreateToggle({
   Name = "Chop Aura (Pohon)",
   CurrentValue = getgenv().W424.ChopAura,
   Flag = "ChopAuraTog",
   Callback = function(Value)
      getgenv().W424.ChopAura = Value
   end,
})

TabMain:CreateSlider({
   Name = "Chop Aura Radius",
   Range = {20, 500},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.ChopRadius,
   Flag = "ChopRad",
   Callback = function(Value)
      getgenv().W424.ChopRadius = Value
   end,
})

TabMain:CreateToggle({
   Name = "Kill Aura (Mob / Characters)",
   CurrentValue = getgenv().W424.KillAura,
   Flag = "KillAuraTog",
   Callback = function(Value)
      getgenv().W424.KillAura = Value
   end,
})

TabMain:CreateSlider({
   Name = "Kill Aura Radius",
   Range = {20, 500},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = getgenv().W424.KillRadius,
   Flag = "KillRad",
   Callback = function(Value)
      getgenv().W424.KillRadius = Value
   end,
})

TabMain:CreateSection("Automation")

TabMain:CreateToggle({
   Name = "Auto Claim Drops (Log/Items)",
   CurrentValue = getgenv().W424.AutoClaim,
   Flag = "ClaimTog",
   Callback = function(Value)
      getgenv().W424.AutoClaim = Value
   end,
})

Rayfield:Notify({
   Title = "W424 Hub Berhasil Dimuat!",
   Content = "Chop Aura & Kill Aura siap digunakan.",
   Duration = 5,
   Image = 4483362458
})
