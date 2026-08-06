-- ==========================================
-- LOGIC & BACKEND MODULE (99 NIGHTS) - FIXED
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = workspace:WaitForChild("Items", 10)

local Functions = {}

-- Variables Global Control
_G.KillAura = false
_G.KillAuraRadius = 200

_G.AutoWood = false
_G.AutoWoodRadius = 200

_G.AutoHunt = false
_G.SelectedMob = "Wolf"
_G.HuntHeight = 20

_G.AutoClaim = false
_G.AutoFeed = false
_G.SelectedFeeds = {}

local weapons = {
    ["Spear"] = "196_8999010016", ["Strong Axe"] = "116_8982038982",
    ["Good Axe"] = "112_8982038982", ["Old Axe"] = "1_8982038982",
    ["Chainsaw"] = "647_8992824875"
}

-- Fungsi getHRP Aman (Tanpa Stack Overflow)
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getWeapon()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return nil, nil end
    for wName, dID in pairs(weapons) do
        local t = inv:FindFirstChild(wName)
        if t then return t, dID end
    end
    return nil, nil
end

local function moveItem(item, pos)
    if not item or not item:IsDescendantOf(workspace) or not remoteEvents then return end
    pcall(function()
        remoteEvents.RequestStartDraggingItem:FireServer(item)
        local p = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if p then p.CFrame = CFrame.new(pos) end
        remoteEvents.StopDraggingItem:FireServer(item)
    end)
end

-- 1. LOOP KILL AURA (Safe Wait)
task.spawn(function()
    while true do
        if _G.KillAura then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents then
                    local tool, dmgID = getWeapon()
                    if tool and dmgID then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                        local mobs = workspace:FindFirstChild("Characters")
                        if mobs then
                            for _, mob in ipairs(mobs:GetChildren()) do
                                local p = mob:FindFirstChildWhichIsA("BasePart")
                                if p and (p.Position - hrp.Position).Magnitude <= _G.KillAuraRadius then
                                    remoteEvents.ToolDamageObject:InvokeServer(mob, tool, dmgID, CFrame.new(p.Position))
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- 2. LOOP AUTO WOOD
task.spawn(function()
    while true do
        if _G.AutoWood then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents then
                    local axe, dmgID = getWeapon()
                    if axe and dmgID then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", axe)
                        VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name == "Small Tree") then
                                local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                                if trunk and (trunk.Position - hrp.Position).Magnitude <= _G.AutoWoodRadius then
                                    remoteEvents.ToolDamageObject:InvokeServer(obj, axe, dmgID, CFrame.new(trunk.Position))
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- 3. LOOP AUTO HUNT MOB (TP -> FREEZE -> HIT)
task.spawn(function()
    while true do
        if _G.AutoHunt then
            pcall(function()
                local hrp = getHRP()
                local mobs = workspace:FindFirstChild("Characters")
                if hrp and mobs and remoteEvents then
                    local tool, dmgID = getWeapon()
                    local target = nil
                    for _, m in ipairs(mobs:GetChildren()) do
                        if m.Name == _G.SelectedMob and m:FindFirstChildWhichIsA("BasePart") then
                            target = m; break
                        end
                    end
                    if target then
                        local p = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
                        if p then
                            if tool then remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool) end
                            hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, _G.HuntHeight, 0))
                            hrp.Anchored = true
                            VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                            if tool and dmgID then
                                remoteEvents.ToolDamageObject:InvokeServer(target, tool, dmgID, CFrame.new(p.Position))
                            end
                            task.wait(0.15)
                            hrp.Anchored = false
                        end
                    else
                        if hrp.Anchored then hrp.Anchored = false end
                    end
                end
            end)
        else
            local hrp = getHRP()
            if hrp and hrp.Anchored then hrp.Anchored = false end
        end
        task.wait(0.2)
    end
end)

-- 4. LOOP AUTO CLAIM & FEED
task.spawn(function()
    while true do
        pcall(function()
            local hrp = getHRP()
            if _G.AutoClaim and hrp and itemFolder then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name:find("Meat") or item.Name:find("Pelt") or item.Name:find("Foot") then
                        moveItem(item, hrp.Position + Vector3.new(0, 2, 0))
                    end
                end
            end
            if _G.AutoFeed and itemFolder then
                local campsite = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campsite")
                local targetPos = campsite and (campsite.PrimaryPart and campsite.PrimaryPart.Position + Vector3.new(6, 3, 6)) or Vector3.new(6, 12, 6)
                for itemName, enabled in pairs(_G.SelectedFeeds) do
                    if enabled then
                        for _, item in ipairs(itemFolder:GetChildren()) do
                            if item.Name == itemName then moveItem(item, targetPos) end
                        end
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

function Functions.BringItem(itemName)
    local hrp = getHRP()
    if not hrp or not itemFolder then return end
    local count = 0
    for _, item in ipairs(itemFolder:GetChildren()) do
        if item.Name == itemName then
            moveItem(item, hrp.Position + Vector3.new(0, count * 2, 0))
            count = count + 1
        end
    end
end

return Functions
