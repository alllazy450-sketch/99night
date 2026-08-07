-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FINAL STABLE VERSION (ANTI-CRASH)
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Variabel Global yang aman
local UIReady = false
local ChopAuraEnabled = false
local ChopAuraRadius = 30
local AutoClaimEnabled = false 

-- Helper fungsi yang sudah teruji
local function getHRP()
    local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Engine Aura (Tanpa Teleport)
task.spawn(function()
    while task.wait(0.2) do
        if UIReady and ChopAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood")) then
                            local trunk = obj:FindFirstChildWhichIsA("BasePart", true)
                            if trunk and (trunk.Position - hrp.Position).Magnitude <= ChopAuraRadius then
                                local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
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

-- SETUP UI DENGAN PROTEKSI
task.spawn(function()
    repeat task.wait() until Fluent ~= nil
    
    local Window = Fluent:CreateWindow({
        Title = "W424 Hub",
        SubTitle = "99 Nights | Stable",
        Size = UDim2.fromOffset(480, 320),
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Tabs = {
        Main = Window:AddTab({ Title = "Main", Icon = "zap" })
    }

    Tabs.Main:AddToggle("ChopAura", { Title = "Enable Chop Aura", Default = false }):OnChanged(function(v) ChopAuraEnabled = v end)
    Tabs.Main:AddSlider("Range", { Title = "Aura Radius", Default = 30, Min = 10, Max = 60, Callback = function(v) ChopAuraRadius = v end })
    Tabs.Main:AddToggle("Claim", { Title = "Auto Claim Items", Default = false }):OnChanged(function(v) AutoClaimEnabled = v end)

    -- Mobile Toggle yang tidak bergantung pada fungsi minimize library
    pcall(function()
        local btn = Instance.new("TextButton", game:GetService("CoreGui"):FindFirstChild("RobloxGui"))
        btn.Name = "ToggleBtn"
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Position = UDim2.new(0, 10, 0.4, 0)
        btn.Text = "MENU"
        btn.Draggable = true
        btn.MouseButton1Down:Connect(function()
            -- Sembunyikan/Tampilkan container utama fluent secara langsung
            local container = game:GetService("CoreGui"):FindFirstChild("Fluent", true)
            if container then container.Enabled = not container.Enabled end
        end)
    end)
    
    UIReady = true
end)
