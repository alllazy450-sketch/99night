-- ==========================================
-- 99 NIGHT | 
-- ==========================================
-- Load UI Library
local Kairo = loadstring(game:HttpGet("https://raw.githubusercontent.com/Itzzavi335/Kairo-Ui-Library/refs/heads/main/source.luau"))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local TreesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")

if not RemoteEvents or not TreesFolder then
    warn("Missing required objects! Make sure you're in 99 Night.")
    return
end

-- ==========================================
-- CONFIG
-- ==========================================
local valueAxe = "1_" .. LocalPlayer.UserId
local treeAuraEnabled = false
local treeAuraRadius = 350
local treeESPEnabled = false
local treeESPList = {}

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getTreePart(tree)
    local trunk = tree:FindFirstChild("Trunk")
    if trunk and trunk:IsA("BasePart") then return trunk end
    if tree.PrimaryPart then return tree.PrimaryPart end
    for _, child in ipairs(tree:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("MeshPart") then
            return child
        end
    end
    return nil
end

local function getTool()
    local locations = {LocalPlayer.Inventory, LocalPlayer.Backpack, LocalPlayer.Character}
    for _, loc in ipairs(locations) do
        if loc then
            local tool = loc:FindFirstChild("Old Axe")
            if tool then return tool end
        end
    end
    return nil
end

-- ==========================================
-- TREE ESP
-- ==========================================
local espFolder = Instance.new("Folder")
espFolder.Name = "TreeESP"
espFolder.Parent = CoreGui

local function createTreeESP(tree)
    if treeESPList[tree] then return end
    local part = getTreePart(tree)
    if not part then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "TreeESP"
    bb.Size = UDim2.fromScale(4, 1)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espFolder
    bb.Adornee = part

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0
    text.TextColor3 = Color3.fromRGB(0, 255, 0)
    text.Parent = bb

    treeESPList[tree] = { gui = bb, label = text, part = part }
end

local function updateTreeESP(tree)
    local esp = treeESPList[tree]
    if not esp then return end
    local hp = tree:GetAttribute("Health")
    if not hp then
        esp.gui:Destroy()
        treeESPList[tree] = nil
        return
    end
    esp.label.Text = ("HP: %d"):format(hp)
    if hp > 5 then
        esp.label.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif hp > 2 then
        esp.label.TextColor3 = Color3.fromRGB(255, 170, 0)
    else
        esp.label.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end

local function refreshTreeESP()
    for _, esp in pairs(treeESPList) do
        pcall(function() esp.gui:Destroy() end)
    end
    treeESPList = {}
    if treeESPEnabled and TreesFolder then
        for _, tree in ipairs(TreesFolder:GetChildren()) do
            if tree.Name == "Small Tree" then
                createTreeESP(tree)
                updateTreeESP(tree)
            end
        end
    end
end

-- ==========================================
-- UI SETUP
-- ==========================================
local cam = workspace.CurrentCamera
local screenSize = cam and cam.ViewportSize or Vector2.new(500, 600)
local uiWidth = math.min(340, math.max(300, screenSize.X * 0.9))
local uiHeight = math.min(420, math.max(320, screenSize.Y * 0.78))

local Window = Kairo:CreateWindow({
    Title = "Tree Aura",
    Theme = "Midnight",
    Size = UDim2.fromOffset(uiWidth, uiHeight),
    Center = true,
    Draggable = true,
    Resize = false,
    Badges = {"99N", "v1.0"},
    MinimizeKey = Enum.KeyCode.RightShift,
    MinimizeButton = true,
    Config = { Enabled = true, Folder = "TreeAura_Config", AutoLoad = true }
})

local MainTab = Window:CreateTab("Main", "rbxassetid://16932740082")
local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://16932740082")
local PlayerTab = Window:CreateTab("Player", "rbxassetid://16932740082")
local MiscTab = Window:CreateTab("Misc", "rbxassetid://16932740082")

-- ==========================================
-- MAIN TAB (Tree Aura)
-- ==========================================
Window:AddParagraph(MainTab, "Tree Aura", "Nebang pohon otomatis di sekitar")

Window:AddToggle(MainTab, "Tree Aura", "Aktifkan / Nonaktifkan", false, function(state)
    treeAuraEnabled = state
    if state then
        Window:Notify({Title = "Tree Aura", Description = "ON", Content = "Mencari pohon...", Color = Color3.fromRGB(0,200,0), Delay = 2})
    else
        Window:Notify({Title = "Tree Aura", Description = "OFF", Content = "Dinonaktifkan", Color = Color3.fromRGB(200,0,0), Delay = 2})
    end
end, "TreeAura")

Window:AddSlider(MainTab, "Radius", "Jarak tebang pohon", 50, 500, 350, function(value)
    treeAuraRadius = value
end, "Radius", true)

Window:AddButton(MainTab, "Test Chop", "Tebang pohon terdekat (1x)", "rbxassetid://16932740082", function()
    local hrp = getRootPart()
    local tool = getTool()
    if not hrp or not tool then
        Window:Notify({Title = "Error", Description = "Old Axe tidak ditemukan!", Content = "Pastikan ada Old Axe di inventory/backpack", Color = Color3.fromRGB(255,0,0), Delay = 3})
        return
    end
    local closestTree = nil
    local closestDist = math.huge
    for _, tree in ipairs(TreesFolder:GetChildren()) do
        if tree.Name == "Small Tree" and tree:IsDescendantOf(workspace) then
            local part = getTreePart(tree)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestTree = tree
                end
            end
        end
    end
    if closestTree then
        local part = getTreePart(closestTree)
        local hp = closestTree:GetAttribute("Health") or 10
        if hp > 0 then
            pcall(function()
                RemoteEvents.ToolDamageObject:InvokeServer(closestTree, tool, valueAxe, part.CFrame)
            end)
            Window:Notify({Title = "Chop", Description = "Menebang pohon terdekat!", Content = "Jarak: " .. math.floor(closestDist) .. "m", Color = Color3.fromRGB(0,200,255), Delay = 2})
        else
            Window:Notify({Title = "Info", Description = "Pohon sudah mati", Content = "HP: 0", Color = Color3.fromRGB(255,170,0), Delay = 2})
        end
    else
        Window:Notify({Title = "Info", Description = "Tidak ada pohon di sekitar", Content = "Radius: " .. treeAuraRadius, Color = Color3.fromRGB(255,170,0), Delay = 2})
    end
end)

-- ==========================================
-- VISUALS TAB (Tree ESP)
-- ==========================================
Window:AddParagraph(VisualsTab, "Tree ESP", "Tampilkan HP pohon")
Window:AddToggle(VisualsTab, "ESP Trees", "Tampilkan indikator HP di atas pohon", false, function(state)
    treeESPEnabled = state
    if state then
        refreshTreeESP()
    else
        for _, esp in pairs(treeESPList) do
            pcall(function() esp.gui:Destroy() end)
        end
        treeESPList = {}
    end
end, "ESPTrees")

-- ==========================================
-- PLAYER TAB (WalkSpeed, Jump)
-- ==========================================
Window:AddParagraph(PlayerTab, "Stats", "Modifikasi Karakter")
Window:AddSlider(PlayerTab, "WalkSpeed", "Kecepatan berjalan", 0, 200, 16, function(value)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = value end
end, "WalkSpeed", true)

local infiniteJumpEnabled = false
Window:AddToggle(PlayerTab, "Infinite Jump", "Lompat tanpa batas di udara", false, function(state)
    infiniteJumpEnabled = state
end, "InfJump")
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ==========================================
-- MISC TAB (Fullbright, FPS)
-- ==========================================
Window:AddParagraph(MiscTab, "Miscellaneous", "Fitur Tambahan")

local fullbrightConn = nil
Window:AddToggle(MiscTab, "Fullbright", "Membuat map terang benderang", false, function(state)
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        fullbrightConn = RunService.RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        end)
    else
        if fullbrightConn then
            fullbrightConn:Disconnect()
            fullbrightConn = nil
        end
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
    end
end, "Fullbright")

-- FPS Counter
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPS_Counter"
fpsGui.ResetOnSpawn = false
fpsGui.Parent = CoreGui
fpsGui.Enabled = false

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 100, 0, 25)
fpsLabel.Position = UDim2.new(0, 10, 0, 80)
fpsLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
fpsLabel.BackgroundTransparency = 0.4
fpsLabel.TextColor3 = Color3.fromRGB(0,255,128)
fpsLabel.TextSize = 14
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Text = "FPS: 0"
fpsLabel.Parent = fpsGui
Instance.new("UICorner", fpsLabel).CornerRadius = UDim.new(0, 6)

local lastTick = tick()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastTick >= 1 then
        local fps = math.round(frameCount / (tick() - lastTick))
        fpsLabel.Text = "FPS: " .. fps
        frameCount = 0
        lastTick = tick()
    end
end)

Window:AddToggle(MiscTab, "FPS Counter", "Tampilkan FPS di layar", false, function(state)
    fpsGui.Enabled = state
end, "FpsCounter")

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================

-- TREE AURA LOOP
task.spawn(function()
    while true do
        if treeAuraEnabled then
            local hrp = getRootPart()
            local tool = getTool()
            if hrp and tool and TreesFolder then
                for _, tree in ipairs(TreesFolder:GetChildren()) do
                    if tree.Name == "Small Tree" and tree:IsDescendantOf(workspace) then
                        local treePart = getTreePart(tree)
                        if not treePart then continue end
                        local dist = (treePart.Position - hrp.Position).Magnitude
                        if dist <= treeAuraRadius then
                            local hp = tree:GetAttribute("Health")
                            if hp == nil then hp = 10 end
                            if hp > 0 then
                                pcall(function()
                                    RemoteEvents.ToolDamageObject:InvokeServer(
                                        tree,
                                        tool,
                                        valueAxe,
                                        treePart.CFrame  -- Dynamic CFrame!
                                    )
                                end)
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- TREE ESP REFRESH
task.spawn(function()
    while true do
        if treeESPEnabled and TreesFolder then
            for _, tree in ipairs(TreesFolder:GetChildren()) do
                if tree.Name == "Small Tree" then
                    createTreeESP(tree)
                    updateTreeESP(tree)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ==========================================
-- KEYBIND (F5 TOGGLE TREE AURA)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F5 then
        treeAuraEnabled = not treeAuraEnabled
        Window:Notify({
            Title = "Tree Aura",
            Description = treeAuraEnabled and "ON" or "OFF",
            Content = "Press F5 again to toggle",
            Color = treeAuraEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0),
            Delay = 2
        })
        -- Update toggle UI jika ada flag (opsional)
    end
end)

-- ==========================================
-- NOTIFICATION LOADED
-- ==========================================
Window:Notify({
    Title = "Tree Aura",
    Description = "Loaded",
    Content = "Press F5 to toggle Tree Aura\nRightShift for menu",
    Color = Color3.fromRGB(10, 30, 60),
    Delay = 5
})

print("W424 JELEK!!!!")