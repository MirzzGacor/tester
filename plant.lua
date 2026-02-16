-- AutoPlantUI (no Punch Count)
-- UI matches Auto Farm style. Auto Plant: teleport then place seeds along +X.
-- Punch Count removed entirely from UI and logic.
-- Paste as LocalScript in executor (supports gethui/syn). Adjust remote name if needed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Get LocalPlayer (some executors need a short wait)
local player = Players.LocalPlayer
if not player then
    for i = 1, 30 do
        player = Players.LocalPlayer
        if player then break end
        wait(0.05)
    end
end

-- Remote lookup (adjust path/name if your game uses different)
local function findPlaceRemote()
    local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    return root and root:FindFirstChild("PlayerPlaceItem")
end
local placeRemote = findPlaceRemote()

-- Choose GUI parent (executor-friendly)
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

-- Create ScreenGui
local okGui, gui = pcall(function()
    local g = Instance.new("ScreenGui")
    g.Name = "AutoPlantUI"
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = guiParent
    return g
end)
if not okGui or not gui then
    warn("AutoPlantUI: failed to create GUI parent.")
    return
end

-- Protect GUI if executor supports it
if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(function() syn.protect_gui(gui) end)
end

-- Panel sizes (match Auto Farm style)
local PANEL_WIDTH, PANEL_HEIGHT = 380, 320
local PANEL_MIN_HEIGHT = 40

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
panel.Position = UDim2.new(0.03, 0, 0.12, 0)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
panel.BorderSizePixel = 0
panel.AnchorPoint = Vector2.new(0,0)
panel.Parent = gui
panel.Active = true
panel.ClipsDescendants = true
panel.ZIndex = 2
panel.Visible = true

-- Drag bar
local dragBar = Instance.new("Frame", panel)
dragBar.Name = "DragBar"
dragBar.Size = UDim2.new(1, 0, 0, 36)
dragBar.Position = UDim2.new(0, 0, 0, 0)
dragBar.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
dragBar.BorderSizePixel = 0
dragBar.ZIndex = 3

local dragTitle = Instance.new("TextLabel", dragBar)
dragTitle.Size = UDim2.new(1, -100, 1, 0)
dragTitle.Position = UDim2.new(0, 12, 0, 0)
dragTitle.BackgroundTransparency = 1
dragTitle.Text = "Harvest Studio"
dragTitle.TextColor3 = Color3.fromRGB(235,235,240)
dragTitle.Font = Enum.Font.SourceSansBold
dragTitle.TextSize = 16
dragTitle.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", dragBar)
minimizeBtn.Name = "Minimize"
minimizeBtn.Size = UDim2.new(0, 28, 0, 24)
minimizeBtn.Position = UDim2.new(1, -72, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(120,120,120)
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.AutoButtonColor = false
minimizeBtn.ZIndex = 4

local closeBtn = Instance.new("TextButton", dragBar)
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 4

-- Drag logic
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updatePosition(input)
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
dragBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and dragStart then
        updatePosition(input)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    pcall(function() gui:Destroy() end)
end)

-- Content (scrollable) - ensure scrolling works like Auto Farm
local content = Instance.new("ScrollingFrame", panel)
content.Name = "ContentScroll"
content.Size = UDim2.new(1, -24, 1, -72)
content.Position = UDim2.new(0, 12, 0, 60)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 6
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
content.ScrollBarImageColor3 = Color3.fromRGB(100,100,110)
content.Visible = true
content.ZIndex = 2
content.Active = true -- important for mouse wheel

local listLayout = Instance.new("UIListLayout", content)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)

local pad = Instance.new("UIPadding", content)
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingRight = UDim.new(0, 6)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local sizeY = listLayout.AbsoluteContentSize.Y + 12
    content.CanvasSize = UDim2.new(0, 0, 0, sizeY)
end)

-- Helper to create labeled textbox inside scrolling frame
local function labeledTextbox(parent, labelText, layoutOrder, placeholder, default)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -12, 0, 64)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200,200,210)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(1, 0, 0, 34)
    box.Position = UDim2.new(0, 0, 0, 26)
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

-- Inputs (match Auto Farm UI fields, Punch Count removed)
local tileXBox = labeledTextbox(content, "Tile X (base)", 1, "e.g. 2", "2")
local tileYBox = labeledTextbox(content, "Tile Y (base)", 2, "e.g. 37", "37")
local idBox = labeledTextbox(content, "Item ID (seed)", 3, "e.g. 10", "10")
local delayBox = labeledTextbox(content, "Delay (ms)", 4, "e.g. 1000", "1000")
local seedCountBox = labeledTextbox(content, "Seed Count", 5, "e.g. 10", "10")

-- Spacer
local spacer = Instance.new("Frame", content)
spacer.Size = UDim2.new(1, 0, 0, 6)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 6

-- Start Auto Plant button (only control requested)
local plantContainer = Instance.new("Frame", content)
plantContainer.Size = UDim2.new(1, -12, 0, 56)
plantContainer.BackgroundTransparency = 1
plantContainer.LayoutOrder = 7

local plantBtn = Instance.new("TextButton", plantContainer)
plantBtn.Size = UDim2.new(1, 0, 1, 0)
plantBtn.Position = UDim2.new(0, 0, 0, 0)
plantBtn.BackgroundColor3 = Color3.fromRGB(120,200,120)
plantBtn.TextColor3 = Color3.fromRGB(18,20,25)
plantBtn.Font = Enum.Font.SourceSansBold
plantBtn.TextSize = 16
plantBtn.Text = "▶ Start Auto Plant"
plantBtn.AutoButtonColor = false
plantBtn.BorderSizePixel = 0

-- Status label
local status = Instance.new("TextLabel", content)
status.Size = UDim2.new(1, -12, 0, 20)
status.BackgroundTransparency = 1
status.LayoutOrder = 8
status.Text = "Status: idle"
status.TextColor3 = Color3.fromRGB(160,200,255)
status.Font = Enum.Font.SourceSans
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left

-- Safe remote helpers
local function safeFind()
    placeRemote = findPlaceRemote()
end

local function safeFirePlace(tx, ty, id)
    if not placeRemote then safeFind() end
    if not placeRemote then return false, "Place remote not found" end
    local ok, err = pcall(function()
        placeRemote:FireServer(Vector2.new(tx, ty), tonumber(id))
    end)
    return ok, err
end

-- Teleport helpers: wait for HRP, attempt teleport multiple times and verify
local function waitForHRP(timeout)
    timeout = timeout or 5
    local t0 = tick()
    while tick() - t0 < timeout do
        local char = player and player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp then return hrp end
        end
        wait(0.05)
    end
    return nil
end

local function tryTeleport(hrp, targetCFrame)
    local ok, err = pcall(function()
        hrp.CFrame = targetCFrame
    end)
    return ok, err
end

local function isClose(posA, posB, tol)
    tol = tol or 1.5
    return (math.abs(posA.X - posB.X) <= tol) and (math.abs(posA.Z - posB.Z) <= tol)
end

local function teleportAndVerify(worldX, worldZ, attempts, safeY)
    attempts = attempts or 5
    safeY = safeY or 50
    local hrp = waitForHRP(6)
    local humanoid = nil
    if player and player.Character then
        humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    end
    if not hrp then return false, "HumanoidRootPart not found (character not ready)" end

    local targetPos = Vector3.new(tonumber(worldX) or 2, safeY, tonumber(worldZ) or 37)
    local targetCFrame = CFrame.new(targetPos)

    for i = 1, attempts do
        -- direct set
        pcall(function() hrp.CFrame = targetCFrame end)
        wait(0.12)
        if isClose(hrp.Position, targetPos) then return true end

        -- try humanoid state then set
        if humanoid then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
            wait(0.06)
            pcall(function() hrp.CFrame = targetCFrame end)
            wait(0.12)
            if isClose(hrp.Position, targetPos) then return true end
        end

        -- try MoveTo
        pcall(function()
            local char = player.Character
            if char then char:MoveTo(targetPos) end
        end)
        wait(0.25)
        if isClose(hrp.Position, targetPos) then return true end

        -- upward nudge
        pcall(function() hrp.CFrame = CFrame.new(targetPos.X, safeY + 3, targetPos.Z) end)
        wait(0.12)
        if isClose(hrp.Position, targetPos) then return true end
    end

    if isClose(hrp.Position, targetPos) then return true end
    return false, "teleport verification failed (server may override client movement)"
end

-- Planting logic: teleport then place seeds along +X (no punching)
local plantRunning = false

plantBtn.MouseButton1Click:Connect(function()
    plantRunning = not plantRunning
    if plantRunning then
        plantBtn.Text = "⏸ Stop Auto Plant"
        status.Text = "Status: preparing auto plant..."
        spawn(function()
            -- read inputs
            local baseTileX = tonumber(tileXBox.Text) or 2
            local baseTileY = tonumber(tileYBox.Text) or 37
            local id = tonumber(idBox.Text)
            local delayMs = tonumber(delayBox.Text) or 1000
            local seedCount = tonumber(seedCountBox.Text) or 1
            if seedCount < 1 then seedCount = 1 end
            if not id then
                status.Text = "Status: invalid Item ID"
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end

            -- Teleport world coords: default to (2,37) as requested
            status.Text = "Status: teleporting to (2,37)..."
            local ok, err = teleportAndVerify(2, 37, 6, 50)
            if not ok then
                status.Text = "Teleport failed: " .. tostring(err)
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end

            status.Text = "Status: teleported. Starting planting..."
            for i = 1, seedCount do
                if not plantRunning then break end
                local targetTileX = math.floor(baseTileX + (i - 1) + 0.5)
                local targetTileY = math.floor(baseTileY + 0.5) + 1 -- Y+1 mapping

                -- Place
                if not placeRemote then safeFind() end
                if placeRemote then
                    local okPlace, errPlace = safeFirePlace(targetTileX, targetTileY, id)
                    if okPlace then
                        status.Text = string.format("Placed %d/%d at (%d,%d)", i, seedCount, targetTileX, targetTileY)
                    else
                        status.Text = "Place failed: " .. tostring(errPlace)
                    end
                else
                    status.Text = "Place remote not found"
                end

                -- optional small movement to mimic walking and help server accept place
                pcall(function()
                    local hrp = waitForHRP(0.5)
                    if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(1, 0, 0) end
                end)

                wait((delayMs or 1000) / 1000)
            end

            status.Text = "Status: finished planting"
            plantRunning = false
            plantBtn.Text = "▶ Start Auto Plant"
        end)
    else
        plantBtn.Text = "▶ Start Auto Plant"
        status.Text = "Status: stopping..."
        plantRunning = false
    end
end)

-- Minimize behavior
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        content.Visible = false
        panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_MIN_HEIGHT)
        dragTitle.Text = "Harvest Studio (minimized)"
        minimizeBtn.Text = "+"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    else
        content.Visible = true
        panel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
        dragTitle.Text = "Harvest Studio"
        minimizeBtn.Text = "—"
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(120,120,120)
    end
end)

-- Cleanup
gui.Destroying:Connect(function()
    plantRunning = false
end)

status.Text = "Status: ready — masukkan Tile X,Y, Item ID, Seed Count lalu Start"
print("AutoPlantUI loaded (Punch Count removed)")
