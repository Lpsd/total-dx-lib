DxText = inherit(DxElement)

function DxText:constructor(x, y, width, height, text, textColor, alignX, alignY)	
	self.type = "dx-text"
	self.text = text
	
	local defaultPrimaryColor = getStyleSetting("text", "primary_color")
	
	self:setColor(defaultPrimaryColor.r, defaultPrimaryColor.g, defaultPrimaryColor.b, defaultPrimaryColor.a)
	
	local defaultTextColor = getStyleSetting("general", "text_color")
	
	textColor = textColor or tocolor(defaultTextColor.r, defaultTextColor.g, defaultTextColor.b, defaultTextColor.a)
	
	local textR, textG, textB, textA = decimalToRGBA(textColor)
	
	self.textColor = {
		r = textR,
		g = textG,
		b = textB,
		a = textA
	}
	
	self.align = {
		x = alignX or "left",
		y = alignY or "top"
	}
end

function DxText:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	dxDrawText(self.text, x, y, x+self.width, y+self.height, tocolor(self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a), 1, "default", self.align.x, self.align.y)
end
