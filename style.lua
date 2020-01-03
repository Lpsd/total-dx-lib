DxStyles = {}
DxStyle = false

STYLES_PATH = "styles"
STYLE_DEFINITIONS_PATH = "styles.xml"

function getAllStyles()
	local xmlNode = xmlLoadFile(STYLE_DEFINITIONS_PATH)
	
	local styleNodes = xmlNodeGetChildren(xmlNode)

	for i, node in ipairs(styleNodes) do
		local attributes = xmlNodeGetAttributes(node)
		if(attributes.default == "true") then
			DxStyle = attributes.name
		end
		
		DxStyles[attributes.name] = {
			name = attributes.name,
			src = attributes.src
		}
		
		DxStyles[attributes.name].style = getStyleData(attributes.name)
	end
end

function getStyleData(styleName)
	styleName = styleName or DxStyle
	
	if(not DxStyles[styleName]) then
		return iprint("[DXLIB] Style doesn't exist", "getStyleData")
	end
	
	if(not DxStyles[styleName].style) then
		local style = {}
		
		local xmlNode = xmlLoadFile(STYLES_PATH.."/"..DxStyles[styleName].src)
		
		local elementTypes = xmlNodeGetChildren(xmlNode)
		
		for i, node in ipairs(elementTypes) do
			local elementType = xmlNodeGetName(node)
			
			style[elementType] = {}
			
			local styles = xmlNodeGetChildren(node)
			
			for i, styleNode in ipairs(styles) do
				local attributes = xmlNodeGetAttributes(styleNode)
				
				for _, attribute in ipairs(attributes) do
					attribute = tonumber(attribute) or attribute
				end
				
				local attributeName = attributes.name
				
				attributes.name = nil
				
				style[elementType][attributeName] = attributes
			end
		end
		
		return style
	end
	
	return DxStyles[styleName].style
end

function setCurrentStyle(styleName)
	if(not DxStyles[styleName]) then
		return iprint("[DXLIB] Style doesn't exist", "setCurrentStyle")
	end	
	
	DxStyle = styleName
end

-- ************************************************************************************** --

function getStyleSetting(elementType, name)
	return getStyleData()[elementType] and getStyleData()[elementType][name] or false
end

-- ************************************************************************************** --

function getPrimaryColor()
	local color = getStyleSetting("general", "primary_color")
	return {r = color.r, g = color.g, b = color.b, a = color.a}
end

-- ************************************************************************************** --
