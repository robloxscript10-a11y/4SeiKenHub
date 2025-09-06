-- 4SeiKen Hub
-- Full script with Rayfield UI, Auto Block, ESP, Themes

-- // Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "4SeiKen Hub",
   LoadingTitle = "4SeiKen Hub Loading...",
   LoadingSubtitle = "by robloxscript10-a11y",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "4SeiKenHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
      Invite = "",
      RememberJoins = false
   },
   KeySystem = false,
})

-- // Themes
local themes = {
    Default = Color3.fromRGB(255, 0, 0),
    Blue = Color3.fromRGB(0, 170, 255),
    Green = Color3.fromRGB(0, 255, 100),
    Purple = Color3.fromRGB(170, 0, 255),
    Orange = Color3.fromRGB(255, 140, 0),
    Pink = Color3.fromRGB(255, 105, 180),
    Yellow = Color3.fromRGB(255, 255, 0),
    White = Color3.fromRGB(255, 255, 255),
}

local ThemeTab = Window:CreateTab("Themes", 4483362458)
ThemeTab:CreateDropdown({
   Name = "Select Theme",
   Options = {"Default", "Blue", "Green", "Purple", "Orange", "Pink", "Yellow", "White"},
   CurrentOption = "Default",
   Callback = function(option)
      Rayfield:Notify({Title="Theme", Content="Theme changed to "..option, Duration=3})
      Rayfield:ChangeColor(themes[option])
   end,
})

-- // Auto Block Script
local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateButton({
   Name = "Enable Auto Block",
   Callback = function()
      loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidi399/Auto-block-script/refs/heads/main/FINAL%20AUTO%20BLOCK"))()
      Rayfield:Notify({Title="Auto Block", Content="Auto Block Loaded!", Duration=3})
   end
})

-- // ESP
local VisualTab = Window:CreateTab("Visuals", 4483362458)
VisualTab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Callback = function(Value)
      if Value then
         local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/zntly/highlight-esp/main/main.lua"))()
         Rayfield:Notify({Title="ESP", Content="ESP Enabled!", Duration=3})
      else
         Rayfield:Notify({Title="ESP", Content="ESP Disabled (rejoin to remove)", Duration=3})
      end
   end,
})

-- // Misc
local MiscTab = Window:CreateTab("Misc", 4483362458)
MiscTab:CreateButton({
   Name = "Rejoin Game",
   Callback = function()
      game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
   end
})
MiscTab:CreateButton({
   Name = "Reset Character",
   Callback = function()
      game.Players.LocalPlayer.Character:BreakJoints()
   end
})
