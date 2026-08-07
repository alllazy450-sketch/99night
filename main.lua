-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE STABLE & ROBUST ENGINE (FIXED)
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
local KillAuraEnabled = false
local KillAuraRadius = 500

local AutoWoodEnabled = false
local SelectedTreeType = "All Trees"
local SelectedAxeName = "Old Axe"

local AutoHuntEnabled = false
local SelectedMob = "Wolf"

local BulkTPEnabled = false
local SelectedBulkItem = "Log"
local TPDestination = "To Player"

local AutoClaimEnabled = false
local AutoFeedEnabled = false
local SelectedFeedMaterials = {["Log"] = true, ["Coal"] = true, ["Biofuel"] = true, ["Fuel Canister"] = true}

local SavedWoodBasecampCFrame = nil
local SavedMobBasecampCFrame = nil
local WasWoodFarming = false
local WasHunting = false
local equippedTool = nil

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
    if char and char:IsDescendantOf(Workspace) then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ==========================================
-- EQUIP TOOL (ROBUST & SMART CHECK)
-- ==========================================
local function ensureToolEquipped(toolName)
    local char = LocalPlayer.Character
    if not char then return nil end

    -- 1. UTAMA: Cek jika tool SUDAH DIPEGANG di Character
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then
            if child.Name == toolName or child.Name:lower():find(toolName:lower()) then
                equippedTool = child
                return child
            end
        end
    end

    -- 2. Cek jika karakter sedang memegang sembarang Tool (fallback cepat)
    local heldTool = char:FindFirstChildOfClass("Tool")
    if heldTool and (heldTool.Name:lower():find("axe") or heldTool.Name:lower():find("saw")) then
        equippedTool = heldTool
        return heldTool
    end

    -- 3. Cari di Inventory jika belum di tangan
    local inv = LocalPlayer:FindFirstChild("Inventory")
    local tool = nil
    if inv then
        tool = inv:FindFirstChild(toolName)
        if not tool then
            for _, item in ipairs(inv:GetChildren()) do
                if item.Name:lower():find(toolName:lower()) then
                    tool = item
                    break
                end
            end
        end
    end

    -- Jika tidak ada di inventory & tidak di tangan, kembalikan Tool yang sedang dipegang (jika ada)
    if not tool then
        return heldTool
    end

    -- 4. Kirim Remote Equip jika item terdeteksi di Inventory
    if remoteEvents then
        local equipRemote = remoteEvents:FindFirstChild("EquipItemHandle") or remoteEvents:FindFirstChild("EquipItem")
        if equipRemote then
            pcall(function() equipRemote:FireServer(tool) end)
            task.wait(0.2)
            
            local newTool = char:FindFirstChildOfClass("Tool")
            if newTool then
                equippedTool = newTool
                return newTool
            end
        end
    end

    return char:FindFirstChildOfClass("Tool")
end

-- ==========================================
-- SERANG TARGET (ATTACK ENGINE)
-- ==========================================
local function attackTarget(target, tool, damageID)
    if not target or not tool then return false end
    local mainPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") 
        or target:FindFirstChild("Trunk") or target:FindFirstChild("MainPart") 
        or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not mainPart then return false end

    local success = false
    pcall(function() tool:Activate() success = true end)

    local swing = tool:FindFirstChild("Swing")
    if swing then pcall(function() swing:FireServer() success = true end) end

    if remoteEvents then
        local damageRemote = remoteEvents:FindFirstChild("ToolDamageObject")
        if damageRemote then
            pcall(function() damageRemote:InvokeServer(target, tool, damageID, CFrame.new(mainPart.Position)) success = true end)
        end
        local hitRemote = remoteEvents:FindFirstChild("Hit") or remoteEvents:FindFirstChild("DealDamage")
        if hitRemote then pcall(function() hitRemote:FireServer(target, tool) success = true end) end
    end

    local damageEvent = tool:FindFirstChild("DamageEvent") or tool:FindFirstChild("OnAttack")
    if damageEvent then pcall(function() damageEvent:FireServer(target) success = true end) end

    return success
end

-- ==========================================
-- CAMPFIRE & ITEM MOVER
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
        if remoteEvents then remoteEvents.RequestStartDraggingItem:FireServer(item) end
        task.wait(0.05)
        local targetPart = item.PrimaryPart or item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
        if targetPart and targetPart:IsDescendantOf(Workspace) then
            targetPart.CFrame = CFrame.new(position)
            targetPart.Velocity = Vector3.new(0, 0, 0)
        end
        if remoteEvents then remoteEvents.StopDraggingItem:FireServer(item) end
    end)
end

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

    if #trees == 0 then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Tree") or obj.Name:find("Brightwood") or obj.Name:find("Fairy")) then
                if getTreeMainPart(obj) then table.insert(trees, obj) end
            end
        end
    end
    return trees
end

-- ==========================================
-- AUTO CLAIM & REALTIME EVENTS
-- ==========================================
local function isClaimableItem(item)
    if not item or not item.Name then return false end
    local name = item.Name
    return name:find("Meat") or name:find("Pelt") or name == "Bunny Foot" or name == "Log" or name:find("Steak") or name:find("Morsel") or name == "Sheet Metal" or name == "Bolt"
end

itemFolder.ChildAdded:Connect(function(child)
    if AutoClaimEnabled then
        task.wait(0.3)
        if child and child:IsDescendantOf(Workspace) and isClaimableItem(child) then
            local hrp = getHRP()
            if hrp then moveItemToPos(child, hrp.Position + Vector3.new(0, 2, 0)) end
        end
    end
end)

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================

-- Kill Aura
task.spawn(function()
    while true do
        if KillAuraEnabled then
            pcall(function()
                local hrp = getHRP()
                if hrp and remoteEvents and characterFolder then
                    local tool = ensureToolEquipped(SelectedAxeName)
                    local damageID = toolsDamageIDs[SelectedAxeName] or "1_8982038982"
                    if tool then
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob:IsA("Model") and mob:IsDescendantOf(Workspace) then
                                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                if part and part:IsDescendantOf(Workspace) and (part.Position - hrp.Position).Magnitude <= KillAuraRadius then
                                    attackTarget(mob, tool, damageID)
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.15)
    end
end)

-- Auto Wood
task.spawn(function()
    while true do
        if AutoWoodEnabled then
            local hrp = getHRP()
            if hrp then
                if not WasWoodFarming then
                    SavedWoodBasecampCFrame = hrp.CFrame
                    WasWoodFarming = true
                end

                local tool = ensureToolEquipped(SelectedAxeName)
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
                    local damageID = toolsDamageIDs[SelectedAxeName] or "1_8982038982"
                    while AutoWoodEnabled and tree:IsDescendantOf(Workspace) and getTreeMainPart(tree) and hitCount < maxHits do
                        local currentTool = ensureToolEquipped(SelectedAxeName)
                        if currentTool then
                            attackTarget(tree, currentTool, damageID)
                        end
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
                equippedTool = nil
            end
        end
        task.wait(1)
    end
end)

-- Auto Hunt
task.spawn(function()
    while true do
        if AutoHuntEnabled then
            local hrp = getHRP()
            if hrp then
                if not WasHunting then
                    SavedMobBasecampCFrame = hrp.CFrame
                    WasHunting = true
                end
                pcall(function()
                    local tool = ensureToolEquipped(SelectedAxeName)
                    local damageID = toolsDamageIDs[SelectedAxeName] or "1_8982038982"
                    if tool and characterFolder then
                        for _, mob in ipairs(characterFolder:GetChildren()) do
                            if mob:IsA("Model") and mob.Name == SelectedMob and mob:IsDescendantOf(Workspace) then
                                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                                if part and part:IsDescendantOf(Workspace) then
                                    attackTarget(mob, tool, damageID)
                                end
                            end
                        end
                    end
                end)
            end
            task.wait(0.4)
        else
            if WasHunting then
                local hrp = getHRP()
                if hrp and SavedMobBasecampCFrame then
                    hrp.CFrame = SavedMobBasecampCFrame
                end
                WasHunting = false
                SavedMobBasecampCFrame = nil
                equippedTool = nil
            end
            task.wait(1)
        end
    end
end)

-- Bulk TP & Auto Feed
task.spawn(function()
    while true do
        if BulkTPEnabled then
            pcall(function()
                local hrp = getHRP()
                if itemFolder then
                    local targetPos = (TPDestination == "To Player" and hrp) and (hrp.Position + Vector3.new(0, 2, 0)) or getCampfirePosition()
                    local count = 0
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if item.Name == SelectedBulkItem and item:IsDescendantOf(Workspace) then
                            moveItemToPos(item, targetPos + Vector3.new(math.random(-1,1), count * 0.5, math.random(-1,1)))
                            count = count + 1
                            if count >= 5 then break end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if AutoFeedEnabled then
            pcall(function()
                if itemFolder then
                    local dropPos = getCampfirePosition()
                    local count = 0
                    for _, item in ipairs(itemFolder:GetChildren()) do
                        if SelectedFeedMaterials[item.Name] and item:IsDescendantOf(Workspace) then
                            moveItemToPos(item, dropPos + Vector3.new(math.random(-0.5,0.5), count * 0.5, math.random(-0.5,0.5)))
                            count = count + 1
                            if count >= 3 then break end
                        end
                    end
                end
            end)
        end
        task.wait(2.5)
    end
end)

-- Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    WasWoodFarming = false
    WasHunting = false
    SavedWoodBasecampCFrame = nil
    SavedMobBasecampCFrame = nil
    equippedTool = nil
    if WindUI then
        WindUI:Notify({ Title = "Respawn", Content = "State direset.", Duration = 3 })
    end
end)

-- ==========================================
-- WIND UI INTERFACE
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "99 Nights in the Forest",
    Subtitle = "W424 Hub | Ultimate Fixed",
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

MainTab:Section({ Title = "Combat System" })
MainTab:Toggle({ Title = "Kill Aura (All Mobs)", Default = false, Callback = function(v) KillAuraEnabled = v end })
MainTab:Input({ Title = "Kill Aura Range (Studs)", Value = "500", Placeholder = "Ketik Range", Callback = function(v) local num = tonumber(v) if num then KillAuraRadius = num end end })

AutoTab:Section({ Title = "Wood & Mob Farming" })
AutoTab:Dropdown({ Title = "Select Axe / Tool", Values = {"Old Axe", "Good Axe", "Strong Axe", "Chainsaw"}, Default = "Old Axe", Callback = function(v) SelectedAxeName = v end })
AutoTab:Dropdown({ Title = "Target Tree Type", Values = {"All Trees", "Small Trees", "Hard Trees", "Brightwood Trees", "Fairy Trees"}, Default = "All Trees", Callback = function(v) SelectedTreeType = v end })
AutoTab:Toggle({ Title = "Auto Farm Wood (TP & Cut)", Default = false, Callback = function(v) AutoWoodEnabled = v end })
AutoTab:Toggle({ Title = "Auto Hunt Mob", Default = false, Callback = function(v) AutoHuntEnabled = v end })
AutoTab:Dropdown({ Title = "Target Mob", Values = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist"}, Default = "Wolf", Callback = function(v) SelectedMob = v end })

AutoTab:Section({ Title = "Campfire & Claim Settings" })
AutoTab:Toggle({ Title = "Realtime Auto Claim Items", Default = false, Callback = function(v) AutoClaimEnabled = v end })
AutoTab:Toggle({ Title = "Auto Feed Campfire", Default = false, Callback = function(v) AutoFeedEnabled = v end })
AutoTab:Dropdown({ Title = "Campfire Feed Item", Values = {"Log", "Coal", "Biofuel", "Fuel Canister"}, Default = "Log", Callback = function(v) SelectedFeedMaterials = {[v] = true} end })

ItemTab:Section({ Title = "Item Teleport Toggle" })
ItemTab:Toggle({ Title = "Auto Bring Selected Item", Default = false, Callback = function(v) BulkTPEnabled = v end })
ItemTab:Dropdown({ Title = "Item Name", Values = {"Log", "Coal", "Biofuel", "Bunny Meat", "Wolf Meat", "Bear Meat", "Sheet Metal", "Bolt"}, Default = "Log", Callback = function(v) SelectedBulkItem = v end })
ItemTab:Dropdown({ Title = "Teleport Destination", Values = {"To Player", "To Campfire"}, Default = "To Player", Callback = function(v) TPDestination = v end })

PlayerTab:Input({ Title = "WalkSpeed", Value = "16", Placeholder = "Ketik Kecepatan", Callback = function(v)
    local num = tonumber(v)
    local char = LocalPlayer and LocalPlayer.Character
    if num and char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = num end
end })

WindUI:Notify({ Title = "Script Updated", Content = "Tool Equip Fixed & Stabil!", Duration = 5 })
