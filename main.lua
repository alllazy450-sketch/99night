-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- CLEAN FLUENT UI & STABLE CHOP AURA
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local UIReady = false

-- State Variables
local ChopAuraEnabled = false
local ChopAuraRadius = 30
local SelectedAxeName = "Old Axe"

local AutoClaimEnabled = false 
local AutoCookEnabled = false
local AutoFeedEnabled = false
local SelectedFeedMaterials = {["Log"] = true}

-- Utility Functions
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:IsDescendantOf(Workspace) and char:FindFirstChild("HumanoidRootPart")
end

local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name == toolName or child.Name:lower():find(toolName:lower())) then
            return child
        end
    end
    return char:FindFirstChildOfClass("Tool")
end

local function triggerPhysicalSwing(treeTarget)
    local tool = ensureToolEquipped(SelectedAxeName)
    if not tool then return end
    pcall(function() tool:Activate() end)
    local swing = tool:FindFirstChild("Swing") or tool:FindFirstChild("Attack")
    if swing then pcall(function() swing:FireServer() end) end
end

-- CHOP AURA ENGINE (NO TP)
task.spawn(function()
    while true do
        if UIReady and ChopAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood")) then
                            local trunk = obj:FindFirstChildWhichIsA("BasePart", true)
                            if trunk and (trunk.Position - hrp.Position).Magnitude <= ChopAuraRadius then
                                triggerPhysicalSwing(obj)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- REALTIME CLAIM
task.spawn(function()
    while true do
        if UIReady and AutoClaimEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp and itemFolder then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                            item:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 1, 0)))
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- UI SETUP (STANDAR AMAN FLUENT)
local Window = Fluent:CreateWindow({
    Title = "99 Nights | W424 Hub",
    SubTitle = "Chop Aura Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 320),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.Keycode.LeftControl
})

local Tabs = {
    Aura = Window:AddTab({ Title = "Chop Aura", Icon = "zap" }),
    Auto = Window:AddTab({ Title = "Auto", Icon = "axe" })
}

Tabs.Aura:AddToggle("ChopAura", { Title = "Enable Chop Aura", Default = false }):OnChanged(function(v) ChopAuraEnabled = v end)
Tabs.Aura:AddSlider("Range", { Title = "Aura Radius", Default = 30, Min = 10, Max = 60, Callback = function(v) ChopAuraRadius = v end })
Tabs.Auto:AddToggle("Claim", { Title = "Auto Claim Items", Default = false }):OnChanged(function(v) AutoClaimEnabled = v end)

-- MOBILE TOGGLE BUTTON AMAN
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild("W424_MobileToggle") then CoreGui.W424_MobileToggle:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "W424_MobileToggle"
    ScreenGui.Parent = CoreGui
    ScreenGui.DisplayOrder = 999999
    ScreenGui.ResetOnSpawn = false

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "W424Btn"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.Size = UDim2.fromOffset(50, 50)
    ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleBtn.Text = "UI"
    ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    ToggleBtn.Font = Enum.Font.SourceSansBold
    ToggleBtn.TextSize = 16
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true

    local UICorner = Instance.new("UICorner", ToggleBtn)
    UICorner.CornerRadius = UDim.new(1, 0)

    local isOpen = true
    ToggleBtn.MouseButton1Down:Connect(function()
        isOpen = not isOpen
        pcall(function()
            Fluent:ToggleWindow()
        end)
    end)
end)

UIReady = true
Fluent:Notify({ Title = "Success", Content = "Script berhasil dimuat tanpa error!", Duration = 3 })
