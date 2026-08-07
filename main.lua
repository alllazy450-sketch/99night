-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FIXED POSITION & ABSOLUTE VISIBILITY
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    SelectedTool = "Old Axe",
    ChopAura = false, ChopRadius = 25,
    AutoWood = false, WoodRadius = 30, TreeType = "All Trees",
    KillAura = false, KillRadius = 25,
    AutoHunt = false, HuntRadius = 30, TargetMob = "Wolf",
    AutoClaim = false,
    AutoFeed = false, FeedMaterial = "Log",
    AutoBringChest = false,
}

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016",
}
local function getDamageID(name)
    return toolsDamageIDs[name] or "1_" .. tostring(LocalPlayer.UserId)
end

local function getHRP()
    local char = LocalPlayer.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function equipTool(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child.Name == toolName then return child end
    end
    local containers = {
        LocalPlayer:FindFirstChild("Inventory"),
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("StarterGear")
    }
    local tool = nil
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    tool = item
                    break
                end
            end
        end
        if tool then break end
    end
    if not tool then return nil end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
    end
    pcall(function() tool.Parent = char end)
    task.wait(0.2)
    return char:FindFirstChild(toolName)
end

local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    local mainPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
        or target:FindFirstChild("Trunk") or target:FindFirstChild("MainPart")
        or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end
    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if damageRemote then
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position))
        end)
        return true
    end
    return false
end

local function dragItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
        local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
        if startDrag then startDrag:FireServer(item) end
        task.wait(0.05)
        local part = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if part and part:IsDescendantOf(Workspace) then
            part.CFrame = CFrame.new(position)
            part.Velocity = Vector3.new(0, 0, 0)
        end
        if stopDrag then stopDrag:FireServer(item) end
    end)
end

-- ==========================================
-- ENGINE LOOPS (CHOP, KILL, CLAIM, FEED)
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local foliage = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliage then return end
                for _, tree in ipairs(foliage:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
                    local part = tree:FindFirstChild("Trunk") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
                    if part and (hrp.Position - part.Position).Magnitude <= getgenv().W424.ChopRadius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.05)
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
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace
                for _, mob in ipairs(enemies:GetChildren()) do
                    if not getgenv().W424.KillAura then break end
                    if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob ~= LocalPlayer.Character then
                        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if part and (hrp.Position - part.Position).Magnitude <= getgenv().W424.KillRadius then
                            attackTarget(mob, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim and itemFolder then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") then dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0)) end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- UI PEMBUATAN UTAMA (FIXED SCREEN / CORE GUI)
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("W424_UI_Fixed") then CoreGui.W424_UI_Fixed:Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("W424_UI_Fixed") then LocalPlayer.PlayerGui.W424_UI_Fixed:Destroy() end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "W424_UI_Fixed"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2147483647

local success = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = LocalPlayer.PlayerGui end

-- Main Frame (Di tengah layar persis, ukuran proporsional HP)
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(0, 255, 150)
stroke.Thickness = 2

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "W424 Hub | Mobile Safe"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- Close Button
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255,255,255)
close.Font = Enum.Font.GothamBold
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

-- Scrolling Frame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -50)
scroll.Position = UDim2.new(0, 10, 0, 45)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.Parent = main

local list = Instance.new("UIListLayout")
list.Parent = scroll
list.Padding = UDim.new(0, 8)

-- Fungsi Buat Toggle Button
local function createToggle(text, stateKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(40, 40, 40)
    btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        getgenv().W424[stateKey] = not getgenv().W424[stateKey]
        btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(40, 40, 40)
        btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    end)
end

createToggle("Chop Aura", "ChopAura")
createToggle("Kill Aura (Mob)", "KillAura")
createToggle("Auto Claim Drops", "AutoClaim")

-- Tombol Bubble Melayang di Layar
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 55, 0, 55)
floatBtn.Position = UDim2.new(0, 20, 0.3, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
floatBtn.Text = "UI"
floatBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 18
floatBtn.Parent = screenGui
floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)

local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(0, 255, 150)
floatStroke.Thickness = 2.5

close.MouseButton1Click:Connect(function() main.Visible = false end)
floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

print("[W424] UI Fix Berhasil Dimuat Di Tengah Layar!")
