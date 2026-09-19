-- core.lua
-- Tema, services, utils, accent, state, sound, bindings

local Ryze = _G.Ryze
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

Ryze.Services = {
    Players = Players,
    UIS = UIS,
    RunService = RunService,
    Tween = TweenService,
    Sound = SoundService,
    Http = HttpService,
}

Ryze.player = Players.LocalPlayer

-- ============ TEMA ============
Ryze.Theme = {
    bg          = Color3.fromRGB(11, 11, 16),
    sidebar     = Color3.fromRGB(14, 14, 20),
    card        = Color3.fromRGB(20, 20, 27),
    cardBorder  = Color3.fromRGB(36, 36, 48),
    text        = Color3.fromRGB(235, 235, 245),
    textDim     = Color3.fromRGB(125, 125, 145),
    switchOff   = Color3.fromRGB(44, 44, 56),
    hover       = Color3.fromRGB(28, 28, 38),
    danger      = Color3.fromRGB(220, 70, 70),
}

Ryze.constants = {
    FOV_IMAGE_ID   = "rbxthumb://type=Asset&id=107380944966766&w=420&h=420",
    HOVER_SOUND_ID = "rbxassetid://136108770017536",
    FOV_SIZE_MULT  = 1.2,
    FOV_ROT_SPEED  = 90,
    FRAME_RADIUS   = 15,
    SIDEBAR_WIDTH  = 62,
    ROW_HEIGHT     = 34,
    CARD_HEADER    = 30,
    CARD_PADDING_Y = 12,
    CARD_GAP       = 10,
    MAX_SKELETON_LINES = 20,
}

Ryze.CATEGORY_ICONS = {
    Aimbot   = "",
    Visual   = "",
    Config   = "",
    Settings = "",
}

Ryze.colorPalette = {
    {name="White",  color=Color3.fromRGB(255,255,255)},
    {name="Silver", color=Color3.fromRGB(200,200,210)},
    {name="Gray",   color=Color3.fromRGB(140,140,150)},
    {name="Black",  color=Color3.fromRGB(40,40,48)},
    {name="Orange", color=Color3.fromRGB(230,126,34)},
    {name="Amber",  color=Color3.fromRGB(240,200,60)},
    {name="Lime",   color=Color3.fromRGB(120,220,90)},
    {name="Green",  color=Color3.fromRGB(60,200,120)},
    {name="Teal",   color=Color3.fromRGB(60,200,200)},
    {name="Blue",   color=Color3.fromRGB(80,160,255)},
    {name="Indigo", color=Color3.fromRGB(110,110,240)},
    {name="Purple", color=Color3.fromRGB(150,90,230)},
    {name="Pink",   color=Color3.fromRGB(255,130,200)},
    {name="Red",    color=Color3.fromRGB(230,70,90)},
    {name="Cyan",   color=Color3.fromRGB(90,230,240)},
    {name="Gold",   color=Color3.fromRGB(230,180,60)},
}

-- ============ STATE ============
Ryze.accentColor = Color3.fromRGB(255, 255, 255)
Ryze.accentRegistry = {}
Ryze.knobRegistry = {}
Ryze.uiSync = {}
Ryze.espData = {}

Ryze.aimbotCfg = {active=false, part="Head", fov=150, distance=5000, smooth=0.35, showFov=true, wallCheck=true}
Ryze.silentCfg = {
    active=false, part="Head", fov=200, distance=5000,
    triggerMode="HOLD", showFov=true, mode="Camera",
    wallCheck=true, lockOnShoot=true,
}
Ryze.teamCheckCfg = {active=false, auto=false, manual=false, manualPlayers={}}
Ryze.espCfg = {
    active=false, skeleton=false, skeletonThickness=1,
    skeletonColor=Color3.fromRGB(0,255,0),
    espDistance=500, rgbMode=false, rgbSpeed=1,
}

Ryze.binds = {
    togglePanel  = Enum.KeyCode.RightControl,
    toggleAimbot = Enum.KeyCode.H,
    toggleSilent = nil,
    toggleWall   = nil,
    toggleCross  = nil,
}

Ryze.state = {
    wallhack = false,
    crosshairEnabled = true,
    showFps = false,
    menuScale = 1,
    fovStyle = "ROUND",
    dragEnabled = true,
    listeningForBind = false,
    sliderDragging = false,
    hooksApplied = false,
    currentConfigName = nil,
    silentHeld = false,
    silentShotFrame = false,
    silentTarget = nil,
    silentTargetPart = nil,
    silentLocked = false,
    silentLockedTarget = nil,
    silentLockedPart = nil,
    silentSaveCF = nil,
    silentLoop = nil,
    silentFovThread = nil,
    espThread = nil,
    aimbotThread = nil,
}

Ryze.silentModes = {"Camera", "Mouse", "Raycast", "Hybrid"}
Ryze.triggerMds  = {"HOLD", "TOGGLE"}
Ryze.fovStyles   = {"ROUND", "IMAGE"}

Ryze.partNames = {
    "Head","Torso","HumanoidRootPart","UpperTorso","LowerTorso",
    "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
    "LeftUpperLeg","RightUpperLeg","LeftFoot","RightFoot",
}
Ryze.partLabels = {
    "CABECA","TRONCO","RAIZ","TORSO SUP","TORSO INF",
    "BRACO E SUP","BRACO D SUP","BRACO E INF","BRACO D INF",
    "PERNA E SUP","PERNA D SUP","PE E","PE D",
}

Ryze.CONFIG_FOLDER = "RyzeConfigs"

-- ============ UTILS ============
function Ryze.new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

function Ryze.corner(inst, r)
    return Ryze.new("UICorner", {CornerRadius = UDim.new(0, r)}, inst)
end

function Ryze.asymmetricCorner(inst, tl, tr, bl, br)
    local c = Instance.new("UICorner")
    c.TopLeftRadius = UDim.new(0, tl)
    c.TopRightRadius = UDim.new(0, tr)
    c.BottomLeftRadius = UDim.new(0, bl)
    c.BottomRightRadius = UDim.new(0, br)
    c.Parent = inst
    return c
end

function Ryze.stroke(inst, color, thick, trans)
    return Ryze.new("UIStroke", {
        Color = color or Ryze.Theme.cardBorder,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

function Ryze.tween(obj, props, dur)
    TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

function Ryze.nextOrder(parent)
    local n = (parent:GetAttribute("rowOrder") or 0) + 1
    parent:SetAttribute("rowOrder", n)
    return n
end

function Ryze.getMousePos()
    local mp = UIS:GetMouseLocation()
    return Vector2.new(mp.X, mp.Y)
end

function Ryze.getContrastColor(bg)
    local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
    if lum > 0.6 then
        return Color3.fromRGB(20, 20, 27)
    end
    return Color3.fromRGB(255, 255, 255)
end

function Ryze.cardHeight(rows)
    local C = Ryze.constants
    return C.CARD_PADDING_Y * 2 + C.CARD_HEADER + rows * C.ROW_HEIGHT + math.max(0, rows - 1) * 8
end

function Ryze.isAlive(char)
    if not char then return false end
    local h = char:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

function Ryze.clearChildren(inst)
    for _, c in ipairs(inst:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
    inst:SetAttribute("rowOrder", 0)
end

-- ============ ACCENT ============
function Ryze.regAccent(inst, prop)
    inst[prop] = Ryze.accentColor
    table.insert(Ryze.accentRegistry, {inst = inst, prop = prop})
    return inst
end

function Ryze.regKnob(inst)
    inst.BackgroundColor3 = Ryze.getContrastColor(Ryze.accentColor)
    table.insert(Ryze.knobRegistry, inst)
    return inst
end

function Ryze.applyAccent(color)
    Ryze.accentColor = color
    for i = #Ryze.accentRegistry, 1, -1 do
        local e = Ryze.accentRegistry[i]
        if e.inst and e.inst.Parent then
            e.inst[e.prop] = color
        else
            table.remove(Ryze.accentRegistry, i)
        end
    end
    for i = #Ryze.knobRegistry, 1, -1 do
        local inst = Ryze.knobRegistry[i]
        if inst and inst.Parent then
            local parent = inst.Parent
            local isOff = parent and parent:GetAttribute("isOff")
            if not isOff then
                inst.BackgroundColor3 = Ryze.getContrastColor(color)
            end
        else
            table.remove(Ryze.knobRegistry, i)
        end
    end
    if Ryze.ui and Ryze.ui.aimbotFovImage then
        local s = Ryze.ui.aimbotFovImage:FindFirstChildOfClass("UIStroke")
        if s then s.Color = color end
    end
    if Ryze.ui and Ryze.ui.gui then
        for _, child in ipairs(Ryze.ui.gui:GetDescendants()) do
            if child.Name == "accentScroll" then
                child.ScrollBarImageColor3 = color
            end
        end
    end
    if Ryze.uiSync.colorPreview then
        Ryze.uiSync.colorPreview.BackgroundColor3 = color
    end
    if Ryze.uiSync.teamCountBg then
        Ryze.uiSync.teamCountBg.BackgroundColor3 = color
        if Ryze.uiSync.teamCountBtn then
            Ryze.uiSync.teamCountBtn.TextColor3 = Ryze.getContrastColor(color)
        end
    end
end

-- ============ SOM ============
local hoverSound
local function initHoverSound()
    if hoverSound then hoverSound:Destroy() end
    hoverSound = Instance.new("Sound")
    hoverSound.Name = "RyzeHoverSound"
    hoverSound.SoundId = Ryze.constants.HOVER_SOUND_ID
    hoverSound.Volume = 0.35
    hoverSound.Parent = SoundService
end
initHoverSound()

function Ryze.playHover()
    if not hoverSound then return end
    pcall(function()
        hoverSound.TimePosition = 0
        hoverSound:Play()
    end)
end

function Ryze.hookHover(inst)
    inst.MouseEnter:Connect(Ryze.playHover)
end

return Ryze