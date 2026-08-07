-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FIXED CHOP AURA & KILL AURA EDITION
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
    ChopAura = false,
    ChopRadius = 100,
    KillAura = false,
    KillRadius = 100,
    AutoClaim = false,
}

-- Mapping Damage ID sesuai metode Kill Aura original
local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- Mencari tool yang aktif di inventory/karakter
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
-- 1. CHOP AURA LOOP (Dimodifikasi dari logika Kill Aura)
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

                    -- Menelusuri folder Foliage tempat pohon berada di Map
                    local map = Workspace:FindFirstChild("Map")
                    local foliage = map and map:FindFirstChild("Foliage")
                    
                    if foliage then
                        for _, tree in ipairs(foliage:GetChildren()) do
                            if not getgenv().W424.ChopAura then break end
                            
                            -- Mengambil bagian batang (Trunk) atau part utama pohon
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
-- 2. KILL AURA LOOP (Sesuai source asli)[span_2](start_span)[span_2](end_span)
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
-- CUSTOM MOBILE UI (ANTI-CRASH PURE LUA)
-- ==========================================
pcall(function()
    if CoreGui:FindFirstChild("W424_FixedUI") then CoreGui.W424_FixedUI:Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("W424_FixedUI") then LocalPlayer.PlayerGui.W424_FixedUI:Destroy() end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "W424_FixedUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 2147483647

local success = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = LocalPlayer.PlayerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 360)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.Active = true
main.Draggable = true
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(110, 0, 210)
stroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "W424 Hub | Fixed Aura"
title.TextColor3 = Color3.fromRGB(150, 50, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255,255,255)
close.Font = Enum.Font.GothamBold
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -55)
scroll.Position = UDim2.new(0, 10, 0, 45)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.Parent = main

local list = Instance.new("UIListLayout")
list.Parent = scroll
list.Padding = UDim.new(0, 10)

local function createToggle(text, stateKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(40, 40, 40)
    btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        getgenv().W424[stateKey] = not getgenv().W424[stateKey]
        btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(40, 40, 40)
        btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    end)
end

createToggle("Chop Aura (Pohon)", "ChopAura")
createToggle("Kill Aura (Mob)", "KillAura")
createToggle("Auto Claim Drops", "AutoClaim")

-- Tombol Melayang (Bubble Open/Close UI)
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0, 20, 0.3, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 220)
floatBtn.Text = "UI"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 16
floatBtn.Parent = screenGui
floatBtn.Draggable = true
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)

close.MouseButton1Click:Connect(function() main.Visible = false end)
floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
