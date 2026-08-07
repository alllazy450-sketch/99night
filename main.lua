-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FINAL CUSTOM UI (FIXED)
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

-- ==========================================
-- DAMAGE ID MAPPING
-- ==========================================
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

-- ==========================================
-- UTILITY FUNCTIONS (sama seperti sebelumnya)
-- ==========================================
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
    local equipRemotes = {
        RemotesFolder:FindFirstChild("EquipItemHandle"),
        RemotesFolder:FindFirstChild("EquipItem"),
        RemotesFolder:FindFirstChild("EquipTool"),
        RemotesFolder:FindFirstChild("SelectTool")
    }
    for _, remote in ipairs(equipRemotes) do
        if remote then
            pcall(function() remote:FireServer(tool) end)
            task.wait(0.15)
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
            pcall(function() remote:FireServer(toolName) end)
            task.wait(0.15)
            if char:FindFirstChild(toolName) then return char:FindFirstChild(toolName) end
        end
    end
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
    local success = false
    pcall(function() tool:Activate() success = true end)
    task.wait(0.05)
    local swing = tool:FindFirstChild("Swing")
    if swing then pcall(function() swing:FireServer() success = true end) end
    local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
    if damageRemote then
        pcall(function()
            damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position))
            success = true
        end)
    end
    local hitRemote = RemotesFolder:FindFirstChild("Hit") or RemotesFolder:FindFirstChild("DealDamage")
    if hitRemote then pcall(function() hitRemote:FireServer(target, tool) success = true end) end
    if not success then
        pcall(function()
            local clickDetector = tool:FindFirstChildWhichIsA("ClickDetector")
            if clickDetector then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                success = true
            end
        end)
    end
    return success
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

local function getTreePart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    return tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1")
        or tree:FindFirstChild("MainPart") or tree:FindFirstChild("Head")
        or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
end

local function getFilteredTrees()
    local trees = {}
    local treeType = getgenv().W424.TreeType
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                local match = false
                if treeType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then match = true end
                elseif treeType == "Small Trees" and name == "Small Tree" then match = true
                elseif treeType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then match = true
                elseif treeType == "Brightwood Trees" and name:find("Brightwood") then match = true
                elseif treeType == "Fairy Trees" and (name:find("Fairy") or name:find("Suci")) then match = true
                end
                if match and getTreePart(obj) then table.insert(trees, obj) end
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        local folders = {"Foliage", "Landmarks", "Trees", "Environment", "Resources"}
        for _, fname in ipairs(folders) do
            local f = map:FindFirstChild(fname)
            if f then scan(f) end
        end
        scan(map)
    end
    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood") or obj.Name:find("Fairy")) then
                if getTreePart(obj) then table.insert(trees, obj) end
            end
        end
    end
    return trees
end

-- ==========================================
-- ENGINE LOOPS (disingkat agar tidak terlalu panjang)
-- ==========================================
-- 1. Chop Aura
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.ChopAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.ChopRadius
                local foliage = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliage then return end
                for _, tree in ipairs(foliage:GetChildren()) do
                    if not getgenv().W424.ChopAura then break end
                    local part = getTreePart(tree)
                    if part and (hrp.Position - part.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.05)
                    end
                end
            end)
        end
    end
end)

-- 2. Kill Aura
task.spawn(function()
    while task.wait(0.15) do
        if getgenv().W424.KillAura then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.KillRadius
                local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace
                for _, mob in ipairs(enemies:GetChildren()) do
                    if not getgenv().W424.KillAura then break end
                    if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob ~= LocalPlayer.Character then
                        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if part and (hrp.Position - part.Position).Magnitude <= radius then
                            attackTarget(mob, tool, damageID)
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)

-- 3. Auto Wood
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().W424.AutoWood then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local radius = getgenv().W424.WoodRadius
                local trees = getFilteredTrees()
                for _, tree in ipairs(trees) do
                    if not getgenv().W424.AutoWood then break end
                    local part = getTreePart(tree)
                    if part and (hrp.Position - part.Position).Magnitude <= radius then
                        attackTarget(tree, tool, damageID)
                        task.wait(0.1)
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Hunt
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().W424.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end
                local tool = equipTool(getgenv().W424.SelectedTool)
                if not tool then return end
                local damageID = getDamageID(getgenv().W424.SelectedTool)
                local targetName = getgenv().W424.TargetMob
                local radius = getgenv().W424.HuntRadius
                local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs") or Workspace
                for _, mob in ipairs(enemies:GetChildren()) do
                    if not getgenv().W424.AutoHunt then break end
                    if mob:IsA("Model") and mob.Name:find(targetName) and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        local part = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if part and (hrp.Position - part.Position).Magnitude <= radius then
                            attackTarget(mob, tool, damageID)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Claim
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoClaim then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                        dragItemToPos(item, hrp.Position + Vector3.new(0, 1.5, 0))
                    end
                end
            end)
        end
    end
end)

-- 6. Auto Feed
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

-- 7. Auto Bring Chest
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().W424.AutoBringChest then
            pcall(function()
                local hrp = getHRP()
                if not hrp or not itemFolder then return end
                for _, chest in ipairs(itemFolder:GetChildren()) do
                    if not getgenv().W424.AutoBringChest then break end
                    if chest:IsA("Model") and chest.Name:find("Chest") then
                        local main = chest:FindFirstChild("Main") or chest.PrimaryPart
                        if main then
                            for _, obj in ipairs(main:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    pcall(function() obj.RequiresLineOfSight = false end)
                                    fireproximityprompt(obj)
                                    task.wait(0.2)
                                    for _, loot in ipairs(itemFolder:GetChildren()) do
                                        if loot ~= chest and loot:IsA("Model") and loot:IsDescendantOf(Workspace) then
                                            dragItemToPos(loot, hrp.Position + Vector3.new(0, 2, 0))
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
-- RESPAWN HANDLER
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function(char)
    print("[W424] Character respawned.")
end)

-- ==========================================
-- CUSTOM UI (DIPERBAIKI - PASTI MUNCUL)
-- ==========================================
local function createUI()
    -- Hapus UI lama jika ada
    pcall(function()
        if CoreGui:FindFirstChild("W424_UI") then CoreGui.W424_UI:Destroy() end
        if LocalPlayer.PlayerGui:FindFirstChild("W424_UI") then LocalPlayer.PlayerGui.W424_UI:Destroy() end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "W424_UI"
    screenGui.ResetOnSpawn = false

    -- Coba parent ke CoreGui, jika gagal ke PlayerGui
    local success, err = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
        print("[W424] UI dipasang di PlayerGui (CoreGui tidak diizinkan)")
    else
        print("[W424] UI dipasang di CoreGui")
    end

    -- Main Frame
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 350, 0, 480)
    main.Position = UDim2.new(0.5, -175, 0.5, -240)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BackgroundTransparency = 0.05
    main.Active = true
    main.Draggable = true
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(0, 255, 180)
    stroke.Thickness = 1.5

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "W424 Hub | 99 Nights"
    title.TextColor3 = Color3.fromRGB(0, 255, 180)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    -- Close
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255,255,255)
    close.Font = Enum.Font.GothamBold
    close.Parent = main
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.Parent = main

    local list = Instance.new("UIListLayout")
    list.Parent = scroll
    list.Padding = UDim.new(0, 6)

    -- Helper functions (UI)
    local function createToggle(text, stateKey)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
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
        return btn
    end

    local function createSlider(text, stateKey, min, max, default)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 50)
        container.BackgroundTransparency = 1
        container.Parent = scroll

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. " (" .. tostring(getgenv().W424[stateKey]) .. ")"
        label.TextColor3 = Color3.fromRGB(200,200,200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = container

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(getgenv().W424[stateKey])
        valueLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 13
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = container

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 6)
        slider.Position = UDim2.new(0, 0, 0, 25)
        slider.BackgroundColor3 = Color3.fromRGB(60,60,60)
        slider.Parent = container
        Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((getgenv().W424[stateKey] - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
        fill.Parent = slider
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function updateSlider(mouseX)
            local relX = math.clamp((mouseX - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local val = math.round(min + relX * (max - min))
            getgenv().W424[stateKey] = val
            fill.Size = UDim2.new(relX, 0, 1, 0)
            valueLabel.Text = tostring(val)
            label.Text = text .. " (" .. tostring(val) .. ")"
        end

        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateSlider(input.Position.X)
            end
        end)
        slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        slider.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)
    end

    local function createDropdown(text, stateKey, options)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 35)
        container.BackgroundTransparency = 1
        container.Parent = scroll

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.Text = text .. ": " .. getgenv().W424[stateKey]
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.Parent = container
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local menuOpen = false
        local menu = Instance.new("Frame")
        menu.Size = UDim2.new(1, 0, 0, #options * 30 + 10)
        menu.Position = UDim2.new(0, 0, 1, 0)
        menu.BackgroundColor3 = Color3.fromRGB(30,30,35)
        menu.Visible = false
        menu.Parent = container
        Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)

        local listMenu = Instance.new("UIListLayout")
        listMenu.Parent = menu
        listMenu.Padding = UDim.new(0, 2)

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -10, 0, 28)
            optBtn.BackgroundColor3 = Color3.fromRGB(50,50,55)
            optBtn.Text = opt
            optBtn.TextColor3 = Color3.fromRGB(255,255,255)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 12
            optBtn.Parent = menu
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)
            optBtn.MouseButton1Click:Connect(function()
                getgenv().W424[stateKey] = opt
                btn.Text = text .. ": " .. opt
                menu.Visible = false
                menuOpen = false
            end)
        end

        btn.MouseButton1Click:Connect(function()
            menuOpen = not menuOpen
            menu.Visible = menuOpen
        end)
    end

    -- ==== BUILD UI ====
    createToggle("Chop Aura (Radius)", "ChopAura")
    createSlider("Chop Radius", "ChopRadius", 10, 60, 25)
    createToggle("Kill Aura (Mob)", "KillAura")
    createSlider("Kill Radius", "KillRadius", 10, 60, 25)

    createToggle("Auto Wood (Radius)", "AutoWood")
    createSlider("Wood Radius", "WoodRadius", 10, 60, 30)
    createDropdown("Tree Type", "TreeType", {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"})

    createToggle("Auto Hunt (Radius)", "AutoHunt")
    createSlider("Hunt Radius", "HuntRadius", 10, 60, 30)
    createDropdown("Target Mob", "TargetMob", {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"})

    createToggle("Auto Claim Drops", "AutoClaim")
    createToggle("Auto Feed Campfire", "AutoFeed")
    createDropdown("Feed Material", "FeedMaterial", {"Log", "Coal", "Biofuel", "Fuel Canister"})
    createToggle("Auto Bring Chest", "AutoBringChest")
    createDropdown("Selected Tool", "SelectedTool", {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw", "Spear"})

    -- Floating toggle button
    local floatBtn = Instance.new("TextButton")
    floatBtn.Size = UDim2.new(0, 50, 0, 50)
    floatBtn.Position = UDim2.new(0, 10, 0.4, 0)
    floatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    floatBtn.Text = "⚡"
    floatBtn.TextColor3 = Color3.fromRGB(0, 255, 180)
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextSize = 24
    floatBtn.Parent = screenGui
    floatBtn.Draggable = true
    Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
    local floatStroke = Instance.new("UIStroke", floatBtn)
    floatStroke.Color = Color3.fromRGB(0, 255, 180)
    floatStroke.Thickness = 2

    close.MouseButton1Click:Connect(function() main.Visible = false end)
    floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

    print("[W424] UI berhasil dibuat.")
end

-- Jalankan UI dengan pcall
pcall(createUI)

-- Notifikasi kecil
task.wait(1)
local notif = Instance.new("TextLabel")
notif.Size = UDim2.new(0, 250, 0, 40)
notif.Position = UDim2.new(0.5, -125, 0.9, 0)
notif.BackgroundColor3 = Color3.fromRGB(20,20,25)
notif.Text = "W424 Hub Loaded! ⚡"
notif.TextColor3 = Color3.fromRGB(0,255,180)
notif.Font = Enum.Font.GothamBold
notif.TextSize = 16
notif.Parent = CoreGui
Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
task.wait(3)
notif:Destroy()

print("[W424] Script selesai.")