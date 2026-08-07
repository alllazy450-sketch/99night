-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FULL MASTER EDITION (THEME: DARK BLUE + CLEAN LOOP CHOP)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL CONFIGURATIONS
-- ==========================================
getgenv().W424 = {
    ChopAura = false,
    ChopRadius = 150,
    
    KillAura = false,
    KillRadius = 150,
    
    SelectedItem = "All",
    AutoBringSelected = false,
    AutoBringChest = false,
    
    AutoFeedCampfire = false,
    CampfireItem = "Log"
}

-- Kamus Damage ID Sesuai Game Asli
local toolsDamageIDs = {
    ["Old Axe"] = "2_9883131443",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getAnyTool()
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
            if tool then return tool, damageID end
        end
    end
    return nil, nil
end

-- ==========================================
-- 1. FIXED CHOP AURA LOOP (Clean & Presisi)
-- ==========================================
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if getgenv().W424 and getgenv().W424.ChopAura then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyTool()
                
                for _, tree in ipairs(Workspace:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
                    
                    if tree:IsA("Model") and (tree.Name:find("Tree") or tree.Name:find("Log")) then
                        local part = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                        
                        if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.ChopRadius then
                            local damageRemote = RemotesFolder and RemotesFolder:FindFirstChild("ToolDamageObject")
                            if damageRemote and tool and damageID then
                                damageRemote:InvokeServer(
                                    tree,
                                    tool,
                                    damageID,
                                    CFrame.new(part.Position, hrp.Position),
                                    false
                                )
                            end
                            task.wait(0.1)
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 2. KILL AURA LOOP (Mob / Characters)
-- ==========================================
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if getgenv().W424 and getgenv().W424.KillAura then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local tool, damageID = getAnyTool()
                local charactersFolder = Workspace:FindFirstChild("Characters")
                
                if charactersFolder then
                    for _, mob in ipairs(charactersFolder:GetChildren()) do
                        if not getgenv().W424.KillAura then break end
                        if mob:IsA("Model") and mob ~= LocalPlayer.Character then
                            local part = mob:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.KillRadius then
                                local damageRemote = RemotesFolder and RemotesFolder:FindFirstChild("ToolDamageObject")
                                if damageRemote and tool and damageID then
                                    damageRemote:InvokeServer(
                                        mob,
                                        tool,
                                        damageID,
                                        CFrame.new(part.Position, hrp.Position),
                                        false
                                    )
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 3. INDEX LOOTING, CHEST & AUTO FEED CAMPFIRE
-- ==========================================
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not itemFolder then return end

            local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
            local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")

            -- Auto Bring Selected Item (Lengkap dengan Index)
            if getgenv().W424.AutoBringSelected then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") then
                        local targetMatch = (getgenv().W424.SelectedItem == "All") or (item.Name:lower():find(getgenv().W424.SelectedItem:lower()))
                        
                        if targetMatch then
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
            end

            -- Auto Bring & Open Chests
            if getgenv().W424.AutoBringChest then
                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                        if main and startDrag and stopDrag then
                            startDrag:FireServer(chest)
                            main.CFrame = hrp.CFrame + Vector3.new(0, 2, 2)
                            main.Velocity = Vector3.zero
                            stopDrag:FireServer(chest)

                            for _, obj in ipairs(chest:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    fireproximityprompt(obj)
                                end
                            end
                        end
                    end
                end
            end

            -- Auto Feed Campfire dengan Pemilihan Index Item
            if getgenv().W424.AutoFeedCampfire then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item.Name:lower():find(getgenv().W424.CampfireItem:lower()) then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        local campfire = Workspace:FindFirstChild("Campfire") or Workspace:FindFirstChild("Fireplace")
                        if part and campfire and startDrag and stopDrag then
                            local firePart = campfire.PrimaryPart or campfire:FindFirstChildWhichIsA("BasePart")
                            if firePart then
                                startDrag:FireServer(item)
                                part.CFrame = firePart.CFrame + Vector3.new(0, 1, 0)
                                part.Velocity = Vector3.zero
                                stopDrag:FireServer(item)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- RAYFIELD UI INTERFACE SETUP (THEME: DARKBLUE)
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | Full Master Edition",
   LoadingTitle = "Memuat Fitur Lengkap...",
   LoadingSubtitle = "by W424",
   Theme = "DarkBlue",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Aura & Combat", 4483362458)
local TabLoot = Window:CreateTab("Index & Looting", 4483362458)
local TabCamp = Window:CreateTab("Campfire & Utility", 4483362458)

-- TAB 1: AURA
TabMain:CreateSection("Wood Farming & Combat")

TabMain:CreateToggle({
   Name = "Chop Aura (Fixed Drop)",
   CurrentValue = getgenv().W424.ChopAura,
   Flag = "ChopTog",
   Callback = function(Value) getgenv().W424.ChopAura = Value end,
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

TabMain:CreateToggle({
   Name = "Kill Aura (Mobs / Characters)",
   CurrentValue = getgenv().W424.KillAura,
   Flag = "KillTog",
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

-- TAB 2: INDEX & LOOTING
TabLoot:CreateSection("Item Selector Index")

TabLoot:CreateDropdown({
   Name = "Pilih Item yang Ingin Ditarik",
   Options = {"All", "Log", "Item Chest", "MedKit", "Revolver", "Chainsaw", "Spear", "Meat"},
   CurrentOption = "All",
   Flag = "ItemDropdown",
   Callback = function(Option)
      getgenv().W424.SelectedItem = Option
   end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring Selected Item",
   CurrentValue = getgenv().W424.AutoBringSelected,
   Flag = "BringSelTog",
   Callback = function(Value) getgenv().W424.AutoBringSelected = Value end,
})

TabLoot:CreateToggle({
   Name = "Auto Bring & Open Chests",
   CurrentValue = getgenv().W424.AutoBringChest,
   Flag = "ChestTog",
   Callback = function(Value) getgenv().W424.AutoBringChest = Value end,
})

-- TAB 3: CAMPFIRE & UTILITY
TabCamp:CreateSection("Campfire Automation")

TabCamp:CreateDropdown({
   Name = "Pilih Item untuk Campfire",
   Options = {"Log", "Wood", "Meat", "Coal"},
   CurrentOption = "Log",
   Flag = "CampDropdown",
   Callback = function(Option)
      getgenv().W424.CampfireItem = Option
   end,
})

TabCamp:CreateToggle({
   Name = "Auto Feed Campfire (Index)",
   CurrentValue = getgenv().W424.AutoFeedCampfire,
   Flag = "CampTog",
   Callback = function(Value) getgenv().W424.AutoFeedCampfire = Value end,
})

Rayfield:Notify({
   Title = "W424 DarkBlue Edition Ready!",
   Content = "Tema DarkBlue aktif dengan struktur loop chop yang bersih.",
   Duration = 5,
   Image = 4483362458
})
