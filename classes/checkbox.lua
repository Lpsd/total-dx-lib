DxCheckbox = inherit(DxElement)

function DxCheckbox:constructor(x, y, width, height, text, selected)	
	self.type = "dx-checkbox"
	
	self.text = text
	
	self.textColor = getStyleSetting("checkbox", "text_color")
	
	self.checkbox = {
		width = math.min(height, 20),
		height = math.min(height, 20),
		selected = selected and true or false
	}
	
	local checkX, checkY = self:getCheckboxBounds()
	
	self.checkbox.element = DxText:new(checkX-self.x, checkY-self.y, self.checkbox.height, self.checkbox.height, "", "center", "center")
	
	local checkboxColor = getStyleSetting("checkbox", "checkbox_color")
	local checkboxTextColor = getStyleSetting("checkbox", "checkbox_text_color")
	
	self.checkbox.element:setColor(checkboxColor.r, checkboxColor.g, checkboxColor.b, checkboxColor.a)
	self.checkbox.element:setTextColor(checkboxTextColor.r, checkboxTextColor.g, checkboxTextColor.b, checkboxTextColor.a)
	self.checkbox.element:setParent(self)
	
	self.checkbox.fToggleSelectedState = function(button, state, x, y)
		if(button == "left") and (state == "down") then
			self:toggleSelectedState()
		end
	end
	
	self.checkbox.element:addClickFunction(self.checkbox.fToggleSelectedState)

	self:setSelected(selected)
end

function DxCheckbox:dx(x, y)
	x, y = x or self.x, y or self.y
	
	local padding = (self.height - self.checkbox.height) / 2
	
	dxDrawText(self.text, x + padding + self.checkbox.width + (padding*2), y, x + self.width, y + self.height, tocolor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a), 1, "default", "left", "center")
end

function DxCheckbox:setSelected(state)
	state = state and true or false
	
	self.checkbox.selected = state
	
	if(state) then
		self.checkbox.element:setText("✓")
	else
		self.checkbox.element:setText("")
	end
	
	return true
end

function DxCheckbox:getSelected()
	return self.checkbox.selected
end

function DxCheckbox:toggleSelectedState()
	self:setSelected(not self:getSelected())
end

function DxCheckbox:getCheckboxBounds()
	local padding = (self.height - self.checkbox.height) / 2
	return (self.x + padding), (self.y + padding), self.checkbox.width, self.checkbox.height
end

function DxCheckbox:setCheckboxMaxSize(size)
	if(not tonumber(size)) then
		return false
	end
	
	size = math.min(size, self.height)
	
	self.checkbox.width = size
	self.checkbox.height = size
	
	self.checkbox.element:setSize(size, size)
	
	return true
end

