-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Очистка предыдущего запуска
if getgenv().HTrungCleanup then
    pcall(getgenv().HTrungCleanup)
end

-- Таблица состояний
local States = {
    Fly = false, FlyUp = false, FlyDown = false,
    Noclip = false, InfJump = false, AutoJump = false, AutoRun = false,
    FreeCam = false, FreeCamSpeed = 50,
    Aimbot = false, Hitbox = false, ESP = false, KillAura = false,
    Dodge = false, GodMode = false, Wallbang = false,
    AutoItemTp = false, ItemTpSpeed = 0.5,
    AntiAFK = false, Fullbright = false, AutoClick = false, RemoveParticles = false,
    AntiFling = false, Glide = false, ItemESP = false, XRay = false, AntiVoid = false, UnlockFPS = false,
    ResetTime = false, AutoClaim = false, SpamRemote = false,
    Speed = 16, JumpPower = 50, FlySpeed = 60, HitboxSize = 10, AuraRange = 2000
}

-- Переменные
local freeCamCFrame = CFrame.new()
local freeCamRotX, freeCamRotY = 0, 0
local freeCamInput = {F=false, B=false, L=false, R=false, U=false, D=false}
local lastAuraAttack = 0
local lastHealth = 100
local dodgeCooldown = 0
local godModeThread = nil
local oldRaycast = nil
local autoClickThread = nil
local autoItemTpThread = nil
local scannedItems = {}

local Connections = {}
local ESPObjects = {}

-- ==========================================
-- HTTP REQUEST CHO SERVER HOP
-- ==========================================
local function httpGet(url)
    if syn and syn.request then
        return syn.request({Url = url, Method = "GET"}).Body
    elseif http_request then
        return http_request({Url = url, Method = "GET"}).Body
    elseif request then
        return request({Url = url, Method = "GET"}).Body
    end
    return nil
end

-- ==========================================
-- HÀM CLICK CHUẨN CHO MOBILE
-- ==========================================
local function bindClick(button, callback)
    local lastFire = 0
    local function fire()
        local now = tick()
        if now - lastFire < 0.2 then return end
        lastFire = now
        callback()
    end

    button.Activated:Connect(fire)
    
    local pressed = false
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = true
        end
    end)
    button.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and pressed then
            pressed = false
            fire()
        end
    end)
end

local function makeDraggable(frame, dragArea)
    local dragging, dragInput, dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function bindHold(button, callbackDown, callbackUp)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            callbackDown()
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            callbackUp()
        end
    end)
end

-- ==========================================
-- HOOK WALLBANG (XUYÊN TƯỜNG)
-- ==========================================
if hookfunction and workspace.Raycast then
    oldRaycast = hookfunction(workspace.Raycast, function(self, origin, direction, params)
        if States.Wallbang and params then
            local newParams = RaycastParams.new()
            newParams.FilterType = Enum.RaycastFilterType.Include
            local chars = {}
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then table.insert(chars, plr.Character) end
            end
            newParams.FilterDescendantsInstances = chars
            return oldRaycast(self, origin, direction, newParams)
        end
        return oldRaycast(self, origin, direction, params)
    end)
end

-- Создание GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ScriptVipByHTrung"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 2147483647

-- Nút mở menu (AVATAR NHÂN VẬT)
local openButton = Instance.new("ImageButton")
openButton.Size = UDim2.new(0, 50, 0, 50)
openButton.Position = UDim2.new(0, 10, 0, 100)
openButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
openButton.BackgroundTransparency = 0.2
openButton.BorderSizePixel = 0
openButton.ZIndex = 100
openButton.ScaleType = Enum.ScaleType.Crop 
openButton.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
openButton.Parent = gui

local oc = Instance.new("UICorner") oc.CornerRadius = UDim.new(0, 10) oc.Parent = openButton
local os = Instance.new("UIStroke") os.Color = Color3.fromRGB(255, 50, 50) os.Thickness = 2 os.Parent = openButton

-- ==========================================
-- NỔI BÊN NGOÀI: BẢNG ĐIỀU KHIỂN BAY (FLY)
-- ==========================================
local flyOverlay = Instance.new("Frame")
flyOverlay.Size = UDim2.new(0, 180, 0, 50)
flyOverlay.Position = UDim2.new(1, -200, 1, -150)
flyOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
flyOverlay.BackgroundTransparency = 0.3
flyOverlay.Visible = false
flyOverlay.ZIndex = 90
flyOverlay.Parent = gui
local foc = Instance.new("UICorner") foc.CornerRadius = UDim.new(0, 8) foc.Parent = flyOverlay
local fos = Instance.new("UIStroke") fos.Color = Color3.fromRGB(100, 100, 100) fos.Thickness = 1 fos.Parent = flyOverlay

local btnFlyUp = Instance.new("TextButton") btnFlyUp.Size = UDim2.new(0.45, 0, 1, -10) btnFlyUp.Position = UDim2.new(0.03, 0, 0, 5) btnFlyUp.BackgroundColor3 = Color3.fromRGB(30, 70, 30) btnFlyUp.TextColor3 = Color3.fromRGB(255, 255, 255) btnFlyUp.Font = Enum.Font.GothamBold btnFlyUp.Text = "LÊN" btnFlyUp.ZIndex = 91 btnFlyUp.Parent = flyOverlay
local uc1 = Instance.new("UICorner") uc1.CornerRadius = UDim.new(0, 6) uc1.Parent = btnFlyUp
local btnFlyDown = Instance.new("TextButton") btnFlyDown.Size = UDim2.new(0.45, 0, 1, -10) btnFlyDown.Position = UDim2.new(0.52, 0, 0, 5) btnFlyDown.BackgroundColor3 = Color3.fromRGB(70, 30, 30) btnFlyDown.TextColor3 = Color3.fromRGB(255, 255, 255) btnFlyDown.Font = Enum.Font.GothamBold btnFlyDown.Text = "XUỐNG" btnFlyDown.ZIndex = 91 btnFlyDown.Parent = flyOverlay
local dc1 = Instance.new("UICorner") dc1.CornerRadius = UDim.new(0, 6) dc1.Parent = btnFlyDown

bindHold(btnFlyUp, function() States.FlyUp = true end, function() States.FlyUp = false end)
bindHold(btnFlyDown, function() States.FlyDown = true end, function() States.FlyDown = false end)
makeDraggable(flyOverlay, flyOverlay)

-- ==========================================
-- NỔI BÊN NGOÀI: BẢNG ĐIỀU KHIỂN FREECAM
-- ==========================================
local fcOverlay = Instance.new("Frame")
fcOverlay.Size = UDim2.new(0, 180, 0, 200) 
fcOverlay.Position = UDim2.new(1, -200, 1, -380)
fcOverlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
fcOverlay.BackgroundTransparency = 0.3
fcOverlay.Visible = false
fcOverlay.ZIndex = 90
fcOverlay.Parent = gui
local fcoc = Instance.new("UICorner") fcoc.CornerRadius = UDim.new(0, 8) fcoc.Parent = fcOverlay
local fcos = Instance.new("UIStroke") fcos.Color = Color3.fromRGB(100, 100, 100) fcos.Thickness = 1 fcos.Parent = fcOverlay

local function createFcBtn(text, x, y, w, h, key)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w, 0, h, 0)
    b.Position = UDim2.new(x, 0, y, 0)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Text = text
    b.ZIndex = 91
    b.Parent = fcOverlay
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    bindHold(b, function() freeCamInput[key] = true end, function() freeCamInput[key] = false end)
    return b
end

createFcBtn("▲", 0.35, 0.05, 0.3, 0.15, "U")
createFcBtn("◀", 0.05, 0.22, 0.25, 0.15, "L")
createFcBtn("▼", 0.35, 0.4, 0.3, 0.15, "D")
createFcBtn("▶", 0.70, 0.22, 0.25, 0.15, "R")
createFcBtn("TIẾN", 0.35, 0.22, 0.3, 0.15, "F")
createFcBtn("LÙI", 0.35, 0.58, 0.3, 0.15, "B")

local teleBtn = Instance.new("TextButton")
teleBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
teleBtn.Position = UDim2.new(0.05, 0, 0.78, 0)
teleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
teleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleBtn.Font = Enum.Font.GothamBold
teleBtn.TextScaled = true
teleBtn.Text = "TELE ĐẾN ĐÂY"
teleBtn.ZIndex = 91
teleBtn.Parent = fcOverlay
local teCorner = Instance.new("UICorner") teCorner.CornerRadius = UDim.new(0, 6) teCorner.Parent = teleBtn

bindClick(teleBtn, function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = Camera.CFrame + Vector3.new(0, 3, 0)
    end
end)

makeDraggable(fcOverlay, fcOverlay)

-- ==========================================
-- GIAO DIỆN MENU CHÍNH
-- ==========================================
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 500, 0, 420)
menu.Position = UDim2.new(0.5, -250, 0.5, -210)
menu.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
menu.BorderSizePixel = 0
menu.Visible = false
menu.ZIndex = 50
menu.Parent = gui
local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0, 8) mc.Parent = menu
local ms = Instance.new("UIStroke") ms.Color = Color3.fromRGB(60, 60, 60) ms.Thickness = 1 ms.Parent = menu

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "Script Vip By HTrung"
title.ZIndex = 51
title.Parent = menu
local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(0, 8) tc.Parent = title

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 52
closeButton.Parent = menu

local sidebar = Instance.new("ScrollingFrame")
sidebar.Size = UDim2.new(0, 100, 1, -40)
sidebar.Position = UDim2.new(0, 5, 0, 35)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 2
sidebar.ZIndex = 51
sidebar.Parent = menu
local tabLayout = Instance.new("UIListLayout") tabLayout.Padding = UDim.new(0, 5) tabLayout.Parent = sidebar

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -115, 1, -40)
contentFrame.Position = UDim2.new(0, 110, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 51
contentFrame.Parent = menu

local function createTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -5, 0, 30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.Text = name
    tabBtn.BorderSizePixel = 0
    tabBtn.ZIndex = 52
    tabBtn.Parent = sidebar
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = tabBtn
    
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.Visible = false
    frame.ZIndex = 52
    frame.Parent = contentFrame
    local layout = Instance.new("UIListLayout") layout.Padding = UDim.new(0, 5) layout.Parent = frame
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    bindClick(tabBtn, function()
        for _, child in pairs(contentFrame:GetChildren()) do if child:IsA("ScrollingFrame") then child.Visible = false end end
        for _, child in pairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(30, 30, 30) child.TextColor3 = Color3.fromRGB(200, 200, 200) end
        end
        frame.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return frame
end

local function createToggle(parent, text, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = initialState and Color3.fromRGB(30, 70, 30) or Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = initialState and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Text = text .. ": " .. (initialState and "ON" or "OFF")
    btn.BorderSizePixel = 0
    btn.ZIndex = 53
    btn.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    
    local state = initialState
    bindClick(btn, function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(30, 70, 30) or Color3.fromRGB(40, 40, 40)
        btn.TextColor3 = state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

local function createSlider(parent, text, min, max, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 53
    frame.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Text = text .. ": " .. initial
    label.ZIndex = 54
    label.Parent = frame
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 6) lc.Parent = label
    
    local minus = Instance.new("TextButton") minus.Size = UDim2.new(0.15, -2, 1, 0) minus.Position = UDim2.new(0.61, 0, 0, 0) minus.BackgroundColor3 = Color3.fromRGB(70, 30, 30) minus.TextColor3 = Color3.fromRGB(255, 255, 255) minus.Font = Enum.Font.GothamBold minus.Text = "-" minus.ZIndex = 54 minus.Parent = frame
    local minc = Instance.new("UICorner") minc.CornerRadius = UDim.new(0, 6) minc.Parent = minus
    local plus = Instance.new("TextButton") plus.Size = UDim2.new(0.15, -2, 1, 0) plus.Position = UDim2.new(0.77, 0, 0, 0) plus.BackgroundColor3 = Color3.fromRGB(30, 70, 30) plus.TextColor3 = Color3.fromRGB(255, 255, 255) plus.Font = Enum.Font.GothamBold plus.Text = "+" plus.ZIndex = 54 plus.Parent = frame
    local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 6) pc.Parent = plus
    
    local val = initial
    local step = (max > 100 and 50 or 0.1)
    bindClick(minus, function() 
        val = math.max(min, val - step) 
        if max <= 100 then label.Text = text .. ": " .. string.format("%.1f", val) else label.Text = text .. ": " .. val end
        callback(val) 
    end)
    bindClick(plus, function() 
        val = math.min(max, val + step) 
        if max <= 100 then label.Text = text .. ": " .. string.format("%.1f", val) else label.Text = text .. ": " .. val end
        callback(val) 
    end)
end

-- ==========================================
-- VKЛАДКА 1: INFO
-- ==========================================
local infoTab = createTab("INFO")

local profileBox = Instance.new("Frame")
profileBox.Size = UDim2.new(1, -10, 0, 80)
profileBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
profileBox.BorderSizePixel = 0
profileBox.ZIndex = 53
profileBox.Parent = infoTab
local pbc = Instance.new("UICorner") pbc.CornerRadius = UDim.new(0, 8) pbc.Parent = profileBox

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 60, 0, 60)
avatarImage.Position = UDim2.new(0, 10, 0.5, -30)
avatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
avatarImage.BorderSizePixel = 0
avatarImage.Image = "rbxthumb://type=Avatar&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
avatarImage.ScaleType = Enum.ScaleType.Crop
avatarImage.ZIndex = 54
avatarImage.Parent = profileBox
local ac = Instance.new("UICorner") ac.CornerRadius = UDim.new(1, 0) ac.Parent = avatarImage

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -85, 0, 20)
nameLabel.Position = UDim2.new(0, 80, 0, 20)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 14
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Text = LocalPlayer.DisplayName
nameLabel.ZIndex = 54
nameLabel.Parent = profileBox

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(1, -85, 0, 20)
idLabel.Position = UDim2.new(0, 80, 0, 40)
idLabel.BackgroundTransparency = 1
idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 12
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Text = "@" .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")"
idLabel.ZIndex = 54
idLabel.Parent = profileBox

local statBox = Instance.new("Frame")
statBox.Size = UDim2.new(1, -10, 0, 0)
statBox.AutomaticSize = Enum.AutomaticSize.Y
statBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statBox.BorderSizePixel = 0
statBox.ZIndex = 53
statBox.Parent = infoTab
local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0, 8) sbc.Parent = statBox
local sbPad = Instance.new("UIPadding") sbPad.PaddingTop = UDim.new(0, 8) sbPad.PaddingBottom = UDim.new(0, 8) sbPad.PaddingLeft = UDim.new(0, 10) sbPad.PaddingRight = UDim.new(0, 10) sbPad.Parent = statBox
local sbLayout = Instance.new("UIListLayout") sbLayout.SortOrder = Enum.SortOrder.LayoutOrder sbLayout.Padding = UDim.new(0, 4) sbLayout.Parent = statBox

local statTitle = Instance.new("TextLabel")
statTitle.Size = UDim2.new(1, 0, 0, 20)
statTitle.BackgroundTransparency = 1
statTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
statTitle.Font = Enum.Font.GothamBold
statTitle.TextSize = 13
statTitle.TextXAlignment = Enum.TextXAlignment.Left
statTitle.Text = "📊 THÔNG SỐ KỸ THUẬT"
statTitle.ZIndex = 54
statTitle.LayoutOrder = 1
statTitle.Parent = statBox
local fpsLabel = Instance.new("TextLabel") fpsLabel.Size = UDim2.new(1, 0, 0, 18) fpsLabel.BackgroundTransparency = 1 fpsLabel.TextColor3 = Color3.fromRGB(220, 220, 220) fpsLabel.Font = Enum.Font.Gotham fpsLabel.TextSize = 12 fpsLabel.TextXAlignment = Enum.TextXAlignment.Left fpsLabel.Text = "FPS: ..." fpsLabel.ZIndex = 54 fpsLabel.LayoutOrder = 2 fpsLabel.Parent = statBox
local pingLabel = Instance.new("TextLabel") pingLabel.Size = UDim2.new(1, 0, 0, 18) pingLabel.BackgroundTransparency = 1 pingLabel.TextColor3 = Color3.fromRGB(220, 220, 220) pingLabel.Font = Enum.Font.Gotham pingLabel.TextSize = 12 pingLabel.TextXAlignment = Enum.TextXAlignment.Left pingLabel.Text = "Ping: ... ms" pingLabel.ZIndex = 54 pingLabel.LayoutOrder = 3 pingLabel.Parent = statBox
local posLabel = Instance.new("TextLabel") posLabel.Size = UDim2.new(1, 0, 0, 18) posLabel.BackgroundTransparency = 1 posLabel.TextColor3 = Color3.fromRGB(220, 220, 220) posLabel.Font = Enum.Font.Gotham posLabel.TextSize = 12 posLabel.TextXAlignment = Enum.TextXAlignment.Left posLabel.Text = "Vị trí: X, Y, Z" posLabel.ZIndex = 54 posLabel.LayoutOrder = 4 posLabel.Parent = statBox
local serverLabel = Instance.new("TextLabel") serverLabel.Size = UDim2.new(1, 0, 0, 18) serverLabel.BackgroundTransparency = 1 serverLabel.TextColor3 = Color3.fromRGB(220, 220, 220) serverLabel.Font = Enum.Font.Gotham serverLabel.TextSize = 12 serverLabel.TextXAlignment = Enum.TextXAlignment.Left serverLabel.Text = "Server: ..." serverLabel.ZIndex = 54 serverLabel.LayoutOrder = 5 serverLabel.Parent = statBox

local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, -10, 0, 70)
btnFrame.BackgroundTransparency = 1
btnFrame.ZIndex = 53
btnFrame.Parent = infoTab

local rejoinBtn = Instance.new("TextButton")
rejoinBtn.Size = UDim2.new(1, 0, 0, 30)
rejoinBtn.Position = UDim2.new(0, 0, 0, 0)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.Font = Enum.Font.GothamBold
rejoinBtn.TextSize = 13
rejoinBtn.Text = "🔄 REJOIN SERVER"
rejoinBtn.BorderSizePixel = 0
rejoinBtn.ZIndex = 54
rejoinBtn.Parent = btnFrame
local rjc = Instance.new("UICorner") rjc.CornerRadius = UDim.new(0, 6) rjc.Parent = rejoinBtn

local hopBtn = Instance.new("TextButton")
hopBtn.Size = UDim2.new(1, 0, 0, 30)
hopBtn.Position = UDim2.new(0, 0, 0, 35)
hopBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 40)
hopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hopBtn.Font = Enum.Font.GothamBold
hopBtn.TextSize = 13
hopBtn.Text = "🌐 SERVER HOP"
hopBtn.BorderSizePixel = 0
hopBtn.ZIndex = 54
hopBtn.Parent = btnFrame
local hpc = Instance.new("UICorner") hpc.CornerRadius = UDim.new(0, 6) hpc.Parent = hopBtn

bindClick(rejoinBtn, function()
    rejoinBtn.Text = "ĐANG KẾT NỐI..."
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

bindClick(hopBtn, function()
    hopBtn.Text = "ĐANG TÌM SERVER..."
    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = httpGet(url)
        if response then
            local success, decoded = pcall(function() return HttpService:JSONDecode(response) end)
            if success and decoded and decoded.data then
                local validServers = {}
                for _, srv in pairs(decoded.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                        table.insert(validServers, srv.id)
                    end
                end
                if #validServers > 0 then
                    local randomServer = validServers[math.random(1, #validServers)]
                    hopBtn.Text = "ĐANG CHUYỂN..."
                    task.wait(0.5)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
                    end)
                else
                    hopBtn.Text = "SERVER ĐẦY! THỬ LẠI."
                    task.wait(2)
                    hopBtn.Text = "🌐 SERVER HOP"
                end
            else
                hopBtn.Text = "LỖI API! THỬ LẠI."
                task.wait(2)
                hopBtn.Text = "🌐 SERVER HOP"
            end
        else
            hopBtn.Text = "EXECUTOR CHẶN HTTP!"
            task.wait(2)
            hopBtn.Text = "🌐 SERVER HOP"
        end
    end)
end)

local lastFpsUpdate = tick()
local frameCount = 0
local currentFps = 0

table.insert(Connections, RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    if tick() - lastFpsUpdate >= 1 then
        currentFps = frameCount
        frameCount = 0
        lastFpsUpdate = tick()
        fpsLabel.Text = "FPS: " .. currentFps
    end
end))

task.spawn(function()
    while task.wait(0.5) do
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        pingLabel.Text = "Ping: " .. ping .. " ms"

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            posLabel.Text = string.format("Vị trí: X: %d, Y: %d, Z: %d", pos.X, pos.Y, pos.Z)
        else
            posLabel.Text = "Vị trí: Đang tải..."
        end

        serverLabel.Text = "Người chơi: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
    end
end)

-- ==========================================
-- VKЛАДКА 2: PLAYER
-- ==========================================
local playerTab = createTab("PLAYER")
createToggle(playerTab, "God Mode (Bất tử)", false, function(s) 
    States.GodMode = s 
    if s and not godModeThread then
        godModeThread = task.spawn(function()
            while States.GodMode do
                task.wait(0.1)
                local c = LocalPlayer.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if h then
                        if not c:FindFirstChild("GodModeForceField") then
                            local ff = Instance.new("ForceField") ff.Name = "GodModeForceField" ff.Visible = false ff.Parent = c
                        end
                        h.Health = h.MaxHealth
                    end
                end
            end
        end)
    elseif not s then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GodModeForceField") then 
            LocalPlayer.Character.GodModeForceField:Destroy() 
        end
    end
end)
createSlider(playerTab, "WalkSpeed", 16, 500, 16, function(v) States.Speed = v end)
createSlider(playerTab, "JumpPower", 50, 500, 50, function(v) States.JumpPower = v end)
createToggle(playerTab, "Infinite Jump", false, function(s) States.InfJump = s end)
createToggle(playerTab, "Auto Run (Tự chạy)", false, function(s) States.AutoRun = s end)
createToggle(playerTab, "Auto Jump (Tự nhảy)", false, function(s) States.AutoJump = s end)
createToggle(playerTab, "Chống Văng (Anti-Fling)", false, function(s) States.AntiFling = s end)
createToggle(playerTab, "Lướt Trên Không (Glide)", false, function(s) States.Glide = s end)
createToggle(playerTab, "Noclip (Xuyên tường)", false, function(s) 
    States.Noclip = s
    if not s and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
    end
end)
createToggle(playerTab, "Fly (Bay)", false, function(s)
    States.Fly = s
    flyOverlay.Visible = s
end)
createSlider(playerTab, "Fly Speed", 10, 500, 60, function(v) States.FlySpeed = v end)

-- ==========================================
-- VKЛАДКА 3: VISUALS
-- ==========================================
local visualTab = createTab("VISUALS")
createToggle(visualTab, "Player ESP (Highlight)", false, function(s)
    States.ESP = s
    if not s then for _, obj in pairs(ESPObjects) do if obj then obj:Destroy() end end table.clear(ESPObjects) end
end)
createToggle(visualTab, "Hiện Vật Phẩm (Item ESP)", false, function(s) States.ItemESP = s end)
createToggle(visualTab, "Nhìn Xuyên Tường (X-Ray)", false, function(s) 
    States.XRay = s
    if not s then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
                obj.LocalTransparencyModifier = 0
            end
        end
    end
end)
createSlider(visualTab, "FreeCam Speed", 10, 300, 50, function(v) States.FreeCamSpeed = v end)
createToggle(visualTab, "Free Camera (Tự do)", false, function(s)
    States.FreeCam = s
    local char = LocalPlayer.Character
    if s then
        freeCamCFrame = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        if char and char:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = nil
            char.Humanoid.WalkSpeed = 0
            char.Humanoid.JumpPower = 0
        end
        fcOverlay.Visible = true
        for k in pairs(freeCamInput) do freeCamInput[k] = false end
        local rx, ry, rz = freeCamCFrame:ToEulerAnglesYXZ()
        freeCamRotX = rx
        freeCamRotY = ry
    else
        Camera.CameraType = Enum.CameraType.Custom
        if char and char:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = char.Humanoid
            char.Humanoid.WalkSpeed = States.Speed
            char.Humanoid.JumpPower = States.JumpPower
        end
        fcOverlay.Visible = false
    end
end)

-- ==========================================
-- VKЛАДКА 4: COMBAT
-- ==========================================
local combatTab = createTab("COMBAT")
createToggle(combatTab, "Hitbox Expander", false, function(s) States.Hitbox = s end)
createSlider(combatTab, "Hitbox Size", 5, 50, 10, function(v) States.HitboxSize = v end)
createToggle(combatTab, "Aimbot (Camera Lock)", false, function(s) States.Aimbot = s end)
createToggle(combatTab, "Wallbang (Bắn xuyên tường)", false, function(s) States.Wallbang = s end)
createToggle(combatTab, "Kill Aura (Auto-Kill)", false, function(s) States.KillAura = s end)
createSlider(combatTab, "Aura Range", 10, 2000, 2000, function(v) States.AuraRange = v end)
createToggle(combatTab, "Auto Dodge (Né lùi)", false, function(s) States.Dodge = s end)

-- ==========================================
-- VKЛАДКА 5: FARM REWARD (MỚI)
-- ==========================================
local rewardTab = createTab("FARM REWARD")

createToggle(rewardTab, "Ép Thời Gian Về 0", false, function(s) States.ResetTime = s end)
createToggle(rewardTab, "Auto Bấm Nhận (UI)", false, function(s) States.AutoClaim = s end)
createToggle(rewardTab, "Spam Remote (Nhận Ngầm)", false, function(s) States.SpamRemote = s end)

local rewardNote = Instance.new("TextLabel")
rewardNote.Size = UDim2.new(1, -10, 0, 60)
rewardNote.BackgroundTransparency = 1
rewardNote.TextColor3 = Color3.fromRGB(200, 200, 200)
rewardNote.Font = Enum.Font.Gotham
rewardNote.TextSize = 11
rewardNote.TextWrapped = true
rewardNote.Text = "Bật 'Ép thời gian' và 'Auto bấm nhận' để tự động farm phần thưởng liên tục trên giao diện."
rewardNote.ZIndex = 53
rewardNote.Parent = rewardTab

-- Logic Ép thời gian & Auto Click UI
task.spawn(function()
    while true do
        task.wait(0.2)
        
        if States.ResetTime then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
                    local n = string.lower(obj.Name)
                    if string.find(n, "time") or string.find(n, "timer") or string.find(n, "countdown") or string.find(n, "cooldown") then
                        if obj:IsA("IntValue") or obj:IsA("NumberValue") then obj.Value = 0
                        elseif obj:IsA("StringValue") then obj.Value = "00:00" end
                    end
                end
            end
            for _, obj in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
                    local n = string.lower(obj.Name)
                    if string.find(n, "time") or string.find(n, "timer") or string.find(n, "countdown") or string.find(n, "cooldown") then
                        if obj:IsA("IntValue") or obj:IsA("NumberValue") then obj.Value = 0
                        elseif obj:IsA("StringValue") then obj.Value = "00:00" end
                    end
                end
            end
        end

        if States.AutoClaim then
            for _, obj in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local text = string.lower(obj.Text)
                    if string.find(text, "nhận") or string.find(text, "claim") or string.find(text, "free") then
                        pcall(function()
                            if firesignal then firesignal(obj.MouseButton1Click) else obj:Activate() end
                        end)
                    end
                end
            end
        end
    end
end)

-- Logic Spam Remote
task.spawn(function()
    while true do
        task.wait(0.5)
        if States.SpamRemote then
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    local name = string.lower(remote.Name)
                    if string.find(name, "claim") or string.find(name, "reward") or string.find(name, "daily") or string.find(name, "nhan") then
                        pcall(function()
                            if remote:IsA("RemoteEvent") then remote:FireServer() else remote:InvokeServer() end
                        end)
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- VKЛАДКА 6: TELEPORT
-- ==========================================
local tpTab = createTab("TELEPORT")
local savedPos1, savedPos2 = nil, nil
local autoTp1Active, autoTp2Active = false, false
local autoTp1Thread, autoTp2Thread = nil, nil

local function createTpBtn(text, bg)
    local b = Instance.new("TextButton") b.Size = UDim2.new(0.48, 0, 0, 30) b.BackgroundColor3 = bg b.TextColor3 = Color3.fromRGB(255, 255, 255) b.Font = Enum.Font.Gotham b.Text = text b.BorderSizePixel = 0 b.ZIndex = 53
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
    return b
end

local tpMouseBtn = Instance.new("TextButton")
tpMouseBtn.Size = UDim2.new(1, -10, 0, 35)
tpMouseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
tpMouseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpMouseBtn.Font = Enum.Font.GothamBold
tpMouseBtn.Text = "Dịch Đến Chuột (TP to Mouse)"
tpMouseBtn.BorderSizePixel = 0
tpMouseBtn.ZIndex = 53
tpMouseBtn.Parent = tpTab
local tmc = Instance.new("UICorner") tmc.CornerRadius = UDim.new(0, 6) tmc.Parent = tpMouseBtn

bindClick(tpMouseBtn, function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and Mouse.Hit then
        char.HumanoidRootPart.CFrame = Mouse.Hit + Vector3.new(0, 3, 0)
    end
end)

local savePos1Btn = createTpBtn("LƯU VỊ TRÍ 1", Color3.fromRGB(50,50,50)) savePos1Btn.Parent = tpTab
local savePos2Btn = createTpBtn("LƯU VỊ TRÍ 2", Color3.fromRGB(50,50,50)) savePos2Btn.Position = UDim2.new(0.52, 0, 0, 0) savePos2Btn.Parent = tpTab
local tpPos1Btn = createTpBtn("ĐẾN VỊ TRÍ 1", Color3.fromRGB(30,70,30)) tpPos1Btn.Parent = tpTab
local tpPos2Btn = createTpBtn("ĐẾN VỊ TRÍ 2", Color3.fromRGB(30,70,30)) tpPos2Btn.Position = UDim2.new(0.52, 0, 0, 0) tpPos2Btn.Parent = tpTab
local autoTp1Btn = createTpBtn("AUTO TP 1: OFF", Color3.fromRGB(40,40,40)) autoTp1Btn.Parent = tpTab
local autoTp2Btn = createTpBtn("AUTO TP 2: OFF", Color3.fromRGB(40,40,40)) autoTp2Btn.Position = UDim2.new(0.52, 0, 0, 0) autoTp2Btn.Parent = tpTab

bindClick(savePos1Btn, function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp then savedPos1 = hrp.CFrame savePos1Btn.Text = "ĐÃ LƯU 1!" task.wait(1) savePos1Btn.Text = "LƯU VỊ TRÍ 1" end end)
bindClick(savePos2Btn, function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp then savedPos2 = hrp.CFrame savePos2Btn.Text = "ĐÃ LƯU 2!" task.wait(1) savePos2Btn.Text = "LƯU VỊ TRÍ 2" end end)
bindClick(tpPos1Btn, function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp and savedPos1 then hrp.CFrame = savedPos1 end end)
bindClick(tpPos2Btn, function() local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp and savedPos2 then hrp.CFrame = savedPos2 end end)

bindClick(autoTp1Btn, function()
    if not savedPos1 then autoTp1Btn.Text = "CHƯA LƯU VỊ TRÍ 1!" task.wait(1) autoTp1Btn.Text = autoTp1Active and "AUTO TP 1: ON" or "AUTO TP 1: OFF" return end
    if autoTp2Active then autoTp2Active = false if autoTp2Thread then task.cancel(autoTp2Thread) end autoTp2Btn.Text = "AUTO TP 2: OFF" autoTp2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
    autoTp1Active = not autoTp1Active
    if autoTp1Active then
        autoTp1Btn.Text = "AUTO TP 1: ON" autoTp1Btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
        autoTp1Thread = task.spawn(function() while autoTp1Active do local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = savedPos1 end task.wait(0.1) end end)
    else autoTp1Btn.Text = "AUTO TP 1: OFF" autoTp1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) if autoTp1Thread then task.cancel(autoTp1Thread) end end
end)
bindClick(autoTp2Btn, function()
    if not savedPos2 then autoTp2Btn.Text = "CHƯA LƯU VỊ TRÍ 2!" task.wait(1) autoTp2Btn.Text = autoTp2Active and "AUTO TP 2: ON" or "AUTO TP 2: OFF" return end
    if autoTp1Active then autoTp1Active = false if autoTp1Thread then task.cancel(autoTp1Thread) end autoTp1Btn.Text = "AUTO TP 1: OFF" autoTp1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
    autoTp2Active = not autoTp2Active
    if autoTp2Active then
        autoTp2Btn.Text = "AUTO TP 2: ON" autoTp2Btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
        autoTp2Thread = task.spawn(function() while autoTp2Active do local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.CFrame = savedPos2 end task.wait(0.1) end end)
    else autoTp2Btn.Text = "AUTO TP 2: OFF" autoTp2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) if autoTp2Thread then task.cancel(autoTp2Thread) end end
end)

local plrScroll = Instance.new("ScrollingFrame") plrScroll.Size = UDim2.new(1, -10, 0, 150) plrScroll.BackgroundTransparency = 1 plrScroll.BorderSizePixel = 0 plrScroll.ScrollBarThickness = 4 plrScroll.ZIndex = 53 plrScroll.Parent = tpTab
local plrLayout = Instance.new("UIListLayout") plrLayout.Padding = UDim.new(0, 3) plrLayout.Parent = plrScroll
local function updatePlayerList()
    for _, child in pairs(plrScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, 0, 0, 25) btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35) btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.Font = Enum.Font.Gotham btn.TextSize = 11 btn.Text = "Tele đến: " .. plr.Name btn.BorderSizePixel = 0 btn.ZIndex = 54 btn.Parent = plrScroll
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
            bindClick(btn, function() local targetChar = plr.Character local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if targetHrp and myHrp then myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0) end end)
        end
    end
end
updatePlayerList()
table.insert(Connections, Players.PlayerAdded:Connect(updatePlayerList))
table.insert(Connections, Players.PlayerRemoving:Connect(function() task.wait(1) updatePlayerList() end))

-- ==========================================
-- VKЛАДКА 7: MISC
-- ==========================================
local miscTab = createTab("MISC")

createToggle(miscTab, "Anti-AFK (Chống treo)", false, function(s) States.AntiAFK = s end)
createToggle(miscTab, "Fullbright (Sáng bản đồ)", false, function(s) 
    States.Fullbright = s 
    if s then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 100000
    end
end)
createToggle(miscTab, "Chống Rơi Vực (Anti-Void)", false, function(s) States.AntiVoid = s end)
createToggle(miscTab, "Mở Khóa FPS (Unlock FPS)", false, function(s) 
    States.UnlockFPS = s
    if setfpscap then
        pcall(function()
            if s then setfpscap(240) else setfpscap(60) end
        end)
    end
end)
createToggle(miscTab, "Auto Clicker", false, function(s) 
    States.AutoClick = s 
    if s then
        if autoClickThread then task.cancel(autoClickThread) end
        autoClickThread = task.spawn(function()
            while States.AutoClick do
                task.wait(0.1)
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(500, 500))
            end
        end)
    else
        if autoClickThread then task.cancel(autoClickThread) autoClickThread = nil end
    end
end)
createToggle(miscTab, "Remove Particles", false, function(s) 
    States.RemoveParticles = s 
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = not s
        end
    end
end)

-- ==========================================
-- VKЛАДКА 8: SCAN ITEM
-- ==========================================
local scanItemTab = createTab("SCAN ITEM")

local itemInputBox = Instance.new("TextBox")
itemInputBox.Size = UDim2.new(1, -10, 0, 35)
itemInputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
itemInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
itemInputBox.PlaceholderText = "Nhập tên vật phẩm (VD: coin)..."
itemInputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
itemInputBox.Text = ""
itemInputBox.TextScaled = true
itemInputBox.Font = Enum.Font.Gotham
itemInputBox.BorderSizePixel = 0
itemInputBox.ClearTextOnFocus = false
itemInputBox.ZIndex = 53
itemInputBox.Parent = scanItemTab
local iic = Instance.new("UICorner") iic.CornerRadius = UDim.new(0, 6) iic.Parent = itemInputBox

local scanSpeedBtn = Instance.new("TextButton")
scanSpeedBtn.Size = UDim2.new(1, -10, 0, 35)
scanSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 50)
scanSpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanSpeedBtn.Font = Enum.Font.GothamBold
scanSpeedBtn.Text = "QUÉT VẬT PHẨM TỐC ĐỘ"
scanSpeedBtn.BorderSizePixel = 0
scanSpeedBtn.ZIndex = 53
scanSpeedBtn.Parent = scanItemTab
local ssb = Instance.new("UICorner") ssb.CornerRadius = UDim.new(0, 6) ssb.Parent = scanSpeedBtn

local scanItemBtn = Instance.new("TextButton")
scanItemBtn.Size = UDim2.new(1, -10, 0, 35)
scanItemBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 20)
scanItemBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
scanItemBtn.Font = Enum.Font.GothamBold
scanItemBtn.Text = "QUÉT VẬT PHẨM (THEO TÊN)"
scanItemBtn.BorderSizePixel = 0
scanItemBtn.ZIndex = 53
scanItemBtn.Parent = scanItemTab
local sib = Instance.new("UICorner") sib.CornerRadius = UDim.new(0, 6) sib.Parent = scanItemBtn

createSlider(scanItemTab, "Auto TP Delay", 0.1, 2.0, 0.5, function(v) States.ItemTpSpeed = v end)

local itemListFrame = Instance.new("ScrollingFrame")
itemListFrame.Size = UDim2.new(1, -10, 0, 150)
itemListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
itemListFrame.BorderSizePixel = 0
itemListFrame.ScrollBarThickness = 4
itemListFrame.ZIndex = 53
itemListFrame.Parent = scanItemTab
local ilf = Instance.new("UICorner") ilf.CornerRadius = UDim.new(0, 6) ilf.Parent = itemListFrame
local ilLayout = Instance.new("UIListLayout") ilLayout.Padding = UDim.new(0, 3) ilLayout.Parent = itemListFrame

local function addItemToUI(obj, nameOverride)
    table.insert(scannedItems, obj)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Text = "📦 " .. (nameOverride or obj.Name)
    btn.BorderSizePixel = 0
    btn.ZIndex = 54
    btn.Parent = itemListFrame
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = btn
    
    bindClick(btn, function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local targetPos = nil
        if obj:IsA("BasePart") then
            targetPos = obj.Position
        elseif obj:IsA("Model") then
            local success, pivot = pcall(function() return obj:GetPivot() end)
            if success then targetPos = pivot.Position elseif obj.PrimaryPart then targetPos = obj.PrimaryPart.Position end
        end
        if targetPos then
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
        end
    end)
end

local function performScan(isSpeedScan)
    local query = string.lower(itemInputBox.Text)
    if not isSpeedScan and query == "" then
        scanItemBtn.Text = "VUI LÒNG NHẬP TÊN!"
        task.wait(1.5)
        scanItemBtn.Text = "QUÉT VẬT PHẨM (THEO TÊN)"
        return
    end

    for _, child in pairs(itemListFrame:GetChildren()) do 
        if child:IsA("TextButton") then child:Destroy() end 
    end
    table.clear(scannedItems)
    
    local allDescendants = Workspace:GetDescendants()
    local totalObjects = #allDescendants
    local processed = 0
    local count = 0
    
    for _, obj in ipairs(allDescendants) do
        processed = processed + 1
        
        if processed % 100 == 0 then
            if isSpeedScan then
                scanSpeedBtn.Text = "ĐANG QUÉT: " .. processed .. " / " .. totalObjects
            else
                scanItemBtn.Text = "ĐANG QUÉT: " .. processed .. " / " .. totalObjects
            end
            task.wait()
        end

        if (obj:IsA("BasePart") or obj:IsA("Model")) and not obj:IsDescendantOf(LocalPlayer.Character) then
            local nameLower = string.lower(obj.Name)
            local isMatch = false
            
            if isSpeedScan then
                if string.find(nameLower, "speed") or string.find(nameLower, "toc do") or string.find(nameLower, "tốc độ") or string.find(nameLower, "boost") then
                    isMatch = true
                end
            else
                if string.find(nameLower, query) then
                    isMatch = true
                end
            end

            if isMatch then
                addItemToUI(obj)
                count = count + 1
            end
        elseif isSpeedScan and obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            if string.find(textLower, "tốc độ") or string.find(textLower, "toc do") or string.find(textLower, "speed") then
                local current = obj.Parent
                while current and not current:IsA("BasePart") and current ~= Workspace do
                    current = current.Parent
                end
                if current and current:IsA("BasePart") and not current:IsDescendantOf(LocalPlayer.Character) then
                    local isDup = false
                    for _, existing in ipairs(scannedItems) do
                        if existing == current then isDup = true break end
                    end
                    if not isDup then
                        addItemToUI(current, obj.Text)
                        count = count + 1
                    end
                end
            end
        end
    end
    
    if isSpeedScan then
        scanSpeedBtn.Text = "TÌM THẤY: " .. count .. " VẬT PHẨM TỐC ĐỘ"
    else
        scanItemBtn.Text = "TÌM THẤY: " .. count .. " VẬT PHẨM"
    end
end

bindClick(scanSpeedBtn, function() performScan(true) end)
bindClick(scanItemBtn, function() performScan(false) end)

createToggle(scanItemTab, "Auto Teleport Item", false, function(s) 
    States.AutoItemTp = s 
    if s then
        if #scannedItems == 0 then
            performScan(false)
            task.wait(0.5)
        end
        if autoItemTpThread then task.cancel(autoItemTpThread) end
        
        autoItemTpThread = task.spawn(function()
            while States.AutoItemTp do
                if #scannedItems == 0 then
                    performScan(false)
                    task.wait(1)
                else
                    for _, item in ipairs(scannedItems) do
                        if not States.AutoItemTp then break end
                        if item and item.Parent then
                            local char = LocalPlayer.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local targetPos = nil
                                if item:IsA("BasePart") then
                                    targetPos = item.Position
                                elseif item:IsA("Model") then
                                    local success, pivot = pcall(function() return item:GetPivot() end)
                                    if success then targetPos = pivot.Position elseif item.PrimaryPart then targetPos = item.PrimaryPart.Position end
                                end
                                if targetPos then
                                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
                                end
                            end
                            task.wait(States.ItemTpSpeed)
                        end
                    end
                    if States.AutoItemTp then
                        table.clear(scannedItems)
                        performScan(false)
                        task.wait(0.5)
                    end
                end
            end
        end)
    else
        if autoItemTpThread then task.cancel(autoItemTpThread) autoItemTpThread = nil end
    end
end)

-- ==========================================
-- KÉO THẢ & ĐIỀU KHIỂN CHÍNH
-- ==========================================
bindClick(openButton, function() menu.Visible = not menu.Visible end)
bindClick(closeButton, function() menu.Visible = false end)
makeDraggable(openButton, openButton)
makeDraggable(menu, title)

local firstTab = sidebar:GetChildren()[1]
if firstTab and firstTab:IsA("TextButton") then
    firstTab.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    firstTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    contentFrame:GetChildren()[2].Visible = true
end

-- ==========================================
-- VÒNG LẶP XỬ LÝ LOGIC CHÍNH
-- ==========================================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    if States.AntiFling then
        if hrp.Velocity.Magnitude > 50 then
            hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        end
    end

    if States.Glide then
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            if hrp.Velocity.Y < -15 then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, -15, hrp.Velocity.Z)
            end
        end
    end

    if States.AntiVoid then
        if hrp.Position.Y < -50 then
            hrp.CFrame = CFrame.new(0, 50, 0)
        end
    end

    if States.XRay then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(char) then
                obj.LocalTransparencyModifier = 0.5
            end
        end
    end

    if States.ItemESP then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and not obj:IsDescendantOf(char) then
                local n = string.lower(obj.Name)
                if string.find(n, "coin") or string.find(n, "cash") or string.find(n, "gem") or string.find(n, "xu") or string.find(n, "speed") or string.find(n, "boost") then
                    if not obj:FindFirstChild("LermItemESP") then
                        local h = Instance.new("Highlight")
                        h.Name = "LermItemESP"
                        h.FillColor = Color3.fromRGB(255, 215, 0)
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.Parent = obj
                        table.insert(ESPObjects, h)
                    end
                end
            end
        end
    end

    if States.Noclip then
        for _, p in pairs(char:GetDescendants()) do 
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end 
        end
    end

    if not States.FreeCam then
        if hum.WalkSpeed ~= States.Speed then hum.WalkSpeed = States.Speed end
        if hum.JumpPower ~= States.JumpPower then hum.JumpPower = States.JumpPower end
    end

    if States.Fly then
        local bv = hrp:FindFirstChild("LermMaxFlyVel")
        local bg = hrp:FindFirstChild("LermMaxFlyGyro")
        if not bv then
            hum.PlatformStand = true
            bv = Instance.new("BodyVelocity") bv.Name = "LermMaxFlyVel" bv.MaxForce = Vector3.new(1e9, 1e9, 1e9) bv.Velocity = Vector3.zero bv.Parent = hrp
            bg = Instance.new("BodyGyro") bg.Name = "LermMaxFlyGyro" bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9) bg.P = 10000 bg.D = 500 bg.CFrame = hrp.CFrame bg.Parent = hrp
        end
        if bv and bg then
            local dir = Vector3.zero
            if hum.MoveDirection.Magnitude > 0 then dir = hum.MoveDirection end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) or States.FlyUp then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or States.FlyDown then dir -= Vector3.new(0, 1, 0) end
            bv.Velocity = dir.Magnitude > 0 and dir.Unit * States.FlySpeed or Vector3.zero
            bg.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
        end
    else
        local bv = hrp:FindFirstChild("LermMaxFlyVel")
        if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("LermMaxFlyGyro")
        if bg then bg:Destroy() end
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    if States.ESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if not plr.Character.HumanoidRootPart:FindFirstChild("LermMaxESP") then
                    local h = Instance.new("Highlight") h.Name = "LermMaxESP" h.FillColor = Color3.fromRGB(255, 0, 0) h.OutlineColor = Color3.fromRGB(255, 255, 255) h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = plr.Character table.insert(ESPObjects, h)
                end
            end
        end
    end

    if States.Hitbox then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = Vector3.new(States.HitboxSize, States.HitboxSize, States.HitboxSize)
                plr.Character.HumanoidRootPart.Transparency = 0.7
                plr.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really red")
                plr.Character.HumanoidRootPart.Material = Enum.Material.Neon
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if plr.Character.HumanoidRootPart.Size ~= Vector3.new(2, 2, 1) then
                    plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1) plr.Character.HumanoidRootPart.Transparency = 1 plr.Character.HumanoidRootPart.Material = Enum.Material.Plastic
                end
            end
        end
    end

    if States.KillAura then
        local currentTime = tick()
        if currentTime - lastAuraAttack > 0.05 then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local closestTarget = nil
                local shortestDist = States.AuraRange
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local targetHum = plr.Character:FindFirstChildOfClass("Humanoid")
                        local targetHrp = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                        if targetHum and targetHrp and targetHum.Health > 0 then
                            local dist = (hrp.Position - targetHrp.Position).Magnitude
                            if dist < shortestDist then shortestDist = dist closestTarget = targetHrp end
                        end
                    end
                end
                if closestTarget then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestTarget.Position)
                    tool:Activate()
                    lastAuraAttack = currentTime
                end
            end
        end
    elseif States.Aimbot and not States.FreeCam then
        local closestPlr = nil local shortestDist = math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local dist = (plr.Character.Head.Position - Camera.CFrame.Position).Magnitude
                if dist < shortestDist then shortestDist = dist closestPlr = plr.Character.Head end
            end
        end
        if closestPlr then Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlr.Position) end
    end

    if States.AutoJump and not States.FreeCam then
        if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    if States.AutoRun and not States.Fly and not States.FreeCam then
        local flatLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        if flatLook.Magnitude > 0 then hum:Move(flatLook.Unit, true) hum:MoveTo(hrp.Position + flatLook.Unit * 10) end
    end
end))

-- Logic FreeCam
table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    if States.FreeCam then
        freeCamCFrame = CFrame.new(freeCamCFrame.Position) * CFrame.Angles(0, freeCamRotX, 0) * CFrame.Angles(freeCamRotY, 0, 0)
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or freeCamInput.F then moveDir += Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or freeCamInput.B then moveDir += Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or freeCamInput.L then moveDir += Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or freeCamInput.R then moveDir += Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or freeCamInput.U then moveDir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or freeCamInput.D then moveDir += Vector3.new(0, -1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            local camRight = freeCamCFrame.RightVector
            local camUp = Vector3.new(0,1,0)
            local camLook = freeCamCFrame.LookVector
            local finalMove = (camRight * moveDir.X) + (camUp * moveDir.Y) + (camLook * -moveDir.Z)
            freeCamCFrame = freeCamCFrame + (finalMove * States.FreeCamSpeed * dt)
        end
        Camera.CFrame = freeCamCFrame
    else
        freeCamCFrame = Camera.CFrame
    end
end))

-- Xoay Camera FreeCam (Touch)
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if not States.FreeCam then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Delta
        if delta.Magnitude > 0 then
            freeCamRotX = freeCamRotX - math.rad(delta.X * 0.5)
            freeCamRotY = math.clamp(freeCamRotY - math.rad(delta.Y * 0.5), math.rad(-89), math.rad(89))
        end
    end
end))

-- Xử lý nhảy
table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if States.InfJump and not States.FreeCam then
        local char = LocalPlayer.Character
        if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end
end))

-- Anti-AFK
table.insert(Connections, LocalPlayer.Idled:Connect(function()
    if States.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- Reset trạng thái khi chết
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if States.Fly then
        States.Fly = false States.FlyUp = false States.FlyDown = false flyOverlay.Visible = false
    end
    if States.FreeCam then
        States.FreeCam = false fcOverlay.Visible = false Camera.CameraType = Enum.CameraType.Custom
    end
    if States.UnlockFPS and setfpscap then
        pcall(function() setfpscap(60) end)
    end
end))

gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

getgenv().HTrungCleanup = function()
    if autoItemTpThread then task.cancel(autoItemTpThread) end
    if godModeThread then task.cancel(godModeThread) end
    if autoClickThread then task.cancel(autoClickThread) end
    if oldRaycast then hookfunction(workspace.Raycast, oldRaycast) end
    if setfpscap then pcall(function() setfpscap(60) end) end
    for _, conn in pairs(Connections) do if conn then conn:Disconnect() end end
    if gui then gui:Destroy() end
end
