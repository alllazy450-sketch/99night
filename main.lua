-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- CLEAN CUSTOM UI & CHOP AURA ENGINE
-- ==========================================

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)

-- State Variables
getgenv().ChopAuraEnabled = false
getgenv().AutoLootEnabled = false
local ChopAuraRadius = 25
local SelectedAxeName = "Old Axe"

-- Hapus UI lama jika ada agar tidak menumpuk
for _, child in pairs(CoreGui:GetChildren()) do
    if child.Name == "W424HubUI" then child:Destroy() end
end

-- ==========================================
-- UI SETUP (GAYA TOASTIES HUB - 100% AMAN MOBILE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424HubUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 360)
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 2
UIStroke.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "W424 Hub | 99 Nights"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 8)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = MainFrame
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local ReopenBtn = Instance.new("TextButton")
ReopenBtn.Size = UDim2.new(0, 50, 0, 50)
ReopenBtn.Position = UDim2.new(0, 20, 0.4, 0)
ReopenBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
ReopenBtn.Text = "UI"
ReopenBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
ReopenBtn.Font = Enum.Font.GothamBold
ReopenBtn.TextSize = 16
ReopenBtn.Parent = ScreenGui
ReopenBtn.Visible = false
ReopenBtn.Active = true
ReopenBtn.Draggable = true
Instance.new("UICorner", ReopenBtn).CornerRadius = UDim.new(1, 0)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ReopenBtn.Visible = true
end)

ReopenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ReopenBtn.Visible = false
end)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -30, 0, 35)
StatusLabel.Position = UDim2.new(0, 15, 0, 50)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

-- Tombol Chop Aura
local ChopBtn = Instance.new("TextButton")
ChopBtn.Size = UDim2.new(1, -30, 0, 45)
ChopBtn.Position = UDim2.new(0, 15, 0, 100)
ChopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ChopBtn.Text = "Chop Aura: OFF"
ChopBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ChopBtn.Font = Enum.Font.GothamBold
ChopBtn.TextSize = 14
ChopBtn.Parent = MainFrame
Instance.new("UICorner", ChopBtn).CornerRadius = UDim.new(0, 8)

ChopBtn.MouseButton1Click:Connect(function()
    getgenv().ChopAuraEnabled = not getgenv().ChopAuraEnabled
    if getgenv().ChopAuraEnabled then
        ChopBtn.Text = "Chop Aura: ON"
        ChopBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        ChopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StatusLabel.Text = "Chop Aura Active!"
    else
        ChopBtn.Text = "Chop Aura: OFF"
        ChopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ChopBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        StatusLabel.Text = "Status: Ready"
    end
end)

-- Tombol Auto Loot (Mengambil fungsi dari script Chest Bring kamu)
local LootBtn = Instance.new("TextButton")
LootBtn.Size = UDim2.new(1, -30, 0, 45)
LootBtn.Position = UDim2.new(0, 15, 0, 155)
LootBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LootBtn.Text = "Auto Loot Chest: OFF"
LootBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
LootBtn.Font = Enum.Font.GothamBold
LootBtn.TextSize = 14
LootBtn.Parent = MainFrame
Instance.new("UICorner", LootBtn).CornerRadius = UDim.new(0, 8)

LootBtn.MouseButton1Click:Connect(function()
    getgenv().AutoLootEnabled = not getgenv().AutoLootEnabled
    if getgenv().AutoLootEnabled then
        LootBtn.Text = "Auto Loot Chest: ON"
        LootBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        LootBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        LootBtn.Text = "Auto Loot Chest: OFF"
        LootBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        LootBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Position = UDim2.new(0, 0, 1, -25)
Credits.BackgroundTransparency = 1
Credits.Text = "W424 Hub | Optimized"
Credits.TextColor3 = Color3.fromRGB(100, 100, 100)
Credits.Font = Enum.Font.GothamBold
Credits.TextSize, Credits.Parent = 12, MainFrame


-- ==========================================
-- CHOP AURA ENGINE (METODE REMOTE ASLIMU)
-- ==========================================
task.spawn(function()
    while task.wait(0.25) do
        if getgenv().ChopAuraEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local inventory = LocalPlayer:FindFirstChild("Inventory")
                local axeTool = inventory and inventory:FindFirstChild(SelectedAxeName)
                if not axeTool then
                    axeTool = char:FindFirstChild(SelectedAxeName)
                end
                if not axeTool then return end

                local valueAxe = "1_" .. LocalPlayer.UserId
                local foliageFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliageFolder then return end

                for _, v in ipairs(foliageFolder:GetChildren()) do
                    if not getgenv().ChopAuraEnabled then break end
                    -- Mendukung Small Tree atau variasi pohon di Map Foliage
                    if v:FindFirstChild("Trunk") then
                        local distance = (hrp.Position - v.Trunk.Position).Magnitude
                        if distance <= ChopAuraRadius then
                            local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
                            if damageRemote then
                                damageRemote:InvokeServer(
                                    v,
                                    axeTool,
                                    valueAxe,
                                    CFrame.new(v.Trunk.Position)
                                )
                            end
                        end
                    end
                end
            end)
        end
    end
end)


-- ==========================================
-- AUTO LOOT / BRING CHEST SYSTEM
-- ==========================================
local function startDrag(item)
    pcall(function()
        local reqDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        if reqDrag then reqDrag:FireServer(item) end
    end)
end

local function stopDrag(item)
    pcall(function()
        local stopDragRem = RemotesFolder:FindFirstChild("StopDraggingItem")
        if stopDragRem then stopDragRem:FireServer(item) end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoLootEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local itemsFolder = Workspace:FindFirstChild("Items")
                if not hrp or not itemsFolder then return end

                for _, item in ipairs(itemsFolder:GetChildren()) do
                    if not getgenv().AutoLootEnabled then break end
                    if string.find(item.Name, "Chest") and item:FindFirstChild("Main") then
                        local proxAtt = item.Main:FindFirstChild("ProximityAttachment")
                        if proxAtt then
                            for _, obj in ipairs(proxAtt:GetChildren()) do
                                if obj:IsA("ProximityPrompt") or obj.Name == "ProximityInteraction" then
                                    fireproximityprompt(obj)
                                    task.wait(0.2)
                                    
                                    for _, loot in ipairs(itemsFolder:GetChildren()) do
                                        if not loot.Name:find("Chest") then
                                            startDrag(loot)
                                            if loot:IsA("Model") and loot.PrimaryPart then
                                                loot:SetPrimaryPartCFrame(CFrame.new(hrp.Position + Vector3.new(0, 2, 0)))
                                            elseif loot:FindFirstChildWhichIsA("BasePart") then
                                                loot:FindFirstChildWhichIsA("BasePart").Position = hrp.Position + Vector3.new(0, 2, 0)
                                            end
                                            task.wait(0.05)
                                            stopDrag(loot)
                                        end
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
