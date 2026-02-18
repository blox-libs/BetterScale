--[=[
	BetterScale, v2.0 - A responsive UI scaling solution for Roblox.

	Example:
	```lua
	local BetterScale = require(path.to.BetterScale)
	local uiScale = path.to.UIScale

	uiScale:SetAttribute("Ratio", 1.2)
	uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))
	uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
	uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X)
	uiScale:SetAttribute("InnerRatios", '{"Large": 0.8, "Small": 1.3}')

	local betterScale = BetterScale.new(uiScale)
	betterScale:Track()

	betterScale:Destroy()
	```
	
	View source & license: https://github.com/blox-libs/BetterScale
]=]--

--!strict

debug.setmemorycategory("BetterScale")

local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- [ Configs ] --

local GUI_CONTAINERS = {"ScreenGui", "BillboardGui", "DockWidgetPluginGui", "SurfaceGui"}

local DEFAULT_RANGE = NumberRange.new(0, math.huge)
local DEFAULT_RATIO = 1
local DEFAULT_RESOLUTION = Vector2.new(1280, 720)
local DEFAULT_AXIS = Enum.ScrollingDirection.XY

-- [ Types ] --

type DockWidgetPluginGui = ScreenGui & {
	HostWidgetWasRestored: boolean,
	Title: string,
}

export type Attributes = {
	Range: NumberRange,
	Ratio: number,
	Resolution: Vector2,
	Axis: Enum.ScrollingDirection
}

export type GuiContainer = ScreenGui
| DockWidgetPluginGui
| BillboardGui
| SurfaceGui

export type BetterScale = typeof(setmetatable({} :: {
	_isTracking: boolean,
	_uiScale: UIScale,
	_innerRatios: {[string]: number}?,
	_guiContainer: GuiContainer?,
	_updateScheduled: boolean,

	_connections: {RBXScriptConnection},
	_scaleConnection: RBXScriptConnection?,
	_destroyConnection: RBXScriptConnection?,

	ComputeScale: (self: BetterScale) -> number?,

	GetAttributes: (self: BetterScale, displaySize: Enum.DisplaySize?) -> Attributes,
	GetAbsoluteSize: (self: BetterScale) -> Vector2?,

	UpdateContainer: (self: BetterScale) -> (),
	UpdateInnerRatios: (self: BetterScale) -> (),
	UpdateScale: (self: BetterScale) -> (),

	Track: (self: BetterScale) -> (),
	UnTrack: (self: BetterScale) -> (),

	Destroy: (self: BetterScale) -> (),
}, {} :: {
	__index: BetterScale
}))

-- [ Private ] --

local function getGuiContainer(uiScale: UIScale): GuiContainer?
	local parent = uiScale.Parent
	
	while parent do
		if table.find(GUI_CONTAINERS, parent.ClassName) then
			return parent :: any
		end
		parent = parent.Parent
	end
	
	return nil
end

local function disconnectAll(connections: {RBXScriptConnection})
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

-- [ BetterScale ] --

local BetterScale = {}
BetterScale.__index = BetterScale

function BetterScale.new(uiScale: UIScale): BetterScale
	local self = setmetatable({}, BetterScale) :: any

	self._connections = {}
	self._isTracking = false
	self._updateScheduled = false

	self._uiScale = uiScale
	self._guiContainer = getGuiContainer(uiScale)

	self._destroyConnection = uiScale.Destroying:Once(function()
		self:Destroy()
	end)

	return self
end

function BetterScale.ComputeScale(self: BetterScale): number?
	if not self._guiContainer then
		return nil
	end

	local attributes = self:GetAttributes(GuiService.ViewportDisplaySize)
	local size = self:GetAbsoluteSize() :: Vector2

	local ratio = attributes.Ratio
	local range = attributes.Range
	local resolution = attributes.Resolution
	local axis = attributes.Axis

	local scale: number

	if axis == Enum.ScrollingDirection.X then
		scale = size.X / resolution.X
	elseif axis == Enum.ScrollingDirection.Y then
		scale = size.Y / resolution.Y
	else
		local scaleX = size.X / resolution.X
		local scaleY = size.Y / resolution.Y
		scale = math.min(scaleX, scaleY)
	end

	return math.clamp(scale * ratio, range.Min, range.Max)
end

function BetterScale.GetAttributes(self: BetterScale, displaySize: Enum.DisplaySize?)
	local attributes = self._uiScale:GetAttributes() :: Attributes

	attributes.Range = attributes.Range or DEFAULT_RANGE
	attributes.Ratio = attributes.Ratio or DEFAULT_RATIO
	attributes.Resolution = attributes.Resolution or DEFAULT_RESOLUTION
	attributes.Axis = attributes.Axis or DEFAULT_AXIS

	if not displaySize then
		return attributes
	end

	local innerRatios = self._innerRatios
	if not innerRatios then
		return attributes
	end

	local innerRatio = innerRatios[displaySize.Name]
	if innerRatio then
		attributes.Ratio *= innerRatio
	end

	return attributes
end

function BetterScale.UpdateInnerRatios(self: BetterScale): ()
	local innerRatios = self._uiScale:GetAttribute("InnerRatios")
	if type(innerRatios) ~= "string" then
		self._innerRatios = nil
		return
	end

	local success, result: {[string]: number} = pcall(HttpService.JSONDecode, HttpService, innerRatios)
	if not success or type(result) ~= "table" then
		self._innerRatios = nil
		return
	end

	for key, value in result do
		if type(value) ~= "number" then
			self._innerRatios = nil
			warn(`Invalid InnerRatios: {key} is not a number`)
			return
		end
	end

	self._innerRatios = result
end

function BetterScale.UpdateContainer(self: BetterScale): ()
	self._guiContainer = getGuiContainer(self._uiScale)

	if self._scaleConnection then
		self._scaleConnection:Disconnect()
		self._scaleConnection = nil
	end

	if self._guiContainer and self._isTracking then
		self._scaleConnection = self._guiContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:UpdateScale()
		end)
	end
end

function BetterScale.GetAbsoluteSize(self: BetterScale): Vector2?
	if self._guiContainer then
		return self._guiContainer.AbsoluteSize
	end

	return nil
end

function BetterScale.UpdateScale(self: BetterScale): ()
	if not self._guiContainer or not self._isTracking or self._updateScheduled then
		return
	end

	self._updateScheduled = true

	RunService.RenderStepped:Once(function()
		self._updateScheduled = false

		local compute = self:ComputeScale()
		if compute and compute ~= self._uiScale.Scale then
			self._uiScale.Scale = compute
		end
	end)
end

function BetterScale.Track(self: BetterScale)
	if self._isTracking then
		return
	end

	self._isTracking = true
	
	self:UpdateContainer()
	self:UpdateInnerRatios()
	self:UpdateScale()

	table.insert(self._connections, self._uiScale.AncestryChanged:Connect(function()
		self:UpdateContainer()
	end))

	table.insert(self._connections, self._uiScale.AttributeChanged:Connect(function(attribute)
		if attribute == "InnerRatios" then
			self:UpdateInnerRatios()
		end
		
		self:UpdateScale()
	end))
end

function BetterScale.UnTrack(self: BetterScale)
	if not self._isTracking then
		return
	end

	self._isTracking = false

	if self._scaleConnection then
		self._scaleConnection:Disconnect()
	end

	disconnectAll(self._connections)
end

function BetterScale.Destroy(self: BetterScale)
	self:UnTrack()

	if self._destroyConnection then
		self._destroyConnection:Disconnect()
		self._destroyConnection = nil
	end
end

return BetterScale
