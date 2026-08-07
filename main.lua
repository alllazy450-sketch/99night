-- ==========================================
-- W424 HUB | 99 NIGHTS IN THE FOREST
-- ULTIMATE EDITION: AUTO COOK, CARROTS & FEED
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local itemFolder = Workspace:WaitForChild("Items", 10)
local characterFolder = Workspace:GetService("Workspace"):FindFirstChild("Characters")

-- State Variables
local AutoTapEnabled = false
local TapInterval = 0.2

local AutoWoodEnabled = false
local AutoCarrotEnabled = false
local SelectedTreeType = "All Trees"
local SelectedAxeName = "Old Axe"

local AutoClaimEnabled = true
local AutoFeedEnabled = false
local AutoCookEnabled = false
local SelectedFeedMaterials = {["Log"] = true}

local BulkTPEnabled = false
local SelectedBulkItem = "Log"
local TPDestination = "To Player"

-- Utility Functions
local function getHRP()
    local char = LocalPlayer and LocalPlayer.Character
    return char and char:IsDescendantOf(Workspace) and char:FindFirstChild("HumanoidRootPart")
end

local function getHeldTool()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Tool")
end

-- ==========================================
-- ENGINE CORE
-- ==========================================
local function triggerPhysicalSwing(target)
    local tool = getHeldTool()
    if not tool then return end
    pcall(function() tool:Activate() end)
    local swing = tool:FindFirstChild("Swing") or tool:FindFirstChild("Attack")
    if swing then pcall(function() swing:FireServer() end) end
end

local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(Workspace) then return end
    pcall(function()
        if remoteEvents then pcall(function() remoteEvents.RequestStartDraggingItem:FireServer(item) end) end
        if item:IsA("Model") then item:PivotTo(CFrame.new(position)) end
        for _, p in ipairs(item:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = CFrame.new(position) end end
        if remoteEvents then pcall(function() remoteEvents.StopDraggingItem:FireServer(item) end) end
    end)
end

local function getCampfirePosition()
    local map = Workspace:FindFirstChild("Map")
    local fire = map and (map:FindFirstChild("Campground", true) or map:FindFirstChild("Campsite", true))
    if fire then return fire:GetPivot().Position + Vector3.new(0, 3, 0) end
    return Vector3.new(0, 19, 0)
end

-- ==========================================
-- AUTO FARM LOOPS
-- ==========================================

-- Auto Farm Carrots
task.spawn(function()
    while true do
        if AutoCarrotEnabled then
            local hrp = getHRP()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not AutoCarrotEnabled then break end
                if obj:IsA("Model") and (obj.Name:lower():find("carrot")) then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and hrp then
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(1.5,0,1.5), part.Position)
                        triggerPhysicalSwing(obj)
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Cook & Auto Feed
task.spawn(function()
    while true do
        pcall(function()
            if AutoCookEnabled or AutoFeedEnabled then
                local firePos = getCampfirePosition()
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsDescendantOf(Workspace) then
                        local name = item.Name
                        -- Auto Cook Daging
                        if AutoCookEnabled and name:lower():find("meat") and not name:lower():find("cooked") then
                            moveItemToPos(item, firePos)
                        end
                        -- Auto Feed
                        if AutoFeedEnabled and SelectedFeedMaterials[name] then
                            moveItemToPos(item, firePos)
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

-- Auto Wood (Sama seperti sebelumnya)
task.spawn(function()
    while true do
        if AutoWoodEnabled then
            local hrp = getHRP()
            if hrp then
                for _, tree in ipairs(Workspace:GetDescendants()) do
                    if not AutoWoodEnabled then break end
                    if tree:IsA("Model") and (tree.Name:find("Tree") or tree.Name:find("Brightwood")) then
                        local trunk = tree:FindFirstChildWhichIsA("BasePart", true)
                        if trunk then
                            hrp.CFrame = CFrame.new(trunk.Position + Vector3.new(2,0,2), trunk.Position)
                            local hits = 0
                            while AutoWoodEnabled and tree:IsDescendantOf(Workspace) and hits < 25 do
                                triggerPhysicalSwing(tree)
                                task.wait(0.2)
                                hits += 1
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- ==========================================
-- WIND UI
-- ==========================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
local Window = WindUI:CreateWindow({Title = "99 Nights | Pro Edition", Size = UDim2.fromOffset(580, 420), Theme = "Dark"})

local MainTab = Window:Tab({Title = "Main"})
local AutoTab = Window:Tab({Title = "Auto Farm"})

MainTab:Toggle({Title = "Auto Click / Tap Swing", Callback = function(v) AutoTapEnabled = v end})
AutoTab:Toggle({Title = "Auto Farm Wood", Callback = function(v) AutoWoodEnabled = v end})
AutoTab:Toggle({Title = "Auto Farm Carrots", Callback = function(v) AutoCarrotEnabled = v end})

AutoTab:Section({Title = "Campfire Settings"})
AutoTab:Toggle({Title = "Auto Cook Meat", Callback = function(v) AutoCookEnabled = v end})
AutoTab:Toggle({Title = "Auto Feed Campfire", Callback = function(v) AutoFeedEnabled = v end})
AutoTab:Dropdown({Title = "Select Feed Item", Values = {"Log", "Coal", "Biofuel", "Fuel Canister"}, Callback = function(v) 
    SelectedFeedMaterials = {[v] = true} 
end})

WindUI:Notify({Title = "Update", Content = "Auto Cook & Carrot Farm Aktif!", Duration = 5})
