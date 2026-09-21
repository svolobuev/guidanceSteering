---
-- GuidanceSteeringHUD
--
-- HUD for GuidanceSteering
--
-- Copyright (c) Wopster, 2019

---@class GuidanceSteeringHUD
GuidanceSteeringHUD = {}

local GuidanceSteeringHUD_mt = Class(GuidanceSteeringHUD)

---Creates a new instance of the GuidanceSteeringHUD.
---@return GuidanceSteeringHUD
function GuidanceSteeringHUD:new(mission, speedMeterDisplay, i18n, uiFilename)
    local instance = setmetatable({}, GuidanceSteeringHUD_mt)

    instance.speedMeterDisplay = speedMeterDisplay
    instance.i18n = i18n
    instance.uiFilename = uiFilename

    instance.vehicle = nil
    instance.receiverIconIsActive = false
    instance.steeringIconIsActive = false
    instance.laneText = "0"

    if not GuidanceSteeringHUD.hooksInstalled then
        SpeedMeterDisplay.storeScaledValues = Utils.appendedFunction(SpeedMeterDisplay.storeScaledValues, GuidanceSteeringHUD.speedMeterDisplay_storeScaledValues)
        SpeedMeterDisplay.draw = Utils.appendedFunction(SpeedMeterDisplay.draw, GuidanceSteeringHUD.speedMeterDisplay_draw)
        GuidanceSteeringHUD.hooksInstalled = true
    end

    return instance
end

function GuidanceSteeringHUD:delete()
    if self.stateBox ~= nil then
        self.stateBox:delete()
    end
end

function GuidanceSteeringHUD:load()
    self:createElements()
    self:storeScaledValues()
    self:setVehicle(nil)
end

--- Create the elements for the HUD.
function GuidanceSteeringHUD:createElements()
    local topRightX, topRightY = self.speedMeterDisplay.gearIcon:getPosition()
    local marginWidth, marginHeight = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.SIZE.BOX_MARGIN))
    self:createBox(self.uiFilename, topRightX + marginWidth, topRightY + marginHeight)
end

--- Create the box with the HUD icons.
function GuidanceSteeringHUD:createBox(hudAtlasPath, x, y)
    local boxWidth, boxHeight = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.SIZE.BOX))
    local posX = x - boxWidth * 0.5

    local iconWidth, iconHeight = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.SIZE.ICON))
    local iconPosX, iconPosY = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.POSITION.ICON))

    local boxOverlay = g_overlayManager:createOverlay("gui.gearBg", posX, y, boxWidth, boxHeight)
    local boxElement = HUDElement.new(boxOverlay)
    self.stateBox = boxElement

    self.stateBox:setColor(0.02, 0.02, 0.02, 0.8)

    self.stateBox:setVisible(true)

    self.steeringIcon = self:createIcon(hudAtlasPath, posX + iconPosX, y + iconPosY, iconWidth, iconHeight, GuidanceSteeringHUD.UV.STEERING_WHEEL_DISABLED)

    self.stateBox:addChild(self.steeringIcon)
    self.steeringIcon:setColor(unpack(GuidanceSteeringHUD.COLOR.INACTIVE))
    self.steeringIcon:setVisible(true)

    y = y + iconHeight

    self.receiverIcon = self:createIcon(hudAtlasPath, posX + iconPosX, y + iconPosY, iconWidth, iconHeight, GuidanceSteeringHUD.UV.RECEIVER)

    self.stateBox:addChild(self.receiverIcon)
    self.receiverIcon:setColor(unpack(GuidanceSteeringHUD.COLOR.INACTIVE))
    self.receiverIcon:setVisible(true)

    y = y + iconHeight

    self.laneIcon = self:createIcon(hudAtlasPath, posX + iconPosX, y + iconPosY, iconWidth, iconHeight, GuidanceSteeringHUD.UV.LANE)

    self.stateBox:addChild(self.laneIcon)
    self.laneIcon:setColor(unpack(GuidanceSteeringHUD.COLOR.INACTIVE))
    self.laneIcon:setVisible(true)

    return x - boxWidth
end

--- Create icon for the HUD.
function GuidanceSteeringHUD:createIcon(imagePath, baseX, baseY, width, height, uvs)
    local iconOverlay = Overlay.new(imagePath, baseX, baseY, width, height)
    iconOverlay:setUVs(GuiUtils.getUVs(uvs))
    local element = HUDElement.new(iconOverlay)

    element:setVisible(false)

    return element
end

function GuidanceSteeringHUD:storeScaledValues()
    if self.stateBox == nil then
        return
    end

    self.textOffX, self.textOffY = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.POSITION.LANE_TEXT))
    local _, textHeight = self.speedMeterDisplay:scalePixelValuesToScreenVector(0, GuidanceSteeringHUD.TEXT_SIZE.LANE)
    self.laneTextSize = textHeight
end

--- Sets the current vehicle to display on the HUD.
function GuidanceSteeringHUD:setVehicle(vehicle)
    self.vehicle = vehicle
    if self.stateBox ~= nil then
        self.stateBox:setVisible(vehicle ~= nil)
    end
end

--- Gets the lane text depending on the direction.
function GuidanceSteeringHUD:getLaneText(laneNumber)
    local lane = math.abs(laneNumber)
    if laneNumber < 0 then
        return ("-%s"):format(lane)
    elseif laneNumber > 0 then
        return ("+%s"):format(lane)
    end
    return ("%s"):format(lane)
end

function GuidanceSteeringHUD:drawText()
    if self.speedMeterDisplay.isVehicleDrawSafe and self.stateBox ~= nil and self.stateBox:getVisible() then
        local spec = self.vehicle.spec_globalPositioningSystem
        local data = spec.guidanceData

        self.laneText = self:getLaneText(data.currentLane)
        if self.steeringIconIsActive ~= spec.guidanceSteeringIsActive then
            self.steeringIconIsActive = spec.guidanceSteeringIsActive
            local uvs = self.steeringIconIsActive and GuidanceSteeringHUD.UV.STEERING_WHEEL_ENABLED or GuidanceSteeringHUD.UV.STEERING_WHEEL_DISABLED
            local color = self.steeringIconIsActive and GuidanceSteeringHUD.COLOR.ACTIVE or GuidanceSteeringHUD.COLOR.INACTIVE

            self.steeringIcon:setUVs(GuiUtils.getUVs(uvs))
            self.steeringIcon:setColor(unpack(color))
        end

        if self.receiverIconIsActive ~= spec.guidanceIsActive then
            self.receiverIconIsActive = spec.guidanceIsActive
            local color = self.receiverIconIsActive and GuidanceSteeringHUD.COLOR.ACTIVE or GuidanceSteeringHUD.COLOR.INACTIVE

            self.receiverIcon:setColor(unpack(color))
            self.laneIcon:setColor(unpack(color))
        end

        local topRightX, topRightY = self.speedMeterDisplay.gearIcon:getPosition()
        local marginWidth, marginHeight = self.speedMeterDisplay:scalePixelValuesToScreenVector(unpack(GuidanceSteeringHUD.SIZE.BOX_MARGIN))
        self.stateBox:setPosition(topRightX + marginWidth, topRightY + marginHeight)
        self.stateBox:draw()
        self:drawLaneText()

        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end

function GuidanceSteeringHUD:drawLaneText()
    local color = self.receiverIconIsActive and GuidanceSteeringHUD.COLOR.ACTIVE or GuidanceSteeringHUD.COLOR.INACTIVE

    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(unpack(color))

    local boxPosX, boxPosY = self.stateBox:getPosition()
    local boxWidth, boxHeight = self.stateBox:getWidth(), self.stateBox:getHeight()

    self.laneTextPositionX = boxPosX + boxWidth + self.textOffX
    self.laneTextPositionY = boxPosY + boxHeight + self.textOffY
    renderText(self.laneTextPositionX, self.laneTextPositionY, self.laneTextSize, self.laneText)
end

function GuidanceSteeringHUD.speedMeterDisplay_storeScaledValues(speedMeterDisplay)
    local guidance = g_currentMission ~= nil and g_currentMission.guidanceSteering
    if guidance ~= nil and guidance.ui.hud ~= nil then
        guidance.ui.hud:storeScaledValues()
    end
end

function GuidanceSteeringHUD.speedMeterDisplay_draw(speedMeterDisplay)
    local guidance = g_currentMission ~= nil and g_currentMission.guidanceSteering
    if guidance ~= nil and guidance.ui.hud ~= nil and speedMeterDisplay:getVisible() then
        guidance.ui.hud:drawText()
    end
end

GuidanceSteeringHUD.SIZE = {
    BOX = { 44, 110 },
    BOX_MARGIN = { -5, 50 },
    ICON = { 32, 32 },
}
GuidanceSteeringHUD.UV = {
    STEERING_WHEEL_ENABLED = { 650, 0, 65, 65 },
    STEERING_WHEEL_DISABLED = { 715, 0, 65, 65 },
    RECEIVER = { 650, 65, 65, 65 },
    LANE = { 715, 65, 65, 65 },
}

GuidanceSteeringHUD.POSITION = {
    LANE_TEXT = { -22, -20 },
    ICON = { 5, 5 },
}

GuidanceSteeringHUD.TEXT_COLOR = {
    LANE = { 0.7, 0.7, 0.7, 0.3 }
}

GuidanceSteeringHUD.COLOR = {
    INACTIVE = { 0.7, 0.7, 0.7, 0.3 },
    ACTIVE = { 0.0003, 0.5647, 0.9822, 1 }
}

GuidanceSteeringHUD.TEXT_SIZE = {
    LANE = 14
}
