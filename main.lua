-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- MASTER EDITION: RAYFIELD UI + SPY AURA + INDEX SELECTOR
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
    ChopRadius = 150,
    KillAura = false,
    KillRadius = 150,
    SelectedItem = "All", -- Default tarik semua atau item spesifik
    AutoBringSelected = false,
    AutoBringChest = false
}

-- Kamus Terjemahan/Indeks Item (English -> Display Name)
local itemList = {
    ["Log"] = "Khúc Gỗ",
    ["Item Chest"] = "Rương Vật Phẩm",
    ["MedKit"] = "Hộp Cứu Thương",
    ["Revolver"] = "Súng Lục",
    ["Chainsaw"] = "Cưa Máy",
    ["Spear"] = "Tombak/Spear"
}

-- ==========================================
-- 1. CHOP AURA LOOP (Menggunakan Temuan Remote Spy: DestroyObject)
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local map = Workspace:FindFirstChild("Map")
                local foliage = map and map:FindFirstChild("Foliage")
                
                if foliage then
                    for _, tree in ipairs(foliage:GetChildren()) do
                        if not getgenv().W424.ChopAura then break end
                        
                        local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.ChopRadius then
                            
                            local destroyEvent = RemotesFolder and RemotesFolder:FindFirstChild("DestroyObject")
                            if destroyEvent and firesignal then
                                firesignal(destroyEvent.OnClientEvent, tree, part.CFrame)
                            end
                            
                            task.wait(0.05)
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
    while task.wait(0.2) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local charactersFolder = Workspace:FindFirstChild("Characters")
                if charactersFolder then
                    for _, mob in ipairs(charactersFolder:GetChildren()) do
                        if not getgenv().W424.KillAura then break end
                        if mob:IsA("Model") and mob ~= LocalPlayer.Character then
                            local part = mob:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= getgenv().W424.KillRadius then
                                local destroyEvent = RemotesFolder and RemotesFolder:FindFirstChild("DestroyObject")
                                if destroyEvent and firesignal then
                                    firesignal(destroyEvent.OnClientEvent, mob, part.CFrame)
                                end
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
-- 3. INDEX & REAL-TIME BRING ITEM LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.4) do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not itemFolder then continue end

        local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")

        -- Bring Item Berdasarkan Indeks Pilihan User (Mencegah Lag/Crash)
        if getgenv().W424.AutoBringSelected then
            pcall(function()
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
            end)
        end

        -- Auto Bring & Open Chests
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
-- RAYFIELD UI INTERFACE SETUP
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | Master Edition",
   LoadingTitle = "Memuat Fitur...",
   LoadingSubtitle = "by W424",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Aura & Combat", 4483362458)
local TabLoot = Window:CreateTab("Index & Looting", 4483362458)

-- TAB 1: AURA
TabMain:CreateSection("Aura Automation (Spy Method)")

TabMain:CreateToggle({
   Name = "Chop Aura (Pohon Otomatis)",
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
   Name = "Kill Aura (Mob Otomatis)",
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
TabLoot:CreateSection("Index Item Selector (Anti-Lag)")

local optionsList = {"All"}
for engName, _ in pairs(itemList) do
    table.insert(optionsList, engName)
end

TabLoot:CreateDropdown({
   Name = "Pilih Item yang Ingin Ditarik",
   Options = optionsList,
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

Rayfield:Notify({
   Title = "W424 Master Hub Ready!",
   Content = "Fitur Chop Aura Spy & Index Selector aktif.",
   Duration = 5,
   Image = 4483362458
})
