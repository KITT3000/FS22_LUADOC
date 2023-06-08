EsportsVideoScreen = {}
local EsportsVideoScreen_mt = Class(EsportsVideoScreen, ScreenElement)
EsportsVideoScreen.CONTROLS = {
	VIDEO_ELEMENT = "videoElement"
}

function EsportsVideoScreen.register()
	local esportsVideoScreen = EsportsVideoScreen.new()

	g_gui:loadGui("dataS/gui/EsportsVideoScreen.xml", "EsportsVideoScreen", esportsVideoScreen)

	return esportsVideoScreen
end

function EsportsVideoScreen.new(target)
	local self = ScreenElement.new(target, EsportsVideoScreen_mt)
	self.isArenaVideo = true
	self.videoFilename = nil
	self.videoDuration = nil

	self:registerControls(EsportsVideoScreen.CONTROLS)

	self.isArenaVideo = true

	return self
end

function EsportsVideoScreen.createFromExistingGui(gui, guiName)
	local newGui = EsportsVideoScreen.new()

	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)

	return newGui
end

function EsportsVideoScreen:onClose()
	self.videoElement:disposeVideo()
	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	EsportsVideoScreen:superClass().onClose(self)
end

function EsportsVideoScreen:onOpen()
	EsportsVideoScreen:superClass().onOpen(self)
	g_gameStateManager:setGameState(GameState.LOADING)

	if self.videoFilename == nil then
		return
	end

	self.videoElement:changeVideo(self.videoFilename, nil, self.videoDuration)
	self.videoElement:playVideo()

	function self.videoElement.mouseEvent()
	end

	function self.videoElement.keyEvent()
	end

	function self.videoElement.inputEvent()
	end
end

function EsportsVideoScreen:onClickBack()
	self.videoElement:stopVideo()
	self:onVideoEnd()
end

function EsportsVideoScreen:onVideoEnd()
	g_gui:showGui("EsportsScreen")
end

function EsportsVideoScreen:setVideoFilename(videoFilename, videoDuration)
	self.videoFilename = videoFilename
	self.videoDuration = videoDuration
end
