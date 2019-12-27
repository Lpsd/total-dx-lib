DxBlank = inherit(DxElement)

function DxBlank:constructor(x, y, width, height)	
	self.type = "dx-blank"
end

function DxBlank:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
end
