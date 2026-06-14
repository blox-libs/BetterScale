--[=[
	BetterScale, v2.1.0
	A UI scaling solution for Roblox, without the headache.

	Example:
	```lua
	local BetterScale = require(path.to.BetterScale)
	local uiScale = path.to.UIScale

	-- Configure scaling attributes
	uiScale:SetAttribute("Ratio", 1.2)
	uiScale:SetAttribute("Range", NumberRange.new(0.5, 2.0))
	uiScale:SetAttribute("Resolution", Vector2.new(1920, 1080))
	uiScale:SetAttribute("Axis", Enum.ScrollingDirection.X) -- X | Y | XY
	uiScale:SetAttribute("DisplayRatios", '{"Large": 0.8, "Small": 1.3}')

	-- Quick usage: create + track in one call
	local cleanup = BetterScale.build(uiScale)
	cleanup()

	-- Or manual control
	local betterScale = BetterScale.new(uiScale)
	betterScale:Track()

	-- Force a refresh manually
	betterScale:Update()

	-- Type checking
	if BetterScale.is(betterScale) then
		print("It's a BetterScale instance!")
	end

	-- Later cleanup
	betterScale:Destroy()
	```
	
	View source & license: https://github.com/bloxlibs/BetterScale
]=]--

--!strict

debug.setmemorycategory("BetterScale")

local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local GUI_CONTAINERS = {"ScreenGui", "BillboardGui", "DockWidgetPluginGui", "SurfaceGui"}

local DEFAULT_RANGE = NumberRange.new(0, math.huge)
local DEFAULT_RESOLUTION = Vector2.new(1280, 720)
local DEFAULT_AXIS = Enum.ScrollingDirection.XY
local DEFAULT_RATIO = 1


export type Attributes = {
	Range: NumberRange,
	Ratio: number,
	Resolution: Vector2,
	Axis: Enum.ScrollingDirection,
	DisplayRatio: {[string]: number}?
}

export type GuiContainer = ScreenGui
| DockWidgetPluginGui
| BillboardGui
| SurfaceGui

export type BetterScale = setmetatable<{
	_isTracking: boolean,
	_uiScale: UIScale,
	_displayRatios: {[string]: number}?,
	_guiContainer: GuiContainer?,

	_connections: {RBXScriptConnection},
	_scaleConnection: RBXScriptConnection?,
	_ancestryChangedConnection: RBXScriptConnection?,

	GetAttributes: (self: BetterScale, displaySize: Enum.DisplaySize?) -> Attributes,
	GetAbsoluteSize: (self: BetterScale) -> Vector2?,
	GetScale: (self: BetterScale) -> number?,

	Update: (self: BetterScale) -> (),
	Track: (self: BetterScale) -> (),
	UnTrack: (self: BetterScale) -> (),
	Destroy: (self: BetterScale) -> (),
}, {
	__index: BetterScale,
}>


local function getGuiContainer(uiScale: UIScale): GuiContainer?
	for _, GUI_CONTAINER in GUI_CONTAINERS  do
		local guiContainer = uiScale:FindFirstAncestorOfClass(GUI_CONTAINER) :: any

		if guiContainer then
			return guiContainer
		end
	end

	return nil
end

local function updateDisplayRatios(self: BetterScale): ()
	local displayRatios = self._uiScale:GetAttribute("DisplayRatios")
	if type(displayRatios) ~= "string" then
		self._displayRatios = nil
		return
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, displayRatios)
	if not success or type(result) ~= "table" then
		self._displayRatios = nil
		return
	end

	self._displayRatios = result
end

local function updateContainer(self: BetterScale): ()
	self._guiContainer = getGuiContainer(self._uiScale)
	if self._scaleConnection then
		self._scaleConnection:Disconnect()
		self._scaleConnection = nil
	end

	if self._guiContainer and self._isTracking then
		self._scaleConnection = self._guiContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:Update()
		end)
	end
end


local BetterScale = {}
BetterScale.__index = BetterScale

function BetterScale.new(uiScale: UIScale): BetterScale
	local self = setmetatable({}, BetterScale) :: any

	self._connections = {}
	self._isTracking = false

	self._uiScale = uiScale
	self._guiContainer = getGuiContainer(uiScale)

	self._ancestryChangedConnection = uiScale.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy()
		end
	end)

	return self
end

function BetterScale.build(uiScale: UIScale): () -> ()
	local self = BetterScale.new(uiScale)
	self:Track()

	return function()
		self:Destroy()
	end
end

function BetterScale.is(value: any): boolean
	return type(value) == "table" and getmetatable(value) == BetterScale
end

function BetterScale.GetAttributes(self: BetterScale, displaySize: Enum.DisplaySize?): ()
	local attributes = self._uiScale:GetAttributes() :: Attributes & {DisplayRatio: string?}

	attributes.Range = attributes.Range or DEFAULT_RANGE
	attributes.Ratio = attributes.Ratio or DEFAULT_RATIO
	attributes.Resolution = attributes.Resolution or DEFAULT_RESOLUTION
	attributes.Axis = attributes.Axis or DEFAULT_AXIS

	if not displaySize then
		return attributes
	end

	local displayRatios = self._displayRatios
	if not displayRatios then
		return attributes
	end

	local displayRatio = displayRatios[displaySize.Name]
	if displayRatio then
		attributes.Ratio *= displayRatio
	end

	return attributes
end

function BetterScale.GetAbsoluteSize(self: BetterScale): Vector2?
	if self._guiContainer then
		return self._guiContainer.AbsoluteSize
	end

	return nil
end

@native
function BetterScale.GetScale(self: BetterScale): number?
	if not self._guiContainer then
		return nil
	end

	local attributes = self:GetAttributes(GuiService.ViewportDisplaySize)
	local size = self:GetAbsoluteSize() :: Vector2

	local ratio = attributes.Ratio
	local range = attributes.Range
	local resolution = attributes.Resolution
	local axis = attributes.Axis

	local axisValue: number

	if axis == Enum.ScrollingDirection.X then
		axisValue = size.X

		local reference = 1 / resolution.X * axisValue
		return math.clamp(reference, range.Min, range.Max) * ratio

	elseif axis == Enum.ScrollingDirection.Y then
		axisValue = size.Y

		local reference = 1 / resolution.Y * axisValue
		return math.clamp(reference, range.Min, range.Max) * ratio

	else
		axisValue = math.min(size.X, size.Y)

		local compute = 1 / resolution.X * size.X / (1 / resolution.Y * axisValue)
		local reference = 1 / resolution.Y * math.clamp(compute, 0, 1)

		return math.clamp(reference * axisValue, range.Min, range.Max) * ratio
	end
end

function BetterScale.Update(self: BetterScale): ()
	local scale = self:GetScale()

	if scale then
		self._uiScale.Scale = scale
	end
end

function BetterScale.Track(self: BetterScale): ()
	if self._isTracking then
		return
	end

	self._isTracking = true

	updateContainer(self)
	updateDisplayRatios(self)

	table.insert(self._connections, RunService.RenderStepped:Once(function()
		self:Update()
	end))

	table.insert(self._connections, self._uiScale.AncestryChanged:Connect(function()
		updateContainer(self)
	end))

	table.insert(self._connections, self._uiScale.AttributeChanged:Connect(function(attribute)
		if attribute == "DisplayRatios" then
			updateDisplayRatios(self)
		end

		self:Update()
	end))

	table.insert(self._connections, GuiService:GetPropertyChangedSignal("ViewportDisplaySize"):Connect(function()
		self:Update()
	end))
end

function BetterScale.UnTrack(self: BetterScale): ()
	if not self._isTracking then
		return
	end

	self._isTracking = false

	if self._scaleConnection then
		self._scaleConnection:Disconnect()
	end

	for _, connection in self._connections do
		connection:Disconnect()
	end

	table.clear(self._connections)
end

function BetterScale.Destroy(self: BetterScale): ()
	self:UnTrack()

	if self._ancestryChangedConnection then
		self._ancestryChangedConnection:Disconnect()
		self._ancestryChangedConnection = nil
	end
end


return table.freeze({
	new = BetterScale.new,
	build = BetterScale.build,

	is = BetterScale.is
})