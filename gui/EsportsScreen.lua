EsportsScreen = {
	MAP_ID_ARENA = "arena.mapArena",
	MAP_ID_BALESTACKING = "baleStacking.mapBaleStacking",
	VIDEO_DURATION = {
		BALE_STACKING = 29.58,
		ARENA = 32.86
	},
	CONTROLS = {
		"onlinePresenceNameElement",
		"changeNameButton",
		"arenaBox",
		"arenaBanner",
		"arenaTrainingButton",
		"baleStackingBox",
		"baleStackingBanner"
	}
}
local EsportsScreen_mt = Class(EsportsScreen, ScreenElement)

function EsportsScreen.register()
	local esportsScreen = EsportsScreen.new()

	g_gui:loadGui("dataS/gui/EsportsScreen.xml", "EsportsScreen", esportsScreen)

	return esportsScreen
end

function EsportsScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or EsportsScreen_mt)

	self:registerControls(EsportsScreen.CONTROLS)

	self.returnScreenClass = MainScreen
	self.serverController = EsportsServerController.new()
	self.isArenaHighlighted = true

	return self
end

function EsportsScreen.createFromExistingGui(gui, guiName)
	local newGui = EsportsScreen.new()

	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)

	return newGui
end

function EsportsScreen:onGuiSetupFinished()
	EsportsScreen:superClass().onGuiSetupFinished(self)

	self.lastFocusedButton = self.arenaTrainingButton
end

function EsportsScreen:onOpen()
	EsportsScreen:superClass().onOpen(self)
	self.serverController:init()
	FocusManager:setFocus(self.lastFocusedButton)
	self:updateOnlinePresenceName()
end

function EsportsScreen:onClose()
	self.lastFocusedButton = FocusManager:getFocusedElement()

	EsportsScreen:superClass().onOpen(self)
end

function EsportsScreen:onClickBack()
	self.serverController:stop()
	EsportsScreen:superClass().onClickBack(self)
end

function EsportsScreen:updateOnlinePresenceName()
	self.onlinePresenceNameElement:setText(g_i18n:getText("ui_onlinePresenceName") .. ": " .. g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))

	if Platform.canChangeGamerTag then
		self.changeNameButton:setVisible(true)
	else
		self.changeNameButton:setVisible(false)
	end
end

function EsportsScreen:onClickArenaTraining()
	self:startTraining(EsportsScreen.MAP_ID_ARENA)
end

function EsportsScreen:onClickArenaStartMatch()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickArenaStartMatch, self) then
		return
	end

	self:startMatch(EsportsScreen.MAP_ID_ARENA)
end

function EsportsScreen:onClickArenaJoinRandom()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickArenaJoinRandom, self) then
		return
	end

	g_gui:showMessageDialog({
		text = g_i18n:getText("ui_esports_searchForRandomMatch"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:joinRandomGame(EsportsScreen.MAP_ID_ARENA, self.onControllerCallback, self)
end

function EsportsScreen:onClickArenaJoin()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickArenaJoin, self) then
		return
	end

	g_gui:showMessageDialog({
		text = g_i18n:getText("ui_esports_searchForMatches"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:findGames(EsportsScreen.MAP_ID_ARENA, self.onControllerCallback, self)
end

function EsportsScreen:onClickBaleStackingTraining()
	self:startTraining(EsportsScreen.MAP_ID_BALESTACKING)
end

function EsportsScreen:onClickBaleStackingStartMatch()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickBaleStackingStartMatch, self) then
		return
	end

	self:startMatch(EsportsScreen.MAP_ID_BALESTACKING)
end

function EsportsScreen:onClickBaleStackingJoinRandom()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickBaleStackingJoinRandom, self) then
		return
	end

	g_gui:showMessageDialog({
		text = g_i18n:getText("ui_esports_searchForRandomMatch"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:joinRandomGame(EsportsScreen.MAP_ID_BALESTACKING, self.onControllerCallback, self)
end

function EsportsScreen:onClickBaleStackingJoin()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickBaleStackingJoin, self) then
		return
	end

	g_gui:showMessageDialog({
		visible = true,
		text = g_i18n:getText("ui_esports_searchForMatches"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:findGames(EsportsScreen.MAP_ID_BALESTACKING, self.onControllerCallback, self)
end

function EsportsScreen:onControllerCallback(callbackType, callbackArguments)
	g_gui:showMessageDialog({
		visible = false
	})

	if callbackType == EsportsServerController.CALLBACK_TYPE.ERROR then
		g_gui:showInfoDialog({
			text = callbackArguments.text,
			dialogType = DialogElement.TYPE_WARNING
		})
	elseif callbackType == EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE then
		g_gui:showMessageDialog({
			visible = true,
			text = callbackArguments.text,
			dialogType = DialogElement.TYPE_LOADING
		})
	elseif callbackType == EsportsServerController.CALLBACK_TYPE.READY_FOR_SERVER_LIST then
		g_joinGameScreen.isRequestPending = true

		g_gui:changeScreen(nil, JoinGameScreen, EsportsScreen)
		g_joinGameScreen:hideElementTemporarily("mapSelectionElement")

		g_joinGameScreen.selectedMap = callbackArguments.joinGameMapId

		g_joinGameScreen:hideElementTemporarily("modDlcElement")

		g_joinGameScreen.onlyWithAllModsAvailable = true

		g_joinGameScreen:hideElementTemporarily("detailButtonElement")
		g_joinGameScreen.settingsBox:invalidateLayout()
		FocusManager:setFocus(g_joinGameScreen.serverNameElement)

		g_joinGameScreen.isRequestPending = false

		g_joinGameScreen:getServers()
	end
end

function EsportsScreen:setIsArenaHighlighted(isHighlighted)
	self.arenaBanner:setVisible(isHighlighted)
	self.baleStackingBanner:setVisible(not isHighlighted)

	self.isArenaHighlighted = isHighlighted
end

function EsportsScreen:onHighlight(element)
	self:setIsArenaHighlighted(element.parent == self.arenaBox)
end

function EsportsScreen:onClickChangeName()
	local text = g_i18n:getText("ui_enterName")

	local function callback(newName)
		if newName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
			g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, newName, true)
			self:updateOnlinePresenceName()
		end
	end

	local defaultText = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	local confirmText = g_i18n:getText("button_change")

	g_gui:showTextInputDialog({
		callback = callback,
		defaultText = defaultText,
		confirmText = confirmText,
		text = text
	})
end

function EsportsScreen:onClickShowEsportsVideo()
	self:setIsArenaHighlighted(true)
	self:onClickOpenVideoScreen()
end

function EsportsScreen:onClickShowBaleStackingVideo()
	self:setIsArenaHighlighted(false)
	self:onClickOpenVideoScreen()
end

function EsportsScreen:onClickOpenVideoScreen()
	local filename = "dataS/videos/TutorialBaleStackingMode.ogv"
	local duration = EsportsScreen.VIDEO_DURATION.BALE_STACKING

	if self.isArenaHighlighted then
		filename = "dataS/videos/TutorialArenaMode.ogv"
		duration = EsportsScreen.VIDEO_DURATION.ARENA
	end

	g_esportsVideoScreen:setVideoFilename(filename, duration)
	g_gui:showGui("EsportsVideoScreen")
end

function EsportsScreen:getMissionInfos(mapId)
	local missionInfo = FSCareerMissionInfo.new("", nil, 0)

	missionInfo:loadDefaults()
	missionInfo:setMapId(mapId)

	missionInfo.supportsSaving = false
	local missionDynamicInfo = {
		mods = self:getMods(mapId)
	}

	return missionInfo, missionDynamicInfo
end

function EsportsScreen:getMods(mapId)
	local mapModName = g_mapManager:getModNameFromMapId(mapId)
	local mapMod = g_modManager:getModByName(mapModName)
	local mods = {
		mapMod
	}

	if g_isDevelopmentVersion then
		for _, modName in ipairs({
			"FS22_ProShot",
			"FS22_actionCamera",
			"actionCamera"
		}) do
			local devMod = g_modManager:getModByName(modName)

			if devMod ~= nil then
				table.insert(mods, devMod)
			end
		end
	end

	return mods
end

function EsportsScreen:startTraining(mapId)
	local missionInfo, missionDynamicInfo = self:getMissionInfos(mapId)

	g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_gui:changeScreen(nil, MPLoadingScreen)
	g_mpLoadingScreen:loadSavegameAndStart()
end

function EsportsScreen:startMatch(mapId)
	local missionInfo, missionDynamicInfo = self:getMissionInfos(mapId)

	g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_createGameScreen:hideElementTemporarily("autoAcceptElement")
	g_createGameScreen.settingsBox:invalidateLayout()
	g_gui:changeScreen(nil, CreateGameScreen, EsportsScreen)
end
