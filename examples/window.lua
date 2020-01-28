local function init()	
	--Load all styles
	getAllStyles()
	
	--Debug testing
	if(DEBUG) then
		local window = DxWindow:new(300, 300, 300, 300, "Primary Window")
		
		local input = DxInput:new(0, 50, 200, 35, "Lorem Ipsum is simply dummy text of the printing and typesetting industry.")
		input:setParent(window)
		input:setCentered(true)
		
		local button = DxButton:new(75, 100, 150, 35, "Button")
		button:setParent(window)
		
		local radiobutton = DxRadioButton:new(75, 150, 100, 35, "Option 1")
		radiobutton:setParent(window)
		radiobutton:setCentered(true)
		
		local radiobutton2 = DxRadioButton:new(75, 180, 100, 35, "Option 2")
		radiobutton2:setParent(window)	
		radiobutton2:setCentered(true)
		
		local slider = DxSlider:new(75, 240, 100, 35,98)
		slider:setParent(window)
		slider:setCentered(true)

		local circle = DxCircle:new(100, 100, 250, 250)
		circle:setColor(15, 190, 250)	
	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)