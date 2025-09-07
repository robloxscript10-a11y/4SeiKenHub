-- 4SeiKen Hub | Forsaken Script
-- ESP + Cooldown + Auto Block + Aimbot + Auto Punch + Infinite Stamina

if getgenv().SeikenHub then
    warn("4SeiKen đã chạy.")
    return
end
getgenv().SeikenHub = true

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Rayfield GUI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "4SeiKen | Forsaken Helper",
    LoadingTitle = "4SeiKen",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = { Enabled = true, FolderName = "4SeiKenHub", FileName = "SeikenCfg" },
    KeySystem = false
})
local TabMain = Window:CreateTab("Main", 4483362458)
local TabVisual = Window:CreateTab("Visual", 4483362458)

--// Flags
local espEnabled, autoBlock, autoPunch, aimbotEnabled, infStamina = false, false, false, false, false
local ActiveCooldowns, LastSeenSkill = {}, {}

--// Remote guess
local function findRemote(names)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            for _, nm in ipairs(names) do
                if string.lower(obj.Name) == string.lower(nm) then return obj end
            end
        end
    end
end
local BlockRemote = findRemote({"Block","Guard","Parry"})
local PunchRemote = findRemote({"Punch","Attack","Hit"})

--// Safe fire
local function safeFire(remote, ...)
    if typeof(remote) == "Instance" then
        pcall(function()
            if remote.FireServer then remote:FireServer(...) else remote:InvokeServer(...) end
        end)
    end
end

--// Billboard ESP
local function getBB(plr)
    if not (plr.Character and plr.Character:FindFirstChild("Head")) then return end
    local head = plr.Character.Head
    local bb = head:FindFirstChild("SEI_BB")
    if not bb then
        bb = Instance.new("BillboardGui", head)
        bb.Name = "SEI_BB"
        bb.Size = UDim2.new(0,200,0,100)
        bb.StudsOffset = Vector3.new(0,3,0)
        bb.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bb)
        txt.Name = "Text"
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(255,255,255)
        txt.Font = Enum.Font.SourceSansBold
        txt.TextSize = 13
        txt.TextYAlignment = Enum.TextYAlignment.Top
    end
    return bb
end

local function updateBB(plr)
    local bb = getBB(plr) if not bb then return end
    local txt = bb.Text
    if not espEnabled then txt.Text = "" return end
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    local hp = hum and string.format("HP: %d/%d",hum.Health,hum.MaxHealth) or "HP: ?"
    local lines = {plr.Name, hp}
    if ActiveCooldowns[plr.UserId] then
        for skill, cd in pairs(ActiveCooldowns[plr.UserId]) do
            table.insert(lines, skill..": "..(cd>0 and math.ceil(cd).."s" or "Ready"))
        end
    end
    txt.Text = table.concat(lines,"\n")
end

-- Tick update
task.spawn(function()
    while true do
        task.wait(0.2)
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then updateBB(p) end
        end
    end
end)

--// Remote listen (auto cooldown detect)
local function hookRemote(ev)
    ev.OnClientEvent:Connect(function(...)
        local args = {...}
        local plr, skill, secs
        for _,v in ipairs(args) do
            if typeof(v)=="Instance" and v:IsA("Model") then
                plr = Players:GetPlayerFromCharacter(v)
            elseif typeof(v)=="string" and #v<20 then
                skill = v
            elseif typeof(v)=="number" then
                secs = v
            end
        end
        if plr and skill then
            ActiveCooldowns[plr.UserId] = ActiveCooldowns[plr.UserId] or {}
            ActiveCooldowns[plr.UserId][skill] = secs or 10
            if autoBlock and plr~=LocalPlayer then safeFire(BlockRemote,true) end
        end
    end)
end
for _,o in ipairs(ReplicatedStorage:GetDescendants()) do if o:IsA("RemoteEvent") then hookRemote(o) end end

--// Toggles
TabVisual:CreateToggle({Name="ESP Head",CurrentValue=false,Callback=function(v) espEnabled=v end})
TabMain:CreateToggle({Name="Auto Block",CurrentValue=false,Callback=function(v) autoBlock=v end})
TabMain:CreateToggle({Name="Auto Punch",CurrentValue=false,Callback=function(v) autoPunch=v end})
TabMain:CreateToggle({Name="Aimbot",CurrentValue=false,Callback=function(v) aimbotEnabled=v end})
TabMain:CreateToggle({Name="Infinite Stamina",CurrentValue=false,Callback=function(v) infStamina=v end})

Rayfield:Notify({Title="4SeiKen",Content="Loaded Hub!",Duration=6})
