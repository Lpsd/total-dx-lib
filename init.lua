SCREEN_WIDTH, SCREEN_HEIGHT = guiGetScreenSize()

DEBUG = true

DxElements = {}

DxInfo = {
	draggingElement = false
}

function init()	
	--Load all styles
	getAllStyles()
	
	--Debug testing
	if(DEBUG) then
		window = DxWindow:new(300, 300, 300, 300, "Primary Window")
		
		input = DxInput:new(50, 50, 200, 35, "Lorem Ipsum is simply dummy text of the printing and typesetting industry.")
		input:setParent(window)
		
		button = DxButton:new(75, 100, 150, 35, "Button")
		button:setParent(window)
		
		local texture = window:getTexture()
		local width, height = window:getSize()
		
		image = DxImage:new(SCREEN_WIDTH - width, 0, width, height, texture)
		label = DxText:new(SCREEN_WIDTH - width, 0, width, height, "(texture)")
	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)

if(DEBUG) then
	bindKey("F2", "down", function()
		showCursor(not isCursorShowing())
	end)
end
