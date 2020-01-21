DxRadioButton = inherit(DxElement)

function DxRadioButton:constructor(x, y, width, height, text, selected)	
	self.type = "dx-radiobutton"
	
	self.text = text
	
	self.textColor = getStyleSetting("radiobutton", "text_color")
	
	self.radiobutton = {
		width = math.min(height, 26),
		height = math.min(height, 26),
		selected = selected and true or false,
		background_color = getStyleSetting("radiobutton", "button_background_color"),
		selected_color = getStyleSetting("radiobutton", "button_selected_color")
	}
	
	local checkX, checkY = self:getRadioButtonBounds()
	
	self.radiobutton.backgroundElement = DxCircle:new(checkX-self.x, checkY-self.y, self.radiobutton.height, self.radiobutton.height)
	self.radiobutton.backgroundElement:setParent(self)
	self.radiobutton.backgroundElement:setColor(self.radiobutton.background_color.r, self.radiobutton.background_color.g, self.radiobutton.background_color.b, self.radiobutton.background_color.a)
	
	self.radiobutton.selected_padding = self.radiobutton.width / 3
	
	self.radiobutton.selectedElement = DxCircle:new((self.radiobutton.selected_padding/2), (self.radiobutton.selected_padding/2), self.radiobutton.height - self.radiobutton.selected_padding, self.radiobutton.height - self.radiobutton.selected_padding)
	self.radiobutton.selectedElement:setParent(self.radiobutton.backgroundElement)
	self.radiobutton.selectedElement:setColor(self.radiobutton.selected_color.r, self.radiobutton.selected_color.g, self.radiobutton.selected_color.b, self.radiobutton.selected_color.a)
	
	self.radiobutton.fToggleSelectedState = function(button, state, x, y)
		if(button == "left") and (state == "down") then
			self:setSelected(true)
		end
	end
	
	self.radiobutton.selectedElement:addClickFunction(self.radiobutton.fToggleSelectedState)
	self:addClickFunction(self.radiobutton.fToggleSelectedState)

	self:setSelected(false)
end

function DxRadioButton:dx(x, y)
	x, y = x or self.x, y or self.y
	
	local padding = (self.height - self.radiobutton.height) / 2
	
	dxDrawText(self.text, x + padding + self.radiobutton.width + (padding*2), y, x + self.width, y + self.height, tocolor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a), 1, "default", "left", "center")
end

function DxRadioButton:setSelected(state)
	state = state and true or false
	
	self.radiobutton.selected = state

	self.radiobutton.selectedElement:setVisible(state)
	
	if(state) then
		if(self:hasParent()) then
			for i, child in ipairs(self:getParent():getChildren()) do
				if(child:getType() == "dx-radiobutton") and (child ~= self) then
					child:setSelected(false)
				end
			end
		else
			for i, element in ipairs(DxElements) do
				if(element:getType() == "dx-radiobutton") and (element:isRootElement()) and (element ~= self) then
					element:setSelected(false)
				end
			end
		end
	end
	
	return true
end

function DxRadioButton:getSelected()
	return self.radiobutton.selected
end

function DxRadioButton:toggleSelectedState()
	self:setSelected(not self:getSelected())
end

function DxRadioButton:getRadioButtonBounds()
	local padding = (self.height - self.radiobutton.height) / 2
	return (self.x + padding), (self.y + padding), self.radiobutton.width, self.radiobutton.height
end

