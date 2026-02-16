-- AutoPlantLine.lua
-- Player teleport ke tile (2,37), lalu menanam seed sambil bergerak ke kanan (X+1)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote untuk planting (ganti sesuai nama Remote di game)
local plantRemote = ReplicatedStorage.Remotes:WaitForChild("PlantTree")

-- Parameter grid
local tileSize = 4
local originX = 0 -- isi hasil kalibrasi
local originY = 0 -- isi hasil kalibrasi

-- Fungsi konversi tile → world
local function tileToWorld(tileX, tileY)
    local worldX = originX + (tileX * tileSize)
    local worldY = originY + (tileY * tileSize)
    return worldX, worldY
end

-- Fungsi teleport player ke tile tertentu
local function teleportTo(tileX, tileY)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local worldX, worldY = tileToWorld(tileX, tileY)
        hrp.CFrame = CFrame.new(worldX, hrp.Position.Y, worldY)
    end
end

-- Fungsi menanam seed di tile tertentu
local function plantAt(tileX, tileY)
    local ok, result = pcall(function()
        return plantRemote:InvokeServer({X = tileX, Y = tileY})
    end)
    if ok then
        print(("Planted at Tile (%d,%d)"):format(tileX, tileY))
    else
        warn("Plant failed at", tileX, tileY, result)
    end
end

-- Loop planting
spawn(function()
    local startX, startY = 2, 37
    local currentX = startX
    local currentY = startY

    -- Teleport ke awal
    teleportTo(currentX, currentY)

    while true do
        plantAt(currentX, currentY)
        wait(0.2) -- delay kecil agar tidak overload
        currentX = currentX + 1
        teleportTo(currentX, currentY)
        -- Tambahkan kondisi stop manual (misalnya tombol keybind)
    end
end)
