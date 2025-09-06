-- // Rayfield Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Window
local Window = Rayfield:CreateWindow({
    Name = "4SeiKen Hub",
    LoadingTitle = "4SeiKen Hub",
    LoadingSubtitle = "by robloxscript10-a11y",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "4SeiKenHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- // Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local AutoBlockTab = Window:CreateTab("Auto Block", 4483362458)

-- // Auto Block Toggle
local AutoBlockEnabled = false
local DetectionRange = 15

local Toggle = AutoBlockTab:CreateToggle({
    Name = "Enable Auto Block",
    CurrentValue = false,
    Flag = "AutoBlock",
    Callback = function(Value)
        AutoBlockEnabled = Value
    end,
})

local Slider = AutoBlockTab:CreateSlider({
    Name = "Detection Range",
    Range = {5, 30},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Flag = "Range",
    Callback = function(Value)
        DetectionRange = Value
    end,
})

-- // Auto Block Logic
task.spawn(function()
    while task.wait(0.1) do
        if AutoBlockEnabled then
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

                for _,v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        local mag = (HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                        if mag <= DetectionRange then
                            -- Gọi block (ví dụ animation)
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "F", false, game)
                            task.wait(0.2)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "F", false, game)
                        end
                    end
                end
            end)
        end
    end
end)

-- // Main Tab Example
MainTab:CreateButton({
    Name = "Test Print",
    Callback = function()
        print("Hello from 4SeiKenHub!")
    end,
})
