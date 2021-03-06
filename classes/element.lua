DxElement = {}

-- *************************************************

function DxElement:new(...)
	return new(self, ...)
end

function DxElement:delete(...)
	for i=#self.children,1,-1 do
		self.children[i]:delete()
	end		
	
	self.terminated = true		
	
	self:setParent(false)
	
	if(self.destruct) then
		self:destruct() 
	end
	
	if(DxInfo.draggingElement == self) then
		DxInfo.draggingElement = false
	end
	
	removeEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	removeEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))
	removeEventHandler("onClientClick", root, getPrivateMethod(self, "click"))
	removeEventHandler("onClientCursorMove", root, getPrivateMethod(self, "cursorMove"))
	
	for i, element in ipairs(DxElements) do
		if(element == self) then
			table.remove(DxElements, i)
		end
	end

	return delete(self, ...)
end

--Alias
function DxElement:destroy(...)
	return self:delete(...)
end

-- **************************************************************************

function DxElement:virtual_constructor(x, y, width, height)
	self.uid = string.random(6) .. getTickCount()
	
	self.baseX, self.baseY = x, y
	self.previousBaseX, self.previousBaseY = x, y
	
	self.x, self.y = x, y
	self.previousX, self.previousY = x, y
	
	self.width, self.height = width, height
	self.previousWidth, self.previousHeight = width, height
	
	self.index = #DxElements+1
	
	self.alpha = 255
	self.visible = true
	
	self.type = "dx-element"
	
	self.align = {
		x = "top",
		y = "left"
	}
	
	self.color = getPrimaryColor()
	
	self.primaryColor = getPrimaryColor()
	
	self.hoverColor = getPrimaryColor()
	self.hoverColor.a = getStyleSetting("general", "hover_color").a
	
	self.hover = true
	self.hovering = false
	
	self.parent = false
	self.children = {}
	
	self.renderFunctions = {
		normal = {},
		prerender = {}
	}
	
	self.clickFunctions = {}
	
	self.properties = deepcopy(DxProperties)
	
	self.bounds = {
		min = {
			x = 0,
			y = 0
		},
		max = {
			x = 0,
			y = 0
		}
	}
	
	self.dragging = false
	
	self.dragArea = {
		x = 0,
		y = 0,
		width = self.width,
		height = self.height
	}
	
	self.canvas = {
		state = false
	}
	
	self.mask = {
		state = false,
		shader = false,
		texture = false
	}
	
	local textColor = getStyleSetting("general", "text_color")

	self.textColor = {
	  r = textColor.r,
	  g = textColor.g,
	  b = textColor.b,
	  a = textColor.a
	}
	
	self.initTime = getTickCount()
	
	addEventHandler("onClientClick", root, getPrivateMethod(self, "click"))

	addEventHandler("onClientCursorMove", root, getPrivateMethod(self, "cursorMove"))
	
	self:addRenderFunction(getPrivateMethod(self, "drag"), true)
	
	self:addRenderFunction(getPrivateMethod(self, "updateInheritedBounds"))
	self:addRenderFunction(getPrivateMethod(self, "forceInBounds"), true)
	
	self:addRenderFunction(getPrivateMethod(self, "updateCachedTextures"))
	
	self:addRenderFunction(getPrivateMethod(self, "draw"))
	self:addRenderFunction(getPrivateMethod(self, "drawCanvas"))
	self:addRenderFunction(getPrivateMethod(self, "drawBounds"))
	
	self:addRenderFunction(getPrivateMethod(self, "updatePreviousDimensions"))
	
	self:addRenderFunction(getPrivateMethod(self, "updateShaderTexture"))
	
	addEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	addEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))		
	
	DxElements[self.index] = self

	self:bringToFront()
	
	return self
end

-- **************************************************************************

function DxElement:createCanvas()
	if(not self.canvas.texture) then
		self.canvas.state = true
		self.canvas.texture = dxCreateRenderTarget(self.width, self.height, true)
		self.canvas.width, self.canvas.height = self.width, self.height
	end
	return self.canvas.texture and true or false
end

function DxElement:setCanvasState(state)
	self.canvas.state = state and true or false
end

function DxElement:getCanvas()
	return self.canvas.texture or false
end

function DxElement:isCanvasEnabled()
	return self.canvas.state
end

function DxElement:inCanvas(parent)
	parent = parent or self:getParent()
	if(parent) then
		if(parent:isCanvasEnabled()) then
			return true
		else
			if(parent:hasParent()) then
				return self:inCanvas(parent:getParent())
			end
		end
	end
	
	return false
end

-- **************************************************************************

function DxElement:getTexture()
	if(not self.cachedTexture) then
		self.cachedTexture = dxCreateRenderTarget(self.width, self.height, true)
	end
	
	dxSetRenderTarget(self.cachedTexture, true)
	
	self:dx(0, 0)
	
	callPrivateMethod(self, "draw_internal", self:getChildren(), true)
	
	dxSetRenderTarget()
	
	return self.cachedTexture
end

--Needs to be separate for mask
function DxElement:getMaskTexture()
	if(not self.cachedMaskTexture) then
		self.cachedMaskTexture = dxCreateRenderTarget(self.width, self.height, true)
	end
	
	if(not self.mask.backgroundTexture) then
		self.mask.backgroundTexture = dxCreateTexture(self.width, self.height)
		local pixels = dxGetTexturePixels(self.mask.backgroundTexture)
		
		for y=0,self.height-1 do
			for x=0, self.width-1 do
				dxSetPixelColor(pixels, x, y, 255, 255, 255, 255)
			end
		end
		
		dxSetTexturePixels(self.mask.backgroundTexture, pixels)
	end
	
	dxSetRenderTarget(self.cachedMaskTexture, true)
	
	dxDrawImage(0, 0, self.width, self.height, self.mask.backgroundTexture)
	
	self:dx(0, 0)
	
	callPrivateMethod(self, "draw_internal", self:getChildren(), true)
	
	dxSetRenderTarget()
	
	return self.cachedMaskTexture
end

-- **************************************************************************

function DxElement:applyMask(mask)
	if(not self.mask.shader) then
		self.mask.shader = dxCreateShader("assets/shaders/mask.fx")
	end
	
	self.mask.texture = mask
	
	if(not isElement(self.mask.texture)) then
		self.mask.texture = dxCreateTexture(self.mask.texture, "argb", true, "clamp")
	end
	
	dxSetShaderValue(self.mask.shader, "ScreenTexture", self:getTexture())
	dxSetShaderValue(self.mask.shader, "MaskTexture", self.mask.texture)
	
	self.mask.state = true
	
	return true
end

function DxElement:isMaskEnabled()
	return self.mask.state
end

function DxElement:setMaskEnabled(state)
	self.mask.state = state and true or false
	
	return true
end

function DxElement:drawMask(x, y)
	x, y = x or self.x, y or self.y
	
	if(not self:isMaskEnabled()) then
		return false
	end
	
	dxDrawImage(x, y, self.width, self.height, self.mask.shader)
end

-- **************************************************************************

function DxElement:addRenderFunction(func, prerender)
	if(type(func) ~= "function") then
		return false
	end
	
	if(not isPrivateMethodFunctionBound(self, func)) then
		func = bind(func, self)
	end
	
	local tbl = self.renderFunctions.normal
	if(prerender) then
		tbl = self.renderFunctions.prerender
	end

	for i, boundFunc in ipairs(tbl) do
		if(boundFunc == func) then
			return false
		end
	end
	
	table.insert(tbl, func)
	return true
end

function DxElement:removeRenderFunction(func)
	if(type(func) ~= "function") then
		return false
	end
	local tbl = self.renderFunctions.normal
	for i=#tbl,1,-1 do
		local f = tbl[i]
		if(f == func) then
			table.remove(tbl, i)
			return true
		end
	end
	tbl = self.renderFunctions.prerender
	for i=#tbl,1,-1 do
		local f = tbl[i]
		if(f == func) then
			table.remove(tbl, i)
			return true
		end	
	end
	return false
end

-- **************************************************************************

function DxElement:addClickFunction(func)
	if(type(func) ~= "function") then
		return false
	end
	
	return table.insert(self.clickFunctions, func)
end

function DxElement:removeClickFunction(func)
	if(type(func) ~= "function") then
		return false
	end
	
	for i=#self.clickFunctions,1,-1 do
		local f = self.clickFunctions[i]
		if(f == func) then
			return table.remove(self.clickFunctions, i)
		end
	end
	
	return false
end

-- **************************************************************************

function DxElement:setDragArea(x, y, width, height)
	self.dragArea.x, self.dragArea.y = x and x or self.dragArea.x, y and y or self.dragArea.y
	self.dragArea.width, self.dragArea.height = width and width or self.dragArea.width, height and height or self.dragArea.height
end

function DxElement:setDraggingEnabled(x, y)
	if(x ~= nil) then
		self:setProperty("allow_drag_x", x and true or false)
	end
	
	if(y ~= nil) then
		self:setProperty("allow_drag_y", y and true or false)
	end
	
	return true
end

-- **************************************************************************

function DxElement:isMouseOverElement()
	if(isMouseInPosition(self.x, self.y, self.width, self.height)) then
		return true
	end
	return false
end

function DxElement:isObstructed(cursorX, cursorY)
	return self:getObstructingElement(cursorX, cursorY) and true or false
end

function DxElement:isObstructedByElement(cursorX, cursorY, element)
	if(not element:getProperty("obstruct")) then
		return false
	end
	
	if(element ~= self) then
		if(element.visible) then
			if(cursorX >= element.x and cursorX <= element.x + element.width and cursorY >= element.y and cursorY <= element.y + element.height) then
				if(self:isChild(element)) then
					return element
				elseif(element:getParent() == self:getParent()) then					
					if(element.index < self.index) then
						return element
					end
				else
					if(self:getRootElement().index > element:getRootElement().index) then
						return element
					end
				end
			end
		end
	end
	return false
end

function DxElement:getObstructingElement(cursorX, cursorY)
	for i, element in ipairs(DxElements) do
		if(self:isObstructedByElement(cursorX, cursorY, element)) then
			return element
		end
	end
	return false
end

-- **************************************************************************

function DxElement:getInheritedBounds()
	local bounds = {
		min = {
			x = 0,
			y = 0
		},
		max = {
			x = self.width,
			y = self.height
		}
	}
	
	if(not self:isCanvasEnabled()) then
		for i,element in ipairs(self:getInheritedChildren()) do
			local x, y = element.x - self.x, element.y - self.y
			
			if(x < bounds.min.x) then
				bounds.min.x = x
			end
			
			if(y < bounds.min.y) then
				bounds.min.y = y
			end
			
			if((x + element.width) > bounds.max.x) then
				bounds.max.x = (x + element.width)
			end
			
			if((y + element.height) > bounds.max.y) then
				bounds.max.y = (y + element.height)
			end
		end
	end
	
	return bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y
end

function DxElement:getBounds(relative)
	return (not relative and self.x or 0), (not relative and self.y or 0), (not relative and self.x + self.width or self.width), (not relative and self.y + self.height or self.height)
end

-- **************************************************************************

function DxElement:isParent(element)
	return self.parent == element
end

function DxElement:setParent(parent)
	if(self:isParent(parent)) then
		return false
	end
	
	if(self:hasParent()) then
		for i=#self.parent.children,1,-1 do
			if(self.parent.children[i] == self) then
				table.remove(self.parent.children, i)
			end
		end
	end
	
	if(parent) then
		table.insert(parent.children, self)
	end
	
	self.parent = parent
	self:setIndex(1)
	
	callPrivateMethod(self, "updateInheritedBounds")
	
	return true	
end

function DxElement:getInheritedParents(parents)
	if(not parents) then
		parents = {}
	end
	
	if(self:hasParent()) then
		parents[#parents+1] = self.parent
		return self.parent:getInheritedParents(parents)
	end
	
	return parents
end

function DxElement:getParent()
	return self.parent
end

function DxElement:hasParent()
	if(self.parent) then
		return true
	end
	return false
end

-- **************************************************************************

function DxElement:isChild(element)
	for i,e in ipairs(self.children) do
		if(element == e) then
			return true
		end
	end
	return false
end

function DxElement:getTopLevelChildren(parent)	
	parent = parent or self:getParent()
	
	if(not parent) then
		return self
	end
	
	local elements = {}	
	
	if(not parent:hasParent()) then
		for i, child in ipairs(parent:getChildren()) do
			table.insert(elements, element)
		end
		
		return elements
	end
	
	return self:getTopLevelChildren(parent:getParent())
end

-- **************************************************************************

function DxElement:getInheritedBasePosition(parent, baseX, baseY)
	baseX, baseY = baseX or self.baseX, baseY or self.baseY
	
	parent = parent or self:getParent()

	if(parent) and (not parent:isRootElement()) then
		baseX, baseY = baseX + parent.baseX, baseY + parent.baseY
		
		if(parent:hasParent()) then
			return self:getInheritedBasePosition(parent:getParent(), baseX, baseY)
		end
	end
	
	return baseX, baseY
end

-- **************************************************************************

function DxElement:getRootElement(hasCanvas)
	if(self:hasParent()) then
		if(hasCanvas) then
			if(self.parent:hasCanvas()) then
				return self.parent:getRootElement(hasCanvas)
			else
				return self
			end
		else
			return self.parent:getRootElement()
		end
	end
	return self
end

function DxElement:isRootElement()
	if(self == self:getRootElement()) then
		return true
	end
	
	return false
end

function DxElement:getRootWithCanvas()
	if(self:hasParent()) then
		return self.parent:getRootElement()
	end
	return self
end

-- **************************************************************************

function DxElement:getInheritedChildren()
	local children = {}
	
	for i, child in ipairs(self.children) do
		table.insert(children, child)
		
		for i, grandChild in ipairs(child:getInheritedChildren()) do
			table.insert(children, grandChild)
		end
	end

	return children
end

function DxElement:isInheritedChild(element)
	for i,e in pairs(self:getInheritedChildren()) do
		if(element == e) then
			return true
		end
	end
	return false
end

function DxElement:getInheritedChildrenByType(elementType)
	local children = {}
	for i, element in ipairs(self:getInheritedChildren()) do
		if(element.type == elementType) then
			table.insert(children, element)
		end
	end
	
	return children
end

-- **************************************************************************

function DxElement:getChildren()
	return self.children
end

function DxElement:getChildrenByType(elementType)
	local children = {}
	for i, element in ipairs(self:getChildren()) do
		if(element.type == elementType) then
			table.insert(children, element)
		end
	end
	
	return children
end

-- **************************************************************************

function DxElement:getType()
	return self.type
end

-- **************************************************************************

function DxElement:addProperty(property, value)
	if(self.properties[property] ~= nil) then
		return false
	end
	
	self.properties[property] = value
	
	return true
end

function DxElement:removeProperty(property)
	if(self.properties[property] == nil) then
		return false
	end
	
	self.properties[property] = nil
	
	return true
end

-- **************************************************************************

function DxElement:setProperty(property, value)
	if(self.properties[property] == nil) then
		return false
	end
	
	if(type(value) ~= type(self.properties[property])) then
		return false
	end
	
	self.properties[property] = value
	
	return true
end

function DxElement:getProperty(property)
	return self.properties[property]
end

-- **************************************************************************

function DxElement:setAlpha(alpha)
	if(not tonumber(alpha)) then
		return false
	end
	
	self.color.a = tonumber(alpha)
	
	return true
end

function DxElement:getAlpha()
	return self.alpha
end

-- **************************************************************************

function DxElement:setVisible(bool)
	if(type(bool) ~= "boolean") then
		return false
	end
	
	self.visible = bool
	
	return true
end

function DxElement:isVisible()
	return self.visible
end

-- **************************************************************************

function DxElement:setColor(r, g, b, a)
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
	
	return true
end

function DxElement:getColor()
	return self.primaryColor.r, self.primaryColor.g, self.primaryColor.b, self.primaryColor.a
end

-- **************************************************************************

function DxElement:setHoverColor(r, g, b, a)
	r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
	
	if(r) then
		self.hoverColor.r = (r >= 0 and r <= 255) and r or self.hoverColor.r
	end
	
	if(g) then
		self.hoverColor.g = (g >= 0 and g <= 255) and g or self.hoverColor.g
	end
	
	if(b) then
		self.hoverColor.b = (b >= 0 and b <= 255) and b or self.hoverColor.b
	end
	
	if(a) then
		self.hoverColor.a = (a >= 0 and a <= 255) and a or self.hoverColor.a
	end
	
	return true
end

function DxElement:getHoverColor()
	return self.hoverColor.r, self.hoverColor.g, self.hoverColor.b, self.hoverColor.a
end

-- **************************************************************************

function DxElement:setTextColor(r, g, b, a)
	r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
	
	if(r) then
		self.textColor.r = (r >= 0 and r <= 255) and r or self.textColor.r
	end
	
	if(g) then
		self.textColor.g = (g >= 0 and g <= 255) and g or self.textColor.g
	end
	
	if(b) then
		self.textColor.b = (b >= 0 and b <= 255) and b or self.textColor.b
	end
	
	if(a) then
		self.textColor.a = (a >= 0 and a <= 255) and a or self.textColor.a
	end
	
	return true
end

function DxElement:getTextColor()
	return self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a
end

-- **************************************************************************

function DxElement:setPosition(x, y)
	x, y = tonumber(x), tonumber(y)
	
	self.baseX, self.baseY = x and x or self.baseX, y and y or self.baseY
	
	if(not self:hasParent()) then
		self.x, self.y = self.baseX, self.baseY
	end
	
	return true
end

function DxElement:getPosition()
	return self.x, self.y
end

function DxElement:isPositionUpdated()
	if(self.baseX ~= self.previousBaseX) or (self.baseY ~= self.previousBaseY) then
		return true
	end
	
	return false
end

-- **************************************************************************

function DxElement:setSize(width, height)
	width, height = tonumber(width), tonumber(height)
	
	self.width, self.height = width and width or self.width, height and height or self.height
	
	return true
end

function DxElement:getSize()
	return self.width, self.height
end

function DxElement:isSizeUpdated()
	if(self.width ~= self.previousWidth) or (self.height ~= self.previousHeight) then
		return true
	end
	
	return false
end

-- **************************************************************************

function DxElement:setText(text)
	if(type(text) ~= "string") then
		return false
	end
	
	self.text = text
	
	return true
end

function DxElement:getText()
	return self.text
end

-- **************************************************************************

function DxElement:getRelativePositionFromAbsolute(x, y)
	local rootWidth, rootHeight = SCREEN_WIDTH, SCREEN_HEIGHT
	
	if(self:hasParent()) then
		rootWidth, rootHeight = self.parent.width, self.parent.height
	end
	
	return x / rootWidth, y / rootHeight
end

function DxElement:getAbsolutePositionFromRelative(x, y)
	local rootWidth, rootHeight = SCREEN_WIDTH, SCREEN_HEIGHT
	
	if(self:hasParent()) then
		rootWidth, rootHeight = self.parent.width, self.parent.height
	end

	return x * rootWidth, y * rootHeight
end

function DxElement:getRelativeSizeFromAbsolute(width, height)
	local rootWidth, rootHeight = SCREEN_WIDTH, SCREEN_HEIGHT
	
	if(self:hasParent()) then
		rootWidth, rootHeight = self.parent.width, self.parent.height	
	end
	
	return width / rootWidth, height / rootHeight
end

function DxElement:getAbsoluteSizeFromRelative(width, height)
	local rootWidth, rootHeight = SCREEN_WIDTH, SCREEN_HEIGHT
	
	if(self:hasParent()) then
		rootWidth, rootHeight = self.parent.width, self.parent.height
	end
	
	return width * rootWidth, height * rootHeight
end

-- **************************************************************************

function DxElement:isTerminated()
	local rootElement = self:getRootElement()
	
	if(self.terminated) then
		return true
	end
	
	for i, parent in ipairs(self:getInheritedParents()) do
		if(parent.terminated) then
			return true
		end
	end
	
	return false
end

-- **************************************************************************

function DxElement:setIndex(index)
	local tbl = self.parent and self.parent.children or DxElements
	
	if(index > #tbl) or (index < 1) then
		return false
	end
	
	--Update the current index, important.
	callPrivateMethod(self, "refreshIndex")
	
	local currentIndex = self:getIndex()
	
	table.insert(tbl, index, table.remove(tbl, currentIndex))
	
	for i=#DxElements,1,-1 do
		local element = DxElements[i]
		if(element:isRootElement()) then
			callPrivateMethod(element, "refreshIndex")
			callPrivateMethod(element, "refreshEventHandlers")
			
			local children = element:getInheritedChildren()
			
			for i=1, #children do
				local child = children[i]
				callPrivateMethod(child, "refreshIndex")
				callPrivateMethod(child, "refreshEventHandlers")
			end
		end		
	end	
	
	return true
end

function DxElement:getIndex()
	return self.index
end

-- **************************************************************************

function DxElement:getRootElements()
	local elements = {}
	for i, element in ipairs(DxElements) do
		if(element:isRootElement()) then
			table.insert(elements, element)
		end
	end
	return elements
end

function DxElement:getNonRootElements()
	local elements = {}
	for i, element in ipairs(DxElements) do
		if(not element:isRootElement()) then
			table.insert(elements, element)
		end
	end
	return elements
end

-- **************************************************************************

function DxElement:bringToFront()
	self:setIndex(1)
	
	if(self:hasParent()) then
		self.parent:bringToFront()
	end
end

function DxElement:sendToBack()
	self:setIndex(#DxElements)
end

function DxElement:isFront()
	if(self.index == 1) then
		return true
	end
	
	return false
end

-- **************************************************************************

function DxElement:setCentered(horizontal, vertical)
	local width, height = self:hasParent() and self:getParent().width or SCREEN_WIDTH, self:hasParent() and self:getParent().height or SCREEN_HEIGHT
	
	if(horizontal) then
		local x = (width / 2) - (self.width / 2)
		
		self:setPosition(x)
	end
	
	if(vertical) then	
		local y = (height / 2) - (self.height / 2)
		
		self:setPosition(nil, y)
	end
end