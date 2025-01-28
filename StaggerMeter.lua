StaggerMeter_Settings = StaggerMeter_Settings or {}
StaggerMeter_Settings.windowPosition = StaggerMeter_Settings.windowPosition or { a1 = "CENTER", af = "UIParent", a2 = "CENTER", x = 0, y = 0 }

StaggerMeter_Settings.showIncomingOverMaxHP = StaggerMeter_Settings.showIncomingOverMaxHP or false 

-- Load saved keybinding and window position from settings
local moveKey = StaggerMeter_Settings.moveKey or "]"
local staggerWindowPosition = StaggerMeter_Settings.windowPosition

local moveKeyPressed = false

-- Function to check for the moveKey press
local function CheckMoveKey()
    local keys = {strsplit("-", StaggerMeter_Settings.moveKey)}
    local allKeysPressed = true

    for _, key in ipairs(keys) do
        if not IsKeyDown(key) then
            allKeysPressed = false
            break
        end
    end

    moveKeyPressed = allKeysPressed
end

-- Stagger Tracker Bar
local frame = CreateFrame("Frame", "StaggerMeter", UIParent)
frame:SetPoint(staggerWindowPosition.a1, _G[staggerWindowPosition.af], staggerWindowPosition.a2, staggerWindowPosition.x, staggerWindowPosition.y)
frame:SetSize(300, 30)

local bgTexture = frame:CreateTexture(nil, "BACKGROUND")
bgTexture:SetAllPoints(frame)
bgTexture:SetColorTexture(0.1, 0.1, 0.1, 0.7)
frame.bgTexture = bgTexture

frame:Show()
frame:EnableMouse(true)

local bar = CreateFrame("StatusBar", nil, frame)
bar:SetSize(300, 30)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
bar:SetPoint("CENTER", frame, "CENTER", 0, 0)
bar:SetStatusBarColor(0, 1, 0)  -- Green for light stagger
bar:Show()

-- Create text for percentage and absolute value
local percentageText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
percentageText:SetPoint("LEFT", frame, "LEFT", 10, 0)
percentageText:SetText("0%")
percentageText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
percentageText:SetJustifyH("LEFT")

local absoluteText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
absoluteText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
absoluteText:SetText("0 / 0")
absoluteText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
absoluteText:SetJustifyH("RIGHT")

-- Helper function to format health values
local function FormatHealth(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fk", value / 1000)
    else
        return tostring(value)
    end
end

-- Function to update the Stagger value
local function UpdateStagger()
    if UnitClass("player") == "Monk" and GetSpecialization() == 1 then
        local staggerAmount = UnitStagger("player")
        local currentHealth = UnitHealth("player")
        local maxHealth = UnitHealthMax("player")
        
        -- Check if the values are valid (not nil or invalid numbers)
        if staggerAmount and currentHealth and maxHealth then
            if staggerAmount > 0 then
                local staggerPercentageOfMaxHealth = staggerAmount / maxHealth  -- For color calculation based on max HP
                local staggerPercentageOfCurrentHealth = staggerAmount / currentHealth  -- For display based on current HP

                -- Use showIncomingOverMaxHP to determine the displayed percentage
                local staggerPercentage = StaggerMeter_Settings.showIncomingOverMaxHP and staggerPercentageOfCurrentHealth or staggerPercentageOfMaxHealth
                bar:SetValue(staggerPercentage)

                -- Display stagger as a percentage of current health or max health
                local percentageTextValue = string.format("%.0f%%", staggerPercentage * 100)
                percentageText:SetText(percentageTextValue)

                -- Format health values for display
                local formattedMaxHealth = FormatHealth(maxHealth)
                local formattedStaggerAmount = FormatHealth(staggerAmount)
                local formattedCurrentHealth = FormatHealth(currentHealth)
                local absoluteTextValue = string.format("%s / %s (%s)", formattedStaggerAmount, formattedCurrentHealth, formattedMaxHealth)
                absoluteText:SetText(absoluteTextValue)

                -- Change bar color based on stagger severity (based on max health percentage)
                if staggerPercentageOfMaxHealth < 0.30 then
                    bar:SetStatusBarColor(0, 1, 0)  -- Green
                elseif staggerPercentageOfMaxHealth < 0.60 then
                    bar:SetStatusBarColor(1, 1, 0)  -- Yellow
                else
                    bar:SetStatusBarColor(1, 0, 0)  -- Red
                end
            else
                bar:SetValue(0)
                bar:SetStatusBarColor(0.5, 0.5, 0.5)  -- Grey
                percentageText:SetText("0%")
                absoluteText:SetText("0 / " .. FormatHealth(currentHealth))
            end
        else
            -- Handle case where values are invalid (nil)
            print("Error: StaggerMeter received invalid values.")
        end
    end
end


frame:SetScript("OnUpdate", function(self, elapsed)
    UpdateStagger()
    CheckMoveKey()
end)

local function applyDragFunctionality(self)
    local df = CreateFrame("Frame", nil, self)
    df:SetAllPoints(self)
    df:SetFrameStrata("HIGH")
    df:SetHitRectInsets(0, 0, 0, 0)
    
    df:SetScript("OnMouseDown", function(self, button)
        CheckMoveKey()
        if moveKeyPressed then
            self:GetParent():StartMoving()
        end
    end)

    df:SetScript("OnMouseUp", function(self, button)
        self:GetParent():StopMovingOrSizing()
        local a1, af, a2, x, y = self:GetParent():GetPoint()
    
        -- Use 'af' if valid, otherwise fallback to 'UIParent'
        StaggerMeter_Settings.windowPosition = { 
            a1 = a1, 
            af = (af and af.GetName and af:GetName()) or "UIParent", 
            a2 = a2, 
            x = x, 
            y = y 
        }
    end)
    

    self:SetClampedToScreen(true)
    self:SetMovable(true)
    self:SetUserPlaced(true)
    df:EnableMouse(true)

    df:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetText("StaggerMeter", 1, 0.5, 0) 
        GameTooltip:AddLine("Tracks your Monk's Stagger percentage and severity.", 1, 1, 1)
        GameTooltip:AddLine("Tip: Hold the move key and drag the bar to adjust its position.", 0.8, 0.8, 1)
        GameTooltip:AddLine(" ", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Type |cff00ff00/smsm|r to configure.", 0.8, 0.8, 1) 
        GameTooltip:Show()
    end)

    df:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

applyDragFunctionality(frame)

function GameTooltip_SetDefaultAnchor(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_NONE")
    tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y)
    tooltip.default = 1
end
