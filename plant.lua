-- Auto Plant minimal: hanya tombol Start Auto Plant
-- Behavior:
-- 1) Teleport player ke world coords (2, 50, 37) untuk keamanan
-- 2) Place seed pada tile base (tileX, tileY) lalu maju +1 X per seed sampai SeedCount habis
-- 3) Hanya satu tombol Start/Stop; status sederhana di layar
-- Paste sebagai LocalScript (PlayerGui)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    for i = 1, 30 do
        player = Players.LocalPlayer
        if player then break end
        wait(0.05)
    end
end

-- cari remote place (sesuaikan path jika berbeda)
local function findPlaceRemote()
    local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    return root and root:FindFirstChild("PlayerPlaceItem")
end

local placeRemote = findPlaceRemote()

-- GUI minimal
local screen = Instance.new("ScreenGui")
screen.Name = "AutoPlantSimpleGui"
screen.ResetOnSpawn = false
screen.Parent = player:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0, 300, 0, 140)
frame.Position = UDim2.new(0, 20, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(24,26,32)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -12, 0, 28)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Auto Plant (Simple)"
title.TextColor3 = Color3.fromRGB(235,235,240)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

local function labeledBox(y, label, default)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 100, 0, 20)
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200,200,210)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.new(0, 170, 0, 28)
    box.Position = UDim2.new(0, 120, 0, y - 4)
    box.BackgroundColor3 = Color3.fromRGB(28,30,36)
    box.TextColor3 = Color3.fromRGB(230,230,235)
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.Text = tostring(default or "")
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    return box
end

local tileXBox = labeledBox(40, "Tile X (base)", 2)
local tileYBox = labeledBox(72, "Tile Y (base)", 37)
local idBox    = labeledBox(104, "Item ID (seed)", 10)
local seedCountBox = labeledBox(136, "Seed Count", 10)

-- Adjust frame height to fit
frame.Size = UDim2.new(0, 300, 0, 180)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0, 140, 0, 30)
startBtn.Position = UDim2.new(0, 20, 0, 140)
startBtn.BackgroundColor3 = Color3.fromRGB(120,200,120)
startBtn.Text = "▶ Start Auto Plant"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 14
startBtn.TextColor3 = Color3.fromRGB(18,20,25)
startBtn.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(0, 120, 0, 30)
statusLabel.Position = UDim2.new(0, 170, 0, 140)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: idle"
statusLabel.TextColor3 = Color3.fromRGB(160,200,255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- helper: tunggu character & HRP
local function waitForHRP(timeout)
    timeout = timeout or 5
    local t0 = tick()
    while tick() - t0 < timeout do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp then return hrp end
        end
        wait(0.1)
    end
    return nil
end

-- teleport aman: set X,Z sesuai, Y ke nilai aman (50)
local function safeTeleportToWorld(x, z)
    local hrp = waitForHRP(5)
    if not hrp then return false, "HumanoidRootPart not found" end
    local ok, err = pcall(function()
        hrp.CFrame = CFrame.new(tonumber(x) or 2, 50, tonumber(z) or 37)
    end)
    if not ok then return false, tostring(err) end
    return true
end

-- safe place call
local function safePlace(tx, ty, id)
    if not placeRemote then placeRemote = findPlaceRemote() end
    if not placeRemote then return false, "place remote not found" end
    local ok, err = pcall(function()
        placeRemote:FireServer(Vector2.new(tx, ty), tonumber(id))
    end)
    return ok, err
end

-- main plant loop
local running = false
startBtn.MouseButton1Click:Connect(function()
    running = not running
    if running then
        startBtn.Text = "⏸ Stop Auto Plant"
        statusLabel.Text = "Status: teleporting..."
        -- read inputs
        local baseX = tonumber(tileXBox.Text) or 2
        local baseY = tonumber(tileYBox.Text) or 37
        local id = tonumber(idBox.Text)
        local seedCount = tonumber(seedCountBox.Text) or 1
        if seedCount < 1 then seedCount = 1 end
        if not id then
            statusLabel.Text = "Status: invalid Item ID"
            running = false
            startBtn.Text = "▶ Start Auto Plant"
            return
        end

        -- teleport to safe world coords (2,50,37)
        local ok, err = safeTeleportToWorld(2, 37)
        if not ok then
            statusLabel.Text = "Teleport failed: " .. tostring(err)
            running = false
            startBtn.Text = "▶ Start Auto Plant"
            return
        end

        statusLabel.Text = "Status: planting..."
        spawn(function()
            for i = 1, seedCount do
                if not running then break end
                local targetTileX = math.floor(baseX + (i - 1) + 0.5)
                local targetTileY = math.floor(baseY + 0.5) + 1 -- Y+1 mapping
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
    else
        running = false
        startBtn.Text = "▶ Start Auto Plant"
        statusLabel.Text = "Status: stopping..."
    end
end)
