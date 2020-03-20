DxColorPicker = inherit(DxElement)

function DxColorPicker:constructor(x, y, width, height)	
	self.type = "dx-colorpicker"
	
	self.shaderText = [[
		float globalAntiAlias = 0.0075;
		float globalRadius = 0;
		
		float HUEtoRGB(float x, float y, float z)
		{
			if (z < 0)
				z = z+1;
			if (z > 1)
				z = z-1;
			if (z * 6 < 1)
				return x + (y - x) * 6 * z;
			if (z * 2 < 1)
				return y;
			if (z * 3 < 2)
				return x + (y - x) * (float(2) / float(3) - z) * 6;
				
			return x;
		}

		float4 HSLtoRGB(float4 hsl)
		{
			float4 RGBA = float4(hsl.b, hsl.b, hsl.b, hsl.a);
			
			if (hsl.g != 0)
			{
				float y = 0;
				if (hsl.b < 0.5)
					y = hsl.b + hsl.g * hsl.b;
				else
					y = hsl.b + hsl.g - hsl.g * hsl.b;
				float x = 2 * hsl.b - y;
				float z = float(1) / float(3);
				RGBA.r = HUEtoRGB(x, y, hsl.r + z);
				RGBA.g = HUEtoRGB(x, y, hsl.r);
				RGBA.b = HUEtoRGB(x, y, hsl.r - z);
			}
			return RGBA;
		}

		float4 ColorPicker(float2 picker:TEXCOORD0):COLOR0
		{
			float radius = distance(picker,0.5);
			float div = globalRadius / 200;
			
			float antiAlias = globalAntiAlias / div;
			
			float4 color = HSLtoRGB(float4(atan2(picker.x - 0.5, picker.y - 0.5) / 6.28, 1, 1 - radius, 1));
			
			color.a = (0.5 - abs(radius) - antiAlias) / antiAlias;
			
			return color;
		}

		technique DrawCircle
		{
			pass P0
			{
				PixelShader = compile ps_2_a ColorPicker();
			}
		}
	]]
	
	self.shader = dxCreateShader(self.shaderText)
	self.shaderTexture = dxCreateRenderTarget(self.width, self.height, true)
	
	self.radius = (self.width >= self.height and self.width or self.height)
	
	self.picker = {
		radius = math.max(self.radius / 5, 20)
	}
	
	self.picker.element = DxCircle:new(0, 0, math.max(self.radius / 5, 20), math.max(self.radius / 5, 20))
	
	self.picker.mask = DxCircle:new(0, 0, self.picker.radius - 10, self.picker.radius - 10)
	self.picker.mask:setColor(0, 0, 0)
	
	self.picker.element:applyMask(self.picker.mask:getTexture())
	
	self.picker.element:setColor(255, 255, 255)
	self.picker.element:setParent(self)
	
	self:addRenderFunction(self.updateShaderValues)
	
	self.fGetClickedColor = bind(self.getClickedColor, self)
	self:addClickFunction(self.fGetClickedColor)
	
	self.clickedColor = false
end

-- **************************************************************************

function DxColorPicker:dx(x, y)
	x, y = x or self.x, y or self.y
	
	if(self.shaderTexture) then
		dxDrawImage(x, y, self.width, self.height, self.shaderTexture, 0, 0, 0, tocolor(255, 255, 255, self.color.a))
	end
end

-- **************************************************************************

function DxColorPicker:updateShaderValues()
	dxSetShaderValue(self.shader, "globalRadius", self.radius)
end

-- **************************************************************************

function DxColorPicker:getClickedColor(button, state)
	if(button == "left" and state == "down") then
		local r, g, b, a = getColorAtCursorPosition()
		
		self.clickedColor = {
			r = r,
			g = g,
			b = b,
			a = a
		}
	end
end

-- **************************************************************************