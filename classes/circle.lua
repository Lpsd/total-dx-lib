DxCircle = inherit(DxElement)

function DxCircle:constructor(x, y, width, height)	
	self.type = "dx-circle"
	
	self.circleTexture = createCircleTexture(self.width, self.height, tocolor(255,255,255), 0)
end

function DxCircle:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawImage(x, y, self.width, self.height, self.circleTexture)
end

-- **************************************************************************

function DxCircle:setColor(r, g, b, a)
	r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
	
	if(r) then
		self.primaryColor.r = (r >= 0 and r <= 255) and r or self.primaryColor.r
		self.hoverColor.r = self.primaryColor.r
	end
	
	if(g) then
		self.primaryColor.g = (g >= 0 and g <= 255) and g or self.primaryColor.g
		self.hoverColor.g = self.primaryColor.g
	end
	
	if(b) then
		self.primaryColor.b = (b >= 0 and b <= 255) and b or self.primaryColor.b
		self.hoverColor.b = self.primaryColor.b
	end
	
	if(a) then
		self.primaryColor.a = (a >= 0 and a <= 255) and a or self.primaryColor.a
	end
	
	if(not self.hovering) then
		self.color = self.primaryColor
	end
	
	if(self.circleTexture and isElement(self.circleTexture)) then
		destroyElement(self.circleTexture)
	end
	
	self.circleTexture = createCircleTexture(self.width, self.height, tocolor(self.primaryColor.r, self.primaryColor.g, self.primaryColor.b, self.primaryColor.a), 0)
	
	return true
end
