-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- CUSTOM PURE LUA V2 (ANTI-CACHE & FULL BYPASS)
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
    AutoWood = false, WoodRadius = 500, BlinkHit = true,
    AutoHunt = false, HuntRadius = 500, TargetMob = "Bunny",
    AutoBringChest = false, AutoClaimDrops = false,
    AutoFeed = false, FeedMaterial = "Log"
}

-- Mapping ID Kapak/Senjata
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
    
    if distance > 20 and getgenv().W424.BlinkHit then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3) 
        task.wait(0.05) 
        pcall(function() damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position)) end)
        task.wait(0.05)
        hrp.CFrame = originalCFrame 
    else
        pcall(function() damageRemote:InvokeServer(target, tool, damageID, CFrame.new(targetPart.Position, hrp.Position)) end)
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
-- CUSTOM PURE LUA UI (100% ANTI CRASH)
-- ==========================================
pcall(function() if CoreGui:FindFirstChild("W424_CustomUI") then CoreGui.W424_CustomUI:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424_CustomUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 2

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "W424 Hub | 99 Nights"
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

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -55)
Scroll.Position = UDim2.new(0, 10, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 4
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Parent = Scroll
UIList.Padding = UDim.new(0, 8)

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
        Btn.BackgroundColor3 = getgenv().W424[stateKey] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(40, 40, 40)
        Btn.Text = text .. (getgenv().W424[stateKey] and " [ON]" or " [OFF]")
    end)
end

createToggle("Auto Wood (Blink 500s)", "AutoWood")
createToggle("Auto Kill Mob (Blink 500s)", "AutoHunt")
createToggle("Auto Bring & Open Chest", "AutoBringChest")
createToggle("Auto Claim All Drops", "AutoClaimDrops")
createToggle("Auto Feed Campfire", "AutoFeed")

-- Tombol Melayang
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
