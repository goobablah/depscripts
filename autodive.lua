-- [[ GK Autodive ]] --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local Config = {
    Enabled = true,
    ShowHUD = true,
    
    -- [[ DEEP CORNER & INSTANT TRIGGER SETTINGS ]] --
    MaxEvaluationDistance = 140, 
    SmallBoxRadiusX = 21.5,       -- [WIDENED] Deep past the goalposts
    SmallBoxRadiusZ = 22.0,       -- Deep goalmouth range
    VelocityTrigger = 5.0,        -- Lowered back down so it fires immediately without lag
    
    TopBinHeightThreshold = 1.6,  -- High vs low distinction
}

local state = {
    previousBall = nil,
    prevBallPos = Vector3.new(0,0,0),
    prevBallVel = Vector3.new(0,0,0),
    isDiving = false,
    lastDiveTick = 0,
    currentPingMs = 0,
    currentFps = 60,
    targetDirection = 0,
    stabilityFrames = 0,
}

local IsKilled = false
local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- [[ CLEAN UI SETUP ]] --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GKAutodiveGui"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = CoreGui end)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainHub"
mainFrame.Size = isMobileDevice and UDim2.new(0, 300, 0, 260) or UDim2.new(0, 380, 0, 280)
mainFrame.Position = UDim2.new(0.5, mainFrame.Size.X.Offset * -0.5, 0.5, mainFrame.Size.Y.Offset * -0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 130)
mainFrame.BorderSizePixel = 1
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 28)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
topBar.Parent = mainFrame

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 6)
topBarCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ GK AUTODIVE | INSTANT V23"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 130)
titleLabel.TextSize = 10
titleLabel.Font = Enum.Font.Code
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(1, -16, 1, -34)
container.Position = UDim2.new(0, 8, 0, 32)
container.BackgroundTransparency = 1
container.CanvasSize = UDim2.new(0, 0, 0, 360)
container.ScrollBarThickness = 3
container.Parent = mainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = container

local function CreateToggle(name, defaultState, callback)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 0, 32)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 5)
    tCorner.Parent = toggleBtn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.68, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 11
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleBtn
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 38, 0, 18)
    indicator.Position = UDim2.new(1, -46, 0.5, -9)
    indicator.BackgroundColor3 = defaultState and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(60, 60, 75)
    
    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 9)
    iCorner.Parent = indicator
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(1, 0)
    cCorner.Parent = circle
    circle.Parent = indicator
    indicator.Parent = toggleBtn
    
    local currentState = defaultState
    toggleBtn.MouseButton1Click:Connect(function()
        currentState = not currentState
        indicator.BackgroundColor3 = currentState and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(60, 60, 75)
        circle.Position = currentState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        callback(currentState)
    end)
    
    return {
        Set = function(val)
            currentState = val
            indicator.BackgroundColor3 = currentState and Color3.fromRGB(0, 255, 130) or Color3.fromRGB(60, 60, 75)
            circle.Position = currentState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        end,
        Get = function() return currentState end,
        Button = toggleBtn
    }
end

local telemetryBox = Instance.new("TextLabel")
telemetryBox.Size = UDim2.new(1, 0, 0, 65)
telemetryBox.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
telemetryBox.TextColor3 = Color3.fromRGB(0, 255, 130)
telemetryBox.TextSize = 10
telemetryBox.Font = Enum.Font.Code
telemetryBox.TextXAlignment = Enum.TextXAlignment.Left
telemetryBox.TextYAlignment = Enum.TextYAlignment.Top
telemetryBox.Text = " System: GK AUTODIVE ACTIVE\n Status: Armed..."
telemetryBox.Parent = container

local tBoxCorner = Instance.new("UICorner")
tBoxCorner.CornerRadius = UDim.new(0, 5)
tBoxCorner.Parent = telemetryBox

local autodiveToggleObj = CreateToggle("Master Autodive [R]", Config.Enabled, function(val)
    Config.Enabled = val
end)
autodiveToggleObj.Button.Parent = container

-- [[ KILL SWITCH FUNCTION ]] --
local function KillScript()
    if IsKilled then return end
    IsKilled = true
    Config.Enabled = false
    
    pcall(function()
        screenGui:Destroy()
    end)
    
    print("[GK AUTODIVE] Kill switch activated. Script permanently terminated.")
end

-- Kill Switch UI Button
local killButton = Instance.new("TextButton")
killButton.Size = UDim2.new(1, 0, 0, 32)
killButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
killButton.Text = "🚨 KILL SWITCH [END]"
killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
killButton.TextSize = 11
killButton.Font = Enum.Font.Code
killButton.AutoButtonColor = false
killButton.Parent = container

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 5)
kCorner.Parent = killButton

killButton.MouseButton1Click:Connect(function()
    KillScript()
end)

if isMobileDevice then
    local mobileOpenBtn = Instance.new("TextButton")
    mobileOpenBtn.Name = "MobileOpenButton"
    mobileOpenBtn.Size = UDim2.new(0, 90, 0, 36)
    mobileOpenBtn.Position = UDim2.new(0, 10, 0.3, 0)
    mobileOpenBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    mobileOpenBtn.BorderColor3 = Color3.fromRGB(0, 255, 130)
    mobileOpenBtn.Text = "MENU [GK]"
    mobileOpenBtn.TextColor3 = Color3.fromRGB(0, 255, 130)
    mobileOpenBtn.TextSize = 11
    mobileOpenBtn.Font = Enum.Font.Code
    mobileOpenBtn.Active = true
    mobileOpenBtn.Draggable = true
    mobileOpenBtn.Parent = screenGui

    local mBtnCorner = Instance.new("UICorner")
    mBtnCorner.CornerRadius = UDim.new(0, 6)
    mBtnCorner.Parent = mobileOpenBtn

    mobileOpenBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if IsKilled then return end
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.K or input.KeyCode == Enum.KeyCode.Insert then
        mainFrame.Visible = not mainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.R then
        Config.Enabled = not Config.Enabled
        autodiveToggleObj.Set(Config.Enabled)
    elseif input.KeyCode == Enum.KeyCode.End then
        KillScript()
    end
end)

local function GetBall()
    local commonNames = {"Football", "Ball", "Touchball", "MatchBall", "ClientBall", "Puck"}
    local found = nil
    for _, name in ipairs(commonNames) do
        found = Workspace:FindFirstChild(name, true)
        if found and found:IsA("BasePart") then return found end
    end
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:lower().find("ball") then return desc end
    end
    return nil
end

local function ExecuteDiveAction(zoneName, isHighShot, isCenterBlock)
    if IsKilled then return end
    if state.isDiving or (tick() - state.lastDiveTick < 0.10) then return end
    state.isDiving = true
    state.lastDiveTick = tick()

    task.spawn(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim or IsKilled then state.isDiving = false return end

        local moveKey = (zoneName == "Right") and Enum.KeyCode.D or Enum.KeyCode.A

        if isCenterBlock then
            vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.001)
            vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        else
            if zoneName ~= "Center" then vim:SendKeyEvent(true, moveKey, false, game) end
            if isHighShot then vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end
            
            task.wait(0.001) 
            vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
            
            task.wait(0.02) 
            
            vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            if isHighShot then vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
            if zoneName ~= "Center" then vim:SendKeyEvent(false, moveKey, false, game) end
        end
        
        task.wait(0.015)
        state.isDiving = false
    end)
end

-- [[ GK AUTODIVE - INSTANT ENGINE ]] --
RunService.Heartbeat:Connect(function(dt)
    if IsKilled then return end

    state.currentFps = math.floor(1 / math.max(dt, 0.001))
    local rawPing = 0
    pcall(function() rawPing = LocalPlayer:GetNetworkPing() end)
    if rawPing == 0 then
        pcall(function() rawPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
    end
    state.currentPingMs = math.floor(rawPing * 1000)

    if not Config.Enabled then
        telemetryBox.Text = string.format(" System: OFFLINE [R]\n Status: Paused", state.currentPingMs)
        return 
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local ball = GetBall()
    if not ball then 
        state.previousBall = nil
        state.stabilityFrames = 0
        telemetryBox.Text = " System: SEARCHING FOR BALL..."
        return 
    end

    if state.previousBall ~= ball then
        state.previousBall = ball
        state.prevBallPos = ball.Position
        state.prevBallVel = ball.AssemblyLinearVelocity or ball.Velocity
        state.stabilityFrames = 0
        return
    end

    local rootPart = character.HumanoidRootPart
    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity or ball.Velocity
    local ballSpeed = ballVel.Magnitude

    local posDelta = (ballPos - state.prevBallPos).Magnitude
    local isTeleportShot = posDelta > 15.0

    state.prevBallPos = ballPos
    state.prevBallVel = ballVel

    if ballSpeed < Config.VelocityTrigger and not isTeleportShot then
        state.stabilityFrames = 0
        telemetryBox.Text = " Ball Safe / Rolling"
        return
    end

    local distanceToGK = (ballPos - rootPart.Position).Magnitude
    local pingSeconds = math.clamp(rawPing, 0.01, 0.40)
    local compensatedBallPos = ballPos + (ballVel * pingSeconds * 1.1)

    local relativeVector = rootPart.CFrame:VectorToObjectSpace(compensatedBallPos - rootPart.Position)
    local relativeVel = rootPart.CFrame:VectorToObjectSpace(ballVel)

    local timeToImpact = math.abs(relativeVector.Z) / math.max(math.abs(relativeVel.Z), 1.0)

    -- [[ ANTI-PREDIVE SAFETY GATES ]] --
    if timeToImpact > 0.28 or relativeVector.Z > 12.0 then
        state.stabilityFrames = 0
        telemetryBox.Text = " Approaching... [Waiting Line]"
        return
    end

    timeToImpact = math.clamp(timeToImpact, 0.02, 0.35)

    local landingX = relativeVector.X + (relativeVel.X * timeToImpact)
    local landingZ = relativeVector.Z + (relativeVel.Z * timeToImpact)

    if math.abs(landingX) > Config.SmallBoxRadiusX or math.abs(landingZ) > Config.SmallBoxRadiusZ then
        state.stabilityFrames = 0
        telemetryBox.Text = string.format(" Outside Box (X:%.1f)", landingX)
        return
    end

    local heightDelta = compensatedBallPos.Y - rootPart.Position.Y
    local isHighShot = heightDelta >= Config.TopBinHeightThreshold

    local currentDesiredDir = 0
    local zoneName = "None"

    if math.abs(landingX) <= 1.8 and math.abs(relativeVel.X) < 4.0 then
        currentDesiredDir = 3
        zoneName = "Center"
    elseif landingX > 0.15 then
        currentDesiredDir = 1
        zoneName = "Right"
    elseif landingX < -0.15 then
        currentDesiredDir = -1
        zoneName = "Left"
    else
        state.stabilityFrames = 0
        telemetryBox.Text = " Calibrating..."
        return
    end

    local isPointBlankM1 = distanceToGK <= 26.0 or isTeleportShot or (ballSpeed > 25.0)
    local requiredFrames = isPointBlankM1 and 1 or 2

    if currentDesiredDir == state.targetDirection and currentDesiredDir ~= 0 then
        state.stabilityFrames = state.stabilityFrames + 1
    else
        state.targetDirection = currentDesiredDir
        state.stabilityFrames = 1
    end

    telemetryBox.Text = string.format(" ⚡ LOCKED [%.1f]\n Zone: %d | Frame: [%d/%d]", landingX, state.targetDirection, state.stabilityFrames, requiredFrames)

    if state.stabilityFrames >= requiredFrames then
        if state.targetDirection == 3 then
            ExecuteDiveAction("Center", isHighShot, true)
        elseif state.targetDirection == 1 then
            ExecuteDiveAction("Right", isHighShot, false)
        elseif state.targetDirection == -1 then
            ExecuteDiveAction("Left", isHighShot, false)
        end
        state.stabilityFrames = 0
    end
end)
