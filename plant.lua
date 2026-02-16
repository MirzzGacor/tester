-- Modern Farm UI with Auto Plant (single X, teleport then place along +X until seeds exhausted)
-- Executor-friendly, scrollable, draggable, minimize & close
-- New: Auto Plant button + Seed Count input
-- Behavior: teleport player to (2,37) then place at base tile and move +1 X each seed until Seed Count exhausted

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Try get LocalPlayer (some executors need a short wait)
local player = Players.LocalPlayer
if not player then
    for i = 1, 30 do
        player = Players.LocalPlayer
        if player then break end
        wait(0.05)
    end
end

-- Safe remote lookup
local function findRemotes()
    local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    local placeRemote = root and root:FindFirstChild("PlayerPlaceItem")
    local punchRemote = root and root:FindFirstChild("PlayerFist")
    return placeRemote, punchRemote
end

local placeRemote, punchRemote = findRemotes()

-- Choose GUI parent with fallbacks for executors
local function chooseGuiParent()
    if player then
        local ok, pg = pcall(function() return player:FindFirstChild("PlayerGui") end)
        if ok and pg then return pg end
    end
    if type(gethui) == "function" then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local core = game:GetService("CoreGui")
    if core then return core end
    return nil
end

local guiParent = chooseGuiParent()
if not guiParent then
    warn("ModernFarmUI: No suitable GUI parent found. GUI may not appear.")
end

-- Create ScreenGui safely
local okGui, gui = pcall(function()
    local g = Instance.new("ScreenGui")
    g.Name = "ModernFarmUI"
    g.ResetOnSpawn = false
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = guiParent
    return g
end)
if not okGui or not gui then
    warn("ModernFarmUI: Failed to create ScreenGui.", gui)
    return
end

-- Protect GUI if executor supports it
if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(function() syn.protect_gui(gui) end)
end
gui.Enabled = true

-- Panel sizes
local PANEL_WIDTH, PANEL_HEIGHT = 460, 420
local PANEL_MIN_HEIGHT = 40

-- Main panel
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
dragTitle.Text = "Harvest Studio"
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

-- Inputs
local tileXBox = labeledTextbox(content, "Tile X (base)", 1, "e.g. 2", "2")
local tileYBox = labeledTextbox(content, "Tile Y (base)", 2, "e.g. 37", "37")
local idBox = labeledTextbox(content, "Item ID (seed)", 3, "e.g. 10", "10")
local delayBox = labeledTextbox(content, "Delay (ms)", 4, "e.g. 1000", "1000")
local punchCountBox = labeledTextbox(content, "Punch Count", 5, "e.g. 1", "1") -- existing
local seedCountBox = labeledTextbox(content, "Seed Count", 6, "e.g. 10", "10") -- NEW: number of seeds to plant

-- Spacer
local spacer = Instance.new("Frame", content)
spacer.Size = UDim2.new(1, 0, 0, 6)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 7

-- Buttons container: Auto Farm and Auto Plant
local buttonsContainer = Instance.new("Frame", content)
buttonsContainer.Size = UDim2.new(1, -12, 0, 56)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.LayoutOrder = 8

local farmBtn = Instance.new("TextButton", buttonsContainer)
farmBtn.Size = UDim2.new(0.48, -6, 1, 0)
farmBtn.Position = UDim2.new(0, 0, 0, 0)
farmBtn.BackgroundColor3 = Color3.fromRGB(88,165,255)
farmBtn.TextColor3 = Color3.fromRGB(18,20,25)
farmBtn.Font = Enum.Font.SourceSansBold
farmBtn.TextSize = 16
farmBtn.Text = "▶ Start Auto Farm"
farmBtn.AutoButtonColor = false
farmBtn.BorderSizePixel = 0

local plantBtn = Instance.new("TextButton", buttonsContainer)
plantBtn.Size = UDim2.new(0.48, -6, 1, 0)
plantBtn.Position = UDim2.new(0.52, 6, 0, 0)
plantBtn.BackgroundColor3 = Color3.fromRGB(120,200,120)
plantBtn.TextColor3 = Color3.fromRGB(18,20,25)
plantBtn.Font = Enum.Font.SourceSansBold
plantBtn.TextSize = 16
plantBtn.Text = "▶ Start Auto Plant"
plantBtn.AutoButtonColor = false
plantBtn.BorderSizePixel = 0

-- Status labels
local status = Instance.new("TextLabel", content)
status.Size = UDim2.new(1, -12, 0, 20)
status.BackgroundTransparency = 1
status.LayoutOrder = 9
status.Text = "Status: idle"
status.TextColor3 = Color3.fromRGB(160,200,255)
status.Font = Enum.Font.SourceSans
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left

local placeStatus = Instance.new("TextLabel", content)
placeStatus.Size = UDim2.new(1, -12, 0, 18)
placeStatus.BackgroundTransparency = 1
placeStatus.LayoutOrder = 10
placeStatus.Text = "Place: idle"
placeStatus.TextColor3 = Color3.fromRGB(180,220,180)
placeStatus.Font = Enum.Font.SourceSans
placeStatus.TextSize = 12
placeStatus.TextXAlignment = Enum.TextXAlignment.Left

local punchStatus = Instance.new("TextLabel", content)
punchStatus.Size = UDim2.new(1, -12, 0, 18)
punchStatus.BackgroundTransparency = 1
punchStatus.LayoutOrder = 11
punchStatus.Text = "Punch: idle"
punchStatus.TextColor3 = Color3.fromRGB(180,220,180)
punchStatus.Font = Enum.Font.SourceSans
punchStatus.TextSize = 12
punchStatus.TextXAlignment = Enum.TextXAlignment.Left

-- Safe remote helpers
local function safeFind()
    placeRemote, punchRemote = findRemotes()
end

local function safeFirePlace(tx, ty, id)
    if not placeRemote then safeFind() end
    if not placeRemote then return false, "Place remote not found" end
    local ok, err = pcall(function()
        placeRemote:FireServer(Vector2.new(tx, ty), id)
    end)
    return ok, err
end

local function safeFirePunch(tx, ty)
    if not punchRemote then safeFind() end
    if not punchRemote then return false, "Punch remote not found" end
    local ok, err = pcall(function()
        punchRemote:FireServer(Vector2.new(tx, ty))
    end)
    return ok, err
end

-- Existing Auto Farm logic (kept minimal here)
local farmRunning = false
local farmThread = nil
local punchDelay = 0.12

farmBtn.MouseButton1Click:Connect(function()
    farmRunning = not farmRunning
    if farmRunning then
        farmBtn.Text = "⏸ Stop Auto Farm"
        status.Text = "Status: running auto farm..."
        farmThread = spawn(function()
            while farmRunning do
                local tx = tonumber(tileXBox.Text)
                local ty = tonumber(tileYBox.Text)
                local id = tonumber(idBox.Text)
                local delayMs = tonumber(delayBox.Text) or 1000
                local punchCount = tonumber(punchCountBox.Text) or 1
                if punchCount < 1 then punchCount = 1 end

                if not tx or not ty or not id then
                    placeStatus.Text = "Place: invalid input"
                    status.Text = "Status: masukkan Tile X, Tile Y, dan Item ID yang valid."
                    farmRunning = false
                    farmBtn.Text = "▶ Start Auto Farm"
                    break
                end

                local targetX = math.floor(tx + 0.5)
                local targetY = math.floor(ty + 0.5) + 1

                if not placeRemote then safeFind() end
                if placeRemote then
                    local okPlace, errPlace = safeFirePlace(targetX, targetY, id)
                    if okPlace then
                        placeStatus.Text = string.format("Place: placed ID %d at (%d,%d)", id, targetX, targetY)
                    else
                        placeStatus.Text = "Place failed: " .. tostring(errPlace)
                    end
                else
                    placeStatus.Text = "Place: remote not found"
                end

                wait(punchDelay)

                if not punchRemote then safeFind() end
                if punchRemote then
                    for i = 1, punchCount do
                        if not farmRunning then break end
                        local okPunch, errPunch = safeFirePunch(targetX, targetY)
                        if okPunch then
                            punchStatus.Text = string.format("Punch: fired %d/%d at (%d,%d)", i, punchCount, targetX, targetY)
                        else
                            punchStatus.Text = "Punch failed: " .. tostring(errPunch)
                        end
                        wait(punchDelay)
                    end
                else
                    punchStatus.Text = "Punch: remote not found"
                end

                wait((tonumber(delayBox.Text) or 1000) / 1000)
            end

            placeStatus.Text = "Place: stopped"
            punchStatus.Text = "Punch: stopped"
            status.Text = "Status: idle"
            farmBtn.Text = "▶ Start Auto Farm"
        end)
    else
        farmBtn.Text = "▶ Start Auto Farm"
        status.Text = "Status: stopping auto farm..."
        farmRunning = false
    end
end)

-- NEW: Auto Plant logic (teleport to (2,37) then place along +X until seeds exhausted)
local plantRunning = false
local plantThread = nil

local function safeTeleportTo(x, z)
    -- Try to teleport player's HumanoidRootPart to world coords (x, currentY, z)
    if not player then return false end
    local char = player.Character or player.CharacterAdded:Wait()
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not hrp then return false end
    local ok, err = pcall(function()
        -- Keep Y as current to avoid falling through map; set X and Z to provided values
        local currentY = hrp.Position.Y
        hrp.CFrame = CFrame.new(x, currentY, z)
    end)
    return ok
end

plantBtn.MouseButton1Click:Connect(function()
    plantRunning = not plantRunning
    if plantRunning then
        plantBtn.Text = "⏸ Stop Auto Plant"
        status.Text = "Status: starting auto plant (teleport -> place along +X)..."
        plantThread = spawn(function()
            -- read inputs
            local baseTileX = tonumber(tileXBox.Text) or 2
            local baseTileY = tonumber(tileYBox.Text) or 37
            local seedCount = tonumber(seedCountBox.Text) or 1
            local id = tonumber(idBox.Text)
            local delayMs = tonumber(delayBox.Text) or 1000

            if seedCount < 1 then seedCount = 1 end
            if not id then
                status.Text = "Status: Item ID invalid"
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end

            -- Teleport player to (2,37) world coords (user requested). We interpret (2,37) as X,Z world coords.
            local tpOk = safeTeleportTo(2, 37)
            if not tpOk then
                status.Text = "Status: teleport failed (no HRP)"
                plantRunning = false
                plantBtn.Text = "▶ Start Auto Plant"
                return
            end
            status.Text = "Status: teleported to (2,37). Starting planting..."

            -- Start placing seeds along +X. We'll use tile coordinates from baseTileX/baseTileY as canonical tile mapping.
            -- For each seed i from 1..seedCount:
            --   targetTileX = baseTileX + (i-1)
            --   targetTileY = baseTileY
            --   place at (targetTileX, targetTileY + 1)  -- keep Y+1 mapping as used elsewhere
            for i = 1, seedCount do
                if not plantRunning then break end

                local targetTileX = math.floor(baseTileX + (i - 1) + 0.5)
                local targetTileY = math.floor(baseTileY + 0.5) + 1

                -- Place
                if not placeRemote then safeFind() end
                if placeRemote then
                    local okPlace, errPlace = safeFirePlace(targetTileX, targetTileY, id)
                    if okPlace then
                        placeStatus.Text = string.format("Plant: placed ID %d at (%d,%d) [%d/%d]", id, targetTileX, targetTileY, i, seedCount)
                    else
                        placeStatus.Text = "Plant place failed: " .. tostring(errPlace)
                    end
                else
                    placeStatus.Text = "Plant: place remote not found"
                end

                -- Optionally move player slightly to follow planting position (so server may accept place)
                -- We'll attempt to move HRP to approximate world X position for the tile (best-effort)
                pcall(function()
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        -- Move HRP by +1 on X in world space to roughly follow tile progression
                        hrp.CFrame = hrp.CFrame * CFrame.new(1, 0, 0)
                    end
                end)

                -- Wait a short moment to avoid spamming
                wait((delayMs / 1000) / math.max(1, seedCount)) -- small pacing; overall cycle delay still controlled by delayMs
            end

            status.Text = "Status: Auto Plant finished or stopped"
            plantBtn.Text = "▶ Start Auto Plant"
            plantRunning = false
        end)
    else
        plantBtn.Text = "▶ Start Auto Plant"
        status.Text = "Status: stopping auto plant..."
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
    farmRunning = false
    plantRunning = false
end)

-- Initial hint
status.Text = "Status: ready — masukkan Tile X,Y, Item ID, Seed Count lalu Start Auto Plant"
print("ModernFarmUI: GUI created and running (Auto Plant added)")
