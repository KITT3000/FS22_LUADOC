EsportsServerController = {
	CALLBACK_TYPE = {}
}
EsportsServerController.CALLBACK_TYPE.ERROR = 1
EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE = 2
EsportsServerController.CALLBACK_TYPE.READY_FOR_SERVER_LIST = 3
EsportsServerController.CALLBACK_TYPE.JOINING_SERVER = 4
local EsportsServerController_mt = Class(EsportsServerController)

function EsportsServerController.new()
	local self = setmetatable({}, EsportsServerController_mt)

	return self
end

function EsportsServerController:init()
	Logging.devInfo("EsportsServerController:init()")
	g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue("defaultServerPort"))
	g_masterServerConnection:setCallbackTarget(self)

	self.numMasterServers = -1
	self.joinGameMapId = ""
	self.isFilteredServersRequestPending = false
	self.ignoredServers = {}
	self.servers = {}
	self.currentServerIndex = -1
end

function EsportsServerController:stop()
	Logging.devInfo("EsportsServerController:stop()")
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	self:cleanup()
end

function EsportsServerController:cleanup()
	Logging.devInfo("EsportsServerController:cleanup()")

	self.joinGameMapId = ""
	self.ignoredServers = {}
	self.servers = {}
	self.callbackFunc = nil
	self.callbackTarget = nil
end

function EsportsServerController:joinRandomGame(mapId, callbackFunc, callbackTarget)
	Logging.devInfo("EsportsServerController:joinRandomGame() %s", mapId)

	local map = g_mapManager:getMapById(mapId)

	if map == nil then
		Logging.error("EsportsServerController:joinRandomGame(): No map for given id '%s'", mapId)
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.ERROR, {
			text = string.format(g_i18n:getText("ui_esports_controller_unableToFindMap"), mapId)
		})

		return
	end

	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.joinGameMapId = mapId
	self.joinRandom = true

	if g_masterServerConnection.lastBackServerIndex == -1 then
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_connectingToMatchmaking"), "Front")
		})
		g_masterServerConnection:connectToMasterServerFront()
	else
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_connectingToMatchmaking"), "Back")
		})
		g_masterServerConnection:connectToMasterServer(0)
	end
end

function EsportsServerController:findGames(mapId, callbackFunc, callbackTarget)
	Logging.devInfo("EsportsServerController:findGames() %s", mapId)

	local map = g_mapManager:getMapById(mapId)

	if map == nil then
		Logging.error("EsportsServerController:joinRandomGame(): No map for given id '%s'", mapId)
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.ERROR, {
			text = string.format(g_i18n:getText("ui_esports_controller_unableToFindMap"), mapId)
		})

		return
	end

	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
	self.joinGameMapId = mapId
	self.joinRandom = false

	if g_masterServerConnection.lastBackServerIndex == -1 then
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_connectingToMatchmaking"), "Front")
		})
		g_masterServerConnection:connectToMasterServerFront()
	else
		callbackFunc(callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_connectingToMatchmaking"), "Back")
		})
		g_masterServerConnection:connectToMasterServer(0)
	end
end

function EsportsServerController:joinServer(password, serverId, languageId)
	g_maxUploadRate = 30.72
	local missionInfo = FSCareerMissionInfo.new("", nil, 0)

	missionInfo:loadDefaults()

	missionInfo.playerModelIndex = g_startMissionInfo.playerModelIndex
	local missionDynamicInfo = {
		serverId = serverId,
		isMultiplayer = true,
		isClient = true,
		password = password,
		languageId = languageId,
		allowOnlyFriends = false,
		joinedRandomServer = self.joinRandom
	}

	g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	g_gui:changeScreen(nil, MPLoadingScreen, EsportsScreen)
	g_mpLoadingScreen:startClient()
	self:cleanup()
end

function EsportsServerController:onMasterServerListStart(numMasterServers)
	Logging.devInfo("EsportsServerController:onMasterServerListStart %d", numMasterServers)

	self.numMasterServers = numMasterServers
end

function EsportsServerController:onMasterServerList(name, id)
	Logging.devInfo("EsportsServerController:onMasterServerList %s %s", name, id)
end

function EsportsServerController:onMasterServerListEnd()
	Logging.devInfo("EsportsServerController:onMasterServerListEnd")

	if self.numMasterServers == 1 then
		g_masterServerConnection:disconnectFromMasterServer()
		self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_connectingToMatchmaking"), "Back")
		})
		g_masterServerConnection:connectToMasterServer(0)

		return
	end

	Logging.warning("no matchmaking back servers found")
	self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.ERROR, {
		text = g_i18n:getText("ui_esports_controller_noMatchmakingServersFound")
	})
end

function EsportsServerController:onMasterServerConnectionReady()
	Logging.devInfo("EsportsServerController:onMasterServerConnectionReady")

	if self.isFilteredServersRequestPending then
		Logging.warning("masterServerRequestFilteredServers already pending, skipping")

		return
	end

	masterServerAddAvailableModStart()

	local mods = g_esportsScreen:getMods(self.joinGameMapId)

	for _, modItem in ipairs(mods) do
		masterServerAddAvailableMod(modItem.fileHash)
	end

	masterServerAddAvailableModEnd()

	if self.joinRandom then
		self.languageQueue = {
			g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
		}

		table.addElement(self.languageQueue, 0)
		self:retrieveServersNextLanguage()
	else
		local callbackArgs = {
			joinGameMapId = self.joinGameMapId
		}

		self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.READY_FOR_SERVER_LIST, callbackArgs)
	end
end

function EsportsServerController:onMasterServerConnectionFailed(reason)
	Logging.devWarning("EsportsServerController:onMasterServerConnectionFailed %s", reason)
	self.callbackFunc(self.callbackTarget)
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "EsportsScreen")
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
end

function EsportsServerController:retrieveServersNextLanguage()
	local languageId = table.remove(self.languageQueue, 1)

	if languageId == nil then
		Logging.devInfo("no more languages to get servers for")
		self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.ERROR, {
			text = g_i18n:getText("ui_esports_controller_noFreeSlotsOrServersFound")
		})
		g_masterServerConnection:disconnectFromMasterServer()

		self.isFilteredServersRequestPending = false

		return
	end

	self.languageId = languageId

	self:retrieveServers()
end

function EsportsServerController:retrieveServers()
	self.isFilteredServersRequestPending = true
	local allowCrossplay = true

	masterServerRequestFilteredServers(self.languageId, allowCrossplay)
	self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
		text = string.format(g_i18n:getText("ui_esports_controller_searchingForServers"), getLanguageName(self.languageId))
	})
end

function EsportsServerController:onServerInfoStart(numServers, totalNumServers)
	Logging.devInfo("EsportsServerController:onServerInfoStart %d %d", numServers, totalNumServers)

	self.servers = {}
end

function EsportsServerController:onServerInfo(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
	if not hasPassword and allModsAvailable and mapId == self.joinGameMapId then
		if self.ignoredServers[name] ~= nil then
			return
		end

		local server = {
			id = id,
			name = name,
			language = language,
			capacity = capacity,
			numPlayers = numPlayers,
			isLanServer = isLanServer,
			isFriendServer = isFriendServer,
			fullness = numPlayers / capacity
		}

		table.insert(self.servers, server)
	end
end

function EsportsServerController:onServerInfoEnd()
	Logging.devInfo("EsportsServerController:onServerInfoEnd")

	self.isFilteredServersRequestPending = false

	if #self.servers == 0 then
		Logging.devInfo("no matching servers found for current language")
		self:retrieveServersNextLanguage()

		return
	end

	table.sort(self.servers, function (a, b)
		return b.fullness < a.fullness
	end)

	self.currentServerIndex = 1

	self:tryJoinNextServer()
end

function EsportsServerController:tryJoinNextServer()
	local server = self.servers[self.currentServerIndex]

	if server ~= nil then
		Logging.devInfo("requesting server details for '%s' (id %d) (server %d / %d)", server.name, server.id, self.currentServerIndex, #self.servers)
		self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.PROGRESS_UPDATE, {
			text = string.format(g_i18n:getText("ui_esports_controller_tryingToJoinServer"), server.name)
		})

		self.currentDetailsServerName = server.name

		masterServerRequestServerDetails(server.id)
	end
end

function EsportsServerController:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	self.currentDetailsServerName = nil

	if numPlayers < capacity then
		self.callbackFunc(self.callbackTarget, EsportsServerController.CALLBACK_TYPE.JOINING_SERVER)
		self:joinServer("", id, language)

		return
	end

	self.ignoredServers[name] = true
	local nameWithoutTimestamp = string.gsub(name, "^%d+:%d%d ", "")
	self.ignoredServers[nameWithoutTimestamp] = true

	if self.currentServerIndex + 1 < #self.servers then
		self.currentServerIndex = self.currentServerIndex + 1

		self:retrieveServers()

		return
	end

	self:retrieveServersNextLanguage()
end

function EsportsServerController:onServerInfoDetailsFailed()
	Logging.devWarning("onServerInfoDetailsFailed")

	self.ignoredServers[self.currentDetailsServerName] = true
	self.currentDetailsServerName = nil

	if self.currentServerIndex + 1 < #self.servers then
		self.currentServerIndex = self.currentServerIndex + 1

		self:retrieveServers()

		return
	end

	self:retrieveServersNextLanguage()
end
