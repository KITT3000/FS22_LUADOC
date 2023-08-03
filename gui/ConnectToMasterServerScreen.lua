ConnectToMasterServerScreen = {
	CONTROLS = {
		MAIN_BOX = "mainBox"
	}
}
local ConnectToMasterServerScreen_mt = Class(ConnectToMasterServerScreen, ScreenElement)

function ConnectToMasterServerScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or ConnectToMasterServerScreen_mt)

	self:registerControls(ConnectToMasterServerScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.isBackAllowed = false

	return self
end

function ConnectToMasterServerScreen:onOpen()
	ConnectToMasterServerScreen:superClass().onOpen(self)
	self.mainBox:setVisible(g_deepLinkingInfo == nil)
	g_gui:showMessageDialog({
		visible = g_deepLinkingInfo ~= nil,
		text = g_i18n:getText("ui_connectingPleaseWait"),
		dialogType = DialogElement.TYPE_LOADING
	})
	g_masterServerConnection:setCallbackTarget(self)
end

function ConnectToMasterServerScreen:onClickCancel()
	ConnectToMasterServerScreen:superClass().onClickCancel(self)
	ConnectToMasterServerScreen.goBackCleanup()

	self.startMissionInfo.canStart = false

	if self.startMissionInfo.createGame then
		self:changeScreen(self.prevScreenClass or CreateGameScreen)
	else
		self:changeScreen(self.prevScreenClass or MultiplayerScreen)
	end
end

function ConnectToMasterServerScreen:setNextScreenClass(nextScreenClass)
	self.nextScreenClass = nextScreenClass
end

function ConnectToMasterServerScreen:setPrevScreenClass(prevScreenClass)
	self.prevScreenClass = prevScreenClass
end

function ConnectToMasterServerScreen:connectToFront()
	g_masterServerConnection:connectToMasterServerFront()
end

function ConnectToMasterServerScreen:connectToBack(index)
	g_masterServerConnection:disconnectFromMasterServer()
	g_masterServerConnection:connectToMasterServer(index)
end

function ConnectToMasterServerScreen:onMasterServerListStart(numMasterServers)
	self.numMasterServers = numMasterServers
end

function ConnectToMasterServerScreen:onMasterServerList(name, id)
end

function ConnectToMasterServerScreen:onMasterServerListEnd()
	if self.numMasterServers == 1 then
		self:connectToBack(0)
	end
end

function ConnectToMasterServerScreen:onMasterServerConnectionFailed(reason)
	self.mainBox:setVisible(false)

	self.startMissionInfo.canStart = false

	ConnectToMasterServerScreen.goBackCleanup()
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, ClassUtil.getClassName(self.prevScreenClass))
end

function ConnectToMasterServerScreen:onMasterServerConnectionReady()
	local screen = g_gui:changeScreen(nil, self.nextScreenClass, self.prevScreenClass)

	screen.target:onMasterServerConnectionReady()
end

function ConnectToMasterServerScreen.goBackCleanup()
	g_asyncTaskManager:flushAllTasks()
	saveReadSavegameFinish("", ConnectToMasterServerScreen)

	g_deepLinkingInfo = nil

	g_masterServerConnection:disconnectFromMasterServer()
	g_mpLoadingScreen:unloadGameRelatedData()

	if g_client ~= nil then
		g_client:delete()

		g_client = nil
	end

	if g_server ~= nil then
		g_server:delete()

		g_server = nil
	else
		g_connectionManager:shutdownAll()
	end
end
