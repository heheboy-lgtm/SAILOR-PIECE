-- ============================================
--       SAILOR PIECE SCRIPT
--       Auto Farm | Teleport | Auto Quest
--       Chạy qua Executor: Synapse X / KRNL / Fluxus
-- ============================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")

local LocalPlayer    = Players.LocalPlayer
local Character      = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid       = Character:WaitForChild("Humanoid")

-- ============================================
--  BIẾN TRẠNG THÁI
-- ============================================
local Settings = {
    AutoFarm       = false,
    AutoQuest      = false,
    FarmMobName    = "Sea King",       -- Tên mob mặc định
    FarmRadius     = 50,               -- Bán kính farm
    TeleportSpeed  = 0.1,              -- Tốc độ tween teleport (giây)
    AutoRespawn    = true,
}

-- ============================================
--  HÀM TIỆN ÍCH
-- ============================================
local function Notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "Sailor Piece Script",
        Text    = msg,
        Duration = 3,
    })
end

local function TeleportTo(position)
    if HumanoidRootPart then
        local goal = {CFrame = CFrame.new(position + Vector3.new(0, 5, 0))}
        local info  = TweenInfo.new(Settings.TeleportSpeed, Enum.EasingStyle.Linear)
        TweenService:Create(HumanoidRootPart, info, goal):Play()
        task.wait(Settings.TeleportSpeed + 0.05)
    end
end

local function GetNearestMob(name, maxDist)
    local nearest, dist = nil, maxDist or math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(name:lower()) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            local hp   = obj:FindFirstChildOfClass("Humanoid")
            if root and hp and hp.Health > 0 then
                local d = (HumanoidRootPart.Position - root.Position).Magnitude
                if d < dist then nearest, dist = obj, d end
            end
        end
    end
    return nearest
end

local function AttackMob(mob)
    local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
              or Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    if not Character:FindFirstChild(tool.Name) then
        tool.Parent = Character
        task.wait(0.1)
    end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if root then
        TeleportTo(root.Position)
        -- Kích hoạt tool
        local event = tool:FindFirstChildOfClass("RemoteEvent")
                   or tool:FindFirstChild("Activate")
        if tool:FindFirstChild("Handle") then
            local args = {root.Position}
            pcall(function()
                tool.Activated:Fire()
            end)
        end
    end
end

-- ============================================
--  AUTO FARM LOOP
-- ============================================
local autoFarmConn
local function StartAutoFarm()
    if autoFarmConn then autoFarmConn:Disconnect() end
    autoFarmConn = RunService.Heartbeat:Connect(function()
        if not Settings.AutoFarm then return end
        local char = LocalPlayer.Character
        if not char then return end
        HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        Humanoid         = char:FindFirstChildOfClass("Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then return end

        local mob = GetNearestMob(Settings.FarmMobName, Settings.FarmRadius)
        if mob then
            local root = mob:FindFirstChild("HumanoidRootPart")
            local hp   = mob:FindFirstChildOfClass("Humanoid")
            if root and hp and hp.Health > 0 then
                TeleportTo(root.Position)
                -- Tấn công bằng cách dùng tool đang cầm
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
    if autoFarmConn then
        autoFarmConn:Disconnect()
        autoFarmConn = nil
    end
    Notify("Auto Farm TẮT")
end

-- ============================================
--  AUTO QUEST LOOP
-- ============================================
local autoQuestConn
local function StartAutoQuest()
    if autoQuestConn then autoQuestConn:Disconnect() end
    autoQuestConn = task.spawn(function()
        while Settings.AutoQuest do
            -- Tìm NPC Quest Giver gần nhất
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("quest") or name:find("navy") or name:find("pirate") then
                        local root = obj:FindFirstChild("HumanoidRootPart")
                        if root then
                            TeleportTo(root.Position)
                            task.wait(0.5)
                            -- Nhấn vào NPC thông qua ProximityPrompt / Click
                            local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                            if prompt then
                                fireproximityprompt(prompt)
                                task.wait(0.5)
                            end
                            -- Thử click detector
                            local click = obj:FindFirstChildOfClass("ClickDetector", true)
                            if click then
                                fireclickdetector(click)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
            -- Tìm và nhận reward nếu quest hoàn thành
            local questGui = LocalPlayer.PlayerGui:FindFirstChild("QuestGui")
                          or LocalPlayer.PlayerGui:FindFirstChild("Quest")
            if questGui then
                for _, btn in ipairs(questGui:GetDescendants()) do
                    if btn:IsA("TextButton") then
                        local t = btn.Text:lower()
                        if t:find("complete") or t:find("claim") or t:find("nhận") or t:find("hoàn") then
                            btn.MouseButton1Click:Fire()
                            task.wait(0.3)
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
    if autoQuestConn then
        task.cancel(autoQuestConn)
        autoQuestConn = nil
    end
    Notify("Auto Quest TẮT")
end

-- ============================================
--  TELEPORT ĐẾN VỊ TRÍ CỐ ĐỊNH
-- ============================================
local Locations = {
    ["Hải Đảo Bắt Đầu"]   = Vector3.new(0,    0,    0),
    ["Biển Đông (Marine)"] = Vector3.new(500,  0,  -200),
    ["Đảo Cướp Biển"]      = Vector3.new(-400, 0,   300),
    ["Vùng Biển Sâu"]      = Vector3.new(1000, 0,  1000),
    ["Boss Island"]        = Vector3.new(2000, 0,  -500),
}

-- ============================================
--  TẠO GUI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SailorPieceHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = LocalPlayer.PlayerGui

-- Frame chính
local MainFrame = Instance.new("Frame")
MainFrame.Size              = UDim2.new(0, 340, 0, 480)
MainFrame.Position          = UDim2.new(0.5, -170, 0.5, -240)
MainFrame.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Thanh tiêu đề
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text              = "⚓  SAILOR PIECE  |  SCRIPT HUB"
TitleLabel.Size              = UDim2.new(1, -50, 1, 0)
TitleLabel.Position          = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
TitleLabel.TextSize          = 14
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.Parent            = TitleBar

-- Nút đóng
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "✕"
CloseBtn.Size              = UDim2.new(0, 30, 0, 30)
CloseBtn.Position          = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3  = Color3.fromRGB(200, 50, 50)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextColor3        = Color3.fromRGB(255,255,255)
CloseBtn.TextSize          = 14
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Kéo GUI
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
--  HÀM TẠO NÚT BẬT/TẮT
-- ============================================
local yOffset = 55
local function CreateToggle(labelText, callback)
    local state = false

    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -20, 0, 38)
    row.Position         = UDim2.new(0, 10, 0, yOffset)
    row.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    row.BorderSizePixel  = 0
    row.Parent           = MainFrame
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    yOffset = yOffset + 46

    local lbl = Instance.new("TextLabel")
    lbl.Text              = labelText
    lbl.Size              = UDim2.new(1, -80, 1, 0)
    lbl.Position          = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.Gotham
    lbl.TextColor3        = Color3.fromRGB(220, 220, 240)
    lbl.TextSize          = 13
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    local btn = Instance.new("TextButton")
    btn.Text             = "TẮT"
    btn.Size             = UDim2.new(0, 60, 0, 26)
    btn.Position         = UDim2.new(1, -68, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.Parent           = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            btn.Text             = "BẬT"
            btn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        else
            btn.Text             = "TẮT"
            btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        end
        callback(state)
    end)
    return btn
end

-- ============================================
--  HÀM TẠO NÚT ACTION
-- ============================================
local function CreateButton(labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Text             = labelText
    btn.Size             = UDim2.new(1, -20, 0, 36)
    btn.Position         = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 13
    btn.BorderSizePixel  = 0
    btn.Parent           = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    yOffset = yOffset + 44
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================
--  HÀM TẠO LABEL PHÂN LOẠI
-- ============================================
local function CreateSection(title)
    local lbl = Instance.new("TextLabel")
    lbl.Text              = "── " .. title .. " ──"
    lbl.Size              = UDim2.new(1, -20, 0, 24)
    lbl.Position          = UDim2.new(0, 10, 0, yOffset)
    lbl.BackgroundTransparency = 1
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextColor3        = Color3.fromRGB(255, 215, 0)
    lbl.TextSize          = 12
    lbl.TextXAlignment    = Enum.TextXAlignment.Center
    lbl.Parent            = MainFrame
    yOffset = yOffset + 30
end

-- ============================================
--  XÂY DỰNG CÁC TAB
-- ============================================

-- SECTION: FARM
CreateSection("⚔  TỰ ĐỘNG FARM")

CreateToggle("Auto Farm Mob", function(on)
    Settings.AutoFarm = on
    if on then StartAutoFarm() else StopAutoFarm() end
end)

-- Input tên mob
local mobRow = Instance.new("Frame")
mobRow.Size             = UDim2.new(1, -20, 0, 38)
mobRow.Position         = UDim2.new(0, 10, 0, yOffset)
mobRow.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
mobRow.BorderSizePixel  = 0
mobRow.Parent           = MainFrame
Instance.new("UICorner", mobRow).CornerRadius = UDim.new(0, 8)
yOffset = yOffset + 46

local mobLbl = Instance.new("TextLabel")
mobLbl.Text = "Tên Mob:"
mobLbl.Size = UDim2.new(0, 70, 1, 0)
mobLbl.Position = UDim2.new(0, 10, 0, 0)
mobLbl.BackgroundTransparency = 1
mobLbl.Font = Enum.Font.Gotham
mobLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
mobLbl.TextSize = 12
mobLbl.TextXAlignment = Enum.TextXAlignment.Left
mobLbl.Parent = mobRow

local mobInput = Instance.new("TextBox")
mobInput.Text             = Settings.FarmMobName
mobInput.Size             = UDim2.new(1, -90, 0, 26)
mobInput.Position         = UDim2.new(0, 80, 0.5, -13)
mobInput.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
mobInput.Font             = Enum.Font.Gotham
mobInput.TextColor3       = Color3.fromRGB(255, 255, 255)
mobInput.TextSize         = 12
mobInput.BorderSizePixel  = 0
mobInput.Parent           = mobRow
Instance.new("UICorner", mobInput).CornerRadius = UDim.new(0, 6)
mobInput.FocusLost:Connect(function()
    Settings.FarmMobName = mobInput.Text
    Notify("Đổi mob: " .. mobInput.Text)
end)

-- SECTION: QUEST
CreateSection("📋  TỰ ĐỘNG QUEST")
CreateToggle("Auto Quest", function(on)
    Settings.AutoQuest = on
    if on then StartAutoQuest() else StopAutoQuest() end
end)

-- SECTION: TELEPORT
CreateSection("🌊  TELEPORT NHANH")
for name, pos in pairs(Locations) do
    CreateButton("📍 " .. name, function()
        TeleportTo(pos)
        Notify("Đã teleport → " .. name)
    end)
end

-- ============================================
--  NÚT HIỆN/ẨN (phím P)
-- ============================================
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.P then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ============================================
--  AUTO RESPAWN
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character         = char
    HumanoidRootPart  = char:WaitForChild("HumanoidRootPart")
    Humanoid          = char:WaitForChild("Humanoid")
    task.wait(2)
    if Settings.AutoRespawn then
        Notify("Đã hồi sinh — Script tiếp tục chạy!")
    end
end)

-- ============================================
Notify("✅ Sailor Piece Script đã tải xong!  |  Nhấn [P] để ẩn/hiện GUI")
print("[Sailor Piece Script] Loaded Successfully!")
