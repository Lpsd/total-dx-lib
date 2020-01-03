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
		local text1 = DxText:new(75, 200, 150, 35, "testing text")
		
		local text2 = DxText:new(75, 225, 150, 35, "testing text")
		text2:setTextColor(255, 255, 0)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)

if(DEBUG) then
	bindKey("F2", "down", function()
		showCursor(not isCursorShowing())
	end)
end
