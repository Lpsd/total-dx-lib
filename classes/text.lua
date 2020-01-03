DxText = inherit(DxElement)

function DxText:constructor(x, y, width, height, text, alignX, alignY)	
	self.type = "dx-text"
	self.text = text
	
	local defaultPrimaryColor = getStyleSetting("text", "primary_color")
	self:setColor(defaultPrimaryColor.r, defaultPrimaryColor.g, defaultPrimaryColor.b, 0)
	
	self.hoverColor.a = 255
	
	local defaultTextColor = getStyleSetting("text", "text_color")
	self:setTextColor(defaultTextColor.r, defaultTextColor.g, defaultTextColor.b, defaultTextColor.a)
	
	self.align = {
		x = alignX or "left",
		y = alignY or "top"
	}
	
	self:setProperty("hover_enabled", false)
end

function DxText:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	dxDrawText(self.text, x, y, x+self.width, y+self.height, tocolor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a), 1, "default", self.align.x, self.align.y)
end
