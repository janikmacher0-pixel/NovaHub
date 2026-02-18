-- Nova Hub | Premium Duel Script
-- Redesigned UI by Nova Hub

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for character to fully load
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end
task.wait(2)

local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Mouse = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════
--             GLOBALS & CONFIG
-- ══════════════════════════════════════════

_G.InstaPickup = false
local stealDelay = 1.30
local lastStealTick = 0

local infiniteJumpEnabled = false
local JUMP_VELOCITY = 35

local zeroGravEnabled = false
local originalGravity = workspace.Gravity

local originalSettings = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    Diffuse = Lighting.EnvironmentDiffuseScale,
    Specular = Lighting.EnvironmentSpecularScale,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    ColorShift_Top = Lighting.ColorShift_Top,
    QualityLevel = settings().Rendering.QualityLevel,
    FogStart = Lighting.FogStart
}

local aimbotEnabled = false
local AIMBOT_RANGE = 35
local AIMBOT_DISABLE_RANGE = 40
local aimbotConnection, alignOri, attach0

local spinBotEnabled = false
local spinSpeed = 0
local spinVelocity = nil

local noAnimEnabled = false
local antiRagdollEnabled = false
local autoWalkEnabled = false
local autoWalkConnection = nil

local hitboxEnabled = false
local expandedSize = Vector3.new(3.5, 3.5, 3.5)

local CIRCLE_RADIUS = 4
local PART_THICKNESS = 0.8
local PART_HEIGHT = 0.3
local PartsCount = 65
local RING_TRANSPARENCY = 0.3
local ringParts = {}
local ringFolder = nil
local ringConnection = nil

local SpeedActive = false
local DisplaySpeedActive = false
local TARGET_SPEED = 56.2
local DISPLAY_SPEED_VAL = 29.777
local speedV2Attachment = nil
local speedV2LinearVel = nil
local ToggleKey = Enum.KeyCode.L

local xrayEnabled = false
local optimizerEnabled = false
local noTextureEnabled = false
local performanceMode = false
local ultraPotato = false
local textureData = {}
local materialCache = {}
local moonlightActive = false
local moonlightConnection = nil
local fullBrightEnabled = false
local noFogEnabled = false
local boxEspEnabled = false
local studsEnabled = false
local originalTransparencies = {}

local statsEnabled = false
local statsLabels = { ping = nil, fps = nil, container = nil }

-- ══════════════════════════════════════════
--             COLOR THEME
-- ══════════════════════════════════════════

local C = {
    BG          = Color3.fromRGB(8,  10,  18),    -- Very dark navy
    PANEL       = Color3.fromRGB(13, 17,  30),    -- Dark navy panel
    SIDEBAR     = Color3.fromRGB(11, 14,  24),    -- Sidebar bg
    CARD        = Color3.fromRGB(18, 24,  42),    -- Toggle card bg
    CARD_HOVER  = Color3.fromRGB(23, 31,  54),
    ACCENT      = Color3.fromRGB(99, 102, 241),   -- Indigo/purple accent
    ACCENT2     = Color3.fromRGB(139, 92, 246),   -- Violet second accent
    GLOW        = Color3.fromRGB(129, 140, 248),  -- Light indigo glow
    ON          = Color3.fromRGB(99,  102, 241),  -- Toggle ON color
    OFF         = Color3.fromRGB(30,  35,  60),   -- Toggle OFF color
    TEXT        = Color3.fromRGB(230, 232, 255),  -- Main text
    SUBTEXT     = Color3.fromRGB(130, 135, 175),  -- Dim text
    WHITE       = Color3.fromRGB(255, 255, 255),
    DANGER      = Color3.fromRGB(239, 68,  68),
    GREEN       = Color3.fromRGB(52,  211, 153),
    RING        = Color3.fromRGB(99,  102, 241),
}

-- ══════════════════════════════════════════
--         STEAL PROGRESS BAR UI
-- ══════════════════════════════════════════

local existingGui = CoreGui:FindFirstChild("NovaProgress")
if existingGui then existingGui:Destroy() end

local ProgressGui = Instance.new("ScreenGui", CoreGui)
ProgressGui.Name = "NovaProgress"
ProgressGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local BarOuter = Instance.new("Frame", ProgressGui)
BarOuter.Size = UDim2.new(0, 260, 0, 36)
BarOuter.Position = UDim2.new(0.5, -130, 0.87, 0)
BarOuter.BackgroundColor3 = C.PANEL
BarOuter.BorderSizePixel = 0
BarOuter.Visible = false
Instance.new("UICorner", BarOuter).CornerRadius = UDim.new(0, 10)
local barStroke = Instance.new("UIStroke", BarOuter)
barStroke.Color = C.ACCENT
barStroke.Thickness = 1.5
barStroke.Transparency = 0.3

local BarFill = Instance.new("Frame", BarOuter)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = C.ACCENT
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0, 10)
local barGrad = Instance.new("UIGradient", BarFill)
barGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT),
    ColorSequenceKeypoint.new(1, C.ACCENT2)
})

local BarLabel = Instance.new("TextLabel", BarOuter)
BarLabel.Size = UDim2.new(1, 0, 1, 0)
BarLabel.BackgroundTransparency = 1
BarLabel.Text = "READY"
BarLabel.TextColor3 = C.WHITE
BarLabel.Font = Enum.Font.GothamBold
BarLabel.TextSize = 11

-- ══════════════════════════════════════════
--         HELPER FUNCTIONS
-- ══════════════════════════════════════════

local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t or 0.25, style, dir), props):Play()
end

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent.Position end
    if parent:IsA("Model") then
        local primary = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
    end
    if parent:IsA("Attachment") then return parent.WorldPosition end
    local part = parent:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function findNearestStealPrompt()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end
    local nearest, minDist = nil, math.huge
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil, math.huge end
    for _, descendant in pairs(plotsFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.ActionText == "Steal" then
            local pos = getPromptPosition(descendant)
            if pos then
                local distance = (hrp.Position - pos).Magnitude
                if distance <= descendant.MaxActivationDistance and distance < minDist then
                    minDist = distance
                    nearest = descendant
                end
            end
        end
    end
    return nearest, minDist
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsDescendantOf(workspace) then return end
    pcall(function() fireproximityprompt(prompt, 1000, math.huge) end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.03)
        prompt:InputHoldEnd()
    end)
end

local function isPlayerBase(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then return false end
    local n = obj.Name:lower()
    local p = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or n:find("claim") or p:find("base") or p:find("claim")
end

local function getClosestTarget()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local closest, shortestDistance = nil, AIMBOT_RANGE
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetHrp = plr.Character.HumanoidRootPart
            local dist = (targetHrp.Position - hrp.Position).Magnitude
            if dist <= shortestDistance then
                shortestDistance = dist
                closest = targetHrp
            end
        end
    end
    return closest
end

-- ══════════════════════════════════════════
--         AIMBOT
-- ══════════════════════════════════════════

local function stopBodyAimbot()
    if aimbotConnection then aimbotConnection:Disconnect() aimbotConnection = nil end
    if alignOri then alignOri:Destroy() alignOri = nil end
    if attach0 then attach0:Destroy() attach0 = nil end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.AutoRotate = true end
    end
end

local function startBodyAimbot()
    if aimbotConnection then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.AutoRotate = false
    attach0 = Instance.new("Attachment", hrp)
    alignOri = Instance.new("AlignOrientation")
    alignOri.Attachment0 = attach0
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.RigidityEnabled = true
    alignOri.MaxTorque = math.huge
    alignOri.Responsiveness = 200
    alignOri.Parent = hrp
    aimbotConnection = RunService.RenderStepped:Connect(function()
        local target = getClosestTarget()
        if not target then return end
        local dist = (target.Position - hrp.Position).Magnitude
        if dist > AIMBOT_DISABLE_RANGE then return end
        local lookPos = Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
        alignOri.CFrame = CFrame.lookAt(hrp.Position, lookPos)
    end)
end

-- ══════════════════════════════════════════
--         INFINITE JUMP
-- ══════════════════════════════════════════

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, JUMP_VELOCITY, hrp.AssemblyLinearVelocity.Z)
        end
    end
end)

-- ══════════════════════════════════════════
--         SPEED SYSTEM
-- ══════════════════════════════════════════

local function disableSpeed()
    if speedV2LinearVel then speedV2LinearVel:Destroy() speedV2LinearVel = nil end
    if speedV2Attachment then speedV2Attachment:Destroy() speedV2Attachment = nil end
end

local function enableSpeed()
    local activeSpeed = DisplaySpeedActive and DISPLAY_SPEED_VAL or (SpeedActive and TARGET_SPEED or 0)
    if activeSpeed == 0 then disableSpeed() return end
    disableSpeed()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hrp or not hum then return end
    speedV2Attachment = Instance.new("Attachment")
    speedV2Attachment.Name = "SpeedV2Attachment"
    speedV2Attachment.Parent = hrp
    speedV2LinearVel = Instance.new("LinearVelocity")
    speedV2LinearVel.Name = "SpeedV2LinearVel"
    speedV2LinearVel.Attachment0 = speedV2Attachment
    speedV2LinearVel.MaxForce = math.huge
    speedV2LinearVel.RelativeTo = Enum.ActuatorRelativeTo.World
    speedV2LinearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    speedV2LinearVel.MaxAxesForce = Vector3.new(math.huge, 0, math.huge)
    speedV2LinearVel.Parent = hrp
    local speedConnection
    speedConnection = RunService.Heartbeat:Connect(function()
        if not (SpeedActive or DisplaySpeedActive) or not speedV2LinearVel or not speedV2LinearVel.Parent then
            if speedConnection then speedConnection:Disconnect() end
            disableSpeed()
            return
        end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            speedV2LinearVel.VectorVelocity = Vector3.new(moveDir.X * activeSpeed, 0, moveDir.Z * activeSpeed)
        else
            speedV2LinearVel.VectorVelocity = Vector3.zero
        end
    end)
end

-- ══════════════════════════════════════════
--         RING SYSTEM
-- ══════════════════════════════════════════

local function destroyRing()
    if ringConnection then ringConnection:Disconnect() ringConnection = nil end
    if ringFolder then ringFolder:Destroy() ringFolder = nil end
    ringParts = {}
end

local function createRing()
    if not ringFolder then
        ringFolder = Instance.new("Folder", workspace)
        ringFolder.Name = "NovaRingFolder"
    end
    for _, p in ipairs(ringParts) do p:Destroy() end
    ringParts = {}
    local points = {}
    for i = 0, PartsCount - 1 do
        local angle = math.rad(i * 360 / PartsCount)
        table.insert(points, Vector3.new(math.cos(angle), 0, math.sin(angle)) * CIRCLE_RADIUS)
    end
    for i = 1, #points do
        local nextIndex = i % #points + 1
        local p1 = points[i]
        local p2 = points[nextIndex]
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CastShadow = false
        part.Size = Vector3.new((p2 - p1).Magnitude + 0.15, PART_HEIGHT, PART_THICKNESS)
        part.Color = C.RING
        part.Material = Enum.Material.Neon
        part.Transparency = RING_TRANSPARENCY
        part.Parent = ringFolder
        table.insert(ringParts, part)
    end
end

local function updateRing()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and ringFolder then
        local ringY = root.Position.Y - 1.5
        for i, part in ipairs(ringParts) do
            local angle1 = math.rad((i - 1) * 360 / PartsCount)
            local angle2 = math.rad(i * 360 / PartsCount)
            local p1 = Vector3.new(math.cos(angle1), 0, math.sin(angle1)) * CIRCLE_RADIUS
            local p2 = Vector3.new(math.cos(angle2), 0, math.sin(angle2)) * CIRCLE_RADIUS
            local center = (p1 + p2) / 2 + Vector3.new(root.Position.X, ringY, root.Position.Z)
            part.CFrame = CFrame.new(center, center + Vector3.new(p2.X - p1.X, 0, p2.Z - p1.Z)) * CFrame.Angles(0, math.pi / 2, 0)
        end
    end
end

-- ══════════════════════════════════════════
--         SPIN BOT
-- ══════════════════════════════════════════

local function stopSpin()
    if spinVelocity then spinVelocity:Destroy() spinVelocity = nil end
    RunService:UnbindFromRenderStep("SpinUpdate")
end

local function startSpin()
    stopSpin()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local attachment = hrp:FindFirstChild("SpinAttachment") or Instance.new("Attachment", hrp)
    attachment.Name = "SpinAttachment"
    spinVelocity = Instance.new("AngularVelocity")
    spinVelocity.Name = "NovaSpin"
    spinVelocity.Attachment0 = attachment
    spinVelocity.MaxTorque = math.huge
    spinVelocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    spinVelocity.Parent = hrp
    RunService:BindToRenderStep("SpinUpdate", 1, function()
        if spinBotEnabled and spinVelocity and spinVelocity.Parent then
            spinVelocity.AngularVelocity = Vector3.new(0, math.rad(spinSpeed * 10), 0)
        else
            stopSpin()
        end
    end)
end

-- ══════════════════════════════════════════
--         AUTO STEAL LOGIC
-- ══════════════════════════════════════════

local currentPrompt = nil
local currentDistance = math.huge
local lastScan = 0

RunService.Heartbeat:Connect(function()
    local now = tick()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if _G.InstaPickup then
        if now - lastScan >= 0.05 then
            currentPrompt, currentDistance = findNearestStealPrompt()
            lastScan = now
        end
        if hum and hum.WalkSpeed > 25 and currentPrompt then
            BarOuter.Visible = true
            local timeSinceLast = now - lastStealTick
            local alpha = math.clamp(timeSinceLast / stealDelay, 0, 1)
            BarFill.Size = UDim2.new(alpha, 0, 1, 0)
            if alpha < 1 then
                BarLabel.Text = string.format("RECHARGING  %.1fs", stealDelay - timeSinceLast)
            else
                BarLabel.Text = "✦ STEALING"
            end
        else
            BarOuter.Visible = false
        end
    else
        BarOuter.Visible = false
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if _G.InstaPickup then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed > 25 and currentPrompt and currentDistance <= currentPrompt.MaxActivationDistance then
                if tick() - lastStealTick >= stealDelay then
                    triggerPrompt(currentPrompt)
                    lastStealTick = tick()
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════
--         ANTI-RAGDOLL HEARTBEAT
-- ══════════════════════════════════════════

RunService.Heartbeat:Connect(function()
    if antiRagdollEnabled then
        local char = LocalPlayer.Character
        if char then
            local ragdollVal = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
            if ragdollVal and ragdollVal:IsA("BoolValue") then ragdollVal.Value = false end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end
        end
    end
end)

-- ══════════════════════════════════════════
--         PERFORMANCE / GRAPHICS
-- ══════════════════════════════════════════

local function applyLowGraphics(v)
    local char = LocalPlayer.Character
    if char and v:IsDescendantOf(char) then return end
    if optimizerEnabled then
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
        if v:IsA("BasePart") then v.Material = Enum.Material.Plastic v.Reflectance = 0 end
    end
    if noTextureEnabled then
        if v:IsA("Texture") or v:IsA("Decal") then
            if not textureData[v] then textureData[v] = v.Transparency end
            v.Transparency = 1
        elseif v:IsA("MeshPart") or v:IsA("UnionOperation") then
            if not textureData[v] then textureData[v] = v.TextureID end
            v.TextureID = ""
        elseif v:IsA("SpecialMesh") then
            if not textureData[v] then textureData[v] = v.TextureId end
            v.TextureId = ""
        end
    end
    if performanceMode then
        if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
    end
    if ultraPotato and v:IsA("BasePart") then
        if not materialCache[v] then materialCache[v] = { v.Material, v.Reflectance } end
        v.Material = Enum.Material.Plastic
        v.Reflectance = 0
    end
end

workspace.DescendantAdded:Connect(applyLowGraphics)

-- ══════════════════════════════════════════
--         BOX ESP
-- ══════════════════════════════════════════

local boxes = {}

local function createBoxESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = C.GLOW
    box.Thickness = 1.5
    box.Transparency = 1
    box.Filled = false
    local toolText = Drawing.new("Text")
    toolText.Visible = false
    toolText.Color = C.WHITE
    toolText.Size = 14
    toolText.Center = true
    toolText.Outline = true
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = C.GLOW
    distText.Size = 13
    distText.Center = true
    distText.Outline = true
    boxes[player] = { box = box, tool = toolText, dist = distText }
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if boxEspEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local size = (Camera:WorldToViewportPoint(root.Position + Vector3.new(2, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position + Vector3.new(-2, -3, 0)).Y)
                box.Size = Vector2.new(size * 0.7, size)
                box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
                box.Visible = true
                local equipped = "None"
                local characterTool = player.Character:FindFirstChildOfClass("Tool")
                if characterTool then equipped = characterTool.Name end
                toolText.Text = "[" .. equipped .. "]"
                toolText.Position = Vector2.new(pos.X, pos.Y - (box.Size.Y / 2) - 18)
                toolText.Visible = true
                if studsEnabled then
                    local char = LocalPlayer.Character
                    local lhrp = char and char:FindFirstChild("HumanoidRootPart")
                    if lhrp then
                        local d = math.floor((lhrp.Position - root.Position).Magnitude)
                        distText.Text = tostring(d) .. " studs"
                        distText.Position = Vector2.new(pos.X, pos.Y + (box.Size.Y / 2) + 5)
                        distText.Visible = true
                    end
                else
                    distText.Visible = false
                end
            else
                box.Visible = false toolText.Visible = false distText.Visible = false
            end
        else
            box.Visible = false toolText.Visible = false distText.Visible = false
            if not boxEspEnabled and connection then
                box:Remove() toolText:Remove() distText:Remove() connection:Disconnect()
            end
        end
    end)
end

-- ══════════════════════════════════════════
--         HIGHLIGHT ESP
-- ══════════════════════════════════════════

local espEnabled = false

local function createESP(player)
    if player == LocalPlayer then return end
    local function setup(character)
        if not espEnabled then return end
        local highlight = character:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = character
        highlight.FillColor = C.BG
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = C.GLOW
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        local head = character:WaitForChild("Head", 15)
        if head then
            local billboard = head:FindFirstChild("ESPNameTag") or Instance.new("BillboardGui", head)
            billboard.Name = "ESPNameTag"
            billboard.Size = UDim2.new(0, 70, 0, 18)
            billboard.StudsOffset = Vector3.new(0, 4.5, 0)
            billboard.AlwaysOnTop = true
            local frame = billboard:FindFirstChild("MainFrame") or Instance.new("Frame", billboard)
            frame.Name = "MainFrame"
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = C.PANEL
            frame.BackgroundTransparency = 0.5
            Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
            local label = frame:FindFirstChild("NameLabel") or Instance.new("TextLabel", frame)
            label.Name = "NameLabel"
            label.Size = UDim2.new(0.9, 0, 0.75, 0)
            label.Position = UDim2.new(0.05, 0, 0.12, 0)
            label.BackgroundTransparency = 1
            label.Text = player.DisplayName or player.Name
            label.TextColor3 = C.GLOW
            label.Font = Enum.Font.GothamBold
            label.TextScaled = true
        end
    end
    player.CharacterAdded:Connect(setup)
    if player.Character then setup(player.Character) end
end

local function removeESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local char = player.Character
            if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
            if char:FindFirstChild("Head") and char.Head:FindFirstChild("ESPNameTag") then char.Head.ESPNameTag:Destroy() end
        end
    end
end

-- ══════════════════════════════════════════
--         MAIN GUI CONSTRUCTION
-- ══════════════════════════════════════════

if CoreGui:FindFirstChild("NovaHub") then CoreGui.NovaHub:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NovaHub"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false

-- ── STATS OVERLAY ────────────────────────

local function createStatsUI()
    local container = Instance.new("Frame", ScreenGui)
    container.Name = "StatsDisplay"
    container.Size = UDim2.new(0, 130, 0, 44)
    container.Position = UDim2.new(0.5, -65, 0, 12)
    container.BackgroundColor3 = C.PANEL
    container.BackgroundTransparency = 0.3
    container.Visible = false
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", container)
    st.Color = C.ACCENT st.Thickness = 1.2 st.Transparency = 0.4
    local fpsLabel = Instance.new("TextLabel", container)
    fpsLabel.Size = UDim2.new(1, 0, 0.5, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = C.TEXT
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 12
    local pingLabel = Instance.new("TextLabel", container)
    pingLabel.Size = UDim2.new(1, 0, 0.5, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.5, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0ms"
    pingLabel.TextColor3 = C.GLOW
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextSize = 11
    statsLabels.container = container
    statsLabels.fps = fpsLabel
    statsLabels.ping = pingLabel
end
createStatsUI()

-- Live FPS/Ping updater
local fpsTimer = 0
local fpsCount = 0
RunService.RenderStepped:Connect(function(dt)
    fpsTimer = fpsTimer + dt
    fpsCount = fpsCount + 1
    if fpsTimer >= 0.5 then
        local fps = math.floor(fpsCount / fpsTimer)
        if statsLabels.fps then statsLabels.fps.Text = "FPS: " .. fps end
        if statsLabels.ping then
            local ping = LocalPlayer:GetNetworkPing and math.floor(LocalPlayer:GetNetworkPing() * 1000) or 0
            statsLabels.ping.Text = "Ping: " .. ping .. "ms"
        end
        fpsTimer = 0
        fpsCount = 0
    end
end)

-- ── OPEN BUTTON ──────────────────────────

local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Name = "NovaOpenBtn"
OpenBtn.Position = UDim2.new(0, 18, 0, 18)
OpenBtn.Size = UDim2.new(0, 54, 0, 54)
OpenBtn.BackgroundColor3 = C.PANEL
OpenBtn.Text = ""
OpenBtn.Draggable = true
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", OpenBtn)
openStroke.Color = C.ACCENT openStroke.Thickness = 2 openStroke.Transparency = 0.2

-- Gradient fill inside open button
local openGrad = Instance.new("UIGradient", OpenBtn)
openGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT),
    ColorSequenceKeypoint.new(1, C.ACCENT2)
})
openGrad.Rotation = 135

local openLabel = Instance.new("TextLabel", OpenBtn)
openLabel.Size = UDim2.new(1, 0, 0.55, 0)
openLabel.Position = UDim2.new(0, 0, 0.08, 0)
openLabel.BackgroundTransparency = 1
openLabel.Text = "✦"
openLabel.TextColor3 = C.WHITE
openLabel.Font = Enum.Font.GothamBold
openLabel.TextSize = 22

local openSub = Instance.new("TextLabel", OpenBtn)
openSub.Size = UDim2.new(1, 0, 0.35, 0)
openSub.Position = UDim2.new(0, 0, 0.62, 0)
openSub.BackgroundTransparency = 1
openSub.Text = "NOVA"
openSub.TextColor3 = C.WHITE
openSub.Font = Enum.Font.GothamBold
openSub.TextSize = 9

-- ── MAIN WINDOW ──────────────────────────

local Main = Instance.new("CanvasGroup", ScreenGui)
Main.Name = "Main"
Main.BackgroundColor3 = C.BG
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 500, 0, 310)
Main.GroupTransparency = 1
Main.Visible = false
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.ACCENT mainStroke.Thickness = 1.5 mainStroke.Transparency = 0.25

-- Subtle top gradient accent bar
local AccentBar = Instance.new("Frame", Main)
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.Position = UDim2.new(0, 0, 0, 0)
AccentBar.BorderSizePixel = 0
AccentBar.BackgroundColor3 = C.ACCENT
Instance.new("UIGradient", AccentBar).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT),
    ColorSequenceKeypoint.new(0.5, C.ACCENT2),
    ColorSequenceKeypoint.new(1, C.ACCENT)
})

-- ── DRAGGING ─────────────────────────────

local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ── SIDEBAR ──────────────────────────────

local Sidebar = Instance.new("Frame", Main)
Sidebar.Name = "Sidebar"
Sidebar.BackgroundColor3 = C.SIDEBAR
Sidebar.BorderSizePixel = 0
Sidebar.Size = UDim2.new(0, 130, 1, 0)

-- Side separator line
local SideLine = Instance.new("Frame", Main)
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(0, 130, 0, 0)
SideLine.BackgroundColor3 = C.ACCENT
SideLine.BorderSizePixel = 0
SideLine.BackgroundTransparency = 0.7

-- Logo area
local LogoFrame = Instance.new("Frame", Sidebar)
LogoFrame.Size = UDim2.new(1, 0, 0, 70)
LogoFrame.Position = UDim2.new(0, 0, 0, 0)
LogoFrame.BackgroundTransparency = 1

local LogoGlyph = Instance.new("TextLabel", LogoFrame)
LogoGlyph.Size = UDim2.new(1, 0, 0, 36)
LogoGlyph.Position = UDim2.new(0, 0, 0, 8)
LogoGlyph.BackgroundTransparency = 1
LogoGlyph.Text = "✦"
LogoGlyph.TextColor3 = C.ACCENT
LogoGlyph.Font = Enum.Font.GothamBold
LogoGlyph.TextSize = 28

local LogoTitle = Instance.new("TextLabel", LogoFrame)
LogoTitle.Size = UDim2.new(1, 0, 0, 18)
LogoTitle.Position = UDim2.new(0, 0, 0, 44)
LogoTitle.BackgroundTransparency = 1
LogoTitle.Text = "NOVA HUB"
LogoTitle.TextColor3 = C.TEXT
LogoTitle.Font = Enum.Font.GothamBold
LogoTitle.TextSize = 11

-- Divider under logo
local SideDiv = Instance.new("Frame", Sidebar)
SideDiv.Size = UDim2.new(0.75, 0, 0, 1)
SideDiv.Position = UDim2.new(0.125, 0, 0, 70)
SideDiv.BackgroundColor3 = C.ACCENT
SideDiv.BackgroundTransparency = 0.6
SideDiv.BorderSizePixel = 0

-- Profile bubble
local ProfileBubble = Instance.new("Frame", Sidebar)
ProfileBubble.BackgroundColor3 = C.CARD
ProfileBubble.Position = UDim2.new(0.5, -52, 1, -52)
ProfileBubble.Size = UDim2.new(0, 105, 0, 40)
Instance.new("UICorner", ProfileBubble).CornerRadius = UDim.new(0, 10)
local profStroke = Instance.new("UIStroke", ProfileBubble)
profStroke.Color = C.ACCENT profStroke.Thickness = 1 profStroke.Transparency = 0.6

local PlayerIcon = Instance.new("ImageLabel", ProfileBubble)
PlayerIcon.Position = UDim2.new(0, 6, 0.5, -14)
PlayerIcon.Size = UDim2.new(0, 28, 0, 28)
PlayerIcon.BackgroundTransparency = 1
PlayerIcon.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
Instance.new("UICorner", PlayerIcon).CornerRadius = UDim.new(1, 0)

local PlayerName = Instance.new("TextLabel", ProfileBubble)
PlayerName.Position = UDim2.new(0, 40, 0, 4)
PlayerName.Size = UDim2.new(0, 62, 0, 14)
PlayerName.BackgroundTransparency = 1
PlayerName.Font = Enum.Font.GothamBold
PlayerName.Text = LocalPlayer.DisplayName
PlayerName.TextColor3 = C.TEXT
PlayerName.TextSize = 9
PlayerName.TextXAlignment = Enum.TextXAlignment.Left
PlayerName.ClipsDescendants = true

local PlayerRole = Instance.new("TextLabel", ProfileBubble)
PlayerRole.Position = UDim2.new(0, 40, 0, 19)
PlayerRole.Size = UDim2.new(0, 62, 0, 13)
PlayerRole.BackgroundTransparency = 1
PlayerRole.Font = Enum.Font.Gotham
PlayerRole.Text = "Nova User"
PlayerRole.TextColor3 = C.GLOW
PlayerRole.TextSize = 8
PlayerRole.TextXAlignment = Enum.TextXAlignment.Left

-- ── TAB SYSTEM ───────────────────────────

local Pages = {}
local TabContainer = Instance.new("Frame", Sidebar)
TabContainer.BackgroundTransparency = 1
TabContainer.Position = UDim2.new(0, 0, 0, 75)
TabContainer.Size = UDim2.new(1, 0, 1, -130)

local TabList = Instance.new("UIListLayout", TabContainer)
TabList.Padding = UDim.new(0, 6)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", TabContainer).PaddingTop = UDim.new(0, 10)

local currentTab = nil

local function ShowPage(name)
    for pageName, frame in pairs(Pages) do
        frame.Visible = (pageName == name)
    end
    currentTab = name
end

local function CreatePage(name)
    local PageFrame = Instance.new("ScrollingFrame", Main)
    PageFrame.Name = name .. "Page"
    PageFrame.BackgroundTransparency = 1
    PageFrame.Position = UDim2.new(0, 140, 0, 12)
    PageFrame.Size = UDim2.new(1, -148, 1, -20)
    PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PageFrame.ScrollBarThickness = 2
    PageFrame.ScrollBarImageColor3 = C.ACCENT
    PageFrame.Visible = false
    local Grid = Instance.new("UIGridLayout", PageFrame)
    Grid.CellPadding = UDim2.new(0, 8, 0, 8)
    Grid.CellSize = UDim2.new(0, 163, 0, 38)
    Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PageFrame.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 12)
    end)
    local Pad = Instance.new("UIPadding", PageFrame)
    Pad.PaddingTop = UDim.new(0, 4)
    Pad.PaddingLeft = UDim.new(0, 2)
    Pages[name] = PageFrame
    return PageFrame
end

local tabBtns = {}

local function AddTabBtn(name, icon)
    local Tab = Instance.new("TextButton", TabContainer)
    Tab.Size = UDim2.new(0, 110, 0, 34)
    Tab.BackgroundColor3 = C.CARD
    Tab.BorderSizePixel = 0
    Tab.Text = ""
    Tab.AutoButtonColor = false
    Instance.new("UICorner", Tab).CornerRadius = UDim.new(0, 9)

    local tabLabel = Instance.new("TextLabel", Tab)
    tabLabel.Size = UDim2.new(1, -8, 1, 0)
    tabLabel.Position = UDim2.new(0, 8, 0, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Text = (icon or "") .. "  " .. name
    tabLabel.Font = Enum.Font.GothamMedium
    tabLabel.TextSize = 12
    tabLabel.TextColor3 = C.SUBTEXT
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left

    local tabAccent = Instance.new("Frame", Tab)
    tabAccent.Size = UDim2.new(0, 3, 0.6, 0)
    tabAccent.Position = UDim2.new(0, 0, 0.2, 0)
    tabAccent.BackgroundColor3 = C.ACCENT
    tabAccent.BorderSizePixel = 0
    tabAccent.BackgroundTransparency = 1
    Instance.new("UICorner", tabAccent).CornerRadius = UDim.new(0, 2)

    tabBtns[name] = { btn = Tab, label = tabLabel, accent = tabAccent }

    Tab.MouseButton1Click:Connect(function()
        ShowPage(name)
        for tabName, tbl in pairs(tabBtns) do
            local active = (tabName == name)
            Tween(tbl.btn, { BackgroundColor3 = active and C.CARD_HOVER or C.CARD }, 0.15)
            tbl.label.TextColor3 = active and C.TEXT or C.SUBTEXT
            tbl.label.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
            Tween(tbl.accent, { BackgroundTransparency = active and 0 or 1 }, 0.15)
        end
    end)
end

-- ── CLOSE BUTTON ─────────────────────────

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -26, 0, 8)
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.SUBTEXT
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 10
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = C.DANGER end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = C.SUBTEXT end)

-- ── ANIMATION TOGGLE ─────────────────────

local function AnimationToggle()
    if not Main.Visible then
        Main.Visible = true
        Main.Size = UDim2.new(0, 350, 0, 200)
        Main.GroupTransparency = 1
        Tween(Main, { Size = UDim2.new(0, 500, 0, 310), GroupTransparency = 0 }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        OpenBtn.Visible = false
    else
        local close = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 350, 0, 200),
            GroupTransparency = 1
        })
        close:Play()
        close.Completed:Connect(function() Main.Visible = false OpenBtn.Visible = true end)
    end
end

OpenBtn.MouseButton1Click:Connect(AnimationToggle)
CloseBtn.MouseButton1Click:Connect(AnimationToggle)

-- ── TOGGLE COMPONENT ─────────────────────

local SpeedToggleFn = nil

local function AddToggle(pageName, name, callback)
    local page = Pages[pageName]

    local TFrame = Instance.new("Frame", page)
    TFrame.BackgroundColor3 = C.CARD
    TFrame.BorderSizePixel = 0
    Instance.new("UICorner", TFrame).CornerRadius = UDim.new(0, 9)
    local tStroke = Instance.new("UIStroke", TFrame)
    tStroke.Color = C.ACCENT tStroke.Thickness = 1 tStroke.Transparency = 0.82

    local TLabel = Instance.new("TextLabel", TFrame)
    TLabel.BackgroundTransparency = 1
    TLabel.Position = UDim2.new(0, 10, 0, 0)
    TLabel.Size = UDim2.new(0.65, 0, 1, 0)
    TLabel.Font = Enum.Font.GothamMedium
    TLabel.Text = name
    TLabel.TextColor3 = C.TEXT
    TLabel.TextSize = 10
    TLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Pill toggle
    local PillBG = Instance.new("TextButton", TFrame)
    PillBG.Position = UDim2.new(1, -44, 0.5, -10)
    PillBG.Size = UDim2.new(0, 36, 0, 20)
    PillBG.BackgroundColor3 = C.OFF
    PillBG.Text = ""
    PillBG.AutoButtonColor = false
    Instance.new("UICorner", PillBG).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", PillBG)
    Knob.BackgroundColor3 = C.WHITE
    Knob.Position = UDim2.new(0, 3, 0.5, -7)
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local enabled = false

    local function updateUI(state)
        enabled = state
        if enabled then
            Tween(PillBG, { BackgroundColor3 = C.ON }, 0.18)
            Knob:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
            Tween(tStroke, { Transparency = 0.4 }, 0.18)
            Tween(TLabel, { TextColor3 = C.TEXT }, 0.15)
        else
            Tween(PillBG, { BackgroundColor3 = C.OFF }, 0.18)
            Knob:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
            Tween(tStroke, { Transparency = 0.82 }, 0.18)
            Tween(TLabel, { TextColor3 = C.SUBTEXT }, 0.15)
        end
    end

    -- Whole card is clickable
    TFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            enabled = not enabled
            updateUI(enabled)
            callback(enabled)
        end
    end)
    PillBG.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateUI(enabled)
        callback(enabled)
    end)

    if name == "Speed Boost" then SpeedToggleFn = updateUI end

    return updateUI
end

-- ── SLIDER COMPONENT ─────────────────────

local function AddSlider(pageName, name, min, max, callback)
    local page = Pages[pageName]

    local SFrame = Instance.new("Frame", page)
    SFrame.BackgroundColor3 = C.CARD
    SFrame.BorderSizePixel = 0
    Instance.new("UICorner", SFrame).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", SFrame).Color = C.ACCENT

    local SLabel = Instance.new("TextLabel", SFrame)
    SLabel.BackgroundTransparency = 1
    SLabel.Position = UDim2.new(0, 10, 0, 4)
    SLabel.Size = UDim2.new(0.7, 0, 0, 14)
    SLabel.Font = Enum.Font.GothamMedium
    SLabel.Text = name
    SLabel.TextColor3 = C.SUBTEXT
    SLabel.TextSize = 9
    SLabel.TextXAlignment = Enum.TextXAlignment.Left

    local SValue = Instance.new("TextLabel", SFrame)
    SValue.BackgroundTransparency = 1
    SValue.Position = UDim2.new(1, -36, 0, 4)
    SValue.Size = UDim2.new(0, 30, 0, 14)
    SValue.Font = Enum.Font.GothamBold
    SValue.Text = tostring(min)
    SValue.TextColor3 = C.GLOW
    SValue.TextSize = 9

    local TrackBG = Instance.new("Frame", SFrame)
    TrackBG.BackgroundColor3 = C.OFF
    TrackBG.Position = UDim2.new(0, 10, 0.68, -2)
    TrackBG.Size = UDim2.new(1, -20, 0, 4)
    Instance.new("UICorner", TrackBG).CornerRadius = UDim.new(1, 0)

    local TrackFill = Instance.new("Frame", TrackBG)
    TrackFill.BackgroundColor3 = C.ACCENT
    TrackFill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", TrackFill).CornerRadius = UDim.new(1, 0)
    local fillGrad = Instance.new("UIGradient", TrackFill)
    fillGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.ACCENT), ColorSequenceKeypoint.new(1, C.ACCENT2) })

    local Thumb = Instance.new("Frame", TrackBG)
    Thumb.BackgroundColor3 = C.WHITE
    Thumb.Size = UDim2.new(0, 10, 0, 10)
    Thumb.Position = UDim2.new(0, -5, 0.5, -5)
    Thumb.ZIndex = 5
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

    local ClickArea = Instance.new("TextButton", TrackBG)
    ClickArea.BackgroundTransparency = 1
    ClickArea.Size = UDim2.new(1, 0, 5, 0)
    ClickArea.Position = UDim2.new(0, 0, -2, 0)
    ClickArea.Text = ""

    local function updateSlider()
        local inputPos = UserInputService:GetMouseLocation().X - TrackBG.AbsolutePosition.X
        local pct = math.clamp(inputPos / TrackBG.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pct)
        TrackFill.Size = UDim2.new(pct, 0, 1, 0)
        Thumb.Position = UDim2.new(pct, -5, 0.5, -5)
        SValue.Text = tostring(value)
        callback(value)
    end

    local sliding = false
    ClickArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true updateSlider()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider()
        end
    end)
end

-- ══════════════════════════════════════════
--         CREATE TABS
-- ══════════════════════════════════════════

local tabDefs = {
    { "Duel",   "⚔" },
    { "Player", "👤" },
    { "ESP",    "👁" },
}

for _, t in ipairs(tabDefs) do
    CreatePage(t[1])
    AddTabBtn(t[1], t[2])
end

-- Open first tab
ShowPage("Duel")
if tabBtns["Duel"] then
    tabBtns["Duel"].label.TextColor3 = C.TEXT
    tabBtns["Duel"].label.Font = Enum.Font.GothamBold
    tabBtns["Duel"].accent.BackgroundTransparency = 0
    tabBtns["Duel"].btn.BackgroundColor3 = C.CARD_HOVER
end

-- ══════════════════════════════════════════
--         DUEL TOGGLES
-- ══════════════════════════════════════════

local autoBatConnection
AddToggle("Duel", "Auto Bat", function(state)
    if state then
        autoBatConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local bat = char:FindFirstChild("Bat")
            if not bat then
                local bp = LocalPlayer.Backpack:FindFirstChild("Bat")
                if bp then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:EquipTool(bp) end
                    bat = bp
                end
            end
            if bat then bat:Activate() end
        end)
    else
        if autoBatConnection then autoBatConnection:Disconnect() autoBatConnection = nil end
    end
end)

AddToggle("Duel", "Aimbot", function(state)
    aimbotEnabled = state
    if state then startBodyAimbot() else stopBodyAimbot() end
end)

AddToggle("Duel", "Auto Walk", function(state)
    autoWalkEnabled = state
    if state then
        autoWalkConnection = RunService.Heartbeat:Connect(function()
            if not autoWalkEnabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local target = getClosestTarget()
                if target then hum:MoveTo(target.Position) end
            end
        end)
    else
        if autoWalkConnection then autoWalkConnection:Disconnect() autoWalkConnection = nil end
    end
end)

AddToggle("Duel", "Locked Person", function(state) end)

-- ══════════════════════════════════════════
--         PLAYER TOGGLES / SLIDERS
-- ══════════════════════════════════════════

AddSlider("Player", "Spin Bot Speed", 0, 100, function(v) spinSpeed = v end)
AddSlider("Player", "Ring Radius", 0, 45, function(v)
    CIRCLE_RADIUS = v
    if ringFolder then createRing() end
end)
AddSlider("Player", "FOV", 70, 120, function(v) Camera.FieldOfView = v end)

AddToggle("Player", "Anti Ragdoll", function(state) antiRagdollEnabled = state end)
AddToggle("Player", "Auto Steal", function(state) _G.InstaPickup = state end)
AddToggle("Player", "Spin Bot", function(state)
    spinBotEnabled = state
    if state then startSpin() else stopSpin() end
end)
AddToggle("Player", "No Animation", function(state)
    noAnimEnabled = state
    local char = LocalPlayer.Character
    local animate = char and char:FindFirstChild("Animate")
    if noAnimEnabled then
        if animate then animate.Disabled = true end
    else
        if animate then animate.Disabled = false end
    end
end)
AddToggle("Player", "Ring Effect", function(state)
    if state then
        createRing()
        ringConnection = RunService.Heartbeat:Connect(updateRing)
    else
        destroyRing()
    end
end)
AddToggle("Player", "Infinite Jump", function(state) infiniteJumpEnabled = state end)
AddToggle("Player", "Zero Gravity", function(state)
    zeroGravEnabled = state
    workspace.Gravity = state and 0 or originalGravity
end)
AddToggle("Player", "Display Speed", function(state)
    DisplaySpeedActive = state
    if state then enableSpeed() else disableSpeed() end
end)
AddToggle("Player", "Speed Boost", function(state)
    SpeedActive = state
    if state then enableSpeed() else disableSpeed() end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == ToggleKey then
        SpeedActive = not SpeedActive
        if SpeedToggleFn then SpeedToggleFn(SpeedActive) end
        if SpeedActive then enableSpeed() else disableSpeed() end
    end
end)

-- ══════════════════════════════════════════
--         ESP TOGGLES
-- ══════════════════════════════════════════

AddToggle("ESP", "Hitbox Expander", function(state)
    hitboxEnabled = state
    if state then
        RunService:BindToRenderStep("HitboxExpander", 1, function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    hrp.Size = expandedSize hrp.Transparency = 0.6 hrp.CanCollide = false
                end
            end
        end)
    else
        RunService:UnbindFromRenderStep("HitboxExpander")
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1) hrp.Transparency = 1 hrp.CanCollide = true
            end
        end
    end
end)

AddToggle("ESP", "ESP Player", function(state)
    espEnabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
    else
        removeESP()
    end
end)

AddToggle("ESP", "Box ESP", function(state)
    boxEspEnabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do createBoxESP(player) end
    end
end)

AddToggle("ESP", "Studs Distance", function(state) studsEnabled = state end)

AddToggle("ESP", "Ping & FPS", function(state)
    statsEnabled = state
    if statsLabels.container then statsLabels.container.Visible = state end
end)

AddToggle("ESP", "Overclock FPS", function(state)
    if state then
        setfpscap(999)
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    else
        setfpscap(60)
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Default
    end
end)

AddToggle("ESP", "FPS Boost", function(state)
    if state then
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
        settings().Rendering.QualityLevel = 1
    else
        settings().Rendering.QualityLevel = originalSettings.QualityLevel
    end
end)

AddToggle("ESP", "Low Graphics", function(state)
    if state then
        optimizerEnabled = true performanceMode = true
        Lighting.GlobalShadows = false
    end
end)

AddToggle("ESP", "High Graphics", function(state)
    if state then
        optimizerEnabled = false performanceMode = false
        Lighting.GlobalShadows = true
        settings().Rendering.QualityLevel = 21
        Lighting.Brightness = 3
    end
end)

AddToggle("ESP", "High Quality", function(state)
    if state then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.Glass end
        end
    end
end)

AddToggle("ESP", "Smooth Mesh", function(state)
    if state then
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.DistanceBased
    else
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end
end)

AddToggle("ESP", "Blue Space Sky", function(state)
    if state then
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.SkyboxBk = "rbxassetid://159454299"
        sky.SkyboxDn = "rbxassetid://159454296"
        sky.SkyboxFt = "rbxassetid://159454293"
        sky.SkyboxLf = "rbxassetid://159454286"
        sky.SkyboxRt = "rbxassetid://159454300"
        sky.SkyboxUp = "rbxassetid://159454282"
        sky.StarCount = 5000
        Lighting.FogColor = Color3.fromRGB(0, 0, 50)
    else
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then sky:Destroy() end
    end
end)

AddToggle("ESP", "Optimizer", function(state)
    optimizerEnabled = state
    if state then
        Lighting.GlobalShadows = false Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        if not moonlightActive then
            Lighting.Brightness = 0
            Lighting.Ambient = Color3.fromRGB(160, 160, 160)
            Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
        end
        for _, v in pairs(workspace:GetDescendants()) do applyLowGraphics(v) end
    else
        Lighting.GlobalShadows = originalSettings.GlobalShadows
        Lighting.FogEnd = noFogEnabled and 9e9 or originalSettings.FogEnd
        settings().Rendering.QualityLevel = originalSettings.QualityLevel
    end
end)

AddToggle("ESP", "No Texture", function(state)
    noTextureEnabled = state
    if state then
        for _, v in pairs(workspace:GetDescendants()) do applyLowGraphics(v) end
    else
        for obj, originalVal in pairs(textureData) do
            if obj and obj.Parent then
                pcall(function()
                    if obj:IsA("Texture") or obj:IsA("Decal") then obj.Transparency = originalVal
                    elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") then obj.TextureID = originalVal
                    elseif obj:IsA("SpecialMesh") then obj.TextureId = originalVal end
                end)
            end
        end
        textureData = {}
    end
end)

AddToggle("ESP", "Performance Mode", function(state)
    performanceMode = state
    if state then
        settings().Rendering.QualityLevel = 1
        for _, v in pairs(workspace:GetDescendants()) do applyLowGraphics(v) end
    else
        settings().Rendering.QualityLevel = originalSettings.QualityLevel
    end
end)

AddToggle("ESP", "Ultra Potato", function(state)
    ultraPotato = state
    if state then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                if not materialCache[v] then materialCache[v] = { v.Material, v.Reflectance } end
                v.Material = Enum.Material.Plastic v.Reflectance = 0
            end
        end
    else
        for part, data in pairs(materialCache) do
            if part and part.Parent then part.Material = data[1] part.Reflectance = data[2] end
        end
        materialCache = {}
    end
end)

AddToggle("ESP", "X-Ray", function(state)
    xrayEnabled = state
    for _, obj in pairs(workspace:GetDescendants()) do
        if isPlayerBase(obj) and not obj:IsDescendantOf(LocalPlayer.Character) then
            if xrayEnabled then
                if not originalTransparencies[obj] then originalTransparencies[obj] = obj.Transparency end
                obj.Transparency = 0.5
            else
                if originalTransparencies[obj] then obj.Transparency = originalTransparencies[obj] end
            end
        end
    end
end)

AddToggle("ESP", "Moonlight Sky", function(state)
    moonlightActive = state
    if moonlightConnection then moonlightConnection:Disconnect() moonlightConnection = nil end
    if state then
        moonlightConnection = RunService.RenderStepped:Connect(function()
            if not moonlightActive then moonlightConnection:Disconnect() return end
            Lighting.ClockTime = 0 Lighting.Brightness = 1.2
            Lighting.OutdoorAmbient = Color3.fromRGB(50, 65, 110)
            Lighting.Ambient = Color3.fromRGB(35, 45, 75)
            Lighting.ColorShift_Top = Color3.fromRGB(170, 190, 255)
            Lighting.GlobalShadows = false
        end)
    else
        Lighting.ClockTime = originalSettings.ClockTime
        Lighting.Brightness = fullBrightEnabled and 2 or originalSettings.Brightness
        Lighting.OutdoorAmbient = originalSettings.OutdoorAmbient
        Lighting.Ambient = originalSettings.Ambient
        Lighting.ColorShift_Top = originalSettings.ColorShift_Top
        Lighting.GlobalShadows = not fullBrightEnabled and originalSettings.GlobalShadows or false
    end
end)

AddToggle("ESP", "Full Bright", function(state)
    fullBrightEnabled = state
    if state then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalSettings.Brightness
        Lighting.Ambient = originalSettings.Ambient
        Lighting.OutdoorAmbient = originalSettings.OutdoorAmbient
        Lighting.GlobalShadows = originalSettings.GlobalShadows
    end
end)

AddToggle("ESP", "No Fog", function(state)
    noFogEnabled = state
    Lighting.FogEnd = state and 9e9 or originalSettings.FogEnd
    Lighting.FogStart = state and 9e9 or originalSettings.FogStart
end)

-- ══════════════════════════════════════════
--         PLAYER ADDED / REMOVED HANDLERS
-- ══════════════════════════════════════════

Players.PlayerAdded:Connect(function(plr)
    if espEnabled then createESP(plr) end
    if boxEspEnabled then createBoxESP(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
    if boxes[plr] then
        if boxes[plr].box then boxes[plr].box:Remove() end
        if boxes[plr].tool then boxes[plr].tool:Remove() end
        if boxes[plr].dist then boxes[plr].dist:Remove() end
        boxes[plr] = nil
    end
end)

-- ══════════════════════════════════════════
-- Nova Hub loaded! Press the ✦ button to open.
-- ══════════════════════════════════════════
