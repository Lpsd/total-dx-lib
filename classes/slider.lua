DxSlider = inherit(DxElement)

function DxSlider:constructor(x, y, width, height, progress)	
	self.type = "dx-slider"
	
	local sliderHeight = math.max(1, (self.height / 4))
	
	self.slider = {
		element = DxBlank:new(0, (self.height / 2) - (sliderHeight / 2), self.width, sliderHeight)
	}
	
	self.slider.element:setParent(self)
	
	local sliderColor = getStyleSetting("slider", "slider_color")
	self.slider.element:setColor(sliderColor.r, sliderColor.g, sliderColor.b, sliderColor.a)	
	
	local handleColor = getStyleSetting("slider", "handle_color")
	local handleSize = (height / 1.4)
	handleSize = (handleSize % 2 == 0) and handleSize or (handleSize + 1)
	
	self.handle = {
		element = DxCircle:new(0, 0, handleSize, handleSize,0),
		color = {
			r = handleColor.r,
			g = handleColor.g,
			b = handleColor.b,
			a = handleColor.a
		}
	}
	
	self.handle.element:setParent(self)
	self.handle.element:setColor(self.handle.color.r, self.handle.color.g, self.handle.color.b, self.handle.color.a)
	
	self.handle.element:setProperty("allow_drag_x", true)
	self.handle.element:setCentered(nil, true)
	
	self:setProgress(tonumber(progress) or 0)
	
	self:addRenderFunction(self.updateProgress, true)
end

function DxSlider:dx(x, y)
	x, y = x or self.x, y or self.y
end

function DxSlider:updateProgress()
	if(self.allowUpdate) then
		self.progress = self:getProgress()
		self.allowUpdate = false
	end
		
	if(self.handle.element.dragging) then
		if(not self.allowUpdate) then
			self.allowUpdate = true
		end
	end
end

function DxSlider:getProgress()
	return ((self.width) * (self.handle.element.baseX / (100 - self.handle.element.width)))
end

function DxSlider:setProgress(progress)
	self.handle.element.baseX  = remap(math.clamp(progress, 0, 100), 0, 100, 0, (100 - self.handle.element.width))
end
