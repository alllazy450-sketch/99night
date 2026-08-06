-- 1. LOAD BACKEND LOGICAL MODULE (functions.lua)
local Functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/alllazy450-sketch/99night/main/functions.lua"))()

-- 2. SAFE LOADER RAYFIELD UI (Link Resmi & Anti HTTP Error)
local Rayfield = nil
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

-- Jika link domain sirius.menu bermasalah, gunakan link mirror GitHub resmi
if not success or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLTD/Rayfield/main/source.lua'))()
end

-- 3. BUAT WINDOW UTAMA
local Window = Rayfield:CreateWindow({
    Name = "99 Nights in the Forest | W424 Hub",
    LoadingTitle = "W424 Hub Loading...",
    LoadingSubtitle = "by lohjc & W424 Team",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- TABS
local MainTab   = Window:CreateTab("Main & Combat", 4483345998)
local AutoTab   = Window:CreateTab("Auto Farm", 4483345998)
local ItemTab   = Window:CreateTab("Item TP", 4483345998)
local PlayerTab = Window:CreateTab("Player", 4483345998)

-- ==========================================
-- MAIN & COMBAT TAB
-- ==========================================
MainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(Value)
        _G.KillAura = Value
    end,
})

MainTab:CreateSlider({
    Name = "Kill Aura Radius",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 200,
    Flag = "KillAuraRadiusSlider",
    Callback = function(Value)
        _G.KillAuraRadius = Value
    end,
})

-- ==========================================
-- AUTO FARM TAB
-- ==========================================
AutoTab:CreateToggle({
    Name = "Auto Farm Wood (Auto Swing)",
    CurrentValue = false,
    Flag = "AutoWoodToggle",
    Callback = function(Value)
        _G.AutoWood = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Hunt Mob (TP + Freeze)",
    CurrentValue = false,
    Flag = "AutoHuntToggle",
    Callback = function(Value)
        _G.AutoHunt = Value
    end,
})

AutoTab:CreateDropdown({
    Name = "Pilih Target Mob",
    Options = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    CurrentOption = {"Wolf"},
    MultipleOptions = false,
    Flag = "TargetMobDropdown",
    Callback = function(Option)
        _G.SelectedMob = typeof(Option) == "table" and Option[1] or Option
    end,
})

AutoTab:CreateSlider({
    Name = "Ketinggian TP/Freeze",
    Range = {5, 100},
    Increment = 1,
    Suffix = "Height",
    CurrentValue = 20,
    Flag = "HuntHeightSlider",
    Callback = function(Value)
        _G.HuntHeight = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Claim Meat/Drop Items",
    CurrentValue = false,
    Flag = "AutoClaimToggle",
    Callback = function(Value)
        _G.AutoClaim = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Enable Auto Feed Campfire",
    CurrentValue = false,
    Flag = "AutoFeedToggle",
    Callback = function(Value)
        _G.AutoFeed = Value
    end,
})

-- ==========================================
-- ITEM TP TAB
-- ==========================================
ItemTab:CreateDropdown({
    Name = "Bring Item Bulk to Player",
    Options = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"},
    CurrentOption = {"Log"},
    MultipleOptions = false,
    Flag = "BringItemDropdown",
    Callback = function(Option)
        local itemName = typeof(Option) == "table" and Option[1] or Option
        if Functions and Functions.BringItem then
            Functions.BringItem(itemName)
        end
    end,
})

-- ==========================================
-- PLAYER TAB
-- ==========================================
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end,
})

Rayfield:Notify({
    Title = "W424 Hub Loaded",
    Content = "Script Rayfield UI Berhasil Dimuat!",
    Duration = 5,
    Image = 4483345998,
})
