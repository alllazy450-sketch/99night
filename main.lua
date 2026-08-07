-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- OFFICIAL SOURCE CHOP AURA INTEGRATION
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UIReady = false
local ChopAuraEnabled = false
local ChopAuraRadius = 25 -- Default aman sesuai source kamu (< 20-25)
local AutoClaimEnabled = false 

-- State variabel untuk axe & damage ID
local SelectedAxeName = "Old Axe"

-- Utility Function untuk mendapatkan HumanoidRootPart
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- CHOP AURA ENGINE (MENGGUNAKAN SOURCE KAMU)
-- ==========================================
task.spawn(function()
    while task.wait(0.25) do
        if UIReady and ChopAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                local inventory = LocalPlayer:FindFirstChild("Inventory")
                local axeTool = inventory and inventory:FindFirstChild(SelectedAxeName)
                if not axeTool then
                    axeTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(SelectedAxeName)
                end

                if not axeTool then return end

                local valueAxe = "1_" .. LocalPlayer.UserId

                -- Cek folder Foliage sesuai source asli kamu
                local foliageFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliageFolder then return end

                for _, v in ipairs(foliageFolder:GetChildren()) do
                    if not ChopAuraEnabled then break end
                    
                    if v.Name == "Small Tree" and v:FindFirstChild("Trunk") then
                        local distance = (hrp.Position - v.Trunk.Position).Magnitude
                        if distance <= ChopAuraRadius then
                            ReplicatedStorage.RemoteEvents.ToolDamageObject:InvokeServer(
                                v,
                                axeTool,
                                valueAxe,
                                CFrame.new(v.Trunk.Position)
                            )
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

-- ==========================================
-- SETUP FLUENT UI & MOBILE TOGGLE
-- ==========================================
task.spawn(function()
    repeat task.wait() until Fluent ~= nil
    
    local Window = Fluent:CreateWindow({
        Title = "W424 Hub",
        SubTitle = "99 Nights | Custom Aura",
        Size = UDim2.new(0, 420, 0, 280),
        Theme = "Dark"
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Chop Aura", Icon = "zap" })
    }

    Tabs.Main:AddToggle("ChopAura", { Title = "Enable Chop Aura", Default = false }):OnChanged(function(v) 
        ChopAuraEnabled = v 
    end)

    Tabs.Main:AddSlider("Range", { 
        Title = "Aura Radius (Studs)", 
        Default = 25, 
        Min = 10, 
        Max = 50, 
        Callback = function(v) 
            ChopAuraRadius = v 
        end 
    })

    Tabs.Main:AddDropdown("AxeSelect", {
        Title = "Select Axe",
        Values = {"Old Axe", "Good Axe", "Strong Axe"},
        Default = "Old Axe",
        Callback = function(v)
            SelectedAxeName = v
        end
    })

    Tabs.Main:AddToggle("Claim", { Title = "Auto Claim Items", Default = false }):OnChanged(function(v) 
        AutoClaimEnabled = v 
    end)

    -- Mobile Toggle Button Melayang (AMAN & ANTI-CRASH)
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
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
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
