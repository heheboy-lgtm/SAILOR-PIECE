-- ============================================
--       SAILOR PIECE SCRIPT - FULL V2
--       Auto Farm | Hover | Range Attack
--       Auto Quest (Level-Based) | Teleport
-- ============================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer      = Players.LocalPlayer
local Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid         = Character:WaitForChild("Humanoid")

-- ============================================
--  CÀI ĐẶT
-- ============================================
local Settings = {
    AutoFarm      = false,
    AutoQuest     = false,
    AutoHover     = true,
    RangeAttack   = true,
    AutoRespawn   = true,
    FarmMobName   = "Sea King",
    FarmRadius    = 150,
    AttackRange   = 35,
    HoverHeight   = 8,
    TeleportSpeed = 0.08,
}

-- ============================================
--  VỊ TRÍ TELEPORT
-- ============================================
local Locations = {
    ["Hải Đảo Bắt Đầu"]   = Vector3.new(0,    0,    0),
    ["Biển Đông (Marine)"] = Vector3.new(500,  0,  -200),
    ["Đảo Cướp Biển"]      = Vector3.new(-400, 0,   300),
    ["Vùng Biển Sâu"]      = Vector3.new(1000, 0,  1000),
    ["Boss Island"]        = Vector3.new(2000, 0,  -500),
}

-- ============================================
--  BIẾN NỘI BỘ
-- ============================================
local hoverBV       = nil
local hoverBG       = nil
local autoFarmConn  = nil
local autoQuestThread = nil
local QuestActive   = false

-- ============================================
--  HÀM TIỆN ÍCH
-- ============================================
local function Notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "⚓ Sailor Piece",
            Text     = msg,
            Duration = 3,
        })
    end)
end

local function TeleportTo(position)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local goal = {CFrame = CFrame.new(position + Vector3.new(0, 5, 0))}
    local info  = TweenInfo.new(Settings.TeleportSpeed, Enum.EasingStyle.Linear)
    TweenService:Create(hrp, info, goal):Play()
    task.wait(Settings.TeleportSpeed + 0.05)
end

local function GetPlayerLevel()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        for _, v in ipairs(stats:GetChildren()) do
            local n = v.Name:lower()
            if n:find("level") or n:find("lv") or n:find("rank") then
                return tonumber(v.Value) or 1
            end
        end
    end
    return 1
end

local function GetNearestMob(name, maxDist)
    local nearest, dist = nil, maxDist or math.huge
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(name:lower()) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            local hp   = obj:FindFirstChildOfClass("Humanoid")
            if root and hp and hp.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    nearest = obj
                    dist    = d
                end
            end
        end
    end
    return nearest
end

-- ============================================
--  HỆ THỐNG BAY (HOVER)
-- ============================================
local function EnableHover()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if hrp:FindFirstChild("SPFarmBG") then hrp.SPFarmBG:Destroy() end
    if hrp:FindFirstChild("SPFarmBV") then hrp.SPFarmBV:Destroy() end

    hoverBG = Instance.new("BodyGyro", hrp)
    hoverBG.Name       = "SPFarmBG"
    hoverBG.MaxTorque  = Vector3.new(9e9, 9e9, 9e9)
    hoverBG.P          = 9e4
    hoverBG.CFrame     = hrp.CFrame

    hoverBV = Instance.new("BodyVelocity", hrp)
    hoverBV.Name      = "SPFarmBV"
    hoverBV.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
    hoverBV.Velocity  = Vector3.new(0, 0.1, 0)
end

local function DisableHover()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hrp:FindFirstChild("SPFarmBG") then hrp.SPFarmBG:Destroy() end
        if hrp:FindFirstChild("SPFarmBV") then hrp.SPFarmBV:Destroy() end
    end
    hoverBG = nil
    hoverBV = nil
end

local function HoverAboveMob(mob)
    if not mob or not hoverBV or not hoverBG then return end
    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos = mobRoot.Position + Vector3.new(0, Settings.HoverHeight, 0)
    local diff      = targetPos - hrp.Position
    local dist      = diff.Magnitude

    -- Bay mượt mà tới vị trí trên đầu mob
    if dist > 2 then
        hoverBV.Velocity = diff.Unit * math.min(dist * 4, 80)
    else
        hoverBV.Velocity = Vector3.new(0, 0.1, 0)
    end
    -- Quay mặt về phía mob
    hoverBG.CFrame = CFrame.new(hrp.Position, Vector3.new(mobRoot.Position.X, hrp.Position.Y, mobRoot.Position.Z))
end

-- ============================================
--  ĐÁNH TỪ XA
-- ============================================
local function ActivateTool(targetPos)
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
              or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Trang bị tool nếu cần
    if not char:FindFirstChild(tool.Name) then
        tool.Parent = char
        task.wait(0.1)
    end

    -- Kích hoạt RemoteEvent nếu có
    local fired = false
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            pcall(function()
                obj:FireServer(CFrame.new(targetPos), targetPos)
            end)
            fired = true
            break
        end
    end

    -- Backup Activated
    if not fired then
        pcall(function() tool.Activated:Fire() end)
    end
end

local function RangeAttack(mob)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot then return end

    local dist = (hrp.Position - mobRoot.Position).Magnitude

    -- Nếu vượt tầm đánh xa thì bay lại gần hơn
    if dist > Settings.AttackRange then
        if Settings.AutoHover and hoverBV then
            -- Tự động điều chỉnh trong HoverAboveMob
        else
            TeleportTo(mobRoot.Position + Vector3.new(0, Settings.HoverHeight, 0))
        end
        return
    end

    ActivateTool(mobRoot.Position)
end

-- ============================================
--  AUTO FARM LOOP
-- ============================================
local function StopAutoFarm()
    if autoFarmConn then
        autoFarmConn:Disconnect()
        autoFarmConn = nil
    end
    DisableHover()
    Notify("⚔ Auto Farm TẮT")
end

local function StartAutoFarm()
    StopAutoFarm()

    if Settings.AutoHover then
        EnableHover()
    end

    local attackTimer = 0
    autoFarmConn = RunService.Heartbeat:Connect(function(dt)
        if not Settings.AutoFarm then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        HumanoidRootPart = hrp
        Humanoid         = hum

        local mob = GetNearestMob(Settings.FarmMobName, Settings.FarmRadius)

        if mob then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            local mobHp   = mob:FindFirstChildOfClass("Humanoid")
            if not mobRoot or not mobHp or mobHp.Health <= 0 then return end

            -- Bay / Di chuyển lên trên đầu mob
            if Settings.AutoHover and hoverBV then
                HoverAboveMob(mob)
            end

            -- Đánh (timer để không spam quá nhanh)
            attackTimer = attackTimer + dt
            if attackTimer >= 0.25 then
                attackTimer = 0
                if Settings.RangeAttack then
                    RangeAttack(mob)
                else
                    -- Đánh gần cổ điển
                    TeleportTo(mobRoot.Position)
                    local activeTool = char:FindFirstChildOfClass("Tool")
                    if activeTool then
                        pcall(function() activeTool.Activated:Fire() end)
                    end
                end
            end
        else
            -- Không có mob, đứng yên
            if hoverBV then
                hoverBV.Velocity = Vector3.new(0, 0.1, 0)
            end
        end
    end)

    Notify("⚔ Auto Farm BẬT: " .. Settings.FarmMobName)
end

-- ============================================
--  AUTO QUEST THÔNG MINH
-- ============================================
local function ClaimQuestReward()
    local playerGui = LocalPlayer.PlayerGui
    for _, btn in ipairs(playerGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local t = btn.Text:lower()
            if t:find("claim") or t:find("complete") or t:find("nhận") or t:find("hoàn") then
                pcall(function() btn.MouseButton1Click:Fire() end)
                task.wait(0.4)
                Notify("✅ Đã nhận thưởng quest!")
                QuestActive = false
            end
        end
    end
end

local function IsQuestActive()
    local playerGui = LocalPlayer.PlayerGui
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t = obj.Text:lower()
            if t:find("in progress") or t:find("đang làm") or t:find("ongoing") then
                return true
            end
        end
    end
    return QuestActive
end

local function TryAcceptQuest(npc)
    -- Nếu đang có quest => bỏ qua
    if IsQuestActive() then return false end

    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return false end

    local playerLv = GetPlayerLevel()

    TeleportTo(npcRoot.Position)
    task.wait(0.5)

    -- Kích hoạt ProximityPrompt
    local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.4)
    end

    -- Kích hoạt ClickDetector
    local click = npc:FindFirstChildOfClass("ClickDetector", true)
    if click then
        pcall(function() fireclickdetector(click) end)
        task.wait(0.4)
    end

    -- Quét GUI chọn quest phù hợp level
    local playerGui = LocalPlayer.PlayerGui
    for _, btn in ipairs(playerGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local t = btn.Text:lower()
            if t:find("accept") or t:find("nhận") or t:find("take") or t:find("start") then
                -- Tìm level yêu cầu trong parent frame
                local reqLv  = 0
                local parent = btn.Parent
                if parent then
                    for _, sib in ipairs(parent:GetDescendants()) do
                        if sib:IsA("TextLabel") then
                            local num = sib.Text:match("[Ll]v%.?%s*(%d+)")
                                     or sib.Text:match("[Ll]evel%s*(%d+)")
                                     or sib.Text:match("(%d+)")
                            if num then
                                reqLv = math.max(reqLv, tonumber(num) or 0)
                            end
                        end
                    end
                end

                if playerLv >= reqLv then
                    pcall(function() btn.MouseButton1Click:Fire() end)
                    QuestActive = true
                    Notify("📋 Nhận quest! (Lv yêu cầu: " .. reqLv .. " | Lv bạn: " .. playerLv .. ")")
                    task.wait(0.3)
                    return true
                end
            end
        end
    end
    return false
end

local function StopAutoQuest()
    Settings.AutoQuest = false
    if autoQuestThread then
        pcall(function() task.cancel(autoQuestThread) end)
        autoQuestThread = nil
    end
    Notify("📋 Auto Quest TẮT")
end

local function StartAutoQuest()
    StopAutoQuest()
    Settings.AutoQuest = true

    autoQuestThread = task.spawn(function()
        while Settings.AutoQuest do
            -- Bước 1: Nhận thưởng nếu xong quest
            ClaimQuestReward()
            task.wait(0.5)

            -- Bước 2: Tìm NPC quest
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not Settings.AutoQuest then break end
                if obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("quest") or name:find("navy")
                    or name:find("pirate") or name:find("marine")
                    or name:find("giver") or name:find("npc") then
                        TryAcceptQuest(obj)
                        task.wait(0.5)
                    end
                end
            end

            task.wait(3)
        end
    end)

    Notify("📋 Auto Quest BẬT (Theo Level)")
end

-- ============================================
--  TẠO GUI
-- ============================================
-- Xóa GUI cũ nếu có
if LocalPlayer.PlayerGui:FindFirstChild("SailorPieceHub") then
    LocalPlayer.PlayerGui.SailorPieceHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SailorPieceHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = LocalPlayer.PlayerGui

-- ============================================
--  FRAME CHÍNH
-- ============================================
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 360, 0, 600)
MainFrame.Position          = UDim2.new(0.5, -180, 0.5, -300)
MainFrame.BackgroundColor3  = Color3.fromRGB(12, 12, 20)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Viền sáng
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color     = Color3.fromRGB(0, 120, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.5

-- ============================================
--  THANH TIÊU ĐỀ
-- ============================================
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 38)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text              = "⚓  SAILOR PIECE  |  V2"
TitleLabel.Size              = UDim2.new(1, -55, 1, 0)
TitleLabel.Position          = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextColor3        = Color3.fromRGB(255, 210, 0)
TitleLabel.TextSize          = 15
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Parent            = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "✕"
CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
CloseBtn.Position          = UDim2.new(1, -36, 0, 8)
CloseBtn.BackgroundColor3  = Color3.fromRGB(200, 40, 40)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize          = 14
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- ============================================
--  KÉO GUI
-- ============================================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================
--  SCROLLING FRAME NỘI DUNG
-- ============================================
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size               = UDim2.new(1, 0, 1, -44)
ScrollFrame.Position           = UDim2.new(0, 0, 0, 44)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel    = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
ScrollFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent             = MainFrame

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.Padding          = UDim.new(0, 6)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local PaddingTop = Instance.new("UIPadding", ScrollFrame)
PaddingTop.PaddingTop    = UDim.new(0, 8)
PaddingTop.PaddingBottom = UDim.new(0, 8)
PaddingTop.PaddingLeft   = UDim.new(0, 10)
PaddingTop.PaddingRight  = UDim.new(0, 10)

-- ============================================
--  HÀM TẠO UI
-- ============================================
local function CreateSection(title)
    local lbl = Instance.new("TextLabel")
    lbl.Text              = "─── " .. title .. " ───"
    lbl.Size              = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextColor3        = Color3.fromRGB(255, 210, 0)
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Center
    lbl.Parent            = ScrollFrame
    return lbl
end

local function CreateToggle(labelText, defaultState, callback)
    local state = defaultState or false

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel  = 0
    row.Parent           = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Text              = labelText
    lbl.Size              = UDim2.new(1, -80, 1, 0)
    lbl.Position          = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.Gotham
    lbl.TextColor3        = Color3.fromRGB(210, 210, 235)
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.TextWrapped       = true
    lbl.Parent            = row

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 62, 0, 28)
    btn.Position         = UDim2.new(1, -70, 0.5, -14)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local function UpdateBtn()
        if state then
            btn.Text             = "BẬT"
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        else
            btn.Text             = "TẮT"
            btn.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
        end
    end

    UpdateBtn()

    btn.MouseButton1Click:Connect(function()
        state = not state
        UpdateBtn()
        callback(state)
    end)

    return btn
end

local function CreateInput(labelText, default, onChange)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    row.BorderSizePixel  = 0
    row.Parent           = ScrollFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Text              = labelText
    lbl.Size              = UDim2.new(0, 100, 1, 0)
    lbl.Position          = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.Gotham
    lbl.TextColor3        = Color3.fromRGB(180, 180, 210)
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    local box = Instance.new("TextBox")
    box.Text             = tostring(default)
    box.Size             = UDim2.new(1, -120, 0, 26)
    box.Position         = UDim2.new(0, 110, 0.5, -13)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
    box.Font             = Enum.Font.Gotham
    box.TextColor3       = Color3.fromRGB(255, 255, 255)
    box.TextSize         = 12
    box.BorderSizePixel  = 0
    box.ClearTextOnFocus = false
    box.Parent           = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    box.FocusLost:Connect(function()
        onChange(box.Text)
    end)

    return box
end

local function CreateButton(labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Text             = labelText
    btn.Size             = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(30, 70, 160)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = ScrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(45, 95, 200)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(30, 70, 160)
    end)

    return btn
end

-- ============================================
--  SECTION: AUTO FARM
-- ============================================
CreateSection("⚔  TỰ ĐỘNG FARM")

CreateToggle("🗡 Auto Farm", false, function(on)
    Settings.AutoFarm = on
    if on then StartAutoFarm() else StopAutoFarm() end
end)

CreateToggle("🪂 Bay Trên Đầu Mob (Hover)", true, function(on)
    Settings.AutoHover = on
    if not on then
        DisableHover()
    elseif Settings.AutoFarm then
        EnableHover()
    end
end)

CreateToggle("🏹 Đánh Từ Xa (Range Attack)", true, function(on)
    Settings.RangeAttack = on
    Notify("Đánh từ xa: " .. (on and "BẬT" or "TẮT"))
end)

CreateInput("🎯 Tên Mob:", Settings.FarmMobName, function(val)
    if val and val ~= "" then
        Settings.FarmMobName = val
        Notify("Mob đã đổi: " .. val)
    end
end)

CreateInput("📏 Tầm Đánh (studs):", Settings.AttackRange, function(val)
    local n = tonumber(val)
    if n then
        Settings.AttackRange = n
        Notify("Tầm đánh: " .. n)
    end
end)

CreateInput("🔭 Bán Kính Farm:", Settings.FarmRadius, function(val)
    local n = tonumber(val)
    if n then
        Settings.FarmRadius = n
        Notify("Bán kính farm: " .. n)
    end
end)

CreateInput("⬆ Độ Cao Bay:", Settings.HoverHeight, function(val)
    local n = tonumber(val)
    if n then
        Settings.HoverHeight = n
        Notify("Độ cao bay: " .. n)
    end
end)

-- ============================================
--  SECTION: AUTO QUEST
-- ============================================
CreateSection("📋  TỰ ĐỘNG QUEST")

CreateToggle("📋 Auto Quest (Theo Level)", false, function(on)
    Settings.AutoQuest = on
    if on then StartAutoQuest() else StopAutoQuest() end
end)

CreateButton("🎁 Nhận Thưởng Quest Ngay", function()
    ClaimQuestReward()
end)

-- ============================================
--  SECTION: TELEPORT
-- ============================================
CreateSection("🌊  TELEPORT NHANH")

for name, pos in pairs(Locations) do
    CreateButton("📍 " .. name, function()
        TeleportTo(pos)
        Notify("Đã teleport → " .. name)
    end)
end

-- ============================================
--  SECTION: TIỆN ÍCH
-- ============================================
CreateSection("🛠  TIỆN ÍCH")

CreateButton("🔄 Refresh Nhân Vật", function()
    LocalPlayer:LoadCharacter()
    Notify("Đã refresh nhân vật!")
end)

CreateButton("❤ Heal (Max HP)", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
            Notify("Đã hồi máu!")
        end
    end
end)

CreateButton("🚀 Speed x2 (WalkSpeed 32)", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 32
            Notify("WalkSpeed = 32")
        end
    end
end)

CreateButton("🔁 Reset WalkSpeed", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            Notify("WalkSpeed về 16")
        end
    end
end)

-- ============================================
--  PHÍM TẮT
-- ============================================
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.P then
        MainFrame.Visible = not MainFrame.Visible
        Notify(MainFrame.Visible and "GUI đã hiện" or "GUI đã ẩn")
    end
end)

-- ============================================
--  AUTO RESPAWN
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character        = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid         = char:WaitForChild("Humanoid")
    task.wait(2)

    if Settings.AutoRespawn then
        Notify("🔄 Đã hồi sinh — Script tiếp tục!")
    end

    -- Khởi động lại hover nếu đang farm
    if Settings.AutoFarm then
        task.wait(1)
        if Settings.AutoHover then EnableHover() end
    end
end)

-- ============================================
--  KHỞI ĐỘNG
-- ============================================
Notify("✅ Sailor Piece V2 đã tải!  |  [P] để ẩn/hiện")
print("[Sailor Piece V2] Loaded Successfully!")
