-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FLUENT UI EDITION (ANTI-ERROR & STABLE)
-- ==========================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- FLAG PENGUNCI
local UIReady = false

-- State Variables
local AutoTapEnabled = false
local TapInterval = 0.2

local AutoWoodEnabled = false
local AutoCarrotEnabled = false
local SelectedTreeType = "All Trees"
local SelectedAxeName = "Old Axe"

local KillAuraEnabled = false
local KillAuraRadius = 500

local AutoClaimEnabled = false 
local AutoFeedEnabled = false
local AutoCookEnabled = false
local SelectedFeedMaterials = {["Log"] = true}

local BulkTPEnabled = false
local SelectedBulkItem = "Log"
local TPDestination = "To Player"

local SavedWoodBasecampCFrame = nil
local WasWoodFarming = false

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- Utility Functions
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:IsDescendantOf(Workspace) and char:FindFirstChild("HumanoidRootPart")
end

-- ==========================================
-- AUTO EQUIP & SWING SYSTEM
-- ==========================================
local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name == toolName or child.Name:lower():find(toolName:lower())) then
            return child
        end
    end

    local inv = LocalPlayer:FindFirstChild("Inventory")
    if not inv then return char:FindFirstChildOfClass("Tool") end

    local tool = inv:FindFirstChild(toolName)
    if not tool then
        for _, item in ipairs(inv:GetChildren()) do
            if item.Name:lower():find(toolName:lower()) then
                tool = item
                break
            end
        end
    end

    if tool and remoteEvents then
        local equipRemote = remoteEvents:FindFirstChild("EquipItemHandle") or remoteEvents:FindFirstChild("EquipItem")
        if equipRemote then
            pcall(function() equipRemote:FireServer(tool) end)
            task.wait(0.25)
            return char:FindFirstChildOfClass("Tool")
        end
    end

    return char:FindFirstChildOfClass("Tool")
end

local function triggerPhysicalSwing(treeTarget)
    local tool = ensureToolEquipped(SelectedAxeName)
    if not tool then return end

    pcall(function() tool:Activate() end)

    local swingRemote = tool:FindFirstChild("Swing") or tool:FindFirstChild("Attack")
    if swingRemote and swingRemote:IsA("RemoteEvent") then
        pcall(function() swingRemote:FireServer() end)
    end

    if treeTarget and remoteEvents then
        local damageID = toolsDamageIDs[SelectedAxeName] or "1_8982038982"
        local mainPart = treeTarget:FindFirstChild("Trunk") or treeTarget.PrimaryPart or treeTarget:FindFirstChildWhichIsA("BasePart")
        if mainPart then
            local damageRemote = remoteEvents:FindFirstChild("ToolDamageObject")
            if damageRemote then
                pcall(function()
                    damageRemote:InvokeServer(treeTarget, tool, damageID, CFrame.new(mainPart.Position))
                end)
            end
        end
    end
end

-- ==========================================
-- ITEM MOVER & CLAIM
-- ==========================================
local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    if map then
        local campground = map:FindFirstChild("Campground") or map:FindFirstChild("Campsite")
        if campground then
            local mainFire = campground:FindFirstChild("MainFire") or campground:FindFirstChild("Campfire") or campground.PrimaryPart
            if mainFire then
                local part = mainFire:IsA("BasePart") and mainFire or mainFire:FindFirstChildWhichIsA("BasePart")
                if part then return part.Position + Vector3.new(0, 3, 0) end
            end
        end
    end
    return Vector3.new(0, 19, 0)
end

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        if item:IsA("Model") then item:PivotTo(CFrame.new(position)) end
        for _, part in ipairs(item:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = CFrame.new(position)
                part.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function isClaimableItem(item)
    if not item or not item.Name then return false end
    local name = item.Name:lower()
    return name:find("log") or name:find("wood") or name:find("meat") 
        or name:find("pelt") or name:find("foot") or name:find("steak") 
        or name:find("morsel") or name:find("sheet") or name:find("bolt") 
        or name:find("coal") or name:find("fuel") or name:find("scrap") or name:find("carrot")
end

-- ==========================================
-- LOOPS
-- ==========================================
if itemFolder then
    itemFolder.ChildAdded:Connect(function(child)
        if UIReady and AutoClaimEnabled then
            task.wait(0.2)
            if child and child:IsDescendantOf(Workspace) and isClaimableItem(child) then
                local hrp = getHRP()
                if hrp then moveItemToPos(child, hrp.Position + Vector3.new(math.random(-1,1), 1, math.random(-1,1))) end
            end
        end
    end)
end

task.spawn(function()
    while true do
        if UIReady and AutoClaimEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp and itemFolder then
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if isClaimableItem(item) and item:IsDescendantOf(Workspace) then
                            moveItemToPos(item, hrp.Position + Vector3.new(math.random(-1,1), 1, math.random(-1,1)))
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if UIReady then
            pcall(function()
                if (AutoCookEnabled or AutoFeedEnabled) and itemFolder then
                    local firePos = getCampfirePosition()
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsDescendantOf(Workspace) then
                            local name = item.Name
                            if AutoCookEnabled and name:lower():find("meat") and not name:lower():find("cooked") then
                                moveItemToPos(item, firePos)
                            end
                            if AutoFeedEnabled and SelectedFeedMaterials[name] then
                                moveItemToPos(item, firePos)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

local function getTreeMainPart(tree)
    if not tree or not tree:IsDescendantOf(Workspace) then return nil end
    local part = tree:FindFirstChild("Trunk") or tree:FindFirstChild("Trunk1") or tree:FindFirstChild("MainPart")
        or tree:FindFirstChild("Head") or tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
    if part and part:IsA("BasePart") and part:IsDescendantOf(Workspace) then return part end
    return nil
end

local function getFilteredTrees()
    local trees = {}
    local function scan(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:IsDescendantOf(Workspace) then
                local name = obj.Name
                local match = false
                if SelectedTreeType == "All Trees" then
                    if name:find("Tree") or name:find("Brightwood") or name:find("Fairy") or name:find("Suci") then match = true end
                elseif SelectedTreeType == "Small Trees" and name == "Small Tree" then match = true
                elseif SelectedTreeType == "Hard Trees" and (name:find("Hard") or name:find("Medium") or name == "Tree") then match = true
                elseif SelectedTreeType == "Brightwood Trees" and name:find("Brightwood") then match = true
                elseif SelectedTreeType == "Fairy Trees" and (name:find("Fairy") or name:find("Suci")) then match = true
                end
                if match and getTreeMainPart(obj) then table.insert(trees, obj) end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if map then
        local possibleFolders = {"Foliage", "Landmarks", "Trees", "Environment", "Resources"}
        for _, folderName in ipairs(possibleFolders) do
            local folder = map:FindFirstChild(folderName)
            if folder then scan(folder) end
        end
        scan(map)
    end
    return trees
end

task.spawn(function()
    while true do
        if UIReady and AutoTapEnabled then triggerPhysicalSwing(nil) end
        task.wait(TapInterval)
    end
end)

task.spawn(function()
    while true do
        if UIReady and AutoWoodEnabled then
            local hrp = getHRP()
            if hrp then
                if not WasWoodFarming then
                    SavedWoodBasecampCFrame = hrp.CFrame
                    WasWoodFarming = true
                end

                local treeList = getFilteredTrees()
                for _, tree in ipairs(treeList) do
                    if not AutoWoodEnabled then break end
                    if not tree:IsDescendantOf(Workspace) then continue end
                    
                    local mainPart = getTreeMainPart(tree)
                    if not mainPart then continue end
                    
                    hrp.CFrame = CFrame.new(mainPart.Position + Vector3.new(2, 0, 2), mainPart.Position)
                    task.wait(0.2)

                    local maxHits = 25
                    local hitCount = 0
                    while AutoWoodEnabled and tree:IsDescendantOf(Workspace) and getTreeMainPart(tree) and hitCount < maxHits do
                        triggerPhysicalSwing(tree)
                        task.wait(0.25)
                        hitCount = hitCount + 1
                    end
                    task.wait(0.3)
                end
            end
        else
            if WasWoodFarming then
                local hrp = getHRP()
                if hrp and SavedWoodBasecampCFrame then hrp.CFrame = SavedWoodBasecampCFrame end
                WasWoodFarming = false
                SavedWoodBasecampCFrame = nil
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if UIReady and AutoCarrotEnabled then
            local hrp = getHRP()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not AutoCarrotEnabled then break end
                if obj:IsA("Model") and (obj.Name:lower():find("carrot")) then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and hrp then
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(1.5, 0, 1.5), part.Position)
                        triggerPhysicalSwing(obj)
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if UIReady and BulkTPEnabled then
            pcall(function()
                local hrp = getHRP()
                if itemFolder then
                    local targetPos = (TPDestination == "To Player" and hrp) and (hrp.Position + Vector3.new(0, 2, 0)) or getCampfirePosition()
                    local count = 0
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsDescendantOf(Workspace) and item.Name:lower():find(SelectedBulkItem:lower()) then
                            moveItemToPos(item, targetPos + Vector3.new(math.random(-1,1), count * 0.5, math.random(-1,1)))
                            count = count + 1
                            if count >= 8 then break end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- FLUENT UI INTERFACE
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "99 Nights in the Forest",
    SubTitle = "W424 Hub | Fluent Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Auto = Window:AddTab({ Title = "Auto Farm", Icon = "axe" }),
    Item = Window:AddTab({ Title = "Item TP", Icon = "box" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" })
}

Tabs.Main:AddToggle("AutoTap", { Title = "Auto Click / Tap Swing", Default = false }):OnChanged(function(v)
    if UIReady then AutoTapEnabled = v end
end)

Tabs.Auto:AddDropdown("SelectAxe", {
    Title = "Select Axe / Tool",
    Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw"},
    Default = "Old Axe",
    Callback = function(v) if UIReady then SelectedAxeName = v end end
})

Tabs.Auto:AddDropdown("SelectTree", {
    Title = "Target Tree Type",
    Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"},
    Default = "All Trees",
    Callback = function(v) if UIReady then SelectedTreeType = v end end
})

Tabs.Auto:AddToggle("AutoWood", { Title = "Auto Farm Wood (TP & Cut)", Default = false }):OnChanged(function(v)
    if UIReady then AutoWoodEnabled = v end
end)

Tabs.Auto:AddToggle("AutoCarrot", { Title = "Auto Farm Carrots", Default = false }):OnChanged(function(v)
    if UIReady then AutoCarrotEnabled = v end
end)

Tabs.Auto:AddToggle("AutoClaim", { Title = "Realtime Auto Claim Items", Default = false }):OnChanged(function(v)
    if UIReady then AutoClaimEnabled = v end
end)

Tabs.Auto:AddToggle("AutoCook", { Title = "Auto Cook Meat", Default = false }):OnChanged(function(v)
    if UIReady then AutoCookEnabled = v end
end)

Tabs.Auto:AddToggle("AutoFeed", { Title = "Auto Feed Campfire", Default = false }):OnChanged(function(v)
    if UIReady then AutoFeedEnabled = v end
end)

Tabs.Auto:AddDropdown("FeedItem", {
    Title = "Campfire Feed Item",
    Values = {"Log", "Coal", "Biofuel", "Fuel Canister"},
    Default = "Log",
    Callback = function(v) if UIReady then SelectedFeedMaterials = {[v] = true} end end
})

Tabs.Item:AddToggle("BulkTP", { Title = "Auto Bring Selected Item", Default = false }):OnChanged(function(v)
    if UIReady then BulkTPEnabled = v end
end)

Tabs.Item:AddDropdown("ItemName", {
    Title = "Item Name",
    Values = {"Log", "Coal", "Biofuel", "Meat", "Bunny Foot", "Pelt", "Sheet Metal", "Bolt"},
    Default = "Log",
    Callback = function(v) if UIReady then SelectedBulkItem = v end end
})

Tabs.Item:AddDropdown("TPDest", {
    Title = "Teleport Destination",
    Values = {"To Player", "To Campfire"},
    Default = "To Player",
    Callback = function(v) if UIReady then TPDestination = v end end
})

Tabs.Player:AddInput("WalkSpeedInput", {
    Title = "WalkSpeed",
    Default = "16",
    Placeholder = "Ketik Kecepatan",
    Numeric = true,
    Callback = function(v)
        if UIReady then
            local num = tonumber(v)
            local char = LocalPlayer and LocalPlayer.Character
            if num and char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = num end
        end
    end
})

UIReady = true

Fluent:Notify({
    Title = "Fluent UI Loaded",
    Content = "Script siap digunakan tanpa error!",
    Duration = 5
})
