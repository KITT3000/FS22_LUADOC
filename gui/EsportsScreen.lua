EsportsScreen = {
	MAP_ID_ARENA = "arena.mapArena",
	MAP_ID_BALESTACKING = "baleStacking.mapBaleStacking",
	VIDEO_DURATION = {
		BALE_STACKING = 29.58,
		ARENA = 32.86
	},
	CONTROLS = {
		"bgBsc",
		"bgArena",
		"bscContainer",
		"arenaContainer",
		"buttonPlay",
		"changeNameButton"
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

	self.isArenaScreen = true
	self.returnScreenName = "MainScreen"
	self.serverController = EsportsServerController.new()

	return self
end

function EsportsScreen.createFromExistingGui(gui, guiName)
	local newGui = EsportsScreen.new()
	newGui.isArenaScreen = gui.isArenaScreen

	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)

	return newGui
end

function EsportsScreen:onGuiSetupFinished()
	EsportsScreen:superClass().onGuiSetupFinished(self)

	self.lastFocusedButton = self.buttonPlay
end

function EsportsScreen:onOpen()
	EsportsScreen:superClass().onOpen(self)
	self.serverController:init()
	FocusManager:setFocus(self.lastFocusedButton)
	self:setIsArenaScreen(self.isArenaScreen)

	if Platform.canChangeGamerTag then
		self.changeNameButton:setVisible(true)
	else
		self.changeNameButton:setVisible(false)
	end
end

function EsportsScreen:onClose()
	self.lastFocusedButton = FocusManager:getFocusedElement()

	EsportsScreen:superClass().onClose(self)
end

function EsportsScreen:setIsArenaScreen(isArenaScreen)
	self.isArenaScreen = isArenaScreen

	self.bgArena:setVisible(self.isArenaScreen)
	self.bgBsc:setVisible(not self.isArenaScreen)
	self.arenaContainer:setVisible(self.isArenaScreen)
	self.bscContainer:setVisible(not self.isArenaScreen)
end

function EsportsScreen:onContinue()
end

function EsportsScreen:onClickBack()
	g_gui:changeScreen(nil, MultiplayerScreen)
	self.serverController:stop()
	FocusManager:setFocus(g_multiplayerScreen.listMp)
end

function EsportsScreen:onClickChangeName()
	local text = g_i18n:getText("ui_enterName")

	local function callback(newName)
		if string.trim(newName) == "" then
			Logging.info("Player name cannot be empty")

			return
		end

		if newName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
			g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, newName, true)
			g_multiplayerScreen:updateOnlinePresenceName()
		end
	end

	local defaultText = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	local confirmText = g_i18n:getText("button_change")

	g_gui:showTextInputDialog({
		applyTextFilter = true,
		text = text,
		defaultText = defaultText,
		callback = callback,
		confirmText = confirmText
	})
end

function EsportsScreen:onClickOpenBlocklist()
	g_gui:showUnblockDialog({
		useLocal = true
	})
end

function EsportsScreen:onClickOpenVideoScreen()
	local filename = "dataS/videos/TutorialBaleStackingMode.ogv"
	local duration = EsportsScreen.VIDEO_DURATION.BALE_STACKING

	if self.isArenaScreen then
		filename = "dataS/videos/TutorialArenaMode.ogv"
		duration = EsportsScreen.VIDEO_DURATION.ARENA
	end

	g_esportsVideoScreen:setVideoFilename(filename, duration)
	g_gui:showGui("EsportsVideoScreen")
end

function EsportsScreen:update(dt)
	EsportsScreen:superClass().update(self, dt)
	Platform.verifyMultiplayerAvailabilityInMenu()
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

function EsportsScreen:onClickStartTraining()
	local mapId = EsportsScreen.MAP_ID_BALESTACKING

	if self.isArenaScreen then
		mapId = EsportsScreen.MAP_ID_ARENA
	end

	local missionInfo, missionDynamicInfo = self:getMissionInfos(mapId)

	g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_gui:changeScreen(nil, MPLoadingScreen)
	g_mpLoadingScreen:loadSavegameAndStart()
end

function EsportsScreen:onClickStartMatch()
	local mapId = EsportsScreen.MAP_ID_BALESTACKING

	if self.isArenaScreen then
		mapId = EsportsScreen.MAP_ID_ARENA
	end

	local missionInfo, missionDynamicInfo = self:getMissionInfos(mapId)

	g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_createGameScreen:hideElementTemporarily("autoAcceptElement")
	g_createGameScreen.settingsBox:invalidateLayout()
	g_gui:changeScreen(nil, CreateGameScreen, EsportsScreen)
end

function EsportsScreen:onClickJoinRandom()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickArenaJoinRandom, self) then
		return
	end

	local mapId = EsportsScreen.MAP_ID_BALESTACKING

	if self.isArenaScreen then
		mapId = EsportsScreen.MAP_ID_ARENA
	end

	g_gui:showMessageDialog({
		text = g_i18n:getText("ui_esports_searchForRandomMatch"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:joinRandomGame(mapId, self.onControllerCallback, self)
end

function EsportsScreen:onClickJoin()
	if not PlatformPrivilegeUtil.checkMultiplayer(self.onClickArenaJoin, self) then
		return
	end

	local mapId = EsportsScreen.MAP_ID_BALESTACKING

	if self.isArenaScreen then
		mapId = EsportsScreen.MAP_ID_ARENA
	end

	g_gui:showMessageDialog({
		text = g_i18n:getText("ui_esports_searchForMatches"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.serverController:findGames(mapId, self.onControllerCallback, self)
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
