ArkUI = {
  name = "ArkUI",
  playerAttributes = {},
  attributeBarOffsetX = 200,
  attributeBarOffsetY = -25
}

-- This only works with control that has one anchor.
function ArkUI:AdjustControlLocationByOffset(control, offsetX, offsetY)
  local isValidAnchor, point, relativeTo, relativePoint, originalOffsetX, originalOffsetY = control:GetAnchor(0)
  control:ClearAnchors()
  control:SetAnchor(point, relativeTo, relativePoint, originalOffsetX + offsetX, originalOffsetY + offsetY)
end

function ArkUI:UpdateLabels()
  local current, max
  for powerType, attr in pairs(self.playerAttributes) do
    current, max = GetUnitPower("player", powerType)
    self:UpdatePlayerAttributeValue(powerType, current, max)
    attr.lastValue = current
  end
end

function ArkUI:UpdateStats(inCombat)
  local regen
  for powerType, attr in pairs(self.playerAttributes) do
    if inCombat then
      regen = GetPlayerStat(attr.statRegenInCombatIndex, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
    else
      regen = GetPlayerStat(attr.statRegenIndex, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
    end

    attr.regenLabel:SetText("(" .. regen .. "/2s)")
  end
end

function ArkUI:CalculateShieldText(shieldValue, maxShieldValue)
  if shieldValue ~= nil and shieldValue > 0 then
    return " [" .. shieldValue .. " / " .. maxShieldValue .. "]"
  end
  return ""
end

function ArkUI:UpdatePlayerAttributeValue(powerType, currentValue, maxValue)
  local attribute = self.playerAttributes[powerType]
  attribute.currentValue = currentValue
  attribute.maxValue = maxValue
  self:OnAttributeUpdate(powerType)
end

function ArkUI:UpdatePlayerShieldValue(currentValue, maxValue)
  local attribute = self.playerAttributes[POWERTYPE_HEALTH]
  attribute.shieldValue = currentValue
  attribute.maxShieldValue = maxValue
  self:OnAttributeUpdate(POWERTYPE_HEALTH)
end

function ArkUI:OnAttributeUpdate(powerType)
  local attribute = self.playerAttributes[powerType]

  local current = attribute.currentValue
  local max = attribute.maxValue
  local diff = current - attribute.lastValue
  local ratio = current/max
  local percentage = math.floor(ratio * 100)

  local shieldText = ""
  if powerType == POWERTYPE_HEALTH then
    shieldText = self:CalculateShieldValue(attribute.shieldValue, attribute.maxShieldValue)
  end

  attribute.label:SetColor(1, ratio, ratio, 1)
  attribute.label:SetText(current .. " / " .. max .. shieldText .. " - " .. percentage .. "%")
  attribute.lastValue = current

  if diff ~= 0 then
    if diff > 0 then
      attribute.diffLabel:SetColor(0, 1, 0, 1)
      attribute.diffLabel:SetText("+"..diff)
    else
      attribute.diffLabel:SetColor(1, 0, 0, 1)
      attribute.diffLabel:SetText(diff)
    end
    attribute.diffFade:PlayFromStart()
  end
end

function ArkUI:UpdateReticleOverHealth()
  local current, max = GetUnitPower("reticleover", POWERTYPE_HEALTH)
  local ratio = current/max
  local percentage = math.floor(ratio * 100)

  local shieldValue, maxShieldValue = GetUnitAttributeVisualizerEffectInfo(
      "reticleover", ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
  local shieldText = self:CalculateShieldText(shieldValue, maxShieldValue)

  self.reticleLabel:SetColor(1, ratio, ratio, 1)
  self.reticleLabel:SetText(current .. " / " .. max .. shieldText .. " - " .. percentage .. "%")
end

function ArkUI:Initialize()
  self.savedVars = ZO_SavedVars:New("ArkUI_SavedVariables", 1, nil, defaults)
  self.unitName = GetUnitName("player")

  local health = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Health")
  self:AdjustControlLocationByOffset(health, 0, self.attributeBarOffsetY)
  healthTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIAttributeLabel", health, "ArkUIAttributeBarLabel"),
    statIndex = STAT_HEALTH_MAX,
    statRegenIndex = STAT_HEALTH_REGEN_IDLE,
    statRegenInCombatIndex = STAT_HEALTH_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIRegenLabel", health, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIDiffLabel", health, "ArkUIAttributeBarLabel"),
    lastValue = 0,
    currentValue = 0,
    maxValue = 0,
    shieldValue = 0,
    maxShieldValue = 0,
  }
  healthTable.label:SetAnchor(BOTTOM, health, TOP, 0, 2)
  healthTable.regenLabel:SetAnchor(RIGHT, healthTable.label, LEFT, -8, 0)
  healthTable.regenLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
  healthTable.diffLabel:SetAnchor(LEFT, healthTable.label, RIGHT, 8, 0)
  healthTable.diffFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArkUIAttributeBarDiffFade", healthTable.diffLabel)
  self.playerAttributes[POWERTYPE_HEALTH] = healthTable

  local stamina = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Stamina")
  self:AdjustControlLocationByOffset(stamina, -self.attributeBarOffsetX, self.attributeBarOffsetY)
  local staminaTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName() .. "ArkUIAttributeLabel", stamina, "ArkUIAttributeBarLabel"),
    statIndex = STAT_STAMINA_MAX,
    statRegenIndex = STAT_STAMINA_REGEN_IDLE,
    statRegenInCombatIndex = STAT_STAMINA_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName() .. "ArkUIRegenLabel", stamina, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName() .. "ArkUIDiffLabel", stamina, "ArkUIAttributeBarLabel"),
    lastValue = 0,
    currentValue = 0,
    maxValue = 0,
  }
  staminaTable.label:SetAnchor(BOTTOMLEFT, stamina, TOPLEFT, 0, 2)
  staminaTable.regenLabel:SetAnchor(LEFT, staminaTable.label, RIGHT, 8, 0)
  staminaTable.regenLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
  staminaTable.diffLabel:SetAnchor(LEFT, staminaTable.regenLabel, RIGHT, 8, 0)
  staminaTable.diffFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArkUIAttributeBarDiffFade", staminaTable.diffLabel)
  self.playerAttributes[POWERTYPE_STAMINA] = staminaTable

  local magicka = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Magicka")
  self:AdjustControlLocationByOffset(magicka, self.attributeBarOffsetX, self.attributeBarOffsetY)
  local magickaTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName() .. "ArkUIAttributeLabel", magicka, "ArkUIAttributeBarLabel"),
    statIndex = STAT_MAGICKA_MAX,
    statRegenIndex = STAT_MAGICKA_REGEN_IDLE,
    statRegenInCombatIndex = STAT_MAGICKA_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName() .. "ArkUIRegenLabel", magicka, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName() .. "ArkUIDiffLabel", magicka, "ArkUIAttributeBarLabel"),
    lastValue = 0,
    currentValue = 0,
    maxValue = 0,
  }
  magickaTable.label:SetAnchor(BOTTOMRIGHT, magicka, TOPRIGHT, 0, 2)
  magickaTable.regenLabel:SetAnchor(RIGHT, magickaTable.label, LEFT, -8, 0)
  magickaTable.regenLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
  magickaTable.diffLabel:SetAnchor(RIGHT, magickaTable.regenLabel, LEFT, -8, 0)
  magickaTable.diffFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArkUIAttributeBarDiffFade", magickaTable.diffLabel)
  self.playerAttributes[POWERTYPE_MAGICKA] = magickaTable

  self.reticleLabel = WINDOW_MANAGER:CreateControlFromVirtual(
      ZO_TargetUnitFramereticleover:GetName() .. "ArkUILabel",
      ZO_TargetUnitFramereticleover,
      "ArkUIAttributeBarLabel")
  self.reticleLabel:SetAnchor(TOP, ZO_TargetUnitFramereticleover, BOTTOM)

  local _, point, _, relPoint, x, y = ZO_TargetUnitFramereticleoverTextArea:GetAnchor(0)
  ZO_TargetUnitFramereticleoverTextArea:ClearAnchors()
  ZO_TargetUnitFramereticleoverTextArea:SetAnchor(point, self.reticleLabel, relPoint, x, y - 6)

  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, ArkUI.PlayerActivated)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_POWER_UPDATE, ArkUI.PowerUpdate)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_STATS_UPDATED, ArkUI.EventStatsUpdate)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, ArkUI.EventCombatState)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_RETICLE_TARGET_CHANGED, ArkUI.EventReticleTargetChanged)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, ArkUI.OnVisualizationAdded)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, ArkUI.OnVisualizationRemoved)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, ArkUI.OnVisualizationUpdated)

  PLAYER_ATTRIBUTE_BARS:ForceShow(true)
end

function ArkUI.PlayerActivated()
  ArkUI:UpdateLabels()
  ArkUI:UpdateStats(false)
end

function ArkUI.PowerUpdate(
    eventType, unitTag, powerPoolIndex, powerType, currentValue, maxValue, effectiveMax)
  if unitTag == "reticleover" then
    if powerType == POWERTYPE_HEALTH then
      ArkUI:UpdateReticleOverHealth()
    end
    return
  end

  if unitTag ~= "player" then return end
  if powerType ~= POWERTYPE_STAMINA and powerType ~= POWERTYPE_HEALTH and powerType ~= POWERTYPE_MAGICKA then return end

  ArkUI:UpdatePlayerAttributeValue(powerType, currentValue, maxValue)
end

function ArkUI.EventStatsUpdate(eventType, unitTag)
  if unitTag == "player" then
    ArkUI:UpdateStats(IsUnitInCombat("player"))
  end
end

function ArkUI.EventCombatState(eventType, inCombat)
  ArkUI:UpdateStats(inCombat)
end

function ArkUI.EventReticleTargetChanged(eventType)
  if DoesUnitExist("reticleover") then
    ArkUI:UpdateReticleOverHealth()
  end
end

function ArkUI.OnVisualizationAdded(
    eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue)
  if unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING then
    if unitTag == "reticleover" then
      ArkUI:UpdateReticleOverHealth()
    elseif unitTag == "player" then
      ArkUI:UpdatePlayerShieldValue(value, maxValue)
    end
  end
end

function ArkUI.OnVisualizationRemoved(
    eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType, value, maxValue)
  if unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING then
    if unitTag == "reticleover" then
      ArkUI:UpdateReticleOverHealth()
    elseif unitTag == "player" then
      ArkUI:UpdatePlayerShieldValue(0, maxValue)
    end
  end
end

function ArkUI.OnVisualizationUpdated(
    eventCode, unitTag, unitAttributeVisual, statType, attributeType, powerType,
    oldValue, newValue, oldMaxValue, newMaxValue)
  if unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING then
    if unitTag == "reticleover" then
      ArkUI:UpdateReticleOverHealth()
    elseif unitTag == "player" then
      ArkUI:UpdatePlayerShieldValue(newValue, newMaxValue)
    end
  end
end

function ArkUI.OnAddOnLoaded(eventType, addonName)
  if addonName == ArkUI.name then
    ArkUI:Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(ArkUI.name, EVENT_ADD_ON_LOADED, ArkUI.OnAddOnLoaded)
