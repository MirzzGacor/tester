-- Auto Plant Executor Script (Fixed: draggable UI + working ScrollingFrame)
-- Paste into your executor. Designed to run client-side (PlayerGui / gethui).
-- Ensure "PlayerPlaceItem" remote exists in ReplicatedStorage.Remotes or ReplicatedStorage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    for i = 1, 30 do
        player = Players.LocalPlayer
        if player then break end
        wait(0.05)
    end
end

-- find place remote
local function findPlaceRemote()
    local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    return root and root:FindFirstChild("PlayerPlaceItem")
end
local placeRemote = findPlaceRemote()

-- choose GUI parent (executor-friendly)
local function chooseGuiParent()
    if player and player:FindFirstChild("PlayerGui") then
        return player.PlayerGui
    end
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    return game:GetService("CoreGui")
end
local guiParent = chooseGuiParent()

-- create ScreenGui
local screen = Instance.new("ScreenGui")
screen.Name = "AutoPlantExecutorGui"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = guiParent

-- protect gui if executor supports it
if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(function() syn.protect_gui(screen) end)
end

-- Main window
local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, 360, 0, 220)
window.Position = UDim2.new(0, 20, 0, 80)
window.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
window.BorderSizePixel = 0
window.AnchorPoint = Vector2.new(0,0)
window.Parent = screen
window.Active = true -- required for dragging on some clients
window.ClipsDescendants = true

-- Title bar (drag handle)
local titleBar = Instance.new("Frame", window)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Plant (Executor)"
titleLabel.TextColor3 = Color3.fromRGB(235,235,240)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false

closeBtn.MouseButton1Click:Connect(function()
    pcall(function() screen:Destroy() end)
end)

-- Scrolling content area
local content = Instance.new("ScrollingFrame", window)
content.Name = "Content"
content.Size = UDim2.new(1, -12, 1, -48)
content.Position = UDim2.new(0, 6, 0, 42)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 8
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
content.ScrollBarImageColor3 = Color3.fromRGB(120,120,130)
content.Active = true -- important so mouse wheel works reliably
content.Parent = window

local layout = Instance.new("UIListLayout", content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)

local padding = Instance.new("UIPadding", content)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)

-- ensure CanvasSize updates when content changes
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
end)

-- Helper to create labeled textbox rows inside scrolling frame
local function labeledTextbox(parent, labelText, layoutOrder, placeholder, default)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(0, 140, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200,200,210)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(1, -4, 0, 30)
    box.Position = UDim2.new(0, 0, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(28,30,36)
    box.TextColor3 = Color3.fromRGB(230,230,235)
    box.PlaceholderText = placeholder or ""
    box.Text = default or ""
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0

    return box, container
end

-- Inputs
local tpXBox = labeledTextbox(content, "Teleport World X", 1, "e.g. 2", "2")
local tpZBox = labeledTextbox(content, "Teleport World Z", 2, "e.g. 37", "37")
local tileXBox = labeledTextbox(content, "Tile X (base)", 3, "e.g. 2", "2")
local tileYBox = labeledTextbox(content, "Tile Y (base)", 4, "e.g. 37", "37")
local idBox    = labeledTextbox(content, "Item ID (seed)", 5, "e.g. 10", "10")
local seedCountBox = labeledTextbox(content, "Seed Count", 6, "e.g. 10", "10")

-- Buttons row
local buttonsFrame = Instance.new("Frame", content)
buttonsFrame.Size = UDim2.new(1, 0, 0, 40)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.LayoutOrder = 7

local startBtn = Instance.new("TextButton", buttonsFrame)
startBtn.Size = UDim2.new(0.5, -6, 1, 0)
startBtn.Position = UDim2.new(0, 0, 0, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(120,200,120)
startBtn.Text = "▶ Start Auto Plant"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 14
startBtn.TextColor3 = Color3.fromRGB(18,20,25)
startBtn.BorderSizePixel = 0

local stopBtn = Instance.new("TextButton", buttonsFrame)
stopBtn.Size = UDim2.new(0.5, -6, 1, 0)
stopBtn.Position = UDim2.new(0.5, 12, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(200,120,120)
stopBtn.Text = "■ Stop"
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 14
stopBtn.TextColor3 = Color3.fromRGB(18,20,25)
stopBtn.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel", content)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.LayoutOrder = 8
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(160,200,255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Dragging logic for titleBar/window
local dragging = false
local dragStart = nil
local startPos = nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        -- nothing here; handled by UserInputService.InputChanged
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Helper: wait for HRP
local function waitForHRP(timeout)
    timeout = timeout or 5
    local t0 = tick()
    while tick() - t0 < timeout do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp then return hrp end
        end
        wait(0.05)
    end
    return nil
end

-- Safe teleport (set Y to safe height 50)
local function safeTeleportToWorld(x, z)
    local hrp = waitForHRP(5)
    if not hrp then return false, "HumanoidRootPart not found" end
    local ok, err = pcall(function()
        hrp.CFrame = CFrame.new(tonumber(x) or 2, 50, tonumber(z) or 37)
    end)
    if not ok then return false, tostring(err) end
    return true
end

-- Safe place call
local function safePlace(tx, ty, id)
    if not placeRemote then placeRemote = findPlaceRemote() end
    if not placeRemote then return false, "place remote not found" end
    local ok, err = pcall(function()
        placeRemote:FireServer(Vector2.new(tx, ty), tonumber(id))
    end)
    return ok, err
end

-- Main planting logic
local running = false
local plantThread = nil

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    startBtn.Text = "⏸ Running..."
    statusLabel.Text = "Status: preparing..."

    local tpX = tonumber(tpXBox.Text) or 2
    local tpZ = tonumber(tpZBox.Text) or 37
    local baseTileX = tonumber(tileXBox.Text) or 2
    local baseTileY = tonumber(tileYBox.Text) or 37
    local id = tonumber(idBox.Text)
    local seedCount = tonumber(seedCountBox.Text) or 1
    if seedCount < 1 then seedCount = 1 end
    if not id then
        statusLabel.Text = "Status: invalid Item ID"
        running = false
        startBtn.Text = "▶ Start Auto Plant"
        return
    end

    -- teleport
    statusLabel.Text = string.format("Status: teleporting to (%.1f, %.1f)...", tpX, tpZ)
    local ok, err = safeTeleportToWorld(tpX, tpZ)
    if not ok then
        statusLabel.Text = "Teleport failed: " .. tostring(err)
        running = false
        startBtn.Text = "▶ Start Auto Plant"
        return
    end

    statusLabel.Text = "Status: planting..."
    plantThread = spawn(function()
        for i = 1, seedCount do
            if not running then break end
            local targetTileX = math.floor(baseTileX + (i - 1) + 0.5)
            local targetTileY = math.floor(baseTileY + 0.5) + 1
            local okPlace, errPlace = safePlace(targetTileX, targetTileY, id)
            if okPlace then
                statusLabel.Text = string.format("Placed %d/%d at (%d,%d)", i, seedCount, targetTileX, targetTileY)
            else
                statusLabel.Text = "Place failed: " .. tostring(errPlace)
            end
            -- move HRP slightly forward to mimic walking (best-effort)
            pcall(function()
                local hrp = waitForHRP(1)
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(1, 0, 0) end
            end)
            wait(0.25)
        end
        statusLabel.Text = "Status: finished"
        running = false
        startBtn.Text = "▶ Start Auto Plant"
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not running then return end
    running = false
    statusLabel.Text = "Status: stopping..."
    startBtn.Text = "▶ Start Auto Plant"
end)

-- Ensure ScrollingFrame responds to mouse wheel on some clients:
-- When mouse is over the content area, capture input and forward to ScrollingFrame
content.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        -- handled by ScrollingFrame automatically; nothing required
    end
end)

-- Finalize
statusLabel.Text = "Status: ready"
print("AutoPlantExecutorGui loaded (draggable + scrollable)")
