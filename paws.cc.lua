-- LocalScript (place in StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Black Screen Loading Effect
local BlackScreen = Instance.new("ScreenGui")
BlackScreen.Name = "PAWSLoading"
BlackScreen.Parent = LocalPlayer:WaitForChild("PlayerGui")
BlackScreen.ResetOnSpawn = false

local BlackOverlay = Instance.new("Frame")
BlackOverlay.Size = UDim2.new(1, 0, 1, 0)
BlackOverlay.Position = UDim2.new(0, 0, 0, 0)
BlackOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackOverlay.BorderSizePixel = 0
BlackOverlay.Parent = BlackScreen

local PawsText = Instance.new("TextLabel")
PawsText.Size = UDim2.new(0, 400, 0, 100)
PawsText.Position = UDim2.new(0.5, -200, 0.5, -50)
PawsText.BackgroundTransparency = 1
PawsText.Text = "paws.cc"
PawsText.TextColor3 = Color3.fromRGB(0, 162, 255)
PawsText.TextScaled = true
PawsText.Font = Enum.Font.GothamBold
PawsText.Parent = BlackOverlay

wait(2)

local fadeOut = TweenService:Create(BlackOverlay, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {
    BackgroundTransparency = 1
})
local textFade = TweenService:Create(PawsText, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {
    TextTransparency = 1
})

fadeOut:Play()
textFade:Play()
fadeOut.Completed:Connect(function()
    BlackScreen:Destroy()
    loadHub()
end)

-- MAIN HUB
local espObjects = {}
local connections = {}
local isAiming = false
local lockedTarget = nil
local speedEnabled = false

local ESP_COLOR = Color3.fromRGB(255, 255, 255) -- White name ESP
local LOCKED_COLOR = Color3.fromRGB(0, 0, 255) -- Green when locked

function loadHub()
    print("paws!")
    
    -- INSTANT SPEED SYSTEM - Works immediately, no delays
    local function updateSpeed()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speedEnabled and 259 or 16
            end
        end
    end
    
    local function toggleSpeed()
        speedEnabled = not speedEnabled
        updateSpeed() -- Instant apply
        print("Speed:", speedEnabled and "ON (259)" or "OFF (16)")
    end
    
    -- Ultra-fast speed loop (runs every frame)
    connections.speed = RunService.Heartbeat:Connect(updateSpeed)
    
    local function cleanupESP(player)
        if espObjects[player] then
            if espObjects[player].name then
                espObjects[player].name:Remove()
            end
            espObjects[player] = nil
        end
        if connections[player] then
            pcall(function() connections[player]:Disconnect() end)
            connections[player] = nil
        end
    end
    
    local function createESP(player)
        if player == LocalPlayer then return end
        
        cleanupESP(player)
        
        local function updateESP()
            local character = player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then 
                return 
            end
            
            local hrp = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if not hrp or not humanoid or humanoid.Health <= 0 then 
                return 
            end
            
            if not espObjects[player] then
                espObjects[player] = {}
                
                local name = Drawing.new("Text")
                name.Color = ESP_COLOR
                name.Size = 18
                name.Center = true
                name.Outline = true
                name.OutlineColor = Color3.new(0,0,0)
                name.Font = 2
                name.Text = player.DisplayName -- Changed to DisplayName
                espObjects[player].name = name
            end
            
            local espData = espObjects[player]
            local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and rootPos.Z > 0 then
                local head = character:FindFirstChild("Head")
                local size = head and head.Size or Vector3.new(2, 1, 1)
                local bottomOffset = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, size.Y + 0.5, 0))
                
                local color = ESP_COLOR
                if hrp == lockedTarget then
                    color = LOCKED_COLOR
                end
                
                espData.name.Color = color
                espData.name.Text = player.DisplayName
                espData.name.Position = Vector2.new(rootPos.X, bottomOffset.Y + 5)
                espData.name.Visible = true
                
            else
                espData.name.Visible = false
            end
        end
        
        local conn = RunService.Heartbeat:Connect(updateESP)
        connections[player] = conn
    end
    
    function getClosestTarget()
        local closest, shortestDist = nil, math.huge
        local mousePos = UserInputService:GetMouseLocation()
        
        for player, data in pairs(espObjects) do
            if data.name and data.name.Visible then
                local namePos = data.name.Position
                local dist = (mousePos - namePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player.Character.HumanoidRootPart
                end
            end
        end
        return closest
    end
    
    -- Controls
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.X then
            toggleSpeed()
        elseif input.UserInputType == Enum.UserInputType.Mousebutton2 then
            isAiming = true
            lockedTarget = getClosestTarget()
            if lockedTarget then
                print("Target locked:", lockedTarget.Parent.Name)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Mousebutton2 then
            isAiming = false
            lockedTarget = nil
            print("Aim released")
        end
    end)
    
    -- Character respawn handler
    LocalPlayer.CharacterAdded:Connect(function()
        -- Speed applies instantly via the heartbeat loop
        wait(0.1) -- Small delay for character to fully load
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        cleanupESP(player)
    end)
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            wait(0.3)
            cleanupESP(player)
            createESP(player)
        end)
        if player.Character then
            createESP(player)
        end
    end)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            createESP(player)
        end
        player.CharacterAdded:Connect(function()
            wait(0.3)
            cleanupESP(player)
            createESP(player)
        end)
    end
    
    RunService.Heartbeat:Connect(function()
        if not isAiming or not lockedTarget or not lockedTarget.Parent then return end
        
        local character = lockedTarget.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoid and humanoid.Health > 0 then
            local targetHead = character:FindFirstChild("Head") or lockedTarget
            local targetPos = targetHead.Position + targetHead.Velocity * 0.1
            
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.3)
        else
            lockedTarget = nil
        end
    end)
end