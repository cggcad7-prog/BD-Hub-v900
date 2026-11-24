--[[ BD Hub Part 1/2: Light UI + FOV + Toggles ]]
if getgenv().BDHub_V3_Loaded then
    warn("BD Hub is already running!")
    return
end
getgenv().BDHub_V3_Loaded = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local EmbeddedSystem = {
    Active = true,
    Initialized = os.clock()
}
getgenv().BDHub_EmbeddedSystem = EmbeddedSystem

local CONFIG = {
    MASTER_COMBAT = false,
    FOV_RADIUS = 250,
    FOV_MODE = "Center",
    CAM_AIMBOT = false,
    CAM_SMOOTHNESS = 1,
    BULLET_TRACK = true,
    CHAR_LOOKAT = false,
    BOX_ESP = false,
    SNAPLINE_ESP = false,
    HEALTHBAR_ESP = false,
    CUBIC_CURVE = true
}
getgenv().BDHub_CONFIG = CONFIG
getgenv().BDHub_State = {
    lockedTarget = nil,
    currentTargetHead = nil,
    currentTargetChar = nil
}

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "BD Hub",
    Icon = "hammer",
    Author = "by BD Team",
    Folder = "BDHub_NoSave",
    Size = UDim2.fromOffset(550, 420),
    MinSize = Vector2.new(480, 320),
    MaxSize = Vector2.new(800, 520),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    Draggable = true,
    SideBarWidth = 185,
    HideSearchBar = true,
    ScrollBarEnabled = true
})

local parentGui
pcall(function()
    if gethui then
        local h = gethui()
        if h then parentGui = h end
    end
end)
parentGui = parentGui or LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("BD_FOV_V3") then
    parentGui.BD_FOV_V3:Destroy()
end

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "BD_FOV_V3"
fovGui.IgnoreGuiInset = true
fovGui.ResetOnSpawn = false
fovGui.DisplayOrder = 999
fovGui.Parent = parentGui

local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOVCircle"
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Size = UDim2.fromOffset(CONFIG.FOV_RADIUS * 2, CONFIG.FOV_RADIUS * 2)
fovFrame.BackgroundTransparency = 1
fovFrame.Visible = false
fovFrame.Parent = fovGui

Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Thickness = 2.5
fovStroke.Transparency = 0.05

local fovGradient = Instance.new("UIGradient", fovStroke)
fovGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(238, 130, 238))
})
getgenv().BDHub_FOVFrame = fovFrame
getgenv().BDHub_FOVGradient = fovGradient

local AimbotTab = Window:Tab({ Title = "Aimbot", Icon = "crosshair" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

AimbotTab:Section({ Title = "Combat Controls" })

AimbotTab:Toggle({
    Title = "Combat Master Toggle (FOV + Active)",
    Default = false,
    Callback = function(v)
        CONFIG.MASTER_COMBAT = v
        fovFrame.Visible = v
        if not v then
            getgenv().BDHub_State.lockedTarget = nil
            getgenv().BDHub_State.currentTargetHead = nil
            getgenv().BDHub_State.currentTargetChar = nil
        end
    end
})

AimbotTab:Toggle({
    Title = "Camera Lock Head (FOV)",
    Default = false,
    Callback = function(v)
        CONFIG.CAM_AIMBOT = v
    end
})

AimbotTab:Toggle({
    Title = "Bullet Tracking (Lock Until Dead)",
    Default = true,
    Callback = function(v)
        CONFIG.BULLET_TRACK = v
    end
})

AimbotTab:Toggle({
    Title = "Cubic Curve Trajectory",
    Default = true,
    Callback = function(v)
        CONFIG.CUBIC_CURVE = v
    end
})

AimbotTab:Toggle({
    Title = "Character LookAt Target",
    Default = false,
    Callback = function(v)
        CONFIG.CHAR_LOOKAT = v
    end
})

AimbotTab:Dropdown({
    Title = "FOV Position Mode",
    Values = { "Center", "Mouse" },
    Default = "Center",
    Callback = function(v)
        CONFIG.FOV_MODE = v
    end
})

AimbotTab:Dropdown({
    Title = "FOV Radius Size",
    Values = { "150", "200", "250", "300", "400" },
    Default = "250",
    Callback = function(v)
        local num = tonumber(v)
        if num then
            CONFIG.FOV_RADIUS = num
            fovFrame.Size = UDim2.fromOffset(num * 2, num * 2)
        end
    end
})

VisualsTab:Section({ Title = "ESP Controls" })

VisualsTab:Toggle({
    Title = "Box ESP",
    Default = false,
    Callback = function(v)
        CONFIG.BOX_ESP = v
    end
})

VisualsTab:Toggle({
    Title = "Snaplines",
    Default = false,
    Callback = function(v)
        CONFIG.SNAPLINE_ESP = v
    end
})

VisualsTab:Toggle({
    Title = "Health Bar ESP",
    Default = false,
    Callback = function(v)
        CONFIG.HEALTHBAR_ESP = v
    end
})

--[[ BD Hub Part 2/2: Target Lock + Instant Camera Head Aim + Wall-Check LookAt + CubicCurve + ESP ]]
local RunService = game:GetService("RunService")

local CONFIG = getgenv().BDHub_CONFIG
local STATE = getgenv().BDHub_State
local fovFrame = getgenv().BDHub_FOVFrame
local fovGradient = getgenv().BDHub_FOVGradient

if not CONFIG or not STATE then
    warn("BD Hub Part 1 missing!")
    return
end

local ESPCache = {}
local hasDrawing = pcall(function() return Drawing and Drawing.new end)
local savedAutoRotate = nil

local function resolveCurvesModule()
    if type(CurvesModule) == "table" and type(CurvesModule.CubicCurve1) == "function" then
        return CurvesModule
    end
    if type(getgenv().CurvesModule) == "table" and type(getgenv().CurvesModule.CubicCurve1) == "function" then
        return getgenv().CurvesModule
    end
    return nil
end

local function triggerCubicCurve(Effect, Explosion, Args)
    if not (CONFIG.MASTER_COMBAT and CONFIG.CUBIC_CURVE) then return end
    local mod = resolveCurvesModule()
    if not mod or type(mod.CubicCurve1) ~= "function" then return end

    pcall(function()
        local originPos = (Explosion and typeof(Explosion) == "Instance" and Explosion:IsA("BasePart") and Explosion.Position)
            or (Explosion and type(Explosion) == "table" and typeof(Explosion.Position) == "Vector3" and Explosion.Position)
            or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position)
            or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
            or Vector3.zero

        local aimPos = (STATE.currentTargetHead and STATE.currentTargetHead.Parent and STATE.currentTargetHead.Position)
            or (Args and Args.MouseHit and typeof(Args.MouseHit) == "CFrame" and Args.MouseHit.Position)
            or (Args and Args.MouseHit and typeof(Args.MouseHit) == "Vector3" and Args.MouseHit)
            or (Mouse and Mouse.Hit and Mouse.Hit.Position)
            or originPos

        local rot = (Args and Args.Rotation) or CFrame.lookAt(originPos, aimPos)
        local expRef = Explosion or { Position = originPos }
        local argsRef = Args or { MouseHit = CFrame.new(aimPos), Rotation = rot }
        if typeof(argsRef.MouseHit) == "Vector3" then
            argsRef.MouseHit = CFrame.new(argsRef.MouseHit)
        elseif not argsRef.MouseHit then
            argsRef.MouseHit = CFrame.new(aimPos)
        end
        if not argsRef.Rotation then
            argsRef.Rotation = rot
        end

        CurvesModule = mod
        local ExplosionRef = expRef
        local ArgsRef = argsRef
        CurvesModule.CubicCurve1(Effect, ExplosionRef.Position, ArgsRef.MouseHit.Position, ArgsRef.Rotation, 200, 1, true, function(bullet)

        end)
    end)
end
getgenv().BDHub_RunCubicCurve = triggerCubicCurve

local function restoreAutoRotate(hum)
    pcall(function()
        if hum and hum.Parent and savedAutoRotate ~= nil then
            hum.AutoRotate = savedAutoRotate
            savedAutoRotate = nil
        end
    end)
end

local function hasClearLineOfSight(originPos, targetPos, myChar, targetChar)
    local ok, isClear = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {}
        if myChar then table.insert(filterList, myChar) end
        if targetChar then table.insert(filterList, targetChar) end
        params.FilterDescendantsInstances = filterList

        local delta = targetPos - originPos
        if delta.Magnitude <= 0.05 then
            return true
        end

        local result = workspace:Raycast(originPos, delta, params)
        return result == nil
    end)
    return ok and isClear
end

local function clearESP(plr)
    pcall(function()
        local entry = ESPCache[plr]
        if entry then
            for _, obj in pairs(entry) do
                if obj and obj.Remove then
                    obj:Remove()
                end
            end
            ESPCache[plr] = nil
        end
        if STATE.lockedTarget == plr then
            STATE.lockedTarget = nil
            STATE.currentTargetHead = nil
            STATE.currentTargetChar = nil
        end
    end)
end

Players.PlayerRemoving:Connect(clearESP)
LocalPlayer.CharacterAdded:Connect(function(char)
    STATE.lockedTarget = nil
    STATE.currentTargetHead = nil
    STATE.currentTargetChar = nil
    savedAutoRotate = nil
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if hum then
        savedAutoRotate = hum.AutoRotate
    end
end)

local function getRefPos(cam)
    if not cam then return Vector2.new(0, 0) end
    if CONFIG.FOV_MODE == "Mouse" and Mouse then
        return Vector2.new(Mouse.X, Mouse.Y + 36)
    end
    return Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
end

local function isHeadValidInFOV(cam, plr, refPos, radius)
    if not cam or not plr or plr == LocalPlayer then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not (hum and hum.Health > 0 and head and head:IsA("BasePart")) then return false end

    local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
    if not onScreen or screenPos.Z <= 0 then return false end

    local dist = (Vector2.new(screenPos.X, screenPos.Y) - refPos).Magnitude
    return dist <= radius, head, dist, char
end

local function acquireTarget(cam, refPos)
    if not cam then return nil, nil, nil end
    local radius = CONFIG.FOV_RADIUS

    if STATE.lockedTarget then
        local ok, head, _, char = isHeadValidInFOV(cam, STATE.lockedTarget, refPos, radius)
        if ok and head then
            return head, STATE.lockedTarget, char
        end
        STATE.lockedTarget = nil
    end

    local closestDist = radius
    local bestHead, bestPlr, bestChar = nil, nil, nil

    for _, plr in ipairs(Players:GetPlayers()) do
        local ok, head, dist, char = isHeadValidInFOV(cam, plr, refPos, radius)
        if ok and head and dist < closestDist then
            closestDist = dist
            bestHead = head
            bestPlr = plr
            bestChar = char
        end
    end

    STATE.lockedTarget = bestPlr
    return bestHead, STATE.lockedTarget, bestChar
end

local accTime = 0
RunService.Heartbeat:Connect(function(dt)
    accTime += (dt or 0.03)
    if accTime < 0.03 then return end
    accTime = 0

    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local refPos = getRefPos(cam)
        if fovFrame then
            fovFrame.Visible = CONFIG.MASTER_COMBAT
            if CONFIG.FOV_MODE == "Mouse" and Mouse then
                fovFrame.Position = UDim2.fromOffset(Mouse.X, Mouse.Y + 36)
            else
                fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
            if fovGradient then
                fovGradient.Rotation = (tick() * 45) % 360
            end
        end

        local targetHead, currentPlr, targetChar = nil, nil, nil
        if CONFIG.MASTER_COMBAT then
            targetHead, currentPlr, targetChar = acquireTarget(cam, refPos)
            STATE.currentTargetHead = targetHead
            STATE.currentTargetChar = targetChar
        else
            STATE.lockedTarget = nil
            STATE.currentTargetHead = nil
            STATE.currentTargetChar = nil
        end

        -- หันกล้องไปหาตำแหน่งหัวของเป้าหมายในวง FOV ทันที
        if CONFIG.MASTER_COMBAT and CONFIG.CAM_AIMBOT and targetHead and targetHead.Parent then
            local camPos = cam.CFrame.Position
            cam.CFrame = CFrame.lookAt(camPos, targetHead.Position)
        end

        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

        local canLookAt = false
        if CONFIG.MASTER_COMBAT and CONFIG.CHAR_LOOKAT and targetHead and myHrp and myHum and myHum.Health > 0 then
            local checkOrigin = Vector3.new(myHrp.Position.X, myHrp.Position.Y + 1.5, myHrp.Position.Z)
            local checkGoal = Vector3.new(targetHead.Position.X, targetHead.Position.Y, targetHead.Position.Z)
            if hasClearLineOfSight(checkOrigin, checkGoal, myChar, targetChar) then
                canLookAt = true
            end
        end

        if canLookAt then
            if savedAutoRotate == nil then
                savedAutoRotate = myHum.AutoRotate
            end
            myHum.AutoRotate = false

            local lookPos = Vector3.new(targetHead.Position.X, myHrp.Position.Y, targetHead.Position.Z)
            if (lookPos - myHrp.Position).Magnitude > 0.1 then
                local currentPos = myHrp.Position
                local currentVel = myHrp.AssemblyLinearVelocity
                myHrp.CFrame = CFrame.lookAt(currentPos, lookPos)
                myHrp.AssemblyLinearVelocity = currentVel
            end
        elseif myHum then
            restoreAutoRotate(myHum)
        end

        local anyESP = hasDrawing and (CONFIG.BOX_ESP or CONFIG.SNAPLINE_ESP or CONFIG.HEALTHBAR_ESP)
        if anyESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local char = plr.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local head = char:FindFirstChild("Head") or hrp
                    local hum = char:FindFirstChildOfClass("Humanoid")

                    if hrp and head and hum and hum.Health > 0 then
                        if not ESPCache[plr] then
                            local box = Drawing.new("Square")
                            box.Thickness = 1.5
                            box.Filled = false

                            local tracer = Drawing.new("Line")
                            tracer.Thickness = 1
                            tracer.Transparency = 0.8

                            local hbBg = Drawing.new("Line")
                            hbBg.Thickness = 3
                            hbBg.Color = Color3.fromRGB(0, 0, 0)

                            local hbFill = Drawing.new("Line")
                            hbFill.Thickness = 1.5

                            ESPCache[plr] = { Box = box, Tracer = tracer, HB_Bg = hbBg, HB_Fill = hbFill }
                        end

                        local entry = ESPCache[plr]
                        local rootPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        local headPos, headOnScreen = cam:WorldToViewportPoint(head.Position)

                        if onScreen and rootPos.Z > 0 then
                            local tanHalf = math.tan(math.rad(cam.FieldOfView * 0.5))
                            local scale = 1000 / math.max(rootPos.Z * tanHalf * 2, 0.01)
                            local w = math.clamp(math.floor(4 * scale), 8, 220)
                            local h = math.clamp(math.floor(5.5 * scale), 12, 280)
                            local boxPos = Vector2.new(rootPos.X - w * 0.5, rootPos.Y - h * 0.5)
                            local col = (plr == currentPlr) and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(0, 255, 130)

                            entry.Box.Visible = CONFIG.BOX_ESP
                            if CONFIG.BOX_ESP then
                                entry.Box.Color = col
                                entry.Box.Size = Vector2.new(w, h)
                                entry.Box.Position = boxPos
                            end

                            entry.Tracer.Visible = CONFIG.SNAPLINE_ESP and (plr == currentPlr) and headOnScreen
                            if entry.Tracer.Visible then
                                entry.Tracer.Color = Color3.fromRGB(255, 60, 60)
                                entry.Tracer.From = refPos
                                entry.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                            end

                            entry.HB_Bg.Visible = CONFIG.HEALTHBAR_ESP
                            entry.HB_Fill.Visible = CONFIG.HEALTHBAR_ESP
                            if CONFIG.HEALTHBAR_ESP then
                                local maxHp = math.max(hum.MaxHealth, 1)
                                local hpPct = math.clamp(hum.Health / maxHp, 0, 1)
                                entry.HB_Bg.From = Vector2.new(boxPos.X - 6, boxPos.Y + h)
                                entry.HB_Bg.To = Vector2.new(boxPos.X - 6, boxPos.Y)
                                entry.HB_Fill.From = Vector2.new(boxPos.X - 6, boxPos.Y + h)
                                entry.HB_Fill.To = Vector2.new(boxPos.X - 6, boxPos.Y + (h - (h * hpPct)))
                                entry.HB_Fill.Color = Color3.fromRGB(0, 255, 0)
                            end
                        else
                            for _, obj in pairs(entry) do
                                obj.Visible = false
                            end
                        end
                    else
                        clearESP(plr)
                    end
                end
            end
        else
            for plr in pairs(ESPCache) do
                clearESP(plr)
            end
        end
    end)
end)

print("BD Hub Loaded!")
