-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- MASTER EDITION (FIXED NIL ERROR & SPY SYNC)
-- ==========================================

-- 1. Inisialisasi Global State di awal agar tidak error "attempt to index nil"
getgenv().W424 = {
    ChopAura = false,
    ChopRadius = 150,
    KillAura = false,
    KillRadius = 150,
    SelectedItem = "All",
    AutoBringSelected = false,
    AutoBringChest = false
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- Kamus Damage ID Sesuai Tangkapan Spy Terbaru
local toolsDamageIDs = {
    ["Old Axe"] = "2_9883131443",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875"
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
-- 1. CHOP AURA LOOP (Menggabungkan ToolDamage & DestroyObject)
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do
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
                            
                            -- Langkah A: Kirim Damage Server (Biar Log / Kayu Muncul)
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
                            
                            -- Langkah B: Kirim Destroy Signal (Biar Pohon Langsung Hancur Bersih)
                            local destroyEvent = RemotesFolder and RemotesFolder:FindFirstChild("DestroyObject")
                            if destroyEvent and firesignal then
                                firesignal(destroyEvent.OnClientEvent, tree, part.CFrame)
                            end
                            
                            task.wait(0.05)
                        end
                    end
                end
            end
        end)
    end
end)

-- ==========================================
-- 2. INDEX & REAL-TIME BRING ITEM LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp or not itemFolder then return end

            local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
            local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")

            if getgenv().W424 and getgenv().W424.AutoBringSelected then
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
        end)
    end
end)

-- ==========================================
-- RAYFIELD UI INTERFACE SETUP
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "W424 Hub | Master Edition",
   LoadingTitle = "Memuat Sistem...",
   LoadingSubtitle = "by W424",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabMain = Window:CreateTab("Aura & Combat", 4483362458)
local TabLoot = Window:CreateTab("Index & Looting", 4483362458)

TabMain:CreateSection("Wood Farming")

TabMain:CreateToggle({
   Name = "Chop Aura (Spy Method)",
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

TabLoot:CreateSection("Item Selector")

TabLoot:CreateDropdown({
   Name = "Pilih Item yang Ingin Ditarik",
   Options = {"All", "Log", "Item Chest", "MedKit", "Revolver"},
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

Rayfield:Notify({
   Title = "W424 Master Hub Ready!",
   Content = "Error Nil Teratasi & Spy Sinkron.",
   Duration = 5,
   Image = 4483362458
})
