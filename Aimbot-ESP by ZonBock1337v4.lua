local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")

local aimEnabled = false -- Wird durch Rechtsklick aktiviert
local target = nil -- Gespeichertes Ziel
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESP_Boxes"

-- Funktion zum Erstellen einer ESP-Box
local function createBox(player, isAiming)
    if player == localPlayer then return end -- Kein ESP für sich selbst
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

    -- Prüfen, ob eine Box existiert, wenn ja, löschen
    local existingBox = espFolder:FindFirstChild(player.Name .. "_ESP")
    if existingBox then
        existingBox:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name .. "_ESP"
    billboard.Adornee = player.Character.HumanoidRootPart
    billboard.Size = UDim2.new(4, 0, 6, 0) -- Größe der Box
    billboard.StudsOffset = Vector3.new(0, -0.35, 0) -- Position über dem Spieler
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = isAiming and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) -- Grüne Box, wenn der Aimbot drauf ist
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 2

    billboard.Parent = espFolder
end

-- Funktion zum Erstellen und Aktualisieren des ESPs
local function updateESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy() -- Löscht alte Boxen
    end

    for _, player in pairs(players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                createBox(player, player == target) -- Grüne Box, wenn Aimbot auf Spieler fokussiert
            end
        end
    end
end

-- Funktion, um den nächsten gültigen Spieler zu finden
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head") -- Zielt auf den Kopf

            if humanoid and humanoid.Health > 0 and head and head:IsDescendantOf(workspace) then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local mousePos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Funktion für sofortiges Zielen auf den Kopf
local function aimAt(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head
        camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position) -- Kein Lerp = Sofortiges Zielen
    end
end

-- Rechtsklick gedrückt -> Aimbot aktivieren
userInput.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = true
        target = getClosestPlayer()
    end
end)

-- Rechtsklick losgelassen -> Aimbot deaktivieren
userInput.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = false
        target = nil
    end
end)

-- Ständiges Update für ESP und Aimbot
runService.RenderStepped:Connect(function()
    if aimEnabled and target then
        if target.Character and target.Character:FindFirstChild("Humanoid") and target.Character:FindFirstChild("Head") then
            if target.Character.Humanoid.Health > 0 then
                aimAt(target)
            else
                target = getClosestPlayer() -- Neues Ziel suchen, wenn der Gegner stirbt
            end
        else
            target = getClosestPlayer() -- Neues Ziel suchen, falls es gelöscht wurde
        end
    end

    -- Aktualisiert das ESP immer
    updateESP()
end)
