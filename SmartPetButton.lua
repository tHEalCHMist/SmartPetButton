-- Initialize the saved position table right away
if not SmartPetButtonPos then
    SmartPetButtonPos = { point = "CENTER", x = 0, y = 0 }
end

-- 1. Create a clean secure button
local frame = CreateFrame("Button", "SmartPetSecureButton", UIParent, "SecureActionButtonTemplate")
frame:SetSize(40, 40) 
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForClicks("AnyUp", "AnyDown")
frame:RegisterForDrag("LeftButton")

-- Build the visual appearance manually
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetColorTexture(0, 0, 0, 0.6)
frame.bg = bg

local texture = frame:CreateTexture(nil, "ARTWORK")
texture:SetAllPoints(frame)
frame.icon = texture

-- 2. DYNAMIC LOOKUP LOGIC: Bypasses the despawned body bug natively
frame:SetScript("PreClick", function(self)
    self:SetAttribute("type", "spell")
    
    if UnitExists("pet") then
        if UnitIsDead("pet") then
            self:SetAttribute("spell", "Revive Pet")
        else
            self:SetAttribute("spell", "Mend Pet")
        end
    else
        -- Clean, explicit lookup tracking: If the pet's corpse is truly gone, 
        -- check if Mend Pet is active in your spell tracker. 
        -- If Mend Pet is accessible, it means the pet is alive but dismissed.
        local isMendPetUsable = C_Spell.IsSpellUsable(136) -- 136 is Mend Pet
        
        if isMendPetUsable then
            self:SetAttribute("spell", "Call Pet 1")
        else
            self:SetAttribute("spell", "Revive Pet")
        end
    end
end)

-- 3. Define the drag positioning functions
frame:SetScript("OnDragStart", function(self) 
    if IsAltKeyDown() and not InCombatLockdown() then 
        self:StartMoving() 
    end 
end)

frame:SetScript("OnDragStop", function(self) 
    if not InCombatLockdown() then
        self:StopMovingOrSizing() 
        local point, _, _, x, y = self:GetPoint()
        SmartPetButtonPos.point = point or "CENTER"
        SmartPetButtonPos.x = x or 0
        SmartPetButtonPos.y = y or 0
    end
end)

-- 4. Update visual look dynamically
local function UpdateVisualIcon()
    local spellName = "Mend Pet"
    
    if not UnitExists("pet") then 
        local isMendPetUsable = C_Spell.IsSpellUsable(136)
        if isMendPetUsable then
            spellName = "Call Pet 1"
        else
            spellName = "Revive Pet"
        end
    elseif UnitIsDead("pet") then
        spellName = "Revive Pet"
    end
    
    local spellInfo = C_Spell.GetSpellInfo(spellName)
    if spellInfo then 
        frame.icon:SetTexture(spellInfo.iconID) 
    else
        frame.icon:SetColorTexture(0.2, 0.6, 0.2, 0.6)
    end
end

-- 5. Register standard update triggers
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("PET_BAR_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:ClearAllPoints()
        self:SetPoint(SmartPetButtonPos.point, UIParent, SmartPetButtonPos.point, SmartPetButtonPos.x, SmartPetButtonPos.y)
    end

    if not InCombatLockdown() then
        UpdateVisualIcon()
    end
end)
