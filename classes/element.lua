DxElement = {}

local PrivateMethods = {}
local PrivateMethodCache = {}

-- *************************************************

local function getPrivateMethod(class, methodName)
	local func = PrivateMethods[methodName]
	
	if(not func) then
		return false
	end	
	
	if(not PrivateMethodCache[class]) then
		PrivateMethodCache[class] = {}
	end
	
	if(not PrivateMethodCache[class][methodName]) then
		PrivateMethodCache[class][methodName] = bind(func, class)
	end

	return PrivateMethodCache[class][methodName]
end

local function callPrivateMethod(class, methodName, ...)
	local func = getPrivateMethod(class, methodName)
	
	if(not func) then
		return false
	end
	
	return func(...)
end

-- *************************************************

function PrivateMethods:draw(allow, parent)
	-- Hacky solution for bypassing 1/2 frames of delay when initializing an element (relating to onClient(pre)Render and private methods)
	if(getTickCount() < (self.initTime + 10)) then
		return
	end
	
	local isRootElement = self:isRootElement()
	
	if(not self:hasCanvas()) then
		if(self:hasParent() and not allow) then
			return false
		end
			
		self:dx()
			
		for i=#self.children,1,-1 do
			local child = self.children[i]
			callPrivateMethod(child, "draw", true)
		end
	else
		if(isRootElement) then
			if(not self:inCanvas()) then
				self:dx()
				callPrivateMethod(self, "generateCanvas")
			end
		end
	end
end

function PrivateMethods:drawCanvas()
	if(self:hasCanvas()) then
		if(self:isRootElement()) then
			dxDrawImage(self.x, self.y, self.canvas.width, self.canvas.height, self:getCanvas())
		end
	end
end


function PrivateMethods:render()
	for i, func in ipairs(self.renderFunctions.normal) do
		func() 
	end
	
	self.previousX, self.previousY = self.x, self.y
	self.previousBaseX, self.previousBaseY = self.baseX, self.baseY
	self.previousWidth, self.previousHeight = self.width, self.height
end

function PrivateMethods:prerender()
	for i, func in ipairs(self.renderFunctions.prerender) do
		func() 
	end
	
	if(self:hasParent()) then
		self.x, self.y = self.baseX + self.parent.x, self.baseY + self.parent.y
	end
end

function PrivateMethods:drag()
	if(self.dragging) then
		local cx, cy = getCursorPosition()

		cx = cx * SCREEN_WIDTH
		cy = cy * SCREEN_HEIGHT
		
		if(not self.dragInitialX) then
			self.dragInitialX, self.dragInitialY = cx - self.x, cy - self.y
		end
		
		if(self:hasParent()) then
			self.baseX, self.baseY = self.baseX + (cx - self.dragInitialX) - self.x, self.baseY + (cy - self.dragInitialY) - self.y
			
			local rootElement = self.parent:getRootElement()
			local baseOffsetX, baseOffsetY = self.baseX, self.baseY
			local minX, minY, maxX, maxY = self.bounds.min.x, self.bounds.min.y, self.bounds.max.x, self.bounds.max.y
			
			for i,e in ipairs(self:getInheritedParents()) do
				if(e ~= rootElement) then
					baseOffsetX, baseOffsetY = baseOffsetX + e.baseX, baseOffsetY + e.baseY
				end
			end
			
			if((rootElement.x + baseOffsetX + maxX) > SCREEN_WIDTH) then
				self.baseX = SCREEN_WIDTH - rootElement.x - maxX - (baseOffsetX-self.baseX)
			end
			
			if((rootElement.y + baseOffsetY + maxY) > SCREEN_HEIGHT) then
				self.baseY = SCREEN_HEIGHT - rootElement.y - maxY - (baseOffsetY-self.baseY)
			end		
			
			if((self.baseX + minX) < -(self.parent and self.parent.x or 0)) then
				self.baseX = -(self.parent and self.parent.x or 0) - minX  
			end
			
			if((self.baseY + minY) < -(self.parent and self.parent.y or 0)) then
				self.baseY = -(self.parent and self.parent.y or 0) - minY 
			end
		else
			self.x, self.y = cx - self.dragInitialX, cy - self.dragInitialY
		end
	end
end

function PrivateMethods:click(button, state, x, y)
	if(button == "left") and (state == "up") then	
		if(DxInfo.draggingElement == self) then
			DxInfo.draggingElement = false
		end
		self.dragging = false
		self.dragInitialX, self.dragInitialY = false, false
	end
	
	if(DxInfo.draggingElement) then
		return false
	end
	
	if(not self:isMouseOverElement()) then
		return false
	end
	
	for i,element in ipairs(self.children) do
		if(element:isMouseOverElement()) then
			return callPrivateMethod(element, "click", button, state, x, y)
		end
	end
	
	if(self:isObstructed(x, y)) then
		return false
	end

	if(button == "left") and (state == "down") then	
		if(self:hasParent()) then
			if(self.parent:getProperty("child_dragging")) then
				if(self:getProperty("allow_drag")) then
					if(isMouseInPosition(self.x + self.dragArea.x, self.y + self.dragArea.y, self.dragArea.width, self.dragArea.height)) then
						self:bringToFront()
						self.dragging = true
						DxInfo.draggingElement = self
					end		
				end
			end
		else
			if(self:getProperty("allow_drag")) then
				if(isMouseInPosition(self.x + self.dragArea.x, self.y + self.dragArea.y, self.dragArea.width, self.dragArea.height)) then
					self:bringToFront()
					self.dragging = true
					DxInfo.draggingElement = self
				end	
			end
		end		
	end	
	
	for i, func in ipairs(self.clickFunctions) do
		func(button, state, x, y)
	end
end

function PrivateMethods:updateInheritedBounds()
	local minX, minY, maxX, maxY = self:getInheritedBounds()
	self.bounds = {
		min = {
			x = minX,
			y = minY
		},
		max = {
			x = maxX,
			y = maxY
		}
	}
	return true
end

function PrivateMethods:forceInBounds()
	if(not self:getProperty("force_in_bounds")) then
		return false
	end
	
	local targetArea = {
		x = 0,
		y = 0,
		width = SCREEN_WIDTH,
		height = SCREEN_HEIGHT
	}
	
	if(self:hasParent()) then
		if(self:getProperty("drag_preview")) then
			if(self.dragging) then
				return false
			end
		end
		
		targetArea.width, targetArea.height = self.parent.width, self.parent.height
		
		if(self.parent.type == "dx-window") then
			if(not self:getProperty("ignore_window_bounds")) then
				targetArea.y = targetArea.y + self.parent.titlebar.height
			end
		end
		
		if(self.baseX + self.width) > (targetArea.width) then
			self.baseX = (targetArea.width) - self.width
		elseif(self.baseX) < targetArea.x then
			self.baseX = targetArea.x
		end
		
		if(self.baseY + self.height) > (targetArea.height) then
			self.baseY = (targetArea.height) - self.height
		elseif(self.baseY) < targetArea.y then
			self.baseY = targetArea.y			
		end
	else
		for i,e in ipairs(self:getInheritedChildren()) do
			if(e.dragging) then
				return false
			end
		end
		
		local minX, minY, maxX, maxY = self.bounds.min.x, self.bounds.min.y, self.bounds.max.x, self.bounds.max.y
		
		if(self.x + maxX) > (targetArea.x + targetArea.width) then
			self.x = (targetArea.x + targetArea.width) - maxX
		elseif(self.x + minX) < targetArea.x then
			self.x = targetArea.y - minX		
		end
		
		if(self.y + maxY) > (targetArea.y + targetArea.height) then
			self.y = (targetArea.y + targetArea.height) - maxY
		elseif(self.y + minY) < targetArea.y then
			self.y = targetArea.y - minY			
		end	
	end
end

function PrivateMethods:cursorMove(relX, relY, absX, absY)
	if(not self:getProperty("hover_enabled")) then
		return false
	end
	
	if(self:isMouseOverElement()) then
		if(not self:isObstructed(absX, absY)) then
			if(self.hover) then
				self.color = self.hoverColor
				self.hovering = true
				return true
			end
		end
	end
	self.hovering = false
	self.color = self.primaryColor
end

function PrivateMethods:generateCanvas()
	if(not self:hasCanvas()) then
		self:createCanvas()
	end
	
	if(self:isSizeUpdated()) then
		destroyElement(self.canvas.texture)
		self.canvas.texture = dxCreateRenderTarget(self.width, self.height, true)
		self.canvas.width, self.canvas.height = self.width, self.height
	end	
	
	local clearRenderTarget = false
	
	for i, child in ipairs(self:getInheritedChildren()) do
		if(child:isPositionUpdated()) or (child:isSizeUpdated()) then
			clearRenderTarget = true
		end
	end
	
	dxSetRenderTarget(self:getCanvas(), clearRenderTarget)
	
	local children = self:getInheritedChildren()
	
	for i=#children,1,-1 do
		local child = children[i]
		local x, y = child.baseX, child.baseY
		
		if(child.parent ~= self) then
			x, y = child:getInheritedBasePosition()
		end
		
		child:dx(x, y)
	end
	
	dxSetRenderTarget()
end

function PrivateMethods:refreshIndex()
	local tbl = self:isRootElement() and DxElements or self.parent.children
	for i, element in ipairs(tbl) do
		if(self == element) then
			self.index = i
			return true
		end
	end
	return false
end


function PrivateMethods:refreshEventHandlers()
	removeEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	addEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	removeEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))
	addEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))	
end

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

-- **************************************************************************

function DxElement:virtual_constructor(x, y, width, height)
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
	
	self.centered = false
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
	
	self.properties = {
		["allow_drag"] = false,
		["force_in_bounds"] = true,
		["drag_preview"] = false,
		["child_dragging"] = true,
		["ignore_window_bounds"] = false,
		["obstruct"] = true,
		["hover_enabled"] = true
	}
	
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
	
	self.textColor = getStyleSetting("general", "text_color")
	
	self.initTime = getTickCount()
	
	addEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	addEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))	
	
	addEventHandler("onClientClick", root, getPrivateMethod(self, "click"))

	addEventHandler("onClientCursorMove", root, getPrivateMethod(self, "cursorMove"))

	self:addRenderFunction(getPrivateMethod(self, "draw"))
	
	self:addRenderFunction(getPrivateMethod(self, "drawCanvas"))
	
	self:addRenderFunction(getPrivateMethod(self, "drag"), true)
	
	self:addRenderFunction(getPrivateMethod(self, "updateInheritedBounds"))
	self:addRenderFunction(getPrivateMethod(self, "forceInBounds"), true)
	
	callPrivateMethod(self, "updateInheritedBounds")
	callPrivateMethod(self, "forceInBounds")
	
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

function DxElement:hasCanvas()
	return self.canvas.state
end

function DxElement:inCanvas(parent)
	parent = parent or self:getParent()
	if(parent) then
		if(parent:hasCanvas()) then
			return true
		else
			if(parent:hasParent()) then
				self:inCanvas(parent)
			end
		end
	end
	
	return false
end

function DxElement:getTexture()
	local canvas = dxCreateRenderTarget(self.width, self.height, true)
	
	dxSetRenderTarget(canvas)
	
	self:dx(0, 0)
	
	local children = self:getInheritedChildren()
	
	for i=#children,1,-1 do
		local child = children[i]
		local x, y = child.baseX, child.baseY
		
		if(child.parent ~= self) then
			x, y = child:getInheritedBasePosition()
		end
		
		child:dx(x, y)
	end
	
	dxSetRenderTarget()
	
	return canvas
end

-- **************************************************************************

function DxElement:addRenderFunction(func, prerender)
	if(type(func) ~= "function") then
		return false
	end
	func = bind(func, self)
	local tbl = self.renderFunctions.normal
	if(prerender) then
		tbl = self.renderFunctions.prerender
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

-- **************************************************************************

function DxElement:isMouseOverElement()
	if(isMouseInPosition(self.x, self.y, self.width, self.height)) then
		return true
	end
	return false
end

function DxElement:isObstructed(cursorX, cursorY)
	for i, element in ipairs(DxElements) do
		if(self:isObstructedByElement(cursorX, cursorY, element)) then
			return true
		end
	end
	return false
end

function DxElement:isObstructedByElement(cursorX, cursorY, element)
	return self:getObstructingElement(cursorX, cursorY, element) and true or false
end

function DxElement:getObstructingElement(cursorX, cursorY, element)
	if(not element:getProperty("obstruct")) then
		return false
	end
	
	if(element ~= self) then
		if(element.visible) then
			if(cursorX >= element.x and cursorX <= element.x + element.width and cursorY >= element.y and cursorY <= element.y + element.height) then
				if(self:isChild(element)) then
					return element
				else
					if(element:getRootElement().index < self:getRootElement().index) then
						return element
					end
				end
			end
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
	
	return bounds.min.x, bounds.min.y, bounds.max.x, bounds.max.y
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
	if(self:isInheritedChild(element)) then
		return true
	end
	for i,e in ipairs(self.children) do
		if(element == e) then
			return true
		end
	end
	return false
end

function DxElement:getTopLevelChild(element)
	local element
	
	for i,e in ipairs(self:getInheritedParents()) do
		if(not e:isRootElement()) then
			element = e
		end
	end
	
	return element or self
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

function DxElement:getRootElement()
	if(self:hasParent()) then
		return self.parent:getRootElement()
	end
	return self
end

function DxElement:isRootElement()
	if(self == self:getRootElement()) then
		return true
	end
	
	return false
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
	
	self.alpha = tonumber(alpha)
	
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

function DxElement:setPosition(x, y)
	x, y = tonumber(x), tonumber(y)
	
	self.baseX, self.baseY = x and x or self.baseX, y and y or self.baseY
	
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
	
	if(rootElement.terminated) then
		return true
	end
	
	for i, child in ipairs(self:getInheritedChildren()) do
		if(child.terminated) then
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
			
			for i, child in ipairs(element:getInheritedChildren()) do
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
