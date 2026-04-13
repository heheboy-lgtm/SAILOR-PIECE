-- ============================================
--  THÊM VÀO PHẦN BIẾN TRẠNG THÁI (Settings)
-- ============================================
Settings.RangeAttack   = true   -- Đánh từ xa
Settings.AttackRange   = 30     -- Khoảng cách đánh xa
Settings.HoverHeight   = 8      -- Độ cao bay trên đầu mob
Settings.AutoHover     = true   -- Bật bay trên đầu mob khi farm

-- ============================================
--  HỆ THỐNG BAY TRÊN ĐẦU MOB
-- ============================================
local hoverBG = nil  -- BodyGyro
local hoverBV = nil  -- BodyVelocity

local function EnableHover()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Xóa cũ nếu có
    if hrp:FindFirstChild("FarmBG") then hrp.FarmBG:Destroy() end
    if hrp:FindFirstChild("FarmBV") then hrp.FarmBV:Destroy() end

    hoverBG = Instance.new("BodyGyro", hrp)
    hoverBG.Name = "FarmBG"
    hoverBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    hoverBG.P = 9e4
    hoverBG.CFrame = hrp.CFrame

    hoverBV = Instance.new("BodyVelocity", hrp)
    hoverBV.Name = "FarmBV"
    hoverBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    hoverBV.Velocity = Vector3.new(0, 0, 0)
end

local function DisableHover()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp:FindFirstChild("FarmBG") then hrp.FarmBG:Destroy() end
    if hrp:FindFirstChild("FarmBV") then hrp.FarmBV:Destroy() end
    hoverBG = nil
    hoverBV = nil
end

local function HoverAboveMob(mob)
    if not mob or not hoverBV or not hoverBG then return end
    local root = mob:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos = root.Position + Vector3.new(0, Settings.HoverHeight, 0)
    local diff = targetPos - hrp.Position

    -- Bay nhẹ nhàng đến vị trí trên đầu mob
    hoverBV.Velocity = diff * 3
    hoverBG.CFrame = CFrame.new(hrp.Position, root.Position)
end

-- ============================================
--  ĐÁNH TỪ XA (RANGE ATTACK)
-- ============================================
local function RangeAttackMob(mob)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local mobRoot = mob:FindFirstChild("HumanoidRootPart")
    if not mobRoot then return end

    local dist = (hrp.Position - mobRoot.Position).Magnitude

    -- Kiểm tra trong tầm đánh xa
    if dist > Settings.AttackRange then return end

    -- Tìm tool trong nhân vật hoặc túi đồ
    local tool = char:FindFirstChildOfClass("Tool")
              or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Trang bị tool nếu chưa có
    if not char:FindFirstChild(tool.Name) then
        tool.Parent = char
        task.wait(0.1)
    end

    -- Kích hoạt đánh
    local handle = tool:FindFirstChild("Handle")
    if handle then
        -- Thử Fire RemoteEvent của tool
        for _, obj in ipairs(tool:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                pcall(function()
                    obj:FireServer(mobRoot.CFrame, mobRoot.Position)
                end)
            end
        end
        -- Backup: kích hoạt Activated
        pcall(function() tool.Activated:Fire() end)
    end
end

-- ============================================
--  AUTO QUEST THÔNG MINH (NHẬN BIẾT LEVEL)
-- ============================================
local CurrentQuest = nil
local QuestActive   = false

local function GetPlayerLevel()
    -- Tìm leaderstats level của nhân vật
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if stats then
        local lv = stats:FindFirstChild("Level") or stats:FindFirstChild("Lv")
                or stats:FindFirstChild("level") or stats:FindFirstChild("EXP")
        if lv then return tonumber(lv.Value) or 1 end
    end
    return 1
end

local function CheckQuestStatus()
    -- Kiểm tra xem đang có quest chưa qua GUI
    local playerGui = LocalPlayer.PlayerGui
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local t = gui.Text:lower()
            -- Nếu thấy chữ "complete", "hoàn thành" => quest đang active
            if t:find("complete") or t:find("hoàn thành") or t:find("in progress") then
                return true
            end
        end
    end
    return false
end

local function ClaimQuestReward()
    local playerGui = LocalPlayer.PlayerGui
    for _, btn in ipairs(playerGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local t = btn.Text:lower()
            if t:find("claim") or t:find("complete") or t:find("nhận") or t:find("hoàn") then
                pcall(function() btn.MouseButton1Click:Fire() end)
                task.wait(0.5)
                Notify("✅ Đã nhận thưởng quest!")
            end
        end
    end
end

local function TryAcceptQuest(npc)
    local playerLv = GetPlayerLevel()
    local npcRoot  = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return false end

    -- Nếu đang có quest khác => bỏ qua
    if CheckQuestStatus() then
        Notify("⚠ Đang có quest! Hoàn thành trước.")
        return false
    end

    -- Teleport đến NPC
    TeleportTo(npcRoot.Position)
    task.wait(0.5)

    -- Thử ProximityPrompt
    local prompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.5)
    end

    -- Thử ClickDetector
    local click = npc:FindFirstChildOfClass("ClickDetector", true)
    if click then
        pcall(function() fireclickdetector(click) end)
        task.wait(0.5)
    end

    -- Chọn quest phù hợp level trong GUI
    local playerGui = LocalPlayer.PlayerGui
    for _, btn in ipairs(playerGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local t = btn.Text:lower()
            -- Nhận quest nếu tên nút chứa "accept", "nhận", "take"
            if t:find("accept") or t:find("nhận") or t:find("take quest") then
                -- Kiểm tra level yêu cầu (tìm TextLabel gần đó)
                local requiredLv = 0
                local parent = btn.Parent
                if parent then
                    for _, sib in ipairs(parent:GetDescendants()) do
                        if sib:IsA("TextLabel") then
                            local num = sib.Text:match("Lv%.?%s*(%d+)")
                                     or sib.Text:match("Level%s*(%d+)")
                                     or sib.Text:match("(%d+)")
                            if num then requiredLv = tonumber(num) or 0 end
                        end
                    end
                end

                if playerLv >= requiredLv then
                    pcall(function() btn.MouseButton1Click:Fire() end)
                    QuestActive = true
                    Notify("📋 Đã nhận quest (Lv " .. requiredLv .. " yêu cầu)")
                    task.wait(0.3)
                    return true
                else
                    Notify("❌ Level không đủ: cần Lv " .. requiredLv)
                end
            end
        end
    end
    return false
end

-- ============================================
--  VÒNG LẶP AUTO QUEST MỚI
-- ============================================
local autoQuestConn2
local function StartAutoQuestSmart()
    if autoQuestConn2 then task.cancel(autoQuestConn2) end

    autoQuestConn2 = task.spawn(function()
        while Settings.AutoQuest do
            -- 1) Thử nhận thưởng nếu đã hoàn thành
            ClaimQuestReward()
            task.wait(0.5)

            -- 2) Tìm NPC quest gần nhất
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if not Settings.AutoQuest then break end
                if obj:IsA("Model") then
                    local name = obj.Name:lower()
                    if name:find("quest") or name:find("navy") or name:find("pirate")
                    or name:find("marine") or name:find("npc") then
                        TryAcceptQuest(obj)
                        task.wait(0.3)
                    end
                end
            end

            task.wait(3)
        end
    end)
    Notify("📋 Auto Quest Thông Minh BẬT")
end

-- ============================================
--  AUTO FARM LOOP MỚI (TÍCH HỢP BAY + ĐÁNH XA)
-- ============================================
local autoFarmConn2
local function StartAutoFarmV2()
    if autoFarmConn2 then autoFarmConn2:Disconnect() end

    -- Bật hover nếu cài đặt cho phép
    if Settings.AutoHover then EnableHover() end

    autoFarmConn2 = RunService.Heartbeat:Connect(function()
        if not Settings.AutoFarm then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end

        -- Cập nhật lại biến
        HumanoidRootPart = hrp
        Humanoid = hum

        local mob = GetNearestMob(Settings.FarmMobName, Settings.FarmRadius)
        if mob then
            local mobRoot = mob:FindFirstChild("HumanoidRootPart")
            local mobHp   = mob:FindFirstChildOfClass("Humanoid")
            if not mobRoot or not mobHp or mobHp.Health <= 0 then return end

            -- Bay trên đầu mob
            if Settings.AutoHover and hoverBV then
                HoverAboveMob(mob)
            end

            -- Đánh từ xa
            if Settings.RangeAttack then
                RangeAttackMob(mob)
            else
                -- Đánh gần (cũ)
                TeleportTo(mobRoot.Position)
                local activeTool = char:FindFirstChildOfClass("Tool")
                if activeTool then
                    pcall(function() activeTool.Activated:Fire() end)
                end
            end
        else
            -- Không có mob, giữ vị trí
            if hoverBV then
                hoverBV.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    Notify("⚔ Auto Farm V2 BẬT: " .. Settings.FarmMobName)
end

local function StopAutoFarmV2()
    if autoFarmConn2 then
        autoFarmConn2:Disconnect()
        autoFarmConn2 = nil
    end
    DisableHover()
    Notify("⚔ Auto Farm TẮT")
end

-- ============================================
--  THÊM VÀO GUI (bên dưới CreateSection Farm)
-- ============================================
-- Thay thế toggle Auto Farm cũ bằng:
CreateSection("⚔  AUTO FARM V2")

CreateToggle("Auto Farm + Bay + Đánh Xa", function(on)
    Settings.AutoFarm = on
    if on then StartAutoFarmV2() else StopAutoFarmV2() end
end)

CreateToggle("Chế Độ Bay Trên Đầu Mob", function(on)
    Settings.AutoHover = on
    if not on then DisableHover() end
end)

CreateToggle("Đánh Từ Xa (Range Attack)", function(on)
    Settings.RangeAttack = on
end)

-- Thanh chỉnh tầm đánh xa
local rangeRow = Instance.new("Frame")
rangeRow.Size             = UDim2.new(1, -20, 0, 38)
rangeRow.Position         = UDim2.new(0, 10, 0, yOffset)
rangeRow.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
rangeRow.BorderSizePixel  = 0
rangeRow.Parent           = MainFrame
Instance.new("UICorner", rangeRow).CornerRadius = UDim.new(0, 8)
yOffset = yOffset + 46

local rangeLbl = Instance.new("TextLabel")
rangeLbl.Text = "Tầm Đánh:"
rangeLbl.Size = UDim2.new(0, 80, 1, 0)
rangeLbl.Position = UDim2.new(0, 10, 0, 0)
rangeLbl.BackgroundTransparency = 1
rangeLbl.Font = Enum.Font.Gotham
rangeLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
rangeLbl.TextSize = 12
rangeLbl.TextXAlignment = Enum.TextXAlignment.Left
rangeLbl.Parent = rangeRow

local rangeInput = Instance.new("TextBox")
rangeInput.Text             = tostring(Settings.AttackRange)
rangeInput.Size             = UDim2.new(1, -100, 0, 26)
rangeInput.Position         = UDim2.new(0, 90, 0.5, -13)
rangeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
rangeInput.Font             = Enum.Font.Gotham
rangeInput.TextColor3       = Color3.fromRGB(255, 255, 255)
rangeInput.TextSize         = 12
rangeInput.BorderSizePixel  = 0
rangeInput.Parent           = rangeRow
Instance.new("UICorner", rangeInput).CornerRadius = UDim.new(0, 6)
rangeInput.FocusLost:Connect(function()
    local n = tonumber(rangeInput.Text)
    if n then
        Settings.AttackRange = n
        Notify("Tầm đánh: " .. n .. " studs")
    end
end)

-- Quest thông minh section
CreateSection("📋  AUTO QUEST THÔNG MINH")
CreateToggle("Auto Quest (Theo Level)", function(on)
    Settings.AutoQuest = on
    if on then StartAutoQuestSmart()
    else
        Settings.AutoQuest = false
        if autoQuestConn2 then task.cancel(autoQuestConn2) autoQuestConn2 = nil end
        Notify("Auto Quest TẮT")
    end
end)

-- ============================================
--  AUTO RESPAWN: cập nhật để duy trì hover
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character        = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid         = char:WaitForChild("Humanoid")
    task.wait(2)
    if Settings.AutoRespawn then
        Notify("🔄 Đã hồi sinh!")
        -- Khởi động lại hover nếu đang farm
        if Settings.AutoFarm and Settings.AutoHover then
            task.wait(1)
            EnableHover()
        end
    end
end)
