
local success, Functions = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/alllazy450-sketch/99night/main/functions.lua"))()
end)

if not success or not Functions then
    Functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/alllazy450-sketch/99night/main/function.lua"))()
end

local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("W424_CustomUI") then
    CoreGui.W424_CustomUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "W424_CustomUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Position = UDim2.new(0.5, -150, 0.5, -120)
Frame.Size = UDim2.new(0, 300, 0, 240)
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "99 Nights | W424 Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 10)

local function createToggleButton(name, posY, defaultState, callback)
    local Btn = Instance.new("TextButton")
    Btn.Parent = Frame
    Btn.Position = UDim2.new(0.05, 0, 0, posY)
    Btn.Size = UDim2.new(0.9, 0, 0, 35)
    Btn.Font = Enum.Font.SourceSansSemibold
    Btn.TextSize = 14
    
    local state = defaultState
    local function updateVisual()
        if state then
            Btn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
            Btn.Text = name .. " : [ ON ]"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Btn.Text = name .. " : [ OFF ]"
            Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    
    updateVisual()
    Btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)
    
    local BtnCorner = Instance.new("UICorner", Btn)
    BtnCorner.CornerRadius = UDim.new(0, 6)
end

createToggleButton("Kill Aura", 45, false, function(v) _G.KillAura = v end)
createToggleButton("Auto Farm Wood", 90, false, function(v) _G.AutoWood = v end)
createToggleButton("Auto Hunt Mob", 135, false, function(v) _G.AutoHunt = v end)
createToggleButton("Auto Claim Meat", 180, false, function(v) _G.AutoClaim = v end)

local OpenBtn = Instance.new("TextButton")
OpenBtn.Parent = ScreenGui
OpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
OpenBtn.Position = UDim2.new(0, 15, 0.4, 0)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.Text = "W424"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.TextSize = 16
OpenBtn.Active = true
OpenBtn.Draggable = true

local OpenCorner = Instance.new("UICorner", OpenBtn)
OpenCorner.CornerRadius = UDim.new(0, 25)

OpenBtn.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)
