local overlays = {}
local loadedOverlays = false
local PIXEL = 1
local TOUCH_SIDE = 2
local TOUCH_MIDDLE = 3
local TOUCH_SIDE_BG = 4
local TOUCH_MIDDLE_BG = 5
local PIXEL_X_SIZE, PIXEL_Y_SIZE, TOUCH_HEIGHT, TOUCH_SIDE_WIDTH = nil

function onProfileUiResolutionScalingChanged()
	local resScale = 1
	local screenWidth = resScale * g_screenWidth
	local screenHeight = resScale * g_screenHeight
	PIXEL_X_SIZE = 1 / screenWidth
	PIXEL_Y_SIZE = 1 / screenHeight
	TOUCH_HEIGHT = 0.0953125 * g_aspectScaleY
	TOUCH_SIDE_WIDTH = math.floor(0.029292929292929294 * g_aspectScaleX / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

local function loadOverlays()
	overlays[PIXEL] = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

	if Platform.isMobile then
		overlays[TOUCH_SIDE] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_SIDE], unpack(GuiUtils.getUVs({
			573,
			502,
			58,
			120
		})))

		overlays[TOUCH_MIDDLE] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_MIDDLE], unpack(GuiUtils.getUVs({
			651,
			502,
			1,
			120
		})))

		overlays[TOUCH_SIDE_BG] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_SIDE_BG], unpack(GuiUtils.getUVs({
			212,
			502,
			58,
			120
		})))

		overlays[TOUCH_MIDDLE_BG] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_MIDDLE_BG], unpack(GuiUtils.getUVs({
			279,
			502,
			1,
			120
		})))
	end

	onProfileUiResolutionScalingChanged()

	loadedOverlays = true
end

function deleteDrawingOverlays()
	for _, overlay in pairs(overlays) do
		delete(overlay)
	end

	loadedOverlays = false
end

function drawFilledRect(x, y, width, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	if width == 0 or height == 0 then
		return
	end

	x, y = GuiUtils.alignToScreenPixels(x, y)
	width, height = GuiUtils.alignToScreenPixels(width, height)
	width = math.max(width, PIXEL_X_SIZE)
	height = math.max(height, PIXEL_Y_SIZE)

	if clipX1 ~= nil then
		local posX2 = x + width
		local posY2 = y + height
		x = math.max(x, clipX1)
		y = math.max(y, clipY1)
		width = math.max(math.min(posX2, clipX2) - x, 0)
		height = math.max(math.min(posY2, clipY2) - y, 0)

		if width == 0 or height == 0 then
			return
		end
	end

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, height)
end

function drawOutlineRect(x, y, width, height, lineWidth, lineHeight, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, lineHeight)
	renderOverlay(overlay, x, y, lineWidth, height)
	renderOverlay(overlay, x + width - lineWidth, y, lineWidth, height)
	renderOverlay(overlay, x, y + height - lineHeight, width, lineHeight)
end

function drawPoint(x, y, width, height, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x - width / 2, y - height / 2, width, height)
end

local function alignHorizontalToScreenPixels(x)
	return math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

function drawTouchButton(x, y, width, isPressed, hasBackground)
	if not loadedOverlays then
		loadOverlays()
	end

	x = alignHorizontalToScreenPixels(x)
	width = alignHorizontalToScreenPixels(width)
	y = y - TOUCH_HEIGHT * 0.5
	local overlaySide, overlayMiddle = nil

	if hasBackground then
		overlaySide = overlays[TOUCH_SIDE_BG]
		overlayMiddle = overlays[TOUCH_MIDDLE_BG]
	else
		overlaySide = overlays[TOUCH_SIDE]
		overlayMiddle = overlays[TOUCH_MIDDLE]
	end

	if isPressed then
		setOverlayColor(overlaySide, 0.718, 0.716, 0.715, 0.25)
		setOverlayColor(overlayMiddle, 0.718, 0.716, 0.715, 0.25)
	else
		setOverlayColor(overlaySide, 1, 1, 1, 1)
		setOverlayColor(overlayMiddle, 1, 1, 1, 1)
	end

	setOverlayRotation(overlaySide, 0, 0, 0)
	renderOverlay(overlaySide, x, y, TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	setOverlayRotation(overlaySide, math.pi, TOUCH_SIDE_WIDTH * 0.5, TOUCH_HEIGHT * 0.5)
	renderOverlay(overlaySide, x + width - TOUCH_SIDE_WIDTH, y, TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	renderOverlay(overlayMiddle, x + TOUCH_SIDE_WIDTH, y, width - 2 * TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
end

function drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	setOverlayColor(overlay, r, g, b, a)

	local deltaX = endX - startX
	local deltaY = endY - startY
	deltaY = deltaY / g_screenAspectRatio
	local deltaXSq = deltaX * deltaX
	local deltaYSq = deltaY * deltaY
	local length = math.sqrt(deltaXSq + deltaYSq)
	local angle = math.acos(deltaX / math.sqrt(deltaXSq + deltaYSq))

	if deltaY < 0 then
		angle = math.pi * 2 - angle
	end

	setOverlayRotation(overlay, angle, 0, 0)
	renderOverlay(overlay, startX, startY, length, thickness)
	setOverlayRotation(overlay, 0, 0, 0)
end

function drawOutlineCircle2D(x, y, radius, thickness, numSegments, r, g, b, a)
	drawPoint(x, y, 4 / g_screenWidth, 4 / g_screenHeight, 0, 0, 1, 1)

	local radiusX = radius
	local radiusY = radius * g_screenAspectRatio
	local startX = x + radiusX
	local startY = y
	local angle = math.pi * 2 / numSegments

	for i = 1, numSegments do
		local endX = x + radiusX * math.cos(angle * i)
		local endY = y + radiusY * math.sin(angle * i)

		drawLine2D(startX, startY, endX, endY, thickness, r, g, b, a)

		startY = endY
		startX = endX
	end
end
