MultiplayerScreen = {
	CONTROLS = {
		"onlinePresenceNameElement",
		"changeNameButton",
		NAT_WARNING = "natWarning",
		LIST_MP = "listMp",
		LIST_COOP = "listCoop"
	}
}
local MultiplayerScreen_mt = Class(MultiplayerScreen, ScreenElement)

function MultiplayerScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or MultiplayerScreen_mt)

	self:registerControls(MultiplayerScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.returnScreenClass = MainScreen

	return self
end

function MultiplayerScreen:onOpen()
	MultiplayerScreen:superClass().onOpen(self)
	self:initJoinGameScreen()

	self.startMissionInfo.createGame = false
	self.startMissionInfo.isMultiplayer = true

	if self.startMissionInfo.canStart then
		self.startMissionInfo.canStart = false

		self:changeScreen(ConnectToMasterServerScreen)
		g_connectToMasterServerScreen:connectToFront()
	end

	self:updateOnlinePresenceName()
	self.listMp:reloadData()

	function self.listMp.onFocusEnter()
		self.listMp:setSelectedItem(1, math.min(self.listCoop.selectedIndex, self.listMp.totalItemCount))
	end

	FocusManager:linkElements(self.listMp, FocusManager.LEFT, nil)
	FocusManager:linkElements(self.listMp, FocusManager.BOTTOM, nil)
	self.listCoop:reloadData()

	function self.listCoop.onFocusEnter()
		self.listCoop:setSelectedItem(1, math.min(self.listMp.selectedIndex, self.listCoop.totalItemCount))
	end

	FocusManager:linkElements(self.listCoop, FocusManager.RIGHT, nil)
	FocusManager:linkElements(self.listCoop, FocusManager.TOP, nil)
	FocusManager:setFocus(self.listCoop)
end

function MultiplayerScreen:updateOnlinePresenceName()
	self.onlinePresenceNameElement:setText(g_i18n:getText("ui_onlinePresenceName") .. ": " .. g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))

	if Platform.canChangeGamerTag then
		self.changeNameButton:setVisible(true)
	else
		self.changeNameButton:setVisible(false)
	end
end

function MultiplayerScreen:initJoinGameScreen()
	g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue("defaultServerPort"))
	g_connectToMasterServerScreen:setNextScreenClass(JoinGameScreen)
	g_connectToMasterServerScreen:setPrevScreenClass(MultiplayerScreen)
end

function MultiplayerScreen:onContinue()
	if FocusManager:getFocusedElement() == self.listCoop then
		local index = self.listCoop.selectedIndex

		if index == 1 then
			g_startMissionInfo.canStart = false

			self:changeScreen(ConnectToMasterServerScreen)
			g_connectToMasterServerScreen:connectToFront()
		elseif index == 2 then
			g_startMissionInfo.canStart = false
			g_createGameScreen.usePendingInvites = false

			self:changeScreen(CareerScreen, MainScreen)
		elseif index == 3 then
			if not GS_IS_STEAM_VERSION then
				openWebFile("fs22-rent-a-dedicated-server.php", "")
			else
				openWebFile("fs22-rent-a-dedicated-server-from-steam.php", "")
			end
		end
	elseif FocusManager:getFocusedElement() == self.listMp then
		self.startMissionInfo.canStart = false

		self:changeScreen(EsportsScreen)

		local index = self.listMp.selectedIndex

		if index == 1 then
			g_esportsScreen:setIsArenaScreen(true)
		elseif index == 2 then
			g_esportsScreen:setIsArenaScreen(false)
		end
	end
end

function MultiplayerScreen:onClickCreateGame()
	self.listCoop:setSelectedIndex(2)
	self:onContinue()
end

function MultiplayerScreen:onClickJoinGame()
	self.listCoop:setSelectedIndex(1)
	self:onContinue()
end

function MultiplayerScreen:onClickBaleStacking()
	g_startMissionInfo.canStart = false

	self:changeScreen(EsportsScreen)
	g_esportsScreen:setIsArenaScreen(false)
end

function MultiplayerScreen:update(dt)
	MultiplayerScreen:superClass().update(self, dt)
	Platform.verifyMultiplayerAvailabilityInMenu()
	self.natWarning:setVisible(getNATType() == NATType.NAT_STRICT)
end

function MultiplayerScreen:onClickChangeName()
	g_gui:showTextInputDialog({
		applyTextFilter = true,
		text = g_i18n:getText("ui_enterName"),
		callback = function (newName)
			if string.trim(newName) == "" then
				Logging.info("Player name cannot be empty")

				return
			end

			if newName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
				g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, newName, true)
				self:updateOnlinePresenceName()
			end
		end,
		defaultText = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME),
		confirmText = g_i18n:getText("button_change")
	})
end

function MultiplayerScreen:onClickOpenBlocklist()
	g_gui:showUnblockDialog({
		useLocal = true
	})
end

function MultiplayerScreen:getNumberOfItemsInSection(list, section)
	return Platform.showRentServerWebButton and list == self.listCoop and 3 or 2
end

function MultiplayerScreen:populateCellForItemInSection(list, section, index, cell)
	local function getOverlayStateFunc()
		if FocusManager:getFocusedElement() == list then
			return ListItemElement:superClass().getOverlayState(cell)
		else
			return GuiOverlay.STATE_NORMAL
		end
	end

	local function getIsSelectedFunc()
		if cell:getOverlayState() == GuiOverlay.STATE_SELECTED and FocusManager:getFocusedElement() == list then
			return true
		else
			return false
		end
	end

	cell.getOverlayState = getOverlayStateFunc
	cell:getAttribute("icon").getOverlayState = getOverlayStateFunc
	cell:getAttribute("title").getIsSelected = getIsSelectedFunc
	cell:getAttribute("text").getIsSelected = getIsSelectedFunc

	if list == self.listCoop then
		if index == 1 then
			cell:getAttribute("title"):setLocaKey("button_joinGame")
			cell:getAttribute("text"):setLocaKey("ui_coop_join_short")
			cell:getAttribute("icon"):applyProfile("multiplayerButtonIconJoin")
		elseif index == 2 then
			cell:getAttribute("title"):setLocaKey("button_createGame")
			cell:getAttribute("text"):setLocaKey("ui_coop_create_short")
			cell:getAttribute("icon"):applyProfile("multiplayerButtonIconCreate")
		elseif index == 3 then
			cell:getAttribute("title"):setLocaKey("button_rentAServer")
			cell:getAttribute("text"):setLocaKey("ui_coop_dedicated_short")
			cell:getAttribute("icon"):applyProfile("multiplayerButtonIconRent")
		end
	elseif index == 1 then
		cell:getAttribute("title"):setLocaKey("ui_esports_arena_title")
		cell:getAttribute("text"):setLocaKey("ui_esports_arena_short")
		cell:getAttribute("icon"):applyProfile("multiplayerButtonIconArena")
	elseif index == 2 then
		cell:getAttribute("title"):setLocaKey("ui_esports_baleStacking_title")
		cell:getAttribute("text"):setLocaKey("ui_esports_bsc_short")
		cell:getAttribute("icon"):applyProfile("multiplayerButtonIconBsc")
	end
end
