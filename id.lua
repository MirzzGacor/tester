-- Check Block ID UI and logic (with Close button)
-- Paste as LocalScript. Works best if run client-side (PlayerGui).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    for i = 1, 30 do
        player = Players.LocalPlayer
        if player then break end
        wait(0.05)
    end
end

-- Helper: create simple ScreenGui
local function createGui()
    local parent = player and player:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    local screen = Instance.new("ScreenGui")
    screen.Name = "BlockIdCheckerGui"
    screen.ResetOnSpawn = false
    screen.Parent = parent

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 360, 0, 180)
    frame.Position = UDim2.new(0, 20, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -12, 0, 28)
    title.Position = UDim2.new(0, 6, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Block ID Checker"
    title.TextColor3 = Color3.fromRGB(235,235,240)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local function makeLabel(y, text)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0, 120, 0, 20)
        lbl.Position = UDim2.new(0, 8, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(200,200,210)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return lbl
    end

    local function makeBox(y, default)
        local box = Instance.new("TextBox", frame)
        box.Size = UDim2.new(0, 200, 0, 28)
        box.Position = UDim2.new(0, 130, 0, y)
        box.BackgroundColor3 = Color3.fromRGB(28,30,36)
        box.TextColor3 = Color3.fromRGB(230,230,235)
        box.Font = Enum.Font.Code
        box.TextSize = 14
        box.Text = default or ""
        box.ClearTextOnFocus = false
        box.BorderSizePixel = 0
        return box
    end

    makeLabel(40, "Tile X")
    local tileXBox = makeBox(36, "2")

    makeLabel(72, "Tile Y")
    local tileYBox = makeBox(68, "37")

    makeLabel(104, "Expected ID")
    local idBox = makeBox(100, "10")

    local checkBtn = Instance.new("TextButton", frame)
    checkBtn.Size = UDim2.new(0, 120, 0, 30)
    checkBtn.Position = UDim2.new(0, 130, 0, 136)
    checkBtn.BackgroundColor3 = Color3.fromRGB(88,165,255)
    checkBtn.Text = "Check ID"
    checkBtn.Font = Enum.Font.SourceSansBold
    checkBtn.TextSize = 14
    checkBtn.TextColor3 = Color3.fromRGB(18,20,25)
    checkBtn.BorderSizePixel = 0

    local resultLabel = Instance.new("TextLabel", frame)
    resultLabel.Size = UDim2.new(1, -12, 0, 28)
    resultLabel.Position = UDim2.new(0, 6, 0, 136)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = Color3.fromRGB(200,200,210)
    resultLabel.Font = Enum.Font.SourceSans
    resultLabel.TextSize = 12
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button (added)
    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 28, 0, 24)
    closeBtn.Position = UDim2.new(1, -34, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false

    closeBtn.MouseButton1Click:Connect(function()
        if screen and screen.Parent then
            screen:Destroy()
        end
    end)

    return {
        Screen = screen,
        TileX = tileXBox,
        TileY = tileYBox,
        IdBox = idBox,
        CheckBtn = checkBtn,
        Result = resultLabel
    }
end

local gui = createGui()

-- Utility: normalize tile -> integer tile coords
local function normalizeTile(v)
    return math.floor(tonumber(v) or 0 + 0.5)
end

-- Search heuristics for block at tile coords
local function findBlockAtTile(tileX, tileY)
    -- returns first matching object and a table of match info, or nil
    tileX = tonumber(tileX)
    tileY = tonumber(tileY)
    if not tileX or not tileY then return nil end

    -- iterate workspace descendants (best-effort)
    for _, obj in ipairs(workspace:GetDescendants()) do
        -- consider BasePart or Model with PrimaryPart
        if obj:IsA("BasePart") then
            local px = math.floor(obj.Position.X + 0.5)
            local py = math.floor(obj.Position.Y + 0.5)
            if px == tileX and py == tileY then
                -- try to read attributes
                local attrs = {}
                if obj.GetAttribute then
                    attrs.BlockID = obj:GetAttribute("BlockID")
                    attrs.ItemID = obj:GetAttribute("ItemID")
                    attrs.ID = obj:GetAttribute("ID")
                end
                return obj, {method = "part-position", attrs = attrs}
            end
        elseif obj:IsA("Model") then
            local primary = obj.PrimaryPart
            if primary then
                local px = math.floor(primary.Position.X + 0.5)
                local py = math.floor(primary.Position.Y + 0.5)
                if px == tileX and py == tileY then
                    local attrs = {}
                    if obj.GetAttribute then
                        attrs.BlockID = obj:GetAttribute("BlockID")
                        attrs.ItemID = obj:GetAttribute("ItemID")
                        attrs.ID = obj:GetAttribute("ID")
                    end
                    return obj, {method = "model-primary-position", attrs = attrs}
                end
            end
        end
    end

    -- fallback: try to find by attributes anywhere (matching tile attributes)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.GetAttribute then
            local tx = obj:GetAttribute("TileX") or obj:GetAttribute("tileX")
            local ty = obj:GetAttribute("TileY") or obj:GetAttribute("tileY")
            if tx and ty and tonumber(tx) == tileX and tonumber(ty) == tileY then
                local attrs = {BlockID = obj:GetAttribute("BlockID"), ItemID = obj:GetAttribute("ItemID"), ID = obj:GetAttribute("ID")}
                return obj, {method = "attribute-tile", attrs = attrs}
            end
        end
    end

    return nil
end

-- Check whether found object matches expected ID
local function checkBlockId(obj, expectedId)
    if not obj then return false, "no object" end
    expectedId = tostring(expectedId)

    -- 1) check attributes
    if obj.GetAttribute then
        local candidates = {"BlockID", "ItemID", "ID"}
        for _, k in ipairs(candidates) do
            local v = obj:GetAttribute(k)
            if v ~= nil and tostring(v) == expectedId then
                return true, string.format("matched attribute %s = %s", k, tostring(v))
            end
        end
    end

    -- 2) check name contains expectedId
    if obj.Name and string.find(tostring(obj.Name), expectedId, 1, true) then
        return true, string.format("matched name contains '%s' (name=%s)", expectedId, obj.Name)
    end

    -- 3) if Model, check children names/attributes
    if obj:IsA("Model") then
        for _, c in ipairs(obj:GetDescendants()) do
            if c:IsA("BasePart") then
                if c.GetAttribute then
                    local v = c:GetAttribute("BlockID")
                    if v and tostring(v) == expectedId then
                        return true, "matched child part attribute BlockID"
                    end
                end
                if c.Name and string.find(c.Name, expectedId, 1, true) then
                    return true, "matched child part name"
                end
            end
        end
    end

    -- 4) no match
    return false, "no matching id found on object"
end

-- Hook up UI button
gui.CheckBtn.MouseButton1Click:Connect(function()
    local tx = normalizeTile(gui.TileX.Text)
    local ty = normalizeTile(gui.TileY.Text)
    local expected = gui.IdBox.Text

    gui.Result.Text = "Checking..."
    -- find block at tile
    local foundObj, info = findBlockAtTile(tx, ty)
    if not foundObj then
        gui.Result.Text = string.format("No block found at tile (%d,%d).", tx, ty)
        return
    end

    local ok, reason = pcall(function()
        return checkBlockId(foundObj, expected)
    end)

    if not ok then
        gui.Result.Text = "Error while checking: " .. tostring(reason)
        return
    end

    local matched, detail = checkBlockId(foundObj, expected)
    if matched then
        gui.Result.Text = string.format("FOUND: %s — %s", tostring(foundObj:GetFullName()), detail)
    else
        gui.Result.Text = string.format("Block found at (%d,%d) but ID not matched: %s", tx, ty, detail)
    end
end)

-- Optional: expose functions for other scripts
local Checker = {}
Checker.findBlockAtTile = findBlockAtTile
Checker.checkBlockId = checkBlockId

-- store on player for quick access (non-persistent)
if player then
    player:SetAttribute("BlockIdCheckerAvailable", true)
    pcall(function() player.BlockIdChecker = Checker end)
end

print("Block ID Checker UI created")
