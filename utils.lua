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
