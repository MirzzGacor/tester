-- Auto Plant Executor with Tile->World mapping and Calibrate feature
-- Paste as LocalScript in executor (PlayerGui / gethui). Adjust remote name if needed.

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

-- Remote lookup
local function findPlaceRemote()
    local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    return root and root:FindFirstChild("PlayerPlaceItem")
end
local placeRemote = findPlaceRemote()

-- GUI parent selection (executor-friendly)
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
    g.Name = "AutoPlantUI_Mapped"
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = guiParent
    return g
end)
if not okGui or not gui then
    warn("AutoPlantUI: failed to create GUI parent.")
    return
end

if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(function() syn.protect_gui(gui) end)
end

-- Panel sizes
local PANEL_WIDTH, PANEL_HEIGHT = 420, 360
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
dragTitle.Size = UDim2.new(1, -160, 1, 0)
dragTitle.Position = UDim2.new(0, 12, 0, 0)
dragTitle.BackgroundTransparency = 1
dragTitle.Text = "Harvest Studio (Auto Plant)"
dragTitle.TextColor3 = Color3.fromRGB(235,235,240)
dragTitle.Font = Enum.Font.SourceSansBold
dragTitle.TextSize = 16
dragTitle.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", dragBar)
minimizeBtn.Name = "Minimize"
minimizeBtn.Size = UDim2.new(0, 28, 0, 24)
minimizeBtn.Position = UDim2.new(1, -120, 0, 6)
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
closeBtn.Position = UDim2.new(1, -84, 0, 6)
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

-- Content (scrollable)
local content = Instance.new("ScrollingFrame", panel)
content.Name = "ContentScroll"
content.Size = UDim2.new(1, -24, 1, -120)
content.Position = UDim2.new(0, 12, 0, 60)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 6
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
content.ScrollBarImageColor3 = Color3.fromRGB(100,100,110)
content.Visible = true
content.ZIndex = 2
content.Active = true

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

-- Helper to create labeled textbox
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

-- Inputs
local tileXBox = labeledTextbox(content, "Tile X (base)", 1, "e.g. 2", "2")
local tileYBox = labeledTextbox(content, "Tile Y (base)", 2, "e.g. 37", "37")
local idBox = labeledTextbox(content, "Item ID (seed)", 3, "e.g. 10", "10")
local delayBox = labeledTextbox(content, "Delay (ms)", 4, "e.g. 1000", "1000")
local seedCountBox = labeledTextbox(content, "Seed Count", 5, "e.g. 10", "10")

-- Mapping parameters
local tileSizeBox = labeledTextbox(content, "Tile Size (world units per tile)", 6, "e.g. 4", "4")
local originXBox = labeledTextbox(content, "Origin World X (tile 0)", 7, "e.g. 0", "0")
local originZBox = labeledTextbox(content, "Origin World Z (tile 0)", 8, "e.g. 0", "0")

-- Calibrate button and info
local calibFrame = Instance.new("Frame", content)
calibFrame.Size = UDim2.new(1, -12, 0, 44)
calibFrame.BackgroundTransparency = 1
calibFrame.LayoutOrder = 9

local calibrateBtn = Instance.new("TextButton", calibFrame)
calibrateBtn.Size = UDim2.new(0.5, -6, 1, 0)
calibrateBtn.Position = UDim2.new(0, 0, 0, 0)
calibrateBtn.BackgroundColor3 = Color3.fromRGB(88,165,255)
calibrateBtn.Text = "Calibrate From Tile"
calibrateBtn.Font = Enum.Font.SourceSansBold
calibrateBtn.TextSize = 14
calibrateBtn.TextColor3 = Color3.fromRGB(18,20,25)
calibrateBtn.BorderSizePixel = 0

local calibInfo = Instance.new("TextLabel", calibFrame)
calibInfo.Size = UDim2.new(0.5, -6, 1, 0)
calibInfo.Position = UDim2.new(0.5, 12, 0, 0)
calibInfo.BackgroundTransparency = 1
calibInfo.Text = "Calibrate finds object with TileX/TileY attributes"
calibInfo.TextColor3 = Color3.fromRGB(180,180,200)
calibInfo.Font = Enum.Font.SourceSans
calibInfo.TextSize = 12
calibInfo.TextXAlignment = Enum.TextXAlignment.Left

-- Start button
local plantContainer = Instance.new("Frame", content)
plantContainer.Size = UDim2.new(1, -12, 0, 56)
plantContainer.BackgroundTransparency = 1
plantContainer.LayoutOrder = 10

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
status.Size = UDim2.new(1, -12, 0, 40)
status.BackgroundTransparency = 1
status.LayoutOrder = 11
status.Text = "Status: ready"
status.TextColor3 = Color3.fromRGB(160,200,255)
status.Font = Enum.Font.SourceSans
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.ClipsDescendants = true

-- Helpers: remote
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

-- Wait for HRP
local function waitForHRP(timeout)
    timeout = timeout or 6
    local t0 = tick()
    while tick() - t0 < timeout do
        local char = player and player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp then return hrp end
        end
        wait(0.06)
    end
    return nil
end

-- Teleport verification (kept robust)
local function isClose(posA, posB, tol)
    tol = tol or 1.5
    return (math.abs(posA.X - posB.X) <= tol) and (math.abs(posA.Z - posB.Z) <= tol)
end

local function tryTeleportTo(posVec, attempts, safeY)
    attempts = attempts or 4
    safeY = safeY or posVec.Y
    local hrp = waitForHRP(6)
    if not hrp then return false, "HumanoidRootPart not found" end
    local target = Vector3.new(posVec.X, safeY, posVec.Z)
    for i = 1, attempts do
        pcall(function() hrp.CFrame = CFrame.new(target) end)
        wait(0.12)
        if isClose(hrp.Position, target) then
            return true, hrp.Position
        end
        pcall(function() hrp.CFrame = CFrame.new(target.X, safeY + 3, target.Z) end)
        wait(0.12)
        if isClose(hrp.Position, target) then
            return true, hrp.Position
        end
        -- MoveTo as fallback
        pcall(function()
            local char = player.Character
            if char then char:MoveTo(target) end
        end)
        wait(0.25)
        if isClose(hrp.Position, target) then
            return true, hrp.Position
        end
    end
    return false, hrp and hrp.Position or nil
end

-- Tile->World conversion
local function tileToWorld(tileX, tileY, tileSize, originX, originZ)
    tileSize = tonumber(tileSize) or 4
    originX = tonumber(originX) or 0
    originZ = tonumber(originZ) or 0
    local worldX = originX + (tileX * tileSize)
    local worldZ = originZ + (tileY * tileSize)
    return worldX, worldZ
end

-- Calibrate: find object with attributes TileX/TileY matching inputs and compute origin
calibrateBtn.MouseButton1Click:Connect(function()
    local tx = tonumber(tileXBox.Text)
    local ty = tonumber(tileYBox.Text)
    local tileSize = tonumber(tileSizeBox.Text) or 4
    if not tx or not ty then
        status.Text = "Calibrate: masukkan Tile X dan Tile Y yang valid."
        return
    end
    status.Text = "Calibrate: mencari objek dengan atribut TileX/TileY..."
    local found = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.GetAttribute then
            local atx = obj:GetAttribute("TileX") or obj:GetAttribute("tileX")
            local aty = obj:GetAttribute("TileY") or obj:GetAttribute("tileY")
            if atx and aty and tonumber(atx) == tx and tonumber(aty) == ty then
                found = obj
                break
            end
        end
    end
    if not found then
        status.Text = "Calibrate: tidak menemukan objek dengan atribut TileX/TileY yang cocok."
        return
    end
    -- use found object's world position to compute origin
    local pos = nil
    if found:IsA("BasePart") then
        pos = found.Position
    elseif found:IsA("Model") and found.PrimaryPart then
        pos = found.PrimaryPart.Position
    else
        -- try to find a child BasePart
        for _, c in ipairs(found:GetDescendants()) do
            if c:IsA("BasePart") then
                pos = c.Position
                break
            end
        end
    end
    if not pos then
        status.Text = "Calibrate: objek ditemukan tapi tidak memiliki posisi world yang dapat digunakan."
        return
    end
    -- originX = pos.X - tileX * tileSize
    local originX = pos.X - (tx * tileSize)
    local originZ = pos.Z - (ty * tileSize)
    originXBox.Text = tostring(math.floor(originX * 100) / 100)
    originZBox.Text = tostring(math.floor(originZ * 100) / 100)
    status.Text = string.format("Calibrate: origin set (OriginX=%.2f, OriginZ=%.2f) based on object %s", originX, originZ, found:GetFullName())
end)

-- Main planting logic (uses tile->world mapping)
local plantRunning = false

plantBtn.MouseButton1Click:Connect(function()
    plantRunning = not plantRunning
    if plantRunning then
        plantBtn.Text = "⏸ Stop Auto Plant"
        status.Text = "Status: preparing..."
        spawn(function()
            local baseTileX = tonumber(tileXBox.Text) or 2
            local baseTileY = tonumber(tileYBox.Text) or 37
            local id = tonumber(idBox.Text)
            local delayMs = tonumber(delayBox.Text) or 1000
            local seedCount = tonumber(seedCountBox.Text) or 1
            local tileSize = tonumber(tileSizeBox.Text) or 4
            local originX = tonumber(originXBox.Text) or 0
            local originZ = tonumber(originZBox.Text) or 0

            if seedCount < 1 then seedCount = 1 end
            if not id then
                status.Text = "Status: invalid Item ID"
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end

            -- compute world coords for base tile
            local worldX, worldZ = tileToWorld(baseTileX, baseTileY, tileSize, originX, originZ)
            status.Text = string.format("Teleporting to world (%.2f, %.2f) mapped from tile (%d,%d)...", worldX, worldZ, baseTileX, baseTileY)

            local ok, info = tryTeleportTo(Vector3.new(worldX, 50, worldZ), 6, 50)
            if not ok then
                local posStr = info and ("current HRP pos: " .. tostring(info)) or "no HRP pos"
                status.Text = "Teleport failed: verification failed; " .. posStr
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end

            status.Text = "Teleported. Starting planting..."
            for i = 1, seedCount do
                if not plantRunning then break end
                local tileX = baseTileX + (i - 1)
                local tileY = baseTileY
                local targetTileX = math.floor(tileX + 0.5)
                local targetTileY = math.floor(tileY + 0.5) + 1 -- Y+1 mapping for place remote
                local okPlace, errPlace = safeFirePlace(targetTileX, targetTileY, id)
                if okPlace then
                    status.Text = string.format("Placed %d/%d at tile (%d,%d)", i, seedCount, targetTileX, targetTileY)
                else
                    status.Text = "Place failed: " .. tostring(errPlace)
                end
                -- small movement to help server accept place
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

gui.Destroying:Connect(function()
    plantRunning = false
end)

status.Text = "Status: ready — gunakan Calibrate From Tile atau atur Tile Size / Origin lalu Start"
print("AutoPlantUI_Mapped loaded")
