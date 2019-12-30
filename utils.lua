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

function createCircleMask(width, height, padding)
	padding = padding or 5
	
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
	
	local renderTarget = dxCreateRenderTarget(width, height)
	
	dxSetRenderTarget(renderTarget)
	dxSetBlendMode("modulate_add")
	
	dxDrawImage(0, 0, width, height, texture)
	
	dxDrawCircle(radius+padding, radius+padding, radius)
	
	dxSetBlendMode("blend") 
	dxSetRenderTarget()
		
	return renderTarget	
end
