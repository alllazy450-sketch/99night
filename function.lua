local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

local Functions = {}

_G.KillAura = false
_G.KillAuraRadius = 200

_G.AutoBringTrees = false
_G.AutoHunt = false
_G.SelectedMob = "Wolf"

_G.AutoClaim = false
_G.AutoFeed = false

local savedBasecampCFrame = nil

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getAnyToolWithDamageID()
    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return nil, nil end
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = inv:FindFirstChild(toolName)
        if tool then return tool, damageID end
    end
    return nil, nil
end

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) or not remoteEvents then return end
    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
    if part then
        pcall(function()
            remoteEvents.RequestStartDraggingItem:FireServer(item)
            part.CFrame = CFrame.new(position)
            remoteEvents.StopDraggingItem:FireServer(item)
        end)
    end
end

-- 1. KILL AURA LOOP
task.spawn(function()
    while true do
        if _G.KillAura then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents and characterFolder then
                    local tool, damageID = getAnyToolWithDamageID()
                    if tool and damageID then
                        remoteEvents.EquipItemHandle:FireServer("FireAllClients", tool)
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob:IsA("Model") then
                                local part = mob:FindFirstChildWhichIsA("BasePart")
                                if part and (part.Position - hrp.Position).Magnitude <= _G.KillAuraRadius then
                                    remoteEvents.ToolDamageObject:InvokeServer(mob, tool, damageID, CFrame.new(part.Position))
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- 2. AUTO BRING ALL SMALL TREES
local originalTreeCFrames = {}

local function getAllSmallTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Small Tree" then
                table.insert(trees, obj)
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if map then
        scan(map:FindFirstChild("Foliage"))
        scan(map:FindFirstChild("Landmarks"))
    end
    return trees
end

local function findTrunk(tree)
    for _, part in ipairs(tree:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "Trunk" then return part end
    end
    return nil
end

task.spawn(function()
    while true do
        if _G.AutoBringTrees then
            local hrp = getHRP()
            if hrp then
                local target = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 10)
                for _, tree in ipairs(getAllSmallTrees()) do
                    local trunk = findTrunk(tree)
                    if trunk then
                        if not originalTreeCFrames[tree] then originalTreeCFrames[tree] = trunk.CFrame end
                        tree.PrimaryPart = trunk
                        trunk.Anchored = false
                        trunk.CanCollide = false
                        tree:SetPrimaryPartCFrame(target + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
                        trunk.Anchored = true
                    end
                end
            end
        else
            if next(originalTreeCFrames) then
                for tree, cframe in pairs(originalTreeCFrames) do
                    local trunk = findTrunk(tree)
                    if trunk then
                        tree.PrimaryPart = trunk
                        tree:SetPrimaryPartCFrame(cframe)
                        trunk.Anchored = true
                        trunk.CanCollide = true
                    end
                end
                originalTreeCFrames = {}
            end
        end
        task.wait(2)
    end
end)

-- 3. AUTO MOB TP + AUTO RETURN TO BASECAMP
task.spawn(function()
    local wasHunting = false
    while true do
        if _G.AutoHunt then
            local hrp = getHRP()
            if hrp then
                if not wasHunting then
                    savedBasecampCFrame = hrp.CFrame
                    wasHunting = true
                end

                pcall(function()
                    if characterFolder then
                        local count = 0
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob.Name == _G.SelectedMob then
                                local mainPart = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                if mainPart then
                                    local targetCFrame = hrp.CFrame + Vector3.new(0, count * 3, 0)
                                    if mob.PrimaryPart then
                                        mob:SetPrimaryPartCFrame(targetCFrame)
                                    else
                                        mainPart.CFrame = targetCFrame
                                    end
                                    count = count + 1
                                end
                            end
                        end
                    end
                end)
            end
        else
            if wasHunting then
                local hrp = getHRP()
                if hrp and savedBasecampCFrame then
                    hrp.CFrame = savedBasecampCFrame
                end
                wasHunting = false
                savedBasecampCFrame = nil
            end
        end
        task.wait(0.5)
    end
end)

-- 4. AUTO CLAIM & AUTO FEED CAMPFIRE
task.spawn(function()
    while true do
        pcall(function()
            local hrp = getHRP()
            if _G.AutoClaim and hrp and itemFolder then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name:find("Meat") or item.Name:find("Pelt") or item.Name == "Bunny Foot" or item.Name == "Log" then
                        moveItemToPos(item, hrp.Position + Vector3.new(0, 2, 0))
                    end
                end
            end
            if _G.AutoFeed and itemFolder then
                local campfireDropPos = Vector3.new(0, 19, 0)
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item.Name == "Log" or item.Name == "Coal" or item.Name == "Biofuel" then
                        moveItemToPos(item, campfireDropPos)
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
            moveItemToPos(item, hrp.Position + Vector3.new(0, count * 2, 0))
            count = count + 1
        end
    end
end

return Functions
