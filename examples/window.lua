local function init()
	--Test window
	local window = DxWindow:new(300, 300, 300, 300, "Color Picker")
	
	local input = DxInput:new(0, 50, 200, 35, "Lorem Ipsum is simply dummy text of the printing and typesetting industry.")
	input:setParent(window)
	input:setCentered(true)
	
	local button = DxButton:new(75, 100, 150, 35, "Button")
	button:setParent(window)
	
	local radiobutton = DxRadioButton:new(75, 150, 100, 35, "Option 1")
	radiobutton:setParent(window)
	radiobutton:setCentered(true)

	local colorpicker = DxColorPicker:new(400, 190, 100, 100)
	colorpicker:setParent(window)
	colorpicker:setCentered(true)
end
addEventHandler("onClientResourceStart", resourceRoot, init)