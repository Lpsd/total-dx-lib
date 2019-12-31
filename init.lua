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
		local window = DxWindow:new(300, 300, 300, 300, "Primary Window")
		
		local input = DxInput:new(50, 50, 200, 35, "Lorem Ipsum is simply dummy text of the printing and typesetting industry.")
		input:setParent(window)
		
		local button = DxButton:new(75, 100, 150, 35, "Button")
		button:setParent(window)
		
		local checkbox = DxCheckbox:new(75, 150, 150, 35, "I am a checkbox")
		checkbox:setParent(window)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)

if(DEBUG) then
	bindKey("F2", "down", function()
		showCursor(not isCursorShowing())
	end)
end
