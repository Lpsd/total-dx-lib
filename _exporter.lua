local metaFile = false
local metaNodes = false

local funcInjectCode = ""

function dxInitializeExporter()
	if(metaFile) then
		return false
	end
	
	funcInjectCode = [[
		local dxOOPClass = {}
		
		dxOOPClass.resourceName = "]] .. RESOURCE_NAME .. [["
		dxOOPClass.resource = getResourceFromName(dxOOPClass.resourceName)
		
		dxOOPClass.elements = {}
		
		dxOOPClass.mt = {
			__index = function(obj, key)
				return function(self, ...)
					local funcName = "dx" .. string.gsub(key, "^%l", string.upper)
					return call(dxOOPClass.resource, funcName, self.uid, ...)
				end
			end
		}
		
		dxOOPClass.init = function()
			local resource = getResourceFromName(dxOOPClass.resourceName)
			
			if(not resource) then
				return
			end
			
			dxOOPClass.resource = resource
		end
		addEventHandler("onClientResourceStart", root, dxOOPClass.init)
		
		dxOOPClass.exit = function()
			for i, element in ipairs(dxOOPClass.elements) do
				call(dxOOPClass.resource, "dxDestroy", element.uid)
			end
		end
		addEventHandler("onClientResourceStop", resourceRoot, dxOOPClass.exit)
	]]
	
	
	metaFile = xmlLoadFile("meta.xml")
	metaNodes = xmlNodeGetChildren(metaFile)
	
	for i, node in ipairs(metaNodes) do
		if(xmlNodeGetName(node) == "export") then
			local funcName = xmlNodeGetAttribute(node, "function")
			local typeof = xmlNodeGetAttribute(node, "type")
			
			local metatable = string.find(funcName, "Create") or false
			
			if(typeof == "client") or (typeof == "shared") then
				if(not metatable) then
					funcInjectCode = funcInjectCode .. [[
						function ]] .. funcName .. [[(...)
							return exports.]] .. RESOURCE_NAME .. ":" .. funcName .. [[(...)
						end 
					]]
				else
					funcInjectCode = funcInjectCode .. [[
						function ]] .. funcName .. [[(...)
							local element = exports.]] .. RESOURCE_NAME .. ":" .. funcName .. [[(...)
							
							dxOOPClass.elements[#dxOOPClass.elements + 1] = element
							
							setmetatable(element, dxOOPClass.mt)
							
							return element
						end 
					]]		
				end
			end
		end
	end
end

function dxLoadFunctions()
	return funcInjectCode
end
