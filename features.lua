local colorModal
local espColorModal
local configModal
local viewModal

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
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
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

local function openEspColorModal(current, onPick)
    if espColorModal then return end
    espColorModal = new("Frame", {
        Name = "EspColorModal",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true,
        ZIndex = 510, Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(espColorModal, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    local overlay = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 510, Parent = espColorModal,
    })
    overlay.MouseButton1Click:Connect(function()
        local m = espColorModal; espColorModal = nil
        closeModal(m, 320, 70)
    end)
    TweenService:Create(espColorModal, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
    local content = new("Frame", {
        Name = "modalContent",
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 511, ClipsDescendants = true,
        Parent = espColorModal,
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
        BackgroundTransparency = 1, ZIndex = 512, Parent = content,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1, Text = "ESP Color",
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
    closeBtn.MouseButton1Click:Connect(function()
        playHover()
        local m = espColorModal; espColorModal = nil
        closeModal(m, 320, 70)
    end)
    new("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.new(0, 16, 0, 52),
        BackgroundColor3 = Theme.cardBorder, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 512, Parent = content,
    })
    local holder = new("Frame", {
        Size = UDim2.new(1, -32, 1, -74),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1, ZIndex = 512, Parent = content,
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
            ZIndex = 513, Parent = holder,
        })
        corner(sw, swatchSize / 2)
        stroke(sw, Color3.fromRGB(60, 60, 70), 1.5, 0.4)
        local ring = new("Frame", {
            Size = UDim2.new(1, -12, 1, -12),
            Position = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1, ZIndex = 514, Parent = sw,
        })
        corner(ring, 9999)
        local innerStroke = new("UIStroke", {
            Color = Color3.fromRGB(20, 20, 27), Thickness = 2,
            Transparency = (entry.color == current) and 0 or 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring,
        })
        hookHover(sw)
        sw.MouseButton1Click:Connect(function()
            playHover()
            if onPick then onPick(entry.color) end
            local m = espColorModal; espColorModal = nil
            closeModal(m, 320, 70)
        end)
    end
end
Ryze.openEspColorModal = openEspColorModal

local function collectConfig()
    return {
        aimbot = {
            active = aimbotCfg.active, part = aimbotCfg.part, fov = aimbotCfg.fov,
            distance = aimbotCfg.distance, smooth = aimbotCfg.smooth,
            showFov = aimbotCfg.showFov, wallCheck = aimbotCfg.wallCheck,
        },
        silent = {
            active = silentCfg.active, part = silentCfg.part, fov = silentCfg.fov,
            distance = silentCfg.distance, triggerMode = silentCfg.triggerMode,
            showFov = silentCfg.showFov, mode = silentCfg.mode,
            wallCheck = silentCfg.wallCheck, lockOnShoot = silentCfg.lockOnShoot,
        },
        team = {
            active = teamCheckCfg.active, auto = teamCheckCfg.auto, manual = teamCheckCfg.manual,
        },
        esp = {
            active = espCfg.active, skeleton = espCfg.skeleton,
            skeletonThickness = espCfg.skeletonThickness,
            skeletonColor = {espCfg.skeletonColor.R, espCfg.skeletonColor.G, espCfg.skeletonColor.B},
            espDistance = espCfg.espDistance, rgbMode = espCfg.rgbMode, rgbSpeed = espCfg.rgbSpeed,
        },
        general = {
            wallhack = state.wallhack, crosshairEnabled = state.crosshairEnabled,
            showFps = state.showFps, menuScale = state.menuScale,
            fovStyle = state.fovStyle, dragEnabled = state.dragEnabled,
        },
        binds = (function()
            local b = {}
            for k, v in pairs(binds) do if v then b[k] = v.Name end end
            return b
        end)(),
        accent = {Ryze.accentColor.R, Ryze.accentColor.G, Ryze.accentColor.B},
    }
end

local function applyConfig(cfg)
    if not cfg then return false end
    if cfg.aimbot then
        for k, v in pairs(cfg.aimbot) do aimbotCfg[k] = v end
        if cfg.aimbot.active then updateFov(); startAimbot() else stopAimbot() end
    end
    if cfg.silent then
        for k, v in pairs(cfg.silent) do silentCfg[k] = v end
        if cfg.silent.active then updateSilentFov(); startSilent()
        else
            if ui.silentFovImage then ui.silentFovImage:Destroy(); ui.silentFovImage = nil end
            stopSilentFovLoop(); stopSilent()
        end
    end
    if cfg.team then
        for k, v in pairs(cfg.team) do teamCheckCfg[k] = v end
    end
    if cfg.esp then
        espCfg.active = cfg.esp.active
        espCfg.skeleton = cfg.esp.skeleton
        espCfg.skeletonThickness = cfg.esp.skeletonThickness
        espCfg.espDistance = cfg.esp.espDistance
        espCfg.rgbMode = cfg.esp.rgbMode
        espCfg.rgbSpeed = cfg.esp.rgbSpeed
        if cfg.esp.skeletonColor then
            espCfg.skeletonColor = Color3.new(
                cfg.esp.skeletonColor[1] or 0,
                cfg.esp.skeletonColor[2] or 1,
                cfg.esp.skeletonColor[3] or 0
            )
        end
        if espCfg.active and espCfg.skeleton then startEspLoop() else stopEspLoop() end
    end
    if cfg.general then
        state.wallhack = cfg.general.wallhack
        state.crosshairEnabled = cfg.general.crosshairEnabled
        state.showFps = cfg.general.showFps
        state.menuScale = cfg.general.menuScale
        state.fovStyle = cfg.general.fovStyle
        state.dragEnabled = cfg.general.dragEnabled
        if ui.crosshair then ui.crosshair.Visible = state.crosshairEnabled end
        if ui.fpsLabel then ui.fpsLabel.Visible = state.showFps end
        if ui.uiScale then ui.uiScale.Scale = state.menuScale end
        if uiSync.cross then uiSync.cross(state.crosshairEnabled) end
        if uiSync.wall then uiSync.wall(state.wallhack) end
        if uiSync.fps then uiSync.fps(state.showFps) end
        if uiSync.drag then uiSync.drag(state.dragEnabled) end
        updateFov()
    end
    if cfg.binds then
        for k, name in pairs(cfg.binds) do
            if name and Enum.KeyCode[name] then binds[k] = Enum.KeyCode[name] end
        end
    end
    if cfg.accent then
        Ryze.applyAccent(Color3.new(cfg.accent[1] or 1, cfg.accent[2] or 1, cfg.accent[3] or 1))
        if uiSync.colorPreview then
            uiSync.colorPreview.BackgroundColor3 = Ryze.accentColor
        end
    end
    return true
end
Ryze.applyConfig = applyConfig

local CONFIG_FOLDER = Ryze.CONFIG_FOLDER or "RyzeConfigs"

local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
    return true
end

local function listConfigs()
    if not ensureFolder() or not listfiles then return {} end
    local ok, files = pcall(function() return listfiles(CONFIG_FOLDER) end)
    if not ok or not files then return {} end
    local names = {}
    for _, path in ipairs(files) do
        if type(path) == "string" and path:sub(-5) == ".json" then
            local name = path:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
    end
    table.sort(names)
    return names
end

local function saveConfig(name)
    if not name or name == "" then return false end
    if not ensureFolder() or not writefile then return false end
    local data = collectConfig()
    local encoded
    local HttpS = Ryze.Services.Http
    if HttpS then
        local ok, e = pcall(function() return HttpS:JSONEncode(data) end)
        if ok then encoded = e end
    end
    if not encoded then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    return (pcall(function() writefile(path, encoded) end))
end

local function loadConfig(name)
    if not name or name == "" or not readfile then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    local ok, content = pcall(function() return readfile(path) end)
    if not ok or not content then return false end
    local data
    local HttpS = Ryze.Services.Http
    if HttpS then
        local ok2, decoded = pcall(function() return HttpS:JSONDecode(content) end)
        if ok2 then data = decoded end
    end
    if not data then return false end
    return applyConfig(data)
end

local function deleteConfig(name)
    if not name or name == "" or not delfile then return false end
    local path = CONFIG_FOLDER .. "/" .. name .. ".json"
    return (pcall(function() delfile(path) end))
end

function Ryze.openConfigModal()
    if configModal then return end
    configModal = new("Frame", {
        Name = "ConfigModal",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true,
        ZIndex = 520, Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(configModal, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    local overlay = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 520, Parent = configModal,
    })
    overlay.MouseButton1Click:Connect(function()
        local m = configModal; configModal = nil
        closeModal(m, 340, 60)
    end)
    TweenService:Create(configModal, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
    local content = new("Frame", {
        Name = "modalContent",
        Size = UDim2.new(0, 340, 0, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 521, ClipsDescendants = true,
        Parent = configModal,
    })
    Ryze.asymmetricCorner(content, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    stroke(content, Theme.cardBorder, 1, 0.2)
    TweenService:Create(content, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 360), BackgroundTransparency = 0,
    }):Play()
    task.wait(0.05)

    local header = new("Frame", {
        Size = UDim2.new(1, -32, 0, 30),
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1, ZIndex = 522, Parent = content,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1, Text = "Gerenciar Configs",
        TextColor3 = Theme.text, TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 523, Parent = header,
    })
    local closeBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0.5, -13),
        BackgroundColor3 = Theme.hover,
        Text = "×", TextColor3 = Theme.textDim, TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, AutoButtonColor = false,
        ZIndex = 523, Parent = header,
    })
    corner(closeBtn, 13)
    hookHover(closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        playHover()
        local m = configModal; configModal = nil
        closeModal(m, 340, 60)
    end)

    local saveRow = new("Frame", {
        Size = UDim2.new(1, -32, 0, 36),
        Position = UDim2.new(0, 16, 0, 56),
        BackgroundTransparency = 1, ZIndex = 522, Parent = content,
    })
    local nameBox = new("TextBox", {
        Size = UDim2.new(1, -90, 1, 0),
        BackgroundColor3 = Theme.hover,
        Text = "",
        PlaceholderText = "Nome da config...",
        PlaceholderColor3 = Theme.textDim,
        TextColor3 = Theme.text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        BorderSizePixel = 0, ClearTextOnFocus = false,
        ZIndex = 523, Parent = saveRow,
    })
    corner(nameBox, 6)
    stroke(nameBox, Theme.cardBorder, 1, 0.3)

    local saveBtn = new("TextButton", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundColor3 = Ryze.accentColor,
        Text = "Salvar",
        TextColor3 = getContrastColor(Ryze.accentColor),
        TextSize = 12, Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, AutoButtonColor = false,
        ZIndex = 523, Parent = saveRow,
    })
    corner(saveBtn, 6)
    hookHover(saveBtn)

    new("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.new(0, 16, 0, 100),
        BackgroundColor3 = Theme.cardBorder, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 522, Parent = content,
    })

    local listHolder = new("ScrollingFrame", {
        Size = UDim2.new(1, -32, 1, -140),
        Position = UDim2.new(0, 16, 0, 110),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Ryze.accentColor,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Name = "accentScroll", ZIndex = 522, Parent = content,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = listHolder,
    })

    local function refreshList()
        for _, c in ipairs(listHolder:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        local names = listConfigs()
        if #names == 0 then
            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text = "Nenhuma config salva ainda.",
                TextColor3 = Theme.textDim,
                TextSize = 12, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                LayoutOrder = 1, ZIndex = 523,
                Parent = listHolder,
            })
            return
        end
        for i, name in ipairs(names) do
            local row = new("Frame", {
                Size = UDim2.new(1, -6, 0, 40),
                BackgroundColor3 = Theme.card,
                BorderSizePixel = 0,
                LayoutOrder = i, ZIndex = 523,
                Parent = listHolder,
            })
            corner(row, 6)
            stroke(row, Theme.cardBorder, 1, 0.4)

            new("TextLabel", {
                Size = UDim2.new(1, -130, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme.text,
                TextSize = 12, Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 524, Parent = row,
            })

            local loadBtn = new("TextButton", {
                Size = UDim2.new(0, 60, 0, 26),
                Position = UDim2.new(1, -100, 0.5, -13),
                BackgroundColor3 = Ryze.accentColor,
                Text = "Carregar",
                TextColor3 = getContrastColor(Ryze.accentColor),
                TextSize = 11, Font = Enum.Font.GothamBold,
                BorderSizePixel = 0, AutoButtonColor = false,
                ZIndex = 524, Parent = row,
            })
            corner(loadBtn, 5)
            hookHover(loadBtn)
            loadBtn.MouseButton1Click:Connect(function()
                playHover()
                loadConfig(name)
            end)

            local delBtn = new("TextButton", {
                Size = UDim2.new(0, 26, 0, 26),
                Position = UDim2.new(1, -30, 0.5, -13),
                BackgroundColor3 = Theme.hover,
                Text = "×", TextColor3 = Theme.textDim, TextSize = 14,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0, AutoButtonColor = false,
                ZIndex = 524, Parent = row,
            })
            corner(delBtn, 13)
            hookHover(delBtn)
            delBtn.MouseEnter:Connect(function()
                tween(delBtn, {BackgroundColor3 = Theme.danger, TextColor3 = Color3.fromRGB(255,255,255)})
            end)
            delBtn.MouseLeave:Connect(function()
                tween(delBtn, {BackgroundColor3 = Theme.hover, TextColor3 = Theme.textDim})
            end)
            delBtn.MouseButton1Click:Connect(function()
                playHover()
                deleteConfig(name)
                refreshList()
            end)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        playHover()
        local n = nameBox.Text
        if n and n ~= "" then
            if saveConfig(n) then
                nameBox.Text = ""
                saveBtn.Text = "Salvo!"
                task.delay(1, function()
                    if saveBtn and saveBtn.Parent then saveBtn.Text = "Salvar" end
                end)
                refreshList()
            end
        end
    end)

    refreshList()
end

function Ryze.openCurrentConfigView()
    if viewModal then return end
    viewModal = new("Frame", {
        Name = "ViewModal",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true,
        ZIndex = 530, Parent = ui.mainFrame,
    })
    Ryze.asymmetricCorner(viewModal, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    local overlay = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 530, Parent = viewModal,
    })
    overlay.MouseButton1Click:Connect(function()
        local m = viewModal; viewModal = nil
        closeModal(m, 340, 60)
    end)
    TweenService:Create(viewModal, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
    local content = new("Frame", {
        Name = "modalContent",
        Size = UDim2.new(0, 340, 0, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 531, ClipsDescendants = true,
        Parent = viewModal,
    })
    Ryze.asymmetricCorner(content, C.FRAME_RADIUS, 0, 0, C.FRAME_RADIUS)
    stroke(content, Theme.cardBorder, 1, 0.2)
    TweenService:Create(content, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 360), BackgroundTransparency = 0,
    }):Play()
    task.wait(0.05)

    local header = new("Frame", {
        Size = UDim2.new(1, -32, 0, 30),
        Position = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1, ZIndex = 532, Parent = content,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1, Text = "Config Atual",
        TextColor3 = Theme.text, TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 533, Parent = header,
    })
    local closeBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0.5, -13),
        BackgroundColor3 = Theme.hover,
        Text = "×", TextColor3 = Theme.textDim, TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0, AutoButtonColor = false,
        ZIndex = 533, Parent = header,
    })
    corner(closeBtn, 13)
    hookHover(closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        playHover()
        local m = viewModal; viewModal = nil
        closeModal(m, 340, 60)
    end)

    new("Frame", {
        Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.new(0, 16, 0, 56),
        BackgroundColor3 = Theme.cardBorder, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = 532, Parent = content,
    })

    local list = new("ScrollingFrame", {
        Size = UDim2.new(1, -32, 1, -76),
        Position = UDim2.new(0, 16, 0, 66),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Ryze.accentColor,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Name = "accentScroll", ZIndex = 532, Parent = content,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = list,
    })

    local function addLine(text, active)
        new("TextLabel", {
            Size = UDim2.new(1, -6, 0, 22),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = active and Ryze.accentColor or Theme.textDim,
            TextSize = 12, Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = nextOrder(list),
            ZIndex = 533, Parent = list,
        })
    end

    addLine("Aimbot: " .. (aimbotCfg.active and "LIGADO" or "desligado"), aimbotCfg.active)
    addLine("  Parte: " .. tostring(aimbotCfg.part), false)
    addLine("  FOV: " .. tostring(aimbotCfg.fov) .. " | Dist: " .. tostring(aimbotCfg.distance), false)
    addLine("  Smooth: " .. string.format("%.2f", aimbotCfg.smooth) .. " | Wall: " .. tostring(aimbotCfg.wallCheck), false)

    addLine("Silent: " .. (silentCfg.active and "LIGADO" or "desligado"), silentCfg.active)
    addLine("  Modo: " .. tostring(silentCfg.mode) .. " | Trigger: " .. tostring(silentCfg.triggerMode), false)
    addLine("  FOV: " .. tostring(silentCfg.fov) .. " | Part: " .. tostring(silentCfg.part), false)

    addLine("ESP: " .. (espCfg.active and "LIGADO" or "desligado"), espCfg.active)
    addLine("  Skeleton: " .. tostring(espCfg.skeleton) .. " | RGB: " .. tostring(espCfg.rgbMode), false)
    addLine("  Dist: " .. tostring(espCfg.espDistance), false)

    addLine("Team Check: " .. (teamCheckCfg.active and "LIGADO" or "desligado"), teamCheckCfg.active)
    addLine("  Auto: " .. tostring(teamCheckCfg.auto) .. " | Manual: " .. tostring(teamCheckCfg.manual), false)

    addLine("Wallhack: " .. (state.wallhack and "LIGADO" or "desligado"), state.wallhack)
    addLine("Crosshair: " .. (state.crosshairEnabled and "LIGADO" or "desligado"), state.crosshairEnabled)
    addLine("FPS counter: " .. (state.showFps and "LIGADO" or "desligado"), state.showFps)
    addLine("Escala: " .. string.format("%.2f", state.menuScale), false)
end

local pageBuilders = {Aimbot = {}, Visual = {}, Settings = {}}
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
    local card = makeCard(sf, "Team Check", 3)
    local _, setVis = makeToggleRow(card, "Ativar Team Check", teamCheckCfg.active, function(v)
        teamCheckCfg.active = v
    end)
    uiSync.teamCheck = setVis
    local _, setAuto = makeToggleRow(card, "Auto (TeamColor)", teamCheckCfg.auto, function(v)
        teamCheckCfg.auto = v
        if v then
            teamCheckCfg.manual = false
            if uiSync.teamManual then uiSync.teamManual(false) end
        end
    end)
    uiSync.teamAuto = setAuto
    local _, setManual = makeToggleRow(card, "Manual (Player List)", teamCheckCfg.manual, function(v)
        teamCheckCfg.manual = v
        if v then
            teamCheckCfg.auto = false
            if uiSync.teamAuto then uiSync.teamAuto(false) end
        end
    end)
    uiSync.teamManual = setManual

    local card2 = makeCard(sf, "Info", 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2),
        BackgroundTransparency = 1,
        Text = "Auto usa TeamColor. Manual usa lista salva em configs.",
        TextColor3 = Theme.textDim, TextSize = 11,
        Font = Enum.Font.Gotham, TextWrapped = true,
        LayoutOrder = nextOrder(card2), Parent = card2,
    })
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

    local card3 = makeCard(sf, "Skeleton Color", 1)
    local colorRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT + 4),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(card3),
        Parent = card3,
    })
    local colorBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.hover,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = colorRow,
    })
    corner(colorBtn, 8)
    stroke(colorBtn, Theme.cardBorder, 1, 0.3)
    hookHover(colorBtn)
    colorBtn.MouseEnter:Connect(function() tween(colorBtn, {BackgroundColor3 = Theme.cardBorder}) end)
    colorBtn.MouseLeave:Connect(function() tween(colorBtn, {BackgroundColor3 = Theme.hover}) end)

    local preview = new("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 10, 0.5, -11),
        BackgroundColor3 = espCfg.skeletonColor,
        BorderSizePixel = 0,
        Parent = colorBtn,
    })
    corner(preview, 11)
    stroke(preview, Color3.fromRGB(60, 60, 70), 1.5, 0.3)
    uiSync.espColorPreview = preview

    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 42, 0, 0),
        BackgroundTransparency = 1,
        Text = "Skeleton Color",
        TextColor3 = Theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = colorBtn,
    })

    new("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = ">",
        TextColor3 = Theme.textDim,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = colorBtn,
    })

    colorBtn.MouseButton1Click:Connect(function()
        playHover()
        openEspColorModal(espCfg.skeletonColor, function(c)
            espCfg.skeletonColor = c
            if preview and preview.Parent then
                preview.BackgroundColor3 = c
            end
        end)
    end)
end

pageBuilders.Settings.Toggles = function(parent)
    local sf = makeScrollingPage(parent)
    local card = makeCard(sf, "General", 2)
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

pageBuilders.Settings.Configs = function(parent)
    local sf = makeScrollingPage(parent)

    local card = makeCard(sf, "Wallhack", 1)
    local _, setWall = makeToggleRow(card, "Ativar Wallhack", state.wallhack, function(v) state.wallhack = v end)
    uiSync.wall = setWall

    local card2 = makeCard(sf, "Gerenciador", 2)

    local openRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT + 4),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(card2),
        Parent = card2,
    })
    local openBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.hover,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = openRow,
    })
    corner(openBtn, 8)
    stroke(openBtn, Theme.cardBorder, 1, 0.3)
    hookHover(openBtn)
    openBtn.MouseEnter:Connect(function() tween(openBtn, {BackgroundColor3 = Theme.cardBorder}) end)
    openBtn.MouseLeave:Connect(function() tween(openBtn, {BackgroundColor3 = Theme.hover}) end)

    new("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "Abrir Gerenciador de Configs",
        TextColor3 = Theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = openBtn,
    })

    new("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = ">",
        TextColor3 = Theme.textDim,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = openBtn,
    })

    openBtn.MouseButton1Click:Connect(function()
        playHover()
        if Ryze.openConfigModal then Ryze.openConfigModal() end
    end)

    local viewRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT + 4),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(card2),
        Parent = card2,
    })
    local viewBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.hover,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = viewRow,
    })
    corner(viewBtn, 8)
    stroke(viewBtn, Theme.cardBorder, 1, 0.3)
    hookHover(viewBtn)
    viewBtn.MouseEnter:Connect(function() tween(viewBtn, {BackgroundColor3 = Theme.cardBorder}) end)
    viewBtn.MouseLeave:Connect(function() tween(viewBtn, {BackgroundColor3 = Theme.hover}) end)

    new("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "Ver Config Atual",
        TextColor3 = Theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = viewBtn,
    })

    new("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = ">",
        TextColor3 = Theme.textDim,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = viewBtn,
    })

    viewBtn.MouseButton1Click:Connect(function()
        playHover()
        if Ryze.openCurrentConfigView then Ryze.openCurrentConfigView() end
    end)

    local card3 = makeCard(sf, "Info", 1)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT - 2),
        BackgroundTransparency = 1,
        Text = "Salva tudo: aimbot, silent, esp, team check, cores, binds, escala.",
        TextColor3 = Theme.textDim, TextSize = 11,
        Font = Enum.Font.Gotham, TextWrapped = true,
        LayoutOrder = nextOrder(card3), Parent = card3,
    })
end

local sidebarItems = {
    {key = "Aimbot",   name = "Aimbot",   tabs = {"Aimbot", "Silent", "TeamCheck"}},
    {key = "Visual",   name = "Visual",   tabs = {"ESP"}},
    {key = "Settings", name = "Settings", tabs = {"Toggles", "Binds", "Interface", "Configs"}},
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

local function showLoadscreen(onDone)
    local gui = new("ScreenGui", {
        Name = "RyzeLoadscreen",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 10000,
        Parent = player:WaitForChild("PlayerGui"),
    })

    local bg = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(8, 8, 12),
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = gui,
    })

    local vignette = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = gui,
    })

    local center = new("Frame", {
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = gui,
    })

    local logo = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        Text = "Ryze",
        TextColor3 = Color3.fromRGB(245, 245, 255),
        TextSize = 56,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 4,
        Parent = center,
    })

    local underline = new("Frame", {
        Size = UDim2.new(0, 0, 0, 3),
        Position = UDim2.new(0.5, 0, 0, 74),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Ryze.accentColor,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = center,
    })
    corner(underline, 2)

    local subtitle = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 90),
        BackgroundTransparency = 1,
        Text = "Inicializando...",
        TextColor3 = Color3.fromRGB(150, 150, 170),
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4,
        Parent = center,
    })

    local barBg = new("Frame", {
        Size = UDim2.new(0, 320, 0, 4),
        Position = UDim2.new(0.5, 0, 0, 130),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = center,
    })
    corner(barBg, 2)

    local barFill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Ryze.accentColor,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = barBg,
    })
    corner(barFill, 2)

    local percent = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 145),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Ryze.accentColor,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4,
        Parent = center,
    })

    local rotSteps = {
        {p = 0.00, t = "Inicializando..."},
        {p = 0.25, t = "Carregando modulos..."},
        {p = 0.55, t = "Aplicando hooks..."},
        {p = 0.80, t = "Preparando interface..."},
        {p = 1.00, t = "Pronto!"},
    }

    TweenService:Create(underline, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, 3),
    }):Play()

    local total = 2.4
    local elapsed = 0
    local lastStep = 0

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        local p = math.clamp(elapsed / total, 0, 1)
        local eased = 1 - (1 - p) * (1 - p)
        barFill.Size = UDim2.new(eased, 0, 1, 0)
        percent.Text = math.floor(eased * 100) .. "%"

        for i = #rotSteps, 1, -1 do
            if p >= rotSteps[i].p and i > lastStep then
                lastStep = i
                subtitle.Text = rotSteps[i].t
                break
            end
        end

        if p >= 1 then
            if conn then conn:Disconnect() end
            task.wait(0.35)
            TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            TweenService:Create(vignette, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            TweenService:Create(center, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40),
            }):Play()
            for _, child in ipairs(center:GetDescendants()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                elseif child:IsA("Frame") then
                    TweenService:Create(child, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                end
            end
            task.wait(0.55)
            gui:Destroy()
            if onDone then onDone() end
        end
    end)
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
        if colorModal or configModal or viewModal or espColorModal then return end
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
Ryze.showLoadscreen = showLoadscreen

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

function Ryze.init()
    if Ryze.features and Ryze.features.hooks then
        pcall(Ryze.features.hooks.apply)
    end
    showLoadscreen(function()
        createUI()
        print("[Ryze] Menu carregado com sucesso.")
    end)
end

return Ryze
