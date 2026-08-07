-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- FIX ITEM TP & REALTIME AUTO CLAIM
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:WaitForChild("Characters", 10)

-- State Variables
local AutoTapEnabled = false
local TapInterval = 0.15

local AutoWoodEnabled = false
local SelectedTreeType = "All Trees"

local BulkTPEnabled = false
local SelectedBulkItem = "Log"
local TPDestination = "To Player"

local AutoClaimEnabled = false
local AutoFeedEnabled = false
local SelectedFeedMaterials = {["Log"] = true, ["Coal"] = true, ["Biofuel"] = true}

local SavedWoodBasecampCFrame = nil
local WasWoodFarming = false

-- Utility Functions
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHeldTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

-- ==========================================
-- PHYSICAL SWING / TRIGGER FUNCTION
-- ==========================================
local function triggerPhysicalSwing()
    local tool = getHeldTool()
    if not tool then return end

    pcall(function() tool:Activate() end)

    local swingRemote = tool:FindFirstChild("Swing") or tool:FindFirstChild("Attack")
    if swingRemote and swingRemote:IsA("RemoteEvent") then
        pcall(function() swingRemote:FireServer() end)
    end

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

-- ==========================================
-- DIRECT ITEM TP ENGINE (PHYSICS + REMOTE)
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
        -- Panggil Remote jika ada
        if remoteEvents then 
            pcall(function() remoteEvents.RequestStartDraggingItem:FireServer(item) end)
        end
        
        -- Direct CFrame Move ke semua Part dalam Model Item
        if item:IsA("Model") then
            item:PivotTo(CFrame.new(position))
        end
        
        for _, part in ipairs(item:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = CFrame.new(position)
                part.Velocity = Vector3.new(0, 0, 0)
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end

        if remoteEvents then 
            pcall(function() remoteEvents.StopDraggingItem:FireServer(item) end)
        end
    end)
end

-- Universal Name Checker untuk Item Drop (Daging, Kayu, Scrap, dll)
local function isClaimableItem(item)
    if not item or not item.Name then return false end
    local name = item.Name:lower()
    
    return name:find("log") or name:find("wood") or name:find("meat") 
        or name:find("pelt") or name:find("foot") or name:find("steak") 
        or name:find("morsel") or name:find("sheet") or name:find("bolt") 
        or name:find("coal") or name:find("fuel") or name:find("scrap")
end

-- ==========================================
-- REALTIME CLAIM & ITEM LOOPS
-- ==========================================

-- 1. Realtime Listener Item Baru Spawn
if itemFolder then
    itemFolder.ChildAdded:Connect(function(child)
        if AutoClaimEnabled then
            task.wait(0.1) -- Jeda singkat agar part ter-instance sempurna di client
            if child and child:IsDescendantOf(Workspace) and isClaimableItem(child) then
                local hrp = getHRP()
                if hrp then 
                    moveItemToPos(child, hrp.Position + Vector3.new(math.random(-1,1), 1, math.random(-1,1))) 
                end
            end
        end
    end)
end

-- 2. Continuous Sweep Loop (Mengambil item yang tercecer di tanah)
task.spawn(function()
    while true do
        if AutoClaimEnabled then
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
        task.wait(0.5)
    end
end)

-- 3. Bulk Item Teleport (Item Spesifik)
task.spawn(function()
    while true do
        if BulkTPEnabled then
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

-- 4. Auto Feed Campfire
task.spawn(function()
    while true do
        if AutoFeedEnabled then
            pcall(function()
                if itemFolder then
                    local dropPos = getCampfirePosition()
                    local count = 0
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item:IsDescendantOf(Workspace) and SelectedFeedMaterials[item.Name] then
                            moveItemToPos(item, dropPos + Vector3.new(math.random(-0.5,0.5), count * 0.5, math.random(-0.5,0.5)))
                            count = count + 1
                            if count >= 3 then break end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ==========================================
-- AUTO WOOD & SWING LOOPS
-- ==========================================
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
        if AutoTapEnabled then
            triggerPhysicalSwing()
        end
        task.wait(TapInterval)
    end
end)

task.spawn(function()
    while true do
        if AutoWoodEnabled then
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
                    
                    hrp.CFrame = CFrame.new(mainPart.Position + Vector3.new(1.8, 0, 1.8), mainPart.Position)
                    task.wait(0.2)

                    local maxHits = 30
                    local hitCount = 0
                    while AutoWoodEnabled and tree:IsDescendantOf(Workspace) and getTreeMainPart(tree) and hitCount < maxHits do
                        triggerPhysicalSwing()
                        task.wait(0.2)
                        hitCount = hitCount + 1
                    end
                    task.wait(0.3)
                end
            end
        else
            if WasWoodFarming then
                local hrp = getHRP()
                if hrp and SavedWoodBasecampCFrame then
                    hrp.CFrame = SavedWoodBasecampCFrame
                end
                WasWoodFarming = false
                SavedWoodBasecampCFrame = nil
            end
        end
        task.wait(1)
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Fixed Item TP & Realtime Claim",
    Author = "alllazy450-sketch",
    Folder = "W424Hub",
    Size = UDim2.fromOffset(580, 420),
    Transparent = true,
    Theme = "Dark"
})

local MainTab   = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389" })
local AutoTab   = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://10734950309" })
local ItemTab   = Window:Tab({ Title = "Item TP", Icon = "rbxassetid://10723345380" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "rbxassetid://10747373176" })

MainTab:Section({ Title = "Auto Tap / Swing Trigger" })
MainTab:Toggle({ Title = "Auto Click / Tap Swing (Held Tool)", Default = false, Callback = function(v) AutoTapEnabled = v end })
MainTab:Input({ Title = "Tap Speed Interval (Detik)", Value = "0.15", Placeholder = "Ketik Detik", Callback = function(v) local num = tonumber(v) if num then TapInterval = num end end })

AutoTab:Section({ Title = "Wood Farming Settings" })
AutoTab:Dropdown({ Title = "Target Tree Type", Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"}, Default = "All Trees", Callback = function(v) SelectedTreeType = v end })
AutoTab:Toggle({ Title = "Auto Farm Wood (TP + Tap Swing)", Default = false, Callback = function(v) AutoWoodEnabled = v end })

AutoTab:Section({ Title = "Campfire & Item Settings" })
AutoTab:Toggle({ Title = "Realtime Auto Claim Items", Default = false, Callback = function(v) AutoClaimEnabled = v end })
AutoTab:Toggle({ Title = "Auto Feed Campfire", Default = false, Callback = function(v) AutoFeedEnabled = v end })

ItemTab:Section({ Title = "Item Teleport Toggle" })
ItemTab:Toggle({ Title = "Auto Bring Selected Item", Default = false, Callback = function(v) BulkTPEnabled = v end })
ItemTab:Dropdown({ Title = "Item Name", Values = {"Log", "Coal", "Biofuel", "Meat", "Bunny Foot", "Pelt", "Sheet Metal", "Bolt"}, Default = "Log", Callback = function(v) SelectedBulkItem = v end })
ItemTab:Dropdown({ Title = "Teleport Destination", Values = {"To Player", "To Campfire"}, Default = "To Player", Callback = function(v) TPDestination = v end })

PlayerTab:Input({ Title = "WalkSpeed", Value = "16", Placeholder = "Ketik Kecepatan", Callback = function(v)
    local num = tonumber(v)
    local char = LocalPlayer and LocalPlayer.Character
    if num and char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = num end
end })

WindUI:Notify({ Title = "System Fix Updated", Content = "Daging kelinci & Kayu hasil tebang sekarang ter-claim sempurna!", Duration = 5 })
