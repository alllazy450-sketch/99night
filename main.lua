-- URL WindUI resmi dari GitHub (Bebas Error HTTP 402)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Mobile Edition",
    Author = "lohjc & W424 Team",
    Folder = "W424Hub",
    Size = UDim2.fromOffset(580, 420),
    Transparent = true,
    Theme = "Dark"
})

-- TABS
local MainTab   = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389" })
local AutoTab   = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://10734950309" })
local ItemTab   = Window:Tab({ Title = "Item ESP/TP", Icon = "rbxassetid://10723345380" })
local GameTPTab = Window:Tab({ Title = "Game TP", Icon = "rbxassetid://10734951847" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "rbxassetid://10747373176" })

-- SERVICES & VARS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local itemFolder = workspace:WaitForChild("Items")

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- 1. MAIN TAB
-- ==========================================
MainTab:Section({ Title = "Safe Zone & Combat" })

local safezoneParts = {}
for dx = -1, 1 do
    for dz = -1, 1 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(2048, 1, 2048)
        part.Position = Vector3.new(dx * 2048, 100, dz * 2048)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Parent = workspace
        table.insert(safezoneParts, part)
    end
end

MainTab:Toggle({
    Title = "Show Safe Zone",
    Default = false,
    Callback = function(val)
        for _, p in ipairs(safezoneParts) do
            p.Transparency = val and 0.8 or 1
            p.CanCollide = val
        end
    end
})

local killAuraToggle = false
local killAuraRadius = 200
local weapons = {
    ["Spear"] = "196_8999010016", ["Strong Axe"] = "116_8982038982",
    ["Good Axe"] = "112_8982038982", ["Old Axe"] = "1_8982038982",
    ["Chainsaw"] = "647_8992824875"
}

local function getWeapon()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return nil, nil end
    for wName, dID in pairs(weapons) do
        local t = inv:FindFirstChild(wName)
        if t then return t, dID end
    end
    return nil, nil
end

task.spawn(function()
    while true do
        if killAuraToggle then
            local hrp = getHRP()
            if hrp then
                local tool, dmgID = getWeapon()
                if tool and dmgID then
                    pcall(function() remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end)
                    local mobs = workspace:FindFirstChild("Characters")
                    if mobs then
                        for _, mob in ipairs(mobs:GetChildren()) do
                            local p = mob:FindFirstChildWhichIsA("BasePart")
                            if p and (p.Position - hrp.Position).Magnitude <= killAuraRadius then
                                pcall(function() remoteEvents.ToolDamageObject:InvokeServer(mob, tool, dmgID, CFrame.new(p.Position)) end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

MainTab:Toggle({
    Title = "Kill Aura",
    Default = false,
    Callback = function(v) killAuraToggle = v end
})

MainTab:Slider({
    Title = "Kill Aura Range",
    Min = 50, Max = 500, Default = 200,
    Callback = function(v) killAuraRadius = v end
})

-- ==========================================
-- 2. AUTO FARM TAB
-- ==========================================
AutoTab:Section({ Title = "Auto Wood & Mob Hunt" })

local autoWoodToggle = false
local autoWoodRadius = 200

task.spawn(function()
    while true do
        if autoWoodToggle then
            local hrp = getHRP()
            if hrp then
                local axe, dmgID = getWeapon()
                if axe and dmgID then
                    pcall(function() remoteEvents.EquipItemHandle:FireServer("FireAllClients", axe) end)
                    VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name == "Small Tree") then
                            local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                            if trunk and (trunk.Position - hrp.Position).Magnitude <= autoWoodRadius then
                                pcall(function() remoteEvents.ToolDamageObject:InvokeServer(obj, axe, dmgID, CFrame.new(trunk.Position)) end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

AutoTab:Toggle({
    Title = "Auto Farm Wood",
    Default = false,
    Callback = function(v) autoWoodToggle = v end
})

local autoHuntToggle = false
local huntHeight = 20
local selectedMob = "Wolf"

task.spawn(function()
    while true do
        if autoHuntToggle then
            local hrp = getHRP()
            local mobs = workspace:FindFirstChild("Characters")
            if hrp and mobs then
                local tool, dmgID = getWeapon()
                local target = nil
                for _, m in ipairs(mobs:GetChildren()) do
                    if m.Name == selectedMob and m:FindFirstChildWhichIsA("BasePart") then
                        target = m; break
                    end
                end
                if target then
                    local p = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
                    if p then
                        if tool then pcall(function() remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end) end
                        hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, huntHeight, 0))
                        hrp.Anchored = true
                        VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        if tool and dmgID then
                            pcall(function() remoteEvents.ToolDamageObject:InvokeServer(target, tool, dmgID, CFrame.new(p.Position)) end)
                        end
                        task.wait(0.1)
                        hrp.Anchored = false
                    end
                else
                    if hrp.Anchored then hrp.Anchored = false end
                end
            end
        else
            local hrp = getHRP()
            if hrp and hrp.Anchored then hrp.Anchored = false end
        end
        task.wait(0.1)
    end
end)

AutoTab:Dropdown({
    Title = "Select Mob Target",
    Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"},
    Default = "Wolf",
    Callback = function(v) selectedMob = v end
})

AutoTab:Slider({
    Title = "Fly/Freeze Height",
    Min = 5, Max = 100, Default = 20,
    Callback = function(v) huntHeight = v end
})

AutoTab:Toggle({
    Title = "Auto Hunt Mob (TP + Freeze)",
    Default = false,
    Callback = function(v) autoHuntToggle = v end
})

AutoTab:Section({ Title = "Auto Claim & Feed" })

local autoClaimMeat = false
local autoFeedCampfire = false
local selectedFeeds = {}

local function moveItem(item, pos)
    if not item or not item:IsDescendantOf(workspace) then return end
    pcall(function()
        remoteEvents.RequestStartDraggingItem:FireServer(item)
        local p = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if p then p.CFrame = CFrame.new(pos) end
        remoteEvents.StopDraggingItem:FireServer(item)
    end)
end

AutoTab:Toggle({
    Title = "Auto Claim Meat / Drop Items",
    Default = false,
    Callback = function(v) autoClaimMeat = v end
})

AutoTab:Toggle({
    Title = "Enable Auto Feed Campfire",
    Default = false,
    Callback = function(v) autoFeedCampfire = v end
})

AutoTab:Dropdown({
    Title = "Fuel / Cook Items",
    Values = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat"},
    Multi = true,
    Default = {},
    Callback = function(v) selectedFeeds = v end
})

task.spawn(function()
    while true do
        local hrp = getHRP()
        if autoClaimMeat and hrp then
            for _, item in ipairs(itemFolder:GetChildren()) do
                if item.Name:find("Meat") or item.Name:find("Pelt") or item.Name:find("Foot") then
                    moveItem(item, hrp.Position + Vector3.new(0, 2, 0))
                end
            end
        end
        if autoFeedCampfire then
            local campsite = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campsite")
            local targetPos = campsite and (campsite.PrimaryPart and campsite.PrimaryPart.Position + Vector3.new(6, 3, 6)) or Vector3.new(6, 12, 6)
            for itemName, enabled in pairs(selectedFeeds) do
                if enabled then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item.Name == itemName then moveItem(item, targetPos) end
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- ==========================================
-- 3. ITEM TAB
-- ==========================================
ItemTab:Section({ Title = "Bring Bulk Items" })

local bulkList = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"}
ItemTab:Dropdown({
    Title = "Bring Item to Player",
    Values = bulkList,
    Callback = function(itemName)
        local hrp = getHRP()
        if not hrp then return end
        local count = 0
        for _, item in ipairs(itemFolder:GetChildren()) do
            if item.Name == itemName then
                moveItem(item, hrp.Position + Vector3.new(0, count * 2, 0))
                count = count + 1
            end
        end
    end
})

-- ==========================================
-- 4. GAME TP & PLAYER TAB
-- ==========================================
GameTPTab:Button({
    Title = "Teleport to Campsite",
    Callback = function()
        local hrp = getHRP()
        if hrp then hrp.CFrame = CFrame.new(0, 8, 0) end
    end
})

GameTPTab:Button({
    Title = "Teleport to Safe Zone",
    Callback = function()
        local hrp = getHRP()
        if hrp then hrp.CFrame = CFrame.new(0, 110, 0) end
    end
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Min = 16, Max = 250, Default = 16,
    Callback = function(v)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
    end
})

WindUI:Notify({
    Title = "W424 Hub Ready",
    Content = "Script WindUI berhasil dimuat!",
    Duration = 4
})
