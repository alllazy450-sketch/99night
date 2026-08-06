-- 1. LOAD LOGIKA BACKEND (Langsung mengarah ke repo 99night milikmu)
local Functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/alllazy450-sketch/99night/main/functions.lua"))()

-- 2. LOAD UI LIBRARY (Orion UI Library)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({
    Name = "99 Nights in the Forest | W424 Hub",
    HidePremium = true,
    SaveConfig = false,
    ConfigFolder = "W424Config"
})

-- TABS
local MainTab   = Window:MakeTab({Name = "Main & Combat", Icon = "rbxassetid://4483345998"})
local AutoTab   = Window:MakeTab({Name = "Auto Farm", Icon = "rbxassetid://4483345998"})
local ItemTab   = Window:MakeTab({Name = "Item TP", Icon = "rbxassetid://4483345998"})
local PlayerTab = Window:MakeTab({Name = "Player", Icon = "rbxassetid://4483345998"})

-- ==========================================
-- MAIN & COMBAT TAB
-- ==========================================
MainTab:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(Value) _G.KillAura = Value end
})

MainTab:AddSlider({
    Name = "Kill Aura Radius",
    Min = 50, Max = 500, Default = 200, Color = Color3.fromRGB(255,255,255),
    Increment = 10,
    ValueName = "Studs",
    Callback = function(Value) _G.KillAuraRadius = Value end
})

-- ==========================================
-- AUTO FARM TAB
-- ==========================================
AutoTab:AddToggle({
    Name = "Auto Farm Wood (Auto Swing)",
    Default = false,
    Callback = function(Value) _G.AutoWood = Value end
})

AutoTab:AddToggle({
    Name = "Auto Hunt Mob (TP + Freeze)",
    Default = false,
    Callback = function(Value) _G.AutoHunt = Value end
})

AutoTab:AddDropdown({
    Name = "Pilih Target Mob",
    Default = "Wolf",
    Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Callback = function(Value) _G.SelectedMob = Value end
})

AutoTab:AddSlider({
    Name = "Ketinggian TP/Freeze",
    Min = 5, Max = 100, Default = 20, Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Height",
    Callback = function(Value) _G.HuntHeight = Value end
})

AutoTab:AddToggle({
    Name = "Auto Claim Meat/Drop Items",
    Default = false,
    Callback = function(Value) _G.AutoClaim = Value end
})

AutoTab:AddToggle({
    Name = "Enable Auto Feed Campfire",
    Default = false,
    Callback = function(Value) _G.AutoFeed = Value end
})

-- ==========================================
-- ITEM TP & PLAYER TAB
-- ==========================================
ItemTab:AddDropdown({
    Name = "Bring Item Bulk to Player",
    Default = "Log",
    Options = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"},
    Callback = function(Value)
        if Functions and Functions.BringItem then
            Functions.BringItem(Value)
        end
    end
})

PlayerTab:AddSlider({
    Name = "WalkSpeed",
    Min = 16, Max = 250, Default = 16, Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

OrionLib:Init()
