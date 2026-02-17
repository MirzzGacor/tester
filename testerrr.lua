-- Modern Farm UI (Edited to use Block Name instead of Item ID)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote untuk farming
local placeRemote = ReplicatedStorage.Remotes:WaitForChild("PlayerPlaceItem")

-- Helper untuk FireServer
local function safeFirePlace(tx, ty, blockName)
    if not placeRemote then return false, "Place remote not found" end
    local ok, err = pcall(function()
        placeRemote:FireServer(Vector2.new(tx, ty), blockName)
    end)
    return ok, err
end

-- UI
local screen = Instance.new("ScreenGui")
screen.Name = "FarmUI"
screen.ResetOnSpawn = false
screen.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 300, 0, 220)
frame.Position = UDim2.new(0, 20, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 28)
title.Text = "Modern Farm UI"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)

-- Input fields
local function labeledTextbox(parent, labelText, order, placeholder, default)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(0.5, -6, 0, 24)
    label.Position = UDim2.new(0, 6, 0, 30*order)
    label.Text = labelText
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)

    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0.5, -6, 0, 24)
    box.Position = UDim2.new(0.5, 0, 0, 30*order)
    box.PlaceholderText = placeholder
    box.Text = default or ""
    box.BackgroundColor3 = Color3.fromRGB(40,40,50)
    box.TextColor3 = Color3.new(1,1,1)
    return box
end

local xBox = labeledTextbox(frame, "Tile X", 0, "e.g. 10", "10")
local yBox = labeledTextbox(frame, "Tile Y", 1, "e.g. 15", "15")
local nameBox = labeledTextbox(frame, "Block Name", 2, "e.g. TreeBlock", "")
local delayBox = labeledTextbox(frame, "Delay (sec)", 3, "e.g. 0.5", "0.5")
local punchBox = labeledTextbox(frame, "Punch Count", 4, "e.g. 1", "1")

-- Tombol Start
local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1, -12, 0, 40)
startBtn.Position = UDim2.new(0, 6, 0, 180)
startBtn.Text = "Start Farm 1x"
startBtn.BackgroundColor3 = Color3.fromRGB(60,120,200)
startBtn.TextColor3 = Color3.new(1,1,1)

-- Event tombol
startBtn.MouseButton1Click:Connect(function()
    local tx = tonumber(xBox.Text)
    local ty = tonumber(yBox.Text)
    local blockName = nameBox.Text
    local delay = tonumber(delayBox.Text) or 0.5
    local punchCount = tonumber(punchBox.Text) or 1

    if not tx or not ty or blockName == "" then
        warn("Please fill all fields correctly")
        return
    end

    -- Auto farm sekali jalan
    for i=1, punchCount do
        local okPlace, errPlace = safeFirePlace(tx, ty, blockName)
        if not okPlace then
            warn("Farm failed:", errPlace)
        else
            print("Farmed block:", blockName, "at", tx, ty)
        end
        wait(delay)
    end
end)
