local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/maotiandi/Cat-script/refs/heads/main/CatUI.lua"))()
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)
local Window = WindUI:CreateWindow({
    Title = "ZE",
    Author = "猫天帝定制",
    Folder = "ZE",
    Size = UDim2.fromOffset(390, 460),
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 150,
    ScrollBarEnabled = true,
    Background = "",
    BackgroundImageTransparency = 0.5,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 192, 203))
    }),
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end
    },
})
Window:EditOpenButton({
    Title = "ZE",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2.5,
    Color = ColorSequence.new(Color3.fromRGB(255, 100, 100)),
    Draggable = true,
    OnlyMobile = false,
})
Window.ToggleKey = Enum.KeyCode.RightShift
local Tabs = {}
function Tabs:Create(name, icon)
    return Window:Tab({ Title = name, Icon = icon })
end
local FastTrain
do
    local lp = Players.LocalPlayer
    local muscleEvent
    local Strength
    task.spawn(function()
        muscleEvent = lp:WaitForChild("muscleEvent")
    end)
    task.spawn(function()
        local ls = lp:WaitForChild("leaderstats")
        Strength = ls:WaitForChild("Strength")
    end)
    local CONFIG = {
        Rate = 500,
        TokenBurst = 20,
    }
    local state = {
        running = false,
        tokens = 0,
        lastTick = os.clock(),
        sendRate = CONFIG.Rate,
        lastControlAt = 0,
        lastStrength = 0,
        stalledCount = 0,
    }
    local function unlockTools()
        local tools = {
            { name = "Weight", prop = "repTime" },
            { name = "Pushups", prop = "repTime" },
            { name = "Situps", prop = "repTime" },
            { name = "Handstands", prop = "repTime" },
        }
        local function process(container)
            for _, toolData in ipairs(tools) do
                local tool = container:FindFirstChild(toolData.name)
                if tool then
                    local timeObj = tool:FindFirstChild(toolData.prop)
                    if timeObj then
                        timeObj.Value = 0
                    end
                end
            end
        end
        local backpack = lp:FindFirstChild("Backpack")
        if backpack then process(backpack) end
        local char = lp.Character
        if char then process(char) end
    end
    RunService.Heartbeat:Connect(unlockTools)
    local function updateRate(now)
        if now - state.lastControlAt < 0.5 then return end
        state.lastControlAt = now
        if not Strength then return end
        local currentStr = Strength.Value
        if currentStr > state.lastStrength then
            state.stalledCount = 0
            state.sendRate = math.min(CONFIG.Rate, state.sendRate + 50)
        else
            state.stalledCount = state.stalledCount + 1
        end
        if state.stalledCount >= 2 then
            state.sendRate = math.max(100, state.sendRate - 100)
            state.stalledCount = 0
            state.tokens = 0
        end
        state.lastStrength = currentStr
    end
    RunService.Heartbeat:Connect(function()
        if not state.running then return end
        if not muscleEvent then return end
        local now = os.clock()
        local dt = now - state.lastTick
        state.lastTick = now
        updateRate(now)
        state.tokens = math.min(CONFIG.TokenBurst, state.tokens + state.sendRate * dt)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local sent = 0
            while state.tokens >= 1 do
                muscleEvent:FireServer("rep")
                state.tokens = state.tokens - 1
                sent = sent + 1
                if sent >= CONFIG.TokenBurst then break end
            end
        else
            state.tokens = 0
        end
    end)
    FastTrain = {}
    function FastTrain.SetRate(rate)
        local n = tonumber(rate)
        if n and n > 0 then
            CONFIG.Rate = math.floor(n)
            if state.sendRate > CONFIG.Rate then
                state.sendRate = CONFIG.Rate
            end
        end
    end
    function FastTrain.Start()
        if state.running then return end
        state.running = true
        state.lastTick = os.clock()
        state.lastControlAt = os.clock()
        state.sendRate = CONFIG.Rate
        state.tokens = 0
        if Strength then
            state.lastStrength = Strength.Value
        end
    end
    function FastTrain.Stop()
        state.running = false
        state.tokens = 0
    end
    function FastTrain.IsRunning()
        return state.running
    end
end
Tabs.Attribute = Tabs:Create("属性", "user")
do
    local Tab = Tabs.Attribute
    local currentPlayer = Players.LocalPlayer
    local attrPara = Tab:Paragraph({
        Title = "当前玩家属性",
        Desc = "读取中...",
    })
    local function getAttrString(plr)
        if not plr then return "无效玩家" end
        local leaderstats = plr:FindFirstChild("leaderstats")
        local gym = plr:FindFirstChild("GymCurrencies")
        local function getVal(parent, name)
            if parent then
                local v = parent:FindFirstChild(name)
                if v and v:IsA("ValueBase") then return tostring(v.Value) end
            end
            local v2 = plr:FindFirstChild(name)
            if v2 and v2:IsA("ValueBase") then return tostring(v2.Value) end
            return "0"
        end
        local gpCount = 0
        local gps = plr:FindFirstChild("ownedGamepasses")
        if gps then
            if gps:IsA("Folder") then
                for _, v in ipairs(gps:GetChildren()) do
                    if v:IsA("BoolValue") and v.Value then gpCount = gpCount + 1 end
                end
            elseif gps:IsA("BoolValue") and gps.Value then
                gpCount = 1
            end
        end
        local s = ""
        s = s .. "力量: " .. getVal(leaderstats, "Strength") .. "\n"
        s = s .. "耐力: " .. getVal(plr, "Durability") .. "\n"
        s = s .. "敏捷: " .. getVal(plr, "Agility") .. "\n"
        s = s .. "重生: " .. getVal(leaderstats, "Rebirths") .. "\n"
        s = s .. "击杀: " .. getVal(leaderstats, "Kills") .. "\n"
        s = s .. "邪恶业报: " .. getVal(plr, "evilKarma") .. "\n"
        s = s .. "善良业报: " .. getVal(plr, "goodKarma") .. "\n"
        s = s .. "争斗: " .. getVal(leaderstats, "Brawls") .. "\n"
        s = s .. "宝石: " .. getVal(plr, "Gems") .. "\n"
        s = s .. "过载碎片: " .. getVal(plr, "OverchargedShards") .. "\n"
        s = s .. "玉米糖: " .. getVal(plr, "CandyCorn") .. "\n"
        s = s .. "雪花: " .. getVal(gym, "Snowflakes") .. "\n"
        s = s .. "外星人货币: " .. getVal(gym, "AlienTokens") .. "\n"
        s = s .. "奖章: " .. getVal(plr, "Medals") .. "\n"
        s = s .. "氏族点数: " .. getVal(plr, "ClanPoints") .. "\n"
        s = s .. "通行证数量: " .. tostring(gpCount)
        return s
    end
    task.spawn(function()
        while Tab do
            if currentPlayer then
                local ok, txt = pcall(getAttrString, currentPlayer)
                if ok then attrPara:SetDesc(txt) end
            end
            task.wait(1)
        end
    end)
    local targetPara = Tab:Paragraph({
        Title = "选中玩家属性",
        Desc = "请选择玩家",
    })
    local selectedPlr = nil
    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then table.insert(names, p.Name) end
        end
        if #names == 0 then table.insert(names, "无其他玩家") end
        return names
    end
    local plrDropdown = Tab:Dropdown({
        Title = "选择服务器玩家",
        Values = getPlayerNames(),
        Default = "",
        Callback = function(val)
            if val == "无其他玩家" or val == "" then
                selectedPlr = nil
                targetPara:SetDesc("请选择玩家")
            else
                selectedPlr = Players:FindFirstChild(val)
                if selectedPlr then targetPara:SetDesc(getAttrString(selectedPlr)) end
            end
        end
    })
    Tab:Button({
        Title = "刷新玩家列表",
        Callback = function()
            pcall(function() plrDropdown:Refresh(getPlayerNames()) end)
        end
    })
    task.spawn(function()
        while Tab do
            task.wait(1)
            if selectedPlr and selectedPlr.Parent then
                local ok, txt = pcall(getAttrString, selectedPlr)
                if ok then targetPara:SetDesc(txt) end
            end
        end
    end)
    Tab:Button({
        Title = "属性显示",
        Callback = function()
            local player = Players.LocalPlayer
            local playerGui = player:WaitForChild("PlayerGui")
            local UserInputService = game:GetService("UserInputService")
            local oldGui = playerGui:FindFirstChild("CatStatsPanel")
            if oldGui then oldGui:Destroy() end
            local gui = Instance.new("ScreenGui")
            gui.Name = "CatStatsPanel"
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = playerGui
            local main = Instance.new("Frame")
            main.Size = UDim2.new(0, 240, 0, 175)
            main.Position = UDim2.new(0.12, 0, 0.35, 0)
            main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            main.BackgroundTransparency = 0.4
            main.BorderSizePixel = 2
            main.BorderColor3 = Color3.fromRGB(255, 165, 0)
            main.ClipsDescendants = true
            main.Active = true
            main.Parent = gui
            Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -10, 0, 30)
            titleLabel.Position = UDim2.new(0, 5, 0, 4)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = "属性"
            titleLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            titleLabel.TextSize = 14
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = main
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 28, 0, 28)
            closeBtn.Position = UDim2.new(1, -32, 0, 4)
            closeBtn.BackgroundTransparency = 1
            closeBtn.Text = "╳"
            closeBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
            closeBtn.TextSize = 18
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.Parent = main
            closeBtn.MouseButton1Click:Connect(function()
                gui:Destroy()
            end)
            local stats = {
                {key = "Strength", label = "力量", color = Color3.fromRGB(255, 50, 50)},
                {key = "Durability", label = "耐力", color = Color3.fromRGB(50, 150, 255)},
                {key = "Agility", label = "敏捷", color = Color3.fromRGB(50, 225, 50)},
                {key = "Rebirths", label = "重生", color = Color3.fromRGB(255, 200, 100)},
            }
            local valueLabels = {}
            local startY = 38
            local rowHeight = 32
            for i, stat in ipairs(stats) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, rowHeight)
                row.Position = UDim2.new(0, 5, 0, startY + (i-1)*(rowHeight+2))
                row.BackgroundColor3 = Color3.fromRGB(255, 192, 203)
                row.BackgroundTransparency = 0.85
                row.BorderSizePixel = 0
                row.Parent = main
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(0, 3, 0.5, 0)
                bar.Position = UDim2.new(0, 6, 0.25, 0)
                bar.BackgroundColor3 = stat.color
                bar.BorderSizePixel = 0
                bar.Parent = row
                Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.4, -10, 1, 0)
                nameLabel.Position = UDim2.new(0, 14, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = stat.label
                nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
                nameLabel.TextSize = 13
                nameLabel.Font = Enum.Font.GothamSemibold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = row
                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.6, -10, 1, 0)
                valLabel.Position = UDim2.new(0.4, 0, 0, 0)
                valLabel.BackgroundTransparency = 1
                valLabel.Text = "…"
                valLabel.TextColor3 = stat.color
                valLabel.TextSize = 16
                valLabel.Font = Enum.Font.GothamBold
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.TextScaled = true
                valLabel.Parent = row
                valueLabels[stat.key] = valLabel
            end
            local dragging = false
            local dragStart = Vector2.new()
            local startPos = main.Position
            main.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local absPos = closeBtn.AbsolutePosition
                    local absSize = closeBtn.AbsoluteSize
                    if input.Position.X >= absPos.X and input.Position.X <= absPos.X + absSize.X and
                    input.Position.Y >= absPos.Y and input.Position.Y <= absPos.Y + absSize.Y then
                        return
                    end
                    dragging = true
                    dragStart = input.Position
                    startPos = main.Position
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    main.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
            local function findStatObject(statKey)
                local ls = player:FindFirstChild("leaderstats")
                if ls then
                    local obj = ls:FindFirstChild(statKey)
                    if obj and obj:IsA("ValueBase") then return obj end
                    for _, child in ipairs(ls:GetChildren()) do
                        if child.Name:lower() == statKey:lower() and child:IsA("ValueBase") then
                            return child
                        end
                    end
                end
                local direct = player:FindFirstChild(statKey)
                if direct and direct:IsA("ValueBase") then return direct end
                for _, child in ipairs(player:GetChildren()) do
                    if child.Name:lower() == statKey:lower() and child:IsA("ValueBase") then
                        return child
                    end
                end
                return nil
            end
            local function setupStat(stat)
                local obj = findStatObject(stat.key)
                if not obj then return end
                local label = valueLabels[stat.key]
                label.Text = tostring(obj.Value)
                obj:GetPropertyChangedSignal("Value"):Connect(function()
                    label.Text = tostring(obj.Value)
                end)
            end
            for _, stat in ipairs(stats) do
                setupStat(stat)
            end
            if not player:FindFirstChild("leaderstats") then
                local conn
                conn = player.ChildAdded:Connect(function(child)
                    if child.Name == "leaderstats" or child.Name:lower() == "agility" or child.Name:lower() == "durability" then
                        conn:Disconnect()
                        for _, stat in ipairs(stats) do
                            setupStat(stat)
                        end
                    end
                end)
            end
        end
    })
end
Tabs.PlayerSection = Window:Section({
    Title = "锻炼",
    Icon = "dumbbell",
    Opened = true
})
Tabs.Basic = Tabs.PlayerSection:Tab({ Title = "基础", Icon = "settings" })
do
    local Tab = Tabs.Basic
    local workType = ""
    local autowork = false
    local autorebirth = false
    local rebirthTarget = 0
    local rebirthMainThread = nil
    local customSizeEnabled = false
    local customSizeValue = 1
    local customTeleportEnabled = false
    local customTeleportTarget = nil
    local function removeEffects()
        local uiFolder = game:GetService("ReplicatedStorage"):WaitForChild("shared"):WaitForChild("assets"):WaitForChild("ui")
        local effectNames = {"durabilityFrame", "agilityFrame", "strengthFrame"}
        for _, name in ipairs(effectNames) do
            local obj = uiFolder:FindFirstChild(name)
            if obj then
                obj:Destroy()
            end
        end
    end
    local function optimizeEnvironment()
        for _, v in ipairs(workspace:GetChildren()) do
            pcall(function()
                v:Destroy()
            end)
        end
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        for _, v in ipairs(playerGui:GetChildren()) do
            pcall(function()
                v:Destroy()
            end)
        end
        local lighting = game:GetService("Lighting")
        for _, v in ipairs(lighting:GetChildren()) do
            pcall(function()
                v:Destroy()
            end)
        end
    end
    local function parseTargetPosition(inputStr)
        if not inputStr or inputStr == "" then return nil end
        local x, y, z
        local cframePattern = "CFrame%.new%((.-)%)"
        local params = inputStr:match(cframePattern)
        if params then
            local parts = {}
            for part in params:gmatch("[^,]+") do
                table.insert(parts, part)
            end
            if #parts >= 3 then
                x = tonumber(parts[1])
                y = tonumber(parts[2])
                z = tonumber(parts[3])
            end
        else
            local parts = {}
            for part in inputStr:gmatch("[^,]+") do
                table.insert(parts, part)
            end
            if #parts >= 3 then
                x = tonumber(parts[1])
                y = tonumber(parts[2])
                z = tonumber(parts[3])
            end
        end
        if x and y and z then
            return Vector3.new(x, y, z)
        end
        return nil
    end
    local function applyCustomSize()
        if not customSizeEnabled then return end
        pcall(function()
            ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("changeSpeedSizeRemote"):InvokeServer("changeSize", customSizeValue)
        end)
    end
    Players.LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        applyCustomSize()
    end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not customTeleportEnabled then continue end
            pcall(function()
                local char = Players.LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local targetPos = customTeleportTarget
                if not targetPos then return end
                if (root.Position - targetPos).Magnitude > 1 then
                    root.CFrame = CFrame.new(targetPos)
                end
            end)
        end
    end)
    Tab:Dropdown({
        Title = "选择锻炼类型",
        Values = { "哑铃", "倒立", "仰卧起坐", "俯卧撑", "--"},
        Default = "",
        Callback = function(val) workType = val end
    })
    Tab:Toggle({
        Title = "自动锻炼",
        Default = false,
        Callback = function(state)
            autowork = state
            if state then
                task.spawn(function()
                    while autowork do
                        pcall(function()
                            local player = Players.LocalPlayer
                            local char = player.Character
                            local backpack = player.Backpack
                            if not char then return end
                            player.muscleEvent:FireServer("rep")
                            local toolName = ""
                            if workType == "哑铃" then toolName = "Weight"
                            elseif workType == "倒立" then toolName = "Handstands"
                            elseif workType == "仰卧起坐" then toolName = "Situps"
                            elseif workType == "俯卧撑" then toolName = "Pushups"
                            end
                            if toolName ~= "" and backpack:FindFirstChild(toolName) then
                                char.Humanoid:EquipTool(backpack[toolName])
                            end
                        end)
                        task.wait()
                    end
                end)
            end
        end
    })
    Tab:Input({
        Title = "自定义重生次数",
        Placeholder = "输入数值",
        Default = "",
        Callback = function(val) rebirthTarget = tonumber(val) or 0 end
    })
    Tab:Toggle({
        Title = "自动重生",
        Default = false,
        Callback = function(state)
            if rebirthMainThread then
                task.cancel(rebirthMainThread)
                rebirthMainThread = nil
            end
            autorebirth = state
            if state then
                rebirthMainThread = task.spawn(function()
                    local player = Players.LocalPlayer
                    while autorebirth do
                        pcall(function()
                            local rebirthRemote = ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("rebirthRemote")
                            if rebirthRemote then
                                rebirthRemote:InvokeServer("rebirthRequest")
                                repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            end
                        end)
                        if rebirthTarget > 0 and player.leaderstats.Rebirths.Value >= rebirthTarget then
                            autorebirth = false
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
    Tab:Input({
        Title = "自定义大小数值",
        Placeholder = "1",
        Value = "1",
        Callback = function(val)
            local num = tonumber(val)
            if num then
                customSizeValue = num
            end
        end
    })
    Tab:Toggle({
        Title = "锁定自定义大小",
        Default = false,
        Callback = function(state)
            customSizeEnabled = state
            if state then
                applyCustomSize()
            end
        end
    })
    Tab:Input({
        Title = "自定义传送坐标",
        Placeholder = "例如：10, 20, 30",
        Value = "",
        Callback = function(val)
            customTeleportTarget = parseTargetPosition(val)
        end
    })
    Tab:Toggle({
        Title = "锁定传送位置",
        Default = false,
        Callback = function(state)
            customTeleportEnabled = state
        end
    })
    Tab:Button({
        Title = "复制当前位置",
        Callback = function()
            pcall(function()
                local char = Players.LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    setclipboard("game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new("
                        .. tostring(root.CFrame) .. ")")
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "猫脚本",
                        Text = "当前位置已复制到剪贴板，请粘贴到上方输入框",
                        Duration = 3
                    })
                end
            end)
        end
    })
end
Tabs.Hall = Tabs.PlayerSection:Tab({ Title = "大厅", Icon = "monitor" })
do
    local Tab = Tabs.Hall
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local deadliftFuncs = {
        { name = "①硬拉1500(右上角)", cf = CFrame.new(135.838379, 3.30565023, 97.185379, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①硬拉2500(右上角)", cf = CFrame.new(138.122299, 3.30565, 66.0853577, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①硬拉4000(右上角)", cf = CFrame.new(141.232071, 3.30565, 26.4854164, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②硬拉1500(右上角)", cf = CFrame.new(182.817261, 3.30565023, 97.1852036, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "②硬拉2500(右上角)", cf = CFrame.new(180.733276, 3.30565023, 66.0851135, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "②硬拉4000(右上角)", cf = CFrame.new(177.823456, 3.30565, 26.4850807, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
    }
    for idx, item in ipairs(deadliftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchPressFuncs = {
        { name = "①仰卧推举(右下角)", cf = CFrame.new(111.400826, 6.71424437, 352.656433, 0.998808622, 4.62216354e-09, -0.0487988107, -4.46773907e-09, 1, 3.27358518e-09, 0.0487988107, -3.0516647e-09, 0.998808622) },
        { name = "①仰卧推举10(前方)", cf = CFrame.new(4.74278641, 6.71424484, 46.4786491, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "①仰卧推举150(前方)", cf = CFrame.new(-15.1012564, 7.55120468, 45.4072647, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②仰卧推举10(前方)", cf = CFrame.new(4.74273682, 6.71424484, -0.592803359, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②仰卧推举150(前方)", cf = CFrame.new(-15.1014681, 7.55120468, -0.921384215, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local squatFuncs = {
        { name = "①深蹲架1000(右上角)", cf = CFrame.new(234.779938, 3.30564976, 97.0440903, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①深蹲架1000(前方)", cf = CFrame.new(-42.9242592, 3.30565047, 39.5736923, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "①深蹲架1000(左上角)", cf = CFrame.new(-235.653976, 3.30564952, 136.869431, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "①深蹲架1500(右上角)", cf = CFrame.new(231.255844, 3.30564952, 62.9939117, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①深蹲架1500(左上角)", cf = CFrame.new(-231.32988, 3.30564976, 66.7550735, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "②深蹲架1000(前方)", cf = CFrame.new(-41.9757195, 3.30564976, 3.73980021, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②深蹲架1000(左上角)", cf = CFrame.new(-235.653976, 3.30564904, 103.995522, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "②深蹲架1500(右上角)", cf = CFrame.new(231.255905, 3.30564976, 24.3584881, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②深蹲架1500(左上角)", cf = CFrame.new(-231.32988, 3.30564952, 23.8196106, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "③深蹲架1000(前方)", cf = CFrame.new(-73.3981934, 3.30565047, 39.5736923, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "④深蹲架1000(前方)", cf = CFrame.new(-72.449646, 3.30564976, 3.73979521, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local pullupFuncs = {
        { name = "①引体向上1000(左上角)", cf = CFrame.new(-185.000092, 3.30564976, 137.263672, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①引体向上2500(左上角)", cf = CFrame.new(-185.000092, 3.30564976, 67.5385132, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②引体向上1000(左上角)", cf = CFrame.new(-185.000092, 3.30564952, 104.06366, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②引体向上2500(左上角)", cf = CFrame.new(-185.000092, 3.30564976, 24.0887852, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
    }
    for idx, item in ipairs(pullupFuncs) do
        createMachineToggle(item.name, item.cf, "Legends Pullup")
    end
    local treadmillFuncs = {
        { name = "①跑步机0(雕像下)", cf = CFrame.new(-27.8830738, 4.41672897, 261.175507, 0.564802229, -5.11192644e-09, -0.825226307, 3.02890241e-10, 1, -5.98727068e-09, 0.825226307, 3.1316707e-09, 0.564802229) },
        { name = "①跑步机10(右边)", cf = CFrame.new(238.671112, 5.40315914, 387.713165, -0.0160072874, -2.90710176e-08, -0.99987185, -3.3434191e-09, 1, -2.90212157e-08, 0.99987185, 2.87843993e-09, -0.0160072874) },
        { name = "①跑步机20(右边)", cf = CFrame.new(239.613434, 5.04044819, 358.220367, 0.00401047058, -5.37945333e-08, -0.999991953, -4.41010144e-08, 1, -5.39718314e-08, 0.999991953, 4.43171118e-08, 0.00401047058) },
        { name = "①跑步机100(右边)", cf = CFrame.new(236.496414, 5.6660099, 324.961945, 0.0235777963, 9.22312338e-10, -0.999722004, -8.43754009e-08, 1, -1.06737041e-09, 0.999722004, 8.43771133e-08, 0.0235777963) },
        { name = "①跑步机100(左边)", cf = CFrame.new(-136.306549, 5.6660099, -115.52002, 0.999168098, 2.05816045e-10, 0.0407816805, -2.54893606e-10, 1, 1.19822197e-09, -0.0407816805, -1.20762012e-09, 0.999168098) },
        { name = "①跑步机250(右边)", cf = CFrame.new(233.572845, 6.50978899, 279.890015, 0.0105351051, 4.99802155e-08, -0.999944508, 1.00854407e-07, 1, 5.10455607e-08, 0.999944508, -1.01386583e-07, 0.0105351051) },
        { name = "①跑步机250(左边)", cf = CFrame.new(-176.619217, 6.50978851, -110.555016, 0.992729127, -1.03382369e-08, 0.120369554, 1.06406022e-08, 1, -1.86923632e-09, -0.120369554, 3.13644999e-09, 0.992729127) },
        { name = "①跑步机600(右边)", cf = CFrame.new(230.512817, 7.79000807, 220.043625, 0.0873519629, 5.28795452e-09, -0.996177495, -1.2905895e-08, 1, 4.17656398e-09, 0.996177495, 1.24917312e-08, 0.0873519629) },
        { name = "①跑步机600(左边)", cf = CFrame.new(-229.857269, 7.79000807, -106.370033, 0.997136414, -4.94225176e-08, 0.0756242126, 4.83853846e-08, 1, 1.55464797e-08, -0.0756242126, -1.18428547e-08, 0.997136414) },
        { name = "①跑步机1000(右边右上角)", cf = CFrame.new(220.189423, 8.9247427, -117.170845, -0.013011341, -1.46350143e-09, -0.999915361, 3.34266694e-08, 1, -1.89858795e-09, 0.999915361, -3.34485399e-08, -0.013011341) },
        { name = "②跑步机0(雕像下)", cf = CFrame.new(-35.6689377, 4.98409796, 252.130386, 0.408518851, 7.43816209e-09, -0.912749887, -5.12923428e-08, 1, -1.48077008e-08, 0.912749887, 5.28663051e-08, 0.408518851) },
        { name = "②跑步机10(右边)", cf = CFrame.new(239.640167, 5.04044819, 372.711761, 0.029969966, -1.28647903e-09, -0.999550819, 1.28739501e-07, 1, 2.57299515e-09, 0.999550819, -1.28758785e-07, 0.029969966) },
        { name = "②跑步机20(右边)", cf = CFrame.new(239.345917, 5.04044819, 343.10083, 0.0597619638, 2.24676153e-08, -0.998212636, 7.73517694e-09, 1, 2.29709407e-08, 0.998212636, -9.09413966e-09, 0.0597619638) },
        { name = "②跑步机100(右边)", cf = CFrame.new(236.872421, 5.6660099, 304.633728, 0.0480287559, 2.44919907e-09, -0.998845935, 1.65263216e-08, 1, 3.24668448e-09, 0.998845935, -1.66631846e-08, 0.0480287559) },
        { name = "②跑步机100(左边)", cf = CFrame.new(-154.383545, 5.6660099, -116.297073, 0.997724295, 7.15217183e-08, 0.0674260035, -7.50726841e-08, 1, 5.01308079e-08, -0.0674260035, -5.50785764e-08, 0.997724295) },
        { name = "②跑步机250(右边)", cf = CFrame.new(234.890656, 6.50978899, 252.083389, 0.0101178577, -2.29435333e-08, -0.9999488, -8.55895763e-08, 1, -2.38107347e-08, 0.9999488, 8.58261089e-08, 0.0101178577) },
        { name = "②跑步机250(左边)", cf = CFrame.new(-201.69278, 6.50978851, -110.268921, 0.997821212, 8.88301059e-08, 0.0659763142, -8.40411047e-08, 1, -7.53620668e-08, -0.0659763142, 6.96531401e-08, 0.997821212) },
        { name = "②跑步机600(右边右上角)", cf = CFrame.new(225.811386, 7.79000807, -90.2171707, -0.00239520147, 6.83120192e-08, -0.999997139, -6.62442972e-08, 1, 6.84708894e-08, 0.999997139, 6.64081057e-08, -0.00239520147) },
        { name = "③跑步机0(雕像下)", cf = CFrame.new(-42.1799202, 5.69912529, 237.991882, -0.0540122949, -8.45547277e-08, -0.998540282, -2.62576254e-08, 1, -8.32580227e-08, 0.998540282, 2.17223395e-08, -0.0540122949) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
    local situpRightBottomFuncs = {
        { name = "①仰卧起坐150(右下角)", cf = CFrame.new(74.7987747, 7.55120564, 350.807373, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②仰卧起坐10(右下角)", cf = CFrame.new(94.6428375, 6.71424484, 351.878723, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②仰卧起坐150(右下角)", cf = CFrame.new(74.7985382, 7.55120564, 304.478668, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "③仰卧起坐10(右下角)", cf = CFrame.new(111.642921, 6.71424484, 304.80722, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "④仰卧起坐10(右下角)", cf = CFrame.new(94.6427307, 6.71424484, 304.80722, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(situpRightBottomFuncs) do
        createMachineToggle(item.name, item.cf, "Situps")
    end
    local situpLeftBottomFuncs = {
        { name = "①仰卧起坐10(左下角)", cf = CFrame.new(-195.914307, 6.71424484, 383.535706, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①仰卧起坐150(左下角)", cf = CFrame.new(-195.585709, 7.55120468, 346.691345, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①仰卧起坐400(左下角)", cf = CFrame.new(-194.551514, 8.82657242, 300.776245, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②仰卧起坐10(左下角)", cf = CFrame.new(-195.914276, 6.71424484, 366.535553, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②仰卧起坐150(左下角)", cf = CFrame.new(-195.585663, 7.55120564, 325.379761, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②仰卧起坐400(左下角)", cf = CFrame.new(-194.551544, 8.82657433, 272.894531, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "③仰卧起坐10(左下角)", cf = CFrame.new(-242.985718, 6.71424484, 383.535675, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "③仰卧起坐150(左下角)", cf = CFrame.new(-241.914322, 7.55120659, 346.691559, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "③仰卧起坐400(左下角)", cf = CFrame.new(-239.748322, 8.82657337, 300.776398, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "④仰卧起坐10(左下角)", cf = CFrame.new(-242.985718, 6.71424484, 366.535614, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "④仰卧起坐150(左下角)", cf = CFrame.new(-241.914322, 7.55120468, 325.379883, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "④仰卧起坐400(左下角)", cf = CFrame.new(-239.748322, 8.82657337, 272.894623, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
    }
    for idx, item in ipairs(situpLeftBottomFuncs) do
        createMachineToggle(item.name, item.cf, "Situps")
    end
end
Tabs.Beach = Tabs.PlayerSection:Tab({ Title = "沙滩", Icon = "waves" })
do
    local Tab = Tabs.Beach
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local deadliftFuncs = {
        { name = "①硬拉8000", cf = CFrame.new(-68.4866943, 3.31417942, -494.214325, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②硬拉8000", cf = CFrame.new(67.0421143, 3.31417942, -494.215057, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
    }
    for idx, item in ipairs(deadliftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchPressFuncs = {
        { name = "①仰卧推举3000", cf = CFrame.new(196.73172, 12.6128159, -317.205231, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "①仰卧推举4000", cf = CFrame.new(197.98735, 15.4425354, -374.905212, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "①仰卧推举10000", cf = CFrame.new(473.462585, 18.7106667, -257.305542, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①仰卧推举15000", cf = CFrame.new(466.041656, 22.1382141, -328.803345, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "①巨石抛掷3000", cf = CFrame.new(-86.1599579, 3.31418014, -293.360443, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②巨石抛掷3000", cf = CFrame.new(-86.1599426, 3.31417918, -324.26059, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①巨石抛掷7500", cf = CFrame.new(-75.0598831, 3.31417894, -364.385376, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "②巨石抛掷7500", cf = CFrame.new(-75.0598679, 3.31417942, -408.035553, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①巨石抛掷15000", cf = CFrame.new(55.6397324, 3.31417942, -281.327942, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "②巨石抛掷15000", cf = CFrame.new(55.6396255, 3.31417942, -343.442596, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "①巨石抛掷25000", cf = CFrame.new(36.9296036, 3.31417942, -411.535248, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local squatFuncs = {
        { name = "①深蹲架4000", cf = CFrame.new(-195.254028, 3.31417942, -354.65448, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
        { name = "①深蹲架10000", cf = CFrame.new(-203.108704, 3.3141799, -422.33844, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local treadmillFuncs = {
        { name = "①跑步机1000", cf = CFrame.new(-413.187378, 12.8381319, -263.237732, -0.0668151081, 8.37962375e-08, 0.997765362, -3.2232748e-08, 1, -8.61423644e-08, -0.997765362, -3.79163332e-08, -0.0668151081) },
        { name = "①跑步机1500", cf = CFrame.new(-419.057526, 15.5876875, -328.426819, -0.104439825, -7.26821991e-10, 0.994531214, -7.96818611e-08, 1, -7.63690267e-09, -0.994531214, -8.00436979e-08, -0.104439825) },
        { name = "①跑步机2000", cf = CFrame.new(-422.635712, 18.7445793, -404.703339, -0.0219939984, -5.53460815e-08, 0.999758124, 7.62561143e-08, 1, 5.7037056e-08, -0.999758124, 7.7492146e-08, -0.0219939984) },
        { name = "①跑步机3000", cf = CFrame.new(-391.424866, 23.0493374, -498.073395, -0.00305148936, 5.73683456e-09, 0.999995351, 4.13070893e-08, 1, -5.6108127e-09, -0.999995351, 4.12897769e-08, -0.00305148936) },
        { name = "②跑步机2000", cf = CFrame.new(432.956726, 18.7445793, -405.844025, 0.036689911, 7.83524854e-08, -0.999326706, -2.93913676e-08, 1, 7.73261846e-08, 0.999326706, 2.65344884e-08, 0.036689911) },
        { name = "③跑步机2000", cf = CFrame.new(425.59726, 18.7445793, -497.523895, 0.0272405371, 1.28495374e-08, -0.999628901, 9.92943239e-09, 1, 1.31248914e-08, 0.999628901, -1.02832765e-08, 0.0272405371) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Frost = Tabs.PlayerSection:Tab({ Title = "冰霜健身房", Icon = "snowflake" })
do
    local Tab = Tabs.Frost
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local benchPressFuncs = {
        { name = "冰霜推举5000", cf = CFrame.new(-2917.47168, 3.31418037, -209.563873, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local practiceBenchFuncs = {
        { name = "①冰霜练习凳1000", cf = CFrame.new(-2605.58521, 10.4403896, -176.204895, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②冰霜练习凳1000", cf = CFrame.new(-2641.11401, 10.4403906, -176.204895, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "①冰霜练习凳3000", cf = CFrame.new(-2695.14404, 14.0672112, -181.814285, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②冰霜练习凳3000", cf = CFrame.new(-2748.75537, 14.0672121, -181.814285, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "冰霜练习凳7500", cf = CFrame.new(-3022.5498, 29.5708885, -197.53894, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
        { name = "冰霜练习凳15000", cf = CFrame.new(-3008.67017, 39.2158623, -337.746918, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
    }
    for idx, item in ipairs(practiceBenchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local squatFuncs = {
        { name = "①冰霜深蹲4000", cf = CFrame.new(-2629.13818, 3.36860609, -609.827454, -0.995664716, -2.67296816e-08, -0.0930150598, -1.90042453e-08, 1, -8.39415222e-08, 0.0930150598, -8.18099295e-08, -0.995664716) },
        { name = "②冰霜深蹲10000", cf = CFrame.new(-2720.05127, 3.31417942, -591.259155, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local treadmillFuncs = {
        { name = "①冰霜健身房跑步机2000", cf = CFrame.new(-3005.37866, 14.3221855, -464.697876, -0.015773816, -1.38508964e-08, 0.999875605, -5.13225586e-08, 1, 1.30429667e-08, -0.999875605, -5.11104332e-08, -0.015773816) },
        { name = "②冰霜健身房跑步机3000", cf = CFrame.new(-2953.44556, 29.2772789, -583.006287, -0.0362823829, -9.97339598e-08, 0.999341607, -1.85937332e-09, 1, 9.97321621e-08, -0.999341607, 1.76037129e-09, -0.0362823829) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Myth = Tabs.PlayerSection:Tab({ Title = "神话健身房", Icon = "zap" })
do
    local Tab = Tabs.Myth
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local benchPressFuncs = {
        { name = "①神话练习凳15000", cf = CFrame.new(2369.70044, 39.2158623, 1243.02173, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "①神话抛掷10000", cf = CFrame.new(2486.01733, 3.67689276, 1237.89331, 0.883595645, -2.06135038e-08, -0.468250751, -3.3286871e-09, 1, -5.03036404e-08, 0.468250751, 4.60067362e-08, 0.883595645) },
        { name = "②神话抛掷18000", cf = CFrame.new(2577.24048, 3.31417942, 1223.67383, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "③神话抛掷25000", cf = CFrame.new(2667.74072, 3.31417966, 1203.33374, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local pullupFuncs = {
        { name = "①神话引体向上4000", cf = CFrame.new(2260.698, 3.31417942, 843.888916, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②神话引体向上4000", cf = CFrame.new(2315.82104, 5.81071281, 847.153076, 0.993555248, 6.99809632e-08, 0.113349125, -7.05298859e-08, 1, 8.32554692e-10, -0.113349125, -8.82168916e-09, 0.993555248) },
        { name = "①神话引体向上8000", cf = CFrame.new(2395.27368, 3.31417918, 848.289124, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②神话引体向上8000", cf = CFrame.new(2487.12085, 3.3141799, 848.289124, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(pullupFuncs) do
        createMachineToggle(item.name, item.cf, "Legends Pullup")
    end
    local treadmillFuncs = {
        { name = "①神话健身房跑步机2000", cf = CFrame.new(2571.23706, 15.6896839, 898.650391, 0.999968231, 2.23868635e-09, -0.00797206629, -1.73198844e-09, 1, 6.35660768e-08, 0.00797206629, -6.3550246e-08, 0.999968231) },
        { name = "②神话健身房跑步机3000", cf = CFrame.new(2661.05908, 21.2468414, 919.779785, 0.984700143, -4.61772558e-08, 0.174257502, 4.95759522e-08, 1, -1.51510751e-08, -0.174257502, 2.35582451e-08, 0.984700143) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Eternal = Tabs.PlayerSection:Tab({ Title = "永恒健身房", Icon = "infinity" })
do
    local Tab = Tabs.Eternal
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local benchPressFuncs = {
        { name = "永恒练习凳15000", cf = CFrame.new(-7173.3418, 45.3941154, -1105.02759, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local treadmillFuncs = {
        { name = "永恒健身房跑步机3500", cf = CFrame.new(-7077.79102, 29.6702118, -1457.59961, -0.0322036594, -3.31122768e-10, 0.99948132, -6.44344267e-09, 1, 1.23684493e-10, -0.99948132, -6.43611742e-09, -0.0322036594) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Legend = Tabs.PlayerSection:Tab({ Title = "传奇健身房", Icon = "crown" })
do
    local Tab = Tabs.Legend
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local benchPressFuncs = {
        { name = "传奇推举", cf = CFrame.new(4532.21777, 987.495056, -4002.71216, 0.642774045, 0, -0.766055822, 0, 1, 0, 0.766055822, 0, 0.642774045) },
    }
    for idx, item in ipairs(benchPressFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "传奇健身房投掷石", cf = CFrame.new(4189.96143, 987.829773, -3903.0166, 0.422592968, 0, 0.906319559, 0, 1, 0, -0.906319559, 0, 0.422592968) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local squatFuncs = {
        { name = "传奇健身房深蹲架", cf = CFrame.new(4443.04443, 987.521484, -4061.12988, 0.83309716, 3.33018835e-09, 0.553126693, -2.87759438e-09, 1, -1.68654424e-09, -0.553126693, -1.86619012e-10, 0.83309716) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local pullupFuncs = {
        { name = "①传奇引体向上", cf = CFrame.new(4510.20752, 987.463623, -3636.71753, -0.766061425, 0, -0.64276737, 0, 1, 0, 0.64276737, 0, -0.766061425) },
        { name = "②传奇引体向上", cf = CFrame.new(4304.02393, 987.486267, -4122.27734, -0.984812498, 0, -0.173621133, 0, 1, 0, 0.173621133, 0, -0.984812498) },
    }
    for idx, item in ipairs(pullupFuncs) do
        createMachineToggle(item.name, item.cf, "Legends Pullup")
    end
    local treadmillFuncs = {
        { name = "传奇健身房跑步机3000", cf = CFrame.new(4370.82812, 999.358704, -3621.42773, -0.960604727, -8.41949266e-09, -0.27791819, -6.12478646e-09, 1, -9.12496567e-09, 0.27791819, -7.06329528e-09, -0.960604727) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.King = Tabs.PlayerSection:Tab({ Title = "肌肉之王健身房", Icon = "star" })
do
    local Tab = Tabs.King
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local liftFuncs = {
        { name = "力量之王举重", cf = CFrame.new(-8772.9707, 13.1642103, -5663.5625, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(liftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchFuncs = {
        { name = "力量之王长凳", cf = CFrame.new(-8590.23535, 46.0167389, -6044.59521, -0.642763495, 0, 0.766064644, 0, 1, 0, -0.766064644, 0, -0.642763495) },
    }
    for idx, item in ipairs(benchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "力量之王投掷石", cf = CFrame.new(-8935.4384765625, 13.855730056762695, -5693.66748046875) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local squatFuncs = {
        { name = "力量之王深蹲架", cf = CFrame.new(-8757.37012, 13.2186356, -6051.24365, -0.902269304, 1.63610299e-08, -0.431172907, 1.71076486e-08, 1, 2.14606288e-09, 0.431172907, -5.44002754e-09, -0.902269304) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
end
Tabs.Jungle = Tabs.PlayerSection:Tab({ Title = "丛林健身房", Icon = "leaf" })
do
    local Tab = Tabs.Jungle
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local benchFuncs = {
        { name = "①丛林长凳25000", cf = CFrame.new(-8629.88184, 35.6957436, 1897.96667, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②丛林长凳50000", cf = CFrame.new(-8429.88184, 45.659626, 1902.96667, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "③丛林长凳100000", cf = CFrame.new(-8176.72168, 59.6090698, 1918.18982, -0.999944925, 1.00847783e-08, -0.0104927532, 9.91424365e-09, 1, 1.63046394e-08, 0.0104927532, 1.61997136e-08, -0.999944925) },
    }
    for idx, item in ipairs(benchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "丛林投掷石", cf = CFrame.new(-8620.99, 89.81, 2673.54, -0.902269304, 1.63610299e-08, -0.431172907, 1.71076486e-08, 1, 2.14606288e-09, 0.431172907, -5.44002754e-09, -0.902269304) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local squatFuncs = {
        { name = "丛林蹲50000", cf = CFrame.new(-8582.27734, 2.74318409, 2888.69653, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local treadmillFuncs = {
        { name = "丛林健身房跑步机20000", cf = CFrame.new(-8138.67919921875, 28.270538330078125, 2833.511474609375, -0.960604727, -8.41949266e-09, -0.27791819, -6.12478646e-09, 1, -9.12496567e-09, 0.27791819, -7.06329528e-09, -0.960604727) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Industrial = Tabs.PlayerSection:Tab({ Title = "工业健身房", Icon = "factory" })
do
    local Tab = Tabs.Industrial
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local liftFuncs = {
        { name = "工业酒吧升降机250千", cf = CFrame.new(-5492.70508, 60.4064407, 4643.64209, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(liftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchFuncs = {
        { name = "①工业长椅62.5千", cf = CFrame.new(-5469.71973, 93.3590622, 4452.34717, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "②工业长椅125千", cf = CFrame.new(-5269.71973, 103.322983, 4457.34717, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
        { name = "③工业长椅250千", cf = CFrame.new(-5014.71973, 117.272316, 4467.34717, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(benchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local throwFuncs = {
        { name = "工业巨石187.5千", cf = CFrame.new(-5456.42969, 60.4064407, 5231.53516, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local squatFuncs = {
        { name = "①工业深蹲125千", cf = CFrame.new(-5422.11523, 60.4064407, 5443.07715, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
        { name = "②工业深蹲312.5千", cf = CFrame.new(-5217.11523, 60.4064407, 5418.07715, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local treadmillFuncs = {
        { name = "工业跑步机50千", cf = CFrame.new(-4972.01416, 81.2528229, 5408.52197, -0.999095559, 2.14437339e-08, -0.0425219648, 2.28628174e-08, 1, -3.28866783e-08, 0.0425219648, -3.38291031e-08, -0.999095559) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.ZeroDegrees = Tabs.PlayerSection:Tab({ Title = "Zero Degrees健身房", Icon = "snowflake" })
do
    local Tab = Tabs.ZeroDegrees
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local liftFuncs = {
        { name = "Zero Degrees Bar Lift 1(100千)", cf = CFrame.new(-5374.86719, 46.8623886, 10321.7617, -9.46027002e-13, 4.17792769e-08, 1, -1.47090055e-12, 1, -4.17792769e-08, -1, -1.47090066e-12, -9.46027002e-13) },
    }
    for idx, item in ipairs(liftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchFuncs = {
        { name = "①Zero Degrees Bench 3(25千)", cf = CFrame.new(-5355.4917, 79.8146439, 10132.5752, 0.125147, 2.36685e-08, -0.992138207, -5.17586969e-08, 1, 1.73272792e-08, 0.992138207, 4.91833241e-08, 0.125147) },
        { name = "②Zero Degrees Bench 2(50千)", cf = CFrame.new(-5156.27051, 89.7790527, 10136.9902, 0.189251676, -6.90230948e-08, -0.981928587, -2.74308505e-08, 1, -7.55802674e-08, 0.981928587, 4.1238831e-08, 0.189251676) },
        { name = "③Zero Degrees Bench 1(100千)", cf = CFrame.new(-4901.84521, 103.727707, 10146.2598, -0.624886155, -8.30325817e-08, -0.780715883, -1.88251814e-08, 1, -9.12867151e-08, 0.780715883, -4.23466844e-08, -0.624886155) },
    }
    for idx, item in ipairs(benchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local squatFuncs = {
        { name = "①Zero Degrees Squat 1(50千)", cf = CFrame.new(-5304.27734, 46.8623886, 11121.1963, 1, -2.82783486e-09, 4.41309478e-09, 2.82783463e-09, 1, 6.50564402e-09, -4.41309478e-09, -6.50564402e-09, 1) },
        { name = "②Zero Degrees Squat 2(125千)", cf = CFrame.new(-5099.27734, 46.8623886, 11096.1963, 1, -7.22851201e-09, 1.86739202e-09, 7.22851201e-09, 1, -5.82249271e-09, -1.86739202e-09, 5.82249271e-09, 1) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local throwFuncs = {
        { name = "Zero Degrees Boulder 1(75千)", cf = CFrame.new(-5338.5918, 46.8623886, 10909.6543, -0.208028123, 0, 0.97812283, 0, 1, 0, -0.97812283, 0, -0.208028123) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local treadmillFuncs = {
        { name = "Zero Degrees Treadmill(20千)", cf = CFrame.new(-4856.16455, 71.6982422, 11097.5498, -0.99957341, -1.27177096e-08, -0.029207157, -1.31515803e-08, 1, 1.46628665e-08, 0.029207157, 1.50407313e-08, -0.99957341) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.AlienGym = Tabs.PlayerSection:Tab({ Title = "Alien Gym健身房", Icon = "atom" })
do
    local Tab = Tabs.AlienGym
    local function createMachineToggle(name, cf, machineName)
        local active = false
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                active = state
                if state then
                    task.spawn(function()
                        while active do
                            pcall(function()
                                local player = Players.LocalPlayer
                                local char = player.Character
                                local root = char and char:FindFirstChild("HumanoidRootPart")
                                if not root then return end
                                local machineInUse = player:FindFirstChild("machineInUse")
                                local isUsing = machineInUse and machineInUse.Value ~= nil
                                if not isUsing then
                                    root.CFrame = cf
                                    task.wait(0.15)
                                    local vim = game:GetService("VirtualInputManager")
                                    vim:SendKeyEvent(true, "E", false, game)
                                    task.wait(0.05)
                                    vim:SendKeyEvent(false, "E", false, game)
                                    task.wait(0.3)
                                else
                                    local seat = machineInUse.Value
                                    if seat and player:FindFirstChild("muscleEvent") then
                                        player.muscleEvent:FireServer("rep", seat)
                                    end
                                end
                            end)
                            task.wait(0.1)
                        end
                    end)
                else
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char then char:WaitForChild("Humanoid").Jump = true end
                    end)
                end
            end
        })
    end
    local function createTreadmillToggle(name, cf)
        local running = false
        local bindName = "Treadmill_" .. name
        Tab:Toggle({
            Title = name,
            Default = false,
            Callback = function(state)
                running = state
                if state then
                    task.spawn(function()
                        local char = Players.LocalPlayer.Character
                        local originalSpeed = 16
                        if char and char:FindFirstChild("Humanoid") then
                            originalSpeed = char.Humanoid.WalkSpeed
                        end
                        while running do
                            pcall(function()
                                char = Players.LocalPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.Humanoid.WalkSpeed = 10
                                    char.HumanoidRootPart.CFrame = cf
                                    RunService:BindToRenderStep(bindName, Enum.RenderPriority.Character.Value + 1, function()
                                        if char and char:FindFirstChild("Humanoid") then
                                            char.Humanoid:Move(Vector3.new(10000, 0, -1), true)
                                        end
                                    end)
                                end
                            end)
                            task.wait()
                        end
                        RunService:UnbindFromRenderStep(bindName)
                        pcall(function()
                            char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = originalSpeed
                            end
                        end)
                    end)
                else
                    RunService:UnbindFromRenderStep(bindName)
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid.WalkSpeed = 16
                        end
                    end)
                end
            end
        })
    end
    local liftFuncs = {
        { name = "①Alien Bar Lift 1(250千)", cf = CFrame.new(-2216.64966, 52.8168793, -11220.4893, 0, 1.08151323e-34, 1, 1.05647555e-36, 1, -1.08151323e-34, -1, 1.05647555e-36, -0) },
        { name = "②Alien Bar Lift 2(250千)", cf = CFrame.new(-2154.71094, 52.8190193, -11332.9111, 0.819254875, -1.80857954e-12, 0.573429585, 5.89915486e-13, 1, 2.31116168e-12, -0.573429585, -1.55515542e-12, 0.819254875) },
    }
    for idx, item in ipairs(liftFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local benchFuncs = {
        { name = "①Alien Bench 1(62.5千)", cf = CFrame.new(-2216.94458, 84.1581802, -10754.709, 0.92403996, 7.25476923e-08, -0.382295877, -8.12139191e-08, 1, -6.53215571e-09, 0.382295877, 3.70837192e-08, 0.92403996) },
        { name = "②Alien Bench 2(125千)", cf = CFrame.new(-2167.18823, 84.1529388, -10644.1904, 0.895121992, -5.35230393e-09, -0.445821285, -3.76645826e-09, 1, -1.95678052e-08, 0.445821285, 1.919474e-08, 0.895121992) },
        { name = "③Alien Bench 3(250千)", cf = CFrame.new(-2046.31384, 84.1483078, -10616.2412, 0.48175174, -6.34214956e-08, -0.876307726, 9.53984127e-08, 1, -1.99280912e-08, 0.876307726, -7.3997974e-08, 0.48175174) },
    }
    for idx, item in ipairs(benchFuncs) do
        createMachineToggle(item.name, item.cf, "Bench Press")
    end
    local squatFuncs = {
        { name = "①Alien Squat 1(125千)", cf = CFrame.new(-1603.33679, 52.8019028, -11326.9961, -0.998595417, 0, -0.0529830977, 0, 1, 0, 0.0529830977, 0, -0.998595417) },
        { name = "②Alien Squat 2(125千)", cf = CFrame.new(-1511.64111, 52.7975121, -11282.3213, -0.68245542, -8.24743935e-08, 0.730927229, -8.24999944e-08, 1, 3.58063339e-08, -0.730927229, -3.58652628e-08, -0.68245542) },
        { name = "③Alien Squat 3(312.5千)", cf = CFrame.new(-1490.97559, 52.7935524, -11188.7051, 0.374024808, 1.48040264e-08, 0.927418709, 1.48072532e-08, 1, -2.19343281e-08, -0.927418709, 2.19365059e-08, 0.374024808) },
    }
    for idx, item in ipairs(squatFuncs) do
        createMachineToggle(item.name, item.cf, "Squat Rack")
    end
    local throwFuncs = {
        { name = "Alien Boulder(187.5千)", cf = CFrame.new(-2061.31763, 52.8154984, -11314.2607, 0.86607182, 0, -0.499919623, 0, 1, 0, 0.499919623, 0, 0.86607182) },
    }
    for idx, item in ipairs(throwFuncs) do
        createMachineToggle(item.name, item.cf, "Deadlift")
    end
    local treadmillFuncs = {
        { name = "①Alien Treadmill 1(50千)", cf = CFrame.new(-1601.46338, 64.8113708, -10615.1094, -0.988528371, 9.56467261e-09, -0.151035443, 1.19025749e-08, 1, -1.45751242e-08, 0.151035443, -1.62056342e-08, -0.988528371) },
        { name = "②Alien Treadmill 2(50千)", cf = CFrame.new(-1504.79492, 64.8083801, -10650.293, -0.846906245, 9.68903446e-09, -0.531742275, 1.30727233e-08, 1, -2.59963584e-09, 0.531742275, -9.15296727e-09, -0.846906245) },
        { name = "③Alien Treadmill 3(50千)", cf = CFrame.new(-1459.31921, 64.8118591, -10757.8213, -0.0198461544, 2.89750474e-10, -0.999803066, 6.76230405e-10, 1, 2.7638436e-10, 0.999803066, -6.70612066e-10, -0.0198461544) },
    }
    for idx, item in ipairs(treadmillFuncs) do
        createTreadmillToggle(item.name, item.cf)
    end
end
Tabs.Boss = Tabs.PlayerSection:Tab({ Title = "头目专属", Icon = "crown" })
do
    local Tab = Tabs.Boss
    local statusPara_strength = Tab:Paragraph({
        Title = "力量 & 重生",
        Desc = "计算中...",
    })
    local autoRebirthCallback
    Tab:Toggle({
        Title = "自动重生",
        Default = false,
        Callback = function(state)
            autoRebirthCallback(state)
        end
    })
    local rebirthEstimatePara = Tab:Paragraph({
        Title = "重生",
        Desc = "自动重生未开启",
    })
    local autoRebirthEnabled = false
    local autoRebirthThread = nil
    local rebirthStats = { count = 0, startTime = 0 }
    local function calculateRequiredStrength()
        local player = Players.LocalPlayer
        local rebirths = player.leaderstats.Rebirths.Value
        local baseRequired = 10000 + 5000 * rebirths
        return math.max(1, math.floor(baseRequired * 0.5))
    end
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local player = Players.LocalPlayer
                local requiredStrength = calculateRequiredStrength()
                local currentStrength = player.leaderstats.Strength.Value
                statusPara_strength:SetDesc("当前力量: " .. math.floor(currentStrength) .. " | 重生需要: " .. math.floor(requiredStrength))
            end)
        end
    end)
    autoRebirthCallback = function(state)
        autoRebirthEnabled = state
        if autoRebirthThread then
            task.cancel(autoRebirthThread)
            autoRebirthThread = nil
        end
        if state then
            rebirthStats.count = 0
            rebirthStats.startTime = 0
            autoRebirthThread = task.spawn(function()
                while autoRebirthEnabled do
                    local ok, err = pcall(function()
                        local player = Players.LocalPlayer
                        local leaderstats = player:FindFirstChild("leaderstats")
                        if not leaderstats then return end
                        local strengthStat = leaderstats:FindFirstChild("Strength")
                        local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                        if not strengthStat or not rebirthsStat then return end
                        local required = calculateRequiredStrength()
                        local current = strengthStat.Value
                        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                        if current < required then
                            for i = 1, 15 do
                                player.muscleEvent:FireServer("rep")
                            end
                        else
                            task.wait(1)
                            rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                            rebirthStats.count = rebirthStats.count + 1
                            if rebirthStats.count == 1 then
                                rebirthStats.startTime = os.clock()
                            end
                            task.wait(2)
                        end
                    end)
                    if not ok then
                        print("[自动重生] 错误: " .. tostring(err))
                    end
                    task.wait()
                end
            end)
        end
    end
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                if not autoRebirthEnabled then
                    rebirthEstimatePara:SetDesc("自动重生未开启")
                    return
                end
                local player = Players.LocalPlayer
                local leaderstats = player:FindFirstChild("leaderstats")
                if not leaderstats then return end
                local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                if not rebirthsStat then return end
                local currentRebirths = rebirthsStat.Value
                if rebirthStats.count > 0 and rebirthStats.startTime > 0 then
                    local elapsed = os.clock() - rebirthStats.startTime
                    local avgInterval = elapsed / rebirthStats.count
                    local perDay = math.floor(86400 / avgInterval)
                    rebirthEstimatePara:SetDesc("当前重生: " .. currentRebirths .. "\n今天约 " .. perDay .. " 次")
                else
                    rebirthEstimatePara:SetDesc("当前重生: " .. currentRebirths .. " | 计算中...")
                end
            end)
        end
    end)
    local fastWorkCallback
    Tab:Input({
        Title = "自定义锻炼倍数",
        Placeholder = "500",
        Default = "500",
        Callback = function(v)
            FastTrain.SetRate(v)
        end
    })
    Tab:Toggle({
        Title = "快速锻炼",
        Desc = "开启前自己装备宠物",
        Default = false,
        Callback = function(state)
            fastWorkCallback(state)
        end
    })
    local strengthEstimatePara = Tab:Paragraph({
        Title = "力量",
        Desc = "快速锻炼未开启",
    })
    local fastWorkEnabled = false
    local strengthStats = { startTime = 0, startStrength = 0 }
    fastWorkCallback = function(state)
        fastWorkEnabled = state
        if state then
            local player = Players.LocalPlayer
            strengthStats.startTime = os.clock()
            strengthStats.startStrength = player.leaderstats.Strength.Value
            FastTrain.Start()
        else
            FastTrain.Stop()
        end
    end
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                if not fastWorkEnabled then
                    strengthEstimatePara:SetDesc("快速锻炼未开启")
                    return
                end
                local player = Players.LocalPlayer
                local leaderstats = player:FindFirstChild("leaderstats")
                if not leaderstats then return end
                local strengthStat = leaderstats:FindFirstChild("Strength")
                if not strengthStat then return end
                local currentStrength = strengthStat.Value
                if strengthStats.startTime > 0 then
                    local elapsed = os.clock() - strengthStats.startTime
                    local gained = currentStrength - strengthStats.startStrength
                    if elapsed > 3 and gained > 0 then
                        local perSecond = gained / elapsed
                        local perDay = math.floor(perSecond * 86400)
                        strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. "\n今天约 " .. perDay .. " 力量")
                    else
                        strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. " | 计算中...")
                    end
                else
                    strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. " | 计算中...")
                end
            end)
        end
    end)
    local customSpeedValue = 16
    local autoLockSpeed = false
    Tab:Input({
        Title = "自定义锁定速度",
        Placeholder = "默认16",
        Default = "16",
        Callback = function(val)
            local num = tonumber(val)
            if num then customSpeedValue = num end
        end
    })
    Tab:Toggle({
        Title = "自动锁定自定义速度",
        Default = false,
        Callback = function(state)
            autoLockSpeed = state
            if state then
                task.spawn(function()
                    while autoLockSpeed do
                        pcall(function()
                            local char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = customSpeedValue
                            end
                        end)
                        task.wait()
                    end
                end)
            end
        end
    })
end
Tabs.Bao = Tabs.PlayerSection:Tab({ Title = "包功能", Icon = "package" })
do
    local Tab = Tabs.Bao
    local statusPara_strength = Tab:Paragraph({
        Title = "力量 & 重生",
        Desc = "计算中...",
    })
    local statusPara_pets = Tab:Paragraph({
        Title = "宠物槽位",
        Desc = "计算中...",
    })
    local statusPara_equip = Tab:Paragraph({
        Title = "装备详情",
        Desc = "检测中...",
    })
    local autoRebirthCallback
    Tab:Toggle({
        Title = "自动重生",
        Default = false,
        Callback = function(state)
            autoRebirthCallback(state)
        end
    })
    local rebirthEstimatePara = Tab:Paragraph({
        Title = "重生",
        Desc = "自动重生未开启",
    })
    local TRIBAL_NAME = "Tribal Overlord"
    local SWIFT_NAME = "Swift Samurai"
    local autoRebirthEnabled = false
    local autoRebirthThread = nil
    local rebirthStats = { count = 0, startTime = 0 }
    local statusData = {
        requiredStrength = 0,
        maxSlots = 0,
        tribalCount = 0,
        swiftCount = 0,
        currentStrength = 0,
        equipList = {},
    }
    local function calculateRequiredStrength()
        local player = Players.LocalPlayer
        local rebirths = player.leaderstats.Rebirths.Value
        local baseRequired = 10000 + 5000 * rebirths
        return math.max(1, math.floor(baseRequired * 0.5))
    end
    local function getEquippedMaxSlots()
        local equipped = Players.LocalPlayer:FindFirstChild("equippedPets")
        if not equipped then return 0 end
        local count = 0
        for _, child in ipairs(equipped:GetChildren()) do
            if child:IsA("ValueBase") and child.Name:match("^pet%d+$") then
                count = count + 1
            end
        end
        return count
    end
    local function getEquippedPetName(slotIndex)
        local equipped = Players.LocalPlayer:FindFirstChild("equippedPets")
        if not equipped then return "" end
        local slot = equipped:FindFirstChild("pet" .. slotIndex)
        if slot and slot:IsA("ValueBase") then
            local val = slot.Value
            if val == nil then return "" end
            return tostring(val)
        end
        return ""
    end
    local function countUniquePets(petName)
        local player = Players.LocalPlayer
        local petsFolder = player:FindFirstChild("petsFolder")
        if not petsFolder then return 0 end
        local unique = petsFolder:FindFirstChild("Unique")
        if not unique then return 0 end
        local count = 0
        for _, pet in ipairs(unique:GetChildren()) do
            if pet.Name == petName then
                count = count + 1
            end
        end
        return count
    end
    local function findAllPets(name)
        local result = {}
        local folder = Players.LocalPlayer:FindFirstChild("petsFolder")
        if not folder then return result end
        for _, child in ipairs(folder:GetDescendants()) do
            if child.Name == name then
                table.insert(result, child)
            end
        end
        return result
    end
    local function unequipAllPets()
        pcall(function()
            local player = Players.LocalPlayer
            local eq = player:FindFirstChild("equippedPets")
            if not eq then return end
            local rEvents = ReplicatedStorage:WaitForChild("rEvents")
            for _, slot in ipairs(eq:GetChildren()) do
                if slot:IsA("ValueBase") and slot.Value then
                    local petName = tostring(slot.Value)
                    if petName ~= "nil" and petName ~= "" and petName ~= "Instance" then
                        for _, pet in ipairs(findAllPets(petName)) do
                            rEvents.equipPetEvent:FireServer("unequipPet", pet)
                        end
                    end
                end
            end
        end)
    end
    local function equipAllPets(petName)
        local pets = findAllPets(petName)
        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
        for i, pet in ipairs(pets) do
            rEvents.equipPetEvent:FireServer("equipPet", pet)
            if i % 3 == 0 then task.wait() end
        end
    end
    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local player = Players.LocalPlayer
                statusData.requiredStrength = calculateRequiredStrength()
                statusData.maxSlots = getEquippedMaxSlots()
                statusData.tribalCount = countUniquePets(TRIBAL_NAME)
                statusData.swiftCount = countUniquePets(SWIFT_NAME)
                statusData.currentStrength = player.leaderstats.Strength.Value
                local equipList = {}
                for i = 1, statusData.maxSlots do
                    local slotName = getEquippedPetName(i)
                    equipList[i] = (slotName ~= "" and slotName ~= "nil") and slotName or "空"
                end
                statusData.equipList = equipList
                statusPara_strength:SetDesc(
                    "当前力量: " .. math.floor(statusData.currentStrength) ..
                    " | 重生需要: " .. math.floor(statusData.requiredStrength)
                )
                statusPara_pets:SetDesc(
                    "槽位数量: " .. statusData.maxSlots ..
                    " | Unique中 Tribal: " .. statusData.tribalCount ..
                    " | Swift: " .. statusData.swiftCount
                )
                local equipStr = ""
                for i = 1, statusData.maxSlots do
                    equipStr = equipStr .. "pet" .. i .. "=" .. equipList[i]
                    if i < statusData.maxSlots then equipStr = equipStr .. " | " end
                end
                statusPara_equip:SetDesc(equipStr)
            end)
        end
    end)
    autoRebirthCallback = function(state)
        autoRebirthEnabled = state
        if autoRebirthThread then
            task.cancel(autoRebirthThread)
            autoRebirthThread = nil
        end
        if state then
            rebirthStats.count = 0
            rebirthStats.startTime = 0
            autoRebirthThread = task.spawn(function()
                while autoRebirthEnabled do
                    local ok, err = pcall(function()
                        local player = Players.LocalPlayer
                        local leaderstats = player:FindFirstChild("leaderstats")
                        if not leaderstats then return end
                        local strengthStat = leaderstats:FindFirstChild("Strength")
                        local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                        if not strengthStat or not rebirthsStat then return end
                        local required = calculateRequiredStrength()
                        local current = strengthStat.Value
                        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                        local equippedNames = {}
                        pcall(function()
                            local eq = player:FindFirstChild("equippedPets")
                            if eq then
                                for _, slot in ipairs(eq:GetChildren()) do
                                    if slot:IsA("ValueBase") and slot.Value then
                                        local name = tostring(slot.Value)
                                        if name ~= "nil" and name ~= "" and name ~= "Instance" then
                                            table.insert(equippedNames, name)
                                        end
                                    end
                                end
                            end
                        end)
                        local function allEquipped(targetName)
                            if #equippedNames == 0 then return false end
                            for _, name in ipairs(equippedNames) do
                                if name ~= targetName then return false end
                            end
                            return true
                        end
                        if current < required then
                            if not allEquipped(SWIFT_NAME) then
                                unequipAllPets()
                                task.wait()
                                equipAllPets(SWIFT_NAME)
                            end
                            for i = 1, 15 do
                                player.muscleEvent:FireServer("rep")
                            end
                        else
                            if not allEquipped(TRIBAL_NAME) then
                                unequipAllPets()
                                task.wait()
                                equipAllPets(TRIBAL_NAME)
                            end
                            rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                            rebirthStats.count = rebirthStats.count + 1
                            if rebirthStats.count == 1 then
                                rebirthStats.startTime = os.clock()
                            end
                        end
                    end)
                    if not ok then
                        print("[自动重生] 错误: " .. tostring(err))
                    end
                    task.wait()
                end
            end)
        end
    end
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                if not autoRebirthEnabled then
                    rebirthEstimatePara:SetDesc("自动重生未开启")
                    return
                end
                local player = Players.LocalPlayer
                local leaderstats = player:FindFirstChild("leaderstats")
                if not leaderstats then return end
                local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                if not rebirthsStat then return end
                local currentRebirths = rebirthsStat.Value
                if rebirthStats.count > 0 and rebirthStats.startTime > 0 then
                    local elapsed = os.clock() - rebirthStats.startTime
                    local avgInterval = elapsed / rebirthStats.count
                    local perDay = math.floor(86400 / avgInterval)
                    rebirthEstimatePara:SetDesc("当前重生: " .. currentRebirths .. "\n今天约 " .. perDay .. " 次")
                else
                    rebirthEstimatePara:SetDesc("当前重生: " .. currentRebirths .. " | 计算中...")
                end
            end)
        end
    end)
    local fastWorkCallback
    Tab:Input({
        Title = "自定义锻炼倍数",
        Placeholder = "500",
        Default = "500",
        Callback = function(v)
            FastTrain.SetRate(v)
        end
    })
    Tab:Toggle({
        Title = "快速锻炼",
        Desc = "开启前自己装备宠物",
        Default = false,
        Callback = function(state)
            fastWorkCallback(state)
        end
    })
    local strengthEstimatePara = Tab:Paragraph({
        Title = "力量",
        Desc = "快速锻炼未开启",
    })
    local fastWorkEnabled = false
    local strengthStats = { startTime = 0, startStrength = 0 }
    fastWorkCallback = function(state)
        fastWorkEnabled = state
        if state then
            local player = Players.LocalPlayer
            strengthStats.startTime = os.clock()
            strengthStats.startStrength = player.leaderstats.Strength.Value
            pcall(function()
                local eq = player:FindFirstChild("equippedPets")
                local allSwift = true
                local hasSlot = false
                if eq then
                    for _, slot in ipairs(eq:GetChildren()) do
                        if slot:IsA("ValueBase") and slot.Name:match("^pet%d+$") then
                            hasSlot = true
                            local val = slot.Value
                            if val then
                                local name = tostring(val)
                                if name ~= "nil" and name ~= "" and name ~= "Instance" and name ~= "Swift Samurai" then
                                    allSwift = false
                                    break
                                end
                            else
                                allSwift = false
                                break
                            end
                        end
                    end
                end
                if not hasSlot then allSwift = false end
                if not allSwift then
                    local eq2 = player:FindFirstChild("equippedPets")
                    if eq2 then
                        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                        for _, slot in ipairs(eq2:GetChildren()) do
                            if slot:IsA("ValueBase") and slot.Value then
                                local petName = tostring(slot.Value)
                                if petName ~= "nil" and petName ~= "" and petName ~= "Instance" then
                                    local folder = player:FindFirstChild("petsFolder")
                                    if folder then
                                        for _, child in ipairs(folder:GetDescendants()) do
                                            if child.Name == petName then
                                                rEvents.equipPetEvent:FireServer("unequipPet", child)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait()
                    local folder = player:FindFirstChild("petsFolder")
                    if folder then
                        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                        local pets = {}
                        for _, child in ipairs(folder:GetDescendants()) do
                            if child.Name == "Swift Samurai" then
                                table.insert(pets, child)
                            end
                        end
                        for i, pet in ipairs(pets) do
                            rEvents.equipPetEvent:FireServer("equipPet", pet)
                            if i % 3 == 0 then task.wait() end
                        end
                    end
                end
            end)
            FastTrain.Start()
        else
            FastTrain.Stop()
        end
    end
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                if not fastWorkEnabled then
                    strengthEstimatePara:SetDesc("快速锻炼未开启")
                    return
                end
                local player = Players.LocalPlayer
                local leaderstats = player:FindFirstChild("leaderstats")
                if not leaderstats then return end
                local strengthStat = leaderstats:FindFirstChild("Strength")
                if not strengthStat then return end
                local currentStrength = strengthStat.Value
                if strengthStats.startTime > 0 then
                    local elapsed = os.clock() - strengthStats.startTime
                    local gained = currentStrength - strengthStats.startStrength
                    if elapsed > 3 and gained > 0 then
                        local perSecond = gained / elapsed
                        local perDay = math.floor(perSecond * 86400)
                        strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. "\n今天约 " .. perDay .. " 力量")
                    else
                        strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. " | 计算中...")
                    end
                else
                    strengthEstimatePara:SetDesc("当前力量: " .. math.floor(currentStrength) .. " | 计算中...")
                end
            end)
        end
    end)
    local fpsCallback
    Tab:Button({
        Title = "减少延迟",
        Callback = function()
            fpsCallback()
        end
    })
    fpsCallback = function()
        pcall(function()
            local Lighting = game:GetService("Lighting")
            local Players = game:GetService("Players")
            local localPlayer = Players.LocalPlayer
            settings().Rendering.QualityLevel = 0
            settings().Physics.PhysicsEnvironmentalThrottle = 3
            Lighting.Brightness = 0
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            Lighting.GlobalShadows = false
            Lighting.ClockTime = 0
            Lighting.FogEnd = 30
            Lighting.FogStart = 0
            for _, child in ipairs(Lighting:GetChildren()) do
                pcall(function()
                    child:Destroy()
                end)
            end
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("BasePart") then
                    desc.Transparency = 1
                    desc.CanCollide = false
                    desc.CastShadow = false
                else
                    pcall(function()
                        if desc.Name ~= localPlayer.Name then
                            desc:Destroy()
                        end
                    end)
                end
            end
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= localPlayer and otherPlayer.Character then
                    pcall(function()
                        otherPlayer.Character:Destroy()
                    end)
                end
            end
            if localPlayer.PlayerGui then
                for _, desc in ipairs(localPlayer.PlayerGui:GetDescendants()) do
                    pcall(function()
                        desc:Destroy()
                    end)
                end
            end
            if localPlayer.Character then
                for _, desc in ipairs(localPlayer.Character:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        desc.Transparency = 1
                    end
                end
            end
        end)
    end
    local fpsCallback2
    Tab:Button({
        Title = "减少延迟②",
        Callback = function()
            fpsCallback2()
        end
    })
    fpsCallback2 = function()
        if getgenv().ReduceLag2_Active then
            getgenv().ReduceLag2_Active = false
            return
        end
        getgenv().ReduceLag2_Active = true
        pcall(function()
            game:GetService("Lighting").ClockTime = 0
            for _, d in pairs(game:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
                    d.Enabled = false
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                elseif d:IsA("PointLight") or d:IsA("SurfaceLight") or d:IsA("SpotLight") then
                    d.Enabled = false
                elseif d:IsA("Sound") then
                    d.Stop()
                    d.Volume = 0
                elseif d:IsA("Accessory") or d:IsA("Clothing") then
                    d:Destroy()
                elseif d:IsA("Explosion") then
                    d:Destroy()
                end
            end
            local L = game:GetService("Lighting")
            L.GlobalShadows = false
            L.FogEnd = 10000000000
            L.Brightness = 0
            L.EnvironmentDiffuseScale = 0
            L.EnvironmentSpecularScale = 0
            for _, c in pairs(L:GetChildren()) do
                if c:IsA("BlurEffect") or c:IsA("SunRaysEffect") or c:IsA("ColorCorrectionEffect") or c:IsA("BloomEffect") or c:IsA("DepthOfFieldEffect") then
                    c.Enabled = false
                end
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.EagerBulkExecution = true
            settings().Rendering.ReloadAssets = false
            for _, d in pairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d.Parent:FindFirstChild("Humanoid") then
                    d.Material = Enum.Material.SmoothPlastic
                    d.Reflectance = 0
                    d.CastShadow = false
                elseif d:IsA("MeshPart") or d:IsA("SpecialMesh") then
                    d.Enabled = false
                end
            end
        end)
    end
    local customSpeedValue = 16
    local autoLockSpeed = false
    Tab:Input({
        Title = "自定义锁定速度",
        Placeholder = "默认16",
        Default = "16",
        Callback = function(val)
            local num = tonumber(val)
            if num then customSpeedValue = num end
        end
    })
    Tab:Toggle({
        Title = "自动锁定自定义速度",
        Default = false,
        Callback = function(state)
            autoLockSpeed = state
            if state then
                task.spawn(function()
                    while autoLockSpeed do
                        pcall(function()
                            local char = Players.LocalPlayer.Character
                            if char and char:FindFirstChild("Humanoid") then
                                char.Humanoid.WalkSpeed = customSpeedValue
                            end
                        end)
                        task.wait()
                    end
                end)
            end
        end
    })
end
Tabs.Kill = Tabs:Create("击杀", "skull")
do
    local Tab = Tabs.Kill
    local autokill = false
    local lockkill = false
    local autoPunchKill = false
    local whitelist = {}
    local blacklist = {}
    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then table.insert(names, p.Name) end
        end
        table.sort(names)
        return names
    end
    local statusInfo = Tab:Paragraph({
        Title = "名单状态",
        Desc = "白名单 (0): 空\n黑名单 (0): 空",
    })
    local function updateInfo()
        local wList, bList = {}, {}
        for name in pairs(whitelist) do table.insert(wList, name) end
        for name in pairs(blacklist) do table.insert(bList, name) end
        table.sort(wList)
        table.sort(bList)
        local wStr = (#wList == 0) and "空" or table.concat(wList, ", ")
        local bStr = (#bList == 0) and "空" or table.concat(bList, ", ")
        statusInfo:SetDesc("白名单 (" .. #wList .. "): " .. wStr .. "\n黑名单 (" .. #bList .. "): " .. bStr)
    end
    updateInfo()
    local whiteDropdown = Tab:Dropdown({
        Title = "白名单",
        Values = getPlayerNames(),
        Default = {},
        Multi = true,
        Callback = function(selected)
            whitelist = {}
            if type(selected) == "table" then
                for _, name in ipairs(selected) do
                    if name and name ~= "" then whitelist[name] = true end
                end
            end
            updateInfo()
        end
    })
    local blackDropdown = Tab:Dropdown({
        Title = "黑名单",
        Values = getPlayerNames(),
        Default = {},
        Multi = true,
        Callback = function(selected)
            blacklist = {}
            if type(selected) == "table" then
                for _, name in ipairs(selected) do
                    if name and name ~= "" then blacklist[name] = true end
                end
            end
            updateInfo()
        end
    })
    Tab:Button({
        Title = "刷新玩家列表",
        Callback = function()
            local names = getPlayerNames()
            pcall(function() whiteDropdown:Refresh(names) end)
            pcall(function() blackDropdown:Refresh(names) end)
        end
    })
    local function ensurePunchEquipped()
        local lp = Players.LocalPlayer
        local character = lp.Character
        local backpack = lp.Backpack
        if character and backpack then
            local punchTool = backpack:FindFirstChild("Punch")
            if punchTool then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    local currentTool = character:FindFirstChildOfClass("Tool")
                    if not currentTool or currentTool.Name ~= "Punch" then humanoid:EquipTool(punchTool) end
                end
            end
        end
    end
    local function tpKillPlayer(targetPlayer)
        pcall(function()
            local lp = Players.LocalPlayer
            local targetChar = targetPlayer.Character
            if not targetChar then return end
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end
            local myChar = lp.Character
            if not myChar then return end
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2.5)
            myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            RunService.Heartbeat:Wait()
            local leftHand = myChar:FindFirstChild("LeftHand")
            local rightHand = myChar:FindFirstChild("RightHand")
            local targetHead = targetChar:FindFirstChild("Head")
            if targetHead and targetHead.Parent then
                if leftHand and leftHand.Parent then
                    firetouchinterest(targetHead, leftHand, 0)
                    firetouchinterest(targetHead, leftHand, 1)
                end
                if rightHand and rightHand.Parent then
                    firetouchinterest(targetHead, rightHand, 0)
                    firetouchinterest(targetHead, rightHand, 1)
                end
            end
            if lp:FindFirstChild("muscleEvent") then
                lp.muscleEvent:FireServer("punch", "leftHand")
                lp.muscleEvent:FireServer("punch", "rightHand")
            end
        end)
    end
    Tab:Toggle({
        Title = "自动击杀全部",
        Default = false,
        Callback = function(s)
            autokill = s
            if s then
                task.spawn(function()
                    while autokill do
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if not autokill then break end
                            if plr ~= Players.LocalPlayer and not whitelist[plr.Name] then
                                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                                    tpKillPlayer(plr)
                                    task.wait(0.05)
                                end
                            end
                        end
                        task.wait(0.05)
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "锁定击杀黑名单",
        Default = false,
        Callback = function(s)
            lockkill = s
            if s then
                task.spawn(function()
                    while lockkill do
                        for name in pairs(blacklist) do
                            if not lockkill then break end
                            local target = Players:FindFirstChild(name)
                            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                                tpKillPlayer(target)
                                task.wait(0.05)
                            end
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "自动挥拳",
        Default = false,
        Callback = function(s)
            autoPunchKill = s
            if s then
                task.spawn(function()
                    while autoPunchKill do
                        pcall(function()
                            ensurePunchEquipped()
                            if Players.LocalPlayer:FindFirstChild("muscleEvent") then
                                Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
                            end
                        end)
                        task.wait()
                    end
                end)
            end
        end
    })
end
Tabs.Boss = Tabs:Create("头目", "swords")
do
    local Tab = Tabs.Boss
    local autoBossKill = false
    local autoBossThread = nil
    local cachedArena = nil
    local lastDeepSearch = 0
    local lastGlobalScan = 0
    local globalBossCache = {}
    local uiHasBoss = false
    local autoBossRebirth = false
    local autoBossRebirthThread = nil
    local autoTrainBoss = false
    local autoTrainBossThread = nil
    local TARGET_STRENGTH = 1000000000000
    local TRAIN_CFRAME = CFrame.new(-5492.70508, 60.4064407, 4643.64209, 0, 0, 1, 0, 1, 0, -1, 0, 0)
    local TRIBAL_NAME = "Tribal Overlord"
    local SWIFT_NAME = "Swift Samurai"
    if _G.CatBossKillThread then
        pcall(function()
            task.cancel(_G.CatBossKillThread)
        end)
        _G.CatBossKillThread = nil
        pcall(function()
            local char = Players.LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.AutoRotate = true
            end
        end)
    end
    local function getBossArena()
        if cachedArena and cachedArena.Parent then
            return cachedArena
        end
        cachedArena = nil
        local events = workspace:FindFirstChild("Events")
        if events then
            local arena = events:FindFirstChild("BossArena")
            if arena then
                cachedArena = arena
                return arena
            end
        end
        if os.clock() - lastDeepSearch > 3 then
            lastDeepSearch = os.clock()
            cachedArena = workspace:FindFirstChild("BossArena", true)
        end
        return cachedArena
    end
    local function getRootPart(inst)
        if not inst then
            return nil
        end
        if inst:IsA("BasePart") then
            return inst
        end
        if inst:IsA("Model") then
            return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
        end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end
    local function getGuiTexts(guiObj)
        local texts = {}
        if not guiObj then
            return texts
        end
        pcall(function()
            for _, d in ipairs(guiObj:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text ~= "" then
                    table.insert(texts, d.Text)
                end
            end
        end)
        return texts
    end
    local function extractNumbers(text)
        local nums = {}
        if type(text) ~= "string" then
            return nums
        end
        for num, suffix in text:gmatch("([%d%.%,]+)%s*([KkMmBb]?)") do
            local clean = num:gsub("[%,]", "")
            local n = tonumber(clean)
            if n then
                local s = suffix and suffix:lower() or ""
                if s == "k" then
                    n = n * 1000
                elseif s == "m" then
                    n = n * 1000000
                elseif s == "b" then
                    n = n * 1000000000
                end
                table.insert(nums, n)
            end
        end
        return nums
    end
    local function isPlayerCharacter(model)
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char and (char == model or model:IsDescendantOf(char)) then
                return true
            end
        end
        return false
    end
    local bossNameMap = {
        ["Boss1"] = "普通头目",
        ["Boss2"] = "稀有头目",
        ["Boss3"] = "史诗头目",
        ["Boss4"] = "传奇头目",
        ["Boss5"] = "神话头目",
        ["Boss6"] = "彩虹头目"
    }
    local function resolveBossInfo(inst, source)
        local info = { name = nil, hp = nil, maxHp = nil, root = nil, alive = false }
        info.root = getRootPart(inst)
        if not info.root or not info.root.Parent then
            return info
        end
        local container = inst:IsA("BasePart") and inst.Parent or inst
        local stats = container and container:FindFirstChild("stats")
        local numbers = {}
        if stats then
            for _, v in ipairs(stats:GetChildren()) do
                if v:IsA("StringValue") and v.Value ~= "" and not info.name then
                    info.name = v.Value
                elseif v:IsA("ValueBase") and typeof(v.Value) == "number" then
                    table.insert(numbers, v.Value)
                end
            end
        end
        local healthGui = container and (container:FindFirstChild("bossHealthRuntime") or container:FindFirstChild("bossInfoRuntime"))
        local texts = getGuiTexts(healthGui)
        if #texts > 0 then
            local parsed = extractNumbers(table.concat(texts, "\n"))
            if #parsed >= 2 then
                local a, b = parsed[1], parsed[2]
                if b < a then
                    a, b = b, a
                end
                info.hp, info.maxHp = a, b
            elseif #parsed == 1 then
                info.hp = parsed[1]
            end
            if not info.name then
                for _, t in ipairs(texts) do
                    if not t:find("%d") and not t:find("时间") then
                        info.name = t
                        break
                    end
                end
            end
        end
        if not info.hp and #numbers >= 2 then
            local a, b = numbers[1], numbers[2]
            if b < a then
                a, b = b, a
            end
            info.hp, info.maxHp = a, b
        elseif not info.hp and #numbers == 1 then
            info.hp = numbers[1]
        end
        if info.hp then
            info.alive = info.hp > 0
        elseif source == "Bosses" then
            info.alive = true
        elseif source == "Arena" then
            info.alive = #texts > 0
        else
            info.alive = true
        end
        local cn = container and container.Name or inst.Name
        if info.name and bossNameMap[info.name] then
            info.name = bossNameMap[info.name]
        elseif not info.name then
            info.name = bossNameMap[cn] or cn
        end
        return info
    end
    local function getBossBoardName()
        local arena = getBossArena()
        if not arena then
            return nil
        end
        for _, slot in ipairs(arena:GetChildren()) do
            for _, child in ipairs(slot:GetChildren()) do
                if child:FindFirstChild("bossInfoRuntime") then
                    local texts = getGuiTexts(child:FindFirstChild("bossInfoRuntime"))
                    for _, t in ipairs(texts) do
                        if not t:find("%d") and not t:find("时间") and not t:find(":") then
                            return t
                        end
                    end
                end
            end
        end
        return nil
    end
    local function refreshGlobalBossCache()
        globalBossCache = {}
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("Model") then
                local humanoid = desc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and not isPlayerCharacter(desc) then
                    local nameLow = desc.Name:lower()
                    local parentLow = desc.Parent and tostring(desc.Parent.Name):lower() or ""
                    if nameLow:find("boss", 1, true) or nameLow:find("头目", 1, true) or parentLow:find("boss", 1, true) or parentLow:find("头目", 1, true) then
                        table.insert(globalBossCache, desc)
                    end
                end
            end
        end
    end
    local function findAliveBosses()
        local bosses = {}
        local seen = {}
        local boardName = nil
        local function tryAddCustom(inst, source)
            if not inst or seen[inst] then
                return
            end
            seen[inst] = true
            local info = resolveBossInfo(inst, source)
            if not info.root or not info.alive then
                return
            end
            for _, e in ipairs(bosses) do
                if e.root and (e.root.Position - info.root.Position).Magnitude < 3 then
                    return
                end
            end
            if not info.name or bossNameMap[info.name] then
                if bossNameMap[info.name] then
                    info.name = bossNameMap[info.name]
                else
                    if not boardName then
                        boardName = getBossBoardName()
                    end
                    info.name = boardName or "BOSS"
                end
            end
            table.insert(bosses, { root = info.root, name = info.name, hp = info.hp, maxHp = info.maxHp, inst = inst })
        end
        pcall(function()
            local ph = workspace:FindFirstChild("PlaceholderWorkspace")
            if ph then
                local folder = ph:FindFirstChild("Bosses")
                if folder then
                    for _, child in ipairs(folder:GetChildren()) do
                        if child:IsA("Model") or child:IsA("Folder") or child:IsA("BasePart") then
                            tryAddCustom(child, "Bosses")
                        end
                    end
                end
            end
        end)
        local arena = getBossArena()
        if arena then
            for _, slot in ipairs(arena:GetChildren()) do
                local boss = slot:FindFirstChild("Boss")
                if boss and (boss:IsA("Model") or boss:IsA("BasePart") or boss:IsA("Folder")) then
                    tryAddCustom(boss, "Arena")
                end
                for _, child in ipairs(slot:GetChildren()) do
                    if child:IsA("Model") and child ~= boss then
                        if child:FindFirstChildOfClass("Humanoid") or child:FindFirstChild("stats") then
                            tryAddCustom(child, "Arena")
                        end
                    end
                end
            end
        end
        if #bosses == 0 and os.clock() - lastGlobalScan > 2 then
            lastGlobalScan = os.clock()
            refreshGlobalBossCache()
        end
        if #bosses == 0 then
            for _, model in ipairs(globalBossCache) do
                if not seen[model] then
                    seen[model] = true
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        table.insert(bosses, { root = getRootPart(model), name = bossNameMap[model.Name] or model.Name, hp = humanoid.Health, maxHp = humanoid.MaxHealth, inst = model })
                    end
                end
            end
        end
        return bosses
    end
    local function getLocalCharacter()
        local char = Players.LocalPlayer.Character
        if not char or not char.Parent then
            return nil
        end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or humanoid.Health <= 0 then
            return nil
        end
        return char, humanoid, root
    end
    local function getNearestBoss(bosses, myPosition)
        local nearest = nil
        local nearestDist = nil
        for _, info in ipairs(bosses) do
            local bossRoot = info.root
            if bossRoot and bossRoot.Parent then
                local dist = (bossRoot.Position - myPosition).Magnitude
                if not nearestDist or dist < nearestDist then
                    nearest = info
                    nearestDist = dist
                end
            end
        end
        return nearest or bosses[1]
    end
    local function getTopCFrame(bossRoot)
        if not bossRoot then
            return nil
        end
        local bossPos = bossRoot.Position
        local look = bossRoot.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.01 then
            flatLook = Vector3.new(0, 0, 1)
        end
        flatLook = flatLook.Unit
        local topPos = bossPos + Vector3.new(0, bossRoot.Size.Y * 0.5 + 2, 0)
        local facePos = Vector3.new(topPos.X + flatLook.X, topPos.Y, topPos.Z + flatLook.Z)
        return CFrame.new(topPos, facePos)
    end
    local function getTouchTargets(entry)
        local targets = {}
        local inst = entry.inst
        if inst and inst:IsA("Model") then
            local head = inst:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                table.insert(targets, head)
            end
            local hitbox = inst:FindFirstChild("BossDamageHitbox")
            if hitbox and hitbox:IsA("BasePart") then
                table.insert(targets, hitbox)
            end
        elseif inst and inst:IsA("BasePart") then
            local container = inst.Parent
            local hitbox = container and container:FindFirstChild("BossDamageHitbox")
            if hitbox and hitbox:IsA("BasePart") then
                table.insert(targets, hitbox)
            end
        end
        if entry.root and entry.root:IsA("BasePart") then
            table.insert(targets, entry.root)
        end
        return targets
    end
    local function autoPunch(char, humanoid, entry)
        local player = Players.LocalPlayer
        local punch = char:FindFirstChild("Punch")
        if not punch then
            local backpack = player:FindFirstChildOfClass("Backpack")
            punch = backpack and backpack:FindFirstChild("Punch")
            if punch then
                pcall(function()
                    humanoid:EquipTool(punch)
                end)
            end
        end
        if punch then
            pcall(function()
                punch:Activate()
            end)
        end
        pcall(function()
            if player:FindFirstChild("muscleEvent") then
                player.muscleEvent:FireServer("punch", "leftHand")
                player.muscleEvent:FireServer("punch", "rightHand")
            end
        end)
        if firetouchinterest then
            local targets = getTouchTargets(entry)
            local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Hand") or char:FindFirstChild("Left Arm")
            local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Hand") or char:FindFirstChild("Right Arm")
            local hands = {}
            if leftHand then
                table.insert(hands, leftHand)
            end
            if rightHand then
                table.insert(hands, rightHand)
            end
            if #hands > 0 and #targets > 0 then
                for _, target in ipairs(targets) do
                    for _, hand in ipairs(hands) do
                        pcall(function()
                            firetouchinterest(target, hand, 0)
                        end)
                    end
                end
                task.wait(0.01)
                for _, target in ipairs(targets) do
                    for _, hand in ipairs(hands) do
                        pcall(function()
                            firetouchinterest(target, hand, 1)
                        end)
                    end
                end
            end
        end
    end
    local function getBossIconTimeText()
        local textResult = ""
        pcall(function()
            local events = workspace:FindFirstChild("Events")
            local arena = events and events:FindFirstChild("BossArena")
            if arena then
                for _, d in ipairs(arena:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text ~= "" then
                        local timeMatch = d.Text:match("%d+:%d+:%d+") or d.Text:match("%d+:%d+")
                        if timeMatch then
                            textResult = timeMatch
                            break
                        end
                    end
                end
            end
            if textResult == "" then
                local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in ipairs(playerGui:GetChildren()) do
                        local gName = gui.Name:lower()
                        if gName:find("boss") or gName:find("event") or gName:find("timer") or gName:find("spawn") then
                            for _, d in ipairs(gui:GetDescendants()) do
                                if d:IsA("TextLabel") and d.Text ~= "" then
                                    local timeMatch = d.Text:match("%d+:%d+:%d+") or d.Text:match("%d+:%d+")
                                    if timeMatch then
                                        textResult = timeMatch
                                        break
                                    end
                                end
                            end
                        end
                        if textResult ~= "" then
                            break
                        end
                    end
                end
            end
        end)
        return textResult
    end
    local bossTimePara = Tab:Paragraph({ Title = "BOSS时间", Desc = "检测中..." })
    local bossStatusPara = Tab:Paragraph({ Title = "头目状态", Desc = "检测中..." })
    task.spawn(function()
        while true do
            pcall(function()
                local bosses = findAliveBosses()
                local timeText = getBossIconTimeText()
                local displayText = ""
                if #bosses > 0 then
                    uiHasBoss = true
                    if timeText ~= "" then
                        displayText = "当前BOSS剩余时间: " .. timeText
                    else
                        displayText = "当前BOSS剩余时间: 未能读取到文字时间"
                    end
                else
                    uiHasBoss = false
                    if timeText ~= "" then
                        displayText = "下一次BOSS刷新时间: " .. timeText
                    else
                        displayText = "下一次BOSS刷新时间: 未能读取到文字时间"
                    end
                end
                if bossTimePara and bossTimePara.SetDesc then
                    bossTimePara:SetDesc(displayText)
                end
            end)
            task.wait(1)
        end
    end)
    task.spawn(function()
        while true do
            pcall(function()
                local bosses = findAliveBosses()
                if #bosses == 0 then
                    bossStatusPara:SetDesc("当前地图未检测到BOSS")
                    uiHasBoss = false
                else
                    local lines = {}
                    for _, info in ipairs(bosses) do
                        local hpText = "血量未知"
                        if info.hp and info.maxHp then
                            hpText = "血量: " .. math.floor(info.hp) .. "/" .. math.floor(info.maxHp)
                        elseif info.hp then
                            hpText = "血量: " .. math.floor(info.hp)
                        end
                        table.insert(lines, "BOSS：" .. tostring(info.name or "未知") .. " | " .. hpText)
                    end
                    bossStatusPara:SetDesc(table.concat(lines, "\n"))
                    uiHasBoss = true
                end
            end)
            task.wait(0.5)
        end
    end)
    Tab:Toggle({
        Title = "自动击杀BOSS",
        Default = false,
        Callback = function(state)
            autoBossKill = state
            if autoBossThread then
                pcall(function()
                    task.cancel(autoBossThread)
                end)
            end
            autoBossThread = nil
            _G.CatBossKillThread = nil
            if state then
                autoBossThread = task.spawn(function()
                    local lastChar = nil
                    local respawnWaitUntil = 0
                    local nextAttackTime = 0
                    local hoverY = nil
                    local lastBossCount = 0
                    local needsClaim = false
                    local claimStartTime = 0
                    while autoBossKill do
                        local now = os.clock()
                        pcall(function()
                            local char, humanoid, root = getLocalCharacter()
                            if char then
                                if char ~= lastChar then
                                    local firstActivation = (lastChar == nil)
                                    lastChar = char
                                    if not firstActivation then
                                        respawnWaitUntil = now + 1.5
                                        nextAttackTime = now + 1.5
                                    end
                                    hoverY = nil
                                    needsClaim = false
                                end
                                if now >= respawnWaitUntil then
                                    local bosses = findAliveBosses()
                                    local info = nil
                                    if #bosses > 0 then
                                        info = getNearestBoss(bosses, root.Position)
                                    end
                                    if info and info.root and info.root.Parent then
                                        if lastBossCount == 0 then
                                            needsClaim = false
                                        end
                                        lastBossCount = #bosses
                                        humanoid.AutoRotate = false
                                        local ideal = getTopCFrame(info.root)
                                        if ideal then
                                            local offsetXZ = Vector3.new(root.Position.X - ideal.Position.X, 0, root.Position.Z - ideal.Position.Z).Magnitude
                                            local offsetY = math.abs(root.Position.Y - ideal.Position.Y)
                                            if offsetXZ > 1 or offsetY > 2 then
                                                root.CFrame = ideal
                                                hoverY = ideal.Position.Y
                                                nextAttackTime = now + 0.15
                                            end
                                            if hoverY then
                                                local cf = root.CFrame
                                                root.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                root.AssemblyLinearVelocity = Vector3.zero
                                                root.AssemblyAngularVelocity = Vector3.zero
                                            end
                                        end
                                        if now >= nextAttackTime then
                                            autoPunch(char, humanoid, info)
                                            nextAttackTime = now + 0.1
                                        end
                                    else
                                        humanoid.AutoRotate = true
                                        hoverY = nil
                                        if lastBossCount > 0 then
                                            needsClaim = true
                                            lastBossCount = 0
                                            claimStartTime = now
                                        end
                                        if needsClaim then
                                            if now - claimStartTime > 15 then
                                                needsClaim = false
                                            else
                                                local safeCFrame = CFrame.new(-12.4676466, 32.9251251, -1246.85315, 0.188146308, 3.6376548e-08, -0.982141018, -9.79466819e-08, 1, 1.82746049e-08, 0.982141018, 9.27591586e-08, 0.188146308)
                                                root.CFrame = safeCFrame
                                                task.wait(0.2)
                                                local bossChestFolder = workspace:FindFirstChild("BossChest")
                                                if bossChestFolder then
                                                    local chestRoot = bossChestFolder:FindFirstChild("Root")
                                                    local prompt = chestRoot and chestRoot:FindFirstChild("bossChestPrompt")
                                                    if prompt and prompt:IsA("ProximityPrompt") then
                                                        pcall(function()
                                                            fireproximityprompt(prompt)
                                                        end)
                                                        task.wait(0.5)
                                                        if not bossChestFolder.Parent or not bossChestFolder:FindFirstChild("Root") then
                                                            needsClaim = false
                                                        end
                                                    else
                                                        task.wait(0.5)
                                                    end
                                                else
                                                    task.wait(0.5)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.05)
                    end
                end)
                _G.CatBossKillThread = autoBossThread
            else
                pcall(function()
                    local char = Players.LocalPlayer.Character
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
            end
        end
    })
    local origToggle
    local newToggle
    local function getCurrentStrength()
        local ls = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("leaderstats")
        local st = ls and ls:FindFirstChild("Strength")
        return st and st.Value or 0
    end
    local function getCurrentRebirths()
        local ls = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("leaderstats")
        local r = ls and ls:FindFirstChild("Rebirths")
        return r and r.Value or 0
    end
    local function findAllPets(name)
        local result = {}
        local folder = Players.LocalPlayer:FindFirstChild("petsFolder")
        if not folder then
            return result
        end
        for _, child in ipairs(folder:GetDescendants()) do
            if child.Name == name then
                table.insert(result, child)
            end
        end
        return result
    end
    local function unequipAllPets()
        pcall(function()
            local player = Players.LocalPlayer
            local eq = player:FindFirstChild("equippedPets")
            if not eq then
                return
            end
            local rEvents = ReplicatedStorage:WaitForChild("rEvents")
            for _, slot in ipairs(eq:GetChildren()) do
                if slot:IsA("ValueBase") and slot.Value then
                    local petName = tostring(slot.Value)
                    if petName ~= "nil" and petName ~= "" and petName ~= "Instance" then
                        for _, pet in ipairs(findAllPets(petName)) do
                            rEvents.equipPetEvent:FireServer("unequipPet", pet)
                        end
                    end
                end
            end
        end)
    end
    local function equipAllPets(petName)
        local pets = findAllPets(petName)
        local rEvents = ReplicatedStorage:WaitForChild("rEvents")
        for i, pet in ipairs(pets) do
            rEvents.equipPetEvent:FireServer("equipPet", pet)
            if i % 3 == 0 then
                task.wait()
            end
        end
    end
    local function allEquipped(targetName)
        local equippedNames = {}
        pcall(function()
            local eq = Players.LocalPlayer:FindFirstChild("equippedPets")
            if eq then
                for _, slot in ipairs(eq:GetChildren()) do
                    if slot:IsA("ValueBase") and slot.Value then
                        local name = tostring(slot.Value)
                        if name ~= "nil" and name ~= "" and name ~= "Instance" then
                            table.insert(equippedNames, name)
                        end
                    end
                end
            end
        end)
        if #equippedNames == 0 then
            return false
        end
        for _, name in ipairs(equippedNames) do
            if name ~= targetName then
                return false
            end
        end
        return true
    end
    local function resolveMountSeat()
        local machinesFolder = workspace:FindFirstChild("machinesFolder")
        if not machinesFolder then
            return nil
        end
        local machine = machinesFolder:FindFirstChild("Industrial Bar Lift")
        return machine and machine:FindFirstChild("interactSeat")
    end
    local function leaveMachineForce()
        pcall(function()
            local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
            local remote = rEvents and rEvents:FindFirstChild("machineInteractRemote")
            if remote then
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("leaveMachine")
                elseif remote:IsA("RemoteEvent") then
                    remote:FireServer("leaveMachine")
                end
            end
        end)
        pcall(function()
            local char = Players.LocalPlayer.Character
            if not char then
                return
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Sit = false
                hum.PlatformStand = false
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
    local function doMount()
        local player = Players.LocalPlayer
        local char = player.Character
        if not char then
            return false
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return false
        end
        local miu = player:FindFirstChild("machineInUse")
        if miu and miu.Value ~= nil then
            if (root.Position - TRAIN_CFRAME.Position).Magnitude > 10 then
                leaveMachineForce()
                task.wait(0.5)
            end
        end
        root.CFrame = TRAIN_CFRAME
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(1)
        local seat = resolveMountSeat()
        if not seat then
            return false
        end
        pcall(function()
            local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt and seat.Parent then
                prompt = seat.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if prompt then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration)
                    prompt:InputHoldEnd()
                end
            end
        end)
        task.wait(0.2)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local vp = workspace.CurrentCamera.ViewportSize
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2 + 50, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2 + 50, 0, false, game, 1)
        end)
        task.wait(0.2)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, "E", false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, "E", false, game)
        end)
        task.wait(0.2)
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local remote = rEvents and rEvents:FindFirstChild("machineInteractRemote")
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("useMachine", seat)
                elseif remote:IsA("RemoteEvent") then
                    remote:FireServer("useMachine", seat)
                end
            end)
        end
        task.wait(1.5)
        miu = player:FindFirstChild("machineInUse")
        if miu and miu.Value ~= nil then
            return true
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
            pcall(function()
                seat:Sit(hum)
            end)
            task.wait(0.5)
        end
        return true
    end
    local function ensureMounted()
        if doMount() then
            return true
        end
        task.wait(0.5)
        return doMount()
    end
    local function breakAllExercise()
        pcall(function()
            local rEvents = game:GetService("ReplicatedStorage"):FindFirstChild("rEvents")
            if rEvents then
                local machineInteractRemote = rEvents:FindFirstChild("machineInteractRemote")
                if machineInteractRemote then
                    machineInteractRemote:InvokeServer("leaveMachine")
                end
            end
            local char = Players.LocalPlayer.Character
            if not char then
                return
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then
                return
            end
            hum:UnequipTools()
            hum.Sit = false
            hum.PlatformStand = false
            hum:StopAllAnimations()
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                for _, obj in pairs(root:GetChildren()) do
                    if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                        obj:Destroy()
                    end
                end
                root.CFrame = root.CFrame + Vector3.new(0, 0.3, 0)
            end
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                    obj:Destroy()
                end
            end
            hum.JumpPower = 50
            for i = 1, 8 do
                hum.Jump = true
                task.wait(0.05)
            end
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end)
    end
    local function fastTrain40()
        pcall(function()
            local me = Players.LocalPlayer:FindFirstChild("muscleEvent")
            if me then
                for i = 1, 40 do
                    me:FireServer("rep")
                end
            end
        end)
    end
    local HALLOWED_SQUAT_CFRAME = CFrame.new(-5217.11523, 60.4064407, 5418.07715, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    local function resolveHallowedSquatSeat()
        local machinesFolder = workspace:FindFirstChild("machinesFolder")
        local squat = machinesFolder and machinesFolder:FindFirstChild("Industrial Squat")
        return squat and squat:FindFirstChild("interactSeat")
    end
    local function doMountHallowedSquat()
        local player = Players.LocalPlayer
        local char = player.Character
        if not char then
            return false
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then
            return false
        end
        local miu = player:FindFirstChild("machineInUse")
        if miu and miu.Value ~= nil then
            if (root.Position - HALLOWED_SQUAT_CFRAME.Position).Magnitude > 10 then
                leaveMachineForce()
                task.wait(0.5)
            end
        end
        root.CFrame = HALLOWED_SQUAT_CFRAME
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(1)
        local seat = resolveHallowedSquatSeat()
        if not seat then
            return false
        end
        pcall(function()
            local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt and seat.Parent then
                prompt = seat.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if prompt then
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration)
                    prompt:InputHoldEnd()
                end
            end
        end)
        task.wait(0.2)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local vp = workspace.CurrentCamera.ViewportSize
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2 + 50, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(vp.X / 2, vp.Y / 2 + 50, 0, false, game, 1)
        end)
        task.wait(0.2)
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, "E", false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, "E", false, game)
        end)
        task.wait(0.2)
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        local remote = rEvents and rEvents:FindFirstChild("machineInteractRemote")
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("useMachine", seat)
                elseif remote:IsA("RemoteEvent") then
                    remote:FireServer("useMachine", seat)
                end
            end)
        end
        task.wait(1.5)
        miu = player:FindFirstChild("machineInUse")
        if miu and miu.Value ~= nil then
            return true
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
            pcall(function()
                seat:Sit(hum)
            end)
            task.wait(0.5)
        end
        return true
    end
    local function ensureMountedHallowedSquat()
        if doMountHallowedSquat() then
            return true
        end
        task.wait(0.5)
        return doMountHallowedSquat()
    end
    local function leaveHallowedSquat()
        pcall(function()
            local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
            local machineRemote = rEvents and rEvents:FindFirstChild("machineInteractRemote")
            if machineRemote then
                machineRemote:InvokeServer("leaveMachine")
            end
        end)
        pcall(function()
            local char = Players.LocalPlayer.Character
            if not char then
                return
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then
                return
            end
            hum:UnequipTools()
            hum.Sit = false
            hum.PlatformStand = false
            hum:StopAllAnimations()
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop(0)
                end
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                for _, obj in ipairs(root:GetChildren()) do
                    if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                        obj:Destroy()
                    end
                end
                root.CFrame = root.CFrame + Vector3.new(0, 0.3, 0)
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                    obj:Destroy()
                end
            end
            hum.JumpPower = 50
            for _ = 1, 8 do
                hum.Jump = true
                task.wait(0.05)
            end
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end)
    end
    origToggle = Tab:Toggle({
        Title = "自动击杀BOSS+重生(包专属)",
        Default = false,
        Callback = function(state)
            if state and autoTrainBoss then
                autoTrainBoss = false
                if autoTrainBossThread then
                    pcall(function()
                        task.cancel(autoTrainBossThread)
                    end)
                    autoTrainBossThread = nil
                end
                pcall(function()
                    if newToggle and newToggle.Set then
                        newToggle:Set(false)
                    end
                end)
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
                leaveHallowedSquat()
            end
            autoBossRebirth = state
            if autoBossRebirthThread then
                pcall(function()
                    task.cancel(autoBossRebirthThread)
                end)
                autoBossRebirthThread = nil
            end
            if state then
                autoBossRebirthThread = task.spawn(function()
                    while autoBossRebirth do
                        local char = getLocalCharacter()
                        if not char then
                            task.wait(1)
                        else
                            if uiHasBoss then
                                task.wait(0.5)
                                local strength = getCurrentStrength()
                                if strength < TARGET_STRENGTH then
                                    if not allEquipped(SWIFT_NAME) then
                                        unequipAllPets()
                                        task.wait(0.1)
                                        equipAllPets(SWIFT_NAME)
                                    end
                                    ensureMounted()
                                    while autoBossRebirth and uiHasBoss and getCurrentStrength() < TARGET_STRENGTH do
                                        fastTrain40()
                                        task.wait()
                                    end
                                end
                                if autoBossRebirth and uiHasBoss then
                                    task.wait(0.5)
                                    breakAllExercise()
                                    task.wait(0.3)
                                    local attackStart = os.clock()
                                    local hoverY = nil
                                    while autoBossRebirth and uiHasBoss and (os.clock() - attackStart) < 300 do
                                        local currentBosses = findAliveBosses()
                                        local c, hum, r = getLocalCharacter()
                                        if not c then
                                            break
                                        end
                                        if #currentBosses > 0 then
                                            hum.AutoRotate = false
                                            local info = getNearestBoss(currentBosses, r.Position)
                                            local ideal = getTopCFrame(info.root)
                                            if ideal then
                                                local offsetXZ = Vector3.new(r.Position.X - ideal.Position.X, 0, r.Position.Z - ideal.Position.Z).Magnitude
                                                local offsetY = math.abs(r.Position.Y - ideal.Position.Y)
                                                if offsetXZ > 1 or offsetY > 2 then
                                                    r.CFrame = ideal
                                                    hoverY = ideal.Position.Y
                                                end
                                                if hoverY then
                                                    local cf = r.CFrame
                                                    r.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                    r.AssemblyLinearVelocity = Vector3.zero
                                                    r.AssemblyAngularVelocity = Vector3.zero
                                                end
                                            end
                                            autoPunch(c, hum, info)
                                        else
                                            hum.AutoRotate = true
                                            hoverY = nil
                                        end
                                        task.wait(0.05)
                                    end
                                    if autoBossRebirth then
                                        local _, hum, r = getLocalCharacter()
                                        if hum then
                                            hum.AutoRotate = true
                                        end
                                        local safeCFrame = CFrame.new(-12.4676466, 32.9251251, -1246.85315, 0.188146308, 3.6376548e-08, -0.982141018, -9.79466819e-08, 1, 1.82746049e-08, 0.982141018, 9.27591586e-08, 0.188146308)
                                        if r then
                                            r.CFrame = safeCFrame
                                        end
                                        task.wait(0.2)
                                        local bossChestFolder = workspace:FindFirstChild("BossChest")
                                        if bossChestFolder then
                                            local chestRoot = bossChestFolder:FindFirstChild("Root")
                                            local prompt = chestRoot and chestRoot:FindFirstChild("bossChestPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                for i = 1, 15 do
                                                    pcall(function()
                                                        fireproximityprompt(prompt)
                                                    end)
                                                    task.wait(0.15)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                ensureMounted()
                                while autoBossRebirth and not uiHasBoss do
                                    local player = Players.LocalPlayer
                                    local leaderstats = player:FindFirstChild("leaderstats")
                                    if leaderstats then
                                        local strengthStat = leaderstats:FindFirstChild("Strength")
                                        local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                                        if strengthStat and rebirthsStat then
                                            local currentReb = rebirthsStat.Value
                                            local required = math.max(1, math.floor((10000 + 5000 * currentReb) * 0.5))
                                            local currentStr = strengthStat.Value
                                            local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                                            if currentStr < required then
                                                if not allEquipped(SWIFT_NAME) then
                                                    unequipAllPets()
                                                    task.wait()
                                                    equipAllPets(SWIFT_NAME)
                                                end
                                                for i = 1, 15 do
                                                    player.muscleEvent:FireServer("rep")
                                                end
                                            else
                                                if not allEquipped(TRIBAL_NAME) then
                                                    unequipAllPets()
                                                    task.wait()
                                                    equipAllPets(TRIBAL_NAME)
                                                end
                                                if rEvents then
                                                    rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                                                end
                                            end
                                        end
                                    end
                                    task.wait()
                                end
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            else
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
            end
        end
    })
    Tab:Input({
        Title = "自定义锻炼倍数",
        Placeholder = "500",
        Default = "500",
        Callback = function(val)
            FastTrain.SetRate(val)
        end
    })
    newToggle = Tab:Toggle({
        Title = "自动击杀BOSS+力量(包专属)",
        Desc = "开启前自己装备宠物",
        Default = false,
        Callback = function(state)
            if state and autoBossRebirth then
                autoBossRebirth = false
                if autoBossRebirthThread then
                    pcall(function()
                        task.cancel(autoBossRebirthThread)
                    end)
                    autoBossRebirthThread = nil
                end
                pcall(function()
                    if origToggle and origToggle.Set then
                        origToggle:Set(false)
                    end
                end)
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
                breakAllExercise()
            end
            autoTrainBoss = state
            if autoTrainBossThread then
                pcall(function()
                    task.cancel(autoTrainBossThread)
                end)
                autoTrainBossThread = nil
            end
            if state then
                autoTrainBossThread = task.spawn(function()
                    while autoTrainBoss do
                        local char = getLocalCharacter()
                        if not char then
                            task.wait(1)
                        else
                            if uiHasBoss then
                                FastTrain.Stop()
                                task.wait(0.5)
                                if autoTrainBoss and uiHasBoss then
                                    task.wait(0.5)
                                    leaveHallowedSquat()
                                    task.wait(0.3)
                                    local attackStart = os.clock()
                                    local hoverY = nil
                                    while autoTrainBoss and uiHasBoss and (os.clock() - attackStart) < 300 do
                                        local currentBosses = findAliveBosses()
                                        local c, hum, r = getLocalCharacter()
                                        if not c then
                                            break
                                        end
                                        if #currentBosses > 0 then
                                            hum.AutoRotate = false
                                            local info = getNearestBoss(currentBosses, r.Position)
                                            local ideal = getTopCFrame(info.root)
                                            if ideal then
                                                local offsetXZ = Vector3.new(r.Position.X - ideal.Position.X, 0, r.Position.Z - ideal.Position.Z).Magnitude
                                                local offsetY = math.abs(r.Position.Y - ideal.Position.Y)
                                                if offsetXZ > 1 or offsetY > 2 then
                                                    r.CFrame = ideal
                                                    hoverY = ideal.Position.Y
                                                end
                                                if hoverY then
                                                    local cf = r.CFrame
                                                    r.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                    r.AssemblyLinearVelocity = Vector3.zero
                                                    r.AssemblyAngularVelocity = Vector3.zero
                                                end
                                            end
                                            autoPunch(c, hum, info)
                                        else
                                            hum.AutoRotate = true
                                            hoverY = nil
                                        end
                                        task.wait(0.05)
                                    end
                                    if autoTrainBoss then
                                        local _, hum, r = getLocalCharacter()
                                        if hum then
                                            hum.AutoRotate = true
                                        end
                                        local safeCFrame = CFrame.new(-12.4676466, 32.9251251, -1246.85315, 0.188146308, 3.6376548e-08, -0.982141018, -9.79466819e-08, 1, 1.82746049e-08, 0.982141018, 9.27591586e-08, 0.188146308)
                                        if r then
                                            r.CFrame = safeCFrame
                                        end
                                        task.wait(0.2)
                                        local bossChestFolder = workspace:FindFirstChild("BossChest")
                                        if bossChestFolder then
                                            local chestRoot = bossChestFolder:FindFirstChild("Root")
                                            local prompt = chestRoot and chestRoot:FindFirstChild("bossChestPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                for _ = 1, 15 do
                                                    pcall(function()
                                                        fireproximityprompt(prompt)
                                                    end)
                                                    task.wait(0.15)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                ensureMountedHallowedSquat()
                                FastTrain.Start()
                                while autoTrainBoss and not uiHasBoss do
                                    task.wait()
                                end
                                FastTrain.Stop()
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            else
                FastTrain.Stop()
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
                leaveHallowedSquat()
            end
        end
    })
    local autoKillRebirth = false
    local autoKillRebirthThread = nil
    local autoKillTrain = false
    local autoKillTrainThread = nil
    Tab:Toggle({
        Title = "自动击杀BOSS+重生",
        Default = false,
        Callback = function(state)
            autoKillRebirth = state
            if autoKillRebirthThread then
                pcall(function()
                    task.cancel(autoKillRebirthThread)
                end)
                autoKillRebirthThread = nil
            end
            if state then
                pcall(function()
                    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                    local equipEvent = rEvents and rEvents:FindFirstChild("equipPetEvent")
                    if equipEvent then
                        equipEvent:FireServer("equipBest")
                    end
                end)
                autoKillRebirthThread = task.spawn(function()
                    while autoKillRebirth do
                        local char = getLocalCharacter()
                        if not char then
                            task.wait(1)
                        else
                            if uiHasBoss then
                                task.wait(0.5)
                                local strength = getCurrentStrength()
                                if strength < TARGET_STRENGTH then
                                    ensureMounted()
                                    while autoKillRebirth and uiHasBoss and getCurrentStrength() < TARGET_STRENGTH do
                                        fastTrain40()
                                        task.wait()
                                    end
                                end
                                if autoKillRebirth and uiHasBoss then
                                    task.wait(0.5)
                                    breakAllExercise()
                                    task.wait(0.3)
                                    local attackStart = os.clock()
                                    local hoverY = nil
                                    while autoKillRebirth and uiHasBoss and (os.clock() - attackStart) < 300 do
                                        local currentBosses = findAliveBosses()
                                        local c, hum, r = getLocalCharacter()
                                        if not c then
                                            break
                                        end
                                        if #currentBosses > 0 then
                                            hum.AutoRotate = false
                                            local info = getNearestBoss(currentBosses, r.Position)
                                            local ideal = getTopCFrame(info.root)
                                            if ideal then
                                                local offsetXZ = Vector3.new(r.Position.X - ideal.Position.X, 0, r.Position.Z - ideal.Position.Z).Magnitude
                                                local offsetY = math.abs(r.Position.Y - ideal.Position.Y)
                                                if offsetXZ > 1 or offsetY > 2 then
                                                    r.CFrame = ideal
                                                    hoverY = ideal.Position.Y
                                                end
                                                if hoverY then
                                                    local cf = r.CFrame
                                                    r.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                    r.AssemblyLinearVelocity = Vector3.zero
                                                    r.AssemblyAngularVelocity = Vector3.zero
                                                end
                                            end
                                            autoPunch(c, hum, info)
                                        else
                                            hum.AutoRotate = true
                                            hoverY = nil
                                        end
                                        task.wait(0.05)
                                    end
                                    if autoKillRebirth then
                                        local _, hum, r = getLocalCharacter()
                                        if hum then
                                            hum.AutoRotate = true
                                        end
                                        local safeCFrame = CFrame.new(-12.4676466, 32.9251251, -1246.85315, 0.188146308, 3.6376548e-08, -0.982141018, -9.79466819e-08, 1, 1.82746049e-08, 0.982141018, 9.27591586e-08, 0.188146308)
                                        if r then
                                            r.CFrame = safeCFrame
                                        end
                                        task.wait(0.2)
                                        local bossChestFolder = workspace:FindFirstChild("BossChest")
                                        if bossChestFolder then
                                            local chestRoot = bossChestFolder:FindFirstChild("Root")
                                            local prompt = chestRoot and chestRoot:FindFirstChild("bossChestPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                for i = 1, 15 do
                                                    pcall(function()
                                                        fireproximityprompt(prompt)
                                                    end)
                                                    task.wait(0.15)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                ensureMounted()
                                while autoKillRebirth and not uiHasBoss do
                                    local player = Players.LocalPlayer
                                    local leaderstats = player:FindFirstChild("leaderstats")
                                    if leaderstats then
                                        local strengthStat = leaderstats:FindFirstChild("Strength")
                                        local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
                                        if strengthStat and rebirthsStat then
                                            local currentReb = rebirthsStat.Value
                                            local required = math.max(1, math.floor((10000 + 5000 * currentReb) * 0.5))
                                            local currentStr = strengthStat.Value
                                            local rEvents = ReplicatedStorage:WaitForChild("rEvents")
                                            if currentStr < required then
                                                for i = 1, 15 do
                                                    player.muscleEvent:FireServer("rep")
                                                end
                                            else
                                                if rEvents then
                                                    rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                                                end
                                            end
                                        end
                                    end
                                    task.wait()
                                end
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            else
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
            end
        end
    })
    Tab:Input({
        Title = "自定义锻炼倍数",
        Placeholder = "500",
        Default = "500",
        Callback = function(val)
            FastTrain.SetRate(val)
        end
    })
    Tab:Toggle({
        Title = "自动击杀BOSS+力量",
        Default = false,
        Callback = function(state)
            autoKillTrain = state
            if autoKillTrainThread then
                pcall(function()
                    task.cancel(autoKillTrainThread)
                end)
                autoKillTrainThread = nil
            end
            if state then
                autoKillTrainThread = task.spawn(function()
                    while autoKillTrain do
                        local char = getLocalCharacter()
                        if not char then
                            task.wait(1)
                        else
                            if uiHasBoss then
                                FastTrain.Stop()
                                task.wait(0.2)
                                local strength = getCurrentStrength()
                                if strength < TARGET_STRENGTH then
                                    ensureMountedHallowedSquat()
                                    FastTrain.Start()
                                    while autoKillTrain and uiHasBoss and getCurrentStrength() < TARGET_STRENGTH do
                                        task.wait()
                                    end
                                    FastTrain.Stop()
                                end
                                task.wait(0.5)
                                if autoKillTrain and uiHasBoss then
                                    task.wait(0.5)
                                    leaveHallowedSquat()
                                    task.wait(0.3)
                                    local attackStart = os.clock()
                                    local hoverY = nil
                                    while autoKillTrain and uiHasBoss and (os.clock() - attackStart) < 300 do
                                        local currentBosses = findAliveBosses()
                                        local c, hum, r = getLocalCharacter()
                                        if not c then
                                            break
                                        end
                                        if #currentBosses > 0 then
                                            hum.AutoRotate = false
                                            local info = getNearestBoss(currentBosses, r.Position)
                                            local ideal = getTopCFrame(info.root)
                                            if ideal then
                                                local offsetXZ = Vector3.new(r.Position.X - ideal.Position.X, 0, r.Position.Z - ideal.Position.Z).Magnitude
                                                local offsetY = math.abs(r.Position.Y - ideal.Position.Y)
                                                if offsetXZ > 1 or offsetY > 2 then
                                                    r.CFrame = ideal
                                                    hoverY = ideal.Position.Y
                                                end
                                                if hoverY then
                                                    local cf = r.CFrame
                                                    r.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                    r.AssemblyLinearVelocity = Vector3.zero
                                                    r.AssemblyAngularVelocity = Vector3.zero
                                                end
                                            end
                                            autoPunch(c, hum, info)
                                        else
                                            hum.AutoRotate = true
                                            hoverY = nil
                                        end
                                        task.wait(0.05)
                                    end
                                    if autoKillTrain then
                                        local _, hum, r = getLocalCharacter()
                                        if hum then
                                            hum.AutoRotate = true
                                        end
                                        local safeCFrame = CFrame.new(-12.4676466, 32.9251251, -1246.85315, 0.188146308, 3.6376548e-08, -0.982141018, -9.79466819e-08, 1, 1.82746049e-08, 0.982141018, 9.27591586e-08, 0.188146308)
                                        if r then
                                            r.CFrame = safeCFrame
                                        end
                                        task.wait(0.2)
                                        local bossChestFolder = workspace:FindFirstChild("BossChest")
                                        if bossChestFolder then
                                            local chestRoot = bossChestFolder:FindFirstChild("Root")
                                            local prompt = chestRoot and chestRoot:FindFirstChild("bossChestPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                for _ = 1, 15 do
                                                    pcall(function()
                                                        fireproximityprompt(prompt)
                                                    end)
                                                    task.wait(0.15)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                ensureMountedHallowedSquat()
                                FastTrain.Start()
                                while autoKillTrain and not uiHasBoss do
                                    task.wait()
                                end
                                FastTrain.Stop()
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            else
                FastTrain.Stop()
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
                leaveHallowedSquat()
            end
        end
    })
    local ALIEN_BOSS_NAME = "Alien Boss"
    local ALIEN_CLAIM_CFRAME = CFrame.new(-1839.16821, 55.3670616, -10990.1895, -0.767357707, 1.31723397e-08, -0.641219258, -2.90020825e-08, 1, 5.52499166e-08, 0.641219258, 6.09931448e-08, -0.767357707)
    local function getAlienBoss()
        return workspace:FindFirstChild(ALIEN_BOSS_NAME)
    end
    local function tryClaimAlienReward()
        local char, humanoid, root = getLocalCharacter()
        if not char then
            return
        end
        root.CFrame = ALIEN_CLAIM_CFRAME
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.3)
        local prompts = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent
                if part and part:IsA("BasePart") and (part.Position - ALIEN_CLAIM_CFRAME.Position).Magnitude < 40 then
                    table.insert(prompts, obj)
                end
            end
        end
        for _, prompt in ipairs(prompts) do
            pcall(function()
                fireproximityprompt(prompt)
            end)
            task.wait(0.1)
        end
        task.wait(0.5)
    end
    local alienBossStatusPara = Tab:Paragraph({
        Title = "Alien Boss状态",
        Desc = "检测中...",
    })
    task.spawn(function()
        while true do
            pcall(function()
                if getAlienBoss() then
                    alienBossStatusPara:SetDesc("Alien Boss 已出现！")
                else
                    alienBossStatusPara:SetDesc("当前地图未检测到Alien Boss")
                end
            end)
            task.wait(0.5)
        end
    end)
    local autoAlienBoss = false
    local autoAlienBossThread = nil
    Tab:Toggle({
        Title = "自动击杀Alien Boss",
        Default = false,
        Callback = function(state)
            autoAlienBoss = state
            if autoAlienBossThread then
                pcall(function()
                    task.cancel(autoAlienBossThread)
                end)
                autoAlienBossThread = nil
            end
            if state then
                autoAlienBossThread = task.spawn(function()
                    local lastChar = nil
                    local respawnWaitUntil = 0
                    local nextAttackTime = 0
                    local hoverY = nil
                    local lastBossCount = 0
                    local needsClaim = false
                    local claimStartTime = 0
                    while autoAlienBoss do
                        local now = os.clock()
                        pcall(function()
                            local char, humanoid, root = getLocalCharacter()
                            if char then
                                if char ~= lastChar then
                                    local firstActivation = (lastChar == nil)
                                    lastChar = char
                                    if not firstActivation then
                                        respawnWaitUntil = now + 1.5
                                        nextAttackTime = now + 1.5
                                    end
                                    hoverY = nil
                                    needsClaim = false
                                end
                                if now >= respawnWaitUntil then
                                    local boss = getAlienBoss()
                                    local info = nil
                                    if boss then
                                        local bossRoot = getRootPart(boss)
                                        if bossRoot then
                                            info = { root = bossRoot, name = ALIEN_BOSS_NAME, inst = boss }
                                        end
                                    end
                                    if info and info.root and info.root.Parent then
                                        if lastBossCount == 0 then
                                            needsClaim = false
                                        end
                                        lastBossCount = 1
                                        humanoid.AutoRotate = false
                                        local ideal = getTopCFrame(info.root)
                                        if ideal then
                                            local offsetXZ = Vector3.new(root.Position.X - ideal.Position.X, 0, root.Position.Z - ideal.Position.Z).Magnitude
                                            local offsetY = math.abs(root.Position.Y - ideal.Position.Y)
                                            if offsetXZ > 1 or offsetY > 2 then
                                                root.CFrame = ideal
                                                hoverY = ideal.Position.Y
                                            end
                                            if hoverY then
                                                local cf = root.CFrame
                                                root.CFrame = CFrame.new(cf.Position.X, hoverY, cf.Position.Z) * (ideal - ideal.Position)
                                                root.AssemblyLinearVelocity = Vector3.zero
                                                root.AssemblyAngularVelocity = Vector3.zero
                                            end
                                        end
                                        if now >= nextAttackTime then
                                            autoPunch(char, humanoid, info)
                                            nextAttackTime = now + 0.1
                                        end
                                    else
                                        humanoid.AutoRotate = true
                                        hoverY = nil
                                        if lastBossCount > 0 then
                                            needsClaim = true
                                            lastBossCount = 0
                                            claimStartTime = now
                                        end
                                        if needsClaim then
                                            if now - claimStartTime > 15 then
                                                needsClaim = false
                                            else
                                                tryClaimAlienReward()
                                                needsClaim = false
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.05)
                    end
                end)
            else
                pcall(function()
                    local _, humanoid = getLocalCharacter()
                    if humanoid then
                        humanoid.AutoRotate = true
                    end
                end)
            end
        end
    })
end
Tabs.TP = Tabs:Create("传送", "map-pin")
do
    local Tab = Tabs.TP
    local points = {
        {"大厅", CFrame.new(2.93, 88.93, 243.94)},
        {"小岛", CFrame.new(-38.86, 7.53, 1894.03)},
        {"冰霜健身房", CFrame.new(-2623.02, 7.38, -409.07)},
        {"神话健身房", CFrame.new(2250.77, 7.38, 1073.22)},
        {"永恒健身房", CFrame.new(-6758.96, 7.38, -1284.91)},
        {"传奇健身房", CFrame.new(4603.28, 991.53, -3897.86)},
        {"肌肉之王", CFrame.new(-8749.94, 124.45, -5861.06)},
        {"丛林健身房", CFrame.new(-8685.62, 6.81, 2392.32)},
        {"工业健身房", CFrame.new(-5563.23389, 60.4064407, 4942.44482, -4.14692796e-14, -2.55242618e-08, -1, -7.53453051e-08, 1, -2.55242618e-08, 1, 7.53453051e-08, -4.33924137e-14)},
        {"Zero Degrees健身房", CFrame.new(-5400, 46.8623886, 10622, 1.45993532e-14, 3.48852431e-08, -1, -4.22328803e-08, 1, 3.48852431e-08, 1, 4.22328803e-08, 1.60726569e-14)},
        {"Alien Gym健身房", CFrame.new(-1838.57788, 58.7160721, -10412.0928, 1, -7.00015619e-08, 6.44759989e-14, 7.00015619e-08, 1, -3.87019412e-08, -6.17668013e-14, 3.87019412e-08, 1)},
        {"转盘岛", CFrame.new(1952.09, 1.86, 6180.28)},
        {"熔岩争斗", CFrame.new(4472.61, 119.96, -8849.90)},
        {"沙漠争斗", CFrame.new(987.70, 17.23, -7440.26)},
        {"海滩争斗", CFrame.new(-1863.18, 17.23, -6292.78)},
    }
    for _, p in ipairs(points) do
        Tab:Button({ Title = p[1], Callback = function()
            local char = Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = p[2]
            end
        end })
    end
    Tab:Button({ Title = "安全平台", Callback = function()
        local char = Players.LocalPlayer.Character
        if char then
            char.HumanoidRootPart.CFrame = CFrame.new(-300, 100100, -450)
            local part = Instance.new("Part", workspace)
            part.CFrame = CFrame.new(-300, 100000, -450)
            part.Size = Vector3.new(1000000, 0, 10000000)
            part.Anchored = true
        end
    end })
end
Tabs.Auto = Tabs:Create("自动", "play")
do
    local Tab = Tabs.Auto
    local autowheel, autobr, autocollect = false, false, false
    local autoClaimGift = false
    local claimGiftThread = nil
    local autoDailyReward = false
    local dailyRewardThread = nil

    local function getGiftRemote()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if not rEvents then return nil end
        return rEvents:FindFirstChild("freeGiftClaimRemote")
    end
    Tab:Toggle({
        Title = "自动领取在线奖励",
        Default = false,
        Callback = function(s)
            autoClaimGift = s
            if claimGiftThread then
                task.cancel(claimGiftThread)
                claimGiftThread = nil
            end
            if s then
                claimGiftThread = task.spawn(function()
                    while autoClaimGift do
                        local remote = getGiftRemote()
                        if remote then
                            for i = 1, 8 do
                                if not autoClaimGift then break end
                                pcall(function()
                                    remote:InvokeServer("claimGift", i)
                                end)
                                task.wait(0.15)
                            end
                        end
                        task.wait(0.8)
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "自动签到",
        Default = false,
        Callback = function(s)
            autoDailyReward = s
            if dailyRewardThread then
                task.cancel(dailyRewardThread)
                dailyRewardThread = nil
            end
            if s then
                dailyRewardThread = task.spawn(function()
                    while autoDailyReward do
                        pcall(function()
                            local Event = ReplicatedStorage:WaitForChild("rEvents").dailyRewardRemote
                            for i = 1, 7 do
                                if not autoDailyReward then break end
                                Event:InvokeServer("claim")
                                task.wait(0.2)
                            end
                        end)
                        task.wait(1)
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "自动转盘抽奖",
        Default = false,
        Callback = function(s)
            autowheel = s
            if s then
                task.spawn(function()
                    local Event = ReplicatedStorage:WaitForChild("rEvents").openFortuneWheelRemote
                    while autowheel do
                        pcall(function()
                            Event:InvokeServer(
                                "openFortuneWheel",
                                ReplicatedStorage:WaitForChild("shared"):WaitForChild("catalogs"):WaitForChild("fortuneWheelChances"):WaitForChild("Fortune Wheel")
                            )
                        end)
                        task.wait()
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "自动参加争斗",
        Default = false,
        Callback = function(s)
            autobr = s
            if s then
                task.spawn(function()
                    while autobr do
                        pcall(function()
                            local machineRemote = ReplicatedStorage:WaitForChild("rEvents"):FindFirstChild("machineInteractRemote")
                            if machineRemote then
                                machineRemote:InvokeServer("leaveMachine")
                            end
                            task.wait(0.1)
                            local brawlEvent = ReplicatedStorage:WaitForChild("rEvents"):FindFirstChild("brawlEvent")
                            if brawlEvent then
                                brawlEvent:FireServer("joinBrawl")
                            end
                        end)
                        task.wait(2)
                    end
                end)
            end
        end
    })
    Tab:Toggle({
        Title = "自动收集宝箱",
        Default = false,
        Callback = function(s)
            autocollect = s
            if s then
                task.spawn(function()
                    local chests = {
                        {name = "Enchanted Chest", cf = CFrame.new(-2574.75146, 7.25373173, -556.987854, -0.137762934, -3.33488721e-08, -0.990465224, 1.34344014e-09, 1, -3.38567645e-08, 0.990465224, -5.99483796e-09, -0.137762934)},
                        {name = "Golden Chest", cf = CFrame.new(-138.384232, 7.25373077, -268.454926, 0.771318078, -2.84643882e-08, -0.636449873, -2.21614123e-08, 1, -7.15812689e-08, 0.636449873, 6.93165489e-08, 0.771318078)},
                        {name = "Mythical Chest", cf = CFrame.new(2214.43994, 7.25373077, 914.585083, 0.128692612, -8.08148215e-08, 0.991684556, -3.14114921e-08, 1, 8.55687929e-08, -0.991684556, -4.21623625e-08, 0.128692612)},
                        {name = "Magma Chest", cf = CFrame.new(-6722.25732, 7.25373077, -1455.96313, -0.0225496758, -1.04026235e-07, -0.999745727, 2.04485406e-09, 1, -1.04098817e-07, 0.999745727, -4.39172876e-09, -0.0225496758)},
                        {name = "Legends Chest", cf = CFrame.new(4660.31787, 1000.97217, -3699.3894, -0.643809855, 4.4027118e-08, -0.765185535, 1.84800086e-08, 1, 4.19891713e-08, 0.765185535, 1.28924071e-08, -0.643809855)},
                        {name = "Jungle Chest", cf = CFrame.new(-7909.55615, 6.73273563, 2968.34106, -0.999969125, -9.2121244e-09, 0.00785430335, -9.44795264e-09, 1, -2.99882288e-08, -0.00785430335, -3.00615106e-08, -0.999969125)},
                        {name = "Industrial Chest", cf = CFrame.new(-4747.19678, 57.8979149, 5552.28467, -0.995834827, -1.94910921e-10, 0.091175817, -1.61098634e-09, 1, -1.54576671e-08, -0.091175817, -1.55401665e-08, -0.995834827)},
                        {name = "Zero Degrees Chest", cf = CFrame.new(-4605.11279, 46.8623886, 11169.4922, -0.993283033, 3.67675956e-09, 0.115709998, 1.19028565e-09, 1, -2.15579377e-08, -0.115709998, -2.12754063e-08, -0.993283033)},
                    }
                    pcall(function()
                        local char = Players.LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if not root then return end
                        for _, chest in ipairs(chests) do
                            if not autocollect then break end
                            root.CFrame = chest.cf
                            task.wait(0.2)
                            root.CFrame = root.CFrame * CFrame.new(0, 0, -2)
                            task.wait(0.3)
                            task.wait(3)
                        end
                        ReplicatedStorage:WaitForChild("rEvents"):WaitForChild("groupRemote"):InvokeServer("groupRewards")
                    end)
                    autocollect = false
                end)
            end
        end
    })
    local redeemCodes = {
        "mightygems2500",
        "ultimate250",
        "spacegems50",
        "megalift50",
        "speedy50",
        "epicreward500",
        "MillionWarriors",
        "frostgems10",
        "Musclestorm50",
        "Skyagility50",
        "galaxycrystal50",
        "supermuscle100",
        "superpunch100",
        "launch250",
        "junglegym500",
        "epicmusle20",
        "musclestorm50",
        "ASCENSION",
        "STRONGBLOXIAN",
        "HALLOWEENPART2",
        "BLOODMOON",
        "FROSTBITE",
        "ZERODEGREES",
        "ALIENINVASION"
    }
    Tab:Button({
        Title = "一键兑换兑换码",
        Callback = function()
            task.spawn(function()
                local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                local codeRemote = rEvents and rEvents:FindFirstChild("codeRemote")
                if not codeRemote then return end
                for _, code in ipairs(redeemCodes) do
                    pcall(function()
                        codeRemote:InvokeServer(code)
                    end)
                    task.wait(0.5)
                end
            end)
        end
    })
end
Tabs.Egg = Tabs:Create("食物", "utensils")
do
    local Tab = Tabs.Egg
    local foodMap = {
        ["蛋白棒"]     = { itemName = "Protein Bar",    key = "proteinBar"    },
        ["能量棒"]     = { itemName = "Energy Bar",     key = "energyBar"     },
        ["超级奶昔"]   = { itemName = "ULTRA Shake",    key = "ultraShake"    },
        ["热带奶昔"]   = { itemName = "Tropical Shake", key = "tropicalShake" },
        ["蛋白质奶昔"] = { itemName = "Protein Shake",  key = "proteinShake"  },
        ["健壮条"]     = { itemName = "TOUGH Bar",      key = "toughBar"      },
        ["能量奶昔"]   = { itemName = "Energy Shake",   key = "energyShake"   },
        ["蛋"]         = { itemName = "Protein Egg",    key = "proteinEgg"    },
    }
    local selectedFood = foodMap["蛋白棒"]
    Tab:Dropdown({
        Title    = "选择食物",
        Values   = { "蛋白棒", "能量棒", "超级奶昔", "热带奶昔", "蛋白质奶昔", "健壮条", "能量奶昔", "蛋" },
        Default  = "蛋白棒",
        Callback = function(val)
            selectedFood = foodMap[val]
        end
    })
    local foodCountDisplay = Tab:Paragraph({
        Title = "剩余数量",
        Desc  = "检测中...",
    })
    task.spawn(function()
        while true do
            local count = 0
            pcall(function()
                local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in ipairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name == selectedFood.itemName then
                            count = count + 1
                        end
                    end
                end
                local char = Players.LocalPlayer.Character
                if char then
                    for _, tool in ipairs(char:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name == selectedFood.itemName then
                            count = count + 1
                        end
                    end
                end
            end)
            foodCountDisplay:SetDesc(count .. " 个")
            task.wait(0.5)
        end
    end)    
    local eatingActive = false
    local function GetNil(Name, DebugId)
        for _, Object in ipairs(getnilinstances()) do
            if Object.Name == Name then
                if DebugId == nil or Object:GetDebugId() == DebugId then
                    return Object
                end
            end
        end
    end    
    Tab:Toggle({
        Title    = "自动吃食",
        Default  = false,
        Callback = function(state)
            eatingActive = state
            if state then
                task.spawn(function()
                    while eatingActive do
                        pcall(function()
                            local player = Players.LocalPlayer
                            local name   = selectedFood.itemName
                            local key    = selectedFood.key
                            local char = player.Character
                            if not char then return end
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if not hum then return end
                            local tool = char:FindFirstChild(name)
                            if not tool then
                                local backpack = player:FindFirstChild("Backpack")
                                if backpack then
                                    tool = backpack:FindFirstChild(name)
                                end
                            end
                            if not tool then
                                tool = GetNil(name)
                            end
                            if not tool or not tool:IsA("Tool") then return end
                            if tool.Parent ~= char then
                                hum:EquipTool(tool)
                                task.wait(0.03)
                                tool = char:FindFirstChild(name) or tool
                            end
                            if player:FindFirstChild("muscleEvent") then
                                for _ = 1, 10 do
                                    player.muscleEvent:FireServer(key, tool)
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
    local eatAllActive = false
    Tab:Toggle({
        Title    = "自动吃掉所有食物",
        Default  = false,
        Callback = function(state)
            eatAllActive = state
            if state then
                task.spawn(function()
                    while eatAllActive do
                        pcall(function()
                            local player = Players.LocalPlayer
                            local char = player.Character
                            if not char then return end
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if not hum then return end
                            local toolsToEat = {}
                            local backpack = player:FindFirstChild("Backpack")
                            if backpack then
                                for _, item in ipairs(backpack:GetChildren()) do
                                    if item:IsA("Tool") and item.Name ~= "Protein Egg" then
                                        table.insert(toolsToEat, item)
                                    end
                                end
                            end
                            for _, item in ipairs(char:GetChildren()) do
                                if item:IsA("Tool") and item.Name ~= "Protein Egg" then
                                    table.insert(toolsToEat, item)
                                end
                            end
                            for _, tool in ipairs(toolsToEat) do
                                if not eatAllActive then break end
                                local foodKey = nil
                                for _, foodData in pairs(foodMap) do
                                    if foodData.itemName == tool.Name then
                                        foodKey = foodData.key
                                        break
                                    end
                                end
                                if foodKey then
                                    if tool.Parent ~= char then
                                        hum:EquipTool(tool)
                                        task.wait(0.03)
                                        tool = char:FindFirstChild(tool.Name) or tool
                                    end
                                    if player:FindFirstChild("muscleEvent") then
                                        for _ = 1, 10 do
                                            player.muscleEvent:FireServer(foodKey, tool)
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end)
            end
        end
    })
    local longegg = Tab:Paragraph({
        Title = "剩余蛋:",
        Desc = "",
    })
    task.spawn(function()
        while task.wait() do
            pcall(function()
                longegg:SetDesc("" .. #game.Players.LocalPlayer.consumablesFolder:GetChildren())
            end)
        end
    end)
    local gived = 0
    Tab:Input({
        Title = "请选择送蛋次数",
        Value = "",
        PlaceholderText = "请输入",
        ClearTextOnFocus = false,
        Callback = function(Text)
            gived = Text
        end
    })
    local whoneed = ""
    Tab:Input({
        Title = "请输入用户名",
        Desc = "输入接收蛋玩家的用户名，不能是自己！！！",
        Value = "",
        PlaceholderText = "请输入",
        ClearTextOnFocus = false,
        Callback = function(Text)
            whoneed = Text
        end
    })
    Tab:Button({
        Title = "自动送蛋",
        Callback = function()
            local autogived = Window:Dialog({
                Title = "自动送蛋",
                Content = "防止不小心多次点击，请点确定",
                Buttons = {
                    {
                        Title = "确定",
                        Callback = function()
                            local total = tonumber(gived) or 1
                            local sentCount = 0
                            task.spawn(function()
                                while sentCount < total do
                                    local target = Players:FindFirstChild(whoneed)
                                    if not target then
                                        task.wait(1)
                                    else
                                        local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
                                        local egg = backpack and backpack:FindFirstChild("Protein Egg")
                                        if not egg or not egg:IsA("Tool") then
                                            break
                                        end
                                        local success = false
                                        pcall(function()
                                            local consumables = Players.LocalPlayer:FindFirstChild("consumablesFolder")
                                            if not consumables then
                                                consumables = Instance.new("Folder")
                                                consumables.Name = "consumablesFolder"
                                                consumables.Parent = Players.LocalPlayer
                                            end
                                            local eggEntry = consumables:FindFirstChild("Protein Egg")
                                            if not eggEntry then
                                                eggEntry = Instance.new("StringValue")
                                                eggEntry.Name = "Protein Egg"
                                                eggEntry.Parent = consumables
                                            end
                                            local canGift = eggEntry:FindFirstChild("canGift")
                                            if not canGift then
                                                canGift = Instance.new("BoolValue")
                                                canGift.Name = "canGift"
                                                canGift.Parent = eggEntry
                                            end
                                            canGift.Value = true
                                            ReplicatedStorage:WaitForChild("rEvents").giftRemote:InvokeServer("giftRequest", target, eggEntry)
                                            success = true
                                        end)
                                        if not success then
                                            pcall(function()
                                                local consumables = Players.LocalPlayer:FindFirstChild("consumablesFolder")
                                                if not consumables then
                                                    consumables = Instance.new("Folder")
                                                    consumables.Name = "consumablesFolder"
                                                    consumables.Parent = Players.LocalPlayer
                                                end
                                                local eggEntry = consumables:FindFirstChild("Protein Egg")
                                                if not eggEntry then
                                                    eggEntry = Instance.new("StringValue")
                                                    eggEntry.Name = "Protein Egg"
                                                    eggEntry.Parent = consumables
                                                end
                                                ReplicatedStorage:WaitForChild("rEvents").giftRemote:InvokeServer("giftRequest", target, eggEntry)
                                                success = true
                                            end)
                                        end
                                        if success then
                                            sentCount = sentCount + 1
                                        end
                                        task.wait(0.09)
                                    end
                                end
                            end)
                        end
                    },
                    {
                        Title = "取消",
                        Callback = function()
                            print("取消")
                        end
                    }
                }
            })
            autogived:Open()
        end,
    })
end
Window:SelectTab(1)
print("此脚本由猫天帝制作")