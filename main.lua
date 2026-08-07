-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ORION LIBRARY EDITION (MOBILE 100% FIX)
-- ==========================================

-- Menggunakan Orion Library (Lebih stabil untuk Mobile Executor)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexsoftware/Orion/main/source')))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UIReady = false
local ChopAuraEnabled = false
local ChopAuraRadius = 25
local AutoClaimEnabled = false 
local SelectedAxeName = "Old Axe"

-- Utility Function
local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- CHOP AURA ENGINE (SOURCE ASLI KAMU)
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

-- ==========================================
-- REALTIME AUTO CLAIM
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
-- ORION UI SETUP
-- ==========================================
local Window = OrionLib:MakeWindow({
    Name = "W424 Hub | 99 Nights", 
    HidePremium = true, 
    SaveConfig = false, 
    IntroText = "Memuat W424 Hub..."
})

local Tab = Window:MakeTab({
    Name = "Chop Aura",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

Tab:AddToggle({
    Name = "Enable Chop Aura",
    Default = false,
    Callback = function(Value)
        ChopAuraEnabled = Value
    end    
})

Tab:AddSlider({
    Name = "Aura Radius (Studs)",
    Min = 10,
    Max = 60,
    Default = 25,
    Color = Color3.fromRGB(0, 255, 150),
    Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        ChopAuraRadius = Value
    end    
})

Tab:AddDropdown({
    Name = "Select Axe",
    Default = "Old Axe",
    Options = {"Old Axe", "Good Axe", "Strong Axe"},
    Callback = function(Value)
        SelectedAxeName = Value
    end    
})

Tab:AddToggle({
    Name = "Auto Claim Items",
    Default = false,
    Callback = function(Value)
        AutoClaimEnabled = Value
    end    
})

-- Selesaikan Inisialisasi Orion
OrionLib:Init()
UIReady = true
