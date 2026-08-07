-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTRA CLEAN & ERROR-FREE VERSION
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local UIReady = false
local ChopAuraEnabled = false
local ChopAuraRadius = 30
local AutoClaimEnabled = false 

-- Utility Function
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Chop Aura Engine (Tanpa TP)
task.spawn(function()
    while task.wait(0.2) do
        if UIReady and ChopAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood")) then
                            local trunk = obj:FindFirstChildWhichIsA("BasePart", true)
                            if trunk and (trunk.Position - hrp.Position).Magnitude <= ChopAuraRadius then
                                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                if tool then
                                    pcall(function() tool:Activate() end)
                                    local swing = tool:FindFirstChild("Swing") or tool:FindFirstChild("Attack")
                                    if swing then swing:FireServer() end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Realtime Auto Claim
task.spawn(function()
    while task.wait(0.5) do
        if UIReady and AutoClaimEnabled then
            pcall(function()
                local hrp = getHRP()
                local itemFolder = Workspace:FindFirstChild("Items")
                if hrp and itemFolder then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsA("Model") and item:IsDescendantOf(Workspace) then
                            item:PivotTo(CFrame.new(hrp.Position + Vector3.new(0, 1, 0)))
                        end
                    end
                end
            end)
        end
    end
end)

-- SETUP UI (TANPA MINIMIZEKEY SUPAYA 100% AMAN DI MOBILE)
task.spawn(function()
    repeat task.wait() until Fluent ~= nil
    
    local Window = Fluent:CreateWindow({
        Title = "W424 Hub",
        SubTitle = "99 Nights | Chop Aura",
        Size = UDim2.fromOffset(480, 320),
        Theme = "Dark"
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Main", Icon = "zap" })
    }

    Tabs.Main:AddToggle("ChopAura", { Title = "Enable Chop Aura", Default = false }):OnChanged(function(v) ChopAuraEnabled = v end)
    Tabs.Main:AddSlider("Range", { Title = "Aura Radius", Default = 30, Min = 10, Max = 60, Callback = function(v) ChopAuraRadius = v end })
    Tabs.Main:AddToggle("Claim", { Title = "Auto Claim Items", Default = false }):OnChanged(function(v) AutoClaimEnabled = v end)

    -- Mobile Toggle Button
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

        ToggleBtn.MouseButton1Down:Connect(function()
            local container = CoreGui:FindFirstChild("Fluent", true)
            if container then
                container.Enabled = not container.Enabled
            end
        end)
    end)
    
    UIReady = true
end)
