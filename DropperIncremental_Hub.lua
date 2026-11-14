--[[
    ═══════════════════════════════════════════════════════════
    ✨ DROPPER INCREMENTAL — PRETTY ULTIMATE SCRIPT HUB ✨
    • Aesthetic roblox-menu-ui design
    • Complete Auto Upgrades (All 18 categories + Tree + Daily)
    • Infinite-Range Auto Coin & Part Vacuum (Works everywhere!)
    • Complete Auto Farm, Progression, Activities & Ocean
    • Rock-solid Tab System (No race conditions, smooth scrolling)
    ═══════════════════════════════════════════════════════════
--]]

-- Clean up existing UI instances safely
local targetParent = (gethui and gethui()) or (game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
for _, child in ipairs(targetParent:GetChildren()) do
    if child.Name == "DropperIncremental_Hub" then
        pcall(function() child:Destroy() end)
    end
end

if getgenv().DropperHubLoaded and typeof(getgenv().DropperHubCleanup) == "function" then
    pcall(getgenv().DropperHubCleanup)
end

-- Core Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local MapEssentials = workspace:WaitForChild("MapEssentials", 10)

-- Themes System
local Themes = {
    ["🌙 Midnight"] = {
        Background   = Color3.fromRGB(15, 15, 25),
        Surface      = Color3.fromRGB(25, 25, 40),
        SurfaceLight = Color3.fromRGB(36, 36, 56),
        Accent       = Color3.fromRGB(130, 100, 255),
        AccentGlow   = Color3.fromRGB(160, 130, 255),
        Text         = Color3.fromRGB(235, 235, 250),
        TextDim      = Color3.fromRGB(150, 150, 180),
        Border       = Color3.fromRGB(50, 50, 80),
    },
    ["🌸 Sakura"] = {
        Background   = Color3.fromRGB(25, 18, 22),
        Surface      = Color3.fromRGB(40, 28, 35),
        SurfaceLight = Color3.fromRGB(55, 38, 48),
        Accent       = Color3.fromRGB(255, 130, 170),
        AccentGlow   = Color3.fromRGB(255, 160, 190),
        Text         = Color3.fromRGB(250, 235, 240),
        TextDim      = Color3.fromRGB(180, 145, 160),
        Border       = Color3.fromRGB(75, 50, 65),
    },
    ["💚 Matcha"] = {
        Background   = Color3.fromRGB(18, 25, 18),
        Surface      = Color3.fromRGB(28, 40, 30),
        SurfaceLight = Color3.fromRGB(40, 58, 44),
        Accent       = Color3.fromRGB(100, 230, 140),
        AccentGlow   = Color3.fromRGB(130, 245, 165),
        Text         = Color3.fromRGB(235, 250, 238),
        TextDim      = Color3.fromRGB(145, 175, 150),
        Border       = Color3.fromRGB(50, 75, 55),
    },
    ["🔥 Ember"] = {
        Background   = Color3.fromRGB(22, 14, 12),
        Surface      = Color3.fromRGB(38, 24, 20),
        SurfaceLight = Color3.fromRGB(55, 34, 28),
        Accent       = Color3.fromRGB(255, 120, 50),
        AccentGlow   = Color3.fromRGB(255, 150, 80),
        Text         = Color3.fromRGB(250, 238, 230),
        TextDim      = Color3.fromRGB(180, 155, 140),
        Border       = Color3.fromRGB(75, 45, 38),
    },
    ["💎 Ice"] = {
        Background   = Color3.fromRGB(12, 18, 28),
        Surface      = Color3.fromRGB(20, 30, 48),
        SurfaceLight = Color3.fromRGB(30, 45, 70),
        Accent       = Color3.fromRGB(80, 185, 255),
        AccentGlow   = Color3.fromRGB(120, 205, 255),
        Text         = Color3.fromRGB(230, 240, 255),
        TextDim      = Color3.fromRGB(140, 160, 190),
        Border       = Color3.fromRGB(45, 65, 95),
    },
    ["🖤 AMOLED"] = {
        Background   = Color3.fromRGB(0, 0, 0),
        Surface      = Color3.fromRGB(18, 18, 18),
        SurfaceLight = Color3.fromRGB(30, 30, 30),
        Accent       = Color3.fromRGB(255, 255, 255),
        AccentGlow   = Color3.fromRGB(200, 200, 200),
        Text         = Color3.fromRGB(255, 255, 255),
        TextDim      = Color3.fromRGB(130, 130, 130),
        Border       = Color3.fromRGB(50, 50, 50),
    },
}

local CurrentThemeName = "🌙 Midnight"
local CurrentTheme = Themes[CurrentThemeName]

-- Master State Table
local State = {
    -- Main & Farm
    AutoDropper = false,
    AutoBronzeDropper = false,
    AutoCollectCoins = true,
    AutoClaimDaily = false,
    AutoClaimQuests = false,
    AutoClaimAchievements = false,
    ClickDelay = 0.05,
    
    -- Upgrades (All Categories)
    AutoBuyAllUpgrades = false,
    AutoCashUpgrades = false,
    AutoRebirthUpgrades = false,
    AutoBronzeUpgrades = false,
    AutoDiamondsUpgrades = false,
    AutoCoinsUpgrades = false,
    AutoOtherCurrenciesUpgrades = false,
    AutoReadingUpgrades = false,
    AutoTreeUpgrades = false,
    AutoDailyUpgrades = false,
    
    -- Progression
    AutoRebirth = false,
    AutoBronzeRebirth = false,
    AutoPrestige = false,
    AutoAscend = false,
    AutoCrystalize = false,
    AutoPower = false,
    AutoFire = false,
    AutoGalactic = false,
    AutoSupernova = false,
    AutoSingularity = false,
    AutoBlackHole = false,
    AutoSacrifice = false,
    AutoEquipEnergy = false,
    AutoShrineDeposit = false,

    -- Activities & Gathering
    AutoTreeChop = false,
    AutoMobFight = false,
    AutoRockMining = false,
    AutoFarmHarvest = false,
    AutoBarn = false,
    AutoGreenhouse = false,
    AutoFruitDeposit = false,
    AutoFishing = false,
    AutoFishMarket = false,
    AutoCollectPearls = false,
    AutoCollectIngots = false,
    AutoCollectAmber = false,
    AutoDebrisMagnet = false,
    AutoDeliverOrders = false,

    -- Movement & Mods
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
}

-- ScreenGui Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DropperIncremental_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = targetParent

-- Notification System
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 280, 1, -20)
ToastContainer.Position = UDim2.new(1, -290, 0, 10)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastLayout.Padding = UDim.new(0, 8)
ToastLayout.Parent = ToastContainer

local function SendToast(message, toastType)
    local colors = {
        Success = Color3.fromRGB(80, 220, 120),
        Info    = CurrentTheme.Accent,
        Warning = Color3.fromRGB(255, 180, 50),
        Error   = Color3.fromRGB(255, 75, 75),
    }
    local icons = {
        Success = "✅",
        Info    = "✨",
        Warning = "⚠️",
        Error   = "❌",
    }
    local accentCol = colors[toastType or "Info"] or CurrentTheme.Accent
    local iconChar = icons[toastType or "Info"] or "✨"

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.Position = UDim2.fromOffset(300, 0)
    card.BackgroundColor3 = CurrentTheme.Surface
    card.BorderSizePixel = 0
    card.Parent = ToastContainer

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
    local cStroke = Instance.new("UIStroke", card)
    cStroke.Color = CurrentTheme.Border
    cStroke.Thickness = 1

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, -8)
    accentBar.Position = UDim2.new(0, 4, 0, 4)
    accentBar.BackgroundColor3 = accentCol
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 24, 1, 0)
    iconLabel.Position = UDim2.new(0, 16, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = iconChar
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = CurrentTheme.Text
    iconLabel.Parent = card

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -48, 1, 0)
    msgLabel.Position = UDim2.new(0, 44, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextSize = 12
    msgLabel.Font = Enum.Font.GothamMedium
    msgLabel.TextColor3 = CurrentTheme.Text
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = card

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    }):Play()

    task.delay(3, function()
        if card.Parent then
            local tw = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.fromOffset(300, 0),
                BackgroundTransparency = 1
            })
            tw:Play()
            tw.Completed:Connect(function() card:Destroy() end)
        end
    end)
end

-- Watermark Bar
local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.fromOffset(400, 28)
Watermark.Position = UDim2.new(0.5, -200, 0, 12)
Watermark.BackgroundColor3 = CurrentTheme.Surface
Watermark.BackgroundTransparency = 0.25
Watermark.Parent = ScreenGui

Instance.new("UICorner", Watermark).CornerRadius = UDim.new(1, 0)
local wmStroke = Instance.new("UIStroke", Watermark)
wmStroke.Color = CurrentTheme.Border
wmStroke.Thickness = 1

local wmText = Instance.new("TextLabel")
wmText.Size = UDim2.new(1, 0, 1, 0)
wmText.BackgroundTransparency = 1
wmText.Font = Enum.Font.GothamMedium
wmText.TextSize = 11
wmText.TextColor3 = CurrentTheme.TextDim
wmText.Text = "✨ Dropper Hub  │  🕐 00:00:00  │  📶 0ms  │  🖥️ 60 FPS"
wmText.Parent = Watermark

local fpsCount = 0
local lastFpsUpdate = os.clock()
local currentFps = 60
RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if os.clock() - lastFpsUpdate >= 1 then
        currentFps = fpsCount
        fpsCount = 0
        lastFpsUpdate = os.clock()
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local timeStr = os.date("%H:%M:%S")
        wmText.Text = string.format("✨ Dropper Hub  │  🕐 %s  │  📶 %dms  │  🖥️ %d FPS", timeStr, ping, currentFps)
        task.wait(0.5)
    end
end)

-- Main Hub Window
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.fromOffset(630, 460)
MainWindow.Position = UDim2.new(0.5, -315, 0.5, -230)
MainWindow.BackgroundColor3 = CurrentTheme.Background
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", MainWindow)
mainStroke.Color = CurrentTheme.Border
mainStroke.Thickness = 1.2

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 44)
Topbar.BackgroundColor3 = CurrentTheme.Surface
Topbar.BorderSizePixel = 0
Topbar.Parent = MainWindow
Instance.new("UICorner", Topbar).CornerRadius = UDim.new(0, 14)

local TopbarLine = Instance.new("Frame")
TopbarLine.Size = UDim2.new(1, 0, 0, 1)
TopbarLine.Position = UDim2.new(0, 0, 1, -1)
TopbarLine.BackgroundColor3 = CurrentTheme.Border
TopbarLine.BorderSizePixel = 0
TopbarLine.Parent = Topbar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.fromOffset(30, 44)
TitleIcon.Position = UDim2.fromOffset(14, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "💎"
TitleIcon.TextSize = 20
TitleIcon.Parent = Topbar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.fromOffset(46, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Dropper Incremental <font color=\"#8264FF\">Ultimate Hub</font>"
TitleLabel.RichText = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = CurrentTheme.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Topbar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(26, 26)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Parent = Topbar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(26, 26)
MinBtn.Position = UDim2.new(1, -68, 0.5, -13)
MinBtn.BackgroundColor3 = CurrentTheme.SurfaceLight
MinBtn.Text = "—"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.TextColor3 = CurrentTheme.Text
MinBtn.Parent = Topbar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

-- Dragging Implementation
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar Tabs Container
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = CurrentTheme.Surface
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.Parent = MainWindow

local SidebarBorder = Instance.new("Frame")
SidebarBorder.Name = "SidebarBorder"
SidebarBorder.Size = UDim2.new(0, 1, 1, -44)
SidebarBorder.Position = UDim2.new(0, 160, 0, 44)
SidebarBorder.BackgroundColor3 = CurrentTheme.Border
SidebarBorder.BorderSizePixel = 0
SidebarBorder.Parent = MainWindow

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = Sidebar

local TabListPadding = Instance.new("UIPadding")
TabListPadding.PaddingTop = UDim.new(0, 10)
TabListPadding.PaddingLeft = UDim.new(0, 8)
TabListPadding.PaddingRight = UDim.new(0, 8)
TabListPadding.PaddingBottom = UDim.new(0, 10)
TabListPadding.Parent = Sidebar

-- Content Container
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -160, 1, -44)
ContentArea.Position = UDim2.new(0, 160, 0, 44)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainWindow

-- Tab Registration & Switching (Robust & Race-Condition Free!)
local Tabs = {}
local CurrentTabName = nil

local function RegisterTab(name, icon, order)
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "Tab_" .. name
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 3
    tabScroll.ScrollBarImageColor3 = CurrentTheme.Accent
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.Visible = false
    tabScroll.Parent = ContentArea

    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingTop = UDim.new(0, 14)
    scrollPadding.PaddingLeft = UDim.new(0, 16)
    scrollPadding.PaddingRight = UDim.new(0, 16)
    scrollPadding.PaddingBottom = UDim.new(0, 16)
    scrollPadding.Parent = tabScroll

    local scrollLayout = Instance.new("UIListLayout")
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scrollLayout.Padding = UDim.new(0, 10)
    scrollLayout.Parent = tabScroll

    -- Tab Button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Btn_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundColor3 = CurrentTheme.SurfaceLight
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.AutoButtonColor = false
    tabBtn.LayoutOrder = order
    tabBtn.Parent = Sidebar

    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

    local btnIcon = Instance.new("TextLabel")
    btnIcon.Size = UDim2.new(0, 26, 1, 0)
    btnIcon.Position = UDim2.new(0, 8, 0, 0)
    btnIcon.BackgroundTransparency = 1
    btnIcon.Text = icon
    btnIcon.TextSize = 16
    btnIcon.Font = Enum.Font.GothamBold
    btnIcon.TextColor3 = CurrentTheme.TextDim
    btnIcon.Parent = tabBtn

    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(1, -40, 1, 0)
    btnLabel.Position = UDim2.new(0, 36, 0, 0)
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = name
    btnLabel.Font = Enum.Font.GothamMedium
    btnLabel.TextSize = 13
    btnLabel.TextColor3 = CurrentTheme.TextDim
    btnLabel.TextXAlignment = Enum.TextXAlignment.Left
    btnLabel.Parent = tabBtn

    -- Direct instant-switch logic without race conditions
    local function selectTab()
        if CurrentTabName == name then return end
        CurrentTabName = name

        for tName, tData in pairs(Tabs) do
            if tName == name then
                tData.Button.BackgroundTransparency = 0.2
                tData.Button.BackgroundColor3 = CurrentTheme.SurfaceLight
                tData.Label.TextColor3 = CurrentTheme.Accent
                tData.Icon.TextColor3 = CurrentTheme.Accent
                
                tData.Container.CanvasPosition = Vector2.new(0, 0)
                tData.Container.Position = UDim2.fromOffset(0, 0)
                tData.Container.Visible = true
            else
                tData.Button.BackgroundTransparency = 1
                tData.Label.TextColor3 = CurrentTheme.TextDim
                tData.Icon.TextColor3 = CurrentTheme.TextDim
                tData.Container.Visible = false
            end
        end
    end

    local tabData = {
        Container = tabScroll,
        Button = tabBtn,
        Icon = btnIcon,
        Label = btnLabel,
        Select = selectTab,
    }
    Tabs[name] = tabData

    tabBtn.MouseButton1Click:Connect(selectTab)
    return tabScroll
end

-- Section Builder
local function CreateSection(parent, title, emoji)
    local secFrame = Instance.new("Frame")
    secFrame.Size = UDim2.new(1, 0, 0, 0)
    secFrame.AutomaticSize = Enum.AutomaticSize.Y
    secFrame.BackgroundTransparency = 1
    secFrame.Parent = parent

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.Text = string.format("%s  %s", emoji or "📌", title)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 13
    header.TextColor3 = CurrentTheme.Accent
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = secFrame

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.fromOffset(0, 24)
    divider.BackgroundColor3 = CurrentTheme.Accent
    divider.BackgroundTransparency = 0.75
    divider.BorderSizePixel = 0
    divider.Parent = secFrame

    local itemsHolder = Instance.new("Frame")
    itemsHolder.Size = UDim2.new(1, 0, 0, 0)
    itemsHolder.Position = UDim2.fromOffset(0, 30)
    itemsHolder.AutomaticSize = Enum.AutomaticSize.Y
    itemsHolder.BackgroundTransparency = 1
    itemsHolder.Parent = secFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = itemsHolder

    return itemsHolder
end

-- Pill Toggle
local function CreateToggle(parent, text, emoji, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = CurrentTheme.Surface
    frame.BackgroundTransparency = 0.35
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = CurrentTheme.Border
    fStroke.Thickness = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s  %s", emoji or "⚙️", text)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = CurrentTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(40, 22)
    pill.Position = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = defaultVal and CurrentTheme.Accent or Color3.fromRGB(60, 60, 75)
    pill.BorderSizePixel = 0
    pill.Parent = frame
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = defaultVal and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isEnabled = defaultVal

    local function updateState(newState)
        isEnabled = newState
        TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = isEnabled and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
        }):Play()
        TweenService:Create(pill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            BackgroundColor3 = isEnabled and CurrentTheme.Accent or Color3.fromRGB(60, 60, 75)
        }):Play()
        
        TweenService:Create(frame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
            Size = UDim2.new(1, 0, 0, 36)
        }):Play()
        task.delay(0.08, function()
            TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, 38)
            }):Play()
        end)
        if callback then
            task.spawn(callback, isEnabled)
        end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateState(not isEnabled)
        end
    end)

    return {
        Set = updateState,
        Get = function() return isEnabled end,
    }
end

-- Slider with Value Badge
local function CreateSlider(parent, text, emoji, minVal, maxVal, defaultVal, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = CurrentTheme.Surface
    frame.BackgroundTransparency = 0.35
    frame.Parent = parent

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = CurrentTheme.Border
    fStroke.Thickness = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 0, 24)
    label.Position = UDim2.fromOffset(12, 2)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s  %s", emoji or "📏", text)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = CurrentTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.fromOffset(65, 18)
    badge.Position = UDim2.new(1, -77, 0, 5)
    badge.BackgroundColor3 = CurrentTheme.SurfaceLight
    badge.Text = tostring(defaultVal) .. (suffix or "")
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 11
    badge.TextColor3 = CurrentTheme.Accent
    badge.Parent = frame
    Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local currentVal = defaultVal
    local fill = Instance.new("Frame")
    local initRatio = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundColor3 = CurrentTheme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.new(1, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = fill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isSliding = false
    local function updateValue(inputX)
        local trackAbsPos = track.AbsolutePosition.X
        local trackAbsSize = track.AbsoluteSize.X
        local ratio = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)
        currentVal = math.floor(minVal + (maxVal - minVal) * ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        badge.Text = tostring(currentVal) .. (suffix or "")
        if callback then
            task.spawn(callback, currentVal)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            updateValue(input.Position.X)
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(1, -9, 0.5, -9)
            }):Play()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and isSliding then
            isSliding = false
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(1, -7, 0.5, -7)
            }):Play()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input.Position.X)
        end
    end)

    return {
        Set = function(v)
            currentVal = math.clamp(v, minVal, maxVal)
            local r = (currentVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(r, 0, 1, 0)
            badge.Text = tostring(currentVal) .. (suffix or "")
            if callback then callback(currentVal) end
        end,
        Get = function() return currentVal end,
    }
end

-- Action Button
local function CreateButton(parent, text, emoji, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = CurrentTheme.SurfaceLight
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local bStroke = Instance.new("UIStroke", btn)
    bStroke.Color = CurrentTheme.Border
    bStroke.Thickness = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s  %s", emoji or "🚀", text)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = CurrentTheme.Text
    label.Parent = btn

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0.97, 0, 0, 34),
            BackgroundColor3 = CurrentTheme.Accent
        }):Play()
        label.TextColor3 = Color3.new(1, 1, 1)
    end)

    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = CurrentTheme.SurfaceLight
        }):Play()
        label.TextColor3 = CurrentTheme.Text
        if callback then task.spawn(callback) end
    end)

    return btn
end

-- Dropdown
local function CreateDropdown(parent, text, emoji, options, defaultOption, callback)
    local isExpanded = false
    local selectedOption = defaultOption or options[1] or ""

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundColor3 = CurrentTheme.Surface
    container.BackgroundTransparency = 0.35
    container.ClipsDescendants = true
    container.Parent = parent

    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local cStroke = Instance.new("UIStroke", container)
    cStroke.Color = CurrentTheme.Border
    cStroke.Thickness = 1

    local headerBtn = Instance.new("TextButton")
    headerBtn.Size = UDim2.new(1, 0, 0, 38)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s  %s", emoji or "📋", text)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextColor3 = CurrentTheme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = headerBtn

    local selBadge = Instance.new("TextLabel")
    selBadge.Size = UDim2.fromOffset(85, 22)
    selBadge.Position = UDim2.new(1, -120, 0.5, -11)
    selBadge.BackgroundColor3 = CurrentTheme.SurfaceLight
    selBadge.Text = selectedOption
    selBadge.Font = Enum.Font.GothamBold
    selBadge.TextSize = 11
    selBadge.TextColor3 = CurrentTheme.Accent
    selBadge.Parent = headerBtn
    Instance.new("UICorner", selBadge).CornerRadius = UDim.new(0, 6)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.fromOffset(24, 38)
    arrow.Position = UDim2.new(1, -30, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 11
    arrow.TextColor3 = CurrentTheme.TextDim
    arrow.Parent = headerBtn

    local optList = Instance.new("Frame")
    optList.Size = UDim2.new(1, 0, 0, #options * 32)
    optList.Position = UDim2.fromOffset(0, 38)
    optList.BackgroundTransparency = 1
    optList.Parent = container

    local optLayout = Instance.new("UIListLayout")
    optLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optLayout.Parent = optList

    local function toggleDropdown()
        isExpanded = not isExpanded
        local targetHeight = isExpanded and (38 + #options * 32 + 4) or 38
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        }):Play()
        TweenService:Create(arrow, TweenInfo.new(0.25), {
            Rotation = isExpanded and 180 or 0
        }):Play()
    end

    headerBtn.MouseButton1Click:Connect(toggleDropdown)

    for _, opt in ipairs(options) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = CurrentTheme.SurfaceLight
        row.BackgroundTransparency = 1
        row.Text = ""
        row.Parent = optList

        local optText = Instance.new("TextLabel")
        optText.Size = UDim2.new(1, -24, 1, 0)
        optText.Position = UDim2.fromOffset(20, 0)
        optText.BackgroundTransparency = 1
        optText.Text = (opt == selectedOption and "● " or "○ ") .. opt
        optText.Font = Enum.Font.GothamMedium
        optText.TextSize = 12
        optText.TextColor3 = (opt == selectedOption and CurrentTheme.Accent or CurrentTheme.TextDim)
        optText.TextXAlignment = Enum.TextXAlignment.Left
        optText.Parent = row

        row.MouseButton1Click:Connect(function()
            selectedOption = opt
            selBadge.Text = opt
            toggleDropdown()
            for _, child in ipairs(optList:GetChildren()) do
                if child:IsA("TextButton") then
                    local t = child:FindFirstChildOfClass("TextLabel")
                    if t then
                        local isSel = (string.find(t.Text, opt, 1, true) ~= nil)
                        t.Text = (isSel and "● " or "○ ") .. string.gsub(t.Text, "^[●○]%s*", "")
                        t.TextColor3 = isSel and CurrentTheme.Accent or CurrentTheme.TextDim
                    end
                end
            end
            if callback then task.spawn(callback, opt) end
        end)
    end

    return container
end

-- Mobile Draggable Floating Button
local FloatBtn = Instance.new("ImageButton")
FloatBtn.Name = "DropperHub_FloatingBtn"
FloatBtn.Size = UDim2.fromOffset(46, 46)
FloatBtn.Position = UDim2.new(0, 16, 0.5, -23)
FloatBtn.BackgroundColor3 = CurrentTheme.Accent
FloatBtn.AutoButtonColor = false
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)

local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = Color3.new(1, 1, 1)
fbStroke.Thickness = 1.5

local fbIcon = Instance.new("TextLabel")
fbIcon.Size = UDim2.new(1, 0, 1, 0)
fbIcon.BackgroundTransparency = 1
fbIcon.Text = "💎"
fbIcon.TextSize = 22
fbIcon.Parent = FloatBtn

task.spawn(function()
    while FloatBtn.Parent do
        TweenService:Create(FloatBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(50, 50)
        }):Play()
        task.wait(1.4)
        TweenService:Create(FloatBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(46, 46)
        }):Play()
        task.wait(1.4)
    end
end)

local fbDragging = false
local fbDragStart, fbStartPos
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        fbDragging = true
        fbDragStart = input.Position
        fbStartPos = FloatBtn.Position
    end
end)

FloatBtn.InputChanged:Connect(function(input)
    if fbDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - fbDragStart
        FloatBtn.Position = UDim2.new(fbStartPos.X.Scale, fbStartPos.X.Offset + delta.X, fbStartPos.Y.Scale, fbStartPos.Y.Offset + delta.Y)
    end
end)

FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if fbDragging then
            local dist = (input.Position - fbDragStart).Magnitude
            if dist < 8 then
                MainWindow.Visible = not MainWindow.Visible
                if MainWindow.Visible then
                    MainWindow.Size = UDim2.fromOffset(500, 360)
                    MainWindow.BackgroundTransparency = 0.4
                    TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(630, 460),
                        BackgroundTransparency = 0
                    }):Play()
                end
            end
        end
        fbDragging = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(520, 380),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.2, function() MainWindow.Visible = false end)
    SendToast("Hub minimized. Tap the floating 💎 button to open!", "Info")
end)

MinBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
    SendToast("Hub minimized.", "Info")
end)

-- ═══════════════════════════════════════════════════════════
-- BUILD TABS & COMPREHENSIVE AUTO SYSTEMS
-- ═══════════════════════════════════════════════════════════

-- Dynamic Upgrades Engine (Loaded from ReplicatedStorage Shared Modules)
local SharedModules = ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("Shared", 10)
local UpgradesModule = SharedModules:WaitForChild("Upgrades", 10)
local DailyUpgradesModule = SharedModules:WaitForChild("DailyUpgrades", 10)
local UpgradeTreeModule = SharedModules:WaitForChild("UpgradeTree", 10)
local ReadingUpgradesModule = SharedModules:WaitForChild("ReadingUpgrades", 10)

local UpgradesData = {}
pcall(function() UpgradesData = require(UpgradesModule) end)

local DailyUpgradesData = {}
pcall(function() DailyUpgradesData = require(DailyUpgradesModule) end)

local UpgradeTreeData = {}
pcall(function() UpgradeTreeData = require(UpgradeTreeModule) end)

local ReadingUpgradesData = {}
pcall(function() ReadingUpgradesData = require(ReadingUpgradesModule) end)

-- Pre-indexed upgrade key tables for zero overhead during execution
local CategoryKeys = {}
for cat, info in pairs(UpgradesData) do
    if type(info) == "table" and type(info.Upgrades) == "table" then
        CategoryKeys[cat] = {}
        for upKey, _ in pairs(info.Upgrades) do
            table.insert(CategoryKeys[cat], upKey)
        end
    end
end

local DailyKeys = {}
if type(DailyUpgradesData) == "table" and type(DailyUpgradesData.Upgrades) == "table" then
    for k, _ in pairs(DailyUpgradesData.Upgrades) do
        table.insert(DailyKeys, k)
    end
end

local TreeKeys = {}
if type(UpgradeTreeData) == "table" then
    for k, _ in pairs(UpgradeTreeData) do
        table.insert(TreeKeys, k)
    end
end

local ReadingKeys = {}
if type(ReadingUpgradesData) == "table" and type(ReadingUpgradesData.Upgrades) == "table" then
    for k, _ in pairs(ReadingUpgradesData.Upgrades) do
        table.insert(ReadingKeys, k)
    end
end

-- TAB 1: 🏠 Main (Dropper & Coin Farm)
local tabMain = RegisterTab("Main", "🏠", 1)
local secAutoDrop = CreateSection(tabMain, "Dropper Automation", "💧")

CreateToggle(secAutoDrop, "Auto Click Main Dropper", "⚡", State.AutoDropper, function(val)
    State.AutoDropper = val
    SendToast(val and "Auto Dropper: ON" or "Auto Dropper: OFF", val and "Success" or "Warning")
end)

CreateToggle(secAutoDrop, "Auto Click Bronze Dropper", "🥉", State.AutoBronzeDropper, function(val)
    State.AutoBronzeDropper = val
    SendToast(val and "Auto Bronze Dropper: ON" or "Auto Bronze Dropper: OFF", val and "Success" or "Warning")
end)

CreateToggle(secAutoDrop, "Auto Collect Coins (Infinite Range Fix)", "🧲", State.AutoCollectCoins, function(val)
    State.AutoCollectCoins = val
    SendToast(val and "Auto Coins Vacuum: ACTIVE (Works from anywhere!)" or "Auto Coins Vacuum: OFF", val and "Success" or "Warning")
end)

CreateToggle(secAutoDrop, "Auto Claim Daily Rewards", "🎁", State.AutoClaimDaily, function(val)
    State.AutoClaimDaily = val
end)

CreateToggle(secAutoDrop, "Auto Claim Quests", "📜", State.AutoClaimQuests, function(val)
    State.AutoClaimQuests = val
end)

CreateToggle(secAutoDrop, "Auto Claim Achievements", "🏆", State.AutoClaimAchievements, function(val)
    State.AutoClaimAchievements = val
end)

CreateSlider(secAutoDrop, "Dropper Click Delay", "⏱️", 0.01, 0.5, State.ClickDelay, "s", function(val)
    State.ClickDelay = val
end)

-- TAB 2: ⚡ Auto Upgrades (Complete Dynamic Coverage!)
local tabUpgrades = RegisterTab("Upgrades", "⚡", 2)
local secMasterUp = CreateSection(tabUpgrades, "Master Auto Upgrades", "🌟")

CreateToggle(secMasterUp, "⚡ Auto Buy ALL Categories (Max)", "👑", State.AutoBuyAllUpgrades, function(val)
    State.AutoBuyAllUpgrades = val
    SendToast(val and "Master Auto Upgrades: ALL ACTIVE" or "Master Auto Upgrades: OFF", val and "Success" or "Warning")
end)

CreateButton(secMasterUp, "Buy Max All Categories Once", "💥", function()
    local totalBought = 0
    for cat, keys in pairs(CategoryKeys) do
        for _, upKey in ipairs(keys) do
            pcall(function()
                Remotes.Upgrade:FireServer(cat, upKey, true)
                Remotes.Upgrade:FireServer(cat, upKey, false)
            end)
            totalBought = totalBought + 1
        end
    end
    for _, k in ipairs(DailyKeys) do
        pcall(function() Remotes.DailyUpgrade:FireServer(k) end)
    end
    for _, k in ipairs(TreeKeys) do
        pcall(function() Remotes.TreeUpgrade:FireServer(k) end)
    end
    for _, k in ipairs(ReadingKeys) do
        pcall(function() Remotes.DepositUpgrade:FireServer(k) end)
    end
    SendToast("Upgraded Max on all boards & trees!", "Success")
end)

local secIndUp = CreateSection(tabUpgrades, "Specific Currency Upgrades", "🛒")

CreateToggle(secIndUp, "Auto Cash Upgrades", "💵", State.AutoCashUpgrades, function(val)
    State.AutoCashUpgrades = val
end)

CreateToggle(secIndUp, "Auto Rebirth Points Upgrades", "🔮", State.AutoRebirthUpgrades, function(val)
    State.AutoRebirthUpgrades = val
end)

CreateToggle(secIndUp, "Auto Bronze Upgrades", "🥉", State.AutoBronzeUpgrades, function(val)
    State.AutoBronzeUpgrades = val
end)

CreateToggle(secIndUp, "Auto Diamonds Upgrades", "💎", State.AutoDiamondsUpgrades, function(val)
    State.AutoDiamondsUpgrades = val
end)

CreateToggle(secIndUp, "Auto Coins Upgrades", "🪙", State.AutoCoinsUpgrades, function(val)
    State.AutoCoinsUpgrades = val
end)

CreateToggle(secIndUp, "Auto Other Currencies (Produce, Grain, etc.)", "🌾", State.AutoOtherCurrenciesUpgrades, function(val)
    State.AutoOtherCurrenciesUpgrades = val
end)

CreateToggle(secIndUp, "Auto Reading Upgrades", "📖", State.AutoReadingUpgrades, function(val)
    State.AutoReadingUpgrades = val
end)

CreateToggle(secIndUp, "Auto Tree Upgrades", "🌳", State.AutoTreeUpgrades, function(val)
    State.AutoTreeUpgrades = val
end)

CreateToggle(secIndUp, "Auto Daily Upgrades", "📅", State.AutoDailyUpgrades, function(val)
    State.AutoDailyUpgrades = val
end)

-- TAB 3: 🔄 Progression (Rebirth & Prestige)
local tabProg = RegisterTab("Progression", "🔄", 3)
local secProg = CreateSection(tabProg, "Rebirth & Advanced Tiers", "👑")

CreateToggle(secProg, "Auto Rebirth", "🔁", State.AutoRebirth, function(val)
    State.AutoRebirth = val
    SendToast(val and "Auto Rebirth: ON" or "Auto Rebirth: OFF", val and "Success" or "Warning")
end)

CreateToggle(secProg, "Auto Bronze Rebirth", "🥉", State.AutoBronzeRebirth, function(val)
    State.AutoBronzeRebirth = val
end)

CreateToggle(secProg, "Auto Prestige", "🌟", State.AutoPrestige, function(val)
    State.AutoPrestige = val
end)

CreateToggle(secProg, "Auto Ascend", "🚀", State.AutoAscend, function(val)
    State.AutoAscend = val
end)

CreateToggle(secProg, "Auto Crystalize", "💎", State.AutoCrystalize, function(val)
    State.AutoCrystalize = val
end)

CreateToggle(secProg, "Auto Power & Fire", "🔥", State.AutoFire, function(val)
    State.AutoFire = val
    State.AutoPower = val
end)

CreateToggle(secProg, "Auto Galactic & Supernova", "🌌", State.AutoGalactic, function(val)
    State.AutoGalactic = val
    State.AutoSupernova = val
end)

CreateToggle(secProg, "Auto Singularity & Black Hole", "🌀", State.AutoSingularity, function(val)
    State.AutoSingularity = val
    State.AutoBlackHole = val
end)

CreateToggle(secProg, "Auto Sacrifice", "🩸", State.AutoSacrifice, function(val)
    State.AutoSacrifice = val
end)

CreateToggle(secProg, "Auto Equip All Energy", "⚡", State.AutoEquipEnergy, function(val)
    State.AutoEquipEnergy = val
end)

CreateToggle(secProg, "Auto Max Shrine Deposit", "⛩️", State.AutoShrineDeposit, function(val)
    State.AutoShrineDeposit = val
end)

local secInstant = CreateSection(tabProg, "Instant Actions", "⚡")
CreateButton(secInstant, "Instant Rebirth Now", "✨", function()
    pcall(function() Remotes.Rebirth:FireServer() end)
    SendToast("Rebirth fired!", "Info")
end)

CreateButton(secInstant, "Instant Prestige Now", "👑", function()
    pcall(function() Remotes.Prestige:FireServer() end)
    SendToast("Prestige fired!", "Info")
end)

CreateButton(secInstant, "Instant Ascend Now", "🚀", function()
    pcall(function() Remotes.Ascend:FireServer() end)
    SendToast("Ascend fired!", "Info")
end)

-- TAB 4: ⚔️ Activities (Combat & Mining)
local tabAct = RegisterTab("Activities", "⚔️", 4)
local secCombat = CreateSection(tabAct, "Gathering & Mobs", "🌲")

CreateToggle(secCombat, "Auto Tree Chop / Logging", "🪓", State.AutoTreeChop, function(val)
    State.AutoTreeChop = val
    pcall(function() Remotes.ChoppingState:FireServer(val) end)
    SendToast(val and "Auto Tree Chop: ON" or "Auto Tree Chop: OFF", val and "Success" or "Warning")
end)

CreateToggle(secCombat, "Auto Mob Fight", "🗡️", State.AutoMobFight, function(val)
    State.AutoMobFight = val
    pcall(function() Remotes.FightingState:FireServer(val) end)
    SendToast(val and "Auto Mob Fight: ON" or "Auto Mob Fight: OFF", val and "Success" or "Warning")
end)

CreateToggle(secCombat, "Auto Rock Mining", "⛏️", State.AutoRockMining, function(val)
    State.AutoRockMining = val
    pcall(function() Remotes.RockAttackState:FireServer(val) end)
    SendToast(val and "Auto Rock Mining: ON" or "Auto Rock Mining: OFF", val and "Success" or "Warning")
end)

CreateButton(secCombat, "Hit Tree 25x", "🌲", function()
    for _ = 1, 25 do
        pcall(function() Remotes.TreeHit:FireServer() end)
        task.wait(0.03)
    end
    SendToast("Hit tree 25 times!", "Success")
end)

CreateButton(secCombat, "Attack Mob 25x", "💥", function()
    for _ = 1, 25 do
        pcall(function() Remotes.MobAttackMlt:FireServer() end)
        task.wait(0.03)
    end
    SendToast("Attacked mob 25 times!", "Success")
end)

-- TAB 5: 🌾 Farm & Ocean (Farming, Barn & Fishing)
local tabFarm = RegisterTab("Farm & Fish", "🌾", 5)
local secFarm = CreateSection(tabFarm, "Farm, Barn & Greenhouse", "🚜")

CreateToggle(secFarm, "Auto Farm Field", "🌱", State.AutoFarmHarvest, function(val)
    State.AutoFarmHarvest = val
end)

CreateToggle(secFarm, "Auto Barn", "🏡", State.AutoBarn, function(val)
    State.AutoBarn = val
end)

CreateToggle(secFarm, "Auto Greenhouse", "🌿", State.AutoGreenhouse, function(val)
    State.AutoGreenhouse = val
end)

CreateToggle(secFarm, "Auto Fruit Deposit", "🍎", State.AutoFruitDeposit, function(val)
    State.AutoFruitDeposit = val
end)

local secFish = CreateSection(tabFarm, "Ocean & Fishing", "🎣")

CreateToggle(secFish, "Auto Fishing & Reel", "🐟", State.AutoFishing, function(val)
    State.AutoFishing = val
end)

CreateToggle(secFish, "Auto Fish Market Sell", "💰", State.AutoFishMarket, function(val)
    State.AutoFishMarket = val
end)

CreateToggle(secFish, "Auto Collect Pearls", "🦪", State.AutoCollectPearls, function(val)
    State.AutoCollectPearls = val
end)

CreateToggle(secFish, "Auto Collect Ingots", "🪙", State.AutoCollectIngots, function(val)
    State.AutoCollectIngots = val
end)

CreateToggle(secFish, "Auto Collect Amber", "🪵", State.AutoCollectAmber, function(val)
    State.AutoCollectAmber = val
end)

CreateToggle(secFish, "Auto Debris Magnet", "🧲", State.AutoDebrisMagnet, function(val)
    State.AutoDebrisMagnet = val
end)

CreateToggle(secFish, "Auto Deliver Orders", "📦", State.AutoDeliverOrders, function(val)
    State.AutoDeliverOrders = val
end)

-- TAB 6: 🏃 Movement & Teleports
local tabMove = RegisterTab("Movement", "🏃", 6)
local secMove = CreateSection(tabMove, "Character Modifiers", "⚡")

CreateSlider(secMove, "WalkSpeed", "👟", 16, 300, State.WalkSpeed, "", function(val)
    State.WalkSpeed = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = val
        end
    end)
end)

CreateSlider(secMove, "JumpPower", "🦘", 50, 350, State.JumpPower, "", function(val)
    State.JumpPower = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = val
        end
    end)
end)

CreateToggle(secMove, "Infinite Jump", "🪽", State.InfiniteJump, function(val)
    State.InfiniteJump = val
    SendToast(val and "Infinite Jump: ON" or "Infinite Jump: OFF", "Info")
end)

CreateToggle(secMove, "Noclip", "👻", State.Noclip, function(val)
    State.Noclip = val
    SendToast(val and "Noclip: ON" or "Noclip: OFF", "Info")
end)

local secTP = CreateSection(tabMove, "Quick Teleports", "📍")
local function tpTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
        SendToast("Teleported successfully!", "Success")
    end
end

CreateButton(secTP, "Teleport to Spawn", "🏠", function()
    local sp = workspace:FindFirstChild("SpawnLocation")
    if sp then tpTo(sp.CFrame + Vector3.new(0, 3, 0)) end
end)

CreateButton(secTP, "Teleport to Main Dropper", "💧", function()
    local d = workspace:FindFirstChild("MapEssentials") and workspace.MapEssentials:FindFirstChild("Droppers")
    if d then
        local p = d:FindFirstChildWhichIsA("Model") or d:FindFirstChildWhichIsA("BasePart")
        if p then tpTo(p:GetPivot() + Vector3.new(0, 4, 0)) end
    end
end)

CreateButton(secTP, "Teleport to Tree (Logging)", "🌲", function()
    local tr = workspace:FindFirstChild("Worlds") and workspace.Worlds:FindFirstChild("Tree")
    if tr then tpTo(tr:GetPivot() + Vector3.new(0, 4, 0)) end
end)

-- TAB 7: ⚙️ Settings
local tabSet = RegisterTab("Settings", "⚙️", 7)
local secTheme = CreateSection(tabSet, "Visual Theme", "🎨")

local themeNames = {"🌙 Midnight", "🌸 Sakura", "💚 Matcha", "🔥 Ember", "💎 Ice", "🖤 AMOLED"}
CreateDropdown(secTheme, "Select Theme", "🎭", themeNames, CurrentThemeName, function(selected)
    if Themes[selected] then
        CurrentThemeName = selected
        CurrentTheme = Themes[selected]
        
        MainWindow.BackgroundColor3 = CurrentTheme.Background
        Topbar.BackgroundColor3 = CurrentTheme.Surface
        Sidebar.BackgroundColor3 = CurrentTheme.Surface
        mainStroke.Color = CurrentTheme.Border
        TopbarLine.BackgroundColor3 = CurrentTheme.Border
        SidebarBorder.BackgroundColor3 = CurrentTheme.Border
        FloatBtn.BackgroundColor3 = CurrentTheme.Accent
        TitleLabel.TextColor3 = CurrentTheme.Text
        Watermark.BackgroundColor3 = CurrentTheme.Surface
        wmStroke.Color = CurrentTheme.Border
        
        SendToast("Theme changed to " .. selected, "Success")
    end
end)

local secControls = CreateSection(tabSet, "Script Controls", "🛠️")

CreateButton(secControls, "Unload Script Hub", "🗑️", function()
    SendToast("Unloading Hub...", "Warning")
    task.wait(0.5)
    if typeof(getgenv().DropperHubCleanup) == "function" then
        getgenv().DropperHubCleanup()
    end
end)

-- Initialize Default Tab Cleanly
if Tabs["Main"] and Tabs["Main"].Select then
    Tabs["Main"].Select()
end

-- ═══════════════════════════════════════════════════════════
-- BACKGROUND LOOPS & AUTO ENGINE
-- ═══════════════════════════════════════════════════════════

-- 1. Auto Dropper Loop
task.spawn(function()
    while ScreenGui.Parent do
        if State.AutoDropper then
            pcall(function() Remotes.DropperClick:FireServer() end)
        end
        if State.AutoBronzeDropper then
            pcall(function() Remotes.BronzeDropperClick:FireServer() end)
        end
        task.wait(State.ClickDelay or 0.05)
    end
end)

-- 2. DUAL-ENGINE TRUE INFINITE-RANGE AUTO COIN & VACUUM (Works from any distance & any world!)
task.spawn(function()
    local lastServerSync = 0
    while ScreenGui.Parent do
        if State.AutoCollectCoins then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local spawned = MapEssentials:FindFirstChild("Spawned")
                
                -- Expand internal RangeObject
                local ro = MapEssentials:FindFirstChild("RangeObject")
                if ro and hrp then
                    local myRange = ro:FindFirstChild(LocalPlayer.Name .. "'s range")
                    if myRange then
                        myRange.Size = Vector3.new(0.2, 5000, 5000)
                    end
                end

                -- Engine A: Local Visual Vacuum (Collects parts in workspace and brings them to player)
                if spawned then
                    local children = spawned:GetChildren()
                    for i = 1, #children do
                        local part = children[i]
                        if part:IsA("BasePart") and not part:GetAttribute("PickedUp") then
                            part:SetAttribute("PickedUp", true)
                            Remotes.CollectPart:FireServer(part.Name)
                            Remotes.CollectPart:FireServer(part.Name, true)
                            if hrp then
                                part.CFrame = hrp.CFrame
                            end
                            part.Transparency = 0.7
                        end
                    end
                end

                -- Engine B: Server Master Sync (Sweeps all server-spawned coins directly every 0.35s)
                local now = os.clock()
                if now - lastServerSync >= 0.35 then
                    lastServerSync = now
                    task.spawn(function()
                        pcall(function()
                            local active = Remotes.Collectible:InvokeServer()
                            if type(active) == "table" then
                                for coinId, _ in pairs(active) do
                                    Remotes.CollectPart:FireServer(coinId)
                                    Remotes.CollectPart:FireServer(coinId, true)
                                end
                            end
                        end)
                    end)
                end
            end)
        end
        task.wait(0.12)
    end
end)

-- 3. Comprehensive Auto Upgrades Loop (All 18 Categories + Tree + Daily + Reading)
task.spawn(function()
    while ScreenGui.Parent do
        -- Master Auto Buy All
        if State.AutoBuyAllUpgrades then
            pcall(function()
                for cat, keys in pairs(CategoryKeys) do
                    for _, upKey in ipairs(keys) do
                        Remotes.Upgrade:FireServer(cat, upKey, true)
                        Remotes.Upgrade:FireServer(cat, upKey, false)
                    end
                end
                for _, k in ipairs(DailyKeys) do
                    Remotes.DailyUpgrade:FireServer(k)
                end
                for _, k in ipairs(TreeKeys) do
                    Remotes.TreeUpgrade:FireServer(k)
                end
                for _, k in ipairs(ReadingKeys) do
                    Remotes.DepositUpgrade:FireServer(k)
                end
            end)
        else
            -- Individual Category Upgrades
            if State.AutoCashUpgrades and CategoryKeys["Cash"] then
                pcall(function()
                    for _, upKey in ipairs(CategoryKeys["Cash"]) do
                        Remotes.Upgrade:FireServer("Cash", upKey, true)
                        Remotes.Upgrade:FireServer("Cash", upKey, false)
                    end
                end)
            end
            if State.AutoRebirthUpgrades and CategoryKeys["RebirthPoints"] then
                pcall(function()
                    for _, upKey in ipairs(CategoryKeys["RebirthPoints"]) do
                        Remotes.Upgrade:FireServer("RebirthPoints", upKey, true)
                        Remotes.Upgrade:FireServer("RebirthPoints", upKey, false)
                    end
                end)
            end
            if State.AutoBronzeUpgrades then
                pcall(function()
                    if CategoryKeys["Bronze"] then
                        for _, upKey in ipairs(CategoryKeys["Bronze"]) do
                            Remotes.Upgrade:FireServer("Bronze", upKey, true)
                            Remotes.Upgrade:FireServer("Bronze", upKey, false)
                        end
                    end
                    if CategoryKeys["BronzeRebirthPoints"] then
                        for _, upKey in ipairs(CategoryKeys["BronzeRebirthPoints"]) do
                            Remotes.Upgrade:FireServer("BronzeRebirthPoints", upKey, true)
                            Remotes.Upgrade:FireServer("BronzeRebirthPoints", upKey, false)
                        end
                    end
                end)
            end
            if State.AutoDiamondsUpgrades and CategoryKeys["Diamonds"] then
                pcall(function()
                    for _, upKey in ipairs(CategoryKeys["Diamonds"]) do
                        Remotes.Upgrade:FireServer("Diamonds", upKey, true)
                        Remotes.Upgrade:FireServer("Diamonds", upKey, false)
                    end
                end)
            end
            if State.AutoCoinsUpgrades and CategoryKeys["Coins"] then
                pcall(function()
                    for _, upKey in ipairs(CategoryKeys["Coins"]) do
                        Remotes.Upgrade:FireServer("Coins", upKey, true)
                        Remotes.Upgrade:FireServer("Coins", upKey, false)
                    end
                end)
            end
            if State.AutoOtherCurrenciesUpgrades then
                pcall(function()
                    local others = {"Produce", "Grain", "Paper", "Rocks", "Scrap", "Bones", "Amber", "DarkMatter", "Gravitons", "Ingots", "Pearls", "Stardust"}
                    for _, cat in ipairs(others) do
                        if CategoryKeys[cat] then
                            for _, upKey in ipairs(CategoryKeys[cat]) do
                                Remotes.Upgrade:FireServer(cat, upKey, true)
                                Remotes.Upgrade:FireServer(cat, upKey, false)
                            end
                        end
                    end
                end)
            end
            if State.AutoReadingUpgrades then
                pcall(function()
                    for _, k in ipairs(ReadingKeys) do
                        Remotes.DepositUpgrade:FireServer(k)
                    end
                end)
            end
            if State.AutoTreeUpgrades then
                pcall(function()
                    for _, k in ipairs(TreeKeys) do
                        Remotes.TreeUpgrade:FireServer(k)
                    end
                end)
            end
            if State.AutoDailyUpgrades then
                pcall(function()
                    for _, k in ipairs(DailyKeys) do
                        Remotes.DailyUpgrade:FireServer(k)
                    end
                end)
            end
        end

        task.wait(0.4)
    end
end)

-- 4. Auto Progression (Rebirth, Prestige, Ascension, Cosmic)
task.spawn(function()
    while ScreenGui.Parent do
        if State.AutoRebirth then
            pcall(function() Remotes.Rebirth:FireServer() end)
        end
        if State.AutoBronzeRebirth then
            pcall(function() Remotes.BronzeRebirth:FireServer() end)
        end
        if State.AutoPrestige then
            pcall(function() Remotes.Prestige:FireServer() end)
        end
        if State.AutoAscend then
            pcall(function() Remotes.Ascend:FireServer() end)
        end
        if State.AutoCrystalize then
            pcall(function() Remotes.Crystalize:FireServer() end)
        end
        if State.AutoPower then
            pcall(function() Remotes.Power:FireServer() end)
        end
        if State.AutoFire then
            pcall(function() Remotes.Fire:FireServer() end)
        end
        if State.AutoGalactic then
            pcall(function() Remotes.Galactic:FireServer() end)
        end
        if State.AutoSupernova then
            pcall(function() Remotes.Supernova:FireServer() end)
        end
        if State.AutoSingularity then
            pcall(function() Remotes.Singularity:FireServer() end)
        end
        if State.AutoBlackHole then
            pcall(function() Remotes.BlackHole:FireServer() end)
        end
        if State.AutoSacrifice then
            pcall(function() Remotes.Sacrifice:FireServer() end)
        end
        if State.AutoEquipEnergy then
            pcall(function() Remotes.EquipAllEnergy:FireServer() end)
        end
        if State.AutoShrineDeposit then
            pcall(function()
                local stats = {"Cash", "RebirthPoints", "Bronze", "Diamonds", "Coins", "Produce", "Grain"}
                for _, s in ipairs(stats) do
                    Remotes.ShrineDeposit:FireServer(s, true)
                end
            end)
        end
        task.wait(0.8)
    end
end)

-- 5. Auto Activities (Tree, Mobs, Rock Mining)
task.spawn(function()
    while ScreenGui.Parent do
        if State.AutoTreeChop then
            pcall(function()
                Remotes.ChoppingState:FireServer(true)
                Remotes.TreeHit:FireServer()
                Remotes.AutoTreeHit:FireServer()
            end)
        end
        if State.AutoMobFight then
            pcall(function()
                Remotes.FightingState:FireServer(true)
                Remotes.MobAttackMlt:FireServer()
                Remotes.EnemySwing:FireServer()
            end)
        end
        if State.AutoRockMining then
            pcall(function()
                Remotes.RockAttackState:FireServer(true)
                Remotes.RockSwing:FireServer()
            end)
        end
        task.wait(0.12)
    end
end)

-- 6. Auto Farm, Barn, Ocean & Fishing
task.spawn(function()
    while ScreenGui.Parent do
        if State.AutoFarmHarvest then
            pcall(function() Remotes.Farm:FireServer() end)
        end
        if State.AutoBarn then
            pcall(function() Remotes.Barn:FireServer() end)
        end
        if State.AutoGreenhouse then
            pcall(function() Remotes.Greenhouse:FireServer() end)
        end
        if State.AutoFruitDeposit then
            pcall(function() Remotes.FruitDeposit:FireServer() end)
        end
        if State.AutoFishing then
            pcall(function()
                Remotes.Fishing:FireServer()
                Remotes.RodAction:FireServer()
            end)
        end
        if State.AutoFishMarket then
            pcall(function() Remotes.FishMarket:FireServer() end)
        end
        if State.AutoCollectPearls then
            pcall(function() Remotes.CollectPearls:FireServer() end)
        end
        if State.AutoCollectIngots then
            pcall(function() Remotes.CollectIngots:FireServer() end)
        end
        if State.AutoCollectAmber then
            pcall(function() Remotes.CollectAmber:FireServer() end)
        end
        if State.AutoDebrisMagnet then
            pcall(function() Remotes.DebrisMagnet:FireServer(1, 1) end)
        end
        if State.AutoDeliverOrders then
            pcall(function() Remotes.Orders:FireServer("Deliver", 1) end)
        end
        task.wait(0.5)
    end
end)

-- 7. Auto Daily, Quests & Achievements
task.spawn(function()
    while ScreenGui.Parent do
        if State.AutoClaimDaily then
            pcall(function() Remotes.ClaimDaily:FireServer() end)
        end
        if State.AutoClaimQuests then
            pcall(function()
                for i = 1, 5 do
                    Remotes.ClaimQuest:FireServer(i)
                end
            end)
        end
        if State.AutoClaimAchievements then
            pcall(function()
                for i = 1, 20 do
                    Remotes.Achievement:FireServer(i)
                end
            end)
        end
        task.wait(10)
    end
end)

-- 8. Player Movement Modifiers
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if State.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.WalkSpeed then
            hum.WalkSpeed = State.WalkSpeed
        end
        if State.JumpPower ~= 50 and hum.JumpPower ~= State.JumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPower
        end
    end
end)

-- Cleanup Handler
getgenv().DropperHubLoaded = true
getgenv().DropperHubCleanup = function()
    getgenv().DropperHubLoaded = false
    ScreenGui:Destroy()
end

SendToast("💎 Dropper Incremental Ultimate Hub Loaded!", "Success")
print("[DropperHub] Ultimate Hub Loaded.")
