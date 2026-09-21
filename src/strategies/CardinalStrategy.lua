---
-- CardinalStrategy
--
-- Strategy class for cardinal degrees also called A+heading.
--
-- Copyright (c) Wopster, 2018

---@class CardinalStrategy: ABStrategy
CardinalStrategy = {}

local CardinalStrategy_mt = Class(CardinalStrategy, ABStrategy)

function CardinalStrategy:new(vehicle, customMt)
    local instance = ABStrategy:new(vehicle, customMt or CardinalStrategy_mt)

    instance.currentCardinal = nil
    instance.id = ABStrategy.A_PLUS_HEADING

    return instance
end

function CardinalStrategy:readStream(streamId, connection)
    CardinalStrategy:superClass().readStream(self, streamId, connection)

    if streamReadBool(streamId) then
        self.currentCardinal = streamReadFloat32(streamId)
    end
end

function CardinalStrategy:writeStream(streamId, connection)
    CardinalStrategy:superClass().writeStream(self, streamId, connection)

    streamWriteBool(streamId, self.currentCardinal ~= nil)
    if self.currentCardinal ~= nil then
        streamWriteFloat32(streamId, self.currentCardinal)
    end
end

function CardinalStrategy:delete()
    CardinalStrategy:superClass().delete(self)
    self.currentCardinal = nil
end

---Show the input dialog for setting the current cardinal.
local function showCardinalDialog(target)
    if target.vehicle.isClient and target.vehicle:getIsEntered() then
        TextInputDialog.show(CardinalStrategy.cardinalCallback, target, "0",
            g_i18n:getText("guidanceSteering_setting_cardinalTitle"), nil, 3,
            g_i18n:getText("guidanceSteering_setting_cardinalConfirmText"))
    end
end

function CardinalStrategy:interact(guidanceData)
    if self.ab:getIsEmpty() then
        showCardinalDialog(self)
        self.ab:nextPoint(guidanceData)
    end
end

---Callback on the dialog to set and calculate the current direction.
function CardinalStrategy:cardinalCallback(cardinal, confirmed)
    if confirmed == false then
        self.vehicle:updateGuidanceData(nil, false, true)
        return
    end
    cardinal = tonumber(cardinal)
    if cardinal ~= nil then
        self.currentCardinal = MathUtil.degToRad(cardinal)

        local spec = self.vehicle.spec_globalPositioningSystem
        if spec.lineStrategy:getIsGuidancePossible() then
            -- When possible we do handle the next event directly.
            spec.multiActionEvent:reset()
            self.vehicle:interactWithGuidanceStrategy(false) -- call again for event.
            GlobalPositioningSystem.computeGuidanceDirection(self.vehicle)
        end
    else
        showCardinalDialog(self)
    end
end

---Gets the guidance drive data for the given cardinals
---@param guidanceNode number
---@param data table
function CardinalStrategy:getGuidanceData(guidanceNode, data)
    local x, y, z = getWorldTranslation(guidanceNode)
    local dx, dz = 0, 0

    if self.currentCardinal ~= nil then
        local cardinal = self.currentCardinal + math.pi
        dx, dz = math.sin(cardinal), -math.cos(cardinal)
    else
        local pointA = self.ab:getPointNode(ABPoint.POINT_A)
        local a = { localToWorld(guidanceNode, 0, 0, 0) }
        local b = { localToWorld(pointA, 0, 0, 0) }

        local dirX = a[1] - b[1]
        local dirZ = a[3] - b[3]
        local length = MathUtil.vector2Length(dirX, dirZ)

        if length > 0.000001 then
            dx, dz = dirX / length, dirZ / length
        else
            dx, _, dz = localDirectionToWorld(guidanceNode, 0, 0, 1)
        end
    end

    return { x, y, z, dx, dz }
end

function CardinalStrategy:getIsGuidancePossible()
    return self.ab:getPointNode(ABPoint.POINT_A) ~= nil
end

function CardinalStrategy:needsDrivingDistanceThreshold()
    return false
end
