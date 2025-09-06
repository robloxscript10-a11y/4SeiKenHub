-- 4SeiKen Full (Rayfield + ESP Head + Cooldown Auto + Auto Block + Aimbot + AutoPunch + Inf Stamina)
-- Không hardcode tên skill: tự bắt từ RemoteEvent (UseActorAbility / UpdateAbilityCooldown ...)
-- Lưu ý: Auto Block/Punch cần game đúng Remote; script đã scan & đoán tên phổ biến, bạn có thể sửa nhanh trong phần "REMOTE GUESSES".

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

--// Rayfield GUI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
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

--// Cooldown store: per player -> per skill -> timeLeft (sec)
local ActiveCooldowns = {}  -- [userId] = { [skillName] = seconds }
local LastSeenSkill   = {}  -- [userId] = ordered list of skill names to render ổn định

--// Fallback cooldown (nếu event UseActorAbility không gửi số giây). Bạn chỉnh nếu cần.
local DefaultCooldowns = {
    Ghostburger=25, SlateskinPotion=55, InvisibilityCloak=30,
    ThrowPizza=30, RushHour=25, Sentry=35, Dispenser=35,
    VirtualInsanity=50, VoidRush=20, Nova=12, Observant=30,
    Clone=40, Inject=30, CoinFlip=25, HatFix=20, Reroll=30, OneShot=45,
    Stab=20, Slash=15, Punch=10, Tripwire=20, PlasmaBeam=25,
    FriedChicken=40, CorruptEnergy=45, CorruptNature=45
}

--// ===== Remote guesses (Auto Block / Auto Punch) =====
local function findRemoteByNames(names)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            for _, nm in ipairs(names) do
                if string.lower(obj.Name) == string.lower(nm) then
                    return obj
                end
            end
        end
    end
    return nil
end

local BlockRemote = findRemoteByNames({"Block","Guard","Parry","BlockRemote"})
local PunchRemote = findRemoteByNames({"Punch","Melee","Attack","Hit","PunchRemote"})

local function safeFire(remote, ...)
    if typeof(remote) == "Instance" then
        local ok,_ = pcall(function()
            if remote.FireServer then remote:FireServer(...) elseif remote.InvokeServer then remote:InvokeServer(...) end
        end)
        return ok
    end
    return false
end

--// ===== ESP: billboard on head (Name/HP + cooldown lines) =====
local function getOrCreateBillboard(plr)
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local bb = head:FindFirstChild("SEI_BB")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "SEI_BB"
        bb.Size = UDim2.new(0, 220, 0, 110)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local nameL = Instance.new("TextLabel", bb)
        nameL.Name = "Name"
        nameL.Size = UDim2.new(1,0,0,20)
        nameL.BackgroundTransparency = 1
        nameL.TextColor3 = Color3.fromRGB(255,255,255)
        nameL.TextStrokeTransparency = 0.5
        nameL.Font = Enum.Font.SourceSansBold
        nameL.TextSize = 14
        nameL.TextXAlignment = Enum.TextXAlignment.Left

        local hpL = Instance.new("TextLabel", bb)
        hpL.Name = "HP"
        hpL.Position = UDim2.new(0,0,0,20)
        hpL.Size = UDim2.new(1,0,0,18)
        hpL.BackgroundTransparency = 1
        hpL.TextColor3 = Color3.fromRGB(180,255,180)
        hpL.TextStrokeTransparency = 0.6
        hpL.Font = Enum.Font.SourceSansBold
        hpL.TextSize = 13
        hpL.TextXAlignment = Enum.TextXAlignment.Left

        local cdL = Instance.new("TextLabel", bb)
        cdL.Name = "CD"
        cdL.Position = UDim2.new(0,0,0,38)
        cdL.Size = UDim2.new(1,0,1,-38)
        cdL.BackgroundTransparency = 1
        cdL.TextColor3 = Color3.fromRGB(255,200,120)
        cdL.TextStrokeTransparency = 0.7
        cdL.Font = Enum.Font.SourceSansBold
        cdL.TextSize = 12
        cdL.TextXAlignment = Enum.TextXAlignment.Left
        cdL.TextYAlignment = Enum.TextYAlignment.Top
    end
    return bb
end

local function updateBillboard(plr)
    local bb = getOrCreateBillboard(plr)
    if not bb then return end
    local tl = bb:FindFirstChild("Name")
    local hp = bb:FindFirstChild("HP")
    local cd = bb:FindFirstChild("CD")
    if not (tl and hp and cd) then return end

    if not espEnabled then
        tl.Text, hp.Text, cd.Text = "", "", ""
        return
    end

    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        tl.Text = ("[%s]"):format(plr.Name)
        hp.Text = ("HP: %d / %d"):format(math.floor(hum.Health), math.floor(hum.MaxHealth))
    else
        tl.Text = ("[%s]"):format(plr.Name)
        hp.Text = "HP: ?"
    end

    local uid = plr.UserId
    local lines = {}
    -- in ra theo thứ tự lần đầu thấy skill để đỡ nhảy
    LastSeenSkill[uid] = LastSeenSkill[uid] or {}
    local order = LastSeenSkill[uid]

    -- Gom tên xuất hiện lần đầu
    for skill,_ in pairs(ActiveCooldowns[uid] or {}) do
        local seen = false
        for _,s in ipairs(order) do if s == skill then seen = true break end end
        if not seen then table.insert(order, skill) end
    end

    for _,skill in ipairs(order) do
        local t = ActiveCooldowns[uid] and ActiveCooldowns[uid][skill] or 0
        if t and t > 0 then
            table.insert(lines, ("%s: %ds"):format(skill, math.ceil(t)))
        else
            table.insert(lines, ("%s: Ready"):format(skill))
        end
    end

    cd.Text = table.concat(lines, "\n")
end

local function trackPlayer(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        getOrCreateBillboard(plr)
    end)
    if plr.Character then
        getOrCreateBillboard(plr)
    end
end

for _,p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then trackPlayer(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then trackPlayer(p) end end)

--// Tick cooldowns & refresh ESP text
task.spawn(function()
    local acc = 0
    while true do
        local dt = task.wait(0.1)
        acc += dt
        -- giảm cooldown mỗi 0.1s cho mượt
        for uid, skills in pairs(ActiveCooldowns) do
            for name, t in pairs(skills) do
                if t and t > 0 then
                    skills[name] = math.max(0, t - dt)
                end
            end
        end
        -- refresh text xấp xỉ mỗi 0.2s
        if acc >= 0.2 then
            acc = 0
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then updateBillboard(plr) end
            end
        end
    end
end)

--// Helper: tìm Player từ arg
local function resolvePlayerFromArg(v)
    if typeof(v) == "Instance" then
        if v:IsA("Player") then return v end
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
            local plr = Players:GetPlayerFromCharacter(v)
            if plr then return plr end
        end
        if v:IsA("Humanoid") and v.Parent then
            local plr = Players:GetPlayerFromCharacter(v.Parent)
            if plr then return plr end
        end
    elseif typeof(v) == "number" then
        local plr = Players:GetPlayerByUserId(v)
        if plr then return plr end
    elseif typeof(v) == "string" then
        local plr = Players:FindFirstChild(v)
        if plr then return plr end
    end
    return nil
end

--// Helper: rút skillName & duration & actor từ list args
local function parseAbilityEvent(remote, args)
    local raw = {}
    for i=1, select("#", unpack(args)) do
        raw[i] = args[i]
    end

    -- loại các token phổ biến để tìm tên chiêu
    local blacklist = {
        "UseActorAbility","UseAbility","UpdateAbilityCooldown",
        "AbilityCooldown","Cooldown","SetCooldown","Skill","Ability"
    }

    local function isBlacklisted(s)
        local low = string.lower(s)
        for _,k in ipairs(blacklist) do
            if string.find(low, string.lower(k)) then return true end
        end
        return false
    end

    local actorPlr
    local skillName
    local duration

    -- ưu tiên tách actor
    for _,v in ipairs(raw) do
        local p = resolvePlayerFromArg(v)
        if p then actorPlr = p break end
    end

    -- bắt duration
    for _,v in ipairs(raw) do
        if typeof(v) == "number" then
            duration = v -- nhớ giá trị số cuối cùng (thường là giây CD)
        elseif typeof(v) == "table" then
            -- nếu table có field Cooldown/Duration
            local ok,val = pcall(function() return v.Cooldown or v.Duration or v.cd or v.time end)
            if ok and typeof(val) == "number" then duration = val end
        end
    end

    -- bắt skill name: string đầu tiên hợp lệ (không nằm trong blacklist)
    for _,v in ipairs(raw) do
        if typeof(v) == "string" then
            local s = v
            if not isBlacklisted(s) and #s <= 28 then -- tránh string dài rác
                skillName = s
                break
            end
        end
    end

    -- fallback actor
    if not actorPlr then actorPlr = LocalPlayer end
    -- fallback skillName = tên remote (nếu rơi vào TH hiếm)
    if not skillName then skillName = tostring(remote.Name) end
    -- fallback duration
    if not duration then
        duration = DefaultCooldowns[skillName] or 10
    end

    return actorPlr, skillName, duration
end

local function startCooldown(plr, skillName, secs)
    if not plr then return end
    ActiveCooldowns[plr.UserId] = ActiveCooldowns[plr.UserId] or {}
    ActiveCooldowns[plr.UserId][skillName] = tonumber(secs) or 0

    -- nhớ thứ tự hiển thị
    LastSeenSkill[plr.UserId] = LastSeenSkill[plr.UserId] or {}
    local order = LastSeenSkill[plr.UserId]
    local seen = false
    for _,s in ipairs(order) do if s == skillName then seen = true break end end
    if not seen then table.insert(order, skillName) end

    -- auto block nếu đang bật
    if autoBlock and plr ~= LocalPlayer then
        -- nếu đối thủ vừa dùng skill, block nhanh một nhịp
        for i=1,4 do
            safeFire(BlockRemote, true)
        end
    end
end

--// Kết nối tất cả RemoteEvent và theo dõi
local connected = setmetatable({}, {__mode = "k"})
local keywords  = {"UseActorAbility","UseAbility","UpdateAbilityCooldown","AbilityCooldown","Cooldown","SetCooldown"}

local function connectRemoteEvent(ev)
    if connected[ev] then return end
    connected[ev] = true
    ev.OnClientEvent:Connect(function(...)
        local args = {...}
        -- lọc nhanh theo từ khóa trong args hoặc theo tên remote
        local hit = false
        local rn = string.lower(ev.Name)
        for _,k in ipairs(keywords) do
            if rn:find(string.lower(k)) then hit = true break end
        end
        if not hit then
            for _,v in ipairs(args) do
                if typeof(v) == "string" then
                    for _,k in ipairs(keywords) do
                        if string.lower(v):find(string.lower(k)) then hit = true break end
                    end
                end
                if hit then break end
            end
        end
        if hit then
            local plr, skill, secs = parseAbilityEvent(ev, args)
            startCooldown(plr, skill, secs)
        end
    end)
end

local function scanAllRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            connectRemoteEvent(obj)
        end
    end
end
scanAllRemotes()
ReplicatedStorage.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then connectRemoteEvent(obj) end
end)

--// ===== Aimbot (đơn giản: khóa nearest khác mình) =====
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not (myHRP) then return end

    local best, bestDist
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local dist = (head.Position - Camera.CFrame.Position).Magnitude
            if not bestDist or dist < bestDist then
                bestDist = dist
                best = head
            end
        end
    end
    if best then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, best.Position)
    end
end)

--// ===== Auto Punch =====
task.spawn(function()
    while true do
        task.wait(0.25)
        if autoPunch then
            if not PunchRemote then
                PunchRemote = findRemoteByNames({"Punch","Melee","Attack","Hit","PunchRemote"})
            end
            safeFire(PunchRemote)
        end
    end
end)

--// ===== Inf Stamina (best-effort) =====
local function tryInfStamina()
    local stats = LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("Leaderstats") or LocalPlayer:FindFirstChild("PlayerStats")
    local function boost(obj)
        if not obj then return end
        local st = obj:FindFirstChild("Stamina") or obj:FindFirstChild("STA") or obj:FindFirstChild("Energy")
        if st and st:IsA("NumberValue") then
            st.Changed:Connect(function()
                if infStamina then
                    local maxv = obj:FindFirstChild("MaxStamina") or obj:FindFirstChild("StaminaMax") or obj:FindFirstChild("Max")
                    local target = (maxv and maxv.Value) or 999
                    pcall(function() st.Value = target end)
                end
            end)
        end
    end
    boost(stats)
    LocalPlayer.ChildAdded:Connect(function(c) if c.Name:lower():find("stat") then boost(c) end end)
end
tryInfStamina()

--// ===== GUI Controls =====
TabVis:CreateToggle({
    Name = "ESP Head (Tên / HP / Cooldown)",
    CurrentValue = false,
    Callback = function(v)
        espEnabled = v
        -- refresh ngay
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

-- Theme quick picks
TabMisc:CreateParagraph({Title="Theme", Content="Rayfield có sẵn nhiều theme. Vào Settings → Theme để đổi màu nhanh."})

-- Tạo billboard lúc đầu
for _,plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then getOrCreateBillboard(plr) end
end

Rayfield:Notify({Title="4SeiKen", Content="Loaded. Bật ESP để thấy tên/HP/cooldown trên đầu người chơi.", Duration=6})
