-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FULL FEATURED (FLUENT UI + FIXED CHOP AURA)
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local UIReady = false

-- State Variables
local ChopAuraEnabled = false
local ChopAuraRadius = 25
local SelectedAxeName = "Old Axe"
local AutoClaimEnabled = false 
local AutoFeedEnabled = false

local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- 1. CHOP AURA ENGINE (DIPERBAIKI AGAR KAYU JATUH)
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
                local foliageFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage")
                if not foliageFolder then return end

                for _, v in ipairs(foliageFolder:GetChildren()) do
                    if not ChopAuraEnabled then break end
                    
                    -- Mencari bagian dasar pohon dengan aman tanpa memicu error 'Trunk missing'
                    local targetPart = v:FindFirstChild("Trunk") or v:FindFirstChild("PrimaryPart") or v:FindFirstChildWhichIsA("BasePart")
                    
                    if targetPart then
                        local distance = (hrp.Position - targetPart.Position).Magnitude
                        if distance <= ChopAuraRadius then
                            local damageRemote = RemotesFolder:FindFirstChild("ToolDamageObject")
                            if damageRemote then
                                damageRemote:InvokeServer(
                                 v,
                                    axeTool,
                                    valueAxe,
                                    CFrame.new(targetPart.Position)
                                )
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- 2. AUTO CLAIM / LOOT ITEMS ENGINE
-- ==========================================
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
-- 3. AUTO FEED CAMPFIRE ENGINE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if UIReady and AutoFeedEnabled then
            pcall(function()
                local hrp = getHRP()
                local burnRemote = RemotesFolder:FindFirstChild("RequestBurnItem")
                if hrp and burnRemote then
                    -- Cari log/kayu di inventory untuk dimasukkan ke campfire
                    local inventory = LocalPlayer:FindFirstChild("Inventory")
                    if inventory then
                        for _, item in ipairs(inventory:GetChildren()) do
                            if item.Name:lower():find("log") or item.Name:lower():find("wood") then
                                burnRemote:FireServer(item)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- FLUENT UI SETUP (DENGAN TAB LENGKAP)
-- ==========================================
task.spawn(function()
    repeat task.wait() until Fluent ~= nil

    local Window = Fluent:CreateWindow({
        Title = "W424 Hub | 99 Nights",
        SubTitle = "Full Features Edition",
        TabWidth = 160,
        Size = UDim2.new(0, 480, 0, 340),
        Theme = "Dark",
        Acrylic = false
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Chop Aura", Icon = "zap" }),
        Auto = Window:AddTab({ Title = "Automation", Icon = "package" })
    }

    -- Tab Chop Aura
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

    -- Tab Automation (Auto Claim & Auto Feed)
    Tabs.Auto:AddToggle("Claim", { Title = "Auto Claim / Bring Items", Default = false }):OnChanged(function(v) 
        AutoClaimEnabled = v 
    end)

    Tabs.Auto:AddToggle("Feed", { Title = "Auto Feed Campfire", Default = false }):OnChanged(function(v) 
        AutoFeedEnabled = v 
    end)

    -- Mobile Toggle Button Melayang Aman (Pengganti MinimizeKey yang error)
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
    Fluent:Notify({ Title = "Success", Content = "W424 Hub berhasil dimuat secara penuh!", Duration = 3 })
end)
