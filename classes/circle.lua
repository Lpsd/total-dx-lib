DxCircle = inherit(DxElement)

function DxCircle:constructor(x, y, width, height)	
	self.type = "dx-circle"
	
	self.shaderText = [[
		float globalAntiAlias = 0.0075;
		float globalRadius = 0;
		
		float primaryColor = float4(255, 255, 255, 255);
		
		float r = -1;
		float g = -1;
		float b = -1;
		float a = -1;

		float4 AntiAliasedCircle(float2 picker:TEXCOORD0):COLOR0
		{
			// single pass here while waiting for MTA to provide values
			if(r == -1) {
				return float4(0, 0, 0, 0);
			}
			
			float radius = distance(picker,0.5);
			float div = globalRadius / 200;
			
			float antiAlias = globalAntiAlias / div;
			
			float4 color = float4(r, g, b, a);
			
			float alphaDiff = 1 - a;
			
			color.a = (0.5 - abs(radius) - antiAlias) / antiAlias;
			
			color.a = color.a - alphaDiff;
			
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
	self.shaderTexture = dxCreateRenderTarget(self.width, self.height, true)
	
	self:addRenderFunction(self.updateShaderValues)
end

-- **************************************************************************

function DxCircle:dx(x, y)
	x, y = x or self.x, y or self.y
	
	if(self.shaderTexture) then
		dxDrawImage(x, y, self.width, self.height, self.shaderTexture, 0, 0, 0, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	end
end

-- **************************************************************************

function DxCircle:updateShaderValues()
	dxSetShaderValue(self.shader, "r", remap(self.color.r, 0, 255, 0, 1))
	dxSetShaderValue(self.shader, "g", remap(self.color.g, 0, 255, 0, 1))
	dxSetShaderValue(self.shader, "b", remap(self.color.b, 0, 255, 0, 1))
	dxSetShaderValue(self.shader, "a", remap(self.color.a, 0, 255, 0, 1))
	dxSetShaderValue(self.shader, "globalRadius", (self.width >= self.height and self.width or self.height))
end

-- **************************************************************************