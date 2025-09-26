-- ============================
-- GUI EDUCATIVA para Delta Executor (Roblox)
-- Propósito: somente aprendizado de UI (drag, floating, toggle)
-- NÃO altera estados do jogo nem fornece cheats.
-- Cole em um executor que rode scripts cliente (LocalScript style).
-- ============================

-- Helper: cria instâncias com propriedades em uma chamada
local function new(className, props)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

-- ============================
-- CONFIGS VISUAIS (personalize aqui)
-- ============================
local FLOAT_SIZE = UDim2.fromOffset(60, 60)         -- tamanho do botão flutuante
local MENU_SIZE  = UDim2.fromOffset(300, 380)       -- tamanho do menu
local RED_COLOR  = Color3.fromRGB(200, 30, 30)      -- cor vermelha (pode ajustar)
local TITLE_TEXT = "SXTh3usMods"                    -- texto do título (pedido)

-- ============================
-- ROOT GUI (ScreenGui)
-- ============================
-- Criamos uma ScreenGui que conterá o floating + menu
local screenGui = new("ScreenGui", {
    Name = "SXTh3usMods_GUI",
    ResetOnSpawn = false, -- não remover ao respawn (se for usado localmente)
    Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    -- Nota: alguns executores já setam Parent automaticamente; se der erro, ajuste para PlayerGui.
})

-- ============================
-- BOTÃO FLUTUANTE (floating)
-- ============================
local floating = new("Frame", {
    Name = "FloatingButton",
    Size = FLOAT_SIZE,
    Position = UDim2.new(0.02, 0, 0.4, 0), -- posição inicial (esquerda da tela)
    BackgroundColor3 = RED_COLOR,
    AnchorPoint = Vector2.new(0,0),
    Parent = screenGui,
})

-- bordas arredondadas (UICorner)
local cornerFloat = new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = floating})
-- botão visual dentro do frame (um TextButton para clique)
local floatBtn = new("TextButton", {
    Name = "OpenBtn",
    Size = UDim2.fromScale(1,1),
    Position = UDim2.fromOffset(0,0),
    BackgroundTransparency = 1, -- usa a cor do frame
    Text = "", -- sem texto para ficar só ícone; você pode colocar emoji "≡" ou "○"
    Parent = floating,
})

-- ícone (TextLabel) dentro do botão para visual
local floatIcon = new("TextLabel", {
    Name = "Icon",
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    Text = "≡", -- ícone simples, altere se quiser
    TextColor3 = Color3.new(1,1,1),
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    Parent = floating,
})

-- ============================
-- MENU PRINCIPAL (inicialmente escondido)
-- ============================
local menu = new("Frame", {
    Name = "MainMenu",
    Size = MENU_SIZE,
    Position = UDim2.new(0.15, 0, 0.25, 0),
    Visible = false, -- começa oculto
    BackgroundColor3 = RED_COLOR,
    Parent = screenGui,
})

local menuCorner = new("UICorner", {CornerRadius = UDim.new(0, 12), Parent = menu})
local menuPadding = new("UIPadding", {PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), Parent = menu})

-- TÍTULO
local title = new("TextLabel", {
    Name = "SXTh3usMods '-'",
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1,
    Text = TITLE_TEXT,
    TextColor3 = Color3.new(1,1,1),
    TextScaled = true,
    Font = Enum.Font.GothamBold,
    Parent = menu,
})

-- ÁREA DE CONTEÚDO (onde botões vão ficar)
local content = new("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -20, 1, -60),
    Position = UDim2.fromOffset(10, 50),
    BackgroundTransparency = 1,
    Parent = menu,
})

-- Layout vertical para organizar botões
local layout = new("UIListLayout", {
    Parent = content,
    Padding = UDim.new(0, 8),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})

-- Função utilitária: cria um botão de menu (apenas exemplo visual)
local function createMenuButton(text, callback)
    local btn = new("TextButton", {
        Name = text:gsub("%s","_"),
        Size = UDim2.new(0.9, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(230, 60, 60),
        Text = text,
        TextColor3 = Color3.new(1,1,1),
        TextScaled = true,
        Font = Enum.Font.Gotham,
        Parent = content,
    })
    new("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn})
    btn.MouseButton1Click:Connect(function()
        pcall(callback) -- callback protegido para evitar erros que travem o GUI
    end)
    return btn
end

-- Exemplo de botões que NÃO alteram o jogo, só mostram mensagens no console.
createMenuButton("Função Exemplo 1", function()
    print("[SXTh3usMods] Função Exemplo 1 ativada (apenas demo).")
end)

createMenuButton("Função Exemplo 2", function()
    print("[SXTh3usMods] Função Exemplo 2 ativada (apenas demo).")
end)

createMenuButton("Fechar Menu", function()
    menu.Visible = false
end)

-- ============================
-- LÓGICA: abrir/fechar menu ao clicar no floating
-- ============================
floatBtn.MouseButton1Click:Connect(function()
    menu.Visible = not menu.Visible
end)

-- ============================
-- DRAG (arrastar) - função reutilizável
-- Explicação: faz o objeto seguir o ponteiro enquanto o botão do mouse estiver pressionado.
-- ============================
local UserInputService = game:GetService("UserInputService")

-- dragify: torna qualquer GuiObject arrastável
local function dragify(guiObject)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    local function onInputChanged(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            -- Converte delta (pixels) pra posição relativa da tela:
            local absSize = workspace.CurrentCamera.ViewportSize
            -- startPos é UDim2; convertemos para pixels e adicionamos delta:
            local startX = startPos.X.Offset + startPos.X.Scale * absSize.X
            local startY = startPos.Y.Offset + startPos.Y.Scale * absSize.Y
            local newX = (startX + delta.X)
            local newY = (startY + delta.Y)
            -- converter de volta pra UDim2 mantendo escala 0:
            guiObject.Position = UDim2.new(0, newX, 0, newY)
        end
    end

    guiObject.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            onInputChanged(input)
        end
    end)
end

-- Aplica drag ao floating e ao menu (para mover ambos)
dragify(floating)
dragify(menu)

-- ============================
-- EXPLICAÇÕES IMPORTANTES (resumo)
-- ============================
-- 1) ScreenGui: raiz para elementos 2D na tela.
-- 2) Frame: contêiner visual (usado para floating e menu).
-- 3) UICorner: deixa os cantos arredondados (CornerRadius em pixels ou em escala).
-- 4) TextButton/TextLabel: elementos clicáveis / texto.
-- 5) dragify(): função que "escuta" início do clique (InputBegan) e movimento do mouse,
--    calcula delta em pixels e atualiza Position do GUI — por isso o menu/floating "seguem" o cursor.
-- 6) Os botões de menu aqui chamam callbacks que apenas usam print() — isso significa
--    que não alteram o estado do jogo e servem apenas para aprendizado.
-- ============================