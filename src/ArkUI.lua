ArkUI = {
  name = "ArkUI",
  playerAttributes = {},
  attributeBarOffset = 200
}

function ArkUI:AdjustAttributeBarsLocation()
  local stats = { "Health", "Stamina", "Magicka"}
  local types = { POWERTYPE_HEALTH, POWERTYPE_STAMINA, POWERTYPE_MAGICKA }

  for i = 1, #stats, 1 do
    local attributeBar = _G["ZO_PlayerAttribute" .. stats[i]]

    -- Get the current anchor point and adjust it a bit more to the middle of the screen
    local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = attributeBar:GetAnchor(0)

    -- Adjust both bars to the left/right by half of the width of the health bar
    if (stats[i] == "Magicka") then
      offsetX = 0 - self.attributeBarOffset
      -- Set a new anchor point relative to the health bar in the center
      attributeBar:ClearAnchors()
      attributeBar:SetAnchor(point, ZO_PlayerAttributeHealth, relativePoint, offsetX, offsetY)
    elseif (stats[i] == "Stamina") then
      offsetX = 0 + self.attributeBarOffset
      -- Set a new anchor point relative to the health bar in the center
      attributeBar:ClearAnchors()
      attributeBar:SetAnchor(point, ZO_PlayerAttributeHealth, relativePoint, offsetX, offsetY)
    end
  end
end

function ArkUI:UpdateLabels()
  local current, max
  for powerType, attr in pairs(self.playerAttributes) do
    current, max = GetUnitPower("player", powerType)
    self:OnAttributeUpdate(powerType, current, max)
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

function ArkUI:OnAttributeUpdate(powerType, current, max, effectiveMax)
  local diff = current - self.playerAttributes[powerType].lastValue
  local ratio = current/max
  local percentage = math.floor(ratio * 100)
  local attribute = self.playerAttributes[powerType]

  attribute.label:SetColor(1, ratio, ratio, 1)
  attribute.label:SetText(current .. " / " .. max .. " (" .. percentage .. "%)")
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

function ArkUI:UpdateReticleOverHealth(current, max)
  local ratio = current/max
  local percentage = math.floor(ratio * 100)
  self.reticleLabel:SetColor(1, ratio, ratio, 1)
  self.reticleLabel:SetText(current .. " / " .. max .. " (" .. percentage .. "%)")
end

function ArkUI:Initialize()
  self.savedVars = ZO_SavedVars:New("ArkUI_SavedVariables", 1, nil, defaults)
  self.unitName = GetUnitName("player")

  local health = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Health")
  healthTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIAttributeLabel", health, "ArkUIAttributeBarLabel"),
    statIndex = STAT_HEALTH_MAX,
    statRegenIndex = STAT_HEALTH_REGEN_IDLE,
    statRegenInCombatIndex = STAT_HEALTH_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIRegenLabel", health, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(health:GetName() .. "ArkUIDiffLabel", health, "ArkUIAttributeBarLabel"),
    lastValue = 0,
  }
  healthTable.label:SetAnchor(BOTTOM, health, TOP, 0, 2)
  healthTable.regenLabel:SetAnchor(RIGHT, healthTable.label, LEFT, -8, 0)
  healthTable.regenLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
  healthTable.diffLabel:SetAnchor(LEFT, healthTable.label, RIGHT, 8, 0)
  healthTable.diffFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArkUIAttributeBarDiffFade", healthTable.diffLabel)
  self.playerAttributes[POWERTYPE_HEALTH] = healthTable
	
  local stamina = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Stamina")
  local staminaTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName().."ArkUIAttributeLabel", stamina, "ArkUIAttributeBarLabel"),
    statIndex = STAT_STAMINA_MAX,
    statRegenIndex = STAT_STAMINA_REGEN_IDLE,
    statRegenInCombatIndex = STAT_STAMINA_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName().."ArkUIRegenLabel", stamina, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(stamina:GetName().."ArkUIDiffLabel", stamina, "ArkUIAttributeBarLabel"),
    lastValue = 0,
  }
  staminaTable.label:SetAnchor(BOTTOMLEFT, stamina, TOPLEFT, 0, 2)
  staminaTable.regenLabel:SetAnchor(LEFT, staminaTable.label, RIGHT, 8, 0)
  staminaTable.regenLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
  staminaTable.diffLabel:SetAnchor(LEFT, staminaTable.regenLabel, RIGHT, 8, 0)
  staminaTable.diffFade = ANIMATION_MANAGER:CreateTimelineFromVirtual("ArkUIAttributeBarDiffFade", staminaTable.diffLabel)
  self.playerAttributes[POWERTYPE_STAMINA] = staminaTable
	
  local magicka = GetControl(PLAYER_ATTRIBUTE_BARS.control, "Magicka")
  local magickaTable = {
    label = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName().."ArkUIAttributeLabel", magicka, "ArkUIAttributeBarLabel"),
    statIndex = STAT_MAGICKA_MAX,
    statRegenIndex = STAT_MAGICKA_REGEN_IDLE,
    statRegenInCombatIndex = STAT_MAGICKA_REGEN_COMBAT,
    regenLabel = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName().."ArkUIRegenLabel", magicka, "ArkUIAttributeBarLabel"),
    diffLabel = WINDOW_MANAGER:CreateControlFromVirtual(magicka:GetName().."ArkUIDiffLabel", magicka, "ArkUIAttributeBarLabel"),
    lastValue = 0,
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

  self.AdjustAttributeBarsLocation()
  PLAYER_ATTRIBUTE_BARS:ForceShow(true)
end

function ArkUI.PlayerActivated()
  ArkUI:UpdateLabels()
  ArkUI:UpdateStats(false)
end

function ArkUI.PowerUpdate(eventType, unitTag, powerPoolIndex, powerType, current, max, effectiveMax)
  if unitTag == "reticleover" then
    if powerType == POWERTYPE_HEALTH then
      ArkUI:UpdateReticleOverHealth(current, max)
    end
    return
  end

  if unitTag ~= "player" then return end
  if powerType ~= POWERTYPE_STAMINA and powerType ~= POWERTYPE_HEALTH and powerType ~= POWERTYPE_MAGICKA then return end

  ArkUI:OnAttributeUpdate(powerType, current, max, effectiveMax)
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
  if not DoesUnitExist("reticleover") then return end
  local current, max = GetUnitPower("reticleover", POWERTYPE_HEALTH)
  ArkUI:UpdateReticleOverHealth(current, max)
end

function ArkUI.OnAddOnLoaded(eventType, addonName)
  if addonName == ArkUI.name then
    ArkUI:Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(ArkUI.name, EVENT_ADD_ON_LOADED, ArkUI.OnAddOnLoaded)
