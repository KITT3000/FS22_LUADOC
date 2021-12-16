HelpLineManager = {}
local HelpLineManager_mt = Class(HelpLineManager, AbstractManager)
HelpLineManager.ITEM_TYPE = {
	TEXT = "text",
	IMAGE = "image"
}

function HelpLineManager.new(customMt)
	local self = AbstractManager.new(customMt or HelpLineManager_mt)

	return self
end

function HelpLineManager:initDataStructures()
	self.categories = {}
	self.categoryNames = {}
	self.triggers = {}
	self.triggerNodeToData = {}
	self.sharedLoadingIds = {}
	self.helpData = nil
end

function HelpLineManager:loadMapData(xmlFile, missionInfo)
	HelpLineManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.helpline#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load helpline config file '" .. tostring(filename) .. "'!")

		return false
	end

	self:loadFromXML(filename, missionInfo)

	local xmlObject = XMLFile.wrap(xmlFile, nil)

	xmlObject:iterate("map.helpline.trigger", function (index, key)
		local position = xmlObject:getVector(key .. "#position", nil, 3)

		if position ~= nil then
			local trigger = {
				position = position,
				categoryIndex = xmlObject:getInt(key .. "#categoryIndex", 1),
				pageIndex = xmlObject:getInt(key .. "#pageIndex", 1)
			}
			local category = self.categories[trigger.categoryIndex]

			if category ~= nil then
				local page = category.pages[trigger.pageIndex]

				if page ~= nil then
					local sharedLoadingId = g_i3DManager:loadI3DFileAsync("data/objects/helpIcon/icon.i3d", false, false, HelpLineManager.onIconLoaded, self, trigger)

					table.insert(self.sharedLoadingIds, sharedLoadingId)
				else
					Logging.xmlWarning(xmlObject, "Invalid helpline trigger page index for '%s'", key)
				end
			else
				Logging.xmlWarning(xmlObject, "Invalid helpline trigger category index for '%s'", key)
			end
		else
			Logging.xmlWarning(xmlObject, "Missing helpline trigger position for '%s'", key)
		end
	end)
	xmlObject:delete()

	self.activatable = HelpLineActivatable.new(self)

	return true
end

function HelpLineManager:unloadMapData()
	self.helpData = nil

	g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

	for _, sharedLoadingId in ipairs(self.sharedLoadingIds) do
		g_i3DManager:releaseSharedI3DFile(sharedLoadingId)
	end

	for _, trigger in ipairs(self.triggers) do
		g_currentMission:removeHelpTrigger(trigger.node)
		removeTrigger(trigger.triggerNode)
		delete(trigger.node)
	end

	HelpLineManager:superClass().unloadMapData(self)
end

function HelpLineManager:onIconLoaded(i3dNode, failedReason, trigger)
	if i3dNode ~= 0 then
		trigger.node = i3dNode
		trigger.triggerNode = getChildAt(getChildAt(i3dNode, 0), 0)
		self.triggerNodeToData[trigger.triggerNode] = trigger

		link(getRootNode(), i3dNode)
		addTrigger(trigger.triggerNode, "onIconTrigger", self)
		setWorldTranslation(i3dNode, trigger.position[1], trigger.position[2], trigger.position[3])
		addToPhysics(i3dNode)
		table.insert(self.triggers, trigger)
		g_currentMission:addHelpTrigger(trigger.node)
	end
end

function HelpLineManager:onIconTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	local data = self.triggerNodeToData[triggerId]

	if data ~= nil then
		if onEnter then
			self.helpData = data

			g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
		elseif onLeave then
			self.helpData = nil

			g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
		end
	end
end

function HelpLineManager:loadFromXML(filename, missionInfo)
	local xmlFile = XMLFile.load("helpLineViewContentXML", filename)

	xmlFile:iterate("helpLines.category", function (index, key)
		local category = self:loadCategory(xmlFile, key, missionInfo)

		if category ~= nil then
			table.insert(self.categories, category)
		end
	end)
	xmlFile:delete()
end

function HelpLineManager:loadCategory(xmlFile, key, missionInfo)
	local category = {
		title = xmlFile:getString(key .. "#title"),
		pages = {}
	}

	xmlFile:iterate(key .. ".page", function (index, key)
		local page = self:loadPage(xmlFile, key, missionInfo)

		table.insert(category.pages, page)
	end)

	return category
end

function HelpLineManager:loadPage(xmlFile, key, missionInfo)
	local page = {
		title = xmlFile:getString(key .. "#title"),
		paragraphs = {}
	}

	xmlFile:iterate(key .. ".paragraph", function (index, key)
		local paragraph = {
			text = xmlFile:getString(key .. ".text#text")
		}
		local filename = xmlFile:getString(key .. ".image#filename")

		if filename ~= nil then
			local heightScale = xmlFile:getFloat(key .. ".image#heightScale", 1)
			local aspectRatio = xmlFile:getFloat(key .. ".image#aspectRatio", 1)
			local size = GuiUtils.get2DArray(xmlFile:getString(key .. ".image#size"), {
				1024,
				1024
			})
			local uvs = GuiUtils.getUVs(xmlFile:getString(key .. ".image#uvs", "0 0 1 1"), size)
			paragraph.image = {
				filename = filename,
				uvs = uvs,
				size = size,
				heightScale = heightScale,
				aspectRatio = aspectRatio
			}
		end

		table.insert(page.paragraphs, paragraph)
	end)

	return page
end

function HelpLineManager:convertText(text)
	local translated = g_i18n:convertText(text)

	return string.gsub(translated, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
end

function HelpLineManager:getCategories()
	return self.categories
end

function HelpLineManager:getCategory(categoryIndex)
	if categoryIndex ~= nil then
		return self.categories[categoryIndex]
	end

	return nil
end

g_helpLineManager = HelpLineManager.new()
HelpLineActivatable = {}
local HelpLineActivatable_mt = Class(HelpLineActivatable)

function HelpLineActivatable.new()
	local self = setmetatable({}, HelpLineActivatable_mt)
	self.activateText = g_i18n:getText("helpLine_open")

	return self
end

function HelpLineActivatable:getIsActivatable()
	if g_gui.currentGui ~= nil then
		return false
	end

	if g_helpLineManager.helpData == nil then
		return false
	end

	if not g_currentMission:getCanShowHelpTriggers() then
		return false
	end

	return true
end

function HelpLineActivatable:run()
	local data = g_helpLineManager.helpData

	if data ~= nil then
		g_gui:showGui("InGameMenu")
		g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, data.categoryIndex, data.pageIndex)
	end
end
