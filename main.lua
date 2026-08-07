-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE FLUENT EDITION (MOBILE FIXED, NO 404)
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- ==========================================
-- GLOBAL STATE
-- ==========================================
getgenv().W424 = {
    ChopAura = false, ChopRadius = 25, SelectedAxe = "Old Axe",
    KillAura = false, KillRadius = 25,
    AutoWood = false, AutoWoodRadius = 30, TreeType = "All Trees",
    AutoHunt = false, AutoHuntRadius = 30, TargetMob = "Wolf",
    AutoClaim = false,
    AutoFeed = false, FeedMaterial = "Log",
    AutoLootChest = false,
}

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016",
    ["Sword"] = "12_8982038982"
}

local equippedTool = nil

-- ==========================================
-- UTILITY FUNCTIONS & ROBUST PHYSICS
-- ==========================================
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name == toolName or child.Name:find(toolName)) then
            return child
        end
    end

    local container = LocalPlayer:FindFirstChild("Inventory")
    local tool = nil
    if container then
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and (item.Name == toolName or item.Name:find(toolName)) then
                tool = item
                break
            end
        end
    end

    if not tool then return nil end

    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        pcall(function() humanoid:EquipTool(tool) end)
        task.wait(0.2)
        return char:FindFirstChild(toolName) or tool
    end
    return tool
end

local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    local mainPart = target:FindFirstChild("Trunk") or target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end

    local hrp = getHRP()
    if not hrp then return false end

    -- Physics Strike Calculation (Bypass Anti-Cheat)
    local hitCFrame = CFrame.new(mainPart.Position, hrp.Position)

    if RemotesFolder then
        local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
        if damageRemote then
            pcall(function() damageRemote:InvokeServer(target, tool, damageID, hitCFrame) end)
        end
    end
    return true
end

local function getTreeMainPart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
    return part
end

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        if RemotesFolder then
            local startDrag = RemotesFolder:FindFirstChild("RequestStartDraggingItem")
            if startDrag then startDrag:FireServer(item) end
        end
        task.wait(0.05)
        local targetPart = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if targetPart then
            targetPart.CFrame = CFrame.new(position)
            targetPart.Velocity = Vector3.new(0, 0, 0)
        end
        if RemotesFolder then
            local stopDrag = RemotesFolder:FindFirstChild("StopDraggingItem")
            if stopDrag then stopDrag:FireServer(item) end
        end
    end)
end

-- ==========================================
-- 1. CHOP AURA ENGINE
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                if not hrp or not tool then return end
                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                local foliageFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                
                if foliageFolder then
                    for _, v in ipairs(foliageFolder:GetChildren()) do
                        if not getgenv().W424.ChopAura then break end
                        local mainPart = getTreeMainPart(v)
                        if mainPart and (hrp.Position - mainPart.Position).Magnitude <= getgenv().W424.ChopRadius then
                            attackTarget(v, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 2. KILL AURA ENGINE
-- ==========================================
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = getHRP()
                local tool = ensureToolEquipped(getgenv().W424.SelectedAxe)
                if not hrp or not tool then return end
                local damageID = toolsDamageIDs[getgenv().W424.SelectedAxe] or "1_8982038982"
                local entitiesFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace

                for _, v in ipairs(entitiesFolder:GetChildren()) do
                    if not getgenv().W424.KillAura then break end
                    if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v ~= LocalPlayer.Character then
                        local targetPart = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                        if targetPart and (hrp.Position - targetPart.Position).Magnitude <= getgenv().W424.KillRadius then
                            attackTarget(v, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 3. AUTO CLAIM / BRING DROPS
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = getHRP()
                if hrp and itemFolder then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                            moveItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 4. AUTO FEED CAMPFIRE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if getgenv().W424.AutoFeed then
            pcall(function()
                local burnRemote = RemotesFolder:FindFirstChild("RequestBurnItem")
                local inventory = LocalPlayer:FindFirstChild("Inventory")
                if not burnRemote or not inventory then return end

                local feedMat = getgenv().W424.FeedMaterial
                for _, item in ipairs(inventory:GetChildren()) do
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
-- 5. AUTO LOOT CHEST
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoLootChest then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end

                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoLootChest then break end
                    if chest:IsA("Model") and string.find(chest.Name, "Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, child in ipairs(main:GetChildren()) do
                                if child:IsA("ProximityPrompt") then
                                    pcall(function() child.RequiresLineOfSight = false end)
                                    fireproximityprompt(child)
                                    task.wait(0.2)
                                    for _, loot in ipairs(itemFolder:GetChildren()) do
                                        if loot ~= chest and string.find(loot.Name, "Chest") == nil then
                                            moveItemToPos(loot, hrp.Position + Vector3.new(0, 2, 0))
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

-- ==========================================
-- FLUENT UI SETUP (MOBILE DIMENSIONS FIXED)
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "W424 Hub | 99 Nights",
    SubTitle = "Mobile Edition",
    TabWidth = 110, -- Lebar tab diperkecil agar tidak memotong layar
    Size = UDim2.new(0, 420, 0, 280), -- Ukuran proporsional HP
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Farm = Window:AddTab({ Title = "Farming", Icon = "leaf" }),
    Automation = Window:AddTab({ Title = "Autos", Icon = "box" })
}

-- TAB: COMBAT
Tabs.Combat:AddDropdown("WeaponSelect", {
    Title = "Select Weapon/Axe",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"},
    Default = getgenv().W424.SelectedAxe,
    Callback = function(v) getgenv().W424.SelectedAxe = v end
})

Tabs.Combat:AddToggle("ChopAura", { Title = "Chop Aura (Radius)", Default = getgenv().W424.ChopAura }):OnChanged(function(v) getgenv().W424.ChopAura = v end)
Tabs.Combat:AddSlider("ChopRadius", { Title = "Chop Radius", Min = 10, Max = 60, Default = getgenv().W424.ChopRadius, Callback = function(v) getgenv().W424.ChopRadius = v end })

Tabs.Combat:AddToggle("KillAura", { Title = "Kill Aura (Mob)", Default = getgenv().W424.KillAura }):OnChanged(function(v) getgenv().W424.KillAura = v end)
Tabs.Combat:AddSlider("KillRadius", { Title = "Kill Radius", Min = 10, Max = 60, Default = getgenv().W424.KillRadius, Callback = function(v) getgenv().W424.KillRadius = v end })

-- TAB: FARMING
Tabs.Farm:AddToggle("AutoWood", { Title = "Auto Wood (Radius)", Default = getgenv().W424.AutoWood }):OnChanged(function(v) getgenv().W424.AutoWood = v end)
Tabs.Farm:AddToggle("AutoHunt", { Title = "Auto Hunt (Radius)", Default = getgenv().W424.AutoHunt }):OnChanged(function(v) getgenv().W424.AutoHunt = v end)

-- TAB: AUTOMATION
Tabs.Automation:AddToggle("AutoClaim", { Title = "Auto Claim Drops", Default = getgenv().W424.AutoClaim }):OnChanged(function(v) getgenv().W424.AutoClaim = v end)
Tabs.Automation:AddToggle("AutoFeed", { Title = "Auto Feed Campfire", Default = getgenv().W424.AutoFeed }):OnChanged(function(v) getgenv().W424.AutoFeed = v end)
Tabs.Automation:AddToggle("AutoLootChest", { Title = "Auto Loot Chests", Default = getgenv().W424.AutoLootChest }):OnChanged(function(v) getgenv().W424.AutoLootChest = v end)

-- ==========================================
-- SUPER BUBBLE TOGGLE (100% MUNCUL)
-- ==========================================
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("W424_Toggle") then CoreGui.W424_Toggle:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "W424_Toggle"
    ScreenGui.Parent = CoreGui
    ScreenGui.DisplayOrder = 2147483647 -- Pastikan selalu di atas
    ScreenGui.ResetOnSpawn = false

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
    ToggleBtn.Position = UDim2.new(0, 15, 0.25, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleBtn.Text = "UI"
    ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 14
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true

    local UICorner = Instance.new("UICorner", ToggleBtn)
    UICorner.CornerRadius = UDim.new(1, 0)
    
    local UIStroke = Instance.new("UIStroke", ToggleBtn)
    UIStroke.Color = Color3.fromRGB(0, 255, 150)
    UIStroke.Thickness = 2

    ToggleBtn.MouseButton1Down:Connect(function()
        -- Trigger tombol minimize bawaan Fluent UI secara instan
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)
end)

Fluent:Notify({ Title = "W424 Loaded", Content = "99 night in forest test!", Duration = 3 })
