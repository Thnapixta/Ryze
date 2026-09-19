-- main.lua
-- Loader raiz do Ryze Menu
-- Uso: loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USER/ryze-menu/main/main.lua"))()

local BASE_URL = "https://raw.githubusercontent.com/Thnapixta/Ryze/main/"

_G.Ryze = _G.Ryze or {}
_G.Ryze.BASE_URL = BASE_URL

local loaded = {}

local function load(file)
    if loaded[file] then return end
    loaded[file] = true

    local url = BASE_URL .. file .. ".lua"
    local ok, code = pcall(function() return game:HttpGet(url) end)
    if not ok or not code or code == "" then
        warn("[Ryze] Falha ao baixar:", file)
        return
    end

    local fn, err = loadstring(code)
    if not fn then
        warn("[Ryze] Erro de sintaxe em " .. file .. ":", err)
        return
    end

    local ok2, result = pcall(fn)
    if not ok2 then
        warn("[Ryze] Erro ao executar " .. file .. ":", result)
    end
end

_G.Ryze.load = load

load("core")
load("features")

if _G.Ryze.init then
    _G.Ryze.init()
end
