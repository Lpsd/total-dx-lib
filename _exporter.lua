local metaFile = false
local metaNodes = false

local funcInjectCode = ""

function dxInitializeExporter()
	if(metaFile) then
		return false
	end
	
	funcInjectCode = [[
		local dxOOPClass = {
			resourceName = "]] .. RESOURCE_NAME .. [[",
			resource = getResourceFromName("]] .. RESOURCE_NAME .. [[")
		}
		
		local mt = {
			__index = function(obj, key)
				return function(self, ...)
					local funcName = "dx" .. string.gsub(key, "^%l", string.upper)
					return call(dxOOPClass.resource, funcName, self.uid, ...)
				end
			end
		}
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
							
							setmetatable(element, mt)
							
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
