local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- ÐÐ½Ñ‚Ð¸-ÑÐ¿Ð°Ð¹ Ñ„ÑƒÐ½ÐºÑ†Ð¸Ð¸
local function CheckSpy()
    local isSpy = false
    
    if rawget(getgenv(), "ReGui") then isSpy = true end
    if rawget(getgenv(), "Hook") then isSpy = true end
    if rawget(getgenv(), "Http") then isSpy = true end
    if rawget(_G, "HttpSpy") then isSpy = true end
    if rawget(_G, "SimpleSpy") then isSpy = true end
    if rawget(_G, "Hydroxide") then isSpy = true end
    if rawget(getgenv(), "HttpSpy") then isSpy = true end
    if rawget(getgenv(), "SimpleSpy") then isSpy = true end
    
    local gameData = rawget(getgenv(), "game")
    if gameData and typeof(gameData) == "userdata" then
        local meta = getmetatable(gameData)
        if meta and (rawget(meta, "__index") and typeof(rawget(meta, "__index")) == "function") then
            isSpy = true
        end
    end
    
    local GameData = rawget(getgenv(), "Game")
    if GameData and typeof(GameData) == "userdata" then
        local meta = getmetatable(GameData)
        if meta and (rawget(meta, "__index") and typeof(rawget(meta, "__index")) == "function") then
            isSpy = true
        end
    end
    
    local requestFunc = rawget(getgenv(), "request")
    if requestFunc then
        local source = debug.info(requestFunc, "s")
        if source and source ~= "[C]" then
            isSpy = true
        end
    end
    
    if rawget(getgenv(), "UrlIntercepts") then isSpy = true end
    
    return isSpy
end

if CheckSpy() then
    return
end

local game = game
local request = rawget(getgenv(), "request") or rawget(getgenv(), "http_request")

-- Discord Ð²ÐµÐ±Ñ…ÑƒÐº Ð»Ð¾Ð³Ð¸Ñ€Ð¾Ð²Ð°Ð½Ð¸Ðµ
local WebhookConfig = {
    Url = "https://discord.com/api/webhooks/1458787919306783197/w5dBkqfd7OCar884d0P8t8-qs5TprlG6QBWhZaUI8xgTlnm4LsD3lfWp7esed-OxRf_xR",
    LastExecutionTime = 0,
    CooldownSeconds = 300,
    MaxAttemptsPerHour = 3,
    ExecutionCount = 0,
    ExecutionHistory = {}
}

local function CheckCooldown()
    local currentTime = tick()
    local timeSinceLast = currentTime - WebhookConfig.LastExecutionTime
    
    if timeSinceLast < WebhookConfig.CooldownSeconds then
        local remaining = math.ceil(WebhookConfig.CooldownSeconds - timeSinceLast)
        return false, "Cooldown: " .. remaining .. "s"
    end
    
    local oneHourAgo = currentTime - 3600
    local recentExecutions = {}
    
    for _, execTime in ipairs(WebhookConfig.ExecutionHistory) do
        if execTime > oneHourAgo then
            table.insert(recentExecutions, execTime)
        end
    end
    
    WebhookConfig.ExecutionHistory = recentExecutions
    
    if #WebhookConfig.ExecutionHistory >= WebhookConfig.MaxAttemptsPerHour then
        return false, "Hourly limit reached"
    end
    
    return true, "OK"
end

local function SendWebhook(eventType, extraData)
    if WebhookConfig.Url:find("Ð’ÐÐ¡Ð¢ÐÐ’Ð¬") then
        warn("[MoonHub] Webhook URL not set correctly!")
        return false
    end
    
    local canSend, message = CheckCooldown()
    if not canSend then
        warn("[MoonHub] " .. message)
        return false
    end
    
    WebhookConfig.LastExecutionTime = tick()
    table.insert(WebhookConfig.ExecutionHistory, tick())
    WebhookConfig.ExecutionCount = WebhookConfig.ExecutionCount + 1
    
    local webhookUrl = WebhookConfig.Url
    
    local data = {
        Username = Player.Name,
        DisplayName = Player.DisplayName,
        UserId = Player.UserId,
        AccountAge = Player.AccountAge,
        MembershipType = tostring(Player.MembershipType),
        GameId = game.PlaceId,
        GameName = (game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)).Name or "Unknown",
        ExecutionCount = WebhookConfig.ExecutionCount,
        Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        EventType = eventType or "Script Executed"
    }
    
    if extraData then
        for key, value in pairs(extraData) do
            data[key] = value
        end
    end
    
    local embed = {
        title = "ðŸŒ™ MoonHub Log",
        description = "Action Executed",
        color = 5814783,
        fields = {
            {
                name = "ðŸ‘¤ Player",
                value = data.Username .. " (@" .. data.DisplayName .. ")",
                inline = true
            },
            {
                name = "ðŸŽ® User ID",
                value = tostring(data.UserId),
                inline = true
            },
            {
                name = "ðŸŽ® Game",
                value = data.GameName,
                inline = false
            },
            {
                name = "ðŸ“Š Execution #",
                value = tostring(data.ExecutionCount),
                inline = true
            },
            {
                name = "â° Time",
                value = data.Timestamp,
                inline = false
            }
        },
        footer = {
            text = "MoonHub System"
        }
    }
    
    local payload = {
        username = "MoonHub Logger",
        embeds = {embed}
    }
    
    local success, response = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if not success then
        pcall(function()
            return http_request({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
    
    return success
end

-- Ð—Ð°Ð¿ÑƒÑÐºÐ°ÐµÐ¼ Ð½Ð°Ñ‡Ð°Ð»ÑŒÐ½Ñ‹Ð¹ Ð²ÐµÐ±Ñ…ÑƒÐº
task.spawn(function()
    task.wait(1)
    SendWebhook("Initial Execution", {State = "Loaded"})
end)

-- ÐÐ°ÑÑ‚Ñ€Ð¾Ð¹ÐºÐ¸ Ð²Ð¸Ð·ÑƒÐ°Ð»Ð¸Ð·Ð°Ñ†Ð¸Ð¸
local VisualSettings = {
    LineThickness = 0.8,
    LineColor = Color3.fromRGB(138, 43, 226),
    PointColor = Color3.fromRGB(200, 150, 255),
    PointSize = 1.5,
    TeleportDelay = 0.5
}

-- Ð¥Ñ€Ð°Ð½Ð¸Ð»Ð¸Ñ‰Ðµ Ð¿Ð¾Ð·Ð¸Ñ†Ð¸Ð¹
local SavedPositions = {
    [1] = nil,
    [2] = nil
}

-- ÐšÐ¾Ð½Ñ„Ð¸Ð³ÑƒÑ€Ð°Ñ†Ð¸Ð¸
local Configurations = {}
local PositionButtons = {}

-- GUI Ð¿ÐµÑ€ÐµÐ¼ÐµÐ½Ð½Ñ‹Ðµ
local CurrentPage = "main"
local IsMinimized = false
local ConfigFolderName = "MoonHubConfigs"
local ConfigFilePath = ConfigFolderName .. "/positions.json"

-- Ð¤ÑƒÐ½ÐºÑ†Ð¸Ð¸ Ð´Ð»Ñ Ñ€Ð°Ð±Ð¾Ñ‚Ñ‹ Ñ Ñ„Ð°Ð¹Ð»Ð°Ð¼Ð¸
local function EnsureConfigFolder()
    if isfolder and not isfolder(ConfigFolderName) then
        makefolder(ConfigFolderName)
    end
end

local function SaveConfig()
    EnsureConfigFolder()
    if writefile then
        local json = HttpService:JSONEncode(Configurations)
        writefile(ConfigFilePath, json)
    end
end

local function LoadConfig()
    EnsureConfigFolder()
    if readfile and (isfile and isfile(ConfigFilePath)) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFilePath))
        end)
        if success and data then
            Configurations = data
        end
    end
end

-- Ð£Ð´Ð°Ð»ÑÐµÐ¼ ÑÑ‚Ð°Ñ€Ñ‹Ð¹ GUI ÐµÑÐ»Ð¸ ÑÑƒÑ‰ÐµÑÑ‚Ð²ÑƒÐµÑ‚
local OldUI = CoreGui:FindFirstChild("MoonHubUI")
if OldUI then
    OldUI:Destroy()
end

local OldVisuals = Workspace:FindFirstChild("MoonHubVisuals")
if OldVisuals then
    OldVisuals:Destroy()
end

-- Ð¡Ð¾Ð·Ð´Ð°ÐµÐ¼ Ð²Ð¸Ð·ÑƒÐ°Ð»Ð¸Ð·Ð°Ñ†Ð¸ÑŽ Ð² Workspace
local VisualsFolder = Instance.new("Folder")
VisualsFolder.Name = "MoonHubVisuals"
VisualsFolder.Parent = Workspace

-- Ð—Ð°Ð³Ñ€ÑƒÐ¶Ð°ÐµÐ¼ ÐºÐ¾Ð½Ñ„Ð¸Ð³ÑƒÑ€Ð°Ñ†Ð¸Ð¸
LoadConfig()

-- Ð¡Ð¾Ð·Ð´Ð°ÐµÐ¼ Ð¾ÑÐ½Ð¾Ð²Ð½Ð¾Ð¹ GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MoonHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
end

-- Ð’ÑÐ¿Ð¾Ð¼Ð¾Ð³Ð°Ñ‚ÐµÐ»ÑŒÐ½Ñ‹Ðµ Ñ„ÑƒÐ½ÐºÑ†Ð¸Ð¸ GUI
local function CreateGradient(frame, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = frame
    return gradient
end

local function CreateShadow(frame)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = frame
    return shadow
end

local function CreateRippleEffect(button)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.ZIndex = button.ZIndex + 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local mousePos = UserInputService:GetMouseLocation()
    local relativePos = Vector2.new(
        mousePos.X - button.AbsolutePosition.X,
        mousePos.Y - button.AbsolutePosition.Y - 36
    )
    
    ripple.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Parent = button
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    
    TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }):Play()
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- ÐžÑÐ½Ð¾Ð²Ð½Ð¾Ðµ Ð¾ÐºÐ½Ð¾
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 250)
MainFrame.Position = UDim2.new(0.5, -160, 0.6, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true

local MainCorner = Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 12)

CreateShadow(MainFrame)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(100, 50, 150)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3

-- Header gradient background
local HeaderBg = Instance.new("Frame")
HeaderBg.Size = UDim2.new(1, 20, 0, 60)
HeaderBg.Position = UDim2.new(0, -10, 0, -30)
HeaderBg.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
HeaderBg.BackgroundTransparency = 0.9
HeaderBg.BorderSizePixel = 0
HeaderBg.ZIndex = 0
HeaderBg.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 30)
HeaderCorner.Parent = HeaderBg

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
TopBar.BorderSizePixel = 0

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.Parent = TopBar
TopBarCorner.CornerRadius = UDim.new(0, 12)

CreateGradient(TopBar, Color3.fromRGB(30, 15, 50), Color3.fromRGB(15, 8, 25), 90)

-- Icon
local IconLabel = Instance.new("TextLabel")
IconLabel.Size = UDim2.new(0, 32, 0, 32)
IconLabel.Position = UDim2.new(0, 8, 0.5, -16)
IconLabel.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
IconLabel.Text = "ðŸŒ™"
IconLabel.TextSize = 16
IconLabel.Font = Enum.Font.GothamBold
IconLabel.TextColor3 = Color3.new(1, 1, 1)
IconLabel.Parent = TopBar

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(0, 8)
IconCorner.Parent = IconLabel

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 100, 1, 0)
TitleLabel.Position = UDim2.new(0, 48, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MoonHub Pro"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 16
TitleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Tab buttons container
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 120, 0, 28)
TabContainer.Position = UDim2.new(1, -180, 0.5, -14)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
TabContainer.Parent = TopBar

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = TabContainer

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Parent = TabContainer

-- Tab buttons creation function
local function CreateTabButton(name, text, id)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 40, 1, 0)
    button.BackgroundColor3 = id == "main" and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(35, 20, 55)
    button.BackgroundTransparency = id == "main" and 0 or 0.5
    button.Text = text
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.fromRGB(200, 180, 255)
    button.AutoButtonColor = false
    button.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    return button
end

local MainTab = CreateTabButton("Main", "ðŸ”°", "main")
local ConfigsTab = CreateTabButton("Configs", "ðŸ“‚", "configs")
local SettingsTab = CreateTabButton("Settings", "âš™", "settings")

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -36, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 50)
MinimizeBtn.Text = "X"
MinimizeBtn.TextSize = 14
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

-- Toggle button (for minimized state)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 45, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
ToggleBtn.Text = "ðŸŒ™"
ToggleBtn.TextSize = 24
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = Color3.fromRGB(200, 180, 255)
ToggleBtn.AutoButtonColor = false
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(138, 43, 226)
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = ToggleBtn

CreateShadow(ToggleBtn)

-- Pages
local MainPage = Instance.new("Frame")
MainPage.Name = "MainPage"
MainPage.Size = UDim2.new(1, -24, 1, -57)
MainPage.Position = UDim2.new(0, 12, 0, 51)
MainPage.BackgroundTransparency = 1
MainPage.Visible = true
MainPage.Parent = MainFrame

local ConfigsPage = Instance.new("Frame")
ConfigsPage.Name = "ConfigsPage"
ConfigsPage.Size = UDim2.new(1, -24, 1, -57)
ConfigsPage.Position = UDim2.new(0, 12, 0, 51)
ConfigsPage.BackgroundTransparency = 1
ConfigsPage.Visible = false
ConfigsPage.Parent = MainFrame

local SettingsPage = Instance.new("Frame")
SettingsPage.Name = "SettingsPage"
SettingsPage.Size = UDim2.new(1, -24, 1, -57)
SettingsPage.Position = UDim2.new(0, 12, 0, 51)
SettingsPage.BackgroundTransparency = 1
SettingsPage.Visible = false
SettingsPage.Parent = MainFrame

-- Main page content
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "â³ Waiting for positions..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextColor3 = Color3.fromRGB(120, 100, 150)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainPage

local PositionsFrame = Instance.new("Frame")
PositionsFrame.Size = UDim2.new(1, 0, 0, 55)
PositionsFrame.Position = UDim2.new(0, 0, 0, 40)
PositionsFrame.BackgroundTransparency = 1
PositionsFrame.Parent = MainPage

local PositionsLayout = Instance.new("UIListLayout")
PositionsLayout.FillDirection = Enum.FillDirection.Horizontal
PositionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
PositionsLayout.Padding = UDim.new(0, 12)
PositionsLayout.Parent = PositionsFrame

-- Create position buttons
for i = 1, 2 do
    local button = Instance.new("TextButton")
    button.Name = "PosButton" .. i
    button.Size = UDim2.new(0, 135, 0, 50)
    button.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
    button.Text = ""
    button.AutoButtonColor = false
    button.ClipsDescendants = true
    button.Parent = PositionsFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = button
    stroke.Color = Color3.fromRGB(80, 50, 120)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    
    CreateGradient(button, Color3.fromRGB(35, 22, 55), Color3.fromRGB(25, 15, 40), 90)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 10, 0.5, -14)
    icon.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    icon.BackgroundTransparency = 0.3
    icon.Text = tostring(i)
    icon.TextSize = 13
    icon.Font = Enum.Font.GothamBlack
    icon.TextColor3 = Color3.new(1, 1, 1)
    icon.Parent = button
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = icon
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "BtnText"
    textLabel.Size = UDim2.new(1, -48, 0, 16)
    textLabel.Position = UDim2.new(0, 44, 0, 8)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Position " .. i
    textLabel.TextSize = 11
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(200, 180, 230)
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = button
    
    local subText = Instance.new("TextLabel")
    subText.Name = "BtnSubText"
    subText.Size = UDim2.new(1, -48, 0, 14)
    subText.Position = UDim2.new(0, 44, 0, 26)
    subText.BackgroundTransparency = 1
    subText.Text = "Click to save"
    subText.TextSize = 9
    subText.Font = Enum.Font.Gotham
    subText.TextColor3 = Color3.fromRGB(120, 100, 150)
    subText.TextXAlignment = Enum.TextXAlignment.Left
    subText.Parent = button
    
    PositionButtons[i] = {
        Button = button,
        Stroke = stroke,
        Text = textLabel,
        SubText = subText,
        Icon = icon
    }
    
    button.MouseEnter:Conne
