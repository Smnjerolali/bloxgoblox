--!strict
-- WKHub - Hunt GUI (single LocalScript)
-- Tabs: Main, Hunt, Teleport, Misc, Info, Server
-- Minimize -> dock icon (draggable), hotkey T to toggle

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Try load theme (optional, safe fallback)
local Theme = {}
do
	local m = ReplicatedStorage:FindFirstChild("UITheme")
	if m and m:IsA("ModuleScript") then
		local ok, t = pcall(require, m)
		if ok and type(t) == "table" then
			Theme = t
		end
	end
end

-- Palette
local Colors = {
	Accent = Color3.fromRGB(148, 97, 255),
	Accent2 = Color3.fromRGB(110, 78, 210),
	Surface = Color3.fromRGB(20, 15, 26),
	Surface2 = Color3.fromRGB(35, 26, 48),
	Stroke = Color3.fromRGB(150, 120, 220),
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(196, 176, 230),
	SwitchOff = Color3.fromRGB(72, 64, 92),
}
local function pick(t, k, fallback)
	local v = rawget(t, k)
	return typeof(v) == "Color3" and v or fallback
end
Colors.Accent      = pick(Theme, "Accent", Colors.Accent)
Colors.Surface     = pick(Theme, "Surface", Colors.Surface)
Colors.Surface2    = pick(Theme, "Surface2", Colors.Surface2)
Colors.Stroke      = pick(Theme, "Stroke", Colors.Stroke)
Colors.TextPrimary = pick(Theme, "TextPrimary", Colors.TextPrimary)
Colors.TextMuted   = pick(Theme, "TextMuted", Colors.TextMuted)

-- Helpers
local function New(className, props, children)
	local inst = Instance.new(className)
	if props then for k, v in pairs(props) do (inst :: any)[k] = v end end
	if children then for _, c in ipairs(children) do c.Parent = inst end end
	return inst
end
local function addCorner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
	return c
end
local function addStroke(p, color, thickness, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(1,1,1)
	s.Thickness = thickness or 1
	s.Transparency = trans or 0.2
	s.Parent = p
	return s
end
local function addGradient(p, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 0
	g.Parent = p
	return g
end
local function tween(obj, ti, goal)
	local t = TweenService:Create(obj, ti, goal)
	t:Play()
	return t
end

-- Root gui
local gui = New("ScreenGui", {
	Name = "HuntUI_Runtime",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = playerGui,
})
print('[WKHub] Boot: ScreenGui created, Enabled='..tostring(gui.Enabled))

-- Window

-- Overlay for dropdowns above all content
local overlay = New("Frame", {
	Name = "Overlay",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1,1),
	ZIndex = 100,
	Visible = false,
	Parent = gui,
}, {})

local window = New("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(680, 420),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Colors.Surface2,
	BackgroundTransparency = 0.15,
	Parent = gui,
})
print('[WKHub] Boot: Window created, Visible='..tostring(window.Visible))
addCorner(window, 14)
addStroke(window, Colors.Stroke, 1, 0.3)
addGradient(window, Color3.fromRGB(30,22,44), Color3.fromRGB(20,14,28), 90)

-- Shadow
do
	local shadow = New("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		Position = UDim2.fromOffset(0,0),
		Image = "rbxassetid://5028857084",
		ImageColor3 = Color3.fromRGB(0,0,0),
		ImageTransparency = 0.35,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24,24,276,276),
		ZIndex = 0,
		Parent = window,
	})
end

-- Title bar
local titleBar = New("Frame", {
	Name = "TitleBar",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -12, 0, 48),
	Position = UDim2.fromOffset(6,6),
	Parent = window,
})
local title = New("TextLabel", {
	Text = "WKHub",
	Font = Enum.Font.GothamSemibold,
	TextSize = 20,
	TextColor3 = Colors.TextPrimary,
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 12, 0, 12),
	Size = UDim2.fromOffset(260, 22),
	Parent = titleBar,
})

-- Top-right buttons
local btnRow = New("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1,0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(96, 30),
	Parent = titleBar,
})
local uiList = Instance.new("UIListLayout")
uiList.FillDirection = Enum.FillDirection.Horizontal
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Right
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Padding = UDim.new(0, 6)
uiList.Parent = btnRow

local function makeTopButton(txt)
	local b = New("TextButton", {
		Text = txt,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = Colors.TextPrimary,
		AutoButtonColor = false,
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(42, 28),
	}, {})
	addCorner(b, 8)
	addStroke(b, Colors.Stroke, 1, 0.5)
	b.MouseEnter:Connect(function() tween(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.05}) end)
	b.MouseLeave:Connect(function() tween(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}) end)
	b.Parent = btnRow
	return b
end

local btnMin = makeTopButton("–")
local btnClose = makeTopButton("✕")

-- Dragging window
do
	local dragging = false
	local dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	titleBar.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Dock (bubble) icon
local dockIcon = New("TextButton", {
	Name = "DockIcon",
	Text = "WK",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Colors.TextPrimary,
	AutoButtonColor = false,
	BackgroundColor3 = Colors.Accent,
	BackgroundTransparency = 0.1,
	Size = UDim2.fromOffset(46, 46),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12), -- bottom-left
	Visible = false,
	Parent = gui,
	ZIndex = 10,
})
addCorner(dockIcon, 23)
addStroke(dockIcon, Colors.Stroke, 1, 0.3)
addGradient(dockIcon, Color3.fromRGB(164,120,255), Color3.fromRGB(120,90,210), 90)
do -- subtle shadow for dock
	local s = New("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24,24,276,276),
		Size = UDim2.fromScale(1,1),
		ZIndex = -1,
		Parent = dockIcon,
	})
end

-- Make dock icon draggable (bounded to screen with 12px margin)
do
	local dragging = false
	local dragStart: Vector2
	local startPos: UDim2
	local margin = 12
	dockIcon.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = dockIcon.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	dockIcon.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			local screenSize = gui.AbsoluteSize
			local iconSize = dockIcon.AbsoluteSize
			local newX = math.clamp(startPos.X.Offset + delta.X, margin, screenSize.X - margin - iconSize.X)
			local minY = margin + iconSize.Y - screenSize.Y
			local maxY = -margin
			local newY = math.clamp(startPos.Y.Offset + delta.Y, minY, maxY)
			dockIcon.Position = UDim2.new(0, newX, 1, newY)
		end
	end)
end

-- Sidebar
local sidebar = New("Frame", {
	Name = "Sidebar",
	BackgroundColor3 = Colors.Surface,
	BackgroundTransparency = 0.15,
	AnchorPoint = Vector2.new(0,1),
	Position = UDim2.new(0, 8, 1, -8),
	Size = UDim2.new(0, 150, 1, -62),
	Parent = window,
})
addCorner(sidebar, 12)
addStroke(sidebar, Colors.Stroke, 1, 0.5)
addGradient(sidebar, Color3.fromRGB(34,26,52), Color3.fromRGB(26,20,38), 90)

local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 12)
sidePad.PaddingBottom = UDim.new(0, 12)
sidePad.PaddingLeft = UDim.new(0, 12)
sidePad.PaddingRight = UDim.new(0, 12)
sidePad.Parent = sidebar

local navList = Instance.new("UIListLayout")
navList.Padding = UDim.new(0, 8)
navList.FillDirection = Enum.FillDirection.Vertical
navList.HorizontalAlignment = Enum.HorizontalAlignment.Left
navList.VerticalAlignment = Enum.VerticalAlignment.Top
navList.Parent = sidebar

local function navButton(labelText)
	local b = New("TextButton", {
		Text = labelText,
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Colors.TextPrimary,
		AutoButtonColor = false,
		BackgroundColor3 = Colors.Surface2,
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, 0, 0, 36),
	}, {})
	addCorner(b, 10)
	addStroke(b, Colors.Stroke, 1, 0.6)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = b
	b.MouseEnter:Connect(function() tween(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}) end)
	b.MouseLeave:Connect(function() tween(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.2}) end)
	b.Parent = sidebar
	return b
end

-- [Removed duplicate early Pages block]


-- [Removed duplicate early Main page block to avoid pre-definition errors and duplication]

-- Switch factory
local function createSwitch(initial, onChanged)
	local sw = New("TextButton", {
		Name = "Switch",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = initial and Colors.Accent or Colors.SwitchOff,
		Size = UDim2.fromOffset(58, 28),
	}, {})
	addCorner(sw, 14)
	addStroke(sw, Colors.Stroke, 1, 0.6)
	local knob = New("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.fromOffset(24, 24),
		Position = initial and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12),
		AnchorPoint = Vector2.new(0,0),
	}, { })
	addCorner(knob, 12)
	knob.Parent = sw

	local state = initial
	local function apply(anim)
		local goalBg = state and Colors.Accent or Colors.SwitchOff
		local goalPos = state and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
		if anim then
			tween(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalBg})
			tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos})
		else
			sw.BackgroundColor3 = goalBg
			knob.Position = goalPos
		end
	end

	sw.Activated:Connect(function()
		state = not state
		apply(true)
		if onChanged then task.spawn(onChanged, state) end
	end)

	return sw, function(v : boolean) state = v; apply(true) end
end

-- Toggle card
local function toggleCard(parent, titleText, subtitleText, defaultOn, onChanged: (boolean)->())
	local card = New("Frame", {
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 74),
	}, {})
	addCorner(card, 12)
	addStroke(card, Colors.Stroke, 1, 0.4)
	addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)

	local t = New("TextLabel", {
		Text = titleText,
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 22),
	}, {})
	t.Parent = card

	local sub = New("TextLabel", {
		Text = subtitleText or "",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -120, 0, 18),
	}, {})
	sub.Parent = card

	local sw, setState = createSwitch(defaultOn, onChanged)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -14, 0.5, 0)
	sw.Parent = card

	card.Parent = parent
	return setState
end

-- Status logging utility
local StatusLog = {
	buffer = {},
	max = 50,
	onUpdate = nil,
}
local function logStatus(msg)
	local s = "[WKHub] " .. tostring(msg)
	table.insert(StatusLog.buffer, 1, tostring(msg))
	if #StatusLog.buffer > StatusLog.max then table.remove(StatusLog.buffer) end
	if StatusLog.onUpdate then
		StatusLog.onUpdate(table.concat(StatusLog.buffer, "\n"))
	end
	print(s)
end

-- Utility: get CFrame for a teleport target (area + cpIndex)
local Config = {
	Teleports = {

  MountTalamau = {
    [1] = CFrame.fromMatrix(Vector3.new(-655.8442993164062, 1081.611083984375, 281.3544006347656), Vector3.new(0.649083137512207, 0, -0.7607174515724182), Vector3.new(0, 1, 0), Vector3.new(0.7607174515724182, 0, 0.649083137512207))
  },
		-- Optional: hardcode coordinates here if needed
	}
}

local function getInstanceCFrame(inst): CFrame?
	if inst == nil then return nil end
	if inst:IsA("BasePart") then
		return inst.CFrame
	end
	if inst:IsA("Attachment") then
		local ok, cf = pcall(function()
			return (inst :: Attachment).WorldCFrame
		end)
		if ok then return cf end
	end
	if inst:IsA("Model") then
		local m = inst :: Model
		if m.PrimaryPart then return m.PrimaryPart.CFrame end
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				return (d :: BasePart).CFrame
			end
		end
	end
	-- Generic container fallback (e.g., Folder)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			return (d :: BasePart).CFrame
		end
	end
	return nil
end



local function findTeleportCFrame(area, cpIndex): CFrame?
	-- 1) Manual config override
	local cfgArea = Config.Teleports[area]
	if cfgArea and cfgArea[cpIndex] then
		return cfgArea[cpIndex]
	end
		-- 1a) Special-case: MountTalamau cp1 named "Summit" at workspace.SummitTrigger
	if area == "MountTalamau" and cpIndex == 1 then
		local node = workspace:FindFirstChild("SummitTrigger")
		local cf = getInstanceCFrame(node)
		if cf then return cf end
	end

-- 1b) Special-case: MountYagataw uses numeric children: workspace.Checkpoints["<index>"]
		-- 1a-extended) Fallbacks for MountTalamau cp1 when SummitTrigger missing
	if area == "MountTalamau" and cpIndex == 1 then
		-- AutoFallbackMountTalamau
		local candidateNames = { "Summit", "Puncak", "Summit Trigger", "Summit_Trigger", "MountTalamauSummit", "TalamauSummit", "SummitTalamau" }
		for _, nm in ipairs(candidateNames) do
			local node = workspace:FindFirstChild(nm)
			local cf = getInstanceCFrame(node)
			if cf then return cf end
		end
		local checkpoints = workspace:FindFirstChild("Checkpoints")
		if checkpoints then
			local cands = { "Summit", "Puncak", "Checkpoint1", "1" }
			for _, nm in ipairs(cands) do
				local node = checkpoints:FindFirstChild(nm)
				local cf = getInstanceCFrame(node)
				if cf then return cf end
			end
		end
		local tpRoot = workspace:FindFirstChild("TeleportPoints")
		if tpRoot then
			local areaFolder = tpRoot:FindFirstChild("MountTalamau")
			if areaFolder then
				local cands = { "Summit", "Puncak", "CP1", "1" }
				for _, nm in ipairs(cands) do
					local node = areaFolder:FindFirstChild(nm)
					local cf = getInstanceCFrame(node)
					if cf then return cf end
				end
			end
		end
		for _, inst in ipairs(workspace:GetDescendants()) do
			if inst.Name == "SummitTrigger" then
				local cf = getInstanceCFrame(inst)
				if cf then return cf end
			end
		end
	end
if area == "MountYagataw" then
		local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
		if checkpointsFolder then
			local node = checkpointsFolder:FindFirstChild(tostring(cpIndex))
			local cf = getInstanceCFrame(node)
			if cf then return cf end
		end
	end
	-- 1c) Special-case: MountHoreg cp5 named "Puncak"
	if area == "MountHoreg" and cpIndex == 5 then
		local folder = workspace:FindFirstChild("CheckpointsFolder")
		if folder then
			local node = folder:FindFirstChild("Puncak") or folder:FindFirstChild("puncak")
			local cf = getInstanceCFrame(node)
			if cf then return cf end
		end

		local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
		if checkpointsFolder then
			local node = checkpointsFolder:FindFirstChild("Puncak") or checkpointsFolder:FindFirstChild("puncak")
			local cf = getInstanceCFrame(node)
			if cf then return cf end
		end
		local tpRootMH = workspace:FindFirstChild("TeleportPoints")
		if tpRootMH then
			local areaFolderMH = tpRootMH:FindFirstChild(area)
			if areaFolderMH then
				local node = areaFolderMH:FindFirstChild("Puncak") or areaFolderMH:FindFirstChild("puncak")
				local cf = getInstanceCFrame(node)
				if cf then return cf end
			end
		end
	end
	-- 1d) Special-case: MountHoreg cp4 under workspace.CheckpointsFolder.CP<index>
	if area == "MountHoreg" and cpIndex == 4 then
		local folder = workspace:FindFirstChild("CheckpointsFolder")
		if folder then
			local node = folder:FindFirstChild("CP"..tostring(cpIndex))
			local cf = getInstanceCFrame(node)
			if cf then return cf end
		end
	end
	-- 1d) Special-case: MountHoreg cp1..4 under workspace.CheckpointsFolder.CP<index>
	if area == "MountHoreg" and cpIndex >= 1 and cpIndex <= 4 then
		local folder = workspace:FindFirstChild("CheckpointsFolder")
		if folder then
			local nameVariants = {
				"CP"..tostring(cpIndex),
				"Cp"..tostring(cpIndex),
				"cp"..tostring(cpIndex),
			}
			for _, nm in ipairs(nameVariants) do
				local node = folder:FindFirstChild(nm)
				local cf = getInstanceCFrame(node)
				if cf then return cf end
			end
		end
	end
	-- 2) Workspace.Checkpoints.Checkpoint<index> (primary), then numeric child as fallback
	local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
	if checkpointsFolder then
		local node1 = checkpointsFolder:FindFirstChild("Checkpoint"..tostring(cpIndex))
		local cf1 = getInstanceCFrame(node1)
		if cf1 then return cf1 end
		local node2 = checkpointsFolder:FindFirstChild(tostring(cpIndex))
		local cf2 = getInstanceCFrame(node2)
		if cf2 then return cf2 end
	end
	-- 3) Fallbacks: Workspace/TeleportPoints/<Area>/<CPx>
	local tpRoot = workspace:FindFirstChild("TeleportPoints")
	if tpRoot then
		local areaFolder = tpRoot:FindFirstChild(area)
		if areaFolder then
			local nameVariants = {"CP"..cpIndex, "CP "..cpIndex, "CP_"..cpIndex}
			for _, nm in ipairs(nameVariants) do
				local node = areaFolder:FindFirstChild(nm)
				local cf = getInstanceCFrame(node)
				if cf then return cf end
			end
		end
	end
	-- 4) Fallbacks: Top-level <Area>_<CPx>
	local nameVariants = {area.."_CP"..cpIndex, area.."_CP "..cpIndex, area.." CP"..cpIndex}
	for _, nm in ipairs(nameVariants) do
		local node = workspace:FindFirstChild(nm)
		local cf = getInstanceCFrame(node)
		if cf then return cf end
	end
	return nil
end

local function teleportTo(area, cpIndex)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[WKHub] HumanoidRootPart not found")

		logStatus("Teleport failed: HumanoidRootPart not found")        return
	end
	local cf = findTeleportCFrame(area, cpIndex)
	if not cf then
		warn(string.format("[WKHub] Teleport target not found: %s Checkpoint %d", area, cpIndex))
		return
	end
	hrp.CFrame = cf + Vector3.new(0, 5, 0)
	print(string.format("[WKHub] Teleported to %s Checkpoint %d", area, cpIndex))
end

-- Pages and content
local pages = New("Frame", {
	Name = "Pages",
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 168, 0, 56),
	Size = UDim2.new(1, -176, 1, -64),
	Parent = window,
})
print('[WKHub] Boot: Pages frame created, Visible='..tostring(pages.Visible))

local function createPage(name)
	local f = New("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		Visible = false,
	}, {})
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = f
	f.Parent = pages
	return f
end

local pageMain = createPage("Main")
local pageHunt = createPage("Hunt")
local pageTeleport = createPage("Teleport")
local pageMisc = createPage("Misc")
local pageInfo = createPage("Info")
local pageServer = createPage("Server")

-- Main page scroll content
local pageMainContent = New("ScrollingFrame", {
	Name = "MainContent",
	Active = true,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromOffset(4, 34), -- below header (24) + ~10 padding
	Size = UDim2.new(1, -8, 1, -38),
}, {})
pageMainContent.Parent = pageMain
local mainList = Instance.new("UIListLayout")
mainList.Padding = UDim.new(0, 8)
mainList.FillDirection = Enum.FillDirection.Vertical
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Parent = pageMainContent

local __rmMainList = pageMain:FindFirstChildOfClass("UIListLayout"); if __rmMainList then __rmMainList:Destroy() end
pageHunt.Visible = true

-- Hunt page
do
	local header = New("TextLabel", {
		Text = "Hunt",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 24),
	}, {})
	header.Parent = pageHunt

	local function onGhostShark(enabled)
		Players.LocalPlayer:SetAttribute("AutoGhostShark", enabled)
		print("[Hunt] Ghost Shark:", enabled and "ON" or "OFF")
	end
	local function onWorm(enabled)
		Players.LocalPlayer:SetAttribute("AutoWormHunt", enabled)
		print("[Hunt] Worm Hunt:", enabled and "ON" or "OFF")
	end
	local function onShark(enabled)
		Players.LocalPlayer:SetAttribute("AutoSharkHunt", enabled)
		print("[Hunt] Shark Hunt:", enabled and "ON" or "OFF")
	end

	local function toggleCard(parent, titleText, subtitleText, defaultOn, onChanged: (boolean)->())
		local card = New("Frame", {
			BackgroundColor3 = Colors.Surface,
			BackgroundTransparency = 0.15,
			Size = UDim2.new(1, -8, 0, 74),
		}, {})
		addCorner(card, 12)
		addStroke(card, Colors.Stroke, 1, 0.4)
		addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)

		local t = New("TextLabel", {
			Text = titleText,
			Font = Enum.Font.GothamSemibold,
			TextSize = 18,
			TextColor3 = Colors.TextPrimary,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -120, 0, 22),
		}, {})
		t.Parent = card

		local sub = New("TextLabel", {
			Text = subtitleText or "",
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = Colors.Accent,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 36),
			Size = UDim2.new(1, -120, 0, 18),
		}, {})
		sub.Parent = card

		local sw = New("TextButton", {
			Name = "Switch",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = defaultOn and Colors.Accent or Colors.SwitchOff,
			Size = UDim2.fromOffset(58, 28),
		}, {})
		addCorner(sw, 14)
		addStroke(sw, Colors.Stroke, 1, 0.6)
		local knob = New("Frame", {
			Name = "Knob",
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			Size = UDim2.fromOffset(24, 24),
			Position = defaultOn and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12),
			AnchorPoint = Vector2.new(0,0),
		}, { })
		addCorner(knob, 12)
		knob.Parent = sw

		local state = defaultOn
		local function apply(anim)
			local goalBg = state and Colors.Accent or Colors.SwitchOff
			local goalPos = state and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
			if anim then
				tween(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalBg})
				tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos})
			else
				sw.BackgroundColor3 = goalBg
				knob.Position = goalPos
			end
		end

		sw.Activated:Connect(function()
			state = not state
			apply(true)
			if onChanged then task.spawn(onChanged, state) end
		end)

		sw.AnchorPoint = Vector2.new(1, 0.5)
		sw.Position = UDim2.new(1, -14, 0.5, 0)
		sw.Parent = card

		card.Parent = parent
	end

	toggleCard(pageHunt, "Ghost Shark Hunt", "Auto Teleport to Ghost Shark area if activated", false, function(enabled)
		Players.LocalPlayer:SetAttribute("AutoGhostShark", enabled)
	end)
	toggleCard(pageHunt, "Worm Hunt", "Auto Teleport to Worm Hunt area if activated", false, function(enabled)
		Players.LocalPlayer:SetAttribute("AutoWormHunt", enabled)
	end)
	toggleCard(pageHunt, "Shark Hunt", "Auto Teleport to Shark Hunt area if activated", false, function(enabled)
		Players.LocalPlayer:SetAttribute("AutoSharkHunt", enabled)
	end)
end


-- Main page
do
	local header = New("TextLabel", {
		Text = "Main",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 24),
	}, {})
	header.Parent = pageMain

	-- God Mode (self-contained UI + logic)
	local God = {
		enabled = false,
		conns = {},
		ffName = "HuntUI_GodModeFF",
		hb = nil,
		lastSafeCF = nil,
	}

	local function disconnectAll()
		for _, c in ipairs(God.conns) do pcall(function() c:Disconnect() end) end
		God.conns = {}
	end
	local function ensureFF(char)
		if not char then return end
		local ff = char:FindFirstChild(God.ffName)
		if not ff then ff = Instance.new("ForceField"); ff.Name = God.ffName; ff.Visible = false; ff.Parent = char end
	end
	local function protectHumanoid(hum)
		if not hum then return end
		ensureFF(hum.Parent)
		table.insert(God.conns, hum.HealthChanged:Connect(function()
			if not God.enabled then return end
			if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
		end))
		table.insert(God.conns, hum.StateChanged:Connect(function(_, new)
			if not God.enabled then return end
			if new == Enum.HumanoidStateType.FallingDown or new == Enum.HumanoidStateType.Ragdoll then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end))
	end

	local function stopHB()
		if God.hb then pcall(function() God.hb:Disconnect() end); God.hb = nil end
	end

	local function startHB()
		stopHB()
		God.hb = RunService.Heartbeat:Connect(function()
			if not God.enabled then return end
			local plr = Players.LocalPlayer
			local char = plr and plr.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp then return end
			-- keep topped up and out of bad states
			if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
			local st = hum:GetState()
			if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			-- track safe position when standing
			local threshold = (workspace.FallenPartsDestroyHeight ~= 0 and workspace.FallenPartsDestroyHeight) or -500
			if hum.FloorMaterial ~= Enum.Material.Air and hrp.Position.Y > threshold + 50 then
				God.lastSafeCF = hrp.CFrame
			end
			-- anti-void: teleport back to last safe
			if hrp.Position.Y < threshold + 10 then
				local target = God.lastSafeCF or CFrame.new(hrp.Position.X, math.max(threshold + 60, 10), hrp.Position.Z)
				hrp.CFrame = target + Vector3.new(0, 5, 0)
			end
		end)
	end

	local function onCharacter(char)
		if not God.enabled then return end
		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Health = hum.MaxHealth
			pcall(function() hum.BreakJointsOnDeath = false end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end)
			protectHumanoid(hum)
			table.insert(God.conns, hum.Died:Connect(function()
				if not God.enabled then return end
				task.defer(function()
					local plr = Players.LocalPlayer
					if plr then pcall(function() plr:LoadCharacter() end) end
				end)
			end))
		end

	end
	local function setGod(on)
		God.enabled = on
		Players.LocalPlayer:SetAttribute("GodMode", on)
		disconnectAll()
		local char = Players.LocalPlayer.Character
		if on then
			startHB()
			if char then onCharacter(char) end
			table.insert(God.conns, Players.LocalPlayer.CharacterAdded:Connect(onCharacter))
		else
			stopHB()
			if char then local ff = char:FindFirstChild(God.ffName); if ff then ff:Destroy() end end

		end
	end

	-- Build card manually
	local card = New("Frame", {
		Name = "GodModeCardMain",
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 74),
	}, {})
	addCorner(card, 12)
	addStroke(card, Colors.Stroke, 1, 0.4)
	addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	card.Parent = pageMainContent

	local t = New("TextLabel", {
		Text = "God Mode",
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 22),
	}, {})
	t.Parent = card

	local sub = New("TextLabel", {
		Text = "Cegah damage (jatuh dan lainnya).",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -120, 0, 18),
	}, {})
	sub.Parent = card

	local sw = New("TextButton", {
		Name = "Switch",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Colors.SwitchOff,
		Size = UDim2.fromOffset(58, 28),
	}, {})
	addCorner(sw, 14)
	addStroke(sw, Colors.Stroke, 1, 0.6)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -14, 0.5, 0)
	sw.Parent = card

	local knob = New("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 2, 0.5, -12),
		AnchorPoint = Vector2.new(0,0),
	}, { })
	addCorner(knob, 12)
	knob.Parent = sw

	local function applySwitch(anim)
		local on = God.enabled
		local goalBg = on and Colors.Accent or Colors.SwitchOff
		local goalPos = on and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
		if anim then
			tween(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalBg})
			tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos})
		else
			sw.BackgroundColor3 = goalBg
			knob.Position = goalPos
		end
	end

	sw.Activated:Connect(function()
		setGod(not God.enabled)
		applySwitch(true)
	end)

	-- init from attribute
	if Players.LocalPlayer:GetAttribute("GodMode") == true then
		setGod(true)
		applySwitch(false)
	else
		setGod(false)
		applySwitch(false)
	end
end


-- Speed slider
do
	local Speed = { min = 8, max = 100, value = 16, conns = {} }
	local function clamp(v,a,b) if v < a then return a elseif v > b then return b else return v end end

	-- Card UI
	local card = New("Frame", {
		Name = "SpeedCard",
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 90),
	}, {})
	addCorner(card, 12)
	addStroke(card, Colors.Stroke, 1, 0.4)
	addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	card.Parent = pageMainContent

	local title = New("TextLabel", {
		Text = "Speed",
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 22),
	}, {})
	title.Parent = card

	local subtitle = New("TextLabel", {
		Text = "Atur kecepatan gerak pemain.",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 32),
		Size = UDim2.new(1, -120, 0, 18),
	}, {})
	subtitle.Parent = card

	local valueText = New("TextLabel", {
		Text = "16",
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1,0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(60, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, {})
	valueText.Parent = card

	local bar = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(60,48,78),
		BackgroundTransparency = 0.1,
		Position = UDim2.fromOffset(14, 60),
		Size = UDim2.new(1, -28, 0, 8),
	}, {})
	addCorner(bar, 4)
	bar.Parent = card

	local fill = New("Frame", {
		BackgroundColor3 = Colors.Accent,
		Size = UDim2.new(0, 0, 1, 0),
	}, {})
	addCorner(fill, 4)
	fill.Parent = bar

	local knob = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5,0.5),
		Position = UDim2.fromOffset(0, 4),
	}, {})
	addCorner(knob, 7)
	addStroke(knob, Colors.Stroke, 1, 0.5)
	knob.Parent = bar

	local function setUIByValue(v)
		local ratio = (v - Speed.min) / (Speed.max - Speed.min)
		ratio = clamp(ratio, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueText.Text = tostring(v)
	end

	local function applySpeed(v)
		Speed.value = clamp(v, Speed.min, Speed.max)
		setUIByValue(Speed.value)
		Players.LocalPlayer:SetAttribute("WalkSpeed", Speed.value)
		local char = Players.LocalPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = Speed.value
			end
		end
	end

	-- keep speed on character spawn and if changed
	table.insert(Speed.conns, Players.LocalPlayer.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.WalkSpeed = Speed.value
			local c
			c = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if math.abs(hum.WalkSpeed - Speed.value) > 0.1 then
					hum.WalkSpeed = Speed.value
				end
			end)
			table.insert(Speed.conns, c)
		end
	end))

	-- init from attribute or current humanoid
	do
		local attr = Players.LocalPlayer:GetAttribute("WalkSpeed")
		if typeof(attr) == "number" then
			Speed.value = clamp(attr, Speed.min, Speed.max)
		else
			local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			local base = (hum and hum.WalkSpeed) or 16
			Speed.value = clamp(base, Speed.min, Speed.max)
		end
		applySpeed(Speed.value)
	end

	-- input handling
	do
		local dragging = false
		local function updateFromX(x)
			local absPos = bar.AbsolutePosition.X
			local width = bar.AbsoluteSize.X
			local ratio = 0
			if width > 0 then ratio = (x - absPos) / width end
			ratio = clamp(ratio, 0, 1)
			local v = math.floor(Speed.min + ratio * (Speed.max - Speed.min) + 0.5)
			applySpeed(v)
		end
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				updateFromX(input.Position.X)
			end
		end)
		knob.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromX(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end
end

-- Fly toggle
do
	local Fly = { enabled = false, conns = {}, bv = nil, states = {W=false,A=false,S=false,D=false,Up=false,Down=false,Shift=false} }

	local function getHRP()
		local char = Players.LocalPlayer.Character
		if not char then return nil end
		return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	end

	local function cleanupBV()
		if Fly.bv then Fly.bv:Destroy(); Fly.bv = nil end
	end

	local function disconnectAll()
		for _,c in ipairs(Fly.conns) do pcall(function() c:Disconnect() end) end
		Fly.conns = {}
	end

	local function ensureBV()
		local hrp = getHRP()
		if not hrp then return end
		if not Fly.bv or Fly.bv.Parent ~= hrp then
			cleanupBV()
			local bv = Instance.new("BodyVelocity")
			bv.Name = "FlyBV"
			bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bv.P = 10000
			bv.Velocity = Vector3.new()
			bv.Parent = hrp
			Fly.bv = bv
		end
	end

	local function getSpeed()
		local s = Players.LocalPlayer:GetAttribute("WalkSpeed")
		if typeof(s) ~= "number" then s = 16 end
		if Fly.states.Shift then s = s * 2 end
		return s
	end

	local function updateVelocity()
		if not Fly.enabled then return end
		ensureBV()
		local hrp = getHRP()
		local bv = Fly.bv
		if not hrp or not bv then return end

		local cam = workspace.CurrentCamera
		if not cam then return end
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local up = Vector3.new(0,1,0)
		local forward = Vector3.new(look.X, 0, look.Z)
		local side = Vector3.new(right.X, 0, right.Z)

		local dir = Vector3.new()
		if Fly.states.W then dir += forward end
		if Fly.states.S then dir -= forward end
		if Fly.states.D then dir += side end
		if Fly.states.A then dir -= side end
		if Fly.states.Up then dir += up end
		if Fly.states.Down then dir -= up end
		if dir.Magnitude > 0 then dir = dir.Unit end

		local speed = getSpeed()
		bv.Velocity = dir * speed
	end

	local function bindInput()
		local UIS = UserInputService
		local function set(k, v)
			Fly.states[k] = v
			updateVelocity()
		end
		table.insert(Fly.conns, UIS.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			local key = input.KeyCode
			if key == Enum.KeyCode.W then set("W", true)
			elseif key == Enum.KeyCode.S then set("S", true)
			elseif key == Enum.KeyCode.A then set("A", true)
			elseif key == Enum.KeyCode.D then set("D", true)
			elseif key == Enum.KeyCode.Space then set("Up", true)
			elseif key == Enum.KeyCode.LeftControl then set("Down", true)
			elseif key == Enum.KeyCode.LeftShift then set("Shift", true)
			end
		end))
		table.insert(Fly.conns, UIS.InputEnded:Connect(function(input)
			local key = input.KeyCode
			if key == Enum.KeyCode.W then set("W", false)
			elseif key == Enum.KeyCode.S then set("S", false)
			elseif key == Enum.KeyCode.A then set("A", false)
			elseif key == Enum.KeyCode.D then set("D", false)
			elseif key == Enum.KeyCode.Space then set("Up", false)
			elseif key == Enum.KeyCode.LeftControl then set("Down", false)
			elseif key == Enum.KeyCode.LeftShift then set("Shift", false)
			end
		end))
		table.insert(Fly.conns, RunService.Heartbeat:Connect(function()
			updateVelocity()
		end))
	end

	local function setFly(flag)
		if Fly.enabled == flag then return end
		Fly.enabled = flag
		Players.LocalPlayer:SetAttribute("Fly", flag)
		if flag then
			bindInput()
			ensureBV()
		else
			disconnectAll()
			cleanupBV()
			local hrp = getHRP()
			if hrp then hrp.AssemblyLinearVelocity = Vector3.new() end
		end
	end

	-- UI card
	local card = New("Frame", {
		Name = "FlyCard",
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 74),
	}, {})
	addCorner(card, 12)
	addStroke(card, Colors.Stroke, 1, 0.4)
	addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	card.Parent = pageMainContent

	local t = New("TextLabel", {
		Text = "Fly",
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 22),
	}, {})
	t.Parent = card

	local sub = New("TextLabel", {
		Text = "Terbang bebas: WASD, Space naik, Ctrl turun, Shift boost",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -120, 0, 18),
	}, {})
	sub.Parent = card

	local sw = New("TextButton", {
		Name = "Switch",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Colors.SwitchOff,
		Size = UDim2.fromOffset(58, 28),
	}, {})
	addCorner(sw, 14)
	addStroke(sw, Colors.Stroke, 1, 0.6)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -14, 0.5, 0)
	sw.Parent = card

	local knob = New("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 2, 0.5, -12),
		AnchorPoint = Vector2.new(0,0),
	}, { })
	addCorner(knob, 12)
	knob.Parent = sw

	local function applySwitch(anim)
		local on = Fly.enabled
		local goalBg = on and Colors.Accent or Colors.SwitchOff
		local goalPos = on and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
		if anim then
			tween(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalBg})
			tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos})
		else
			sw.BackgroundColor3 = goalBg
			knob.Position = goalPos
		end
	end

	sw.Activated:Connect(function()
		setFly(not Fly.enabled)
		applySwitch(true)
	end)

	-- init from attribute
	if Players.LocalPlayer:GetAttribute("Fly") == true then
		setFly(true)
		applySwitch(false)
	else
		setFly(false)
		applySwitch(false)
	end

	-- hotkey toggle (F) and attribute sync
	table.insert(Fly.conns, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.F then
			setFly(not Fly.enabled)
			applySwitch(true)
		end
	end))
	table.insert(Fly.conns, Players.LocalPlayer:GetAttributeChangedSignal("Fly"):Connect(function()
		local v = Players.LocalPlayer:GetAttribute("Fly") == true
		setFly(v)
		applySwitch(true)
	end))

	-- re-ensure on respawn if still enabled
	table.insert(Fly.conns, Players.LocalPlayer.CharacterAdded:Connect(function()
		if Fly.enabled then task.defer(function() ensureBV() end) end
	end))
end

-- NoClip toggle
do
	local NoClip = { enabled = false, conns = {}, prev = {} }

	local function getChar()
		return Players.LocalPlayer.Character
	end

	local function disconnectAll()
		for _,c in ipairs(NoClip.conns) do pcall(function() c:Disconnect() end) end
		NoClip.conns = {}
	end

	local function setNoClip(flag)
		if NoClip.enabled == flag then return end
		NoClip.enabled = flag
		Players.LocalPlayer:SetAttribute("NoClip", flag)
		disconnectAll()
		if flag then
			local function step()
				local char = getChar()
				if not char then return end
				for _,desc in ipairs(char:GetDescendants()) do
					if desc:IsA("BasePart") then
						if desc.CanCollide and NoClip.prev[desc] == nil then
							NoClip.prev[desc] = true
						end
						desc.CanCollide = false
					end
				end
			end
			table.insert(NoClip.conns, RunService.Stepped:Connect(step))
			table.insert(NoClip.conns, Players.LocalPlayer.CharacterAdded:Connect(function()
				task.defer(function() if NoClip.enabled then step() end end)
			end))
		else
			for part,_ in pairs(NoClip.prev) do
				if typeof(part) == "Instance" and part.Parent then
					pcall(function() part.CanCollide = true end)
				end
			end
			NoClip.prev = {}
		end
	end

	-- UI card
	local card = New("Frame", {
		Name = "NoClipCard",
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 74),
	}, {})
	addCorner(card, 12)
	addStroke(card, Colors.Stroke, 1, 0.4)
	addGradient(card, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	card.Parent = pageMainContent

	local t = New("TextLabel", {
		Text = "NoClip",
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -120, 0, 22),
	}, {})
	t.Parent = card

	local sub = New("TextLabel", {
		Text = "Tembus objek (hindari menabrak).",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.Accent,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -120, 0, 18),
	}, {})
	sub.Parent = card

	local sw = New("TextButton", {
		Name = "Switch",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Colors.SwitchOff,
		Size = UDim2.fromOffset(58, 28),
	}, {})
	addCorner(sw, 14)
	addStroke(sw, Colors.Stroke, 1, 0.6)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -14, 0.5, 0)
	sw.Parent = card

	local knob = New("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(0, 2, 0.5, -12),
		AnchorPoint = Vector2.new(0,0),
	}, { })
	addCorner(knob, 12)
	knob.Parent = sw

	local function applySwitch(anim)
		local on = NoClip.enabled
		local goalBg = on and Colors.Accent or Colors.SwitchOff
		local goalPos = on and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)
		if anim then
			tween(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalBg})
			tween(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goalPos})
		else
			sw.BackgroundColor3 = goalBg
			knob.Position = goalPos
		end
	end

	sw.Activated:Connect(function()
		setNoClip(not NoClip.enabled)
		applySwitch(true)
	end)

	-- init from attribute
	if Players.LocalPlayer:GetAttribute("NoClip") == true then
		setNoClip(true)
		applySwitch(false)
	else
		setNoClip(false)
		applySwitch(false)
	end
end

-- Teleport page
do
	local header = New("TextLabel", {
		Text = "Teleport",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 24),
	}, {})
	header.Parent = pageTeleport

	-- Scroll container under header to allow vertical scrolling
	local scrollContainer = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -34), -- 24 header + 10 page padding
	}, {})
	scrollContainer.LayoutOrder = 2
	scrollContainer.Parent = pageTeleport

	local content = New("ScrollingFrame", {
		Name = "TeleportScroll",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
	}, {})
	content.Parent = scrollContainer
	do
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 10)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = content
	end
	header.LayoutOrder = 1


	local function createTeleportSection(sectionTitle, areaName, maxCheckpoint)
		local section = New("Frame", {
			BackgroundColor3 = Colors.Surface,
			BackgroundTransparency = 0.15,
			Size = UDim2.new(1, -8, 0, 132),
			ClipsDescendants = false,
		}, {})
		addCorner(section, 12)
		addStroke(section, Colors.Stroke, 1, 0.4)
		addGradient(section, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
		section.Parent = content

		local titleLt = New("TextLabel", {
			Text = sectionTitle,
			Font = Enum.Font.GothamSemibold,
			TextSize = 18,
			TextColor3 = Colors.TextPrimary,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 22),
		}, {})
		titleLt.Parent = section
		if areaName == "MountSibuatan" then section.Size = UDim2.new(1, -8, 0, 172) end

		local cpOptions = {}
		for i = 1, math.max(1, maxCheckpoint) do
			cpOptions[i] = "Checkpoints "..i
		end
		-- cpOptionsOverrideTalamau
		if areaName == "MountTalamau" then
			local autoToggle = New("TextButton", {
				Name = "AutoSummitTalamauToggle",
				Text = "Auto Summit: OFF",
				Font = Enum.Font.GothamSemibold,
				TextSize = 16,
				TextColor3 = Colors.TextPrimary,
				AutoButtonColor = false,
				BackgroundColor3 = Colors.Surface2,
				BackgroundTransparency = 0.2,
				Position = UDim2.fromOffset(150, 86),
				Size = UDim2.fromOffset(160, 34),
				Parent = section,
				ZIndex = 20,
			}, {})
			addCorner(autoToggle, 10)
			addStroke(autoToggle, Colors.Stroke, 1, 0.4)
			local function applyToggleUI(on)
				tween(autoToggle, TweenInfo.new(0.12), {
					BackgroundTransparency = on and 0.05 or 0.2,
					BackgroundColor3 = on and Colors.Accent or Colors.Surface2,
				})
				autoToggle.Text = "Auto Summit: " .. (on and "ON" or "OFF")
			end
			if player:GetAttribute("AutoSummitTalamau") == nil then
				player:SetAttribute("AutoSummitTalamau", false)
			end
			local on = (player:GetAttribute("AutoSummitTalamau") == true)
			local function stillOn() return player:GetAttribute("AutoSummitTalamau") == true end
			local function safeWait(sec)
				local t, step = 0, 0.1; sec = sec or 0
				while t < sec do
					if not stillOn() then return false end
					task.wait(step); t = t + step
				end
				return stillOn()
			end
			local autoRunning = false
			local function startAuto()
				if autoRunning then return end
				autoRunning = true
				task.spawn(function()
					while stillOn() do
						teleportTo(areaName, 1)
						local char = player.Character or player.CharacterAdded:Wait()
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum then hum.Health = 0 end
						if not stillOn() then break end
						player.CharacterAdded:Wait()
						if not stillOn() then break end
						if not safeWait(math.random(5,8)) then break end
					end
					autoRunning = false
					if not stillOn() then
						applyToggleUI(false)
					end
				end)
			end
			applyToggleUI(on)
			if on then startAuto() end
			autoToggle.MouseEnter:Connect(function()
				if on then return end
				tween(autoToggle, TweenInfo.new(0.12), {BackgroundTransparency = 0.1})
			end)
			autoToggle.MouseLeave:Connect(function()
				if on then
					tween(autoToggle, TweenInfo.new(0.12), {BackgroundTransparency = 0.05})
				else
					tween(autoToggle, TweenInfo.new(0.12), {BackgroundTransparency = 0.2})
				end
			end)
			autoToggle.Activated:Connect(function()
				on = not on
				player:SetAttribute("AutoSummitTalamau", on)
				applyToggleUI(on)
				if on then startAuto() end
			end)
		end






local selectedCP = 1

		local ddContainer = New("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 44),
			Size = UDim2.fromOffset(180, 34),
			Parent = section,
			ZIndex = 15,
		}, {})

		local ddButton = New("TextButton", {
			Text = cpOptions[selectedCP] .. " ▾",
			Font = Enum.Font.GothamSemibold,
			TextSize = 16,
			TextColor3 = Colors.TextPrimary,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BackgroundColor3 = Colors.Surface2,
			BackgroundTransparency = 0.2,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = ddContainer,
			ZIndex = 16,
		}, {})
		addCorner(ddButton, 10)
		addStroke(ddButton, Colors.Stroke, 1, 0.6)
		local ddPad = Instance.new("UIPadding")
		ddPad.PaddingLeft = UDim.new(0, 12)
		ddPad.PaddingRight = UDim.new(0, 10)
		ddPad.Parent = ddButton
		ddButton.MouseEnter:Connect(function() tween(ddButton, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}) end)
		ddButton.MouseLeave:Connect(function() tween(ddButton, TweenInfo.new(0.12), {BackgroundTransparency = 0.2}) end)

		local itemH = 30
		local gap = 4
		local padTop, padBottom = 4, 4
		local contentHeight = padTop + (#cpOptions * itemH) + ((#cpOptions - 1) * gap) + padBottom
		local maxMenuHeight = 240

		local menu = New("ScrollingFrame", {
			BackgroundColor3 = Colors.Surface,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, 6),
			Size = UDim2.new(1, 0, 0, math.min(contentHeight, maxMenuHeight)),
			Visible = false,
			Parent = overlay,
			ZIndex = 110,
			ScrollBarImageTransparency = 0.25,
			ScrollBarThickness = 6,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(0, 0, 0, contentHeight),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
		}, {})
		addCorner(menu, 10)
		addStroke(menu, Colors.Stroke, 1, 0.5)
		addGradient(menu, Color3.fromRGB(38,28,58), Color3.fromRGB(28,22,42), 90)
		local menuPad = Instance.new("UIPadding")
		menuPad.PaddingTop = UDim.new(0, padTop)
		menuPad.PaddingBottom = UDim.new(0, padBottom)
		menuPad.PaddingLeft = UDim.new(0, 4)
		menuPad.PaddingRight = UDim.new(0, 4)
		menuPad.Parent = menu
		local menuList = Instance.new("UIListLayout")
		menuList.FillDirection = Enum.FillDirection.Vertical
		menuList.SortOrder = Enum.SortOrder.LayoutOrder
		menuList.Padding = UDim.new(0, gap)
		menuList.Parent = menu

		local function positionMenu()
			local absPos = ddButton.AbsolutePosition
			local absSize = ddButton.AbsoluteSize
			menu.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 6)
			menu.Size = UDim2.fromOffset(absSize.X, math.min(contentHeight, maxMenuHeight))
		end
		ddButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(function() if menu.Visible then positionMenu() end end)
		content:GetPropertyChangedSignal("CanvasPosition"):Connect(function() if menu.Visible then positionMenu() end end)


		local items = {}
		local function refreshMenuSel()
			for idx, btn in ipairs(items) do
				local isSel = (idx == selectedCP)
				tween(btn, TweenInfo.new(0.1), {
					BackgroundTransparency = isSel and 0.05 or 0.2,
					BackgroundColor3 = isSel and Colors.Accent or Colors.Surface2,
				})
			end
		end

		local function choose(idx)
			selectedCP = idx
			ddButton.Text = cpOptions[idx] .. " ▾"
			refreshMenuSel()
			menu.Visible = false
		end

		for i, labelText in ipairs(cpOptions) do
			local it = New("TextButton", {
				Text = labelText,
				Font = Enum.Font.GothamSemibold,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Colors.TextPrimary,
				AutoButtonColor = false,
				BackgroundColor3 = Colors.Surface2,
				BackgroundTransparency = 0.2,
				Size = UDim2.new(1, -0, 0, itemH),
				Parent = menu,
				ZIndex = 31,
			}, {})
			addCorner(it, 8)
			addStroke(it, Colors.Stroke, 1, 0.6)
			local ip = Instance.new("UIPadding")
			ip.PaddingLeft = UDim.new(0, 10)
			ip.Parent = it
			it.MouseEnter:Connect(function() tween(it, TweenInfo.new(0.12), {BackgroundTransparency = 0.12}) end)
			it.MouseLeave:Connect(function() refreshMenuSel() end)
			it.Activated:Connect(function() choose(i) end)
			items[i] = it
		end
		refreshMenuSel()

		ddButton.Activated:Connect(function()
			local willOpen = not menu.Visible
			if willOpen then positionMenu() end
			menu.Visible = willOpen
			overlay.Visible = willOpen
		end)

		local function pointIn(obj, p)
			local pos = obj.AbsolutePosition
			local size = obj.AbsoluteSize
			return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
		end
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if menu.Visible then
					local p = Vector2.new(input.Position.X, input.Position.Y)
					if not pointIn(ddContainer, p) and not pointIn(menu, p) then
						menu.Visible = false
						overlay.Visible = false
					end
				end
			end
		end)

		local tpBtn = New("TextButton", {
			Text = "Teleport",
			Font = Enum.Font.GothamSemibold,
			TextSize = 16,
			TextColor3 = Colors.TextPrimary,
			AutoButtonColor = false,
			BackgroundColor3 = Colors.Accent,
			BackgroundTransparency = 0.05,
			Position = UDim2.fromOffset(14, 86),
			Size = UDim2.fromOffset(120, 34),
			Parent = section,
		}, {})
		addCorner(tpBtn, 10)
		addStroke(tpBtn, Colors.Stroke, 1, 0.4)
		tpBtn.MouseEnter:Connect(function() tween(tpBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0}) end)
		tpBtn.MouseLeave:Connect(function() tween(tpBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.05}) end)
		if areaName == "MountSibuatan" then
			section.Size = UDim2.new(1, -8, 0, 172)
			local autoBtn = New("TextButton", {
				Name = "AutoFinishButton",
				Text = "Auto Finish",
				Font = Enum.Font.GothamSemibold,
				TextSize = 16,
				TextColor3 = Colors.TextPrimary,
				AutoButtonColor = false,
				BackgroundColor3 = Colors.Accent,
				BackgroundTransparency = 0.05,
				Position = UDim2.fromOffset(14, 128),
				Size = UDim2.fromOffset(120, 34),
				Parent = section,
			}, {})
			addCorner(autoBtn, 10)
			addStroke(autoBtn, Colors.Stroke, 1, 0.4)
			autoBtn.MouseEnter:Connect(function() tween(autoBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0}) end)
			autoBtn.MouseLeave:Connect(function() tween(autoBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.05}) end)
			local autoBusy = false
			autoBtn.Activated:Connect(function()
				if autoBusy then return end
				autoBusy = true
				-- Direct jump to workspace.Checkpoints.Checkpoint46; fallback to existing lookup if missing
				local checkpoints = workspace:FindFirstChild("Checkpoints")
				local target = checkpoints and (checkpoints:FindFirstChild("Checkpoint46") or checkpoints:FindFirstChild("46"))
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if not hrp then
					player.CharacterAdded:Wait()
					hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				end
				if target and hrp then
					local basePart = target:IsA("BasePart") and target or (target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")))
					if basePart then
						hrp.CFrame = basePart.CFrame * CFrame.new(0, 3, 0)
					else
						teleportTo(areaName, maxCheckpoint)
					end
				else
					teleportTo(areaName, maxCheckpoint)
				end
				task.delay(0.2, function() autoBusy = false end)
			end)
		end

		if areaName == "MountHoreg" then
			section.Size = UDim2.new(1, -8, 0, 164)
			local note = New("TextLabel", {
				Text = "Note : Teleport agar aman hanya bisa dilakukan dari checkpoints 1.",
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = Colors.TextPrimary,
				BackgroundTransparency = 1,
				TextWrapped = true,
				Position = UDim2.fromOffset(14, 128),
				Size = UDim2.new(1, -28, 0, 32),
			}, {})
			note.Parent = section
		end


		local busy = false
		tpBtn.Activated:Connect(function()
			if busy then return end
			busy = true
			teleportTo(areaName, selectedCP)
			task.delay(0.3, function() busy = false end)
		end)
	end

	createTeleportSection("Mount Daun Teleport", "MountDaun", 4)
	createTeleportSection("Mount Sibuatan Teleport", "MountSibuatan", 46)
	createTeleportSection("Mount Yagataw Teleport", "MountYagataw", 8)

	createTeleportSection("Mount Horeg Teleport", "MountHoreg", 5)
	createTeleportSection("Mount Talamau Teleport", "MountTalamau", 1)
	end

-- Other pages
do
	local label = New("TextLabel", {
		Text = "Misc",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
	}, {})
	label.Parent = pageMisc
end

do
	local label = New("TextLabel", {
		Text = "Info",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
	}, {})
	label.Parent = pageInfo
end

do
	local label = New("TextLabel", {
		Text = "Server",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
	}, {})
	label.Parent = pageServer


	-- Rejoin controls
	local rejoinCard = New("Frame", {
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 74),
	}, {})
	addCorner(rejoinCard, 12)
	addStroke(rejoinCard, Colors.Stroke, 1, 0.4)
	addGradient(rejoinCard, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	rejoinCard.Parent = pageServer

	local btnSame = New("TextButton", {
		Text = "Rejoin (Same Server)",
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextColor3 = Colors.TextPrimary,
		AutoButtonColor = false,
		BackgroundColor3 = Colors.Accent,
		BackgroundTransparency = 0.05,
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.fromOffset(220, 34),
		Parent = rejoinCard,
	}, {})
	addCorner(btnSame, 10)
	addStroke(btnSame, Colors.Stroke, 1, 0.4)
	btnSame.MouseEnter:Connect(function() tween(btnSame, TweenInfo.new(0.12), {BackgroundTransparency = 0}) end)
	btnSame.MouseLeave:Connect(function() tween(btnSame, TweenInfo.new(0.12), {BackgroundTransparency = 0.05}) end)
	btnSame.Activated:Connect(function()
		logStatus("Rejoining same server...")
		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		end)
		if not ok then logStatus("Rejoin failed: "..tostring(err)) end
	end)

	local btnNew = New("TextButton", {
		Text = "Rejoin (New Server)",
		Font = Enum.Font.GothamSemibold,
		TextSize = 16,
		TextColor3 = Colors.TextPrimary,
		AutoButtonColor = false,
		BackgroundColor3 = Colors.Accent,
		BackgroundTransparency = 0.05,
		Position = UDim2.fromOffset(244, 28),
		Size = UDim2.fromOffset(220, 34),
		Parent = rejoinCard,
	}, {})
	addCorner(btnNew, 10)
	addStroke(btnNew, Colors.Stroke, 1, 0.4)
	btnNew.MouseEnter:Connect(function() tween(btnNew, TweenInfo.new(0.12), {BackgroundTransparency = 0}) end)
	btnNew.MouseLeave:Connect(function() tween(btnNew, TweenInfo.new(0.12), {BackgroundTransparency = 0.05}) end)
	btnNew.Activated:Connect(function()
		logStatus("Rejoining a new server...")
		local ok, err = pcall(function()
			TeleportService:Teleport(game.PlaceId, player)
		end)
		if not ok then logStatus("Rejoin failed: "..tostring(err)) end
	end)

	-- Status Logs
	local logCard = New("Frame", {
		BackgroundColor3 = Colors.Surface,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, -8, 0, 180),
	}, {})
	addCorner(logCard, 12)
	addStroke(logCard, Colors.Stroke, 1, 0.4)
	addGradient(logCard, Color3.fromRGB(40,30,62), Color3.fromRGB(32,24,48), 90)
	logCard.Parent = pageServer

	local logTitle = New("TextLabel", {
		Text = "Status Logs",
		Font = Enum.Font.GothamSemibold,
		TextSize = 18,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 22),
	}, {})
	logTitle.Parent = logCard

	local logFrame = New("ScrollingFrame", {
		BackgroundTransparency = 0.1,
		BackgroundColor3 = Colors.Surface2,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 1, -48),
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0,0,0,0),
	}, {})
	addCorner(logFrame, 8)
	addStroke(logFrame, Colors.Stroke, 1, 0.4)
	logFrame.Parent = logCard

	local logPad = Instance.new("UIPadding")
	logPad.PaddingTop = UDim.new(0, 6)
	logPad.PaddingBottom = UDim.new(0, 6)
	logPad.PaddingLeft = UDim.new(0, 8)
	logPad.PaddingRight = UDim.new(0, 8)
	logPad.Parent = logFrame

	local logText = New("TextLabel", {
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Colors.TextPrimary,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -4, 0, 0),
		Position = UDim2.fromOffset(2, 0),
	}, {})
	logText.Parent = logFrame

	StatusLog.onUpdate = function(text)
		logText.Text = text or ""
	end
	if #StatusLog.buffer > 0 then
		StatusLog.onUpdate(table.concat(StatusLog.buffer, "\n"))
	end
end

-- Nav
local navMain = navButton("Main")
local navHunt = navButton("Hunt")
local navTeleport = navButton("Teleport")
local navMisc = navButton("Misc")
local navInfo = navButton("Info")
local navServer = navButton("Server")

local navButtons = {
	{button = navMain, page = pageMain},
	{button = navHunt, page = pageHunt},
	{button = navTeleport, page = pageTeleport},
	{button = navMisc, page = pageMisc},
	{button = navInfo, page = pageInfo},
	{button = navServer, page = pageServer},
}

local function showPage(target)
	for _, it in ipairs(navButtons) do
		it.page.Visible = (it.page == target)
		tween(it.button, TweenInfo.new(0.12), {BackgroundColor3 = it.page.Visible and Colors.Accent or Colors.Surface2})
	end
end
for _, it in ipairs(navButtons) do
	it.button.Activated:Connect(function() showPage(it.page) end)
end
showPage(pageHunt)
print('[WKHub] Boot: showPage(pageHunt) called')

-- Minimize -> dock bubble
local minimized = false
local function setMinimized(flag)
	minimized = flag
	if minimized then
		window.Visible = false
		sidebar.Visible = false
		pages.Visible = false
		dockIcon.Visible = true
		dockIcon.Size = UDim2.fromOffset(1, 1)
		tween(dockIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(46, 46)})
	else
		dockIcon.Visible = false
		window.Visible = true
		sidebar.Visible = true
		pages.Visible = true
	end
end

btnMin.Activated:Connect(function()
	setMinimized(not minimized)
end)

dockIcon.Activated:Connect(function()
	setMinimized(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.T then
		if not gui.Enabled then gui.Enabled = true end
		setMinimized(not minimized)
	end
end)

btnClose.Activated:Connect(function()
	setMinimized(true)
	gui.Enabled = true
end)

-- Failsafe: force show on startup
pcall(function()
	task.defer(function()
		if gui then gui.Enabled = true end
		if typeof(setMinimized) == "function" then setMinimized(false) end
		if typeof(showPage) == "function" and pageHunt then showPage(pageHunt)
			print('[WKHub] Boot: showPage(pageHunt) called') end
	end)
end)
