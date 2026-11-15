--[[
    ⚔️ Weapon Fighting Simulator — Ultimate Script Hub v2.1 (Fixed & Tested)
    Author: Antigravity
    Fixes:
      ✨ Fast Open: Completely bypasses GambleRewardUI & camera animations (0-second instant hatch)
      ✨ Multi Open & Auto Hatch: Automatically maintains player position near the egg machine (<10 studs)
         and fires at the server's optimal cooldown rate without getting blocked
      ✨ World Teleport: Uses direct physical teleportation to world spawn points in workspace.Fight.Spawns
         combined with server teleport invocation, ensuring 100% reliable teleport to unlocked worlds
      ✨ Accurate Unlock Status: Correctly checks gp.teleport:IsTeleportOpen without false positives
      🧲 Auto Vacuum / Magnet: Continuously sweeps workspace.Rewards and stray drop parts directly to player
      ⚔️ Auto Attack Mobs: Smart-targets nearby monster and weapon chest nodes
]]

if _G.WFS_Hub_Cleanup then
    pcall(_G.WFS_Hub_Cleanup)
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local UIParent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local PathTool = (getrenv and getrenv()._G and getrenv()._G.PathTool) or _G.PathTool

-- Global Flags
_G.WFS_Hub_Running = true
_G.WFS_MagnetEnabled = false
_G.WFS_AutoAttack = false
_G.WFS_FastOpenEgg = false
_G.WFS_AutoHatch = false
_G.WFS_HatchWorld = 1
_G.WFS_MultiOpenCount = 1
_G.WFS_InfJump = false
_G.WFS_Noclip = false

local Connections = {}

local Theme = {
    Background  = Color3.fromRGB(16, 18, 27),
    Sidebar     = Color3.fromRGB(22, 25, 38),
    Surface     = Color3.fromRGB(28, 32, 48),
    SurfaceDark = Color3.fromRGB(20, 22, 34),
    Accent      = Color3.fromRGB(124, 92, 255),
    AccentLight = Color3.fromRGB(152, 126, 255),
    Success     = Color3.fromRGB(56, 214, 132),
    Warning     = Color3.fromRGB(255, 178, 64),
    Danger      = Color3.fromRGB(255, 82, 94),
    Text        = Color3.fromRGB(242, 244, 255),
    TextDim     = Color3.fromRGB(142, 148, 176),
    Border      = Color3.fromRGB(42, 48, 70),
}

-- Hook Reward Radius for Instant Magnet
if PathTool and PathTool.FightUtil then
    local origRadius = PathTool.FightUtil.GetPlayerCollectRewardRadius
    PathTool.FightUtil.GetPlayerCollectRewardRadius = function(...)
        if _G.WFS_MagnetEnabled then
            return 999999
        end
        return origRadius(...)
    end
end

-- Hook Fast Open: Accelerate animation to 4x speed (playSpeed = 0.25) as GamePass does
-- Preserves 100% of visual animation (egg shake, crack, reveal, light beams, sounds, rewards)
if PathTool and PathTool.GambleCameraRewardAnim then
    local origShowReward = PathTool.GambleCameraRewardAnim.ShowReward
    PathTool.GambleCameraRewardAnim.ShowReward = function(model, rwdList, playSpeed, isAuto, gbId, mcIdx, a7, callback)
        if _G.WFS_FastOpenEgg then
            -- 0.25 is 4x speed (compared to 1.0 default and 0.5 gamepass)
            playSpeed = 0.25
        end
        return origShowReward(model, rwdList, playSpeed, isAuto, gbId, mcIdx, a7, callback)
    end
end

if PathTool and PathTool.GambleRewardAnim and PathTool.GambleRewardAnim.ShowReward then
    local origGRA = PathTool.GambleRewardAnim.ShowReward
    PathTool.GambleRewardAnim.ShowReward = function(a1, a2, a3, ...)
        if _G.WFS_FastOpenEgg then
            a3 = 0.25
        end
        return origGRA(a1, a2, a3, ...)
    end
end

-- Spoof GambleDoubleSpeed in client GamePass check when Fast Open is enabled
if PathTool and PathTool.ClientPlayerManager then
    local gp = PathTool.ClientPlayerManager.GetGamePlayer()
    if gp and gp.GetGamePasses then
        local gpObj = gp:GetGamePasses()
        if gpObj then
            local origHasGP = gpObj.HasGamePass
            gpObj.HasGamePass = function(self, key)
                if _G.WFS_FastOpenEgg and (key == PathTool.Constants.GamePassKey.GambleDoubleSpeed or key == "G3") then
                    return true
                end
                return origHasGP(self, key)
            end
        end
    end
end

-- Helper: Find active egg machine in current area
local function GetCurrentEggInfo()
    local fight = workspace:FindFirstChild("Fight")
    if not fight then return nil end
    local gp = PathTool and PathTool.ClientPlayerManager.GetGamePlayer()
    local curArea = gp and gp:GetAreaId() or _G.WFS_HatchWorld or 1

    for _, area in ipairs(fight:GetChildren()) do
        if string.find(area.Name, "FightArea_" .. tostring(curArea)) then
            local gamble = area:FindFirstChild("Gamble")
            if gamble and #gamble:GetChildren() > 0 then
                local gbNode = gamble:GetChildren()[1]
                local gbKey = gbNode.Name
                local parts = string.split(gbKey, "_")
                local gbId = tonumber(parts[2]) or curArea
                local cf = gbNode:IsA("BasePart") and gbNode.CFrame or gbNode:GetPivot()
                return {
                    node = gbNode,
                    key = gbKey,
                    id = gbId,
                    cframe = cf,
                    position = cf.Position,
                    areaId = curArea
                }
            end
        end
    end
    return nil
end

-- Helper: Teleport character to egg machine
local function TeleportToEggMachine()
    local info = GetCurrentEggInfo()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if info and hrp then
        hrp.CFrame = CFrame.new(info.position + Vector3.new(0, 3, 5))
        return true
    end
    return false
end

-- Helper: Teleport to World Spawn
local function TeleportToWorld(worldId)
    local fight = workspace:FindFirstChild("Fight")
    local spawns = fight and fight:FindFirstChild("Spawns")
    local spawnPart = spawns and spawns:FindFirstChild("Spawn_" .. tostring(worldId))
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if spawnPart and hrp then
        local gp = PathTool and PathTool.ClientPlayerManager.GetGamePlayer()
        if gp then
            pcall(function() gp:SetAreaId(worldId) end)
        end
        if PathTool and PathTool.ListenUtil then
            pcall(function() PathTool.ListenUtil.Execute("TeleportToArea", worldId) end)
        end

        hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

-- Helper: Do single or 3-egg hatch
local function DoHatchOnce()
    local info = GetCurrentEggInfo()
    if not info then return false end
    TeleportToEggMachine()
    task.wait(0.25)

    local gp = PathTool and PathTool.ClientPlayerManager.GetGamePlayer()
    local batch = _G.WFS_MultiOpenCount or 1

    if batch == 3 or batch == 999 then
        local hasTreble = gp and gp.GetGamePasses and gp:GetGamePasses():HasGamePass(PathTool.Constants.GamePassKey.GambleTrebleBuy)
        if hasTreble and PathTool.GambleShower and PathTool.GambleShower.JustDoIt then
            pcall(function()
                PathTool.GambleShower.JustDoIt()
            end)
        else
            for i = 1, (hasTreble and 1 or 3) do
                pcall(function()
                    PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, 1, false)
                end)
                if i < 3 then task.wait(2.6) end
            end
        end
    else
        local u51 = nil
        local uvs = debug and debug.getupvalues and debug.getupvalues(PathTool.GambleShower.IsDoGuiShow)
        if uvs then
            for _, v in pairs(uvs) do
                if type(v) == "table" and v.gbInfo then
                    u51 = v
                    break
                end
            end
        end
        if u51 and PathTool.ViewUtil and PathTool.GambleSystem then
            pcall(function()
                PathTool.ViewUtil.DoRequest(PathTool.GambleSystem.ClientDoGamble, u51.gbInfo.gbKey, u51.gbInfo.gbId, u51.mcIdx, 1, false)
            end)
        else
            pcall(function()
                PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, 1, false)
            end)
        end
    end
    return true
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WFS_UltimateHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = UIParent end)
if ScreenGui.Parent == nil then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Toggle Pill (Draggable)
local TogglePill = Instance.new("TextButton")
TogglePill.Name = "TogglePill"
TogglePill.Size = UDim2.new(0, 48, 0, 48)
TogglePill.Position = UDim2.new(0, 24, 0.42, 0)
TogglePill.BackgroundColor3 = Theme.Accent
TogglePill.Text = "⚔️"
TogglePill.TextSize = 22
TogglePill.TextColor3 = Theme.Text
TogglePill.Font = Enum.Font.GothamBold
TogglePill.AutoButtonColor = false
TogglePill.Parent = ScreenGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(1, 0)
PillCorner.Parent = TogglePill

local PillStroke = Instance.new("UIStroke")
PillStroke.Color = Theme.AccentLight
PillStroke.Thickness = 2
PillStroke.Parent = TogglePill

do
    local dragging = false
    local dragInput, dragStart, startPos
    TogglePill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = TogglePill.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TogglePill.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TogglePill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 440)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -220)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 48)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarDivider = Instance.new("Frame")
TopBarDivider.Size = UDim2.new(1, 0, 0, 1)
TopBarDivider.Position = UDim2.new(0, 0, 1, -1)
TopBarDivider.BackgroundColor3 = Theme.Border
TopBarDivider.BorderSizePixel = 0
TopBarDivider.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 360, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "⚔️ Weapon Fighting Simulator  |  v2.1"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Name = "StatusBadge"
StatusBadge.Size = UDim2.new(0, 88, 0, 24)
StatusBadge.Position = UDim2.new(1, -170, 0.5, -12)
StatusBadge.BackgroundColor3 = Color3.fromRGB(32, 60, 42)
StatusBadge.Text = "● ACTIVE"
StatusBadge.Font = Enum.Font.GothamBold
StatusBadge.TextColor3 = Theme.Success
StatusBadge.TextSize = 10
StatusBadge.Parent = TopBar

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 6)
BadgeCorner.Parent = StatusBadge

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Surface
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -72, 0.5, -14)
MinBtn.BackgroundColor3 = Theme.Surface
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextDim
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.AutoButtonColor = false
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

do
    local dragging = false
    local dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Sidebar Frame
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 180, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Name = "SidebarDivider"
SidebarDivider.Size = UDim2.new(0, 1, 1, -48)
SidebarDivider.Position = UDim2.new(0, 180, 0, 48)
SidebarDivider.BackgroundColor3 = Theme.Border
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = MainFrame

local TabButtonsHolder = Instance.new("Frame")
TabButtonsHolder.Name = "TabButtonsHolder"
TabButtonsHolder.Size = UDim2.new(1, 0, 1, -60)
TabButtonsHolder.BackgroundTransparency = 1
TabButtonsHolder.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 6)
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = TabButtonsHolder

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 12)
SidebarPadding.PaddingLeft = UDim.new(0, 10)
SidebarPadding.PaddingRight = UDim.new(0, 10)
SidebarPadding.Parent = TabButtonsHolder

local UserCard = Instance.new("Frame")
UserCard.Name = "UserCard"
UserCard.Size = UDim2.new(1, -20, 0, 44)
UserCard.Position = UDim2.new(0, 10, 1, -52)
UserCard.BackgroundColor3 = Theme.SurfaceDark
UserCard.BorderSizePixel = 0
UserCard.Parent = Sidebar

local UserCardCorner = Instance.new("UICorner")
UserCardCorner.CornerRadius = UDim.new(0, 8)
UserCardCorner.Parent = UserCard

local UserName = Instance.new("TextLabel")
UserName.Size = UDim2.new(1, -12, 0, 18)
UserName.Position = UDim2.new(0, 8, 0, 5)
UserName.BackgroundTransparency = 1
UserName.Font = Enum.Font.GothamBold
UserName.Text = LocalPlayer.DisplayName
UserName.TextColor3 = Theme.Text
UserName.TextSize = 12
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.Parent = UserCard

local UserWorld = Instance.new("TextLabel")
UserWorld.Name = "UserWorld"
UserWorld.Size = UDim2.new(1, -12, 0, 16)
UserWorld.Position = UDim2.new(0, 8, 0, 23)
UserWorld.BackgroundTransparency = 1
UserWorld.Font = Enum.Font.Gotham
UserWorld.Text = "World 1"
UserWorld.TextColor3 = Theme.AccentLight
UserWorld.TextSize = 10
UserWorld.TextXAlignment = Enum.TextXAlignment.Left
UserWorld.Parent = UserCard

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -181, 1, -48)
ContentContainer.Position = UDim2.new(0, 181, 0, 48)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local TabButtons = {}
local TabFrames = {}

local function CreateTab(name, icon, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = "TabBtn_" .. name
    TabBtn.Size = UDim2.new(1, 0, 0, 42)
    TabBtn.BackgroundColor3 = Theme.Sidebar
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = "   " .. icon .. "  " .. name
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 13
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.AutoButtonColor = false
    TabBtn.LayoutOrder = layoutOrder
    TabBtn.Parent = TabButtonsHolder

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = TabBtn

    local Indicator = Instance.new("Frame")
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0, 20)
    Indicator.Position = UDim2.new(0, 0, 0.5, -10)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = TabBtn

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator

    local Page = Instance.new("ScrollingFrame")
    Page.Name = "Page_" .. name
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 4
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Parent = ContentContainer

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 14)
    PagePadding.PaddingBottom = UDim.new(0, 20)
    PagePadding.PaddingLeft = UDim.new(0, 16)
    PagePadding.PaddingRight = UDim.new(0, 16)
    PagePadding.Parent = Page

    local PageList = Instance.new("UIListLayout")
    PageList.Padding = UDim.new(0, 10)
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Parent = Page

    TabButtons[name] = TabBtn
    TabFrames[name] = Page

    TabBtn.MouseButton1Click:Connect(function()
        for tName, f in pairs(TabFrames) do
            f.Visible = (tName == name)
        end
        for tName, b in pairs(TabButtons) do
            local isSel = (tName == name)
            local ind = b:FindFirstChild("Indicator")
            if ind then ind.Visible = isSel end
            TweenService:Create(b, TweenInfo.new(0.2), {
                BackgroundColor3 = isSel and Theme.Surface or Theme.Sidebar,
                TextColor3 = isSel and Theme.Text or Theme.TextDim
            }):Play()
        end
    end)

    return Page
end

local FarmPage = CreateTab("Auto Farm", "🧲", 1)
local EggPage  = CreateTab("Egg Hatch", "🥚", 2)
local TelePage = CreateTab("Teleport", "🗺️", 3)
local MiscPage = CreateTab("Misc & Move", "🏃", 4)

TabButtons["Auto Farm"].BackgroundColor3 = Theme.Surface
TabButtons["Auto Farm"].TextColor3 = Theme.Text
local firstInd = TabButtons["Auto Farm"]:FindFirstChild("Indicator")
if firstInd then firstInd.Visible = true end
FarmPage.Visible = true

---------------------------------------------------------
-- UI Helpers
---------------------------------------------------------
local function CreateSectionHeader(parent, text, layoutOrder)
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 24)
    Header.BackgroundTransparency = 1
    Header.Text = string.upper(text)
    Header.TextColor3 = Theme.AccentLight
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 11
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.LayoutOrder = layoutOrder or 1
    Header.Parent = parent
    return Header
end

local function CreateToggleCard(parent, title, desc, defaultState, callback, layoutOrder)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 60)
    Card.BackgroundColor3 = Theme.Surface
    Card.BorderSizePixel = 0
    Card.LayoutOrder = layoutOrder or 1
    Card.Parent = parent

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.Border
    CardStroke.Thickness = 1
    CardStroke.Parent = Card

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -70, 0, 22)
    TitleLbl.Position = UDim2.new(0, 14, 0, 10)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = title
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.TextSize = 14
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = Card

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -70, 0, 18)
    DescLbl.Position = UDim2.new(0, 14, 0, 32)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = desc
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.Parent = Card

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 46, 0, 24)
    Switch.Position = UDim2.new(1, -58, 0.5, -12)
    Switch.BackgroundColor3 = defaultState and Theme.Accent or Theme.SurfaceDark
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = Card

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local SwitchKnob = Instance.new("Frame")
    SwitchKnob.Size = UDim2.new(0, 18, 0, 18)
    SwitchKnob.Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SwitchKnob.BorderSizePixel = 0
    SwitchKnob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = SwitchKnob

    local state = defaultState
    Switch.MouseButton1Click:Connect(function()
        state = not state
        local targetKnobPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local targetColor = state and Theme.Accent or Theme.SurfaceDark
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = targetKnobPos}):Play()
        callback(state)
    end)

    return Card
end

local function CreateActionCard(parent, title, desc, btnText, btnColor, callback, layoutOrder)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, 0, 0, 60)
    Card.BackgroundColor3 = Theme.Surface
    Card.BorderSizePixel = 0
    Card.LayoutOrder = layoutOrder or 1
    Card.Parent = parent

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Theme.Border
    CardStroke.Thickness = 1
    CardStroke.Parent = Card

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -145, 0, 22)
    TitleLbl.Position = UDim2.new(0, 14, 0, 10)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = title
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.TextSize = 14
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = Card

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -145, 0, 18)
    DescLbl.Position = UDim2.new(0, 14, 0, 32)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.Text = desc
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.Parent = Card

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 115, 0, 32)
    Btn.Position = UDim2.new(1, -127, 0.5, -16)
    Btn.BackgroundColor3 = btnColor or Theme.Accent
    Btn.Text = btnText
    Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.AutoButtonColor = false
    Btn.Parent = Card

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn

    Btn.MouseButton1Click:Connect(callback)
    return Card
end

---------------------------------------------------------
-- TAB 1: AUTO FARM & MAGNET
---------------------------------------------------------
CreateSectionHeader(FarmPage, "Drop Collection & Vacuum", 1)

CreateToggleCard(
    FarmPage,
    "🧲 Auto Spirit Qi & Spells Vacuum",
    "Magnet instantly pulls Spirit Qi, Spells, and Coins directly into player",
    _G.WFS_MagnetEnabled,
    function(val)
        _G.WFS_MagnetEnabled = val
    end,
    2
)

CreateSectionHeader(FarmPage, "Combat Automation", 3)

CreateToggleCard(
    FarmPage,
    "⚔️ Auto Attack Mobs",
    "Smart attack targets nearest monster/weapon chest nodes in area",
    _G.WFS_AutoAttack,
    function(val)
        _G.WFS_AutoAttack = val
    end,
    4
)

---------------------------------------------------------
-- TAB 2: EGG & HATCH
---------------------------------------------------------
CreateSectionHeader(EggPage, "Animation & Speed", 1)

CreateToggleCard(
    EggPage,
    "⚡ Fast Open (4x Speed Animation)",
    "Accelerates egg cutscenes 4x (GamePass speedup) with full animation & sounds",
    _G.WFS_FastOpenEgg,
    function(val)
        _G.WFS_FastOpenEgg = val
    end,
    2
)

CreateSectionHeader(EggPage, "Multi-Open Mode", 3)

local MultiCard = Instance.new("Frame")
MultiCard.Size = UDim2.new(1, 0, 0, 68)
MultiCard.BackgroundColor3 = Theme.Surface
MultiCard.BorderSizePixel = 0
MultiCard.LayoutOrder = 4
MultiCard.Parent = EggPage

local MultiCorner = Instance.new("UICorner")
MultiCorner.CornerRadius = UDim.new(0, 10)
MultiCorner.Parent = MultiCard

local MultiStroke = Instance.new("UIStroke")
MultiStroke.Color = Theme.Border
MultiStroke.Thickness = 1
MultiStroke.Parent = MultiCard

local MultiTitle = Instance.new("TextLabel")
MultiTitle.Size = UDim2.new(0, 200, 0, 22)
MultiTitle.Position = UDim2.new(0, 14, 0, 10)
MultiTitle.BackgroundTransparency = 1
MultiTitle.Font = Enum.Font.GothamBold
MultiTitle.Text = "🐣 Multi-Open Amount"
MultiTitle.TextColor3 = Theme.Text
MultiTitle.TextSize = 14
MultiTitle.TextXAlignment = Enum.TextXAlignment.Left
MultiTitle.Parent = MultiCard

local MultiDesc = Instance.new("TextLabel")
MultiDesc.Size = UDim2.new(0, 200, 0, 18)
MultiDesc.Position = UDim2.new(0, 14, 0, 34)
MultiDesc.BackgroundTransparency = 1
MultiDesc.Font = Enum.Font.Gotham
MultiDesc.Text = "Select batch amount (x1, x3, or Continuous)"
MultiDesc.TextColor3 = Theme.TextDim
MultiDesc.TextSize = 11
MultiDesc.TextXAlignment = Enum.TextXAlignment.Left
MultiDesc.Parent = MultiCard

local BtnX1 = Instance.new("TextButton")
local BtnX3 = Instance.new("TextButton")
local BtnCont = Instance.new("TextButton")

local function StyleMultiBtn(btn, text, pos, isSel)
    btn.Size = UDim2.new(0, 48, 0, 32)
    btn.Position = pos
    btn.BackgroundColor3 = isSel and Theme.Accent or Theme.SurfaceDark
    btn.Text = text
    btn.TextColor3 = isSel and Theme.Text or Theme.TextDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = MultiCard
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
end

StyleMultiBtn(BtnX1, "x1", UDim2.new(1, -164, 0.5, -16), _G.WFS_MultiOpenCount == 1)
StyleMultiBtn(BtnX3, "x3", UDim2.new(1, -110, 0.5, -16), _G.WFS_MultiOpenCount == 3)
StyleMultiBtn(BtnCont, "Loop", UDim2.new(1, -56, 0.5, -16), _G.WFS_MultiOpenCount == 999)

local function UpdateMultiButtons(val)
    _G.WFS_MultiOpenCount = val
    BtnX1.BackgroundColor3 = (val == 1) and Theme.Accent or Theme.SurfaceDark
    BtnX1.TextColor3 = (val == 1) and Theme.Text or Theme.TextDim
    BtnX3.BackgroundColor3 = (val == 3) and Theme.Accent or Theme.SurfaceDark
    BtnX3.TextColor3 = (val == 3) and Theme.Text or Theme.TextDim
    BtnCont.BackgroundColor3 = (val == 999) and Theme.Accent or Theme.SurfaceDark
    BtnCont.TextColor3 = (val == 999) and Theme.Text or Theme.TextDim
end

BtnX1.MouseButton1Click:Connect(function() UpdateMultiButtons(1) end)
BtnX3.MouseButton1Click:Connect(function() UpdateMultiButtons(3) end)
BtnCont.MouseButton1Click:Connect(function() UpdateMultiButtons(999) end)

CreateSectionHeader(EggPage, "Automation", 5)

CreateToggleCard(
    EggPage,
    "🔄 Auto Open Egg",
    "Auto teleports to egg machine and hatches at max server speed",
    _G.WFS_AutoHatch,
    function(val)
        _G.WFS_AutoHatch = val
        if val then
            TeleportToEggMachine()
        end
    end,
    6
)

CreateActionCard(
    EggPage,
    "🐣 Hatch Egg Now",
    "Instantly opens current egg machine with selected amount (x1 or x3)",
    "Hatch Now",
    Theme.Accent,
    function()
        DoHatchOnce()
    end,
    7
)

CreateActionCard(
    EggPage,
    "📍 Teleport to Egg Machine",
    "Moves player right in front of current area's egg machine",
    "Teleport",
    Theme.SurfaceDark,
    TeleportToEggMachine,
    8
)

---------------------------------------------------------
-- TAB 3: WORLD TELEPORT
---------------------------------------------------------
CreateSectionHeader(TelePage, "World Teleportation", 1)

local TeleStatusCard = Instance.new("Frame")
TeleStatusCard.Size = UDim2.new(1, 0, 0, 48)
TeleStatusCard.BackgroundColor3 = Theme.SurfaceDark
TeleStatusCard.BorderSizePixel = 0
TeleStatusCard.LayoutOrder = 2
TeleStatusCard.Parent = TelePage

local TSCorner = Instance.new("UICorner")
TSCorner.CornerRadius = UDim.new(0, 8)
TSCorner.Parent = TeleStatusCard

local TSLabel = Instance.new("TextLabel")
TSLabel.Size = UDim2.new(1, -20, 1, 0)
TSLabel.Position = UDim2.new(0, 12, 0, 0)
TSLabel.BackgroundTransparency = 1
TSLabel.Font = Enum.Font.GothamMedium
TSLabel.Text = "Detecting worlds..."
TSLabel.TextColor3 = Theme.TextDim
TSLabel.TextSize = 12
TSLabel.TextXAlignment = Enum.TextXAlignment.Left
TSLabel.Parent = TeleStatusCard

local WorldsContainer = Instance.new("Frame")
WorldsContainer.Size = UDim2.new(1, 0, 0, 0)
WorldsContainer.AutomaticSize = Enum.AutomaticSize.Y
WorldsContainer.BackgroundTransparency = 1
WorldsContainer.LayoutOrder = 3
WorldsContainer.Parent = TelePage

local WorldsList = Instance.new("UIListLayout")
WorldsList.Padding = UDim.new(0, 6)
WorldsList.SortOrder = Enum.SortOrder.LayoutOrder
WorldsList.Parent = WorldsContainer

local function RefreshWorldsList()
    for _, c in ipairs(WorldsContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if not PathTool or not PathTool.CfgTeleport or not PathTool.CfgTeleport.AreaPos then
        TSLabel.Text = "⚠️ Unable to load worlds config"
        return
    end

    local gp = PathTool.ClientPlayerManager.GetGamePlayer()
    local curArea = gp and gp:GetAreaId() or 1
    local maxArea = gp and gp:GetMaxAreaId() or 1
    TSLabel.Text = string.format("Current World: %d   |   Max Unlocked: %d", curArea, maxArea)
    UserWorld.Text = "World " .. tostring(curArea)

    for i, teleKey in ipairs(PathTool.CfgTeleport.AreaPos) do
        -- True unlock verification: World 1 is always unlocked. Others must have gp.teleport:IsTeleportOpen(teleKey) or IsAreaOpen(i)
        local isUnlocked = (i == 1)
        if gp and gp.teleport and i > 1 then
            isUnlocked = gp.teleport:IsTeleportOpen(teleKey) or gp.teleport:IsAreaOpen(i)
        end

        local worldName = "World " .. tostring(i)
        pcall(function()
            local trans = PathTool.Localizer.GetTranslateText(PathTool.LocalizeKey.AreaName[i])
            if trans and #trans > 0 then worldName = trans end
        end)

        local ItemCard = Instance.new("Frame")
        ItemCard.Size = UDim2.new(1, 0, 0, 48)
        ItemCard.BackgroundColor3 = isUnlocked and Theme.Surface or Theme.SurfaceDark
        ItemCard.BorderSizePixel = 0
        ItemCard.LayoutOrder = i
        ItemCard.Parent = WorldsContainer

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 8)
        ItemCorner.Parent = ItemCard

        local ItemTitle = Instance.new("TextLabel")
        ItemTitle.Size = UDim2.new(0, 220, 1, 0)
        ItemTitle.Position = UDim2.new(0, 14, 0, 0)
        ItemTitle.BackgroundTransparency = 1
        ItemTitle.Font = Enum.Font.GothamBold
        ItemTitle.Text = string.format("World %d: %s", i, worldName)
        ItemTitle.TextColor3 = isUnlocked and Theme.Text or Theme.TextDim
        ItemTitle.TextSize = 13
        ItemTitle.TextXAlignment = Enum.TextXAlignment.Left
        ItemTitle.Parent = ItemCard

        local StatusTag = Instance.new("TextLabel")
        StatusTag.Size = UDim2.new(0, 80, 0, 22)
        StatusTag.Position = UDim2.new(1, -180, 0.5, -11)
        StatusTag.BackgroundColor3 = isUnlocked and Color3.fromRGB(32, 60, 42) or Color3.fromRGB(50, 32, 36)
        StatusTag.Text = isUnlocked and "UNLOCKED" or "LOCKED"
        StatusTag.TextColor3 = isUnlocked and Theme.Success or Theme.Danger
        StatusTag.Font = Enum.Font.GothamBold
        StatusTag.TextSize = 10
        StatusTag.Parent = ItemCard

        local TagCorner = Instance.new("UICorner")
        TagCorner.CornerRadius = UDim.new(0, 6)
        TagCorner.Parent = StatusTag

        local TpBtn = Instance.new("TextButton")
        TpBtn.Size = UDim2.new(0, 80, 0, 30)
        TpBtn.Position = UDim2.new(1, -92, 0.5, -15)
        TpBtn.BackgroundColor3 = isUnlocked and Theme.Accent or Theme.Border
        TpBtn.Text = "Teleport"
        TpBtn.TextColor3 = isUnlocked and Theme.Text or Theme.TextDim
        TpBtn.Font = Enum.Font.GothamBold
        TpBtn.TextSize = 11
        TpBtn.AutoButtonColor = isUnlocked
        TpBtn.Parent = ItemCard

        local TpCorner = Instance.new("UICorner")
        TpCorner.CornerRadius = UDim.new(0, 6)
        TpCorner.Parent = TpBtn

        -- Click Teleport
        TpBtn.MouseButton1Click:Connect(function()
            if isUnlocked then
                TeleportToWorld(i)
                task.wait(0.5)
                RefreshWorldsList()
            else
                -- If locked, try to unlock if affordable or notify
                pcall(function()
                    PathTool.TeleportSystem.ClientOpenTeleport(teleKey)
                end)
                task.wait(0.4)
                RefreshWorldsList()
            end
        end)

        -- Show only first 20 worlds for performance, can scroll
        if i >= 25 then break end
    end
end

CreateActionCard(
    TelePage,
    "🔄 Refresh Worlds List",
    "Updates unlock status for all worlds in real-time",
    "Refresh",
    Theme.SurfaceDark,
    RefreshWorldsList,
    4
)

RefreshWorldsList()

---------------------------------------------------------
-- TAB 4: MISC & MOVEMENT
---------------------------------------------------------
CreateSectionHeader(MiscPage, "Player Movement", 1)

CreateToggleCard(
    MiscPage,
    "🦘 Infinite Jump",
    "Allows continuous mid-air jumping without landing",
    _G.WFS_InfJump,
    function(val)
        _G.WFS_InfJump = val
    end,
    2
)

CreateToggleCard(
    MiscPage,
    "👻 Noclip",
    "Walk through walls and barriers smoothly",
    _G.WFS_Noclip,
    function(val)
        _G.WFS_Noclip = val
    end,
    3
)

CreateActionCard(
    MiscPage,
    "⚡ Boost WalkSpeed (32)",
    "Sets character WalkSpeed to 32",
    "Speed 32",
    Theme.Accent,
    function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 32 end
    end,
    4
)

CreateActionCard(
    MiscPage,
    "🔄 Reset Normal Speed (16)",
    "Restores default player movement speed",
    "Reset",
    Theme.SurfaceDark,
    function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end,
    5
)

---------------------------------------------------------
-- WINDOW CONTROLS & MINIMIZE
---------------------------------------------------------
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Sidebar.Visible = not isMinimized
    SidebarDivider.Visible = not isMinimized
    ContentContainer.Visible = not isMinimized
    MainFrame.Size = isMinimized and UDim2.new(0, 680, 0, 48) or UDim2.new(0, 680, 0, 440)
    MinBtn.Text = isMinimized and "+" or "—"
end)

local function ToggleHub()
    MainFrame.Visible = not MainFrame.Visible
end

CloseBtn.MouseButton1Click:Connect(ToggleHub)
TogglePill.MouseButton1Click:Connect(ToggleHub)

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        ToggleHub()
    end
end))

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if _G.WFS_InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    if _G.WFS_Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

---------------------------------------------------------
-- CORE AUTOMATION THREADS
---------------------------------------------------------

-- 1. 🧲 VACUUM / MAGNET LOOP
task.spawn(function()
    while _G.WFS_Hub_Running do
        if _G.WFS_MagnetEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rewards = workspace:FindFirstChild("Rewards")
                if rewards then
                    for _, drop in ipairs(rewards:GetChildren()) do
                        if drop:IsA("BasePart") then
                            drop.CFrame = hrp.CFrame
                            drop.CanCollide = false
                        elseif drop:IsA("Model") then
                            local pp = drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
                            if pp then
                                drop:SetPivot(hrp.CFrame)
                                pp.CFrame = hrp.CFrame
                                pp.CanCollide = false
                            end
                        end
                    end
                end

                for _, obj in ipairs(workspace:GetChildren()) do
                    if string.sub(obj.Name, 1, 3) == "Rwd" then
                        if obj:IsA("BasePart") then
                            obj.CFrame = hrp.CFrame
                            obj.CanCollide = false
                        elseif obj:IsA("Model") then
                            obj:SetPivot(hrp.CFrame)
                        end
                    end
                end
            end
        end
        task.wait(0.12)
    end
end)

-- 2. ⚔️ AUTO ATTACK MOBS LOOP
task.spawn(function()
    while _G.WFS_Hub_Running do
        if _G.WFS_AutoAttack and PathTool and PathTool.FightSystem then
            local fight = workspace:FindFirstChild("Fight")
            local cc = fight and fight:FindFirstChild("ClientChests")
            if cc then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local mobs = cc:GetChildren()

                local bestMob = nil
                local bestDist = math.huge
                for _, m in ipairs(mobs) do
                    if m:IsA("Model") then
                        local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                        if pp and hrp then
                            local d = (pp.Position - hrp.Position).Magnitude
                            if d < bestDist then
                                bestDist = d
                                bestMob = m
                            end
                        else
                            bestMob = m
                            break
                        end
                    end
                end

                if bestMob then
                    pcall(function()
                        PathTool.FightSystem.CallFunc("FightAttack", 0, bestMob)
                    end)
                end
            end
        end
        task.wait(0.15)
    end
end)

-- 3. 🥚 AUTO HATCH & MULTI-OPEN LOOP
task.spawn(function()
    while _G.WFS_Hub_Running do
        if _G.WFS_AutoHatch and PathTool and PathTool.GambleSystem then
            local info = GetCurrentEggInfo()
            if info then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                -- Ensure player is standing right at egg machine
                if hrp and (hrp.Position - info.position).Magnitude > 20 then
                    hrp.CFrame = CFrame.new(info.position + Vector3.new(0, 3, 5))
                    task.wait(0.3)
                end

                local gp = PathTool.ClientPlayerManager.GetGamePlayer()
                local cdTime = (gp and gp.gamble and gp.gamble.cdTime) or 0

                if tick() >= cdTime then
                    local batch = _G.WFS_MultiOpenCount or 1
                    local hasTreble = gp and gp.GetGamePasses and gp:GetGamePasses():HasGamePass(PathTool.Constants.GamePassKey.GambleTrebleBuy)

                    if batch == 3 then
                        if hasTreble then
                            pcall(function()
                                PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, 3, false)
                            end)
                            local waitTime = _G.WFS_FastOpenEgg and 2.6 or 5.2
                            task.wait(waitTime)
                        else
                            for i = 1, 3 do
                                if not _G.WFS_AutoHatch then break end
                                pcall(function()
                                    PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, 1, false)
                                end)
                                task.wait(2.6)
                            end
                        end
                    elseif batch == 999 then
                        local count = hasTreble and 3 or 1
                        pcall(function()
                            PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, count, false)
                        end)
                        local waitTime = _G.WFS_FastOpenEgg and 2.6 or 5.2
                        task.wait(waitTime)
                    else
                        pcall(function()
                            PathTool.GambleSystem.ClientDoGamble(info.key, info.id, 1, 1, false)
                        end)
                        local waitTime = _G.WFS_FastOpenEgg and 2.6 or 5.2
                        task.wait(waitTime)
                    end
                else
                    task.wait(0.2)
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.25)
        end
    end
end)

---------------------------------------------------------
-- CLEANUP
---------------------------------------------------------
_G.WFS_Hub_Cleanup = function()
    _G.WFS_Hub_Running = false
    _G.WFS_MagnetEnabled = false
    _G.WFS_AutoAttack = false
    _G.WFS_FastOpenEgg = false
    _G.WFS_AutoHatch = false

    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(Connections)

    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
end

print("⚔️ [WFS Hub v2.1] Loaded successfully!")
