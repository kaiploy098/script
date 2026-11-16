--[[
    ═══════════════════════════════════════════════════════════════
    ✨ +1 GUN FORGE — PRETTY & POLISHED SCRIPT HUB (V2.2 MASTER) ✨
    ═══════════════════════════════════════════════════════════════
    FEATURES:
    - 🌟 Master Auto Farm (True Full-AFK God Mode)
      * Auto locks and rapid fires with zero gun jamming
      * Auto advances through stages (Stage 1 -> 69+)
      * Auto respawn recovery (never gets stuck in lobby)
      * Instant scrap/drop harvester & magnet
    - 🗺️ Manual Stage Teleporter (Stages 1-69)
    - 🔨 Auto Forge & Gun Upgrades
    - 🎁 Auto Claim Free Gifts & Wheel Spins
    - 👤 Player Mods (Speed, Jump, Inf Jump, Fly, Noclip, Invisibility)
    - 👁️ Visuals & ESP (Chams Highlight, Fullbright, FOV)
    - 🎨 5 Aesthetic Themes + Mobile Floating Button
    ═══════════════════════════════════════════════════════════════
--]]

-- [0] Lifecycle Cleanup
if _G.GunForgeHub and typeof(_G.GunForgeHub.Destroy) == "function" then
    pcall(function() _G.GunForgeHub:Destroy() end)
end

local Hub = {
    Connections = {},
    Loops = {},
    ESPObjects = {},
    Cleanups = {},
    Active = true
}
_G.GunForgeHub = Hub

-- [1] Core Services & Controllers
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Game Controllers & Remotes
local PlusPlus = ReplicatedStorage:WaitForChild("PlusPlus", 10)
local Remotes = PlusPlus and PlusPlus:WaitForChild("Remotes", 10)
local Controllers = PlusPlus and PlusPlus:WaitForChild("Client", 10) and PlusPlus.Client:WaitForChild("Controllers", 10)

local FireController = Controllers and require(Controllers:WaitForChild("FireController", 5))
local ClientState = Controllers and require(Controllers:WaitForChild("ClientState", 5))
local AimAssistController = Controllers and require(Controllers:WaitForChild("AimAssistController", 5))
local GunOrbitController = Controllers and require(Controllers:WaitForChild("GunOrbitController", 5))
local GunView = Controllers and require(Controllers:WaitForChild("GunView", 5))
local AmmoController = Controllers and require(Controllers:WaitForChild("AmmoController", 5))
local LootController = Controllers and require(Controllers:WaitForChild("LootController", 5))

-- 360° Silent Aim & Headlock Hooks
local origGunViewAligned = GunView and GunView.Aligned
local origGunOrbitAligned = GunOrbitController and GunOrbitController.Aligned
local origAimAssistCurrent = AimAssistController and AimAssistController.Current

local function ApplySilentAimHooks()
    if GunView then
        GunView.Aligned = function(...) return true end
    end
    if GunOrbitController then
        GunOrbitController.Aligned = function(...) return true end
    end
end

local function RestoreSilentAimHooks()
    if GunView and origGunViewAligned then
        GunView.Aligned = origGunViewAligned
    end
    if GunOrbitController and origGunOrbitAligned then
        GunOrbitController.Aligned = origGunOrbitAligned
    end
    if AimAssistController and origAimAssistCurrent then
        AimAssistController.Current = origAimAssistCurrent
    end
end

local LockedTargetData = nil

if AimAssistController then
    AimAssistController.Current = function(...)
        if Hub.Active and _G.GunForgeHub_AutoShootActive and LockedTargetData then
            return LockedTargetData
        end
        if origAimAssistCurrent then
            return origAimAssistCurrent(...)
        end
        return nil
    end
end

local RequestCollect = Remotes and Remotes:FindFirstChild("RequestCollect")
local RequestSell = Remotes and Remotes:FindFirstChild("RequestSell")
local RequestForge = Remotes and Remotes:FindFirstChild("RequestForge")
local RequestUpgrade = Remotes and Remotes:FindFirstChild("RequestUpgrade")
local RequestRebirth = Remotes and Remotes:FindFirstChild("RequestRebirth")
local RequestClaimDaily = Remotes and Remotes:FindFirstChild("RequestClaimDaily")
local RequestClaimOffline = Remotes and Remotes:FindFirstChild("RequestClaimOffline")
local RequestSpin = Remotes and Remotes:FindFirstChild("RequestSpin")
local RequestBarrelSpin = Remotes and Remotes:FindFirstChild("RequestBarrelSpin")
local RequestCode = Remotes and Remotes:FindFirstChild("RequestCode")
local RequestReturnHub = Remotes and Remotes:FindFirstChild("RequestReturnHub")
local RequestStageWarp = Remotes and Remotes:FindFirstChild("RequestStageWarp")

-- Scrap & Bag State Helpers
local function GetCarriedScrapCount()
    local data = ClientState and ClientState.Data
    local carried = data and data.CarriedScrap
    local count = 0
    if carried and type(carried) == "table" then
        for _, v in pairs(carried) do
            if type(v) == "number" then
                count = count + v
            end
        end
    end
    return count
end

local function GetCarryCap()
    local data = ClientState and ClientState.Data
    local derived = data and data.Derived
    return (derived and derived.CarryCap) or 50
end

local function IsBagFull()
    local cap = GetCarryCap()
    if cap <= 0 then return false end
    return GetCarriedScrapCount() >= math.max(1, cap - 2)
end

local function SellAllScrap()
    if RequestSell then
        RequestSell:FireServer(nil)
        return true
    end
    return false
end

-- Helper Functions
local function GetStageFloor(stageNum)
    local stages = Workspace:FindFirstChild("Stages")
    local stage = stages and stages:FindFirstChild("Stage" .. tostring(stageNum))
    return stage and stage:FindFirstChild("Floor")
end

local function WarpToStage(stageNum)
    local floor = GetStageFloor(stageNum)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if floor and hrp then
        hrp.CFrame = CFrame.new(floor.Position + Vector3.new(0, 4, 0))
        return true
    end
    return false
end

-- [2] Theme Presets
local Themes = {
    ["🌙 Midnight"] = {
        Background   = Color3.fromRGB(15, 15, 25),
        Surface      = Color3.fromRGB(24, 24, 38),
        SurfaceHover = Color3.fromRGB(34, 34, 52),
        Accent       = Color3.fromRGB(135, 105, 255),
        AccentGlow   = Color3.fromRGB(165, 135, 255),
        Text         = Color3.fromRGB(240, 240, 250),
        TextDim      = Color3.fromRGB(145, 145, 175),
        Border       = Color3.fromRGB(45, 45, 70),
    },
    ["🌸 Sakura"] = {
        Background   = Color3.fromRGB(25, 18, 22),
        Surface      = Color3.fromRGB(38, 26, 33),
        SurfaceHover = Color3.fromRGB(50, 34, 44),
        Accent       = Color3.fromRGB(255, 130, 175),
        AccentGlow   = Color3.fromRGB(255, 165, 200),
        Text         = Color3.fromRGB(250, 235, 240),
        TextDim      = Color3.fromRGB(175, 145, 160),
        Border       = Color3.fromRGB(70, 45, 60),
    },
    ["💚 Matcha"] = {
        Background   = Color3.fromRGB(18, 25, 18),
        Surface      = Color3.fromRGB(28, 40, 30),
        SurfaceHover = Color3.fromRGB(38, 55, 40),
        Accent       = Color3.fromRGB(100, 230, 140),
        AccentGlow   = Color3.fromRGB(130, 245, 165),
        Text         = Color3.fromRGB(235, 248, 238),
        TextDim      = Color3.fromRGB(145, 175, 150),
        Border       = Color3.fromRGB(45, 70, 50),
    },
    ["💎 Ice"] = {
        Background   = Color3.fromRGB(12, 18, 28),
        Surface      = Color3.fromRGB(20, 32, 48),
        SurfaceHover = Color3.fromRGB(28, 44, 66),
        Accent       = Color3.fromRGB(80, 185, 255),
        AccentGlow   = Color3.fromRGB(125, 210, 255),
        Text         = Color3.fromRGB(230, 242, 255),
        TextDim      = Color3.fromRGB(135, 155, 185),
        Border       = Color3.fromRGB(40, 65, 95),
    },
    ["🖤 AMOLED"] = {
        Background   = Color3.fromRGB(8, 8, 8),
        Surface      = Color3.fromRGB(18, 18, 18),
        SurfaceHover = Color3.fromRGB(28, 28, 28),
        Accent       = Color3.fromRGB(220, 220, 220),
        AccentGlow   = Color3.fromRGB(255, 255, 255),
        Text         = Color3.fromRGB(255, 255, 255),
        TextDim      = Color3.fromRGB(130, 130, 130),
        Border       = Color3.fromRGB(40, 40, 40),
    }
}

local CurrentThemeName = "🌙 Midnight"
local CurrentTheme = Themes[CurrentThemeName]

local FONT_TITLE  = Font.fromEnum(Enum.Font.GothamBold)
local FONT_HEADER = Font.fromEnum(Enum.Font.GothamMedium)
local FONT_BODY   = Font.fromEnum(Enum.Font.Gotham)
local FONT_SMALL  = Font.fromEnum(Enum.Font.GothamMedium)

local SIZES = {
    Title = 16,
    Header = 14,
    Body = 12,
    Small = 11,
}

-- [3] Protected GUI Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GunForgeHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local targetParent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if gethui then
    targetParent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    targetParent = CoreGui
elseif CoreGui then
    pcall(function() targetParent = CoreGui end)
end
ScreenGui.Parent = targetParent

function Hub:Destroy()
    Hub.Active = false
    _G.GunForgeHub_AutoShootActive = false
    LockedTargetData = nil
    RestoreSilentAimHooks()
    if Hub.Cleanups then
        for _, cleanup in ipairs(Hub.Cleanups) do
            pcall(cleanup)
        end
    end
    if FireController then
        pcall(function()
            FireController.SetHolding(false)
            FireController.SetAutoFarm(false)
            FireController.SetForcedTarget(nil, 0)
        end)
    end
    for _, conn in ipairs(Hub.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, esp in pairs(Hub.ESPObjects) do
        pcall(function() esp:Destroy() end)
    end
    pcall(function() ScreenGui:Destroy() end)
    _G.GunForgeHub = nil
end

-- [4] Toast Notification System
local ToastContainer = Instance.new("Frame")
ToastContainer.Name = "ToastContainer"
ToastContainer.Size = UDim2.new(0, 280, 1, -20)
ToastContainer.Position = UDim2.new(1, -290, 0, 10)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui

local ToastListLayout = Instance.new("UIListLayout")
ToastListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ToastListLayout.Padding = UDim.new(0, 8)
ToastListLayout.Parent = ToastContainer

local function Notify(text, emoji, colorOverride)
    local theme = CurrentTheme
    local accent = colorOverride or theme.Accent
    emoji = emoji or "✨"

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 42)
    toast.BackgroundColor3 = theme.Surface
    toast.BackgroundTransparency = 0.1
    toast.BorderSizePixel = 0
    toast.Parent = ToastContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Border
    stroke.Thickness = 1
    stroke.Parent = toast

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -12)
    bar.Position = UDim2.new(0, 6, 0, 6)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Parent = toast
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 24, 1, 0)
    icon.Position = UDim2.new(0, 16, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = emoji
    icon.TextSize = 16
    icon.FontFace = FONT_BODY
    icon.Parent = toast

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -50, 1, 0)
    msg.Position = UDim2.new(0, 44, 0, 0)
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.TextColor3 = theme.Text
    msg.TextSize = SIZES.Body
    msg.FontFace = FONT_BODY
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextTruncate = Enum.TextTruncate.AtEnd
    msg.Parent = toast

    toast.Position = UDim2.new(1, 40, 0, 0)
    TweenService:Create(toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(3, function()
        if toast.Parent then
            local dismissTween = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, 0),
                BackgroundTransparency = 1
            })
            dismissTween:Play()
            dismissTween.Completed:Connect(function() toast:Destroy() end)
        end
    end)
end

-- [5] Top Watermark Bar
local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 370, 0, 26)
Watermark.Position = UDim2.new(0.5, -185, 0, 8)
Watermark.BackgroundColor3 = CurrentTheme.Background
Watermark.BackgroundTransparency = 0.35
Watermark.BorderSizePixel = 0
Watermark.Parent = ScreenGui

Instance.new("UICorner", Watermark).CornerRadius = UDim.new(1, 0)
local wmStroke = Instance.new("UIStroke")
wmStroke.Color = CurrentTheme.Border
wmStroke.Thickness = 1
wmStroke.Parent = Watermark

local wmLabel = Instance.new("TextLabel")
wmLabel.Size = UDim2.new(1, 0, 1, 0)
wmLabel.BackgroundTransparency = 1
wmLabel.FontFace = FONT_SMALL
wmLabel.TextSize = SIZES.Small
wmLabel.TextColor3 = CurrentTheme.TextDim
wmLabel.Text = "✨ +1 Gun Forge Hub v2.2  │  🕐 --:--:--  │  📶 --ms  │  🖥️ --fps"
wmLabel.Parent = Watermark

task.spawn(function()
    local lastTime = tick()
    local frameCount = 0
    local fps = 60

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            fps = math.floor(frameCount / (now - lastTime))
            frameCount = 0
            lastTime = now

            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            local clock = os.date("%H:%M:%S")

            wmLabel.Text = string.format("✨ +1 Gun Forge Hub v2.2  │  🕐 %s  │  📶 %dms  │  🖥️ %dfps", clock, ping, fps)
        end
    end)
end)

-- [6] Main Window Frame
local DEFAULT_POS = UDim2.new(0.5, -280, 0.5, -210)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(560, 420)
MainFrame.Position = DEFAULT_POS
MainFrame.BackgroundColor3 = CurrentTheme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = CurrentTheme.Border
mainStroke.Thickness = 1.2
mainStroke.Parent = MainFrame

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.BackgroundColor3 = CurrentTheme.Surface
Topbar.BorderSizePixel = 0
Topbar.Parent = MainFrame

Instance.new("UICorner", Topbar).CornerRadius = UDim.new(0, 14)
local topbarFix = Instance.new("Frame")
topbarFix.Size = UDim2.new(1, 0, 0, 10)
topbarFix.Position = UDim2.new(0, 0, 1, -10)
topbarFix.BackgroundColor3 = CurrentTheme.Surface
topbarFix.BorderSizePixel = 0
topbarFix.Parent = Topbar

local AppIcon = Instance.new("TextLabel")
AppIcon.Size = UDim2.new(0, 32, 1, 0)
AppIcon.Position = UDim2.new(0, 12, 0, 0)
AppIcon.BackgroundTransparency = 1
AppIcon.Text = "⚔️"
AppIcon.TextSize = 20
AppIcon.FontFace = FONT_TITLE
AppIcon.Parent = Topbar

local AppTitle = Instance.new("TextLabel")
AppTitle.Size = UDim2.new(0, 200, 1, 0)
AppTitle.Position = UDim2.new(0, 44, 0, 0)
AppTitle.BackgroundTransparency = 1
AppTitle.Text = "+1 Gun Forge Hub"
AppTitle.TextColor3 = CurrentTheme.Text
AppTitle.TextSize = SIZES.Title
AppTitle.FontFace = FONT_TITLE
AppTitle.TextXAlignment = Enum.TextXAlignment.Left
AppTitle.Parent = Topbar

local VersionBadge = Instance.new("TextLabel")
VersionBadge.Size = UDim2.new(0, 56, 0, 18)
VersionBadge.Position = UDim2.new(0, 196, 0.5, -9)
VersionBadge.BackgroundColor3 = CurrentTheme.Accent
VersionBadge.Text = "v2.2 God"
VersionBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
VersionBadge.TextSize = SIZES.Small
VersionBadge.FontFace = FONT_SMALL
VersionBadge.Parent = Topbar
Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(1, 0)

-- Close / Minimize
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.BackgroundTransparency = 0.8
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
CloseBtn.TextSize = 14
CloseBtn.FontFace = FONT_HEADER
CloseBtn.Parent = Topbar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -74, 0.5, -15)
MinBtn.BackgroundColor3 = CurrentTheme.SurfaceHover
MinBtn.BackgroundTransparency = 0.5
MinBtn.Text = "—"
MinBtn.TextColor3 = CurrentTheme.TextDim
MinBtn.TextSize = 14
MinBtn.FontFace = FONT_HEADER
MinBtn.Parent = Topbar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Window Drag with Safe Screen Clamping
local dragging, dragStart, startPos
Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

Topbar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newX = math.clamp(startPos.X.Offset + delta.X, -Camera.ViewportSize.X/2 + 200, Camera.ViewportSize.X/2 - 200)
        local newY = math.clamp(startPos.Y.Offset + delta.Y, -Camera.ViewportSize.Y/2 + 100, Camera.ViewportSize.Y/2 - 100)
        MainFrame.Position = UDim2.new(0.5, newX, 0.5, newY)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Sidebar & Content Frame
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -42)
Body.Position = UDim2.new(0, 0, 0, 42)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = CurrentTheme.Surface
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Body

Instance.new("UIStroke", Sidebar).Color = CurrentTheme.Border

local TabList = Instance.new("ScrollingFrame")
TabList.Name = "TabList"
TabList.Size = UDim2.new(1, -12, 1, -16)
TabList.Position = UDim2.new(0, 6, 0, 8)
TabList.BackgroundTransparency = 1
TabList.ScrollBarThickness = 2
TabList.ScrollBarImageColor3 = CurrentTheme.Accent
TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabList.Parent = Sidebar

local tabLayout = Instance.new("UIListLayout")
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = TabList

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -160, 1, -16)
ContentContainer.Position = UDim2.new(0, 155, 0, 8)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ClipsDescendants = true
ContentContainer.Parent = Body

-- [7] Tabs Component Builder (No Overlap)
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, icon, order)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_" .. name
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundColor3 = CurrentTheme.Accent
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.LayoutOrder = order or 1
    tabBtn.Parent = TabList
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

    local tabIcon = Instance.new("TextLabel")
    tabIcon.Size = UDim2.new(0, 24, 1, 0)
    tabIcon.Position = UDim2.new(0, 8, 0, 0)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Text = icon
    tabIcon.TextSize = 16
    tabIcon.FontFace = FONT_BODY
    tabIcon.TextColor3 = CurrentTheme.Text
    tabIcon.Parent = tabBtn

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size = UDim2.new(1, -38, 1, 0)
    tabLabel.Position = UDim2.new(0, 36, 0, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Text = name
    tabLabel.TextColor3 = CurrentTheme.TextDim
    tabLabel.TextSize = SIZES.Body
    tabLabel.FontFace = FONT_HEADER
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, -6, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = CurrentTheme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingRight = UDim.new(0, 6)
    pagePadding.PaddingBottom = UDim.new(0, 10)
    pagePadding.Parent = page

    local tabObject = {
        Button = tabBtn,
        Label = tabLabel,
        Icon = tabIcon,
        Page = page,
        Name = name
    }

    tabBtn.MouseButton1Click:Connect(function()
        if CurrentTab == tabObject then return end

        for _, t in ipairs(Tabs) do
            if t ~= tabObject then
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                t.Label.TextColor3 = CurrentTheme.TextDim
            end
        end

        CurrentTab = tabObject
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.25}):Play()
        tabLabel.TextColor3 = CurrentTheme.Text

        page.Position = UDim2.new(0, 15, 0, 0)
        page.Visible = true
        TweenService:Create(page, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end)

    table.insert(Tabs, tabObject)
    return page
end

local function CreateSection(parent, title, emoji)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.Parent = parent

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1
    header.Text = (emoji and emoji .. "  " or "") .. title
    header.TextColor3 = CurrentTheme.AccentGlow
    header.TextSize = SIZES.Header
    header.FontFace = FONT_TITLE
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = section

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -2)
    divider.BackgroundColor3 = CurrentTheme.Border
    divider.BorderSizePixel = 0
    divider.Parent = section

    return section
end

local function CreateToggle(parent, title, emoji, default, callback)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = CurrentTheme.Surface
    row.BackgroundTransparency = 0.4
    row.Parent = parent

    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rStroke = Instance.new("UIStroke")
    rStroke.Color = CurrentTheme.Border
    rStroke.Thickness = 0.8
    rStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -64, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (emoji and emoji .. "  " or "") .. title
    label.TextColor3 = CurrentTheme.Text
    label.TextSize = SIZES.Body
    label.FontFace = FONT_BODY
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new("TextButton")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = state and CurrentTheme.Accent or Color3.fromRGB(60, 60, 75)
    pill.Text = ""
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function toggleState()
        state = not state
        local targetKnobPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = state and CurrentTheme.Accent or Color3.fromRGB(60, 60, 75)

        TweenService:Create(knob, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = targetKnobPos
        }):Play()

        TweenService:Create(pill, TweenInfo.new(0.25), {
            BackgroundColor3 = targetColor
        }):Play()

        if callback then task.spawn(callback, state) end
    end

    pill.MouseButton1Click:Connect(toggleState)

    if default and callback then task.spawn(callback, state) end

    return {
        Set = function(val)
            if state ~= val then toggleState() end
        end,
        Get = function() return state end
    }
end

local function CreateSlider(parent, title, emoji, min, max, default, unit, callback)
    local value = default or min
    unit = unit or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3 = CurrentTheme.Surface
    row.BackgroundTransparency = 0.4
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rStroke = Instance.new("UIStroke")
    rStroke.Color = CurrentTheme.Border
    rStroke.Thickness = 0.8
    rStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = (emoji and emoji .. "  " or "") .. title
    label.TextColor3 = CurrentTheme.Text
    label.TextSize = SIZES.Body
    label.FontFace = FONT_BODY
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 60, 0, 18)
    badge.Position = UDim2.new(1, -72, 0, 6)
    badge.BackgroundColor3 = CurrentTheme.SurfaceHover
    badge.Text = tostring(value) .. unit
    badge.TextColor3 = CurrentTheme.AccentGlow
    badge.TextSize = SIZES.Small
    badge.FontFace = FONT_SMALL
    badge.Parent = row
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local pct = math.clamp((value - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = CurrentTheme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local sliding = false

    local function updateSlide(inputPos)
        local rel = math.clamp((inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel)
        badge.Text = tostring(value) .. unit

        TweenService:Create(fill, TweenInfo.new(0.06), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.06), {Position = UDim2.new(rel, -7, 0.5, -7)}):Play()

        if callback then task.spawn(callback, value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlide(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlide(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    return {
        Set = function(val)
            value = math.clamp(val, min, max)
            local rel = (value - min) / (max - min)
            badge.Text = tostring(value) .. unit
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -7, 0.5, -7)
            if callback then task.spawn(callback, value) end
        end,
        Get = function() return value end
    }
end

local function CreateButton(parent, title, emoji, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = CurrentTheme.Accent
    btn.Text = (emoji and emoji .. "  " or "") .. title
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = SIZES.Body
    btn.FontFace = FONT_TITLE
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 32)}):Play()
    end)

    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 36)}):Play()
        if callback then task.spawn(callback) end
    end)

    return btn
end

local function CreateDropdown(parent, title, emoji, options, default, callback)
    local open = false
    local selected = default or options[1]

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = CurrentTheme.Surface
    container.BackgroundTransparency = 0.4
    container.ClipsDescendants = true
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local cStroke = Instance.new("UIStroke")
    cStroke.Color = CurrentTheme.Border
    cStroke.Thickness = 0.8
    cStroke.Parent = container

    local headerBtn = Instance.new("TextButton")
    headerBtn.Size = UDim2.new(1, 0, 0, 36)
    headerBtn.BackgroundTransparency = 1
    headerBtn.Text = ""
    headerBtn.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (emoji and emoji .. "  " or "") .. title
    label.TextColor3 = CurrentTheme.Text
    label.TextSize = SIZES.Body
    label.FontFace = FONT_BODY
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = headerBtn

    local selBadge = Instance.new("TextLabel")
    selBadge.Size = UDim2.new(0.45, -30, 0, 22)
    selBadge.Position = UDim2.new(0.55, 0, 0.5, -11)
    selBadge.BackgroundColor3 = CurrentTheme.SurfaceHover
    selBadge.Text = tostring(selected)
    selBadge.TextColor3 = CurrentTheme.AccentGlow
    selBadge.TextSize = SIZES.Small
    selBadge.FontFace = FONT_SMALL
    selBadge.TextTruncate = Enum.TextTruncate.AtEnd
    selBadge.Parent = headerBtn
    Instance.new("UICorner", selBadge).CornerRadius = UDim.new(0, 6)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -26, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = CurrentTheme.TextDim
    arrow.TextSize = 12
    arrow.FontFace = FONT_HEADER
    arrow.Parent = headerBtn

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, -16, 0, 140)
    list.Position = UDim2.new(0, 8, 0, 40)
    list.BackgroundTransparency = 1
    list.ScrollBarThickness = 2
    list.ScrollBarImageColor3 = CurrentTheme.Accent
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = list

    local function toggleDropdown()
        open = not open
        local targetHeight = open and 190 or 36
        local arrowRot = open and 180 or 0

        TweenService:Create(arrow, TweenInfo.new(0.2), {Rotation = arrowRot}):Play()
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        }):Play()
    end

    headerBtn.MouseButton1Click:Connect(toggleDropdown)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -6, 0, 26)
        optBtn.BackgroundColor3 = CurrentTheme.SurfaceHover
        optBtn.BackgroundTransparency = 0.6
        optBtn.Text = "  " .. tostring(opt)
        optBtn.TextColor3 = (opt == selected) and CurrentTheme.Accent or CurrentTheme.TextDim
        optBtn.TextSize = SIZES.Small
        optBtn.FontFace = FONT_BODY
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.Parent = list
        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selBadge.Text = tostring(selected)
            toggleDropdown()
            if callback then task.spawn(callback, selected) end
        end)
    end

    return {
        Get = function() return selected end
    }
end

-- [8] Build Pages
-- TAB 1: 🏠 Main
local PageMain = CreateTab("Main", "🏠", 1)
CreateSection(PageMain, "Player Dashboard", "⭐")

local StatCard = Instance.new("Frame")
StatCard.Size = UDim2.new(1, 0, 0, 80)
StatCard.BackgroundColor3 = CurrentTheme.Surface
StatCard.BackgroundTransparency = 0.3
StatCard.Parent = PageMain
Instance.new("UICorner", StatCard).CornerRadius = UDim.new(0, 10)
local scStroke = Instance.new("UIStroke")
scStroke.Color = CurrentTheme.Border
scStroke.Thickness = 1
scStroke.Parent = StatCard

local StatPlayer = Instance.new("TextLabel")
StatPlayer.Size = UDim2.new(1, -20, 0, 20)
StatPlayer.Position = UDim2.new(0, 12, 0, 8)
StatPlayer.BackgroundTransparency = 1
StatPlayer.Text = "👤 Operator: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
StatPlayer.TextColor3 = CurrentTheme.Text
StatPlayer.TextSize = SIZES.Body
StatPlayer.FontFace = FONT_TITLE
StatPlayer.TextXAlignment = Enum.TextXAlignment.Left
StatPlayer.Parent = StatCard

local StatStage = Instance.new("TextLabel")
StatStage.Size = UDim2.new(1, -20, 0, 18)
StatStage.Position = UDim2.new(0, 12, 0, 32)
StatStage.BackgroundTransparency = 1
StatStage.Text = "📍 Current Floor: " .. tostring(LocalPlayer:GetAttribute("StageFloor") or "Lobby") .. " (Max Stage: " .. tostring(LocalPlayer:GetAttribute("SetReached") or 1) .. ")"
StatStage.TextColor3 = CurrentTheme.TextDim
StatStage.TextSize = SIZES.Small
StatStage.FontFace = FONT_BODY
StatStage.TextXAlignment = Enum.TextXAlignment.Left
StatStage.Parent = StatCard

local StatStatus = Instance.new("TextLabel")
StatStatus.Size = UDim2.new(1, -20, 0, 18)
StatStatus.Position = UDim2.new(0, 12, 0, 52)
StatStatus.BackgroundTransparency = 1
StatStatus.Text = "⚡ Status: Ready to Farm"
StatStatus.TextColor3 = CurrentTheme.AccentGlow
StatStatus.TextSize = SIZES.Small
StatStatus.FontFace = FONT_SMALL
StatStatus.TextXAlignment = Enum.TextXAlignment.Left
StatStatus.Parent = StatCard

CreateSection(PageMain, "Quick Actions", "⚡")

CreateButton(PageMain, "Instant Rebirth", "🔄", function()
    if RequestRebirth then
        RequestRebirth:FireServer()
        Notify("Rebirth requested!", "🔄", Color3.fromRGB(120, 240, 140))
    end
end)

CreateButton(PageMain, "Return to Lobby / Hub", "🏠", function()
    if RequestReturnHub then
        RequestReturnHub:FireServer()
        Notify("Teleporting to Lobby...", "🏠")
    end
end)

CreateButton(PageMain, "Redeem Common Codes", "🎁", function()
    local codes = {"RELEASE", "GUNS", "FORGE", "CLANS", "UPDATE", "100K", "50K"}
    if RequestCode then
        for _, code in ipairs(codes) do
            RequestCode:FireServer(code)
            task.wait(0.2)
        end
        Notify("Sent batch code redemptions!", "🎉")
    end
end)

-- TAB 2: 🔫 Auto Farm (ROBUST, MODULAR & NO GLITCH)
local PageFarm = CreateTab("Auto Farm", "🔫", 2)
local AutoShootActive = false
local AutoShootTrainingActive = false
local AutoAdvanceActive = false
local HeadLockActive = true
local CameraAimLockActive = false
local AutoCollectActive = true
local SelectedStage = 1

-- Helper: Locate highest unlocked training pad according to player's Rebirth count
local function GetBestTrainingPad()
    local lobby = Workspace:FindFirstChild("Lobby")
    local trainingPadsFolder = lobby and lobby:FindFirstChild("TrainingPads")
    if not trainingPadsFolder then
        return nil
    end

    local rebirths = (ClientState and ClientState.Data and ClientState.Data.Rebirths) or LocalPlayer:GetAttribute("Rebirths") or 0
    local passes = (ClientState and ClientState.Data and ClientState.Data.Passes) or {}

    local GameConfig = PlusPlus and PlusPlus:FindFirstChild("Config") and require(PlusPlus.Config.GameConfig)
    local padsConfig = GameConfig and GameConfig.TrainingPads and GameConfig.TrainingPads.Pads

    local bestMultiplier = -1
    local bestPadInfo = nil

    for _, padModel in ipairs(trainingPadsFolder:GetChildren()) do
        local padId = padModel:GetAttribute("PadId")
        local padDef = padsConfig and padsConfig[padId]
        if padDef then
            local isUnlocked = false
            if padDef.Pass then
                isUnlocked = passes[padDef.Pass] == true
            else
                isUnlocked = (padDef.Rebirths or 0) <= rebirths
            end

            if isUnlocked and (padDef.Multiplier or 0) > bestMultiplier then
                local plate = padModel:FindFirstChild("Pad")
                local target = padModel:FindFirstChild("Target")
                local face = target and target:FindFirstChild("Face")
                local hitBox = face and (face:FindFirstChild("HitBox") or face:FindFirstChild("Rings"))

                if plate and hitBox then
                    bestMultiplier = padDef.Multiplier or 0
                    bestPadInfo = {
                        Model = padModel,
                        Plate = plate,
                        HitBox = hitBox,
                        Def = padDef,
                        Id = padId
                    }
                end
            end
        end
    end

    return bestPadInfo
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 MODE 1: AUTO SHOOT MOBS & BOSSES (ยิงล็อกม็อน)
-- ═══════════════════════════════════════════════════════════════
CreateSection(PageFarm, "Auto Shoot: Mobs (ยิงล็อกม็อน)", "🎯")

CreateToggle(PageFarm, "Auto Shoot Mobs (360° Headlock)", "🔥", false, function(enabled)
    AutoShootActive = enabled
    _G.GunForgeHub_AutoShootActive = enabled
    if FireController then
        if enabled then
            -- Pause Rebirth Pad farming if active
            AutoShootTrainingActive = false
            ApplySilentAimHooks()
            FireController.SetAutoFarm(false)
            FireController.SetForcedTarget(nil, 0)
            Notify("Auto Shoot Mobs: ACTIVE", "🔥", Color3.fromRGB(120, 240, 140))
        else
            LockedTargetData = nil
            FireController.SetHolding(false)
            FireController.SetAutoFarm(false)
            FireController.SetForcedTarget(nil, 0)
            Notify("Auto Shoot Mobs: PAUSED", "⏹️")
        end
    end
end)

CreateToggle(PageFarm, "Lock Head Part (Critical Hits)", "🎯", true, function(enabled)
    HeadLockActive = enabled
    Notify(enabled and "Headlock: ON (Prioritize Head)" or "Headlock: OFF (Center Torso)", "🎯")
end)

CreateToggle(PageFarm, "Camera Follow Mob", "👁️", false, function(enabled)
    CameraAimLockActive = enabled
    Notify(enabled and "Camera Lock: ACTIVE" or "Camera Lock: OFF", "👁️")
end)

CreateToggle(PageFarm, "Auto Advance to Next Stage", "⏩", false, function(enabled)
    AutoAdvanceActive = enabled
    if enabled then
        Notify("Auto Stage Progression: ON", "⏩")
    else
        Notify("Auto Stage Progression: OFF", "⏹️")
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- ⚡ MODE 2: AUTO SHOOT REBIRTH MULTIPLIER (ยิงคูณตาม Rebirth)
-- ═══════════════════════════════════════════════════════════════
CreateSection(PageFarm, "Auto Shoot: Rebirth Pad (ยิงคูณตาม Rebirth)", "⚡")

CreateToggle(PageFarm, "Auto Shoot Multiplier Pad", "⚡", false, function(enabled)
    AutoShootTrainingActive = enabled
    if enabled then
        -- Pause Mob Shoot if active
        AutoShootActive = false
        _G.GunForgeHub_AutoShootActive = false
        LockedTargetData = nil
        ApplySilentAimHooks()

        local bestPad = GetBestTrainingPad()
        if bestPad then
            local title = bestPad.Def and bestPad.Def.Title or (bestPad.Def.Multiplier .. "x Power")
            Notify("Auto Shoot Rebirth Pad: ON (" .. title .. ")", "⚡", Color3.fromRGB(120, 240, 140))
        else
            Notify("Teleporting to Lobby / Finding Pad...", "⏳", Color3.fromRGB(255, 200, 80))
            if RequestReturnHub then RequestReturnHub:FireServer() end
        end
    else
        if FireController then
            FireController.SetHolding(false)
            FireController.SetForcedTarget(nil, 0)
        end
        Notify("Auto Shoot Rebirth Pad: PAUSED", "⏹️")
    end
end)

CreateButton(PageFarm, "Teleport to Best Unlocked Pad", "🚀", function()
    local bestPad = GetBestTrainingPad()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if bestPad and hrp then
        hrp.CFrame = CFrame.lookAt(bestPad.Plate.Position + Vector3.new(0, 3.5, 0), bestPad.HitBox.Position)
        local title = bestPad.Def and bestPad.Def.Title or (bestPad.Def.Multiplier .. "x Power")
        Notify("Warped to " .. title .. " Pad!", "🚀", Color3.fromRGB(120, 240, 140))
    else
        if RequestReturnHub then
            RequestReturnHub:FireServer()
            Notify("Returning to Hub/Lobby...", "⏳")
        else
            Notify("No training pad available in workspace", "❌", Color3.fromRGB(255, 90, 90))
        end
    end
end)

CreateSection(PageFarm, "Stage Spawner & Teleporter", "📍")

local stageOptions = {}
for i = 1, 60 do table.insert(stageOptions, "Stage " .. i) end

CreateDropdown(PageFarm, "Select Stage", "🗺️", stageOptions, "Stage 1", function(sel)
    local num = tonumber(sel:match("%d+"))
    if num then SelectedStage = num end
end)

CreateButton(PageFarm, "Teleport to Selected Stage", "🚀", function()
    local success = WarpToStage(SelectedStage)
    if success then
        Notify("Warped to Stage " .. SelectedStage .. " Floor!", "🚀", Color3.fromRGB(120, 240, 140))
    else
        Notify("Stage " .. SelectedStage .. " not found", "❌", Color3.fromRGB(255, 90, 90))
    end
end)

CreateButton(PageFarm, "Warp to Highest Unlocked Stage", "👑", function()
    local maxStage = LocalPlayer:GetAttribute("StageUnlocked") or 1
    local success = WarpToStage(maxStage)
    if success then
        Notify("Warped to Highest Stage (" .. maxStage .. ")!", "👑", Color3.fromRGB(120, 240, 140))
    end
end)

-- ADVANCED 360° HEADLOCK & HIGH-DAMAGE AUTO SHOOT LOOP
task.spawn(function()
    while Hub.Active do
        task.wait(0.06)
        if AutoShootActive and FireController then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local enemyFolder = Workspace:FindFirstChild("EnemyFolder")

                if not (char and hrp and hum and hum.Health > 0 and enemyFolder) then
                    LockedTargetData = nil
                    FireController.SetHolding(false)
                    return
                end

                -- Maintain 360° alignment bypass and clean state
                ApplySilentAimHooks()
                FireController.SetForcedTarget(nil, 0)
                FireController.SetAutoFarm(false)

                local enemies = enemyFolder:GetChildren()
                local bestEnemy = nil
                local bestTargetPart = nil
                local bestEnemyId = nil
                local minDist = 99999

                for _, enemy in ipairs(enemies) do
                    if enemy:IsA("Model") then
                        local enemyId = enemy:GetAttribute("EnemyId")
                        if type(enemyId) == "number" then
                            local hp = enemy:GetAttribute("Hp")
                            if hp == nil then
                                local ehum = enemy:FindFirstChildOfClass("Humanoid")
                                hp = ehum and ehum.Health or 1
                            end

                            local isShielded = enemy:GetAttribute("Fx") == "shield"

                            if hp > 0 and not isShielded then
                                local targetPart = nil
                                if HeadLockActive then
                                    targetPart = enemy:FindFirstChild("Head") 
                                        or enemy:FindFirstChild("UpperTorso") 
                                        or enemy:FindFirstChild("HumanoidRootPart") 
                                        or enemy.PrimaryPart 
                                        or enemy:FindFirstChildWhichIsA("BasePart")
                                else
                                    targetPart = enemy:FindFirstChild("UpperTorso") 
                                        or enemy:FindFirstChild("HumanoidRootPart") 
                                        or enemy:FindFirstChild("Head") 
                                        or enemy.PrimaryPart
                                end

                                if targetPart then
                                    local d = (targetPart.Position - hrp.Position).Magnitude
                                    -- AntiCheat.MaxFireRangeStuds is 250
                                    if d < 240 and d < minDist then
                                        minDist = d
                                        bestEnemy = enemy
                                        bestTargetPart = targetPart
                                        bestEnemyId = enemyId
                                    end
                                end
                            end
                        end
                    end
                end

                if bestEnemy and bestTargetPart and bestEnemyId then
                    local targetPos = bestTargetPart.Position
                    LockedTargetData = {
                        EnemyId = bestEnemyId,
                        Point = targetPos,
                        ShotPoint = targetPos,
                        Part = bestTargetPart,
                        Model = bestEnemy
                    }

                    if CameraAimLockActive and Camera then
                        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                    end

                    FireController.SetHolding(true)
                else
                    LockedTargetData = nil
                    FireController.SetHolding(false)

                    -- Auto Advance ONLY if user explicitly enabled it and not in Boss/Raid
                    local inSpecial = LocalPlayer:GetAttribute("InWorldBoss")
                        or LocalPlayer:GetAttribute("InDungeon")
                        or LocalPlayer:GetAttribute("InTower")
                        or LocalPlayer:GetAttribute("InSiege")

                    if AutoAdvanceActive and not inSpecial then
                        local stageUnlocked = LocalPlayer:GetAttribute("StageUnlocked") or 1
                        local stageFloor = LocalPlayer:GetAttribute("StageFloor") or 0
                        if stageUnlocked > stageFloor and stageUnlocked > 1 then
                            WarpToStage(stageUnlocked)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
    end
end)

-- ADVANCED REBIRTH MULTIPLIER PAD AUTO SHOOT LOOP
task.spawn(function()
    while Hub.Active do
        task.wait(0.08)
        if AutoShootTrainingActive and FireController then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (char and hrp and hum and hum.Health > 0) then
                    FireController.SetHolding(false)
                    return
                end

                local padInfo = GetBestTrainingPad()
                if not padInfo then
                    FireController.SetHolding(false)
                    if RequestReturnHub then
                        RequestReturnHub:FireServer()
                        task.wait(1)
                    end
                    return
                end

                -- Ensure player is standing on the pad's plate
                local padPos = padInfo.Plate.Position
                local dist = (hrp.Position - padPos).Magnitude
                if dist > 8 then
                    hrp.CFrame = CFrame.lookAt(padPos + Vector3.new(0, 3.5, 0), padInfo.HitBox.Position)
                    task.wait(0.15)
                end

                -- 360° bypass and target lock on pad HitBox
                ApplySilentAimHooks()
                FireController.SetAutoFarm(false)
                FireController.SetForcedTarget(padInfo.HitBox, 0.2)
                FireController.SetHolding(true)
            end)
        end
    end
end)

-- TAB 3: 🧲 Scrap & Loot
local PageLoot = CreateTab("Scrap & Loot", "🧲", 3)
CreateSection(PageLoot, "Scrap Harvester & Auto Sell", "💎")

local AutoCollectActive = true
local AutoSellActive = true
local ScrapMagnetActive = true
local RecentlyCollected = {}

CreateToggle(PageLoot, "Auto Collect Scrap", "✨", true, function(enabled)
    AutoCollectActive = enabled
    if enabled then Notify("Auto Collect: ACTIVE", "✨", Color3.fromRGB(120, 240, 140)) end
end)

CreateToggle(PageLoot, "Auto Sell When Bag Full", "💰", true, function(enabled)
    AutoSellActive = enabled
    if enabled then Notify("Auto Sell Scrap: ACTIVE", "💰", Color3.fromRGB(120, 240, 140)) end
end)

CreateToggle(PageLoot, "Instant Prompt & Magnet", "🧲", true, function(enabled)
    ScrapMagnetActive = enabled
end)

CreateButton(PageLoot, "⚡ Sweep Harvest (All Drops)", "⚡", function()
    local count = 0
    local scrapFolder = Workspace:FindFirstChild("ScrapDrops")
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (scrapFolder and hrp) then
        Notify("No scrap drops or character found", "❌", Color3.fromRGB(255, 100, 100))
        return
    end

    local origCFrame = hrp.CFrame
    local drops = scrapFolder:GetChildren()

    for _, drop in ipairs(drops) do
        local id = drop:GetAttribute("DropId")
        if id and drop:IsA("BasePart") then
            if IsBagFull() then
                SellAllScrap()
                task.wait(0.12)
            end
            hrp.CFrame = CFrame.new(drop.Position + Vector3.new(0, 3, 0))
            if LootController and typeof(LootController.Collect) == "function" then
                pcall(function() LootController.Collect(id) end)
            elseif RequestCollect then
                RequestCollect:FireServer(id)
            end
            local prompt = drop:FindFirstChild("FxPrompt")
            if prompt and typeof(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, prompt)
            end
            count = count + 1
            task.wait(0.04)
        end
    end

    hrp.CFrame = origCFrame
    Notify("Harvested " .. count .. " drops!", "💎", Color3.fromRGB(120, 240, 140))
end)

CreateButton(PageLoot, "💰 Instant Sell All Carried Scrap", "💰", function()
    local carried = GetCarriedScrapCount()
    if SellAllScrap() then
        Notify("Sold " .. carried .. " scrap!", "💰", Color3.fromRGB(120, 240, 140))
    else
        Notify("RequestSell Remote not found", "❌", Color3.fromRGB(255, 100, 100))
    end
end)

CreateButton(PageLoot, "📦 Check Bag Capacity", "📊", function()
    local count = GetCarriedScrapCount()
    local cap = GetCarryCap()
    local pct = cap > 0 and math.floor((count / cap) * 100) or 0
    Notify("Bag: " .. count .. "/" .. cap .. " (" .. pct .. "%)", "📦", Color3.fromRGB(255, 220, 120))
end)

-- Harvester Background Loop (Rate-limit safe + Auto Sell aware)
task.spawn(function()
    while Hub.Active do
        task.wait(0.2)
        pcall(function()
            -- 1. Auto Sell if bag is near capacity so collections never lock
            if AutoSellActive and IsBagFull() then
                SellAllScrap()
                task.wait(0.15)
            end

            local scrapFolder = Workspace:FindFirstChild("ScrapDrops")
            if not scrapFolder then return end

            local now = os.clock()
            for id, t in pairs(RecentlyCollected) do
                if now - t > 3.5 then
                    RecentlyCollected[id] = nil
                end
            end

            local drops = scrapFolder:GetChildren()
            local collectedThisTick = 0
            local maxPerTick = 4 -- Server RateLimit safe (Per 8, Burst 12)

            for _, drop in ipairs(drops) do
                local dropId = drop:GetAttribute("DropId")

                -- Magnet / Instant Prompt optimization
                if ScrapMagnetActive then
                    local prompt = drop:FindFirstChild("FxPrompt")
                    if prompt and prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                        prompt.MaxActivationDistance = 200
                        prompt.RequiresLineOfSight = false
                    end
                end

                if AutoCollectActive and dropId then
                    if not RecentlyCollected[dropId] and collectedThisTick < maxPerTick then
                        RecentlyCollected[dropId] = now
                        collectedThisTick = collectedThisTick + 1

                        if LootController and typeof(LootController.Collect) == "function" then
                            pcall(function() LootController.Collect(dropId) end)
                        elseif RequestCollect then
                            RequestCollect:FireServer(dropId)
                        end

                        local prompt = drop:FindFirstChild("FxPrompt")
                        if prompt and typeof(fireproximityprompt) == "function" then
                            pcall(fireproximityprompt, prompt)
                        end
                    end
                end
            end
        end)
    end
end)

-- TAB 4: 🔨 Forge & Upgrades
local PageForge = CreateTab("Forge", "🔨", 4)
CreateSection(PageForge, "Auto Crafting & Upgrades", "⚙️")

local AutoForgeActive = false
local ForgeCategory = "Weapons"

CreateToggle(PageForge, "Auto Forge Weapons/Armor", "🔨", false, function(enabled)
    AutoForgeActive = enabled
    if enabled then Notify("Auto Forge: ON", "🔨") end
end)

CreateDropdown(PageForge, "Forge Mode", "📦", {"Weapons", "Armor"}, "Weapons", function(sel)
    ForgeCategory = sel
end)

CreateButton(PageForge, "Instant Forge Once", "⚡", function()
    if RequestForge then
        RequestForge:FireServer({}, ForgeCategory, false)
        Notify("Forge requested (" .. ForgeCategory .. ")", "🔨")
    end
end)

CreateButton(PageForge, "Upgrade Equipped Gun", "⭐", function()
    if RequestUpgrade then
        RequestUpgrade:FireServer()
        Notify("Gun upgraded!", "⭐")
    end
end)

task.spawn(function()
    while Hub.Active do
        task.wait(2.5)
        if AutoForgeActive and RequestForge then
            pcall(function() RequestForge:FireServer({}, ForgeCategory, false) end)
        end
    end
end)

-- TAB 5: 🎁 Rewards & Gacha
local PageRewards = CreateTab("Rewards", "🎁", 5)
CreateSection(PageRewards, "Free Gifts & Wheel Spins", "🎉")

local AutoClaimActive = false

CreateToggle(PageRewards, "Auto Claim Daily & Offline", "🎁", false, function(enabled)
    AutoClaimActive = enabled
    if enabled then Notify("Auto Claim: ON", "🎁") end
end)

CreateButton(PageRewards, "Spin Lucky Wheel", "🎡", function()
    if RequestSpin then
        pcall(function()
            if RequestSpin:IsA("RemoteFunction") then RequestSpin:InvokeServer() else RequestSpin:FireServer() end
        end)
        Notify("Wheel spun!", "🎡")
    end
end)

CreateButton(PageRewards, "Roll Barrel Spin", "🛢️", function()
    if RequestBarrelSpin then
        RequestBarrelSpin:FireServer()
        Notify("Barrel spun!", "🛢️")
    end
end)

CreateButton(PageRewards, "Claim All Rewards Now", "💰", function()
    if RequestClaimDaily then RequestClaimDaily:FireServer() end
    if RequestClaimOffline then RequestClaimOffline:FireServer() end
    Notify("Claimed offline & daily rewards!", "💰", Color3.fromRGB(120, 240, 140))
end)

task.spawn(function()
    while Hub.Active do
        task.wait(5)
        if AutoClaimActive then
            pcall(function()
                if RequestClaimDaily then RequestClaimDaily:FireServer() end
                if RequestClaimOffline then RequestClaimOffline:FireServer() end
                if RequestBarrelSpin then RequestBarrelSpin:FireServer() end
            end)
        end
    end
end)

-- TAB 6: 👤 Player
local PagePlayer = CreateTab("Player", "👤", 6)
CreateSection(PagePlayer, "Movement & Physics", "🏃")

local InfJumpActive = false
local NoclipActive = false
local FlyActive = false
local FlySpeed = 50
local InvisActive = false

CreateSlider(PagePlayer, "Walk Speed", "👟", 16, 250, 16, "", function(val)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end)
end)

CreateSlider(PagePlayer, "Jump Power", "🦘", 50, 350, 50, "", function(val)
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end)
end)

CreateToggle(PagePlayer, "Infinite Jump", "🪽", false, function(enabled)
    InfJumpActive = enabled
    if enabled then Notify("Infinite Jump: ON", "🪽") end
end)

CreateSection(PagePlayer, "Flight & Noclip", "🕊️")

-- Fly Implementation (Smooth Physics Velocity & Orientation)
local flyBodyVel = nil
local flyBodyGyro = nil
local flyConn = nil

local function StopFly()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    if flyBodyVel then
        pcall(function() flyBodyVel:Destroy() end)
        flyBodyVel = nil
    end
    if flyBodyGyro then
        pcall(function() flyBodyGyro:Destroy() end)
        flyBodyGyro = nil
    end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStanding = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
end

local function StartFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    StopFly()

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Name = "GunForgeHub_FlyVel"
    flyBodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "GunForgeHub_FlyGyro"
    flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    hum.PlatformStanding = true

    flyConn = RunService.RenderStepped:Connect(function()
        if not FlyActive or not Hub.Active then return end
        local c = LocalPlayer.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not (c and root and h and flyBodyVel and flyBodyGyro and flyBodyVel.Parent and flyBodyGyro.Parent) then return end

        h.PlatformStanding = true

        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.zero

        -- Keyboard Controls
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        -- Mobile Thumbstick support fallback
        if moveDir.Magnitude == 0 and h.MoveDirection.Magnitude > 0 then
            local flat = h.MoveDirection
            local forwardDot = flat:Dot((cam.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit)
            local rightDot = flat:Dot((cam.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit)
            moveDir = (cam.CFrame.LookVector * forwardDot) + (cam.CFrame.RightVector * rightDot)
        end

        if moveDir.Magnitude > 0 then
            flyBodyVel.Velocity = moveDir.Unit * FlySpeed
        else
            flyBodyVel.Velocity = Vector3.zero
        end

        flyBodyGyro.CFrame = cam.CFrame
    end)
    table.insert(Hub.Connections, flyConn)
end

CreateToggle(PagePlayer, "Fly (บิน)", "🕊️", false, function(enabled)
    FlyActive = enabled
    if enabled then
        StartFly()
        Notify("Fly: ON (WASD + Space/Shift)", "🕊️", Color3.fromRGB(120, 240, 140))
    else
        StopFly()
        Notify("Fly: OFF", "🕊️", Color3.fromRGB(255, 140, 140))
    end
end)

CreateSlider(PagePlayer, "Fly Speed (ความเร็วบิน)", "⚡", 10, 250, 50, "", function(val)
    FlySpeed = val
end)

CreateToggle(PagePlayer, "Noclip (เดินทะลุกำแพง)", "👻", false, function(enabled)
    NoclipActive = enabled
    if enabled then Notify("Noclip: ON", "👻", Color3.fromRGB(120, 240, 140)) end
end)

CreateSection(PagePlayer, "Stealth & Invisibility", "👁️‍🗨️")

-- Invisibility Implementation (Ghost Transparencies & Name Tag Hide)
local invisConn = nil
local origTransparencies = {}
local invisHighlight = nil

local function DisableInvisibility()
    if invisConn then
        invisConn:Disconnect()
        invisConn = nil
    end
    if invisHighlight then
        pcall(function() invisHighlight:Destroy() end)
        invisHighlight = nil
    end
    for part, origVal in pairs(origTransparencies) do
        if part and part.Parent then
            pcall(function()
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = origVal
                elseif part:IsA("BillboardGui") or part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                    part.Enabled = origVal
                end
            end)
        end
    end
    origTransparencies = {}
end

local function EnableInvisibility()
    local char = LocalPlayer.Character
    if not char then return end

    origTransparencies = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            origTransparencies[part] = part.Transparency
            part.Transparency = 1
        elseif part:IsA("BillboardGui") then
            origTransparencies[part] = part.Enabled
            part.Enabled = false
        elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
            origTransparencies[part] = part.Enabled
            part.Enabled = false
        end
    end

    if not invisHighlight then
        invisHighlight = Instance.new("Highlight")
        invisHighlight.Name = "GunForgeHub_GhostInvis"
        invisHighlight.FillColor = Color3.fromRGB(160, 200, 255)
        invisHighlight.OutlineColor = Color3.fromRGB(220, 240, 255)
        invisHighlight.FillTransparency = 0.88
        invisHighlight.OutlineTransparency = 0.35
        invisHighlight.Adornee = char
        invisHighlight.Parent = char
    end

    if invisConn then invisConn:Disconnect() end
    invisConn = RunService.Stepped:Connect(function()
        if not InvisActive or not Hub.Active then return end
        local c = LocalPlayer.Character
        if not c then return end
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency < 1 then
                if not origTransparencies[part] then
                    origTransparencies[part] = part.Transparency
                end
                part.Transparency = 1
            elseif part:IsA("Decal") and part.Transparency < 1 then
                if not origTransparencies[part] then
                    origTransparencies[part] = part.Transparency
                end
                part.Transparency = 1
            elseif (part:IsA("BillboardGui") or part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam")) and part.Enabled then
                if origTransparencies[part] == nil then
                    origTransparencies[part] = true
                end
                part.Enabled = false
            end
        end
    end)
    table.insert(Hub.Connections, invisConn)
end

CreateToggle(PagePlayer, "Invisibility (หายตัว / ล่องหน)", "🌫️", false, function(enabled)
    InvisActive = enabled
    if enabled then
        EnableInvisibility()
        Notify("Invisibility: ON", "🌫️", Color3.fromRGB(120, 240, 140))
    else
        DisableInvisibility()
        Notify("Invisibility: OFF", "🌫️", Color3.fromRGB(255, 140, 140))
    end
end)

-- Register Cleanup
table.insert(Hub.Cleanups, function()
    StopFly()
    DisableInvisibility()
end)

-- Global Connections for Player Mods
table.insert(Hub.Connections, UserInputService.JumpRequest:Connect(function()
    if InfJumpActive then
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end))

table.insert(Hub.Connections, RunService.Stepped:Connect(function()
    if NoclipActive and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

table.insert(Hub.Connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    if InvisActive then
        EnableInvisibility()
    end
    if FlyActive then
        StartFly()
    end
end))

-- TAB 7: 👁️ Visuals & ESP
local PageVisuals = CreateTab("Visuals", "👁️", 7)
CreateSection(PageVisuals, "Chams & Highlights", "✨")

local EnemyESP = false
local ScrapESP = false

local function ApplyHighlight(inst, color, fillTransp)
    local hl = Instance.new("Highlight")
    hl.Adornee = inst
    hl.FillColor = color
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = fillTransp or 0.5
    hl.OutlineTransparency = 0.1
    hl.Parent = inst
    table.insert(Hub.ESPObjects, hl)
    return hl
end

CreateToggle(PageVisuals, "Enemies ESP", "👾", false, function(enabled)
    EnemyESP = enabled
    if not enabled then
        for _, hl in pairs(Hub.ESPObjects) do
            if hl.Name == "EnemyESP" then hl:Destroy() end
        end
    else
        Notify("Enemies ESP: ON", "👾")
    end
end)

CreateToggle(PageVisuals, "Scrap Drops ESP", "💎", false, function(enabled)
    ScrapESP = enabled
    if not enabled then
        for _, hl in pairs(Hub.ESPObjects) do
            if hl.Name == "ScrapESP" then hl:Destroy() end
        end
    else
        Notify("Scrap ESP: ON", "💎")
    end
end)

CreateToggle(PageVisuals, "Fullbright", "☀️", false, function(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Notify("Fullbright: ON", "☀️")
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

CreateSlider(PageVisuals, "Field Of View", "📷", 70, 120, 70, "°", function(val)
    Camera.FieldOfView = val
end)

task.spawn(function()
    while Hub.Active do
        task.wait(1.5)
        if EnemyESP then
            pcall(function()
                local enemies = Workspace:FindFirstChild("EnemyFolder")
                if enemies then
                    for _, enemy in ipairs(enemies:GetChildren()) do
                        if not enemy:FindFirstChild("EnemyESP") then
                            local hl = ApplyHighlight(enemy, Color3.fromRGB(255, 60, 80), 0.4)
                            hl.Name = "EnemyESP"
                        end
                    end
                end
            end)
        end
        if ScrapESP then
            pcall(function()
                local drops = Workspace:FindFirstChild("ScrapDrops")
                if drops then
                    for _, drop in ipairs(drops:GetChildren()) do
                        if drop:IsA("BasePart") and not drop:FindFirstChild("ScrapESP") then
                            local hl = ApplyHighlight(drop, Color3.fromRGB(80, 220, 255), 0.3)
                            hl.Name = "ScrapESP"
                        end
                    end
                end
            end)
        end
    end
end)

-- TAB 8: ⚙️ Settings
local PageSettings = CreateTab("Settings", "⚙️", 8)
CreateSection(PageSettings, "Theme & Appearance", "🎨")

CreateDropdown(PageSettings, "Color Theme", "🎨", {"🌙 Midnight", "🌸 Sakura", "💚 Matcha", "💎 Ice", "🖤 AMOLED"}, CurrentThemeName, function(sel)
    CurrentThemeName = sel
    CurrentTheme = Themes[sel]
    Notify("Applied Theme: " .. sel, "🎨")

    MainFrame.BackgroundColor3 = CurrentTheme.Background
    Topbar.BackgroundColor3 = CurrentTheme.Surface
    Sidebar.BackgroundColor3 = CurrentTheme.Surface
    mainStroke.Color = CurrentTheme.Border
    VersionBadge.BackgroundColor3 = CurrentTheme.Accent
    if CurrentTab then CurrentTab.Button.BackgroundColor3 = CurrentTheme.Accent end
end)

CreateSection(PageSettings, "Menu Lifecycle", "🛠️")

CreateButton(PageSettings, "Reset Window Position to Center", "📐", function()
    MainFrame.Position = DEFAULT_POS
    Notify("Window position reset to center", "📐")
end)

CreateButton(PageSettings, "Unload & Destroy Hub", "💀", function()
    Notify("Unloading Hub...", "💀", Color3.fromRGB(255, 80, 80))
    task.delay(0.5, function() Hub:Destroy() end)
end)

-- [9] Mobile Floating Toggle Button
local FloatBtn = Instance.new("ImageButton")
FloatBtn.Name = "MobileHubToggle"
FloatBtn.Size = UDim2.fromOffset(46, 46)
FloatBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatBtn.BackgroundColor3 = CurrentTheme.Accent
FloatBtn.AutoButtonColor = false
FloatBtn.Parent = ScreenGui

Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local fbStroke = Instance.new("UIStroke")
fbStroke.Color = Color3.fromRGB(255, 255, 255)
fbStroke.Thickness = 1.5
fbStroke.Transparency = 0.4
fbStroke.Parent = FloatBtn

local fbIcon = Instance.new("TextLabel")
fbIcon.Size = UDim2.new(1, 0, 1, 0)
fbIcon.BackgroundTransparency = 1
fbIcon.Text = "☰"
fbIcon.TextSize = 22
fbIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
fbIcon.FontFace = FONT_TITLE
fbIcon.Parent = FloatBtn

local fbDragging = false
local fbDragStart, fbStartPos
local fbMoved = false

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = true
        fbMoved = false
        fbDragStart = input.Position
        fbStartPos = FloatBtn.Position
    end
end)

FloatBtn.InputChanged:Connect(function(input)
    if fbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - fbDragStart
        if delta.Magnitude > 4 then
            fbMoved = true
            FloatBtn.Position = UDim2.new(
                fbStartPos.X.Scale, fbStartPos.X.Offset + delta.X,
                fbStartPos.Y.Scale, fbStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

local function ToggleMenu()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        MainFrame.Position = DEFAULT_POS
        MainFrame.Size = UDim2.fromOffset(500, 360)
        TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(560, 420)
        }):Play()
    end
end

FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not fbMoved then ToggleMenu() end
        fbDragging = false
    end
end)

task.spawn(function()
    while Hub.Active and FloatBtn.Parent do
        TweenService:Create(FloatBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(50, 50)}):Play()
        task.wait(1.4)
        TweenService:Create(FloatBtn, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.fromOffset(46, 46)}):Play()
        task.wait(1.4)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(500, 360),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function()
        MainFrame.Visible = false
        MainFrame.BackgroundTransparency = 0
    end)
    Notify("Menu hidden! Click ☰ button or press RightShift to re-open.", "ℹ️")
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    Notify("Minimized to floating button", "📌")
end)

table.insert(Hub.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        ToggleMenu()
    end
end))

-- [10] Initialize Tabs (First Tab Active)
for i, t in ipairs(Tabs) do
    if i == 1 then
        t.Button.BackgroundTransparency = 0.25
        t.Label.TextColor3 = CurrentTheme.Text
        t.Page.Position = UDim2.new(0, 0, 0, 0)
        t.Page.Visible = true
        CurrentTab = t
    else
        t.Button.BackgroundTransparency = 1
        t.Label.TextColor3 = CurrentTheme.TextDim
        t.Page.Visible = false
    end
end

MainFrame.Size = UDim2.fromOffset(460, 320)
MainFrame.BackgroundTransparency = 0.8
TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.fromOffset(560, 420),
    BackgroundTransparency = 0
}):Play()

Notify("Gun Forge Hub v2.2 (Master AFK) Loaded!", "🎉", CurrentTheme.AccentGlow)
print("[GunForgeHub] v2.2 Master AFK Ready!")
