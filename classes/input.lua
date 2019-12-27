DxInput = inherit(DxElement)

function DxInput:constructor(x, y, width, height, text)
	self.type = "dx-input"
	
	self.caretIndex = 0
	
	self.text = {
		text = text,
		visibleText = text,
		maxCaretIndex = 0,
		offsetIndex = 0,
		padding = {
			left = 10,
			right = 10,
			top = 0,
			bottom = 0
		}
	}
	
	self:updateVisibleText()
	
	self.guiElement = guiCreateEdit(0, 0, width, height, text, false)
	-- guiSetAlpha(self.guiElement, 0)
	
	local primaryColor = getStyleSetting("input", "primary_color")
	self:setColor(primaryColor.a, primaryColor.g, primaryColor.b, primaryColor.a)
	
	local defaultTextColor = getStyleSetting("input", "text_color")
	
	self.textColor = {
		r = defaultTextColor.r,
		g = defaultTextColor.g,
		b = defaultTextColor.b,
		a = defaultTextColor.a
	}
	
	self.setGUIElementFocused = function()
		self.focused = guiFocus(self.guiElement)
		self.focused = true
	end
	
	self:addClickFunction(self.setGUIElementFocused)
	self:addClickFunction(self.setCaretIndexOnClick)
	
	self.fOnClientGUIChanged = bind(self.onClientGUIChanged, self)
	addEventHandler("onClientGUIChanged", root, self.fOnClientGUIChanged)
	
	self.fOnClientGUIBlur = bind(self.onClientGUIBlur, self)
	addEventHandler("onClientGUIBlur", self.guiElement, self.fOnClientGUIBlur)
	
	self:addRenderFunction(self.updateTextOffsetIndex)
	self:addRenderFunction(self.syncCaretIndex)
	self:addRenderFunction(self.updateVisibleText)
end

function DxInput:destroy()
	removeEventHandler("onClientGUIChanged", root, self.fOnClientCharacter)
	removeEventHandler("onClientGUIBlur", self.guiElement, self.fOnClientGUIBlur)
end

-- **************************************************************************

function DxInput:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	
	--Draw text
	local text = self:getTextBounds(x, y)
	dxDrawText(self:getVisibleText(), text.left, text.top, text.right, text.bottom, tocolor(self.textColor.r, self.textColor.g, self.textColor.g, self.textColor.a), 1, "default", "left", "center")
	
	--Draw caret
	if(self.focused) then
		if(self:getCaretIndex()) then
			local caretX = self:getCaretPosition()
			dxDrawRectangle(text.left + caretX, y+(self.height*0.25/2), 2, self.height*0.75, tocolor(0,0,0,25))
		end
	end
end

-- **************************************************************************

function DxInput:getTextBounds(x, y)
	x, y = x or self.x, y or self.y
	
	local text = {}
	text.left = (x + self.text.padding.left)
	text.top = (y + self.text.padding.top)
	text.right = (x + self.width) - self.text.padding.right
	text.bottom = (y + self.height) - self.text.padding.bottom

	return text
end

-- **************************************************************************

function DxInput:getCaretIndexFromCursorPosition(cursorX, cursorY)
	local bounds = self:getTextBounds()
	
	local characters = {}
	self:getText():gsub(".", function(c)
		table.insert(characters, c)
	end)
	
	local offset = 0
	
	local offsetIndex = self:getTextOffsetIndex()
	
	for i=offsetIndex+1, #characters do
		local character = characters[i]
		
		local characterWidth = dxGetTextWidth(character, 1, "default", false)
		
		if(offset == 0) then
			if(cursorX < bounds.left) then
				return 0
			end
		end
		
		if(isMouseInPosition(bounds.left + offset, bounds.top, characterWidth, self.height)) then
			return (i-1) >= 0 and (i-1) or 0
		end
		
		offset = offset + characterWidth
	end
	
	return #characters
end

function DxInput:setCaretIndexOnClick(cursorX, cursorY)
	return self:setCaretIndex(self:getCaretIndexFromCursorPosition(cursorX, cursorY))
end

-- **************************************************************************

function DxInput:getCaretIndex()
	return self.caretIndex
end

function DxInput:setCaretIndex(index)
	if(index == self.caretIndex) then
		return false
	end
	
	self.caretIndex = index
	guiSetProperty(self.guiElement, "CaratIndex", index)
	
	return true
end

-- **************************************************************************

function DxInput:getCaretPosition()
	local bounds = self:getTextBounds()
	
	local characters = {}
	self:getText():gsub(".", function(c)
		table.insert(characters, c)
	end)

	local caretIndex = self:getCaretIndex()
	
	if(not caretIndex) then
		return false
	end
	
	local inputWidth = self:getInputWidth()

	local str = ""
	
	local offsetIndex = self:getTextOffsetIndex()
	
	for i=offsetIndex+1, #characters do
		local character = characters[i]
		
		if i <= caretIndex then
			local nextLength = dxGetTextWidth(str .. character, 1, "default", false)
			
			if(nextLength <= inputWidth) then
				str = str .. character
			end
		end
	end
	
	local textLength = dxGetTextWidth(str, 1, "default", false)
	
	--x
	return textLength
end

-- **************************************************************************

function DxInput:syncCaretIndex()
	local caretIndex = tonumber(guiGetProperty(self.guiElement, "CaratIndex"))
	return self:setCaretIndex(caretIndex)
end

-- **************************************************************************

function DxInput:updateVisibleText()	
	local inputWidth = self:getInputWidth()
	
	local textWidth = dxGetTextWidth(self:getText(), 1, "default", false)
	
	local visibleText = ""
	local visibleWidth = 0
	
	local characters = {}
	self:getText():gsub(".", function(c)
		table.insert(characters, c)
	end)	
	
	if (textWidth > inputWidth) then		
		local lastCaretIndex
		local offsetIndex = self:getTextOffsetIndex()
		
		for i=offsetIndex+1, #characters do
			local character = characters[i]
			
			local characterWidth = dxGetTextWidth(character, 1, "default", false)
			
			if (visibleWidth + characterWidth <= inputWidth) then
				visibleText = visibleText .. character
				visibleWidth = visibleWidth + characterWidth
				lastCaretIndex = (i - offsetIndex)
			else
				break
			end
		end	
		
		self:setVisibleText(visibleText)
		self:setMaxCaretIndex(#visibleText)
	else
		self:setVisibleText(self:getText())
		self:setMaxCaretIndex(#characters)
	end
end

-- **************************************************************************

function DxInput:updateTextOffsetIndex()
	local relativeCaretIndex = self:getRelativeCaretIndex()
	
	if(relativeCaretIndex < 0) then
		self.text.offsetIndex = self.text.offsetIndex - 1
	end
	
	if(relativeCaretIndex > self:getMaxCaretIndex()) then
		self.text.offsetIndex = self.text.offsetIndex + 1
	end
end

-- **************************************************************************

function DxInput:setVisibleText(text)
	self.text.visibleText = text
	return true
end

function DxInput:getVisibleText()
	return self.text.visibleText
end

-- **************************************************************************

function DxInput:getRelativeCaretIndex()
	return self:getCaretIndex() - self.text.offsetIndex
end

function DxInput:getTextOffsetIndex()
	return self.text.offsetIndex
end

-- **************************************************************************

function DxInput:setMaxCaretIndex(index)
	self.text.maxCaretIndex = index
	return true
end

function DxInput:getMaxCaretIndex()
	return self.text.maxCaretIndex
end

-- **************************************************************************

function DxInput:getInputWidth()
	local bounds = self:getTextBounds()
	return (bounds.right - bounds.left)
end

-- **************************************************************************

function DxInput:onClientGUIBlur()
	self.focused = false
end

-- **************************************************************************

function DxInput:onClientGUIChanged()
	self.text.text = guiGetText(self.guiElement)
end

-- **************************************************************************

function DxInput:getText()
	return self.text.text
end

function DxInput:setText(text)
	self.text.text = text
	
	return guiSetText(self.guiElement, text)
end

-- **************************************************************************
