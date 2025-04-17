-- === SETTINGS HANDLING ===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")

local colorMap = {
    purple = Color3.fromRGB(128, 0, 128),
    black = Color3.fromRGB(0, 0, 0),
    orange = Color3.fromRGB(255, 165, 0),
    green = Color3.fromRGB(0, 255, 0),
    pink = Color3.fromRGB(255, 105, 180),
    red = Color3.fromRGB(255, 0, 0),
    white = Color3.fromRGB(255, 255, 255),
}

local function parseColor(value)
    return colorMap[string.lower(tostring(value))] or Color3.fromRGB(255, 255, 255)
end

local function parseKey(value)
    return Enum.KeyCode[string.upper(tostring(value))] or Enum.KeyCode.F
end

local settings = {
    player = {
        nametags = _G.player_nametags or false,
        hitboxes = _G.player_hitboxes or false,
        hitbox_color = parseColor(_G.player_hitboxes_color or "red"),
    },
    bot = {
        nametags = _G.bot_nametags or false,
        hitboxes = _G.bot_hitboxes or false,
        hitbox_color = parseColor(_G.bot_hitboxes_color or "orange"),
    },
    focus_color = parseColor(_G.focus_color or "green"),
    keybinds = {
        hide_hitboxes = parseKey(_G.hide_hitboxes or "F"),
    }
}

-- === ESP SETUP ===
local aimEnabled = false
local target = nil
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESP_Boxes"
local espVisible = true

local function isPlayer(character)
    return Players:GetPlayerFromCharacter(character) ~= nil
end

local function createBox(character, isTarget)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local name = character.Name
    local existing = espFolder:FindFirstChild(name .. "_ESP")
    if existing then existing:Destroy() end

    local isPlayerChar = isPlayer(character)

    -- Entscheide, ob wir für diesen Character eine Box zeichnen sollen
    local shouldDraw =
        (isPlayerChar and settings.player.hitboxes) or
        (not isPlayerChar and settings.bot.hitboxes) or
        isTarget

    if not shouldDraw then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = name .. "_ESP"
    billboard.Adornee = character.HumanoidRootPart
    billboard.Size = UDim2.new(4, 0, 6, 0)
    billboard.StudsOffset = Vector3.new(0, -0.35, 0)
    billboard.AlwaysOnTop = true

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 2

    if isTarget then
        frame.BackgroundColor3 = settings.focus_color
    elseif isPlayerChar then
        frame.BackgroundColor3 = settings.player.hitbox_color
    else
        frame.BackgroundColor3 = settings.bot.hitbox_color
    end

    billboard.Enabled = espVisible
    billboard.Parent = espFolder
end

local function getAllHumanoids()
    local result = {}
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
            if model ~= LocalPlayer.Character then
                table.insert(result, model)
            end
        end
    end
    return result
end

local function updateESP()
    for _, v in pairs(espFolder:GetChildren()) do
        v:Destroy()
    end

    for _, character in pairs(getAllHumanoids()) do
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            createBox(character, character == (target and target.Character))
        end
    end
end

local function getClosestTarget()
    local closest = nil
    local shortestDistance = math.huge

    for _, character in pairs(getAllHumanoids()) do
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")

        if humanoid and humanoid.Health > 0 and head then
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local mouse = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    local player = Players:GetPlayerFromCharacter(character)
                    closest = player or {Character = character}
                end
            end
        end
    end

    return closest
end

local function aimAt(player)
    if player and player.Character and player.Character:FindFirstChild("Head") then
        camera.CFrame = CFrame.new(camera.CFrame.Position, player.Character.Head.Position)
    end
end

UserInput.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = true
        target = getClosestTarget()
    elseif input.KeyCode == settings.keybinds.hide_hitboxes then
        espVisible = not espVisible
    end
end)

UserInput.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimEnabled = false
        target = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if aimEnabled and target then
        if target.Character and target.Character:FindFirstChild("Humanoid") and target.Character:FindFirstChild("Head") then
            if target.Character.Humanoid.Health > 0 then
                aimAt(target)
            else
                target = getClosestTarget()
            end
        else
            target = getClosestTarget()
        end
    end
    updateESP()
end)
