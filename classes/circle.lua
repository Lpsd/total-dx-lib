DxCircle = inherit(DxElement)

function DxCircle:constructor(x, y, width, height)	
	self.type = "dx-circle"
	
	self.shaderText = [[
		float antiAliased = 0.005;
		float primaryColor = float4(255, 255, 255, 255);

		float4 AntiAliasedCircle(float2 tex:TEXCOORD0):COLOR0
		{
			float radius = distance(tex,0.5);
			
			float4 color = primaryColor;
			color.a = 1-(radius-0.5+antiAliased/2)/antiAliased;
			
			return color;
		}

		technique DrawCircle
		{
			pass P0
			{
				PixelShader = compile ps_2_0 AntiAliasedCircle();
			}
		}
	]]
	
	self.shader = dxCreateShader(self.shaderText)
	
	self:updateValues()	
end

-- **************************************************************************

function DxCircle:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawImage(x, y, self.width, self.height, self.shader, 0, 0, 0, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
end

-- **************************************************************************

function DxCircle:updateValues()
	self.radius = 0.49
	
	dxSetShaderValue(self.shader, "primaryColor", {remap(self.color.r, 0, 255, 0, 1), remap(self.color.g, 0, 255, 0, 1), remap(self.color.b, 0, 255, 0, 1), remap(self.color.a, 0, 255, 0, 1)})
end

-- **************************************************************************

function DxCircle:setSize(width, height)
	width, height = tonumber(width), tonumber(height)
	
	self.width, self.height = width and width or self.width, height and height or self.height
	
	self:updateValues()

	return true
end

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
	
	self:updateValues()
	
	return true
end

-- **************************************************************************