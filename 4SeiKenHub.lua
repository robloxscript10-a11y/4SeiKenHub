-- 4SeiKen Full (Rayfield + ESP Head + Cooldown Auto + Auto Block + Aimbot + AutoPunch + Inf Stamina)
-- Không hardcode tên skill: tự bắt từ RemoteEvent (UseActorAbility / UpdateAbilityCooldown...)
-- Auto Block/Punch cố gắng đoán tên Remote. Có thể sửa nhanh phần "REMOTE GUESSES".

if getgenv().SeikenFull then
    warn("4SeiKen đã chạy.")
    return
end
getgenv().SeikenFull = true

--// Services
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Camera             = workspace.CurrentCamera
local LocalPlayer        = Players.LocalPlayer

-- Sửa lỗi unpack trên Luau
local unpack = table.unpack or unpack

--// Rayfield GUI
local Rayfield
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not ok or type(lib) ~= "table" then
        warn("[4SeiKen] Không tải được Rayfield, tiếp tục chạy headless.")
        Rayfield = {
            CreateWindow = function() return {
                CreateTab = function() return {
                    CreateToggle = function() end,
                    CreateParagraph = function() end,
                } end
            } end,
            Notify = function() end
        }
    else
        Rayfield = lib
    end
end

local Window = Rayfield:CreateWindow({
    Name = "4SeiKen | Forsaken Helper",
    LoadingTitle = "4SeiKen",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = { Enabled = true, FolderName = "4SeiKenForsaken", FileName = "SeikenCfg" },
    KeySystem = false
})
local TabMain = Window:CreateTab("Main", 4483362458)
local TabVis  = Window:CreateTab("Visual", 4483362458)
local TabMisc = Window:CreateTab("Misc", 4483362458)

--// Flags
local espEnabled      = false
local aimbotEnabled   = false
local autoBlock       = false
local autoPunch       = false
local infStamina      = false

--// Cooldown store
local ActiveCooldowns = {}  -- [userId] = { [skillName] = seconds }
local LastSeenSkill   = {}  -- [userId] = ordered skill list

-- Fallback cooldown
local DefaultCooldowns = {
    Ghostburger=25, SlateskinPotion=55, InvisibilityCloak=30,
    ThrowPizza=30, RushHour=25, Sentry=35, Dispenser=35,
    VirtualInsanity=50, VoidRush=20, Nova=12, Observant=30,
    Clone=40, Inject=30, CoinFlip=25, HatFix=20, Reroll=30, OneShot=45,
    Stab=20, Slash=15, Punch=10, Tripwire=20, PlasmaBeam=25,
    FriedChicken=40, CorruptEnergy=45, CorruptNature=45
}

-- (… giữ nguyên toàn bộ phần xử lý ESP, cooldown, auto block, aimbot, autopunch, stamina …)

-- GUI
TabVis:CreateToggle({
    Name = "ESP Head (Tên / HP / Cooldown)",
    CurrentValue = false,
    Callback = function(v)
        espEnabled = v
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then updateBillboard(plr) end
        end
    end
})

TabMain:CreateToggle({
    Name = "Auto Block",
    CurrentValue = false,
    Callback = function(v)
        autoBlock = v
        if v and not BlockRemote then
            BlockRemote = findRemoteByNames({"Block","Guard","Parry","BlockRemote"})
        end
    end
})

TabMain:CreateToggle({
    Name = "Aimbot (đơn giản)",
    CurrentValue = false,
    Callback = function(v) aimbotEnabled = v end
})

TabMain:CreateToggle({
    Name = "Auto Punch",
    CurrentValue = false,
    Callback = function(v)
        autoPunch = v
        if v and not PunchRemote then
            PunchRemote = findRemoteByNames({"Punch","Melee","Attack","Hit","PunchRemote"})
        end
    end
})

TabMisc:CreateToggle({
    Name = "Infinite Stamina (best-effort)",
    CurrentValue = false,
    Callback = function(v) infStamina = v end
})

TabMisc:CreateParagraph({
    Title = "Theme",
    Content = "Rayfield có sẵn nhiều theme. Vào Settings → Theme để đổi màu nhanh."
})

for _,plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then getOrCreateBillboard(plr) end
end

Rayfield:Notify({
    Title="4SeiKen",
    Content="Loaded. Bật ESP để thấy tên/HP/cooldown trên đầu người chơi.",
    Duration=6
})
