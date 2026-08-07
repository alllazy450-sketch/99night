-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- PURE LUA EDITION (100% ANTI CRASH/REQUIRE/404)
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    ChopAura = false, ChopRadius = 25, SelectedAxe = "Old Axe",
    KillAura = false, KillRadius = 25,
    AutoClaim = false, AutoFeed = false, AutoLootChest = false
}

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982", ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982", ["Sword"] = "12_8982038982"
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild(toolName)
    if tool then return tool end

    local inv = LocalPlayer:FindFirstChild("Inventory")
    if inv then tool = inv:FindFirstChild(toolName) end
    if not tool then return nil end

    local hum = char:FindFirstChild("Humanoid")
    if hum then pcall(function() hum:EquipTool(tool) end) end
    task.wait(0.2)
    return char:FindFirstChild(toolName) or tool
end

local function attackTarget(target, tool, damageID)
    local mainPart = target:FindFirstChild("Trunk") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
    local hrp = getHRP()
    if mainPart and hrp and RemotesFolder then
        local remote = RemotesFolder:FindFirstChild("ToolDamageObject")
        if remote then
            pcall(function() remote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position, hrp.Position)) end)
            return true
        end
    end
    return false
end

-- ==========================================
-- ENGINE LOOPS
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                local fol = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if hrp and tool and fol then
                    for _, v in ipairs(fol:GetChildren()) do
                        if not getgenv().W424.ChopAura then break end
                        local mainPart = v:FindFirstChild("Trunk") or v.PrimaryPart
                        if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.ChopRadius then
                            attackTarget(v, tool, toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982")
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = getHRP()
                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                local mobs = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs")
                if hrp and tool and mobs then
                    for _, v in ipairs(mobs:GetChildren()) do
                        if not getgenv().W424.KillAura then break end
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            local mainPart = v:FindFirstChild("HumanoidRootPart")
                            if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.KillRadius then
                                attackTarget(v, tool, toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982")
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
-- CUSTOM PURE LUA UI (ANTI-CRASH)
-- ==========================================
pcall(function() if CoreGui:FindFirstChild("W424_CustomUI") then CoreGui.W424_CustomUI:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424_CustomUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Panel Utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 360)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 2

-- Header
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "W424 Hub | Mobile Safe"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

-- Kontainer Tombol
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -55)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Parent = Scroll
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-- Fungsi Buat Tombol Toggle
local function createToggle(text, stateKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 40)
    Btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(40, 40, 40)
    Btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 14
    Btn.Parent = Scroll
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    Btn.MouseButton1Click:Connect(function()
        getgenv().W424[stateKey] = not getgenv().W424[stateKey]
        if getgenv().W424[stateKey] then
            Btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
            Btn.Text = text .. " [ON]"
        else
            Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Btn.Text = text .. " [OFF]"
        end
    end)
end

createToggle("Chop Aura (25 Studs)", "ChopAura")
createToggle("Kill Aura (25 Studs)", "KillAura")
createToggle("Auto Claim Drops", "AutoClaim")
createToggle("Auto Feed Campfire", "AutoFeed")
createToggle("Auto Loot Chest", "AutoLootChest")

-- Tombol Melayang (Anti Hilang)
local ToggleMenu = Instance.new("TextButton")
ToggleMenu.Size = UDim2.new(0, 50, 0, 50)
ToggleMenu.Position = UDim2.new(0, 10, 0.4, 0)
ToggleMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleMenu.Text = "UI"
ToggleMenu.TextColor3 = Color3.fromRGB(0, 255, 150)
ToggleMenu.Font = Enum.Font.GothamBold
ToggleMenu.TextSize = 16
ToggleMenu.Parent = ScreenGui
ToggleMenu.Draggable = true
Instance.new("UICorner", ToggleMenu).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", ToggleMenu)
FloatStroke.Color = Color3.fromRGB(0, 255, 150)
FloatStroke.Thickness = 2

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
ToggleMenu.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
