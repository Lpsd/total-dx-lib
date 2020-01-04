PrivateMethods = {}
PrivateMethodCache = {}

-- *************************************************

function getPrivateMethod(class, methodName)
	local func = PrivateMethods[methodName]
	
	if(not func) then
		return false
	end	
	
	if(not PrivateMethodCache[class.uid]) then
		PrivateMethodCache[class.uid] = {}
	end
	
	if(not PrivateMethodCache[class.uid][methodName]) then
		PrivateMethodCache[class.uid][methodName] = bind(func, class)
	end

	return PrivateMethodCache[class.uid][methodName]
end

function callPrivateMethod(class, methodName, ...)
	local func = getPrivateMethod(class, methodName)
	
	if(not func) then
		return false
	end
	
	return func(...)
end

function isPrivateMethodFunctionBound(class, func)
	for methodName, boundFunc in pairs(PrivateMethodCache[class.uid]) do
		if(boundFunc == func) then
			return true
		end
	end
	
	return false
end

-- *************************************************f

function PrivateMethods:draw(allow)
	local isRootElement = self:isRootElement()
	
	if(not self:isCanvasEnabled()) then
		if(self:hasParent() and not allow) then
			return false
		end
		
		if(self:inCanvas()) then
			return false
		end
			
		if(self:isMaskEnabled()) then
			self:drawMask()
		else
			self:dx()
		end
			
		for i=#self.children,1,-1 do
			local child = self.children[i]
			callPrivateMethod(child, "draw", true)
		end
	else
		if(isRootElement) then
			if(not self:inCanvas()) then
				if(self:isMaskEnabled()) then
					self:drawMask()
				else
					self:dx()
				end
				callPrivateMethod(self, "generateCanvas")
			end
		end
	end
end

function PrivateMethods:drawCanvas()
	if(self:isCanvasEnabled()) then
		if(self:isRootElement()) then
			dxDrawImage(self.x, self.y, self.canvas.width, self.canvas.height, self:getCanvas())
		end
	end
end

-- *************************************************

function PrivateMethods:updatePreviousDimensions()
	self.previousX, self.previousY = self.x, self.y
	self.previousBaseX, self.previousBaseY = self.baseX, self.baseY
	self.previousWidth, self.previousHeight = self.width, self.height
end

-- *************************************************

function PrivateMethods:render()
	for i, func in ipairs(self.renderFunctions.normal) do
		func() 
	end	
end

function PrivateMethods:prerender()
	if(self:hasParent()) then
		self.x, self.y = self.baseX + self.parent.x, self.baseY + self.parent.y
	end
	
	for i, func in ipairs(self.renderFunctions.prerender) do
		func() 
	end
end

-- *************************************************

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

-- *************************************************

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
		
		if(self.width > targetArea.width) or (self.height > targetArea.height) then
			return false
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

-- *************************************************

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

-- *************************************************

function PrivateMethods:generateCanvas()
	if(not self:isCanvasEnabled()) then
		self:createCanvas()
	end
	
	if(self:isSizeUpdated()) then
		destroyElement(self.canvas.texture)
		self.canvas.texture = dxCreateRenderTarget(self.width, self.height, true)
		self.canvas.width, self.canvas.height = self.width, self.height
	end	
	
	dxSetRenderTarget(self:getCanvas(), true)
	dxSetBlendMode("add")
	
	local children = self:getInheritedChildren()
	
	for i=#children,1,-1 do
		local child = children[i]
		local x, y = child.baseX, child.baseY
		
		if(child.parent ~= self) then
			x, y = child:getInheritedBasePosition()
		end
		
		if(child:isMaskEnabled()) then
			child:drawMask(x, y)
		else
			child:dx(x, y)
		end
	end
	
	dxSetBlendMode()
	dxSetRenderTarget()
end

-- *************************************************

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

-- *************************************************

function PrivateMethods:refreshEventHandlers()
	removeEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	addEventHandler("onClientRender", root, getPrivateMethod(self, "render"))
	removeEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))
	addEventHandler("onClientPreRender", root, getPrivateMethod(self, "prerender"))	
end

-- *************************************************

--Basically just an alias (for better naming)
function PrivateMethods:updateCachedTextures()
	self:getTexture()
	self:getMaskTexture()
end
