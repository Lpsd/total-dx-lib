local function init()	
	--Load all styles
	getAllStyles()
	
	--Debug testing
	if(DEBUG) then

	end
end
addEventHandler("onClientResourceStart", resourceRoot, init)