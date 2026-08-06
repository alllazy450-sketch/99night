local success, Functions = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/alllazy450-sketch/99night/refs/heads/main/functions.lua"))()
end)

if not success or not Functions then
    warn("Gagal memuat functions.lua! Memeriksa koneksi atau URL...")
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Mobile Edition",
    Author = "W424 Team",
    Folder = "W424Hub",
    Size = UDim2.fromOffset(580, 420),
    Transparent = true,
    Theme = "Dark"
})

local MainTab   = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389" })
local AutoTab   = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://10734950309" })
local ItemTab   = Window:Tab({ Title = "Item TP", Icon = "rbxassetid://10723345380" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "rbxassetid://10747373176" })

MainTab:Section({ Title = "Combat" })

MainTab:Toggle({
    Title = "Kill Aura",
    Default = false,
    Callback = function(v) _G.KillAura = v end
})

MainTab:Slider({
    Title = "Kill Aura Range",
    Min = 50, Max = 500, Default = 200,
    Callback = function(v) _G.KillAuraRadius = v end
})

AutoTab:Section({ Title = "Automation" })

AutoTab:Toggle({
    Title = "Auto Farm Wood",
    Default = false,
    Callback = function(v) _G.AutoWood = v end
})

AutoTab:Toggle({
    Title = "Auto Hunt Mob",
    Default = false,
    Callback = function(v) _G.AutoHunt = v end
})

AutoTab:Dropdown({
    Title = "Target Mob",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Default = "Wolf",
    Callback = function(v) _G.SelectedMob = v end
})

AutoTab:Toggle({
    Title = "Auto Claim Items",
    Default = false,
    Callback = function(v) _G.AutoClaim = v end
})

ItemTab:Section({ Title = "Bulk Items" })

ItemTab:Dropdown({
    Title = "Bring Item to Player",
    Values = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"},
    Callback = function(itemName)
        if Functions and Functions.BringItem then
            Functions.BringItem(itemName)
        end
    end
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end
})

WindUI:Notify({
    Title = "W424 Hub Ready",
    Content = "Berhasil memuat script dengan WindUI!",
    Duration = 4
})
