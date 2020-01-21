math.randomseed(getTickCount())

function isMouseInPosition ( x, y, width, height )
	if ( not isCursorShowing( ) ) then
		return false
	end
	
	local sx, sy = guiGetScreenSize ( )
	local cx, cy = getCursorPosition ( )
	local cx, cy = ( cx * sx ), ( cy * sy )
	
	return ( ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) )
end

-- tocolor to RGBA
function decimalToRGBA(d)
	return bitExtract(d, 0, 8), bitExtract(d, 8, 8), bitExtract(d, 16, 8), bitExtract(d, 24, 8)
end

function remap(num, oldMin, oldMax, newMin, newMax)
	return (((num - oldMin) * (newMax - newMin)) / (oldMax - oldMin)) + newMin
end

function createCircleTexture(width, height, color, padding)
	if(not tonumber(width)) or (not tonumber(height)) then
		return false
	end
	
	color = color or tocolor(255, 255, 255, 255)
	
	padding = padding and math.max(padding, 2) or 2
	
	local r, g, b, a = decimalToRGBA(color)
	
	local color = {
		r = r,
		g = g,
		b = b,
		a = a
	}
	
	local texture = dxCreateTexture(width, height, "argb", "clamp")
	
	local pixels = dxGetTexturePixels(texture)
	
	local radius = (width / 2)
	
	if(height < width) then
		radius = (height / 2)
	end
	
	radius = radius - padding
	
	for r=radius, 0, -1 do
		local alpha = 255
		
		for i=0, 360, 0.1 do
			local angle = i

			local x = (r * math.cos(angle * math.pi / 180)) + radius + padding
			local y = (r * math.sin(angle * math.pi / 180)) + radius + padding
			
			if(r > radius-2) then
				alpha = 125
				
				if(angle < 90) or (angle > 270) then
					x = x - 0.5
				else
					x = x + 0.5
				end
				
				if(angle < 180) then
					y = y - 0.5
				else
					y = y + 0.5
				end						
			end	

			
			if(r == radius) then
				alpha = 50
				
				if(angle < 90) or (angle > 270) then
					x = x - 0.75
				else
					x = x + 0.75
				end
				
				if(angle < 180) then
					y = y - 0.75
				else
					y = y + 0.75
				end
			end			
			

			dxSetPixelColor(pixels, x, y, color.r, color.g, color.b, alpha)
		end
	end	
	
	dxSetTexturePixels(texture, pixels)	
		
	return texture		
end

function createCircleMask(width, height, padding)
	padding = padding and math.max(padding, 2) or 2
	
	local texture = dxCreateTexture(width, height, "argb", "clamp")
	
	local pixels = dxGetTexturePixels(texture)
	
	for i=0, (width-1) do
		for j=0, (height-1) do
			dxSetPixelColor(pixels, j, i, 0, 0, 0, 255)
		end
	end
	
	local radius = (width / 2)
	
	if(height < width) then
		radius = (height / 2)
	end
	
	radius = radius - padding
	
	for r=radius, 1, -1 do
		local color = {255, 255, 255, 255}
		
		for i=0, 360, 0.1 do
			local angle = i

			local x = (r * math.cos(angle * math.pi / 180)) + radius + padding
			local y = (r * math.sin(angle * math.pi / 180)) + radius + padding
			
			if(r > radius-2) then
				color = {125, 125, 125, 125}
				
				if(angle < 90) or (angle > 270) then
					x = x - 0.5
				else
					x = x + 0.5
				end
				
				if(angle < 180) then
					y = y - 0.5
				else
					y = y + 0.5
				end						
			end	

			
			if(r == radius) then
				color = {50, 50, 50, 50}
				
				if(angle < 90) or (angle > 270) then
					x = x - 0.75
				else
					x = x + 0.75
				end
				
				if(angle < 180) then
					y = y - 0.75
				else
					y = y + 0.75
				end				
			end			

			dxSetPixelColor(pixels, x, y, unpack(color))
		end
	end	
	
	dxSetTexturePixels(texture, pixels)	
		
	return texture	
end

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string.random(length)
	if length > 0 then
		return string.random(length - 1) .. charset[math.random(1, #charset)]
	end
	
	return ""
end
