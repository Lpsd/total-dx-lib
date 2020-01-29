-- **************************************************************************
-- Function call processing
-- **************************************************************************
function dx_iselement(element)
	if(not element) then
		return false
	end

	if(type(element) ~= "table") then
		return false
	end
	
	if(not element.uid) then
		return false
	end
	
	if(not string.match(element.type, "dx")) then
		return false
	end
	
	return true
end

function dx_callmethod(element, methodName, ...) -- dx-element, method name, args
	local uid = (type(element) == "table") and element.uid or element
	
	element = DxHostedElements[uid]
	
	if(not dx_iselement(element)) then
		return false
	end
	
	if(not element[methodName]) then
		return false
	end	
	
	return element[methodName](element, ...)
end

function dx_createmethod(classType, ...)
	if(not _G[classType]) then
		return false
	end
	
	local element = _G[classType]:new(...)
	
	if(not element) then
		return false
	end
	
	DxHostedElements[element.uid] = element
	
	return element
end

-- **************************************************************************
-- Initialization
-- **************************************************************************

function dxCreateWindow(...)
	return dx_createmethod("DxWindow", ...)
end

function dxCreateButton(...)
	return dx_createmethod("DxButton", ...)
end

function dxCreateInput(...)
	return dx_createmethod("DxInput", ...)
end

function dxCreateText(...)
	return dx_createmethod("DxText", ...)
end

function dxCreateSlider(...)
	return dx_createmethod("DxSlider", ...)
end

function dxCreateImage(...)
	return dx_createmethod("DxImage", ...)
end

function dxCreateColor(...)
	return dx_createmethod("DxBlank", ...)
end

function dxCreateCheckbox(...)
	return dx_createmethod("DxCheckbox", ...)
end

function dxCreateRadioButton(...)
	return dx_createmethod("DxRadioButton", ...)
end

function dxCreateCircle(...)
	return dx_createmethod("DxCircle", ...)
end

-- **************************************************************************
-- Destruction override
-- **************************************************************************

_destroyElement = destroyElement

function destroyElement(element, ...)
	if(dx_iselement(element)) then
		return element:delete()
	end
	
	return _destroyElement(element, ...)
end

-- **************************************************************************
-- Global properties
-- **************************************************************************

function dxSetGlobalProperty(propertyName, value)
	if(DxProperties[property] == nil) then
		return false
	end
	
	if(type(value) ~= type(DxProperties[property])) then
		return false
	end
	
	DxProperties[property] = value
	
	return true	
end

function dxGetGlobalProperty(propertyName)
	return DxProperties[propertyName]
end


-- **************************************************************************
-- Per-instance properties
-- **************************************************************************

function dxSetProperty(element, ...)
	return dx_callmethod(element, "setProperty", ...)
end

function dxGetProperty(element, ...)
	return dx_callmethod(element, "getProperty", ...)
end

-- **************************************************************************
-- Textures
-- **************************************************************************

function dxGetTexture(element, ...)
	return dx_callmethod(element, "getTexture", ...)
end

function dxGetMaskTexture(element, ...)
	return dx_callmethod(element, "getMaskTexture", ...)
end

-- **************************************************************************
-- Masks
-- **************************************************************************

function dxApplyMask(element, ...)
	return dx_callmethod(element, "applyMask", ...)
end

function dxSetMaskEnabled(element, ...)
	return dx_callmethod(element, "setMaskEnabled", ...)
end

-- **************************************************************************
-- Render function attaching
-- **************************************************************************

function dxAddRenderFunction(element, ...)
	return dx_callmethod(element, "addRenderFunction", ...)
end

function dxRemoveRenderFunction(element, ...)
	return dx_callmethod(element, "removeRenderFunction", ...)
end

-- **************************************************************************
-- Click function attaching
-- **************************************************************************

function dxAddClickFunction(element, ...)
	return dx_callmethod(element, "addClickFunction", ...)
end

function dxRemoveClickFunction(element, ...)
	return dx_callmethod(element, "removeClickFunction", ...)
end

-- **************************************************************************
-- Drag areas
-- **************************************************************************

function dxSetDragArea(element, ...)
	return dx_callmethod(element, "setDragArea", ...)
end

-- **************************************************************************
-- Mouse
-- **************************************************************************

function isMouseOverDxElement(element)
	return dx_callmethod(element, "isMouseOverElement")
end

-- **************************************************************************
-- Obstructions
-- **************************************************************************

function dxIsObstructed(element)
	local sx, sy = guiGetScreenSize()
	local cx, cy = getCursorPosition()
	
	local cursorX, cursorY = (cx * sx), (cy * sy)
	
	return dx_callmethod(element, "isObstructed", cursorX, cursorY)
end

function dxIsObstructedByElement(element, obstructingElement)
	local sx, sy = guiGetScreenSize()
	local cx, cy = getCursorPosition()
	
	local cursorX, cursorY = (cx * sx), (cy * sy)
	
	return dx_callmethod(element, "isObstructed", cursorX, cursorY, obstructingElement)
end

function dxGetObstructingElement(element)
	local sx, sy = guiGetScreenSize()
	local cx, cy = getCursorPosition()
	
	local cursorX, cursorY = (cx * sx), (cy * sy)	
	
	return dx_callmethod(element, "getObustructingElement", cursorX, cursorY)
end


-- **************************************************************************
-- Element bounds
-- **************************************************************************

function dxGetBounds(element, relative)
	return dx_callmethod(element, "getBounds", relative)
end

function dxGetInheritedBounds(element)
	return dx_callmethod(element, "getInheritedBounds")
end

-- **************************************************************************
-- Parents
-- **************************************************************************

function dxIsParent(element, parentElement)
	return dx_callmethod(element, "isParent", parentElement)
end

function dxSetParent(element, parentElement)
	return dx_callmethod(element, "setParent", parentElement)
end

function dxGetParent(element)
	return dx_callmethod(element, "getParent")
end

function dxGetInheritedParents(element)
	return dx_callmethod(element, "getInheritedParents")
end

-- **************************************************************************
-- Children
-- **************************************************************************

function dxIsChild(element, childElement)
	return dx_callmethod(element, "isChild", childElement)
end

function dxIsInheritedChild(element, childElement)
	return dx_callmethod(element, "isInheritedChild", childElement)
end

function dxGetChildren(element)
	return dx_callmethod(element, "getChildren")
end

function dxGetInheritedChildren(element)
	return dx_callmethod(element, "getInheritedChildren")
end

function dxGetChildrenByType(element, elementType)
	return dx_callmethod(element, "getChildrenByType", elementType)
end

function dxGetInheritedChildrenByType(element, elementType)
	return dx_callmethod(element, "getInheritedChildrenByType", elementType)
end

-- **************************************************************************
-- Alpha
-- **************************************************************************

function dxSetAlpha(element, ...)
	return dx_callmethod(element, "setAlpha", ...)
end

function dxGetAlpha(element)
	return dx_callmethod(element, "getAlpha")
end

-- **************************************************************************
-- Visibility
-- **************************************************************************

function dxSetVisible(element, ...)
	return dx_callmethod(element, "setVisible", ...)
end

function dxGetVisible(element)
	return dx_callmethod(element, "getVisible")
end

-- **************************************************************************
-- Color
-- **************************************************************************

function dxSetColor(element, ...)
	return dx_callmethod(element, "setColor", ...)
end

function dxGetColor(element)
	return dx_callmethod(element, "getColor")

end

function dxSetHoverColor(element, ...)
	return dx_callmethod(element, "setHoverColor", ...)
end

function dxGetHoverColor(element)
	return dx_callmethod(element, "getHoverColor")

end

function dxSetTextColor(element, ...)
	return dx_callmethod(element, "setTextColor", ...)
end

function dxGetTextColor(element)
	return dx_callmethod(element, "getTextColor")

end

-- **************************************************************************
-- Position
-- **************************************************************************

function dxSetPosition(element, ...)
	return dx_callmethod(element, "setPosition", ...)
end

function dxGetPosition(element)
	return dx_callmethod(element, "getPosition")
end

function dxSetCentered(element, ...)
	return dx_callmethod(element, "setCentered")
end

-- **************************************************************************
-- Size
-- **************************************************************************

function dxSetSize(element, ...)
	return dx_callmethod(element, "setSize", ...)
end

function dxGetSize(element)
	return dx_callmethod(element, "getSize")
end

-- **************************************************************************
-- Text
-- **************************************************************************

function dxSetText(element, ...)
	return dx_callmethod(element, "setText", ...)
end

function dxGetText(element)
	return dx_callmethod(element, "getText")
end

-- **************************************************************************
-- Index / Ordering
-- **************************************************************************

function dxBringToFront(element)
	return dx_callmethod(element, "bringToFront")
end

function dxSendToBack(element)
	return dx_callmethod(element, "sendToBack")
end

function dxSetIndex(element, ...)
	return dx_callmethod(element, "setIndex", ...)
end

function dxGetIndex(element)
	return dx_callmethod(element, "getIndex")
end

function dxIsFront(element)
	return dx_callmethod(element, "isFront")
end

-- **************************************************************************
-- Element tree stuff
-- **************************************************************************

function dxGetRootElements()
	local elements = {}
	for i, element in ipairs(DxElements) do
		if(element:isRootElement()) then
			table.insert(elements, element)
		end
	end
	return elements
end

function dxGetNonRootElements()
	local elements = {}
	for i, element in ipairs(DxElements) do
		if(not element:isRootElement()) then
			table.insert(elements, element)
		end
	end
	return elements
end

function dxIsRootElement(element)
	return dx_callmethod(element, "isRootElement")
end

function dxGetRootElement(element)
	return dx_callmethod(element, "getRootElement")
end

function dxGetTopLevelChildren(element)
	return dx_callmethod(element, "getTopLevelChildren")
end

-- **************************************************************************
-- Destruction
-- **************************************************************************
function dxDestroy(element)
	return dx_callmethod(element, "delete")
end