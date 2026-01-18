--// =========================
--// PANEL
--// =========================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

if _G.PanelLoaded then return end
_G.PanelLoaded = true

--// =========================
--// UI
--// =========================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(320, 230)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
frame.BackgroundTransparency = 0.18
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 80, 80)
stroke.Transparency = 0.3

-- TITRE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 42)
title.BackgroundTransparency = 1
title.Text = "SHIN HUB"
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Center

-- DISCORD
local discord = Instance.new("TextLabel", frame)
discord.Size = UDim2.new(1, -20, 0, 18)
discord.Position = UDim2.fromOffset(10, 42)
discord.BackgroundTransparency = 1
discord.Text = "discord.gg/g4GSd2zPx"
discord.Font = Enum.Font.GothamBold
discord.TextSize = 13
discord.TextColor3 = Color3.fromRGB(255,255,255)
discord.TextXAlignment = Enum.TextXAlignment.Center
discord.Active = true
discord.Selectable = true

discord.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		setclipboard("https://discord.gg/g4GSd2zPx")
	end
end)

--// =========================
--// BOUTONS
--// =========================
local function createButton(text, yPos, callback)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.fromOffset(220, 40)
	btn.Position = UDim2.fromOffset(50, yPos)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = Color3.fromRGB(110, 0, 0)
	btn.BackgroundTransparency = 0.1
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(180, 0, 0)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(110, 0, 0)
		}):Play()
	end)

	btn.MouseButton1Click:Connect(callback)
end

-- DESYNC
createButton("DESYNC", 80, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/CnjpBEax"))()
end)

-- INSTANT STEAL
createButton("INSTANT STEAL", 130, function()
	loadstring(game:HttpGet("https://pastebin.com/raw/ThyPmzS6"))()
end)
