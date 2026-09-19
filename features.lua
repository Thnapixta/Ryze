-- features.lua
-- Aimbot, silent, esp, fov, teamcheck, hooks, UI, modais, páginas

local Ryze = _G.Ryze
local player = Ryze.player
local UIS = Ryze.Services.UIS
local RunService = Ryze.Services.RunService
local TweenService = Ryze.Services.Tween
local Theme = Ryze.Theme
local C = Ryze.constants

local new, corner, stroke, tween = Ryze.new, Ryze.corner, Ryze.stroke, Ryze.tween
local nextOrder = Ryze.nextOrder
local getMousePos = Ryze.getMousePos
local getContrastColor = Ryze.getContrastColor
local isAlive = Ryze.isAlive
local cardHeight = Ryze.cardHeight
local playHover = Ryze.playHover
local hookHover = Ryze.hookHover
local regAccent = Ryze.regAccent
local regKnob = Ryze.regKnob

local aimbotCfg = Ryze.aimbotCfg
local silentCfg = Ryze.silentCfg
local teamCheckCfg = Ryze.teamCheckCfg
local espCfg = Ryze.espCfg
local binds = Ryze.binds
local state = Ryze.state
local uiSync = Ryze.uiSync
local espData = Ryze.espData

Ryze.ui = Ryze.ui or {}
local ui = Ryze.ui

-- ============ TEAM CHECK UTILS ============
local function getTeamInfo(plr)
    local info = {obj=nil, name=nil, value=nil, rgb=nil}
    if plr.Team then
        info.obj = plr.Team
        info.name = plr.Team.Name
        if plr.Team.TeamColor then
            info.value = plr.Team.TeamColor.Value
            info.rgb = plr.Team.TeamColor.Color
        end
        if not info.rgb and plr.Team.Color then info.rgb = plr.Team.Color end
    end
    if not info.value and plr.TeamColor then
        info.value = plr.TeamColor.Value
        info.rgb = plr.TeamColor.Color
    end
    if not info.obj and plr.Character then
        local t = plr.Character:FindFirstChild("Team") or plr.Character:FindFirstChild("TeamColor")
        if t then
            if t:IsA("ObjectValue") and t.Value then
                info.obj = t.Value
                if t.Value.TeamColor then
                    info.value = t.Value.TeamColor.Value
                    info.rgb = t.Value.TeamColor.Color
                end
            elseif t:IsA("Color3Value") then info.rgb = t.Value
            elseif t:IsA("NumberValue") then info.value = t.Value end
        end
    end
    if not info.rgb and plr.NameColor then info.rgb = plr.NameColor end
    return info
end

local function sameTeam(a, b)
    if a == b then return true end
    local i1, i2 = getTeamInfo(a), getTeamInfo(b)
    if i1.obj and i2.obj and i1.obj == i2.obj then return true end
    if i1.value and i2.value and i1.value == i2.value then return true end
    if i1.name and i2.name and i1.name == i2.name then return true end
    if i1.rgb and i2.rgb then
        local d = math.abs(i1.rgb.R-i2.rgb.R) + math.abs(i1.rgb.G-i2.rgb.G) + math.abs(i1.rgb.B-i2.rgb.B)
        if d < 0.05 then return true end
    end
    return false
end

local function isTargetAllowed(tp)
    if tp == player then return false end
    if not isAlive(tp.Character) then return false end
    if not teamCheckCfg.active then return true end
    if teamCheckCfg.manual and teamCheckCfg.manualPlayers[tp] then return false end
    if teamCheckCfg.auto and sameTeam(player, tp) then return false end
    return true
end

local function hasLineOfSight(origin, tPart, tChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, tChar}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, (tPart.Position - origin), params)
    return result == nil
end

local function los(origin, tPart, tChar)
    if state.wallhack then return true end
    return hasLineOfSight(origin, tPart, tChar)
end

local function getBestPart(char, partName)
    if not char then return nil end
    local p = char:FindFirstChild(partName)
    if p and p:IsA("BasePart") then return p end
    p = char:FindFirstChild("Head")
    if p then return p end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return char:FindFirstChildWhichIsA("BasePart")
end

local function getAllCandidates(myHead, cam, partName, useMouseCenter, fov, distance)
    local center
    if useMouseCenter then
        center = getMousePos()
    else
        center = cam.ViewportSize / 2
    end

    local list = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if isTargetAllowed(plr) then
            local ec = plr.Character
            local tp = getBestPart(ec, partName)
            if tp then
                local posX, posY, onScreen
                if useMouseCenter then
                    local v3 = cam:WorldToScreenPoint(tp.Position)
                    posX, posY, onScreen = v3.X, v3.Y, v3.Z > 0
                else
                    local v3, on = cam:WorldToViewportPoint(tp.Position)
                    posX, posY, onScreen = v3.X, v3.Y, on
                end
                if onScreen then
                    local sd = (Vector2.new(posX, posY) - center).Magnitude
                    local wd = (myHead.Position - tp.Position).Magnitude
                    if sd <= fov and wd <= distance then
                        table.insert(list, {
                            char = ec,
                            part = tp,
                            screenDist = sd,
                            worldDist = wd,
                        })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.screenDist < b.screenDist end)
    return list
end

-- ============ FOV ============
local function makeFovImage(fov)
    local pixelSize = fov * 2 * C.FOV_SIZE_MULT
    local img = new("ImageLabel", {
        Size = UDim2.new(0, pixelSize, 0, pixelSize),
        Position = UDim2.new(0, -9999, 0, -9999),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = C.FOV_IMAGE_ID,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 999,
        Parent = ui.gui,
    })
    new("UIAspectRatioConstraint", {
        AspectRatio = 1,
        AspectType = Enum.AspectType.FitWithinMaxSize,
        DominantAxis = Enum.DominantAxis.Width,
        Parent = img,
    })
    return img
end

local function makeRoundFov(fov)
    local c = new("Frame", {
        Size = UDim2.new(0, fov*2, 0, fov*2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 999,
        Parent = ui.gui,
    })
    new("UIStroke", {
        Thickness = 2,
        Color = Ryze.accentColor,
        Transparency = 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = c,
    })
    corner(c, 9999)
    new("UIAspectRatioConstraint", {
        AspectRatio = 1,
        AspectType = Enum.AspectType.FitWithinMaxSize,
        DominantAxis = Enum.DominantAxis.Width,
        Parent = c,
    })
    return c
end

local function updateFov()
    if ui.aimbotFovImage then ui.aimbotFovImage:Destroy(); ui.aimbotFovImage = nil end
    if not aimbotCfg.active or not aimbotCfg.showFov or not ui.gui then return end
    if state.fovStyle == "IMAGE" then
        ui.aimbotFovImage = makeFovImage(aimbotCfg.fov)
        ui.aimbotFovImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    else
        ui.aimbotFovImage = makeRoundFov(aimbotCfg.fov)
    end
end
Ryze.updateFov = updateFov

local function updateSilentFovPosition()
    local img = ui.silentFovImage
    if not img or not img.Parent then return end
    local mp = getMousePos()
    local size = silentCfg.fov * C.FOV_SIZE_MULT
    img.Size = UDim2.new(0, size*2, 0, size*2)
    img.Position = UDim2.new(0, mp.X, 0, mp.Y)
end

local function stopSilentFovLoop()
    if state.silentFovThread then task.cancel(state.silentFovThread) end
    state.silentFovThread = nil
end

local function startSilentFovLoop()
    stopSilentFovLoop()
    state.silentFovThread = task.spawn(function()
        local rot = 0
        while ui.silentFovImage and ui.silentFovImage.Parent do
            local dt = RunService.RenderStepped:Wait()
            updateSilentFovPosition()
            rot = (rot + C.FOV_ROT_SPEED * dt) % 360
            ui.silentFovImage.Rotation = rot > 180 and (rot - 360) or rot
        end
    end)
end

local function updateSilentFov()
    if ui.silentFovImage then ui.silentFovImage:Destroy(); ui.silentFovImage = nil end
    stopSilentFovLoop()
    if not silentCfg.active or not silentCfg.showFov or not ui.gui then return end
    ui.silentFovImage = makeFovImage(silentCfg.fov)
    updateSilentFovPosition()
    startSilentFovLoop()
end
Ryze.updateSilentFov = updateSilentFov
Ryze.stopSilentFovLoop = stopSilentFovLoop

-- ============ AIMBOT ============
local function bestTarget(cfg, useMouseCenter)
    local char = player.Character
    if not isAlive(char) then return nil, nil end
    local myHead = char:FindFirstChild("Head")
    local cam = workspace.CurrentCamera
    if not myHead or not cam then return nil, nil end

    local list = getAllCandidates(myHead, cam, cfg.part, useMouseCenter, cfg.fov, cfg.distance)
    if #list == 0 then return nil, nil end

    local respectWall = cfg.wallCheck and not state.wallhack
    if respectWall then
        for _, c in ipairs(list) do
            if hasLineOfSight(myHead.Position, c.part, c.char) then
                return c.char, c.part
            end
        end
        return nil, nil
    end
    return list[1].char, list[1].part
end

local function startAimbot()
    if state.aimbotThread then task.cancel(state.aimbotThread) end
    state.aimbotThread = task.spawn(function()
        while aimbotCfg.active and ui.gui and ui.gui.Parent do
            RunService.RenderStepped:Wait()
            if not state.silentShotFrame then
                pcall(function()
                    local t, tp = bestTarget(aimbotCfg, false)
                    if t and tp and isAlive(t) then
                        local cam = workspace.CurrentCamera
                        if cam then
                            local targetCF = CFrame.lookAt(cam.CFrame.Position, tp.Position)
                            if aimbotCfg.smooth <= 0.001 then
                                cam.CFrame = targetCF
                            else
                                local a = math.clamp(1 - aimbotCfg.smooth, 0.05, 1)
                                cam.CFrame = cam.CFrame:Lerp(targetCF, a)
                            end
                        end
                    end
                end)
            end
        end
    end)
end

local function stopAimbot()
    if ui.aimbotFovImage then ui.aimbotFovImage:Destroy(); ui.aimbotFovImage = nil end
    if state.aimbotThread then task.cancel(state.aimbotThread) end
    state.aimbotThread = nil
end
Ryze.startAimbot = startAimbot
Ryze.stopAimbot = stopAimbot

-- ============ SILENT ============
local function getSilentTarget()
    local char = player.Character
    if not isAlive(char) then return nil, nil end
    local myHead = char:FindFirstChild("Head")
    local cam = workspace.CurrentCamera
    if not myHead or not cam then return nil, nil end

    if state.silentLocked and state.silentLockedTarget and state.silentLockedPart then
        if isAlive(state.silentLockedTarget.Character) then
            local stillPart = getBestPart(state.silentLockedTarget.Character, silentCfg.part)
            if stillPart then
                local myHRP = char:FindFirstChild("HumanoidRootPart")
                local tHRP = state.silentLockedTarget.Character:FindFirstChild("HumanoidRootPart")
                if myHRP and tHRP then
                    local d = (myHRP.Position - tHRP.Position).Magnitude
                    if d <= silentCfg.distance then
                        return state.silentLockedTarget, stillPart
                    end
                end
            end
        end
        state.silentLocked = false
        state.silentLockedTarget = nil
        state.silentLockedPart = nil
    end

    local list = getAllCandidates(myHead, cam, silentCfg.part, true, silentCfg.fov, silentCfg.distance)
    if #list == 0 then return nil, nil end

    if silentCfg.wallCheck and not state.wallhack then
        for _, c in ipairs(list) do
            if hasLineOfSight(myHead.Position, c.part, c.char) then
                return c.char, c.part
            end
        end
        return nil, nil
    end

    return list[1].char, list[1].part
end

local function applySilentShot()
    if not silentCfg.active then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local t, tp = getSilentTarget()
    if not t or not tp then return false end

    if not state.silentSaveCF then
        state.silentSaveCF = cam.CFrame
    end
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, tp.Position)
    state.silentShotFrame = true
    return true
end

local function restoreSilentShot()
    if state.silentSaveCF then
        local cam = workspace.CurrentCamera
        if cam and cam.Parent then
            cam.CFrame = state.silentSaveCF
        end
        state.silentSaveCF = nil
    end
    state.silentShotFrame = false
end

local function startSilent()
    if state.silentLoop then task.cancel(state.silentLoop) end
    state.silentLoop = task.spawn(function()
        while silentCfg.active and ui.gui and ui.gui.Parent do
            RunService.RenderStepped:Wait()
            if state.silentHeld then
                if not state.silentShotFrame then
                    applySilentShot()
                end
            else
                if state.silentShotFrame then
                    restoreSilentShot()
                end
            end
        end
    end)
end

local function stopSilent()
    if state.silentLoop then task.cancel(state.silentLoop) end
    state.silentLoop = nil
    state.silentHeld = false
    state.silentLocked = false
    state.silentLockedTarget = nil
    state.silentLockedPart = nil
    state.silentSaveCF = nil
    state.silentShotFrame = false
end
Ryze.startSilent = startSilent
Ryze.stopSilent = stopSilent
Ryze.applySilentShot = applySilentShot
Ryze.restoreSilentShot = restoreSilentShot

local function silentAimHandler()
    if not silentCfg.active then return end
    local t, tp = getSilentTarget()
    if not t or not tp then
        state.silentTarget = nil
        state.silentTargetPart = nil
        return
    end
    state.silentTarget = t
    state.silentTargetPart = tp
end
Ryze.silentAimHandler = silentAimHandler

-- ============ HOOKS ============
local function hookSilentAim()
    if state.hooksApplied then return end
    if not getrawmetatable or not setreadonly or not newcclosure then return end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if silentCfg.active and state.silentTargetPart and state.silentTarget then
                if method == "Raycast" and self == workspace then
                    local origin = args[1]
                    local direction = args[2]
                    if origin and direction then
                        local targetDir = (state.silentTargetPart.Position - origin)
                        if targetDir.Magnitude > 0 then
                            targetDir = targetDir.Unit * direction.Magnitude
                            return oldNamecall(self, origin, targetDir, unpack(args, 3))
                        end
                    end
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                    local ray = args[1]
                    if ray then
                        local origin = ray.Origin
                        local direction = ray.Direction
                        local targetDir = (state.silentTargetPart.Position - origin)
                        if targetDir.Magnitude > 0 then
                            targetDir = targetDir.Unit * direction.Magnitude
                            local newRay = Ray.new(origin, targetDir)
                            return oldNamecall(self, newRay, unpack(args, 2))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)

        setreadonly(mt, true)
        state.hooksApplied = true
    end)
    if not ok then
        pcall(function()
            local mt = getrawmetatable(game)
            setreadonly(mt, true)
        end)
    end
end

local function hookMouseHit()
    if not getrawmetatable or not setreadonly or not newcclosure then return end
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)

        mt.__index = newcclosure(function(t, k)
            if silentCfg.active and state.silentTargetPart and state.silentTarget then
                if typeof(t) == "Instance" and t:IsA("Mouse") then
                    if k == "Hit" then
                        return CFrame.new(state.silentTargetPart.Position)
                    elseif k == "Target" then
                        return state.silentTargetPart
                    elseif k == "UnitRay" then
                        local cam = workspace.CurrentCamera
                        if cam then
                            return Ray.new(cam.CFrame.Position, (state.silentTargetPart.Position - cam.CFrame.Position))
                        end
                    end
                end
            end
            return oldIndex(t, k)
        end)

        setreadonly(mt, true)
    end)
end

Ryze.features = {
    hooks = {
        apply = function()
            pcall(hookSilentAim)
            pcall(hookMouseHit)
        end,
    },
}

-- ============ ESP (skeleton) ============
local R15_PARTS = {
    "Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm",
    "RightUpperArm","RightLowerArm","LeftUpperLeg","LeftLowerLeg","LeftFoot",
    "RightUpperLeg","RightLowerLeg","RightFoot",
}
local R15_CONNECTIONS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6_CONNECTIONS = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local R6_HEAD_OFFSET = Vector3.new(0, 0.6, 0)
local R6_ARM_OFFSET = Vector3.new(0, 0.6, 0)
local R6_LEG_OFFSET = Vector3.new(0, -0.5, 0)
local R15_HEAD_OFFSET = Vector3.new(0, 0.5, 0)

local function getRigType(char)
    if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") then
        return "R15"
    end
    if char:FindFirstChild("Torso") then
        return "R6"
    end
    return nil
end

local function projectPoint(worldPos, cam)
    local pos, onScreen = cam:WorldToViewportPoint(worldPos)
    if onScreen and pos.Z > 0 then
        return Vector2.new(pos.X, pos.Y)
    end
    return nil
end

local function getBones(char, cam, rig)
    local bones = {}
    if rig == "R15" then
        for _, name in ipairs(R15_PARTS) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local offset = (name == "Head") and R15_HEAD_OFFSET or Vector3.new()
                local v = projectPoint(p.Position + offset, cam)
                if v then bones[name] = v end
            end
        end
    else
        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("Torso")
        local leftArm = char:FindFirstChild("Left Arm")
        local rightArm = char:FindFirstChild("Right Arm")
        local leftLeg = char:FindFirstChild("Left Leg")
        local rightLeg = char:FindFirstChild("Right Leg")
        if head then local v = projectPoint(head.Position + R6_HEAD_OFFSET, cam); if v then bones["Head"] = v end end
        if torso then local v = projectPoint(torso.Position, cam); if v then bones["Torso"] = v end end
        if leftArm then local v = projectPoint(leftArm.Position + R6_ARM_OFFSET, cam); if v then bones["Left Arm"] = v end end
        if rightArm then local v = projectPoint(rightArm.Position + R6_ARM_OFFSET, cam); if v then bones["Right Arm"] = v end end
        if leftLeg then local v = projectPoint(leftLeg.Position + R6_LEG_OFFSET, cam); if v then bones["Left Leg"] = v end end
        if rightLeg then local v = projectPoint(rightLeg.Position + R6_LEG_OFFSET, cam); if v then bones["Right Leg"] = v end end
    end
    return bones
end

local function createSkeletonLines()
    local lines = {}
    for i = 1, C.MAX_SKELETON_LINES do
        local l = Drawing.new("Line")
        l.Thickness = espCfg.skeletonThickness
        l.Color = espCfg.skeletonColor
        l.Transparency = 1
        l.Visible = false
        table.insert(lines, l)
    end
    return lines
end

local function removeLinesOfData(data)
    if not data then return end
    if data.skeletonLines then
        for _, l in ipairs(data.skeletonLines) do
            if l then pcall(function() l:Remove() end) end
        end
    end
    data.skeletonLines = nil
end

local function clearEspData()
    for _, data in pairs(espData) do
        removeLinesOfData(data)
    end
    Ryze.espData = {}
    espData = Ryze.espData
end

local function createEspFor(plr)
    local data = espData[plr]
    if data then removeLinesOfData(data) end
    espData[plr] = {
        skeletonLines = createSkeletonLines(),
        lastRig = nil,
        lastChar = nil,
    }
end

local function removeEspFor(plr)
    local data = espData[plr]
    if not data then return end
    removeLinesOfData(data)
    espData[plr] = nil
end
Ryze.removeEspFor = removeEspFor

local function getSkeletonColor(plr)
    if espCfg.rgbMode then
        local offset = (plr.UserId % 100) / 100
        local h = (tick() * espCfg.rgbSpeed + offset) % 1
        return Color3.fromHSV(h, 1, 1)
    end
    return espCfg.skeletonColor
end

local function updateEspFor(plr)
    local data = espData[plr]
    if not data then return end

    local char = plr.Character
    local cam = workspace.CurrentCamera
    local visible = espCfg.active and espCfg.skeleton

    if data.lastChar ~= char then
        removeLinesOfData(data)
        data.skeletonLines = createSkeletonLines()
        data.lastRig = nil
        data.lastChar = char
    end

    if not data.skeletonLines then
        data.skeletonLines = createSkeletonLines()
    end

    if visible and (not char or not isAlive(char)) then visible = false end

    if visible then
        local myChar = player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not myHRP or not hrp then
            visible = false
        else
            local d = (myHRP.Position - hrp.Position).Magnitude
            if d > espCfg.espDistance then visible = false end
        end
    end

    if visible and teamCheckCfg.active and not isTargetAllowed(plr) then
        visible = false
    end

    if not visible then
        for _, l in ipairs(data.skeletonLines) do
            if l then pcall(function() l.Visible = false end) end
        end
        return
    end

    local rig = getRigType(char)
    if not rig then
        for _, l in ipairs(data.skeletonLines) do
            if l then pcall(function() l.Visible = false end) end
        end
        return
    end

    if data.lastRig ~= rig then
        removeLinesOfData(data)
        data.skeletonLines = createSkeletonLines()
        data.lastRig = rig
    end

    if not cam then return end

    local bones = getBones(char, cam, rig)
    local connections = (rig == "R15") and R15_CONNECTIONS or R6_CONNECTIONS
    local color = getSkeletonColor(plr)
    local maxLineLen = cam.ViewportSize.X * 0.5

    local i = 1
    for _, conn in ipairs(connections) do
        if i > #data.skeletonLines then break end
        local a = bones[conn[1]]
        local b = bones[conn[2]]
        local line = data.skeletonLines[i]
        if line then
            if a and b then
                local dist = (a - b).Magnitude
                if dist <= maxLineLen then
                    line.Visible = true
                    line.From = a
                    line.To = b
                    line.Color = color
                    line.Thickness = espCfg.skeletonThickness
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
        i = i + 1
    end
    for j = i, #data.skeletonLines do
        local line = data.skeletonLines[j]
        if line then pcall(function() line.Visible = false end) end
    end
end

local function startEspLoop()
    if state.espThread then task.cancel(state.espThread) end
    state.espThread = task.spawn(function()
        while espCfg.active and espCfg.skeleton do
            RunService.RenderStepped:Wait()
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr ~= player and isAlive(plr.Character) then
                    if not espData[plr] then createEspFor(plr) end
                end
            end
            for plr in pairs(espData) do
                if plr.Parent == nil or plr == player then
                    removeEspFor(plr)
                else
                    updateEspFor(plr)
                end
            end
        end
        clearEspData()
    end)
end

local function stopEspLoop()
    if state.espThread then task.cancel(state.espThread) end
    state.espThread = nil
    clearEspData()
end
Ryze.startEspLoop = startEspLoop
Ryze.stopEspLoop = stopEspLoop

-- ============ COMPONENTES UI ============
local function makeScrollingPage(parent)
    local sf = new("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Ryze.accentColor,
        ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Name = "accentScroll", Parent = parent,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 8),
        Parent = sf,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, C.CARD_GAP),
        Parent = sf,
    })
    return sf
end

local function makeCard(parent, title, rowCount)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, cardHeight(rowCount)),
        BackgroundColor3 = Theme.card,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
    corner(card, 8)
    stroke(card, Theme.cardBorder, 1, 0)
    new("UIPadding", {
        PaddingTop = UDim.new(0, C.CARD_PADDING_Y),
        PaddingBottom = UDim.new(0, C.CARD_PADDING_Y),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = card,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = card,
    })

    local titleRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.CARD_HEADER - 10),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(card),
        Parent = card,
    })
    local icon = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 2, 0.5, -6),
        BorderSizePixel = 0, Parent = titleRow,
    })
    corner(icon, 3)
    regAccent(icon, "BackgroundColor3")
    new("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = titleRow,
    })
    return card
end

local function makeToggleRow(parent, label, initial, cb)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parent), Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(0.65, 0, 1, 0), BackgroundTransparency = 1,
        Text = label, TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local swBg = new("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, -10),
        BackgroundColor3 = initial and Ryze.accentColor or Theme.switchOff,
        BorderSizePixel = 0, Parent = row,
    })
    corner(swBg, 10)
    swBg:SetAttribute("isOff", not initial)
    local knob = new("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = initial and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BorderSizePixel = 0, Parent = swBg,
    })
    corner(knob, 8)
    regKnob(knob)
    local stateOn = initial
    local function setVisual(v)
        stateOn = v
        swBg:SetAttribute("isOff", not v)
        tween(swBg, {BackgroundColor3 = v and Ryze.accentColor or Theme.switchOff})
        if v then
            knob.BackgroundColor3 = getContrastColor(Ryze.accentColor)
        else
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end
        tween(knob, {Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
    end
    local btn = new("TextButton", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, Parent = row,
    })
    hookHover(btn)
    btn.MouseButton1Click:Connect(function()
        playHover()
        setVisual(not stateOn)
        if cb then cb(stateOn) end
    end)
    return row, setVisual
end

local function makeCyclerRow(parent, label, options, display, initialIdx, cb)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parent), Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
        Text = label, TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local btn = new("TextButton", {
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(1, -140, 0.5, -14),
        BackgroundColor3 = Theme.hover,
        Text = display and display[initialIdx] or options[initialIdx],
        BorderSizePixel = 0, Parent = row,
    })
    regAccent(btn, "TextColor3")
    corner(btn, 6)
    stroke(btn, Theme.cardBorder, 1, 0.3)
    hookHover(btn)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.cardBorder}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.hover}) end)
    local idx = initialIdx
    btn.MouseButton1Click:Connect(function()
        playHover()
        idx = idx % #options + 1
        btn.Text = display and display[idx] or options[idx]
        if cb then cb(options[idx], idx) end
    end)
end

local function makeSliderRow(parent, label, initial, minV, maxV, cb)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT + 8), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parent), Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 16), BackgroundTransparency = 1,
        Text = label, TextColor3 = Theme.text, TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local valLbl = new("TextLabel", {
        Size = UDim2.new(0.35, 0, 0, 16),
        Position = UDim2.new(0.65, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = string.format("%.2f", initial),
        TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })
    regAccent(valLbl, "TextColor3")
    local bar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = Theme.switchOff,
        BorderSizePixel = 0, Parent = row,
    })
    corner(bar, 2)
    local init01 = (initial - minV) / (maxV - minV)
    local fill = new("Frame", {Size = UDim2.new(init01, 0, 1, 0), BorderSizePixel = 0, Parent = bar})
    regAccent(fill, "BackgroundColor3")
    corner(fill, 2)
    local knob = new("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(init01, -6, 0.5, -6),
        BorderSizePixel = 0, Parent = bar,
    })
    regAccent(knob, "BackgroundColor3")
    corner(knob, 6)
    stroke(knob, Color3.fromRGB(255,255,255), 1, 0.6)
    local value = initial
    local dragging = false
    local function update()
        local t01 = (value - minV) / (maxV - minV)
        fill.Size = UDim2.new(t01, 0, 1, 0)
        knob.Position = UDim2.new(t01, -6, 0.5, -6)
        valLbl.Text = string.format("%.2f", value)
        if cb then cb(value) end
    end
    local function setFromMouse(x)
        local bp = bar.AbsolutePosition.X
        local bw = bar.AbsoluteSize.X
        if bw <= 0 then return end
        local t01 = math.clamp((x - bp) / bw, 0, 1)
        value = minV + t01 * (maxV - minV)
        update()
    end
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; state.sliderDragging = true; playHover()
        end
    end)
    knob.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false; state.sliderDragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            setFromMouse(UIS:GetMouseLocation().X)
        end
    end)
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; state.sliderDragging = true
            setFromMouse(UIS:GetMouseLocation().X); playHover()
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false; state.sliderDragging = false
        end
    end)
    return row
end

local function makeNumberRow(parent, label, initial, minV, maxV, cb)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parent), Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
        Text = label, TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = new("TextBox", {
        Size = UDim2.new(0, 110, 0, 28),
        Position = UDim2.new(1, -110, 0.5, -14),
        BackgroundColor3 = Theme.hover,
        Text = tostring(initial),
        TextSize = 12, Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, Parent = row,
        ClearTextOnFocus = false,
    })
    regAccent(box, "TextColor3")
    corner(box, 6)
    stroke(box, Theme.cardBorder, 1, 0.3)
    hookHover(box)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n and n >= minV and n <= maxV then
            n = math.floor(n)
            box.Text = tostring(n)
            if cb then cb(n) end
        else
            box.Text = tostring(initial)
        end
    end)
end

local function makeKeybindRow(parent, label, getKey, setKey)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT), BackgroundTransparency = 1,
        LayoutOrder = nextOrder(parent), Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -160, 1, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    local keyBtn = new("TextButton", {
        Size = UDim2.new(0, 122, 0, 28),
        Position = UDim2.new(1, -158, 0.5, -14),
        BackgroundColor3 = Theme.hover,
        Text = getKey() and getKey().Name or "Nenhuma",
        TextColor3 = getKey() and Ryze.accentColor or Theme.textDim,
        TextSize = 12, Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, Parent = row,
        AutoButtonColor = false,
    })
    corner(keyBtn, 6)
    stroke(keyBtn, Theme.cardBorder, 1, 0.3)
    hookHover(keyBtn)
    keyBtn.MouseEnter:Connect(function() tween(keyBtn, {BackgroundColor3 = Theme.cardBorder}) end)
    keyBtn.MouseLeave:Connect(function() tween(keyBtn, {BackgroundColor3 = Theme.hover}) end)
    local clearBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -30, 0.5, -13),
        BackgroundColor3 = Theme.hover,
        Text = "×", TextColor3 = Theme.textDim, TextSize = 18,
        Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0, Parent = row,
        AutoButtonColor = false,
    })
    corner(clearBtn, 13)
    local clearStroke = stroke(clearBtn, Theme.cardBorder, 1, 0.3)
    clearBtn.MouseEnter:Connect(function()
        tween(clearBtn, {BackgroundColor3 = Theme.danger, TextColor3 = Color3.fromRGB(255,255,255)})
        TweenService:Create(clearStroke, TweenInfo.new(0.15), {Color = Theme.danger, Transparency = 1}):Play()
        playHover()
    end)
    clearBtn.MouseLeave:Connect(function()
        tween(clearBtn, {BackgroundColor3 = Theme.hover, TextColor3 = Theme.textDim})
        TweenService:Create(clearStroke, TweenInfo.new(0.15), {Color = Theme.cardBorder, Transparency = 0.3}):Play()
    end)
    local function refresh()
        local k = getKey()
        keyBtn.Text = k and k.Name or "Nenhuma"
        keyBtn.TextColor3 = k and Ryze.accentColor or Theme.textDim
    end
    clearBtn.MouseButton1Click:Connect(function()
        playHover(); setKey(nil); refresh()
    end)
    keyBtn.MouseButton1Click:Connect(function()
        playHover()
        if state.listeningForBind then return end
        state.listeningForBind = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = Ryze.accentColor
        task.wait(0.15)
        local conn
        conn = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape
                or input.KeyCode == Enum.KeyCode.Backspace
                or input.KeyCode == Enum.KeyCode.Delete then
                    setKey(nil)
                else
                    setKey(input.KeyCode)
                end
                state.listeningForBind = false
                conn:Disconnect()
                refresh()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                   or input.UserInputType == Enum.UserInputType.MouseButton2 then
                state.listeningForBind = false
                conn:Disconnect()
                refresh()
            end
        end)
    end)
    return row
end

-- ============ MODAIS ============
local colorModal, teamModal, espColorModal

local function closeModal(m, w, h)
    if not m then return end
    TweenService:Create(m, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
    for _, child in ipairs(m:GetDescendants()) do
        if child:IsA("Frame") and child.Name == "modalContent" then
            TweenService:Create(child, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 1,
            }):Play()
        end
    end
    task.delay(0.18, function() if m and m.Parent then m:Destroy() end end)
end

local function buildModalBase(name, w, h)
    local modal = new("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 510,
        Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(modal, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    local overlay = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 510,
        Parent = modal,
    })
    TweenService:Create(modal, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
    local content = new("Frame", {
        Name = "modalContent",
        Size = UDim2.new(0, w, 0, 70),
        Position = UDim2.new(0.5, -w/2, 0.5, -h/2),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 511,
        ClipsDescendants = true,
        Parent = modal,
    })
    Ryze.asymmetricCorner(content, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    stroke(content, Theme.cardBorder, 1, 0.2)
    TweenService:Create(content, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 0,
    }):Play()
    task.wait(0.05)
    return modal, content, overlay
end

local function makeModalHeader(content, title, onClose)
    local header = new("Frame", {
        Size = UDim2.new(1, -32, 0, 30),
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1, ZIndex = 512,
        Parent = content,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Theme.text, TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 513, Parent = header,
    })
    local closeBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0.5, -13),
        BackgroundColor3 = Theme.hover,
        Text = "×", TextColor3 = Theme.textDim, TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, AutoButtonColor = false,
        ZIndex = 513, Parent = header,
    })
    corner(closeBtn, 13)
    hookHover(closeBtn)
    closeBtn.MouseButton1Click:Connect(function() playHover(); onClose() end)
    return header
end

local function openColorModal()
    if colorModal then return end
    colorModal = new("Frame", {
        Name = "ColorModal",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true,
        ZIndex = 500, Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(colorModal, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    local overlay = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 500, Parent = colorModal,
    })
    overlay.MouseButton1Click:Connect(function()
        local m = colorModal; colorModal = nil
        closeModal(m, 320, 70)
    end)
    TweenService:Create(colorModal, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
    local content = new("Frame", {
        Name = "modalContent",
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(0.5, -160, 0.5, -150),
        BackgroundColor3 = Theme.bg, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 501, ClipsDescendants = true,
        Parent = colorModal,
    })
    Ryze.asymmetricCorner(content, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    stroke(content, Theme.cardBorder, 1, 0.2)
    TweenService:Create(content, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 320, 0, 300), BackgroundTransparency = 0,
    }):Play()
    task.wait(0.05)
    local header = new("Frame", {
        Size = UDim2.new(1, -32, 0, 30),
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1, ZIndex = 502, Parent = content,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1, Text = "Accent Color",
        TextColor3 = Theme.text, TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 503, Parent = header,
    })
    local closeBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0.5, -13),
        BackgroundColor3 = Theme.hover,
        Text = "×", TextColor3 = Theme.textDim, TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, AutoButtonColor = false,
        ZIndex = 503, Parent = header,
    })
    corner(closeBtn, 13)
    hookHover(closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        playHover()
        local m = colorModal; colorModal = nil
        closeModal(m, 320, 70)
    end)
    new("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.new(0, 16, 0, 52),
        BackgroundColor3 = Theme.cardBorder, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 502, Parent = content,
    })
    local holder = new("Frame", {
        Size = UDim2.new(1, -32, 1, -74),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1, ZIndex = 502, Parent = content,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 12),
        FillDirection = Enum.FillDirection.Horizontal,
        Wraps = true, Parent = holder,
    })
    local swatchSize = 28
    for i, entry in ipairs(Ryze.colorPalette) do
        local sw = new("TextButton", {
            Size = UDim2.new(0, swatchSize, 0, swatchSize),
            BackgroundColor3 = entry.color,
            Text = "", BorderSizePixel = 0,
            LayoutOrder = i, AutoButtonColor = false,
            ZIndex = 503, Parent = holder,
        })
        corner(sw, swatchSize / 2)
        stroke(sw, Color3.fromRGB(60, 60, 70), 1.5, 0.4)
        local ring = new("Frame", {
            Size = UDim2.new(1, -12, 1, -12),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1, ZIndex = 504, Parent = sw,
        })
        corner(ring, 9999)
        local innerStroke = new("UIStroke", {
            Color = Color3.fromRGB(20, 20, 27), Thickness = 2,
            Transparency = (entry.color == Ryze.accentColor) and 0 or 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring,
        })
        hookHover(sw)
        sw.MouseButton1Click:Connect(function()
            playHover()
            Ryze.applyAccent(entry.color)
            for _, other in ipairs(holder:GetChildren()) do
                if other:IsA("TextButton") then
                    local r = other:FindFirstChildOfClass("Frame")
                    if r then
                        local s = r:FindFirstChildOfClass("UIStroke")
                        if s then s.Transparency = 1 end
                    end
                end
            end
            innerStroke.Transparency = 0
        end)
    end
end

Ryze.openColorModal = openColorModal

-- ============ PAGES ============
local pageBuilders = {Aimbot = {}, Visual = {}, Config = {}, Settings = {}}
Ryze.pageBuilders = pageBuilders

pageBuilders.Aimbot.Aimbot = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Aimbot", 4)
    local _, setVis = makeToggleRow(card, "Ativar Aimbot", aimbotCfg.active, function(v)
        aimbotCfg.active = v
        if v then updateFov(); startAimbot() else stopAimbot() end
    end)
    uiSync.aimbot = setVis
    makeCyclerRow(card, "Parte do Corpo", Ryze.partNames, Ryze.partLabels, 1, function(v) aimbotCfg.part = v end)
    makeSliderRow(card, "Suavizacao", aimbotCfg.smooth, 0, 1, function(v) aimbotCfg.smooth = math.floor(v*100)/100 end)
    makeToggleRow(card, "Wall Check", aimbotCfg.wallCheck, function(v) aimbotCfg.wallCheck = v end)

    local card2 = makeCard(sf, "Range & FOV", 3)
    makeNumberRow(card2, "Campo de Visao (px)", aimbotCfg.fov, 10, 2000, function(v) aimbotCfg.fov = v; updateFov() end)
    makeNumberRow(card2, "Distancia Maxima", aimbotCfg.distance, 10, 50000, function(v) aimbotCfg.distance = v end)
    makeToggleRow(card2, "Mostrar FOV", aimbotCfg.showFov, function(v) aimbotCfg.showFov = v; updateFov() end)
end

pageBuilders.Aimbot.Silent = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Silent Aim", 6)
    local _, setVis = makeToggleRow(card, "Ativar Silent Aim", silentCfg.active, function(v)
        silentCfg.active = v
        if v then updateSilentFov(); startSilent()
        else
            if ui.silentFovImage then ui.silentFovImage:Destroy(); ui.silentFovImage = nil end
            stopSilentFovLoop(); stopSilent()
            state.silentTarget = nil; state.silentTargetPart = nil
        end
    end)
    uiSync.silent = setVis
    local startIdx = 1
    for i, v in ipairs(Ryze.silentModes) do if v == silentCfg.mode then startIdx = i break end end
    makeCyclerRow(card, "Silent Mode", Ryze.silentModes, nil, startIdx, function(v) silentCfg.mode = v end)
    makeCyclerRow(card, "Modo de Disparo", Ryze.triggerMds, nil, 1, function(v) silentCfg.triggerMode = v end)
    makeCyclerRow(card, "Parte do Corpo", Ryze.partNames, Ryze.partLabels, 1, function(v) silentCfg.part = v end)
    makeToggleRow(card, "Wall Check", silentCfg.wallCheck, function(v) silentCfg.wallCheck = v end)
    makeToggleRow(card, "Lock on Shoot", silentCfg.lockOnShoot, function(v) silentCfg.lockOnShoot = v end)

    local card2 = makeCard(sf, "Range & FOV", 3)
    makeNumberRow(card2, "Campo de Visao (px)", silentCfg.fov, 10, 2000, function(v) silentCfg.fov = v; updateSilentFov() end)
    makeNumberRow(card2, "Distancia Maxima", silentCfg.distance, 10, 50000, function(v) silentCfg.distance = v end)
    makeToggleRow(card2, "Mostrar FOV (segue mouse)", silentCfg.showFov, function(v) silentCfg.showFov = v; updateSilentFov() end)
end

pageBuilders.Aimbot.TeamCheck = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Team Check", 1)
    local _, setVis = makeToggleRow(card, "Ativar Team Check", teamCheckCfg.active, function(v) teamCheckCfg.active = v end)
    uiSync.teamCheck = setVis

    local card2 = makeCard(sf, "Auto", 1)
    local _, setAuto = makeToggleRow(card2, "Auto (TeamColor)", teamCheckCfg.auto, function(v)
        teamCheckCfg.auto = v
        if v then teamCheckCfg.manual = false; if uiSync.teamManual then uiSync.teamManual(false) end end
    end)
    uiSync.teamAuto = setAuto

    local card3 = makeCard(sf, "Manual", 1)
    local _, setManual = makeToggleRow(card3, "Manual (Player List)", teamCheckCfg.manual, function(v)
        teamCheckCfg.manual = v
        if v then teamCheckCfg.auto = false; if uiSync.teamAuto then uiSync.teamAuto(false) end end
    end)
    uiSync.teamManual = setManual
end

pageBuilders.Visual.ESP = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Skeleton ESP", 1)
    local _, setVis = makeToggleRow(card, "Ativar Skeleton", espCfg.active, function(v)
        espCfg.active = v; espCfg.skeleton = v
        if v then startEspLoop() else stopEspLoop() end
    end)
    uiSync.esp = setVis

    local card2 = makeCard(sf, "Skeleton Style", 4)
    makeSliderRow(card2, "Thickness", espCfg.skeletonThickness, 1, 5, function(v)
        espCfg.skeletonThickness = math.floor(v)
        for _, data in pairs(espData) do
            if data.skeletonLines then
                for _, l in ipairs(data.skeletonLines) do
                    if l then l.Thickness = espCfg.skeletonThickness end
                end
            end
        end
    end)
    makeNumberRow(card2, "Max Distance", espCfg.espDistance, 10, 50000, function(v) espCfg.espDistance = v end)
    makeToggleRow(card2, "RGB Mode", espCfg.rgbMode, function(v) espCfg.rgbMode = v end)
    makeSliderRow(card2, "RGB Speed", espCfg.rgbSpeed, 0.1, 5, function(v) espCfg.rgbSpeed = math.floor(v*10)/10 end)
end

pageBuilders.Config.Configs = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Info", 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2), BackgroundTransparency = 1,
        Text = "Configs requerem executor com writefile/readfile.",
        TextColor3 = Theme.textDim, TextSize = 11,
        Font = Enum.Font.Gotham, TextWrapped = true,
        LayoutOrder = nextOrder(card), Parent = card,
    })
end

pageBuilders.Settings.Toggles = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "General", 3)
    local _, setWall = makeToggleRow(card, "Wallhack", state.wallhack, function(v) state.wallhack = v end)
    uiSync.wall = setWall
    local _, setCross = makeToggleRow(card, "Show Crosshair", state.crosshairEnabled, function(v)
        state.crosshairEnabled = v
        if ui.crosshair then ui.crosshair.Visible = v end
    end)
    uiSync.cross = setCross
    local _, setDrag = makeToggleRow(card, "Allow Panel Drag", state.dragEnabled, function(v) state.dragEnabled = v end)
    uiSync.drag = setDrag

    local card2 = makeCard(sf, "Aimbot FOV", 1)
    local startIdx = 1
    for i, v in ipairs(Ryze.fovStyles) do if v == state.fovStyle then startIdx = i break end end
    makeCyclerRow(card2, "FOV Shape", Ryze.fovStyles, nil, startIdx, function(v) state.fovStyle = v; updateFov() end)
end

pageBuilders.Settings.Binds = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Key Binds", 5)
    makeKeybindRow(card, "Open / Close Menu", function() return binds.togglePanel end, function(k) binds.togglePanel = k end)
    makeKeybindRow(card, "Toggle Aimbot", function() return binds.toggleAimbot end, function(k) binds.toggleAimbot = k end)
    makeKeybindRow(card, "Toggle Silent", function() return binds.toggleSilent end, function(k) binds.toggleSilent = k end)
    makeKeybindRow(card, "Toggle Wallhack", function() return binds.toggleWall end, function(k) binds.toggleWall = k end)
    makeKeybindRow(card, "Toggle Crosshair", function() return binds.toggleCross end, function(k) binds.toggleCross = k end)
end

pageBuilders.Settings.Interface = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "Appearance", 1)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT + 4),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(card), Parent = card,
    })
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.hover,
        Text = "", BorderSizePixel = 0,
        AutoButtonColor = false, Parent = row,
    })
    corner(btn, 8)
    stroke(btn, Theme.cardBorder, 1, 0.3)
    hookHover(btn)
    local preview = new("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 10, 0.5, -11),
        BackgroundColor3 = Ryze.accentColor,
        BorderSizePixel = 0, Parent = btn,
    })
    corner(preview, 11)
    stroke(preview, Color3.fromRGB(60,60,70), 1.5, 0.3)
    uiSync.colorPreview = preview
    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 42, 0, 0),
        BackgroundTransparency = 1, Text = "Accent Color",
        TextColor3 = Theme.text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })
    btn.MouseButton1Click:Connect(function() playHover(); openColorModal() end)

    local card2 = makeCard(sf, "Menu", 2)
    local _, setFpsVis = makeToggleRow(card2, "Show FPS", state.showFps, function(v)
        state.showFps = v
        if ui.fpsLabel then ui.fpsLabel.Visible = v end
    end)
    uiSync.fps = setFpsVis
    makeSliderRow(card2, "Menu Scale", state.menuScale, 0.6, 1.6, function(v)
        state.menuScale = v
        if ui.uiScale then TweenService:Create(ui.uiScale, TweenInfo.new(0.15), {Scale = v}):Play() end
    end)
end

-- ============ JANELA ============
local sidebarItems = {
    {key = "Aimbot",   name = "Aimbot",   tabs = {"Aimbot", "Silent", "TeamCheck"}},
    {key = "Visual",   name = "Visual",   tabs = {"ESP"}},
    {key = "Config",   name = "Config",   tabs = {"Configs"}},
    {key = "Settings", name = "Settings", tabs = {"Toggles", "Binds", "Interface"}},
}

local currentCategory = 1
local currentTab = 1
local sidebarBtns = {}
local tabBtns = {}
local tabBar, pagesFrame

local function rebuildPage()
    Ryze.clearChildren(pagesFrame)
    local cat = sidebarItems[currentCategory]
    local tabName = cat.tabs[currentTab]
    local group = pageBuilders[cat.key]
    local builder = group and group[tabName]
    if builder then builder(pagesFrame) end
end

local function rebuildTabs()
    Ryze.clearChildren(tabBar)
    tabBtns = {}
    local cat = sidebarItems[currentCategory]
    local tabW = 110
    local gap = 6
    for i, tabName in ipairs(cat.tabs) do
        local b = new("TextButton", {
            Size = UDim2.new(0, tabW, 0, 34),
            Position = UDim2.new(0, (i-1) * (tabW + gap), 0, 6),
            BackgroundColor3 = i == currentTab and Theme.hover or Theme.bg,
            BackgroundTransparency = i == currentTab and 0 or 1,
            Text = tabName,
            TextColor3 = i == currentTab and Theme.text or Theme.textDim,
            TextSize = 13, Font = Enum.Font.GothamMedium,
            BorderSizePixel = 0, AutoButtonColor = false,
            Parent = tabBar,
        })
        corner(b, 6)
        local underline = new("Frame", {
            Size = UDim2.new(0.5, 0, 0, 2),
            Position = UDim2.new(0.25, 0, 1, -1),
            BorderSizePixel = 0,
            BackgroundTransparency = i == currentTab and 0 or 1,
            Parent = b,
        })
        regAccent(underline, "BackgroundColor3")
        corner(underline, 1)
        tabBtns[i] = {btn = b, underline = underline}
        hookHover(b)
        b.MouseButton1Click:Connect(function()
            playHover()
            currentTab = i
            for j, data in ipairs(tabBtns) do
                data.btn.TextColor3 = j == i and Theme.text or Theme.textDim
                data.btn.BackgroundTransparency = j == i and 0 or 1
                data.btn.BackgroundColor3 = j == i and Theme.hover or Theme.bg
                data.underline.BackgroundTransparency = j == i and 0 or 1
            end
            rebuildPage()
        end)
    end
    currentTab = 1
    if #tabBtns > 0 then
        tabBtns[1].btn.TextColor3 = Theme.text
        tabBtns[1].btn.BackgroundTransparency = 0
        tabBtns[1].btn.BackgroundColor3 = Theme.hover
        tabBtns[1].underline.BackgroundTransparency = 0
    end
end

local function selectCategory(idx)
    currentCategory = idx
    for i, data in ipairs(sidebarBtns) do
        local active = i == idx
        data.label.TextColor3 = active and Theme.text or Theme.textDim
        data.bg.BackgroundColor3 = active and Theme.hover or Theme.sidebar
        for _, c in ipairs(data.iconHolder:GetDescendants()) do
            if c:IsA("ImageLabel") then
                c.ImageColor3 = active and Ryze.accentColor or Theme.textDim
            end
        end
    end
    rebuildTabs()
    rebuildPage()
end

local function createUI()
    if ui.gui then ui.gui:Destroy() end
    if ui.silentFovImage then ui.silentFovImage = nil end
    if ui.aimbotFovImage then ui.aimbotFovImage = nil end
    stopEspLoop()
    stopSilentFovLoop()

    ui.gui = new("ScreenGui", {
        Name = "RyzeMenu", IgnoreGuiInset = true,
        ResetOnSpawn = false, DisplayOrder = 9999,
        Parent = player:WaitForChild("PlayerGui"),
    })

    ui.crosshair = new("Frame", {
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(0.5, -1, 0.5, -1),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0, ZIndex = 1000,
        Visible = state.crosshairEnabled, Parent = ui.gui,
    })
    new("UIStroke", {Thickness = 1, Color = Color3.fromRGB(0,0,0), Transparency = 0.3, Parent = ui.crosshair})

    ui.fpsLabel = new("TextLabel", {
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Theme.card, BackgroundTransparency = 0.15,
        Text = "FPS: 0", TextSize = 14, Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, Visible = state.showFps, ZIndex = 1000,
        Parent = ui.gui,
    })
    corner(ui.fpsLabel, 6)
    stroke(ui.fpsLabel, Theme.cardBorder, 1, 0)
    regAccent(ui.fpsLabel, "TextColor3")

    ui.mainFrame = new("Frame", {
        Size = UDim2.new(0, 700, 0, 470),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg, BorderSizePixel = 0,
        ClipsDescendants = true, Active = true,
        Parent = ui.gui,
    })
    Ryze.asymmetricCorner(ui.mainFrame, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    stroke(ui.mainFrame, Theme.cardBorder, 1, 0)
    ui.uiScale = new("UIScale", {Scale = state.menuScale, Parent = ui.mainFrame})

    local sidebar = new("Frame", {
        Size = UDim2.new(0, C.SIDEBAR_WIDTH, 1, 0),
        BackgroundColor3 = Theme.sidebar,
        BorderSizePixel = 0, Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(sidebar, C.FRAME_RADIUS, 0, 0, 0)

    local ITEM_SIZE = 42
    local ITEM_GAP = 12
    local ITEM_TOP = 20

    for i, item in ipairs(sidebarItems) do
        local slotHeight = ITEM_SIZE + 16
        local y = ITEM_TOP + (i - 1) * (slotHeight + ITEM_GAP)
        local container = new("Frame", {
            Size = UDim2.new(0, C.SIDEBAR_WIDTH, 0, slotHeight),
            Position = UDim2.new(0, 0, 0, y),
            BackgroundTransparency = 1, Parent = sidebar,
        })
        local row = new("Frame", {
            Size = UDim2.new(0, ITEM_SIZE, 0, ITEM_SIZE),
            Position = UDim2.new(0.5, -ITEM_SIZE/2, 0, 0),
            BackgroundColor3 = i == 1 and Theme.hover or Theme.sidebar,
            BorderSizePixel = 0, Parent = container,
        })
        corner(row, 10)
        local iconHolder = new("Frame", {
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(0.5, -11, 0.5, -11),
            BackgroundTransparency = 1, Parent = row,
        })
        new("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Image = Ryze.CATEGORY_ICONS[item.key] or "",
            ImageColor3 = Theme.textDim,
            ScaleType = Enum.ScaleType.Fit, Parent = iconHolder,
        })
        local label = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 1, -14),
            BackgroundTransparency = 1, Text = item.name,
            TextColor3 = i == 1 and Theme.text or Theme.textDim,
            TextSize = 10, Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = container,
        })
        local btn = new("TextButton", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, Parent = container,
        })
        hookHover(btn)
        btn.MouseButton1Click:Connect(function() playHover(); selectCategory(i) end)
        btn.MouseEnter:Connect(function() if currentCategory ~= i then tween(row, {BackgroundColor3 = Theme.hover}) end end)
        btn.MouseLeave:Connect(function() if currentCategory ~= i then tween(row, {BackgroundColor3 = Theme.sidebar}) end end)
        sidebarBtns[i] = {bg = row, label = label, iconHolder = iconHolder}
    end

    tabBar = new("Frame", {
        Size = UDim2.new(1, -C.SIDEBAR_WIDTH, 0, 46),
        Position = UDim2.new(0, C.SIDEBAR_WIDTH, 0, 0),
        BackgroundColor3 = Theme.bg, BorderSizePixel = 0,
        Parent = ui.mainFrame,
    })
    new("Frame", {
        Size = UDim2.new(1, -C.SIDEBAR_WIDTH, 0, 1),
        Position = UDim2.new(0, C.SIDEBAR_WIDTH, 0, 46),
        BackgroundColor3 = Theme.cardBorder,
        BorderSizePixel = 0, Parent = ui.mainFrame,
    })
    pagesFrame = new("Frame", {
        Size = UDim2.new(1, -C.SIDEBAR_WIDTH, 1, -47),
        Position = UDim2.new(0, C.SIDEBAR_WIDTH, 0, 47),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Parent = ui.mainFrame,
    })

    local dragging, dragStart, startPos = false, nil, nil
    ui.mainFrame.InputBegan:Connect(function(input)
        if not state.dragEnabled then return end
        if state.sliderDragging then return end
        if colorModal or teamModal or espColorModal then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ui.mainFrame.Position
        end
    end)
    ui.mainFrame.InputEnded:Connect(function()
        dragging = false
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        ui.mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)

    selectCategory(1)
    updateFov()
    updateSilentFov()
end

Ryze.ui.window = { create = createUI }

-- ============ LOOPS FINAIS ============
local fpsAccum, fpsFrames = 0, 0
RunService.RenderStepped:Connect(function(dt)
    if silentCfg.active then
        pcall(silentAimHandler)
    end
    fpsAccum = fpsAccum + dt
    fpsFrames = fpsFrames + 1
    if fpsAccum >= 0.5 then
        if ui.fpsLabel then
            ui.fpsLabel.Text = "FPS: " .. math.floor(fpsFrames / fpsAccum + 0.5)
        end
        fpsAccum, fpsFrames = 0, 0
    end
    if not ui.gui or not ui.gui.Parent then
        if Ryze.initialized then createUI() end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or state.listeningForBind then return end
    local k = input.KeyCode
    if binds.togglePanel and k == binds.togglePanel then
        if ui.mainFrame then ui.mainFrame.Visible = not ui.mainFrame.Visible end
        return
    end
    if binds.toggleAimbot and k == binds.toggleAimbot then
        aimbotCfg.active = not aimbotCfg.active
        if uiSync.aimbot then uiSync.aimbot(aimbotCfg.active) end
        if aimbotCfg.active then updateFov(); startAimbot() else stopAimbot() end
        return
    end
    if binds.toggleSilent and k == binds.toggleSilent then
        silentCfg.active = not silentCfg.active
        if uiSync.silent then uiSync.silent(silentCfg.active) end
        if silentCfg.active then updateSilentFov(); startSilent()
        else
            if ui.silentFovImage then ui.silentFovImage:Destroy(); ui.silentFovImage = nil end
            stopSilentFovLoop(); stopSilent()
            state.silentTarget = nil; state.silentTargetPart = nil
        end
        return
    end
    if binds.toggleWall and k == binds.toggleWall then
        state.wallhack = not state.wallhack
        if uiSync.wall then uiSync.wall(state.wallhack) end
        return
    end
    if binds.toggleCross and k == binds.toggleCross then
        state.crosshairEnabled = not state.crosshairEnabled
        if ui.crosshair then ui.crosshair.Visible = state.crosshairEnabled end
        if uiSync.cross then uiSync.cross(state.crosshairEnabled) end
        return
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp or state.listeningForBind then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if not silentCfg.active then return end
        if silentCfg.lockOnShoot then
            local t, tp = getSilentTarget()
            if t and tp then
                state.silentLocked = true
                state.silentLockedTarget = t
                state.silentLockedPart = tp
            end
        end
        if silentCfg.triggerMode == "HOLD" then
            state.silentHeld = true
        else
            state.silentHeld = not state.silentHeld
        end
        if state.silentHeld then applySilentShot() end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if silentCfg.triggerMode == "HOLD" then
            state.silentHeld = false
            restoreSilentShot()
            if silentCfg.lockOnShoot then
                state.silentLocked = false
                state.silentLockedTarget = nil
                state.silentLockedPart = nil
            end
        end
    end
end)

Ryze.Services.Players.PlayerRemoving:Connect(function(plr)
    teamCheckCfg.manualPlayers[plr] = nil
    removeEspFor(plr)
end)

-- ============ INIT PRINCIPAL ============
function Ryze.init()
    if Ryze.features and Ryze.features.hooks then
        pcall(Ryze.features.hooks.apply)
    end
    createUI()
    print("[Ryze] Menu carregado com sucesso.")
end

return Ryze
