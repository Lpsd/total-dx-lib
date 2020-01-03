DxWindow = inherit(DxElement)

function DxWindow:constructor(x, y, width, height, titlebarText)	
	self.type = "dx-window"
	
	titlebarText = titlebarText or "Window"

	local titlebarColor = getStyleSetting("window", "titlebar_color")
	
	self.titlebar = {
		state = true,
		text = titlebarText,
		height = math.max(self.height / 10, 25),
		color = {
			r = titlebarColor.r,
			g = titlebarColor.g,
			b = titlebarColor.b,
			a = titlebarColor.a	
		}
	}
	
	self.close = {
		state = true,
		element = DxText:new(0, 0, self.titlebar.height, self.titlebar.height, "x", "center", "center")
	}
	
	local closeButtonColor = getStyleSetting("window", "close_button_bg_color")
	
	self.close.element:setColor(closeButtonColor.r, closeButtonColor.g, closeButtonColor.b, closeButtonColor.a)
	self.close.element:setProperty("ignore_window_bounds", true)
	self.close.element:setPosition(self.width - self.titlebar.height)
	self.close.element:setParent(self)
	
	self.close.closeOnClick = function(button, state, x, y)
		if(button == "left") and (state == "down") then
			if (self.close.state) then
				self:delete()
			end
		end
	end
	
	self.close.element:addClickFunction(self.close.closeOnClick)
	
	self.update = function()
		if (self:isSizeUpdated()) then
			--Update close button
			local x = self.width - self.titlebar.height
			self.close.element:setPosition(x)
			
			--Update drag area
			self:setDragArea(nil, nil, self.width)
		end
	end
	
	self:addRenderFunction(self.update)
	
	self:setProperty("allow_drag", true)
	self:setDragArea(nil, nil, nil, self.titlebar.height)

	self:createCanvas()
end

function DxWindow:dx(x, y)
	x, y = x or self.x, y or self.y
	dxDrawRectangle(x, y, self.width, self.height, tocolor(self.color.r, self.color.g, self.color.b, self.color.a))
	
	if (self.titlebar.state) then
		--Titlebar
		dxDrawRectangle(x, y, self.width, self.titlebar.height, tocolor(self.titlebar.color.r, self.titlebar.color.g, self.titlebar.color.b, self.titlebar.color.a))
		dxDrawText(self.titlebar.text, x, y, x + self.width, y + self.titlebar.height, tocolor(255, 255, 255), 1, "default", "center", "center")
	end
end
