SCREEN_WIDTH, SCREEN_HEIGHT = guiGetScreenSize()

DEBUG = true

DxElements = {}
DxHostedElements = {}

DxInfo = {
	draggingElement = false
}

DxTypes = {
	"DxElement",
	"DxBlank",
	"DxCheckbox",
	"DxCircle",
	"DxImage",
	"DxInput",
	"DxRadioButton",
	"DxSlider",
	"DxText",
	"DxWindow",
	"DxButton"
}

DxMethods = {}

DxProperties = {
	["allow_drag_x"] = false,
	["allow_drag_y"] = false,
	["force_in_bounds"] = true,
	["drag_preview"] = false,
	["child_dragging"] = true,
	["ignore_window_bounds"] = false,
	["obstruct"] = true,
	["hover_enabled"] = true,
	["click_ordering"] = false,
	["draw_bounds"] = false
}

RESOURCE_NAME = false

local function init()
	RESOURCE_NAME = getResourceName(getThisResource())
	
	-- Load all styles
	getAllStyles()
	
	-- Initialize exporter
	dxInitializeExporter()
end
addEventHandler("onClientResourceStart", resourceRoot, init)