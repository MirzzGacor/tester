-- Modern Farm UI (3 X offsets, Place -> Punch N times)
-- Executor-friendly, scrollable, draggable, minimize & close
-- Behavior: untuk setiap offset (x-1, x, x+1) lakukan Place lalu Punch sebanyak N kali pada koordinat yang sama
-- Paste sebagai LocalScript atau jalankan di APK executor. Sesuaikan nama remote jika perlu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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
local PANEL_WIDTH, PANEL_HEIGHT = 380, 360
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
dragTitle.Size = UDim2.new(1, -140, 1, 0)
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
minimizeBtn.Position = UDim2.new(1, -104, 0, 6)
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
closeBtn.Position = UDim2.new(1, -68, 0, 6)
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
content.Size = UDim2.new(1, -24, 1, -84)
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
local tileXBox = labeledTextbox(content, "Tile X", 1, "e.g. 44", "")
local tileYBox = labeledTextbox(content, "Tile Y", 2, "e.g. 37", "")
local idBox = labeledTextbox(content, "Item ID", 3, "e.g. 10", "10")
local delayBox = labeledTextbox(content, "Delay (ms)", 4, "e.g. 1000", "1000")
local punchCountBox = labeledTextbox(content, "Punch Count", 5, "e.g. 3", "3") -- new input for punch count

-- Spacer
local spacer = Instance.new("Frame", content)
spacer.Size = UDim2.new(1, 0, 0, 6)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 6

-- Single Start Auto Farm button (starts both Place and Punch N times for three X)
local farmContainer = Instance.new("Frame", content)
farmContainer.Size = UDim2.new(1, -12, 0, 56)
farmContainer.BackgroundTransparency = 1
farmContainer.LayoutOrder = 7

local farmBtn = Instance.new("TextButton", farmContainer)
farmBtn.Size = UDim2.new(1, 0, 1, 0)
farmBtn.Position = UDim2.new(0, 0, 0, 0)
farmBtn.BackgroundColor3 = Color3.fromRGB(88,165,255)
farmBtn.TextColor3 = Color3.fromRGB(18,20,25)
farmBtn.Font = Enum.Font.SourceSansBold
farmBtn.TextSize = 16
farmBtn.Text = "▶ Start Auto Farm"
farmBtn.AutoButtonColor = false
farmBtn.BorderSizePixel = 0

-- Status labels
local status = Instance.new("TextLabel", content)
status.Size = UDim2.new(1, -12, 0, 20)
status.BackgroundTransparency = 1
status.LayoutOrder = 8
status.Text = "Status: idle"
status.TextColor3 = Color3.fromRGB(160,200,255)
status.Font = Enum.Font.SourceSans
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left

local placeStatus = Instance.new("TextLabel", content)
placeStatus.Size = UDim2.new(1, -12, 0, 18)
placeStatus.BackgroundTransparency = 1
placeStatus.LayoutOrder = 9
placeStatus.Text = "Place: idle"
placeStatus.TextColor3 = Color3.fromRGB(180,220,180)
placeStatus.Font = Enum.Font.SourceSans
placeStatus.TextSize = 12
placeStatus.TextXAlignment = Enum.TextXAlignment.Left

local punchStatus = Instance.new("TextLabel", content)
punchStatus.Size = UDim2.new(1, -12, 0, 18)
punchStatus.BackgroundTransparency = 1
punchStatus.LayoutOrder = 10
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

-- Combined Auto Farm logic: three X offsets (-1,0,1) with identical coords per offset
local farmRunning = false
local punchDelay = 0.12 -- jeda setelah place sebelum punch (sesuaikan jika perlu)
local betweenOffsetDelay = 0.08 -- jeda kecil antar offset agar tidak spam terlalu cepat
local xOffsets = {-1, 0, 1}

farmBtn.MouseButton1Click:Connect(function()
    farmRunning = not farmRunning
    if farmRunning then
        farmBtn.Text = "⏸ Stop Auto Farm"
        status.Text = "Status: running auto farm (3 X offsets)..."
        placeStatus.Text = "Place: starting..."
        punchStatus.Text = "Punch: starting..."

        spawn(function()
            while farmRunning do
                local baseX = tonumber(tileXBox.Text)
                local baseY = tonumber(tileYBox.Text)
                local id = tonumber(idBox.Text)
                local delayMs = tonumber(delayBox.Text) or 1000
                local punchCount = tonumber(punchCountBox.Text) or 1
                if punchCount < 1 then punchCount = 1 end

                if not baseX or not baseY or not id then
                    placeStatus.Text = "Place: invalid input"
                    status.Text = "Status: masukkan Tile X, Tile Y, dan Item ID yang valid."
                    farmRunning = false
                    farmBtn.Text = "▶ Start Auto Farm"
                    break
                end

                -- iterasi untuk setiap offset: x-1, x, x+1
                for _, dx in ipairs(xOffsets) do
                    if not farmRunning then break end

                    local targetX = math.floor(baseX + dx + 0.5)
                    local targetY = math.floor(baseY + 0.5) + 1 -- Y +1 sesuai kebutuhan

                    -- Place pada target (canonical)
                    if not placeRemote then safeFind() end
                    if placeRemote then
                        local okPlace, errPlace = safeFirePlace(targetX, targetY, id)
                        if okPlace then
                            placeStatus.Text = string.format("Place: ID %d at (%d,%d)", id, targetX, targetY)
                        else
                            placeStatus.Text = "Place failed: " .. tostring(errPlace)
                        end
                    else
                        placeStatus.Text = "Place: remote not found"
                    end

                    -- tunggu singkat agar server memproses place
                    wait(punchDelay)

                    -- Punch sebanyak punchCount kali pada koordinat yang sama
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
                            -- jeda kecil antar punch agar tidak terlalu cepat
                            wait(punchDelay)
                        end
                    else
                        punchStatus.Text = "Punch: remote not found"
                    end

                    -- jeda kecil antar offset untuk mengurangi spam
                    wait(betweenOffsetDelay)
                end

                -- selesai satu siklus tiga offset, tunggu Delay(ms) sebelum ulang
                wait(delayMs / 1000)
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
end)

-- Initial hint
status.Text = "Status: ready — masukkan Tile X,Y, Item ID, Punch Count lalu Start"
print("ModernFarmUI: GUI created and running (3 X offsets, Place -> Punch N times)")
