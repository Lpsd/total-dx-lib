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
		window = DxWindow:new(300, 300, 300, 300, "Primary")
		
		input = DxInput:new(50, 50, 200, 35, "hello i wonder what happens when i put a big text in here")
		
		input:setParent(window)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)

if(DEBUG) then
	bindKey("F2", "down", function()
		showCursor(not isCursorShowing())
	end)
end