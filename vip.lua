-- ================================================================
--   SAILOR PIECE HUB  v2.0
--   Auto Farm | Teleport | Auto Quest | Anti-Ban | Anti-Cheat
--   Executor: Synapse X / KRNL / Fluxus
--   Nhấn [P] để ẩn/hiện GUI
-- ================================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP             = Players.LocalPlayer
local Mouse          = LP:GetMouse()
local Workspace      = game:GetService("Workspace")

-- ================================================================
--  BIẾN TRẠNG THÁI TOÀN CỤC
-- ================================================================
local Settings = {
    AutoFarm        = false,
    AutoQuest       = false,
    AntiBan         = false,
    AntiCheat       = false,
    AntiFling       = false,
    SafeWalk        = false,
    FarmMobName     = "Sea King",
    FarmRadius      = 60,
    FlyEnabled      = false,
    FlySpeed        = 1,
    Noclip          = false,
    GodMode         = false,
    InfiniteJump    = false,
}

local maincolor = Color3.fromRGB(20, 20, 40)
local accentColor = Color3.fromRGB(255, 215, 0)
local loopkillT, bringT, blindT = {}, {}, {}
local loopn, jumping, sitting = {}, {}, {}
local FLYING = false

-- ================================================================
--  HÀM TIỆN ÍCH
-- ================================================================
local function Notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "⚓ Sailor Piece Hub",
        Text    = msg,
        Duration = 3,
    })
end

local function GetChar()
    return LP.Character
end

local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function FindTable(t, v)
    for _, val in pairs(t) do
        if val == v then return true end
    end
    return false
end

local function GetInTable(t, v)
    for i, val in pairs(t) do
        if val == v then return i end
    end
    return false
end

local function TeleportTo(pos)
    local hrp = GetHRP()
    if hrp then
        local goal = {CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))}
        local info = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
        TweenService:Create(hrp, info, goal):Play()
        task.wait(0.15)
    end
end

local function SafeTeleport(pos)
    -- Teleport an toàn (không bị flag anti-cheat)
    local hrp = GetHRP()
    if hrp then
        if Settings.SafeWalk then
            local steps = 10
            local startPos = hrp.Position
            for i = 1, steps do
                local lerpPos = startPos:Lerp(pos + Vector3.new(0,5,0), i/steps)
                hrp.CFrame = CFrame.new(lerpPos)
                task.wait(0.02)
            end
        else
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        end
    end
end

local function GetNearestMob(name, maxDist)
    local nearest, dist = nil, maxDist or math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(name:lower()) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            local hp   = obj:FindFirstChildOfClass("Humanoid")
            if root and hp and hp.Health > 0 then
                local hrp = GetHRP()
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < dist then nearest, dist = obj, d end
                end
            end
        end
    end
    return nearest
end

-- ================================================================
--  ANTI-BAN SYSTEM
-- ================================================================
local antiBanConn
local originalCFrame = nil
local function StartAntiBan()
    -- Anti-ban: bảo vệ character khỏi bị kick bởi anti-cheat của game
    antiBanConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiBan then return end
        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum then return end
        -- Giữ velocity ổn định, tránh spike đột ngột
        if hrp.Velocity.Magnitude > 500 then
            hrp.Velocity = hrp.Velocity.Unit * 100
        end
    end)
end

local function StopAntiBan()
    if antiBanConn then antiBanConn:Disconnect() antiBanConn = nil end
end

-- ================================================================
--  ANTI-CHEAT / ANTI-FLING / ANTI-EXPLOIT-DETECT
-- ================================================================
local antiCheatConn
local function StartAntiCheat()
    antiCheatConn = RunService.Heartbeat:Connect(function()
        if not Settings.AntiCheat then return end
        local char = GetChar()
        local hrp = GetHRP()
        local hum = GetHum()
        if not char or not hrp or not hum then return end

        -- Anti-Fling: ngăn bị fling ra ngoài map
        if Settings.AntiFling then
            if hrp.RotVelocity.Magnitude > 20 then
                hrp.RotVelocity = Vector3.zero
            end
            if hrp.Velocity.Magnitude > 300 and not FLYING then
                hrp.Velocity = Vector3.zero
            end
        end

        -- Nếu bị đẩy ra khỏi map (Y quá thấp hoặc quá xa), tự respawn về vị trí an toàn
        if hrp.Position.Y < -200 then
            hrp.CFrame = CFrame.new(0, 10, 0)
            Notify("Anti-Cheat: Đã khôi phục vị trí!")
        end

        -- Giữ walkspeed & jumppower không bị reset bởi game
        if hum.WalkSpeed < 2 and not Settings.AntiBan then
            hum.WalkSpeed = 16
        end
    end)
    Notify("Anti-Cheat BẬT")
end

local function StopAntiCheat()
    if antiCheatConn then antiCheatConn:Disconnect() antiCheatConn = nil end
    Notify("Anti-Cheat TẮT")
end

-- ================================================================
--  GOD MODE (FE-safe)
-- ================================================================
local function ToggleGodMode(on)
    local hum = GetHum()
    if not hum then return end
    if on then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        Notify("God Mode BẬT")
    else
        hum.MaxHealth = 100
        hum.Health    = 100
        Notify("God Mode TẮT")
    end
end

-- ================================================================
--  NOCLIP
-- ================================================================
local noclipRunning = false
local function StartNoclip()
    Settings.Noclip = true
    if noclipRunning then return end
    noclipRunning = true
    RunService.Stepped:Connect(function()
        if Settings.Noclip then
            local char = GetChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    Notify("Noclip BẬT")
end

local function StopNoclip()
    Settings.Noclip = false
    local char = GetChar()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    Notify("Noclip TẮT")
end

-- ================================================================
--  BAY (FLY) - từ IY
-- ================================================================
local flySpeed = 1
local flyControl = {F=0, B=0, L=0, R=0}
local flyLast    = {F=0, B=0, L=0, R=0}
local flyFlyConn

local function StartFly()
    local char = GetChar()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FLYING = true

    local BG = Instance.new("BodyGyro", hrp)
    BG.P = 9e4; BG.maxTorque = Vector3.new(9e9,9e9,9e9); BG.CFrame = hrp.CFrame

    local BV = Instance.new("BodyVelocity", hrp)
    BV.velocity = Vector3.new(0,0.1,0); BV.maxForce = Vector3.new(9e9,9e9,9e9)

    local SPEED = 0
    flyFlyConn = RunService.Heartbeat:Connect(function()
        if not FLYING then
            SPEED = 0; BG:Destroy(); BV:Destroy()
            if char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").PlatformStand = false
            end
            flyFlyConn:Disconnect()
            return
        end
        if char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").PlatformStand = true
        end
        local c = flyControl
        if c.L+c.R ~= 0 or c.F+c.B ~= 0 then SPEED = 50 * Settings.FlySpeed
        else SPEED = 0 end
        if (c.L+c.R) ~= 0 or (c.F+c.B) ~= 0 then
            BV.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector*(c.F+c.B)) +
                ((Workspace.CurrentCamera.CoordinateFrame*CFrame.new(c.L+c.R,(c.F+c.B)*0.2,0).p) -
                Workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
            flyLast = {F=c.F,B=c.B,L=c.L,R=c.R}
        else
            BV.velocity = Vector3.new(0,0.1,0)
        end
        BG.CFrame = Workspace.CurrentCamera.CoordinateFrame
    end)

    Mouse.KeyDown:Connect(function(k)
        k = k:lower()
        if k=='w' then flyControl.F= flySpeed elseif k=='s' then flyControl.B=-flySpeed
        elseif k=='a' then flyControl.L=-flySpeed elseif k=='d' then flyControl.R= flySpeed end
    end)
    Mouse.KeyUp:Connect(function(k)
        k = k:lower()
        if k=='w' then flyControl.F=0 elseif k=='s' then flyControl.B=0
        elseif k=='a' then flyControl.L=0 elseif k=='d' then flyControl.R=0 end
    end)
    Notify("Bay BẬT | WASD để điều khiển")
end

local function StopFly()
    FLYING = false
    local char = GetChar()
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    Notify("Bay TẮT")
end

-- ================================================================
--  INFINITE JUMP
-- ================================================================
local infJumpConn
local function StartInfJump()
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if Settings.InfiniteJump then
            local hum = GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    Notify("Infinite Jump BẬT")
end
local function StopInfJump()
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    Notify("Infinite Jump TẮT")
end

-- ================================================================
--  SPEED & JUMP
-- ================================================================
local function SetSpeed(val)
    local hum = GetHum()
    if hum then hum.WalkSpeed = tonumber(val) or 16 end
    Notify("Tốc độ: " .. (val or 16))
end

local function SetJump(val)
    local hum = GetHum()
    if hum then hum.JumpPower = tonumber(val) or 50 end
    Notify("Jump: " .. (val or 50))
end

-- ================================================================
--  AUTO FARM
-- ================================================================
local autoFarmConn
local function StartAutoFarm()
    if autoFarmConn then autoFarmConn:Disconnect() end
    autoFarmConn = RunService.Heartbeat:Connect(function()
        if not Settings.AutoFarm then return end
        local char = GetChar()
        if not char then return end
        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum or hum.Health <= 0 then return end
        local mob = GetNearestMob(Settings.FarmMobName, Settings.FarmRadius)
        if mob then
            local root = mob:FindFirstChild("HumanoidRootPart")
            local hp   = mob:FindFirstChildOfClass("Humanoid")
            if root and hp and hp.Health > 0 then
                SafeTeleport(root.Position)
                local activeTool = char:FindFirstChildOfClass("Tool")
                if activeTool then
                    pcall(function() activeTool.Activated:Fire() end)
                end
            end
        end
        task.wait(0.3)
    end)
    Notify("Auto Farm BẬT: " .. Settings.FarmMobName)
end

local function StopAutoFarm()
    if autoFarmConn then autoFarmConn:Disconnect(); autoFarmConn = nil end
    Notify("Auto Farm TẮT")
end

-- ================================================================
--  AUTO QUEST
-- ================================================================
local autoQuestTask
local function StartAutoQuest()
    Settings.AutoQuest = true
    autoQuestTask = task.spawn(function()
        while Settings.AutoQuest do
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local n = obj.Name:lower()
                    if n:find("quest") or n:find("navy") or n:find("pirate") or n:find("npc") then
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if root then
                            SafeTeleport(root.Position)
                            task.wait(0.5)
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                            if prompt then pcall(function() fireproximityprompt(prompt) end); task.wait(0.3) end
                            local click = obj:FindFirstChildOfClass("ClickDetector", true)
                            if click then pcall(function() fireclickdetector(click) end); task.wait(0.3) end
                        end
                    end
                end
            end
            -- Nhận reward
            local qGui = LP.PlayerGui:FindFirstChild("QuestGui") or LP.PlayerGui:FindFirstChild("Quest")
            if qGui then
                for _, btn in ipairs(qGui:GetDescendants()) do
                    if btn:IsA("TextButton") then
                        local t = btn.Text:lower()
                        if t:find("complete") or t:find("claim") or t:find("nhận") or t:find("hoàn") then
                            pcall(function() btn.MouseButton1Click:Fire() end)
                            task.wait(0.2)
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
    Notify("Auto Quest BẬT")
end

local function StopAutoQuest()
    Settings.AutoQuest = false
    if autoQuestTask then task.cancel(autoQuestTask); autoQuestTask = nil end
    Notify("Auto Quest TẮT")
end

-- ================================================================
--  LOOP KILL / LOOP BRING
-- ================================================================
local loopConn
local function UpdateLoops()
    if loopConn then loopConn:Disconnect() end
    loopConn = RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            -- Loop Kill
            if FindTable(loopkillT, plr.Name) and plr.Character then
                pcall(function() plr.Character:BreakJoints() end)
            end
            -- Loop Bring
            if FindTable(bringT, plr.Name) and plr.Character then
                local myHRP = GetHRP()
                local plrHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                if myHRP and plrHRP then
                    plrHRP.CFrame = myHRP.CFrame + Vector3.new(4, 1, 0)
                end
            end
        end
    end)
end
UpdateLoops()

-- ================================================================
--  REJOIN / AUTO RECONNECT
-- ================================================================
local function Rejoin()
    Notify("Đang rejoin...")
    task.wait(1)
    TeleportService:Teleport(game.PlaceId)
end

-- ================================================================
--  TELEPORT LOCATIONS
-- ================================================================
local Locations = {
    ["🏝 Hải Đảo Bắt Đầu"]   = Vector3.new(0, 0, 0),
    ["⚓ Marine Base"]         = Vector3.new(500, 0, -200),
    ["☠ Đảo Cướp Biển"]      = Vector3.new(-400, 0, 300),
    ["🌊 Biển Sâu"]            = Vector3.new(1000, 0, 1000),
    ["💀 Boss Island"]         = Vector3.new(2000, 0, -500),
    ["🗺 Tọa độ tùy chỉnh"]   = nil,
}

-- ================================================================
--  TẠO GUI CHÍNH
-- ================================================================
-- Xóa GUI cũ nếu có
if LP.PlayerGui:FindFirstChild("SailorPieceHub") then
    LP.PlayerGui.SailorPieceHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SailorPieceHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = LP.PlayerGui

-- Frame chính
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 360, 0, 540)
MainFrame.Position          = UDim2.new(0.5, -180, 0.5, -270)
MainFrame.BackgroundColor3  = Color3.fromRGB(12, 12, 22)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Viền neon
local Border = Instance.new("UIStroke", MainFrame)
Border.Color = Color3.fromRGB(60, 60, 120)
Border.Thickness = 1

-- Thanh tiêu đề
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 44)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text              = "⚓  SAILOR PIECE HUB  v2.0"
TitleLabel.Size              = UDim2.new(1, -50, 1, 0)
TitleLabel.Position          = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextColor3        = accentColor
TitleLabel.TextSize          = 13
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Parent            = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "✕"
CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
CloseBtn.Position          = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3  = Color3.fromRGB(180, 40, 40)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextColor3        = Color3.white
CloseBtn.TextSize          = 13
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Kéo GUI
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ScrollingFrame nội dung
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size              = UDim2.new(1, -10, 1, -50)
Scroll.Position          = UDim2.new(0, 5, 0, 46)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel   = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 160)
Scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent            = MainFrame

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding       = UDim.new(0, 6)
ListLayout.SortOrder     = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", Scroll).PaddingTop = UDim.new(0, 6)

-- ================================================================
--  HÀM TẠO UI
-- ================================================================
local function CreateSection(title, order)
    local lbl = Instance.new("TextLabel")
    lbl.Text              = "── " .. title .. " ──"
    lbl.Size              = UDim2.new(1, -16, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextColor3        = accentColor
    lbl.TextSize          = 11
    lbl.LayoutOrder       = order
    lbl.Parent            = Scroll
    return lbl
end

local function CreateToggle(labelText, order, callback)
    local state = false
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -16, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 36)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Text             = labelText
    lbl.Size             = UDim2.new(1, -80, 1, 0)
    lbl.Position         = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextColor3       = Color3.fromRGB(210, 210, 230)
    lbl.TextSize         = 13
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local btn = Instance.new("TextButton")
    btn.Text             = "TẮT"
    btn.Size             = UDim2.new(0, 62, 0, 28)
    btn.Position         = UDim2.new(1, -70, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.white
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text             = state and "BẬT" or "TẮT"
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 70) or Color3.fromRGB(160, 40, 40)
        callback(state)
    end)
    return btn
end

local function CreateButton(labelText, order, callback)
    local btn = Instance.new("TextButton")
    btn.Text             = labelText
    btn.Size             = UDim2.new(1, -16, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(30, 60, 140)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.white
    btn.TextSize         = 13
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = order
    btn.Parent           = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 90, 200)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 60, 140)}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateInputRow(labelText, order, placeholder, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -16, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 36)
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = Scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Text             = labelText
    lbl.Size             = UDim2.new(0, 80, 1, 0)
    lbl.Position         = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextColor3       = Color3.fromRGB(180, 180, 200)
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local input = Instance.new("TextBox")
    input.Text             = placeholder or ""
    input.Size             = UDim2.new(1, -130, 0, 28)
    input.Position         = UDim2.new(0, 88, 0.5, -14)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    input.Font             = Enum.Font.Gotham
    input.TextColor3       = Color3.white
    input.TextSize         = 12
    input.BorderSizePixel  = 0
    input.ClearTextOnFocus = false
    input.Parent           = row
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local setBtn = Instance.new("TextButton")
    setBtn.Text             = "Set"
    setBtn.Size             = UDim2.new(0, 36, 0, 28)
    setBtn.Position         = UDim2.new(1, -42, 0.5, -14)
    setBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    setBtn.Font             = Enum.Font.GothamBold
    setBtn.TextColor3       = Color3.white
    setBtn.TextSize         = 11
    setBtn.BorderSizePixel  = 0
    setBtn.Parent           = row
    Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 6)
    setBtn.MouseButton1Click:Connect(function() callback(input.Text) end)
    input.FocusLost:Connect(function(enter) if enter then callback(input.Text) end end)
    return input
end

-- ================================================================
--  BUILD GUI SECTIONS
-- ================================================================
local order = 0

-- SECTION: COMBAT / FARM
order=order+1; CreateSection("⚔  AUTO FARM", order)
order=order+1; CreateToggle("Auto Farm Mob", order, function(on)
    Settings.AutoFarm = on
    if on then StartAutoFarm() else StopAutoFarm() end
end)
order=order+1; CreateInputRow("Tên Mob:", order, Settings.FarmMobName, function(v)
    Settings.FarmMobName = v; Notify("Mob: "..v)
end)
order=order+1; CreateInputRow("Bán kính:", order, tostring(Settings.FarmRadius), function(v)
    Settings.FarmRadius = tonumber(v) or 60
end)

-- SECTION: QUEST
order=order+1; CreateSection("📋  AUTO QUEST", order)
order=order+1; CreateToggle("Auto Quest", order, function(on)
    if on then StartAutoQuest() else StopAutoQuest() end
end)

-- SECTION: ANTI CHEAT
order=order+1; CreateSection("🛡  ANTI-CHEAT & PROTECTION", order)
order=order+1; CreateToggle("Anti-Ban (Velocity Guard)", order, function(on)
    Settings.AntiBan = on
    if on then StartAntiBan() else StopAntiBan()
        Notify("Anti-Ban "..(on and "BẬT" or "TẮT"))
    end
end)
order=order+1; CreateToggle("Anti-Cheat (Position Guard)", order, function(on)
    Settings.AntiCheat = on
    if on then StartAntiCheat() else StopAntiCheat() end
end)
order=order+1; CreateToggle("Anti-Fling (Velocity Reset)", order, function(on)
    Settings.AntiFling = on
    Notify("Anti-Fling "..(on and "BẬT" or "TẮT"))
end)
order=order+1; CreateToggle("Safe Teleport (Lerp)", order, function(on)
    Settings.SafeWalk = on
    Notify("Safe Teleport "..(on and "BẬT" or "TẮT"))
end)

-- SECTION: MOVEMENT
order=order+1; CreateSection("🏃  MOVEMENT", order)
order=order+1; CreateToggle("Bay (Fly)", order, function(on)
    Settings.FlyEnabled = on
    if on then FLYING = false; StartFly() else StopFly() end
end)
order=order+1; CreateInputRow("Fly Speed:", order, "1", function(v)
    Settings.FlySpeed = tonumber(v) or 1
    Notify("Fly Speed: "..v)
end)
order=order+1; CreateToggle("Noclip", order, function(on)
    if on then StartNoclip() else StopNoclip() end
end)
order=order+1; CreateToggle("Infinite Jump", order, function(on)
    Settings.InfiniteJump = on
    if on then StartInfJump() else StopInfJump() end
end)
order=order+1; CreateInputRow("WalkSpeed:", order, "16", function(v) SetSpeed(v) end)
order=order+1; CreateInputRow("JumpPower:", order, "50", function(v) SetJump(v) end)

-- SECTION: COMBAT TOOLS (IY-inspired)
order=order+1; CreateSection("⚡  COMBAT TOOLS", order)
order=order+1; CreateToggle("God Mode", order, function(on)
    Settings.GodMode = on
    ToggleGodMode(on)
end)
order=order+1; CreateButton("💥 Heal (Full HP)", order, function()
    local hum = GetHum()
    if hum then hum.Health = hum.MaxHealth; Notify("Đã hồi máu!") end
end)
order=order+1; CreateButton("☠ Kill Players (FE Kill)", order, function()
    local char = GetChar()
    if not char then return end
    char:FindFirstChildOfClass("Humanoid").Name = "1"
    local l = char["1"]:Clone()
    l.Parent = char; l.Name = "Humanoid"
    task.wait(0.1)
    char["1"]:Destroy()
    Workspace.CurrentCamera.CameraSubject = char
    char.Animate.Disabled = true
    task.wait(0.1)
    char.Animate.Disabled = false
    char.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    Notify("FE Kill ready - đứng gần target!")
end)
order=order+1; CreateButton("👁 ESP (tất cả player)", order, function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            for _, part in ipairs(plr.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    local box = Instance.new("BoxHandleAdornment", game.CoreGui)
                    box.Name = "ESP_"..plr.Name
                    box.Adornee = part
                    box.AlwaysOnTop = true
                    box.ZIndex = 0
                    box.Size = part.Size
                    box.Transparency = 0.6
                    box.Color = BrickColor.new("Lime green")
                end
            end
        end
    end
    Notify("ESP BẬT - dùng nút bên dưới để tắt")
end)
order=order+1; CreateButton("❌ Tắt ESP", order, function()
    for _, obj in ipairs(game.CoreGui:GetDescendants()) do
        if obj.Name:sub(1,4) == "ESP_" then obj:Destroy() end
    end
    Notify("ESP TẮT")
end)

-- SECTION: TELEPORT
order=order+1; CreateSection("🌊  TELEPORT", order)
for name, pos in pairs(Locations) do
    if pos then
        local n, p = name, pos
        order=order+1
        CreateButton(n, order, function()
            SafeTeleport(p)
            Notify("Đã teleport → " .. n)
        end)
    end
end

order=order+1; CreateInputRow("X:", order, "0", function(v) _G.tpX = tonumber(v) or 0 end)
order=order+1; CreateInputRow("Y:", order, "0", function(v) _G.tpY = tonumber(v) or 0 end)
order=order+1; CreateInputRow("Z:", order, "0", function(v) _G.tpZ = tonumber(v) or 0 end)
order=order+1; CreateButton("📍 Teleport Tới Tọa Độ", order, function()
    local x = _G.tpX or 0; local y = _G.tpY or 0; local z = _G.tpZ or 0
    SafeTeleport(Vector3.new(x,y,z))
    Notify(string.format("Teleport → (%.0f, %.0f, %.0f)", x, y, z))
end)

-- SECTION: UTILITIES
order=order+1; CreateSection("⚙  TIỆN ÍCH", order)
order=order+1; CreateButton("🔄 Rejoin Game", order, Rejoin)
order=order+1; CreateButton("🧹 Xóa Workspace Models", order, function()
    for _, v in ipairs(Workspace:GetChildren()) do
        if not v:IsA("Terrain") and not v:IsA("Camera") and not Players:GetPlayerFromCharacter(v) then
            pcall(function() v:Destroy() end)
        end
    end
    Notify("Đã xóa workspace!")
end)
order=order+1; CreateButton("👻 FE Invisible", order, function()
    local char = GetChar()
    if char then
        local part = Instance.new("Part", Workspace)
        part.Size = Vector3.new(5,0,5)
        part.Anchored = true
        part.CFrame = CFrame.new(Vector3.new(9999,9999,9999))
        char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0,3,0)
        task.spawn(function() task.wait(3); part:Destroy() end)
        if char:FindFirstChild("HumanoidRootPart") then
            if char:FindFirstChild("LowerTorso") then
                local cl = char.LowerTorso.Root:Clone()
                char.LowerTorso.Root:Destroy()
                cl.Parent = char.LowerTorso
            else
                local cl = char.HumanoidRootPart:Clone()
                char.HumanoidRootPart:Destroy()
                cl.Parent = char
            end
        end
        Notify("FE Invisible!")
    end
end)
order=order+1; CreateButton("🔧 Fix Character", order, function()
    local char = GetChar()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.Anchored = false
            end
        end
        local hum = GetHum()
        if hum then
            hum.PlatformStand = false
            hum.WalkSpeed = 16
        end
        Notify("Đã fix character!")
    end
end)

-- ================================================================
--  PHÍM TẮT
-- ================================================================
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.P then
        MainFrame.Visible = not MainFrame.Visible
    end
    if inp.KeyCode == Enum.KeyCode.F4 then
        if not FLYING then FLYING = false; StartFly() else StopFly() end
    end
    if inp.KeyCode == Enum.KeyCode.F5 then
        if Settings.Noclip then StopNoclip() else StartNoclip() end
    end
end)

-- ================================================================
--  AUTO RESPAWN
-- ================================================================
LP.CharacterAdded:Connect(function(char)
    task.wait(2)
    Notify("Đã hồi sinh | Script đang chạy")
    if Settings.AntiBan then StartAntiBan() end
    if Settings.AntiCheat then StartAntiCheat() end
end)

-- ================================================================
-- KHỞI ĐỘNG
-- ================================================================
Notify("✅ Sailor Piece Hub v2.0 đã tải! | [P] ẩn/hiện | F4 bay | F5 noclip")
print("[Sailor Piece Hub v2.0] Loaded!")
print("Các tính năng: Auto Farm, Auto Quest, Anti-Ban, Anti-Cheat, Anti-Fling, Fly, Noclip, Inf Jump, ESP, FE Kill, FE Invis")
