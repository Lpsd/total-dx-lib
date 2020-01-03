DxButton = inherit(DxElement)

function DxButton:constructor(x, y, width, height, text)	
	self.type = "dx-button"
	
	self.text = text
	
	local primaryColor = getStyleSetting("button", "primary_color")
	self:setColor(primaryColor.r, primaryColor.g, primaryColor.b, primaryColor.a)
	
	local hoverColor = getStyleSetting("button", "hover_color")
	self:setHoverColor(nil, nil, nil, hoverColor.a)
	
	local defaultTextColor = getStyleSetting("button", "text_color")
	self:setTextColor(defaultTextColor.r, defaultTextColor.g, defaultTextColor.b, defaultTextColor.a)
end

function DxButton:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	dxDrawText(self.text, x, y, x+self.width, y+self.height, tocolor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a), 1, "default", "center", "center")
end
