ObjectStorageDialog = {
	CONTROLS = {
		ITEM_TEXT = "itemText",
		ITEM_TEXTAMOUNT = "itemTextAmount",
		IAMOUNT_ELEMENT = "amountElement",
		ITEMS_ELEMENT = "itemsElement"
	}
}
local ObjectStorageDialog_mt = Class(ObjectStorageDialog, YesNoDialog)

function ObjectStorageDialog.register()
	local objectStorageDialog = ObjectStorageDialog.new()

	g_gui:loadGui("dataS/gui/dialogs/ObjectStorageDialog.xml", "ObjectStorageDialog", objectStorageDialog)

	ObjectStorageDialog.INSTANCE = objectStorageDialog
end

function ObjectStorageDialog.show(callback, target, title, objectInfos, maxUnloadAmount)
	if ObjectStorageDialog.INSTANCE ~= nil then
		local dialog = ObjectStorageDialog.INSTANCE

		dialog:setCallback(callback, target)
		dialog:setTitle(title)
		dialog:setText(nil)
		dialog:setObjectInfos(objectInfos, maxUnloadAmount)
		g_gui:showDialog("ObjectStorageDialog")
	end
end

function ObjectStorageDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or ObjectStorageDialog_mt)
	self.selectedInfo = nil
	self.selectedInfoIndex = 1
	self.selectedAmount = 1
	self.maxUnloadAmount = math.huge

	self:registerControls(ObjectStorageDialog.CONTROLS)

	return self
end

function ObjectStorageDialog.createFromExistingGui(gui, guiName)
	ObjectStorageDialog.register()

	local callback = gui.callbackFunc
	local target = gui.target
	local title = gui.dialogTitle
	local objectInfos = gui.objectInfos

	ObjectStorageDialog.show(callback, target, title, objectInfos)
end

function ObjectStorageDialog:onClickOk()
	self.callbackArgs = self.selectedAmount

	self:sendCallback(self.selectedInfoIndex)

	self.objectInfos = nil
end

function ObjectStorageDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil, nil)

	return false
end

function ObjectStorageDialog:onClickItems(state)
	self.selectedInfoIndex = state
	self.selectedInfo = self.objectInfos[state]
	local amountTexts = {}

	if self.selectedInfo ~= nil then
		for i = 1, math.min(self.maxUnloadAmount, self.selectedInfo.numObjects) do
			table.insert(amountTexts, string.format("%d / %d", i, self.selectedInfo.numObjects))
		end
	end

	self.amountElement:setTexts(amountTexts)

	self.selectedAmount = #amountTexts

	self.amountElement:setState(self.selectedAmount, true)
end

function ObjectStorageDialog:onClickAmount(state)
	self.selectedAmount = state
end

function ObjectStorageDialog:setTitle(title)
	ObjectStorageDialog:superClass().setTitle(self, title)

	self.dialogTitle = title
end

function ObjectStorageDialog:setObjectInfos(objectInfos, maxUnloadAmount)
	self.objectInfos = objectInfos
	self.maxUnloadAmount = maxUnloadAmount or self.maxUnloadAmount
	local objectInfoTable = {}

	for _, objectInfo in pairs(objectInfos) do
		if objectInfo.objects[1] ~= nil then
			table.insert(objectInfoTable, objectInfo.objects[1]:getDialogText())
		end
	end

	self.itemsElement:setTexts(objectInfoTable)
	self.itemsElement:setState(1, true)
end
